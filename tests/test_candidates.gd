extends SceneTree
## Кандидаты: всегда трое разных — два парня и девушка; имена не кончаются даже у огромной команды.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func genders(gs: Node) -> Array:
	return gs.get_candidates().map(func(p: Variant) -> bool: return bool(p.get("female", false)))


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	check(gs.get_candidates().size() == 3, "три кандидата")
	check(genders(gs) == [false, false, true], "два парня и девушка: %s" % str(genders(gs)))

	# Огромная команда: 200 человек — имена всё равно разные.
	var used: Dictionary = {}
	for i in 200:
		var person: Dictionary = gs._make_candidate(i % 3 == 2)
		person["uid"] = i + 1
		gs._team.append(person)
		used[str(person["name"])] = true
	check(used.size() == 200, "у 200 водителей разные имена: %d" % used.size())
	check(not used.has("Новичок"), "без безликих «Новичков»")
	gs.refresh_candidates()
	var names: Dictionary = {}
	for p: Variant in gs.get_candidates():
		names[str(p["name"])] = true
		check(not used.has(str(p["name"])), "кандидат не повторяет имя из команды")
	check(names.size() == 3, "три разных кандидата")
	check(genders(gs) == [false, false, true], "после «позвать других» — снова двое и одна")

	# Нанятого заменяет кандидат того же пола.
	gs._team.clear()
	gs.coins = 1e12
	gs.buy_fleet("city_taxi")
	var hired_name: String = str(gs.get_candidates()[2]["name"])
	check(gs.hire(2), "наняли девушку")
	check(genders(gs) == [false, false, true], "на её место пришла другая девушка")
	check(str(gs.get_candidates()[2]["name"]) != hired_name, "новый кандидат — другой человек")

	# Старое сохранение с тремя «Новичками» получает нормальных кандидатов.
	gs._candidates = [{"name": "Новичок", "stars": 1, "trait": "none"}, {"name": "Новичок", "stars": 1, "trait": "none"}, {"name": "Новичок", "stars": 1, "trait": "none"}]
	gs.save_game()
	gs.load_game()
	check(gs.get_candidates().size() == 3 and str(gs.get_candidates()[0]["name"]) != "Новичок", "старые «Новички» заменены")
	check(genders(gs) == [false, false, true], "и снова двое и одна")
	# Звёзды 1–5: потолок +40% к доходу и 10% зарплаты, чем выше — тем реже.
	var best: Dictionary = {"name": "Тест", "stars": 5, "trait": "racer"}
	check(gs.get_driver_power(best) <= 1.4001 and gs.get_driver_power(best) >= 1.39, "5★ гонщик — ровно +40%%: %s" % gs.get_driver_power(best))
	check(gs.get_salary_share({"stars": 5, "trait": "greedy"}) <= 0.1001, "зарплата не выше 10%%")
	var chances: Array = gs._staff["stars"].map(func(s: Variant) -> float: return float(s["chance"]))
	check(chances.size() == 5, "пять звёзд")
	for i in range(1, chances.size()):
		check(chances[i] < chances[i - 1], "чем выше звёзды, тем реже")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit()
