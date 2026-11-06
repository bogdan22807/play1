extends SceneTree
## Экономика: равные бонусы за уровень, потолок уровней, машины по островам, линия тапа, ночь.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	gs.coins = 1e15

	# Тюнинг: каждый уровень любой детали — те же +10% тапа, максимум 5 уровней.
	var tap0: float = gs.get_flat_tap()
	check(gs.buy_upgrade("tires"), "купили шины")
	check(is_equal_approx(gs.get_flat_tap(), tap0 * 1.1), "шины: +10%% тапа")
	check(gs.buy_upgrade("wrap"), "купили оклейку")
	check(is_equal_approx(gs.get_flat_tap(), tap0 * 1.2), "оклейка даёт столько же, сколько шины")
	for i in 10:
		gs.buy_upgrade("tires")
	check(gs.get_upgrade_level("tires") == 5 and gs.is_upgrade_maxed("tires"), "у шин потолок 5")
	check(not gs.can_buy_upgrade("tires"), "шестой уровень не купить")
	var price_1: float = gs._scaled_cost(50.0, 3.0, 0)
	var price_2: float = gs._scaled_cost(50.0, 3.0, 1)
	check(price_2 > price_1, "каждый следующий уровень дороже")

	# Районы: уровни, одинаковый бонус за уровень у каждого района, дальние дают больше и стоят дороже.
	var mult0: float = gs._district_multiplier()
	check(gs.open_district("center"), "открыли Центр")
	check(gs.get_district_level("center") == 1, "Центр ур. 1")
	var center_step: float = gs._district_multiplier() - mult0
	check(gs.open_district("center"), "второй уровень Центра")
	check(is_equal_approx(gs._district_multiplier() - mult0, center_step * 2.0), "второй уровень даёт столько же")
	var cheap: float = gs.get_district_cost("station")
	var pricey: float = gs.get_district_cost("business")
	var cheap_step: float = float(gs._find_district("station")["income_pct"])
	var pricey_step: float = float(gs._find_district("business")["income_pct"])
	check(pricey > cheap and pricey_step > cheap_step, "дороже — значит и бонус больше")
	for i in 10:
		gs.open_district("center")
	check(gs.is_district_maxed("center") and not gs.can_open_district("center"), "у района потолок 5")

	# Машины новых классов — только с открытием своего острова.
	check(gs.get_car_lock("comfort") == "", "комфорт доступен сразу")
	check(gs.get_car_lock("business") == "europe" and not gs.can_buy_fleet("business"), "бизнес ждёт Европу")
	check(gs.get_car_lock("limo") == "north_america", "лимузин ждёт Северную Америку")
	gs._opened_regions["europe"] = 1
	check(gs.get_car_lock("business") == "" and gs.can_buy_fleet("business"), "Европа открыла бизнес")
	gs._opened_regions.erase("europe")

	# Линия тапа: до бизнеса (уровень 12) можно, дальше — только с Европой.
	gs._tap_level = 11
	check(gs.get_tap_level_lock() == "europe" and not gs.can_buy_tap_level(), "линия тапа ждёт Европу")
	gs._opened_regions["europe"] = 1
	check(gs.get_tap_level_lock() == "" and gs.can_buy_tap_level(), "с Европой линия идёт дальше")
	gs._opened_regions.erase("europe")

	# Ночь: 8 часов без игры дают 42% дохода — около 3,4 часа игры.
	check(is_equal_approx(gs.get_offline_rate(), 0.42), "без игры — 42%% дохода")

	# Старое сохранение с тюнингом выше потолка обрезается.
	gs._upgrade_levels["horn"] = 40
	gs.save_game()
	gs.load_game()
	check(gs.get_upgrade_level("horn") == 5, "старый тюнинг обрезан до 5: %d" % gs.get_upgrade_level("horn"))

	print("RESULT ", "PASS" if ok else "FAIL")
	quit()
