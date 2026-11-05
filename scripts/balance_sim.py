#!/usr/bin/env python3
"""Симуляция игрока, который покупает самую выгодную вещь.

Читает те же JSON, что и игра, и повторяет формулы цены, тапа, дохода, дуэлей и островов.
Игрок играет без остановки, вовремя моет, чинит и меняет смены, пакостями не пользуется.
Соперники города идут по очереди: активный растёт, пока с ним дуэль; догнали по силе —
он сдаётся, игрок выкупает его, как только хватит денег. Рекламу игрок покупает, только
когда с ней точно обгонит соперника (самую дешёвую из подходящих). Когда за STALL_HOURS часов не захвачено ни одного острова, а франшиза
вырастет хотя бы в PRESTIGE_GAIN раз, он продаёт компанию.

Запуск: python3 scripts/balance_sim.py [часов]   (по умолчанию 400)
"""

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
TAPS_PER_SECOND = 4.0
TAPS_PER_REPUTATION = 20
# Игрок выбирает лучшего из трёх кандидатов: считаем водителя чуть выше среднего.
DRIVER_POWER = 1.3
DRIVER_SALARY = 0.24
HIRE_BASE = 100.0
# Игрок вовремя меняет смены и моет машины: рейтинг держится около 4.5 звёзд.
KEPT_RATING = 4.5
STALL_HOURS = 6.0
PRESTIGE_GAIN = 2.0


def load(name):
    with (DATA / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def scaled_cost(base, growth, owned):
    price = math.floor(base * (growth ** owned) + 0.000001)
    return 1.0 if price < 1.0 else float(price)


def fmt_time(seconds):
    if seconds is None:
        return "—"
    seconds = int(seconds)
    days, rest = divmod(seconds, 86400)
    hours, rest = divmod(rest, 3600)
    minutes, secs = divmod(rest, 60)
    if days:
        return "%d д %02d ч" % (days, hours)
    if hours:
        return "%d ч %02d мин" % (hours, minutes)
    if minutes:
        return "%d мин %02d с" % (minutes, secs)
    return "%d с" % secs


def step_size(time):
    if time < 2 * 3600:
        return 1.0
    if time < 24 * 3600:
        return 5.0
    return 30.0


class Player:
    def __init__(self):
        self.upgrades = load("upgrades.json")
        self.staff = load("drivers.json")
        self.cities = load("cities.json")
        self.regions = load("regions.json")
        self.competitors = load("competitors.json")
        self.market = load("market.json")
        self.cars = load("cars.json")
        balance = load("balance.json")
        self.balance = balance
        self.tap_from_income = float(balance.get("tap_from_income", 0.01))
        self.rent_share = float(balance.get("car_rent_share", 0.3))
        self.rating_per_star = float(balance.get("rating", {}).get("mult_per_star", 0.15))
        self.franchise_reference = float(balance.get("franchise_reference", 1e9))
        self.franchise_weight = float(balance.get("franchise_weight", 0.5))
        # Игрок вовремя моет и чинит: это доля выручки, которая уходит на сервис.
        wear = balance.get("wear", {})
        self.tap_upkeep = (
            float(wear.get("player_wash_taps", 20)) * float(wear.get("tap_clean", 0.0015))
            + float(wear.get("player_repair_taps", 80)) * float(wear.get("tap_health", 0.0003))
        )
        self.fleet_upkeep = (
            float(wear.get("fleet_wash_seconds", 20)) * float(wear.get("fleet_clean_per_second", 0.0016667))
            + float(wear.get("fleet_repair_seconds", 150)) * float(wear.get("fleet_health_per_second", 0.00033333))
        )
        self.fleet_growth = float(balance.get("fleet_growth", 1.15))
        self.trade_share = float(balance.get("trade_in_share", 0.5))
        self.districts = [district for city in self.cities for district in city["districts"]]
        self.franchise = 1.0
        self.lifetime = 0.0
        self.time = 0.0
        self.log = []
        # Ключевые моменты: (время, текст). Первые разы — только один раз за всю игру.
        self.milestones = []
        self.seen = set()
        self.runs = 1
        self.reset_run()

    def reset_run(self):
        self.captured = {}
        self.car = 0
        self.rented = False
        self.owned_cars = set()
        self.levels = {item["id"]: 0 for item in self.upgrades}
        self.home_capacity = int(self.balance.get("garage_start", 5))
        self.expansions = list(self.balance.get("garage_expansions", []))
        self.garage = []
        self.team = 0
        self.open_districts = set()
        self.open_regions = set(item["id"] for item in self.regions if item.get("home"))
        self.owned_competitors = set()
        # id соперника -> цена выкупа после сдачи; id -> секунд дуэли с ним.
        self.surrendered = {}
        self.rival_age = {}
        self.ad_boost = 0.0
        self.ad_until = 0.0
        self.coins = 0.0
        self.taps = 0
        self.last_progress = self.time

    def mark(self, key, text):
        if key in self.seen:
            return
        self.seen.add(key)
        self.milestones.append((self.time, text))

    # --- доход -------------------------------------------------------------

    def multiplier(self):
        district = 1.0 + sum(item["income_bonus"] for item in self.districts if item["id"] in self.open_districts)
        region = 1.0 + sum(item["income_bonus"] for item in self.regions if item["id"] in self.open_regions)
        rival = 1.0 + sum(item["income_bonus"] for item in self.competitors if item["id"] in self.owned_competitors)
        rival += float(self.market.get("capture_bonus", 0.25)) * len(self.captured)
        rating = 1.0 + (KEPT_RATING - 4.0) * self.rating_per_star
        return district * region * rival * self.franchise * rating

    def capacity(self):
        islands = sum(
            int(item.get("garage_slots", 0))
            for item in self.regions
            if item["id"] in self.open_regions and not item.get("home")
        )
        return self.home_capacity + islands

    def car_income(self, index):
        return float(self.cars[index].get("driver_income", 0))

    def driver_net(self, index):
        return self.car_income(index) * DRIVER_POWER * (1.0 - DRIVER_SALARY - self.fleet_upkeep)

    def staffed(self):
        return sorted(self.garage, key=self.car_income, reverse=True)[: self.team]

    def passive(self):
        return sum(self.driver_net(index) for index in self.staffed()) * self.multiplier()

    def fleet_cost(self, index):
        return scaled_cost(float(self.cars[index]["buy_cost"]), self.fleet_growth, self.garage.count(index))

    def hire_cost(self):
        return scaled_cost(HIRE_BASE, float(self.staff.get("hire_growth", 1.5)), self.team)

    def flat_tap(self):
        return 1.0 + sum(item["tap_bonus"] * self.levels[item["id"]] for item in self.upgrades)

    def car_factor(self, index=None, rented=None):
        index = self.car if index is None else index
        rented = self.rented if rented is None else rented
        return float(self.cars[index]["tap_mult"]) * ((1.0 - self.rent_share) if rented else 1.0)

    def tap_power(self):
        ride = self.flat_tap() * self.car_factor() * self.multiplier() * (1.0 - self.tap_upkeep)
        return ride + self.passive() * self.tap_from_income

    def total_dps(self):
        return self.tap_power() * TAPS_PER_SECOND + self.passive()

    def tap_share(self):
        total = self.total_dps()
        return 1.0 if total <= 0.0 else self.tap_power() * TAPS_PER_SECOND / total

    def reputation(self):
        return self.taps // TAPS_PER_REPUTATION + self.team

    # --- рынок -------------------------------------------------------------

    def player_power(self):
        ride = self.flat_tap() * self.car_factor() * self.multiplier()
        return self.passive() + ride * float(self.market.get("player_tap_rate", 3))

    def front(self):
        for item in self.regions:
            if item["id"] in self.open_regions and item["id"] not in self.captured:
                return item["id"]
        return None

    def front_rivals(self):
        island = self.front()
        return [item for item in self.competitors if item.get("island") == island]

    def duel(self):
        return self.market.get("duel", {})

    def growth(self, item):
        duel = self.duel()
        hours = self.rival_age.get(item["id"], 0.0) / 3600.0
        return min(float(duel.get("growth_cap", 1.6)), 1.0 + hours * float(duel.get("growth_per_hour", 0.25)))

    def rival_power(self, item):
        if item["id"] in self.owned_competitors:
            return 0.0
        return float(item["power"]) * self.growth(item)

    def active_rival(self):
        for item in self.front_rivals():
            if item["id"] not in self.owned_competitors and item["id"] not in self.surrendered:
                return item
        return None

    def preview_franchise(self):
        return 1.0 + self.franchise_weight * math.sqrt(self.lifetime / self.franchise_reference)

    # --- покупки -----------------------------------------------------------

    def options(self):
        found = []
        mult = self.multiplier()
        dps = self.total_dps()
        for item in self.upgrades:
            cost = scaled_cost(item["base_cost"], item["cost_growth"], self.levels[item["id"]])
            gain = item["tap_bonus"] * self.car_factor() * mult * TAPS_PER_SECOND
            found.append(("upgrade", item["id"], item["name"], cost, gain / cost))
        ride = self.flat_tap() * mult * TAPS_PER_SECOND
        for index in range(1, len(self.cars)):
            item = self.cars[index]
            if item["id"] in self.owned_cars or index < self.car:
                continue
            if index > self.car:
                gain = ride * (self.car_factor(index, True) - self.car_factor())
                if gain > 0:
                    found.append(("rent", index, item["name"], float(item["rent_cost"]), gain / item["rent_cost"]))
            buy = float(item["buy_cost"])
            if self.rented and index == self.car:
                buy -= float(item["rent_cost"])
            gain = ride * (self.car_factor(index, False) - self.car_factor())
            if gain > 0:
                found.append(("car", index, item["name"], buy, gain / buy))
        boost = mult * (1.0 + self.tap_from_income * TAPS_PER_SECOND)
        capacity = self.capacity()
        full = len(self.garage) >= capacity
        if len(self.garage) > self.team:
            free = sorted(self.garage, key=self.car_income, reverse=True)[self.team]
            cost = self.hire_cost()
            found.append(("hire", free, "Водитель", cost, self.driver_net(free) * boost / cost))
        best_slot = None
        for index in range(1, len(self.cars)):
            if full:
                worst = min(self.garage, key=self.car_income)
                if self.car_income(index) <= self.car_income(worst):
                    continue
                cost = max(1.0, self.fleet_cost(index) - math.floor(self.cars[worst]["buy_cost"] * self.trade_share))
                gain = (self.driver_net(index) - self.driver_net(worst)) * boost
                found.append(("trade", index, self.cars[index]["name"], cost, gain / cost))
            else:
                cost = self.fleet_cost(index) + self.hire_cost()
                gain = self.driver_net(index) * boost
                found.append(("slot", index, self.cars[index]["name"], cost, gain / cost))
            slot_cost = self.fleet_cost(index) + self.hire_cost()
            if best_slot is None or self.driver_net(index) / slot_cost > best_slot[1] / best_slot[0]:
                best_slot = (slot_cost, self.driver_net(index) * boost)
        if full and self.expansions and best_slot:
            step = self.expansions[0]
            cost = float(step["cost"]) + best_slot[0]
            found.append(("expand", 0, "Расширение гаража", float(step["cost"]), best_slot[1] / cost))
        district_now = 1.0 + sum(o["income_bonus"] for o in self.districts if o["id"] in self.open_districts)
        for item in self.districts:
            if item["id"] in self.open_districts:
                continue
            gain = dps * ((district_now + item["income_bonus"]) / district_now - 1.0)
            found.append(("district", item["id"], item["name"], float(item["cost"]), gain / item["cost"]))
        rep = self.reputation()
        region_now = 1.0 + sum(o["income_bonus"] for o in self.regions if o["id"] in self.open_regions)
        for index, item in enumerate(self.regions):
            if item["id"] in self.open_regions:
                continue
            if rep < item["reputation"] or (index > 0 and self.regions[index - 1]["id"] not in self.captured):
                continue
            # Новый остров — это и бонус, и гараж, и новая борьба: открываем, как только можем.
            found.append(("region", item["id"], item["name"], float(item["cost"]), 1e9))
        for item in self.front_rivals():
            if item["id"] not in self.surrendered:
                continue
            # Сдавшегося выкупаем первым делом: это шаг к захвату острова.
            found.append(("competitor", item["id"], item["name"], self.surrendered[item["id"]], 1e8))
        return found

    def buy(self, kind, entry_id, name, cost):
        self.coins -= cost
        if kind == "upgrade":
            self.levels[entry_id] += 1
        elif kind == "rent":
            if not self.rented and self.car > 0:
                self.garage.append(self.car)
            self.car = entry_id
            self.rented = True
            self.mark("rent", "Первая аренда машины")
        elif kind == "car":
            if not self.rented and self.car > 0:
                self.garage.append(self.car)
            self.car = entry_id
            self.rented = False
            self.owned_cars.add(self.cars[entry_id]["id"])
            self.mark("car-" + name, "Своя машина: " + name)
        elif kind in ("hire", "slot"):
            if kind == "slot":
                self.garage.append(entry_id)
            self.team += 1
            self.mark("driver", "Первый водитель")
            if self.team == 10:
                self.mark("driver10", "10 водителей")
        elif kind == "trade":
            self.garage.remove(min(self.garage, key=self.car_income))
            self.garage.append(entry_id)
        elif kind == "expand":
            step = self.expansions.pop(0)
            self.home_capacity += int(step["add"])
        elif kind == "district":
            self.open_districts.add(entry_id)
        elif kind == "region":
            self.open_regions.add(entry_id)
            self.last_progress = self.time
            self.log.append((self.time, "Остров открыт", name, cost))
        elif kind == "competitor":
            self.owned_competitors.add(entry_id)
            del self.surrendered[entry_id]
            self.log.append((self.time, "Выкуп", name, cost))

    def buy_best(self):
        for _guard in range(500):
            choices = [item for item in self.options() if item[3] <= self.coins + 1e-6]
            if not choices:
                return
            kind, entry_id, name, cost, _score = max(choices, key=lambda item: item[4])
            self.buy(kind, entry_id, name, cost)

    def sell_company(self):
        new = self.preview_franchise()
        self.log.append((self.time, "Продажа компании", "франшиза ×%.1f → ×%.1f" % (self.franchise, new), self.lifetime))
        self.milestones.append((self.time, "Продажа компании №%d: франшиза ×%.1f" % (self.runs, new)))
        self.franchise = new
        self.runs += 1
        self.reset_run()

    def step(self):
        dt = step_size(self.time)
        gained = self.total_dps() * dt
        self.coins += gained
        self.lifetime += gained
        self.taps += int(TAPS_PER_SECOND * dt)
        self.time += dt
        rival = self.active_rival()
        if self.time >= self.ad_until:
            self.ad_boost = 0.0
        if rival is not None:
            self.rival_age[rival["id"]] = self.rival_age.get(rival["id"], 0.0) + dt
            self.maybe_ad(rival)
            if self.player_power() * (1.0 + self.ad_boost) >= self.rival_power(rival):
                price = math.ceil(self.rival_power(rival) * float(self.duel().get("price_seconds", 180)))
                self.surrendered[rival["id"]] = price
                self.log.append((self.time, "Сдался", rival["name"], price))
                self.mark("surrender-" + rival["id"], "Сдался: %s (забег %d)" % (rival["name"], self.runs))
        island = self.front()
        if island is not None and all(item["id"] in self.owned_competitors for item in self.front_rivals()):
            self.captured[island] = self.time
            self.last_progress = self.time
            city = next(item["city"] for item in self.regions if item["id"] == island)
            self.log.append((self.time, "Захват", city, 1.0))
            self.mark("capture-" + island, "Захват: %s (забег %d)" % (city, self.runs))
        self.buy_best()
        stalled = self.time - self.last_progress > STALL_HOURS * 3600
        if stalled and self.preview_franchise() >= self.franchise * PRESTIGE_GAIN:
            self.sell_company()

    def maybe_ad(self, rival):
        """Самая дешёвая реклама, с которой сила догоняет соперника, — если хватает денег."""
        if self.ad_boost > 0.0:
            return
        need = self.rival_power(rival)
        base = self.player_power()
        best = None
        for item in self.market.get("ads", []):
            price = math.ceil(max(float(item.get("min_price", 100)), base * float(item.get("price_seconds", 60))))
            if base * (1.0 + float(item["boost"])) >= need and price <= self.coins and (best is None or price < best[0]):
                best = (price, item)
        if best is None:
            return
        price, item = best
        self.coins -= price
        self.ad_boost = float(item["boost"])
        self.ad_until = self.time + float(item.get("duration", 300))
        self.log.append((self.time, "Реклама", item["name"], price))

    def run(self, horizon):
        while self.time < horizon and len(self.captured) < len(self.regions):
            self.step()


def main():
    hours = float(sys.argv[1]) if len(sys.argv) > 1 else 400.0
    player = Player()
    player.buy_best()
    player.run(hours * 3600)
    print("КЛЮЧЕВЫЕ МОМЕНТЫ (непрерывная игра)")
    for moment, text in player.milestones:
        print("%s\t%s" % (fmt_time(moment), text))
    print("\nСЕЙЧАС: %s, забег %d, франшиза ×%.1f, островов %d/%d, гараж %d/%d, доход %.3g/с" % (
        fmt_time(player.time), player.runs, player.franchise, len(player.captured), len(player.regions),
        len(player.garage), player.capacity(), player.total_dps(),
    ))
    if "-v" in sys.argv:
        print("\nЖУРНАЛ")
        for moment, kind, name, cost in player.log:
            print("%s\t%s\t%s\t%.3g" % (fmt_time(moment), kind, name, cost))


if __name__ == "__main__":
    main()
