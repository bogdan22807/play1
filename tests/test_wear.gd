extends SceneTree
## Износ: тапы пачкают свою машину, парк изнашивается в работе, мойка и ремонт, сохранение.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _make_state() -> Node:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	return gs


func _init() -> void:
	var gs := _make_state()
	await process_frame
	gs.reset_progress()

	# Своя машина: тапы пачкают и ломают.
	var fresh: float = gs.get_tap_power()
	for i in 400:
		gs.tap()
	check(gs.get_my_clean() < 0.5, "после 400 тапов машина грязная: %s" % gs.get_my_clean())
	check(gs.get_tap_power() < fresh, "грязная машина приносит меньше")
	gs.coins = 1e6
	var wash: float = gs.get_my_wash_cost()
	check(wash > 0.0 and gs.wash_my_car(), "помыли свою")
	check(gs.get_my_clean() == 1.0 and gs.get_my_wash_cost() == 0.0 and not gs.can_wash_my_car(), "чистая, мыть нечего")

	# Сломанная своя машина всё равно едет на 30%.
	gs._my_health = 0.05
	check(is_equal_approx(gs.get_my_condition_mult(), 0.3), "сломанная своя едет на 30%")
	check(gs.repair_my_car() and gs.get_my_health() == 1.0, "починили свою")

	# Парк: машина с водителем изнашивается, без водителя — нет.
	gs.buy_fleet("old_sedan")
	gs.buy_fleet("old_sedan")
	gs.hire(0)
	gs.rating = 4.0
	gs._recalc_income()
	var income: float = gs.get_income_per_second()
	for i in 600:
		gs._tick_fleet_wear(1.0)
	var garage: Array = gs.get_garage()
	var worked: int = 0
	var idle: int = 0
	for car: Variant in garage:
		if float(car["clean"]) < 0.01:
			worked += 1
		elif float(car["clean"]) == 1.0:
			idle += 1
	check(worked == 1 and idle == 1, "износилась только машина с водителем")
	check(gs.get_income_per_second() < income, "грязный парк приносит меньше")
	for i in 3000:
		gs._tick_fleet_wear(1.0)
	check(gs.get_broken_count() == 1 and gs.get_income_per_second() == 0.0, "сломанная машина стоит")
	check(gs.wash_fleet() and gs.repair_fleet(), "помыли и починили парк")
	# За 60 часов водитель устал и рейтинг упал — это проверяет test_shifts. Здесь сравниваем только износ.
	gs.change_tired_shifts()
	gs.rating = 4.0
	gs._recalc_income()
	check(is_equal_approx(gs.get_income_per_second(), income), "доход вернулся")
	check(gs.get_fleet_wash_cost() == 0.0 and not gs.can_repair_fleet(), "после сервиса платить не за что")

	# Своя прошлая машина уезжает в гараж со своим износом, новая — чистая.
	gs.buy_car("old_sedan")
	for i in 200:
		gs.tap()
	var dirt: float = gs.get_my_clean()
	gs.buy_car("city_taxi")
	check(gs.get_my_clean() == 1.0, "новая своя машина чистая")
	var parked_dirty: bool = false
	for car: Variant in gs.get_garage():
		if is_equal_approx(float(car["clean"]), dirt):
			parked_dirty = true
	check(parked_dirty, "старая уехала в гараж грязной")

	# Износ сохраняется.
	for i in 100:
		gs._tick_fleet_wear(1.0)
	var avg: float = gs.get_fleet_average("clean")
	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(is_equal_approx(gs2.get_fleet_average("clean"), avg), "износ парка сохранился")
	check(is_equal_approx(gs2.get_my_clean(), gs.get_my_clean()), "износ своей сохранился")

	# Старое сохранение с гаражом из строк.
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"coins": 0, "garage": ["old_sedan", "comfort", "nope"]}))
	file.close()
	var gs3 := _make_state()
	await process_frame
	check(gs3.get_garage().size() == 2 and gs3.get_fleet_average("health") == 1.0, "старый гараж стал карточками")

	gs3.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
