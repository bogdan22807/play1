extends SceneTree
## Гараж, найм, раздача машин, зарплата, обмен, сохранение и перенос старых водителей.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		print("FAIL: ", what)


func _make_state() -> Node:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	return gs


func _init() -> void:
	var gs := _make_state()
	await process_frame
	gs.reset_progress()

	check(gs.get_candidates().size() == 3, "три кандидата")
	check(not gs.can_hire(0), "нельзя нанять без машины")
	gs.coins = 1e6
	check(gs.buy_fleet("old_sedan"), "купили седан в парк")
	check(gs.get_fleet_count("old_sedan") == 1, "седан в парке")
	check(gs.get_fleet_cost("old_sedan") > 1200.0, "второй седан дороже")
	var first: Dictionary = gs.get_candidates()[0]
	check(gs.hire(0), "наняли первого")
	check(gs.get_team().size() == 1 and gs.reputation >= 1, "в команде один, репутация растёт")
	check(not gs.can_hire(0), "второй не влезет — нет машины")

	var person: Dictionary = gs.get_team()[0]
	var expect: float = 5.0 * gs.get_driver_power(person) * (1.0 - gs.get_salary_share(person)) * gs.get_income_multiplier()
	check(is_equal_approx(gs.get_income_per_second(), expect), "доход = машина × сила × (1 − зарплата)")
	check(gs.get_salary_per_second() > 0.0, "зарплата считается")

	# Лучшая машина достаётся сильнейшему водителю.
	gs.buy_fleet("comfort")
	gs.hire(0)
	var cars: Dictionary = gs.get_assignments()
	var strongest: Dictionary = gs.get_team()[0]
	for p: Variant in gs.get_team():
		if gs.get_driver_power(p) > gs.get_driver_power(strongest):
			strongest = p
	check(cars[int(strongest["uid"])] == "comfort", "сильнейшему — комфорт")

	# Полный гараж: обмен худшей машины.
	while not gs.is_garage_full():
		gs.buy_fleet("city_taxi")
	check(gs.get_garage().size() == 5, "гараж на 5 мест")
	check(not gs.can_buy_fleet("old_sedan"), "в полный гараж не меняем на такую же")
	gs.coins = 1e8
	var before: int = gs.get_fleet_count("old_sedan")
	check(gs.buy_fleet("business"), "обмен на бизнес")
	check(gs.get_fleet_count("old_sedan") == before - 1 and gs.get_garage().size() == 5, "седан ушёл в обмен")
	check(gs.expand_garage() and gs.get_garage_capacity() == 10, "расширили гараж")

	# Своя прошлая машина уезжает в гараж.
	gs.buy_car("old_sedan")
	gs.buy_car("city_taxi")
	check(gs.get_fleet_count("old_sedan") == 1, "свой седан уехал в парк")

	check(gs.fire(int(gs.get_team()[0]["uid"])) and gs.get_team().size() == 1, "уволили")
	var team_names: Array = []
	for p: Variant in gs.get_team():
		team_names.append(p["name"])
	gs.save_game()

	var gs2 := _make_state()
	await process_frame
	check(gs2.get_team().size() == 1 and gs2.get_team()[0]["name"] == team_names[0], "команда сохранилась")
	check(gs2.get_garage().size() == gs.get_garage().size() and gs2.get_garage_capacity() == 10, "гараж сохранился")
	check(is_equal_approx(gs2.get_income_per_second(), gs.get_income_per_second()), "доход после загрузки тот же")

	# Старое сохранение: 3 стажёра и 1 водитель -> деньги назад.
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"coins": 10, "drivers": {"trainee": 3, "driver": 1}}))
	file.close()
	var gs3 := _make_state()
	await process_frame
	var refund: float = 30.0 + 34.0 + 40.0 + 250.0
	check(is_equal_approx(gs3.coins, 10.0 + refund), "вернули за старых водителей: %s" % gs3.coins)
	check(gs3.get_team().is_empty(), "старые водители не стали людьми")

	gs3.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
