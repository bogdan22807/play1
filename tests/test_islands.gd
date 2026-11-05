extends SceneTree
## Острова: фронт борьбы, открытие по порядку после захвата, конкуренты острова, бонусы, сохранение.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _make_state() -> Node:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	return gs


func _capture_front(gs: Node) -> void:
	for raw: Variant in gs.get_competitors():
		gs._owned_competitors[str(raw["id"])] = 1
	gs._tick_market()


func _init() -> void:
	var gs := _make_state()
	await process_frame
	gs.reset_progress()
	gs.reputation = 100000

	var islands: Array = gs.get_regions()
	check(islands.size() == 6 and islands[0]["id"] == "asia", "6 островов, первый — Азия")
	check(gs.is_region_open("asia") and gs.get_front_island() == "asia", "Азия открыта и идёт борьба")
	check(gs.get_front_city() == "Бангкок", "город фронта — Бангкок")
	check(gs.get_competitors().size() == 3, "у Азии три конкурента")
	for island: Variant in islands:
		check(gs.get_island_competitors(str(island["id"])).size() == 3, "три конкурента на острове %s" % island["id"])

	gs.coins = 1e18
	check(not gs.can_open_region("europe"), "Европа закрыта до захвата Азии")
	var events: Array = []
	gs.island_captured.connect(func(island: String, text: String) -> void: events.append([island, text]))
	var mult: float = gs.get_income_multiplier()
	_capture_front(gs)
	check(gs.is_island_captured("asia") and gs.is_home_captured(), "Азия захвачена")
	check(events.size() == 1 and str(events[0][1]).contains("Европа"), "поздравление зовёт в Европу")
	check(gs.get_front_island() == "" and is_equal_approx(gs.get_market_share(), 1.0), "борьбы нет, пока не открыт новый остров")
	check(gs.get_income_multiplier() > mult, "бонус за захват")
	check(not gs.can_open_region("africa"), "Африка — только после Европы")
	check(gs.get_region_block_reason("africa").contains("Париж"), "причина: сначала Париж")

	var garage_before: int = gs.get_garage_capacity()
	check(gs.open_region("europe"), "открыли Европу")
	check(gs.get_garage_capacity() == garage_before + 20 and gs.get_island_garage_slots() == 20, "в Европе свой гараж на 20 машин")
	check(gs.get_front_island() == "europe" and gs.get_front_city() == "Париж", "фронт — Париж")
	var europe_ids: Array = []
	for raw: Variant in gs.get_competitors():
		europe_ids.append(raw["id"])
	check(europe_ids.has("baguette") and not europe_ids.has("wolf"), "на рынке конкуренты Европы")
	check(gs.get_competitor_power("baguette") > gs._find_def(gs._competitor_defs, "lotus")["power"], "европейцы сильнее азиатов")
	check(gs.get_market_share() < 0.5, "в Европе начинаем с нуля")

	_capture_front(gs)
	check(gs.get_captured_count() == 2, "два острова наши")
	for id in ["africa", "south_america", "north_america", "oceania"]:
		check(gs.open_region(id), "открыли %s" % id)
		_capture_front(gs)
	check(gs.get_captured_count() == 6, "весь мир наш")
	check(gs.get_island_garage_slots() == 100, "гаражи на пяти островах: 100 мест")
	check(str(events[events.size() - 1][1]).contains("весь мир"), "финальное поздравление")
	check(gs.is_achievement_done("whole_world"), "достижение «Такси всего мира»")

	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(gs2.get_captured_count() == 6 and gs2.is_region_open("oceania"), "острова сохранились")

	# Старое сохранение: захват был одним флагом.
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"coins": 0, "home_captured": true}))
	file.close()
	var gs3 := _make_state()
	await process_frame
	check(gs3.is_island_captured("asia") and gs3.get_front_island() == "", "старый захват стал захватом Азии")

	gs3.reset_progress()
	check(gs3.get_captured_count() == 0 and gs3.get_front_island() == "asia", "сброс: снова Азия")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
