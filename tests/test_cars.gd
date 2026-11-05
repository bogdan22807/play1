extends SceneTree
## Линия тапа: копим, покупаем уровень, тап дороже; каждые 3 уровня — новая машина.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _init() -> void:
	var gs = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	var base: float = gs.get_tap_power()
	check(gs.get_car_id() == "rickshaw" and gs.get_tap_level() == 0, "старт на рикше, уровень 0")
	check(is_equal_approx(gs.get_tap_level_cost(), 40.0), "первый уровень за $40: %s" % gs.get_tap_level_cost())
	gs.coins = 39.0
	check(not gs.can_buy_tap_level() and not gs.buy_tap_level(), "без денег не купить")
	gs.coins = 40.0
	check(gs.buy_tap_level() and gs.coins < 0.01, "купили первый уровень")
	check(gs.get_tap_power() > base * 1.2 and gs.get_car_id() == "rickshaw", "тап дороже, машина та же")
	# Через три уровня — старый седан и тап ×2.5.
	gs.coins = 1e6
	gs.buy_tap_level()
	check(gs.get_next_level_car() == "old_sedan", "следующий уровень пересадит в седан")
	gs.buy_tap_level()
	check(gs.get_car_id() == "old_sedan" and is_equal_approx(gs.get_car_tap_mult(), 2.5), "седан, тап ×2.5")
	check(is_equal_approx(gs.get_tap_power(), base * 2.5), "аренды больше нет — весь тап ваш")
	check(gs.get_owned_car_count() == 1 and gs.is_achievement_done("first_car"), "достижение за первую машину")
	# Цены растут, после лимузина линия не кончается.
	var last_cost: float = 0.0
	var growing: bool = true
	gs._tap_level = 0
	for level in 40:
		gs._tap_level = level
		var cost: float = gs.get_tap_level_cost()
		growing = growing and cost > last_cost
		last_cost = cost
	check(growing, "каждый уровень дороже предыдущего")
	gs._tap_level = 30
	check(gs.get_level_tap_mult(31) > gs.get_level_tap_mult(30), "после лимузина тап продолжает расти")
	gs._tap_level = 6
	gs._car_id = "city_taxi"
	gs.set_company_name("   Жёлтая молния   ")
	gs.save_game()
	var gs2 = load("res://autoload/game_state.gd").new()
	root.add_child(gs2)
	await process_frame
	check(gs2.get_tap_level() == 6 and gs2.get_car_id() == "city_taxi" and gs2.company_name == "Жёлтая молния", "линия сохранилась")
	# Старое сохранение: машина была арендована — уровень этой машины.
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"coins": 0, "car": "comfort", "car_rented": true}))
	file.close()
	var gs3 = load("res://autoload/game_state.gd").new()
	root.add_child(gs3)
	await process_frame
	check(gs3.get_tap_level() == 9 and gs3.get_car_id() == "comfort", "старая машина стала уровнем: %d" % gs3.get_tap_level())
	gs3.reset_progress()
	check(gs3.get_car_id() == "rickshaw" and gs3.get_tap_level() == 0, "сброс")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
