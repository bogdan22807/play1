extends SceneTree
## Все покупки разом: тысячи случайных попыток с разным кошельком.
## Если «можно купить» — покупка проходит и списывает ровно показанную цену.
## Если нельзя — ничего не меняется. Деньги никогда не уходят в минус.

var ok := true
var failures: int = 0


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		failures += 1
		if failures <= 20:
			printerr("FAIL: ", what)


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	gs.set_company_name("Тест")
	seed(7)
	var car_ids: Array = []
	for raw: Variant in gs.get_cars():
		car_ids.append(str(raw["id"]))
	var upgrade_ids: Array = []
	for raw: Variant in gs.get_upgrades():
		upgrade_ids.append(str(raw["id"]))
	var helper_ids: Array = []
	for raw: Variant in gs.get_helpers():
		helper_ids.append(str(raw["id"]))
	var district_ids: Array = []
	for city: Variant in gs.get_cities():
		for raw: Variant in city.get("districts", []):
			district_ids.append(str(raw["id"]))
	var region_ids: Array = []
	for raw: Variant in gs.get_regions():
		region_ids.append(str(raw["id"]))
	var ad_ids: Array = ["flyers"]

	for attempt in 3000:
		# Кошелёк скачет от нуля до огромного, чтобы ловить границы цены.
		gs.coins = [0.0, 1.0, 99.0, 1000.0, 1e5, 1e8, 1e12, 1e16][randi() % 8] * randf_range(0.5, 1.5)
		gs.reputation = 100000
		var kind: int = randi() % 9
		var id: String = ""
		var price: float = 0.0
		var can: bool = false
		var done: bool = false
		var before: float = gs.coins
		var garage_before: int = gs.get_garage().size()
		match kind:
			0:
				id = upgrade_ids[randi() % upgrade_ids.size()]
				price = gs.get_upgrade_cost(id)
				can = gs.can_buy_upgrade(id)
				done = gs.buy_upgrade(id)
			1:
				id = car_ids[randi() % car_ids.size()]
				price = gs.get_car_rent_cost(id)
				can = gs.can_rent_car(id)
				done = gs.rent_car(id)
			2:
				id = car_ids[randi() % car_ids.size()]
				price = gs.get_car_buy_cost(id)
				can = gs.can_buy_car(id)
				done = gs.buy_car(id)
			3:
				id = car_ids[randi() % car_ids.size()]
				price = gs.get_fleet_cost(id)
				can = gs.can_buy_fleet(id)
				done = gs.buy_fleet(id)
				if done:
					check(gs.get_garage().size() <= maxi(garage_before + 1, gs.get_garage_capacity()), "парк не больше гаража")
			4:
				id = "expand"
				price = float(gs.get_next_expansion().get("cost", 0))
				can = gs.can_expand_garage()
				done = gs.expand_garage()
			5:
				id = "hire"
				var people: Array = gs.get_candidates()
				price = gs.get_hire_cost(people[0])
				can = gs.can_hire(0)
				done = gs.hire(0)
			6:
				id = helper_ids[randi() % helper_ids.size()]
				price = gs.get_helper_cost(id)
				can = gs.can_hire_helper(id)
				done = gs.hire_helper(id)
			7:
				id = district_ids[randi() % district_ids.size()]
				price = gs.get_district_cost(id)
				can = gs.can_open_district(id)
				done = gs.open_district(id)
			8:
				id = region_ids[randi() % region_ids.size()]
				price = gs.get_region_cost(id)
				can = gs.can_open_region(id)
				done = gs.open_region(id)
		var label: String = "покупка %d «%s», цена %s, было %s" % [kind, id, price, before]
		check(can == done, "можно = купилось: " + label)
		check(gs.coins >= 0.0, "деньги не в минусе: " + label)
		if done:
			# Достижения могут подкинуть награду — поэтому «не больше, чем было минус цена плюс награда».
			check(gs.coins <= before - price + 5000.0 + 0.01 and before + 0.001 >= price, "списана цена: %s, стало %s" % [label, gs.coins])
		else:
			check(is_equal_approx(gs.coins, before), "без покупки деньги не тронуты: " + label)
		if attempt % 50 == 0:
			gs._ad = {}
			# Иногда продаём машину — тоже не должно ломать покупки.
			var garage: Array = gs.get_garage()
			if not garage.is_empty():
				var model: String = str(garage[randi() % garage.size()]["model"])
				var coins_before_sale: float = gs.coins
				var value: float = gs.sell_garage_car(model)
				check(value > 0.0 and gs.coins >= coins_before_sale + value - 0.01, "продажа приносит деньги")
	print("попыток: 3000, ошибок: %d" % failures)
	gs.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
