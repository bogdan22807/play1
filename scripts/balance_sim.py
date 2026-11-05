#!/usr/bin/env python3
"""Симуляция игрока, который покупает самую выгодную вещь.

Читает те же JSON, что и игра, и повторяет формулы цены, тапа, дохода и репутации.
"""

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
TAPS_PER_SECOND = 4.0
TAPS_PER_REPUTATION = 20
# Игрок выбирает лучшего из трёх кандидатов: считаем водителя чуть выше среднего.
DRIVER_POWER = 1.3
DRIVER_SALARY = 0.24
HIRE_BASE = 100.0
DT = 1.0
HORIZON = 7 * 3600


def load(name):
    with (DATA / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def scaled_cost(base, growth, owned):
    price = math.floor(base * (growth ** owned) + 0.000001)
    return 1.0 if price < 1.0 else float(price)


def fmt_time(seconds):
    if seconds is None:
        return "не куплено"
    seconds = int(seconds)
    hours, rest = divmod(seconds, 3600)
    minutes, secs = divmod(rest, 60)
    if hours:
        return "%d ч %02d мин" % (hours, minutes)
    if minutes:
        return "%d мин %02d с" % (minutes, secs)
    return "%d с" % secs


class Player:
    def __init__(self):
        self.upgrades = load("upgrades.json")
        self.staff = load("drivers.json")
        self.cities = load("cities.json")
        self.regions = load("regions.json")
        self.competitors = load("competitors.json")
        balance = load("balance.json")
        self.tap_from_income = float(balance.get("tap_from_income", 0.01))
        self.rent_share = float(balance.get("car_rent_share", 0.3))
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
        self.cars = load("cars.json")
        # Индекс машины, на которой ездим, и арендована ли она.
        self.car = 0
        self.rented = False
        self.owned_cars = set()
        self.levels = {item["id"]: 0 for item in self.upgrades}
        self.fleet_growth = float(balance.get("fleet_growth", 1.15))
        self.trade_share = float(balance.get("trade_in_share", 0.5))
        self.capacity = int(balance.get("garage_start", 5))
        self.expansions = list(balance.get("garage_expansions", []))
        # Гараж — индексы машин, команда — сколько нанято (сидят на лучших машинах).
        self.garage = []
        self.team = 0
        self.districts = []
        for city in self.cities:
            for district in city["districts"]:
                self.districts.append(district)
        self.open_districts = set()
        self.open_regions = set()
        self.owned_competitors = set()
        self.coins = 0.0
        self.lifetime = 0.0
        self.taps = 0
        self.time = 0.0
        self.franchise = 1.0
        self.log = []

    def multiplier(self):
        district = 1.0 + sum(
            item["income_bonus"] for item in self.districts if item["id"] in self.open_districts
        )
        region = 1.0 + sum(
            item["income_bonus"] for item in self.regions if item["id"] in self.open_regions
        )
        rival = 1.0 + sum(
            item["income_bonus"] for item in self.competitors if item["id"] in self.owned_competitors
        )
        return district * region * rival * self.franchise

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
        power = 1.0
        for item in self.upgrades:
            power += item["tap_bonus"] * self.levels[item["id"]]
        return power

    def car_factor(self, index=None, rented=None):
        index = self.car if index is None else index
        rented = self.rented if rented is None else rented
        mult = float(self.cars[index]["tap_mult"]) if self.cars else 1.0
        return mult * ((1.0 - self.rent_share) if rented else 1.0)

    def tap_power(self):
        ride = self.flat_tap() * self.car_factor() * self.multiplier() * (1.0 - self.tap_upkeep)
        return ride + self.passive() * self.tap_from_income

    def reputation(self):
        return self.taps // TAPS_PER_REPUTATION + self.team

    def total_dps(self):
        return self.tap_power() * TAPS_PER_SECOND + self.passive()

    def tap_share(self):
        total = self.total_dps()
        if total <= 0.0:
            return 1.0
        return self.tap_power() * TAPS_PER_SECOND / total

    def options(self):
        found = []
        mult = self.multiplier()
        dps = self.total_dps()
        for item in self.upgrades:
            owned = self.levels[item["id"]]
            cost = scaled_cost(item["base_cost"], item["cost_growth"], owned)
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
        full = len(self.garage) >= self.capacity
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
            # Слот за расширением: та же машина с водителем, но плюс цена расширения.
            slot_cost = self.fleet_cost(index) + self.hire_cost()
            if best_slot is None or self.driver_net(index) / slot_cost > best_slot[1] / best_slot[0]:
                best_slot = (slot_cost, self.driver_net(index) * boost)
        if full and self.expansions and best_slot:
            step = self.expansions[0]
            cost = float(step["cost"]) + best_slot[0]
            found.append(("expand", 0, "Расширение гаража", float(step["cost"]), best_slot[1] / cost))
        for item in self.districts:
            if item["id"] in self.open_districts:
                continue
            bonus = item["income_bonus"]
            current = 1.0 + sum(
                other["income_bonus"] for other in self.districts if other["id"] in self.open_districts
            )
            ratio = (current + bonus) / current
            gain = dps * (ratio - 1.0)
            found.append(("district", item["id"], item["name"], float(item["cost"]), gain / item["cost"] if item["cost"] else 0.0))
        rep = self.reputation()
        for item in self.regions:
            if item["id"] in self.open_regions:
                continue
            if rep < item["reputation"]:
                continue
            current = 1.0 + sum(
                other["income_bonus"] for other in self.regions if other["id"] in self.open_regions
            )
            ratio = (current + item["income_bonus"]) / current
            gain = dps * (ratio - 1.0)
            found.append(("region", item["id"], item["name"], float(item["cost"]), gain / item["cost"] if item["cost"] else 0.0))
        for item in self.competitors:
            if item["id"] in self.owned_competitors:
                continue
            current = 1.0 + sum(
                other["income_bonus"] for other in self.competitors if other["id"] in self.owned_competitors
            )
            ratio = (current + item["income_bonus"]) / current
            gain = dps * (ratio - 1.0)
            cost = float(item["base_cost"])
            found.append(("competitor", item["id"], item["name"], cost, gain / cost if cost else 0.0))
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
            self.log.append((self.time, "Аренда", name, cost))
        elif kind == "car":
            if not self.rented and self.car > 0:
                self.garage.append(self.car)
            self.car = entry_id
            self.rented = False
            self.owned_cars.add(self.cars[entry_id]["id"])
            self.log.append((self.time, "Машина", name, cost))
        elif kind == "hire":
            self.team += 1
            if self.team == 1:
                self.log.append((self.time, "Водитель", "первый", cost))
        elif kind == "slot":
            self.garage.append(entry_id)
            self.team += 1
            if self.team == 1:
                self.log.append((self.time, "Водитель", "первый", cost))
            self.log.append((self.time, "В парк", name, cost)) if len(self.garage) <= 2 else None
        elif kind == "trade":
            self.garage.remove(min(self.garage, key=self.car_income))
            self.garage.append(entry_id)
        elif kind == "expand":
            step = self.expansions.pop(0)
            self.capacity += int(step["add"])
            self.log.append((self.time, "Гараж", "мест: %d" % self.capacity, cost))
        elif kind == "district":
            self.open_districts.add(entry_id)
            self.log.append((self.time, "Район", name, cost))
        elif kind == "region":
            self.open_regions.add(entry_id)
            self.log.append((self.time, "Регион", name, cost))
        elif kind == "competitor":
            self.owned_competitors.add(entry_id)
            self.log.append((self.time, "Выкуп", name, cost))

    def buy_best(self):
        bought = False
        while True:
            choices = [item for item in self.options() if item[3] <= self.coins + 1e-6]
            if not choices:
                break
            kind, entry_id, name, cost, _score = max(choices, key=lambda item: item[4])
            self.buy(kind, entry_id, name, cost)
            bought = True
        return bought

    def step(self):
        gained = self.total_dps() * DT
        self.coins += gained
        self.lifetime += gained
        self.taps += int(TAPS_PER_SECOND * DT)
        self.time += DT
        self.buy_best()

    def run(self):
        shares = {}
        prestige_at = None
        marks = {120: None, 1800: None, 3600: None, 7200: None, 3 * 3600: None, 4 * 3600: None, 5 * 3600: None, 6 * 3600: None}
        while self.time < HORIZON:
            self.step()
            preview = 1.0 + 0.5 * math.sqrt(self.lifetime / 1000000.0)
            if prestige_at is None and preview >= self.franchise * 1.1:
                prestige_at = self.time
                self.log.append((self.time, "Престиж", "кнопка +10%", self.lifetime))
            for mark in marks:
                if marks[mark] is None and self.time >= mark:
                    marks[mark] = (self.tap_share(), self.total_dps(), self.passive(), self.lifetime, self.reputation())
        return prestige_at, marks


def main():
    player = Player()
    # Стартовые покупки на нулевой секунде не из чего делать.
    player.buy_best()
    prestige_at, marks = player.run()
    print("ПОКУПКИ")
    print("время\tтип\tназвание\tцена")
    for moment, kind, name, cost in player.log:
        print("%s\t%s\t%s\t%.0f" % (fmt_time(moment), kind, name, cost))
    print("\nДОЛЯ ТАПОВ")
    for mark, info in marks.items():
        if info is None:
            continue
        share, dps, passive, lifetime, rep = info
        print(
            "%s\tтапы %.1f%%\tдоход %.2f/с\tпассив %.2f/с\tзаработано %.0f\tрепутация %d"
            % (fmt_time(mark), share * 100.0, dps, passive, lifetime, rep)
        )
    print("престиж +10%:", fmt_time(prestige_at))
    print("районы", len(player.open_districts), "/", len(player.districts))
    print("регионы", len(player.open_regions), "/", len(player.regions))
    print("конкуренты", len(player.owned_competitors))
    print("гараж", len(player.garage), "/", player.capacity, " водителей", player.team)
    print("машины в парке:", ", ".join(sorted(set(player.cars[i]["name"] for i in player.garage))))


if __name__ == "__main__":
    main()
