#!/usr/bin/env python3
"""Симуляция обычного игрока по новой экономике.

Игрок заходит 4 раза в день по 15 минут (8:00, 12:30, 18:00, 22:00), всё остальное время
игра закрыта. Пока игра закрыта, водители работают с долей offline_income_rate (не больше
8 часов за раз), отзывы копятся так же. Во время игры игрок тапает, покупает самое
выгодное, держит листовки, запускает билборд и ТВ, когда они готовы, тянет канат дуэли.

Цель баланса: все 6 островов примерно за 3–4 недели, ночь ≈ 3–4 часа игры.

Читает те же JSON, что и игра. Запуск:
    python3 scripts/economy_sim.py            # итоговая таблица
    python3 scripts/economy_sim.py -v         # плюс журнал по дням
"""

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"

SESSIONS = [8.0, 12.5, 18.0, 22.0]   # часы входа
SESSION_MINUTES = 15.0
TAPS_PER_SECOND = 2.5                # обычный игрок, не кликер-машина
TAP_STEPS = 3
TAPS_PER_REPUTATION = 20
DRIVER_POWER = 1.215                 # лучший из трёх (5 звёзд, см. drivers.json) кандидатов
DRIVER_SALARY = 0.06
HIRE_BASE = 100.0
KEPT_RATING = 4.4
OFFLINE_CAP = 8 * 3600.0
DT = 2.0                             # шаг во время игры, секунд
AD_SECONDS = 30.0                    # сколько длится рекламный ролик (в это время игрок не тапает)
DISTRICT_ADS_PER_SESSION = 4         # сколько роликов за районы игрок смотрит за заход
ALIENS_PER_SESSION = 2               # инопланетян за ролик (каждый на 1 час)
SHARE_PAYBACK = 45.0                 # доли берём, когда остальные покупки окупаются дольше 45 минут
USE_VIDEO_ADS = True                 # крутить ТВ за ролики весь заход


def load(name):
    with (DATA / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def scaled_cost(base, growth, owned):
    price = math.floor(base * (growth ** owned) + 0.000001)
    return max(1.0, float(price))


def fmt_day(seconds):
    days = seconds / 86400.0
    return "день %4.1f" % (days + 1.0)


def fmt_money(value):
    for unit, size in (("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if value >= size:
            return "%.1f%s" % (value / size, unit)
    return "%.0f" % value


class Player:
    def __init__(self, overrides=None):
        self.upgrades = load("upgrades.json")
        self.staff = load("drivers.json")
        self.cities = load("cities.json")
        self.regions = load("regions.json")
        self.competitors = load("competitors.json")
        self.market = load("market.json")
        self.cars = load("cars.json")
        self.helpers = load("helpers.json")
        self.balance = load("balance.json")
        if overrides:
            overrides(self)
        b = self.balance
        self.tap_from_income = float(b.get("tap_from_income", 0.01))
        self.first_level_cost = float(b.get("tap_level_first_cost", 40))
        self.rating_per_star = float(b.get("rating", {}).get("mult_per_star", 0.15))
        self.offline_rate = float(b.get("offline_income_rate", 0.45))
        self.reviews_k = float(b.get("reviews_per_hour", 25))
        self.fleet_growth = float(b.get("fleet_growth", 1.15))
        self.trade_share = float(b.get("trade_in_share", 0.5))
        wear = b.get("wear", {})
        self.tap_upkeep = (float(wear.get("player_wash_taps", 20)) * float(wear.get("tap_clean", 0.0015))
                           + float(wear.get("player_repair_taps", 80)) * float(wear.get("tap_health", 0.0003)))
        self.fleet_upkeep = (float(wear.get("fleet_wash_seconds", 20)) * float(wear.get("fleet_clean_per_second", 0.0016667))
                             + float(wear.get("fleet_repair_seconds", 150)) * float(wear.get("fleet_health_per_second", 0.00033333)))
        self.districts = [dict(d, island=city.get("island")) for city in self.cities for d in city["districts"]
                          if not d.get("premium")]
        alien = self.staff.get("alien", {})
        self.alien_power = 1.0 + float(alien.get("income_bonus", 0.7))
        self.alien_salary = float(alien.get("salary", 0.05))
        self.alien_seconds = float(alien.get("seconds", 3600))
        self.time = 0.0
        self.active_seconds = 0.0
        self.lifetime = 0.0
        self.bought = []          # (время, вид, цена, окупаемость в секундах)
        self.events = []
        self.reset()

    def reset(self):
        self.captured = {}
        self.tap_level = 0
        self.tuning = {u["id"]: 0 for u in self.upgrades}
        self.district_levels = {d["id"]: 0 for d in self.districts}
        self.home_capacity = int(self.balance.get("garage_start", 5))
        self.expansion_level = 0
        self.garage = []
        self.team = 0
        self.hired_total = 0
        self.aliens = []          # время, до которого работает каждый
        self.watch_until = 0.0
        self.session_district_ads = 0
        self.session_aliens = 0
        self.shares = {}
        self.paid_boost = 0.0
        self.paid_until = 0.0
        self.helpers_on = set()
        self.open_regions = set(r["id"] for r in self.regions if r.get("home"))
        self.owned = set()
        self.surrendered = {}
        self.rope = {}
        self.ad_boost = 0.0
        self.ad_until = 0.0
        self.free_ready = {}
        self.coins = 0.0
        self.taps = 0
        self.reviews = 0.0

    def log(self, text):
        self.events.append((self.time, text))

    # --- доход ---------------------------------------------------------------
    def district_mult(self):
        return 1.0 + sum(d["income_pct"] * self.district_levels[d["id"]] for d in self.districts)

    def district_unlocked(self, d):
        return not d.get("island") or d["island"] in self.open_regions

    def multiplier(self, with_ad=True):
        region = 1.0 + sum(r.get("income_bonus", 0) for r in self.regions if r["id"] in self.open_regions)
        rival = 1.0 + sum(c.get("income_bonus", 0) for c in self.competitors if c["id"] in self.owned)
        rival += float(self.market.get("capture_bonus", 0.25)) * len(self.captured)
        rating = 1.0 + (KEPT_RATING - 4.0) * self.rating_per_star
        ad = (1.0 + self.ad_boost + self.paid_boost) if with_ad else 1.0
        return self.district_mult() * region * rival * rating * ad

    def capacity(self):
        islands = sum(int(r.get("garage_slots", 0)) for r in self.regions
                      if r["id"] in self.open_regions and not r.get("home"))
        return self.home_capacity + islands

    def car_income(self, i):
        return float(self.cars[i].get("driver_income", 0))

    def helper_fee(self):
        return sum(h.get("fee_share", 0) for h in self.helpers if h["id"] in self.helpers_on)

    def upkeep(self):
        upkeep = self.fleet_upkeep
        if "washer" in self.helpers_on:
            upkeep *= 0.5
        if "mechanic" in self.helpers_on:
            upkeep *= 0.6
        return upkeep

    def driver_net(self, i):
        return self.car_income(i) * DRIVER_POWER * (1.0 - DRIVER_SALARY - self.upkeep())

    def alien_net(self, i):
        return self.car_income(i) * self.alien_power * (1.0 - self.alien_salary - self.upkeep())

    def live_aliens(self):
        return sum(1 for until in self.aliens if until > self.time)

    def staffed(self):
        return sorted(self.garage, key=self.car_income, reverse=True)[: self.team + self.live_aliens()]

    def passive(self, with_ad=True, aliens=True):
        cars = sorted(self.garage, key=self.car_income, reverse=True)
        n_alien = min(self.live_aliens(), len(cars)) if aliens else 0
        base = sum(self.alien_net(i) for i in cars[:n_alien])
        base += sum(self.driver_net(i) for i in cars[n_alien:n_alien + self.team])
        return base * (1.0 - self.helper_fee()) * self.multiplier(with_ad)

    def tuning_mult(self):
        return 1.0 + sum(u["tap_pct"] * self.tuning[u["id"]] for u in self.upgrades)

    def level_curve(self, level, key):
        last = len(self.cars) - 1
        index = level // TAP_STEPS
        if index >= last:
            ratio = float(self.cars[last][key]) / float(self.cars[last - 1][key])
            if key == "tap_mult":
                ratio = float(self.balance.get("tap_after_last_mult", 1.6))
            return float(self.cars[last][key]) * ratio ** ((level - last * TAP_STEPS) / TAP_STEPS)
        start, end = float(self.cars[index][key]), float(self.cars[index + 1][key])
        return start * (end / max(start, 1e-6)) ** ((level % TAP_STEPS) / TAP_STEPS)

    def car_unlocked(self, i):
        island = self.cars[i].get("unlock_island", "")
        return island == "" or island in self.open_regions

    def level_mult(self, level=None):
        return max(1.0, self.level_curve(self.tap_level if level is None else level, "tap_mult"))

    def level_cost(self):
        target = self.tap_level + 1
        if target < TAP_STEPS:
            part = (target - 1) / (TAP_STEPS - 1)
            return math.ceil(self.first_level_cost * (float(self.cars[1]["buy_cost"]) / self.first_level_cost) ** part)
        return math.ceil(self.level_curve(target, "buy_cost"))

    def ride(self, with_ad=True):
        return self.level_mult() * self.tuning_mult() * self.multiplier(with_ad)

    def tap_power(self):
        return self.ride() * (1.0 - self.tap_upkeep) + self.passive() * self.tap_from_income * self.tuning_mult()

    def watching(self):
        return self.time < self.watch_until

    def active_dps(self):
        if self.watching():
            return self.passive()
        return self.tap_power() * TAPS_PER_SECOND + self.passive()

    def full_dps(self):
        return self.tap_power() * TAPS_PER_SECOND + self.passive()

    def reputation(self):
        return self.taps // TAPS_PER_REPUTATION + self.team + int(self.reviews)

    # --- рынок -----------------------------------------------------------------
    def player_power(self):
        return self.passive() + self.ride() * float(self.market.get("player_tap_rate", 3))

    def front(self):
        for r in self.regions:
            if r["id"] in self.open_regions and r["id"] not in self.captured:
                return r["id"]
        return None

    def front_rivals(self):
        island = self.front()
        return [c for c in self.competitors if c.get("island") == island]

    def active_rival(self):
        for c in self.front_rivals():
            if c["id"] not in self.owned and c["id"] not in self.surrendered:
                return c
        return None

    def share_price(self, c):
        duel = self.duel()
        return math.ceil(float(c["power"]) * float(duel.get("share_seconds", 40))
                         * float(duel.get("share_growth", 1.08)) ** self.shares.get(c["id"], 0))

    def shares_total(self):
        return round(100.0 / float(self.duel().get("share_percent", 5)))

    def duel(self):
        return self.market.get("duel", {})

    def rival_power(self, c):
        return float(c["power"])

    def rope_speed(self, ratio):
        """Доля каната в секунду. Сильнее вдвое и больше — полная скорость."""
        duel = self.duel()
        full = 1.0 / float(duel.get("rope_seconds", 720))
        if ratio >= 1.0:
            return full * min(1.0, 3.0 * (ratio - 1.0) / (ratio + 1.0))
        return -1.0 / float(duel.get("rope_back_seconds", 1800))

    # --- покупки -----------------------------------------------------------------
    def options(self):
        found = []
        dps = self.active_dps()
        passive = self.passive()
        tap_part = self.tap_power() * TAPS_PER_SECOND
        # Тюнинг: +tap_pct к тапу за уровень.
        tm = self.tuning_mult()
        for u in self.upgrades:
            if self.tuning[u["id"]] >= int(u.get("max_level", 5)):
                continue
            cost = scaled_cost(u["base_cost"], u["cost_growth"], self.tuning[u["id"]])
            gain = tap_part * (u["tap_pct"] / tm)
            found.append(("tuning", u["id"], cost, gain / cost))
        # Районы теперь за ролики — см. watch_ads().
        cost = self.level_cost()
        next_car = min((self.tap_level + 1) // TAP_STEPS, len(self.cars) - 1)
        if not self.car_unlocked(next_car):
            cost = float("inf")
        gain = tap_part * (self.level_mult(self.tap_level + 1) / self.level_mult() - 1.0)
        found.append(("level", self.tap_level + 1, cost, gain / cost))
        boost = self.multiplier() * (1.0 - self.helper_fee()) * (1.0 + self.tap_from_income * TAPS_PER_SECOND)
        cap = self.capacity()
        full = len(self.garage) >= cap
        hire = scaled_cost(HIRE_BASE, float(self.staff.get("hire_growth", 1.05)), self.hired_total)
        if len(self.garage) > self.team:
            free = sorted(self.garage, key=self.car_income, reverse=True)[self.team]
            found.append(("hire", free, hire, self.driver_net(free) * boost / hire))
        best_slot = None
        for i in range(1, len(self.cars)):
            if not self.car_unlocked(i):
                continue
            fleet = scaled_cost(float(self.cars[i]["buy_cost"]), self.fleet_growth, self.garage.count(i))
            if best_slot is None or self.driver_net(i) / (fleet + hire) > best_slot[1] / best_slot[0]:
                best_slot = (fleet + hire, self.driver_net(i) * boost)
            if full:
                worst = min(self.garage, key=self.car_income)
                if self.car_income(i) <= self.car_income(worst):
                    continue
                cost = max(1.0, fleet - math.floor(self.cars[worst]["buy_cost"] * self.trade_share))
                found.append(("trade", i, cost, (self.driver_net(i) - self.driver_net(worst)) * boost / cost))
            else:
                cost = fleet + hire
                found.append(("slot", i, cost, self.driver_net(i) * boost / cost))
        if full and best_slot:
            step = self.next_expansion()
            cost = float(step["cost"]) + best_slot[0]
            found.append(("expand", 0, float(step["cost"]), best_slot[1] * int(step["add"]) / (cost + best_slot[0] * (int(step["add"]) - 1))))
        for h in self.helpers:
            if h["id"] in self.helpers_on:
                continue
            # Помощники берут долю, но экономят сервис и время: считаем их окупаемыми, когда парк > 8 машин.
            if len(self.garage) >= 8:
                found.append(("helper", h["id"], float(h["cost"]), 1e-12))
        rep = self.reputation()
        for idx, r in enumerate(self.regions):
            if r["id"] in self.open_regions:
                continue
            if rep < r["reputation"] or (idx > 0 and self.regions[idx - 1]["id"] not in self.captured):
                continue
            found.append(("region", r["id"], float(r["cost"]), 1e9))
        for c in self.front_rivals():
            if c["id"] in self.surrendered:
                found.append(("rival", c["id"], self.surrendered[c["id"]], 1e8))
        # Доли — у любого соперника острова; берём самую дешёвую.
        open_rivals = [c for c in self.front_rivals() if c["id"] not in self.owned]
        # Игрок не бросает развитие ради долей: доля «окупается» как вложение на SHARE_PAYBACK минут,
        # то есть сначала берёт всё, что окупается быстрее, а лишние деньги несёт соперникам.
        if open_rivals:
            c = min(open_rivals, key=self.share_price)
            found.append(("share", c["id"], self.share_price(c), 1.0 / (SHARE_PAYBACK * 60.0)))
        return found

    def next_expansion(self):
        listed = self.balance.get("garage_expansions", [])
        if self.expansion_level < len(listed):
            return listed[self.expansion_level]
        last = listed[-1]
        growth = float(self.balance.get("garage_expansion_growth", 10))
        return {"cost": math.floor(float(last["cost"]) * growth ** (self.expansion_level - len(listed) + 1)),
                "add": int(last["add"])}

    def gate_target(self):
        """Ближайшая крупная цель, на которую игрок копит: выкуп сдавшегося или следующий остров."""
        for c in self.front_rivals():
            if c["id"] in self.surrendered:
                return self.surrendered[c["id"]]
        rep = self.reputation()
        for idx, r in enumerate(self.regions):
            if r["id"] in self.open_regions:
                continue
            if idx > 0 and self.regions[idx - 1]["id"] not in self.captured:
                return None
            if rep >= r["reputation"]:
                return float(r["cost"])
            return None
        return None

    def buy(self, kind, eid, cost):
        self.coins -= cost
        if kind == "tuning":
            self.tuning[eid] += 1
        elif kind == "district":
            self.district_levels[eid] += 1
        elif kind == "level":
            self.tap_level = eid
        elif kind in ("hire", "slot"):
            if kind == "slot":
                self.garage.append(eid)
            self.team += 1
            self.hired_total += 1
        elif kind == "share":
            self.shares[eid] = self.shares.get(eid, 0) + 1
            if self.shares[eid] >= self.shares_total():
                self.owned.add(eid)
                self.log("выкуплен босс %s" % eid)
        elif kind == "trade":
            self.garage.remove(min(self.garage, key=self.car_income))
            self.garage.append(eid)
        elif kind == "expand":
            step = self.next_expansion()
            self.expansion_level += 1
            self.home_capacity += int(step["add"])
        elif kind == "helper":
            self.helpers_on.add(eid)
        elif kind == "region":
            self.open_regions.add(eid)
            name = next(r["city"] for r in self.regions if r["id"] == eid)
            self.log("открыт %s" % name)
        elif kind == "rival":
            self.owned.add(eid)
            del self.surrendered[eid]
            self.log("выкуплен %s за %s" % (eid, fmt_money(cost)))

    def buy_best(self):
        for _guard in range(400):
            options = self.options()
            gates = [o for o in options if o[3] >= 1e8]
            affordable_gates = [o for o in gates if o[2] <= self.coins + 1e-6]
            if affordable_gates:
                o = max(affordable_gates, key=lambda o: o[3])
                self.buy(o[0], o[1], o[2])
                continue
            # Копим на цель, если до неё меньше 2 часов активного дохода: мелочь не покупаем.
            target = self.gate_target()
            reserve = 0.0
            if target is not None and target - self.coins < self.full_dps() * 7200:
                reserve = target
            choices = [o for o in options if o[3] < 1e8 and o[2] <= self.coins - reserve + 1e-6]
            if not choices:
                return
            o = max(choices, key=lambda o: o[3])
            self.bought.append((self.time, o[0], o[2], 1.0 / max(o[3], 1e-12)))
            self.buy(o[0], o[1], o[2])

    # --- время -----------------------------------------------------------------
    def watch(self):
        self.watch_until = self.time + AD_SECONDS

    def ads(self):
        """Листовки за монеты и ролики — отдельные полосы, бонусы складываются."""
        if self.time >= self.ad_until:
            self.ad_boost = 0.0
        if self.time >= self.paid_until:
            self.paid_boost = 0.0
        if self.watching():
            return
        ads = self.market.get("ads", [])
        if self.paid_boost <= 0.0:
            for a in ads:
                if a.get("pay", "coins") != "coins":
                    continue
                price = math.ceil(max(float(a.get("min_price", 100)),
                                      self.passive(False) + self.ride(False) * float(self.market.get("player_tap_rate", 3)))
                                  * float(a.get("price_seconds", 60)))
                if price <= self.coins * 0.5:
                    self.coins -= price
                    self.paid_boost = float(a["boost"])
                    self.paid_until = self.time + float(a.get("duration", 300))
                break
        # Районы за ролик: сначала самый выгодный.
        if self.session_district_ads < DISTRICT_ADS_PER_SESSION:
            free = [d for d in self.districts if self.district_unlocked(d)
                    and self.district_levels[d["id"]] < int(d.get("max_level", 5))]
            if free:
                d = max(free, key=lambda d: d["income_pct"])
                self.district_levels[d["id"]] += 1
                self.session_district_ads += 1
                self.watch()
                return
        if self.session_aliens < ALIENS_PER_SESSION and self.garage:
            self.aliens = [u for u in self.aliens if u > self.time]
            self.aliens.append(self.time + AD_SECONDS + self.alien_seconds)
            self.session_aliens += 1
            self.watch()
            return
        if USE_VIDEO_ADS and self.ad_boost <= 0.0:
            best = max((a for a in ads if a.get("pay") == "video"),
                       key=lambda a: float(a["boost"]) * float(a.get("duration", 300)) / (float(a.get("duration", 300)) + AD_SECONDS),
                       default=None)
            if best is not None:
                self.watch()
                self.ad_boost = float(best["boost"])
                self.ad_until = self.watch_until + float(best.get("duration", 300))

    def play(self, seconds):
        end = self.time + seconds
        self.session_district_ads = 0
        self.session_aliens = 0
        while self.time < end:
            self.ads()
            dt = DT
            gained = self.active_dps() * dt
            self.coins += gained
            self.lifetime += gained
            if not self.watching():
                self.taps += int(TAPS_PER_SECOND * dt)
            if self.team:
                self.reviews += self.reviews_k * math.sqrt(self.team) * dt / 3600.0
            # Каната нет: соперников выкупают долями (см. options/buy).
            island = self.front()
            if island and all(c["id"] in self.owned for c in self.front_rivals()):
                self.captured[island] = self.time
                self.log("ЗАХВАЧЕН %s" % next(r["city"] for r in self.regions if r["id"] == island))
            self.buy_best()
            self.time += dt
            self.active_seconds += dt

    def away(self, seconds):
        self.ad_boost = 0.0
        self.paid_boost = 0.0
        self.watch_until = 0.0
        paid = min(seconds, OFFLINE_CAP)
        rate = self.offline_rate
        if "dispatcher" in self.helpers_on:
            rate += float(next(h for h in self.helpers if h["id"] == "dispatcher").get("offline_bonus", 0))
        # Инопланетяне дорабатывают свой час и улетают.
        alien_left = min(paid, max([u - self.time for u in self.aliens] + [0.0]))
        earned = self.passive(False) * rate * alien_left + self.passive(False, aliens=False) * rate * (paid - alien_left)
        self.aliens = []
        self.coins += earned
        self.lifetime += earned
        if self.team:
            self.reviews += self.reviews_k * math.sqrt(self.team) * rate * paid / 3600.0
        self.time += seconds

    def run(self, days=45):
        day_start = SESSIONS[0] * 3600.0
        self.time = day_start
        self.buy_best()
        for day in range(days):
            for k, hour in enumerate(SESSIONS):
                start = day * 86400.0 + hour * 3600.0
                if self.time < start:
                    self.away(start - self.time)
                self.play(SESSION_MINUTES * 60.0)
                if len(self.captured) == len(self.regions):
                    return

    def snapshot(self):
        return {
            "day": self.time / 86400.0 + 1.0,
            "income": self.passive(False),
            "tap": self.tap_power(),
            "team": self.team,
            "garage": len(self.garage),
            "rep": self.reputation(),
        }


KIND_NAMES = {"tuning": "тюнинг", "district": "районы", "level": "линия тапа", "slot": "машина+водитель",
              "trade": "обмен машины", "hire": "водитель", "expand": "гараж", "helper": "помощник"}


def main():
    p = Player()
    opened, captured, sessions = {}, {}, []
    p.time = SESSIONS[0] * 3600.0
    p.buy_best()
    for day in range(45):
        for hour in SESSIONS:
            start = day * 86400.0 + hour * 3600.0
            if p.time < start:
                before = p.coins
                p.away(start - p.time)
                night_gain = p.coins - before
            else:
                night_gain = 0.0
            bought_before = len(p.bought)
            o, c = set(p.open_regions), set(p.captured)
            hour_income = p.full_dps() * 3600.0
            p.play(SESSION_MINUTES * 60.0)
            sessions.append((p.time, len(p.bought) - bought_before, night_gain / max(hour_income, 1.0) if hour == SESSIONS[0] else None))
            for r in p.open_regions - o:
                opened[r] = p.time
            for r in set(p.captured) - c:
                captured[r] = p.time
        if len(p.captured) == len(p.regions):
            break
    print("ОБЫЧНЫЙ ИГРОК: 4 захода по 15 минут, %.1f тапа/с; без игры — %d%% дохода, до 8 ч" % (TAPS_PER_SECOND, round(p.offline_rate * 100)))
    print()
    print("Остров       открыт   захвачен")
    for r in p.regions:
        print("%-11s %7s  %9s" % (r["city"], "старт" if r.get("home") else "%.1f д" % (opened.get(r["id"], 0) / 86400.0 + 1.0) if r["id"] in opened else "—",
                                   "%.1f д" % (captured[r["id"]] / 86400.0 + 1.0) if r["id"] in captured else "—"))
    print()
    nights = [n for _t, _k, n in sessions if n is not None]
    print("Утро после ночи: начислено ≈ %.1f ч активной игры (медиана)" % sorted(nights)[len(nights) // 2])
    edges = [0.0] + sorted(captured.values()) + [float("inf")]
    print()
    print("Этап (до захвата)        покупок за заход   окупаемость покупок, мин (медиана по видам)")
    for k in range(len(edges) - 1):
        lo, hi = edges[k], edges[k + 1]
        counts = [n for t, n, _ in sessions if lo < t <= hi]
        kinds = {}
        for t, kind, cost, pay in p.bought:
            if lo < t <= hi and kind in KIND_NAMES:
                kinds.setdefault(kind, []).append(pay / 60.0)
        parts = ["%s %.0f" % (KIND_NAMES[kind], sorted(v)[len(v) // 2]) for kind, v in sorted(kinds.items())]
        name = p.regions[k]["city"] if k < len(p.regions) else "после"
        if counts:
            print("%-22s %6.1f            %s" % (name, sum(counts) / len(counts), ", ".join(parts)))
    print()
    print("Активной игры: %.0f ч за %.0f дней" % (p.active_seconds / 3600.0, p.time / 86400.0 + 1.0))


if __name__ == "__main__":
    main()
