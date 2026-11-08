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
	var coins_before: float = gs.coins
	check(gs.open_district("station") and gs.coins == coins_before, "район качается за ролик, монеты не списаны")
	var cheap_step: float = float(gs._find_district("station")["income_pct"])
	var top_step: float = float(gs._find_district("business")["income_pct"])
	check(top_step > cheap_step and top_step * 5.0 <= 0.7 + 0.0001, "самый прибыльный район после 5 уровня не больше +70%%")
	# Районы островов: закрыты, пока остров не куплен; платный — только покупкой.
	check(not gs.can_open_district("montmartre"), "районы Парижа ждут Европу")
	gs._opened_regions["europe"] = 1
	check(gs.can_open_district("montmartre"), "Европа открыла районы Парижа")
	check(not gs.can_open_district("champs") and gs.is_district_premium("champs"), "платный район за ролик не открыть")
	var before_premium: float = gs._district_multiplier()
	gs.grant_premium_district("champs")
	check(is_equal_approx(gs._district_multiplier() - before_premium, 4.0), "платный район: +400%% навсегда")
	gs._premium_owned.clear()
	gs._opened_regions.erase("europe")
	for i in 10:
		gs.open_district("center")
	check(gs.is_district_maxed("center") and not gs.can_open_district("center"), "у района потолок 5")

	# Все машины и вся линия тапа доступны с начала игры.
	check(gs.get_car_lock("limo") == "" and gs.can_buy_fleet("business"), "все машины доступны сразу")
	gs._tap_level = 11
	check(gs.get_tap_level_lock() == "", "линия тапа без замков")
	gs._tap_level = 0

	# Ночь: 8 часов без игры дают 42% дохода — около 3,4 часа игры.
	check(is_equal_approx(gs.get_offline_rate(), 0.42), "без игры — 42%% дохода")

	# Старое сохранение с тюнингом выше потолка обрезается.
	gs._upgrade_levels["horn"] = 40
	gs.save_game()
	gs.load_game()
	check(gs.get_upgrade_level("horn") == 5, "старый тюнинг обрезан до 5: %d" % gs.get_upgrade_level("horn"))

	print("RESULT ", "PASS" if ok else "FAIL")
	quit()
