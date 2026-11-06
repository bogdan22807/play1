extends SceneTree
## Помощники: мойщик, механик, диспетчер, их доля дохода, вкл/выкл, офлайн-доход, сохранение.

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
	gs.coins = 1e7
	gs.buy_fleet("city_taxi")
	gs.buy_fleet("old_sedan")
	gs.hire(0)
	gs.hire(0)
	check(is_equal_approx(gs.get_offline_rate(), 0.42), "без диспетчера офлайн 42%%: %s" % gs.get_offline_rate())
	var base: float = gs.get_income_per_second()

	check(gs.hire_helper("washer") and gs.is_helper_on("washer"), "наняли мойщика")
	check(not gs.can_hire_helper("washer"), "второй раз не нанять")
	check(is_equal_approx(gs.get_income_per_second(), base * 0.96), "мойщик берёт 4%")
	check(is_equal_approx(gs.get_helper_fee_per_second(), base * 0.04), "видно, сколько уходит помощникам")

	# Мойщик не даёт машинам стать грязнее половины.
	for i in 900:
		gs._tick_second(1.0)
	var dirty: int = 0
	for car: Variant in gs.get_garage():
		if float(car["clean"]) < 0.49:
			dirty += 1
	check(dirty == 0, "парк чистый с мойщиком")
	gs._my_clean = 0.3
	gs._run_helpers(1.0)
	check(gs.get_my_clean() == 1.0, "мойщик помыл и вашу")

	# Механик чинит по одной, начиная с худшей.
	gs.hire_helper("mechanic")
	var cars: Array = gs.get_garage()
	cars[0]["health"] = 0.2
	cars[1]["health"] = 0.4
	gs._my_health = 1.0
	gs._run_helpers(1.0)
	check(is_equal_approx(float(cars[0]["health"]), 0.21) and is_equal_approx(float(cars[1]["health"]), 0.4), "чинит самую убитую: %s / %s" % [cars[0]["health"], cars[1]["health"]])
	for i in 100:
		gs._run_helpers(1.0)
	check(float(cars[0]["health"]) >= 0.6 and float(cars[1]["health"]) >= 0.6, "довёл обе до 60%")

	# Диспетчер меняет смены и поднимает офлайн.
	gs.hire_helper("dispatcher")
	for person: Variant in gs.get_team():
		person["hours"] = 9.0
	gs._run_helpers(1.0)
	check(gs.get_tired_count() == 0, "диспетчер сменил уставших")
	check(is_equal_approx(gs.get_offline_rate(), 0.52), "с диспетчером офлайн 52%%: %s" % gs.get_offline_rate())
	check(is_equal_approx(gs.get_helper_fee_share(), 0.15), "все трое берут 15%")
	check(gs.is_achievement_done("boss"), "достижение «Сам себе начальник»")

	# Выключили — не работает и не берёт денег.
	check(gs.set_helper_on("washer", false) and not gs.is_helper_on("washer") and gs.is_helper_hired("washer"), "мойщик выключен")
	check(is_equal_approx(gs.get_helper_fee_share(), 0.11), "выключенный не берёт долю")
	gs._my_clean = 0.3
	gs._run_helpers(1.0)
	check(gs.get_my_clean() == 0.3, "выключенный не моет")

	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(gs2.is_helper_hired("washer") and not gs2.is_helper_on("washer") and gs2.is_helper_on("mechanic"), "помощники сохранились")

	gs2.reset_progress()
	check(gs2.get_hired_helper_count() == 0, "сброс увольняет помощников")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
