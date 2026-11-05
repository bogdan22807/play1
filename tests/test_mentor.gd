extends SceneTree
## Дядя Бун: шаги обучения по порядку, ожидание момента, награды, пропуск, советы, ветераны.

var ok := true
var said: Array = []
var tasks: Array = []
var tabs: Array = []


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _make() -> Array:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	var mentor: Node = load("res://scripts/mentor.gd").new()
	root.add_child(mentor)
	return [gs, mentor]


func _listen(mentor: Node) -> void:
	said.clear()
	tasks.clear()
	tabs.clear()
	mentor.said.connect(func(text: String, kind: String) -> void: said.append([text, kind]))
	mentor.task_changed.connect(func(text: String, reward: float) -> void: tasks.append([text, reward]))
	mentor.highlight_tab.connect(func(index: int) -> void: tabs.append(index))


func _last_said() -> String:
	return "" if said.is_empty() else str(said[said.size() - 1][0])


func _init() -> void:
	var pair: Array = _make()
	var gs: Node = pair[0]
	var mentor: Node = pair[1]
	await process_frame
	gs.reset_progress()
	mentor.setup(gs)
	_listen(mentor)
	check(mentor.get_step_index() == 0 and not mentor.is_tutorial_done(), "новичок начинает с первого шага")

	mentor.begin()
	check(said.is_empty(), "без названия компании дед молчит")
	gs.set_company_name("Жёлтая молния")
	mentor.begin()
	check(_last_said().contains("Жёлтая молния") and _last_said().contains("дядя Бун"), "знакомство с названием компании")
	mentor.acknowledge()
	check(mentor.current_step()["id"] == "taps", "дальше — тапы")
	check(tabs[tabs.size() - 1] == 0, "подсвечен Город")

	# Задание «натапай $30»: награда только после цели.
	mentor.acknowledge()
	var coins_before: float = gs.coins
	for i in 10:
		gs.tap()
	mentor.check()
	check(mentor.current_step()["id"] == "taps", "ещё не набрал")
	for i in 40:
		gs.tap()
	mentor.check()
	check(mentor.get_phase() == "praise" and _last_said().contains("+$20"), "похвала с наградой")
	check(gs.coins >= coins_before + 50.0 + 20.0 - 0.01, "награда зачислена")
	mentor.acknowledge()
	check(mentor.current_step()["id"] == "rent" and tabs[tabs.size() - 1] == 1, "аренда, подсвечена Машина")

	gs.coins = 100.0
	gs.rent_car("old_sedan")
	mentor.check()
	check(mentor.get_phase() == "praise", "аренда засчитана")
	mentor.acknowledge()

	# Мойка ждёт, пока машина испачкается.
	check(mentor.current_step()["id"] == "wash" and mentor.get_phase() == "wait", "мойка ждёт грязи")
	var said_count: int = said.size()
	mentor.tick()
	check(said.size() == said_count, "пока чисто — молчит")
	for i in 300:
		gs.tap()
	mentor.tick()
	check(mentor.get_phase() == "say" and _last_said().contains("Чистота"), "испачкалась — дед подсказал")
	mentor.acknowledge()
	gs.coins = 1e6
	gs.wash_my_car()
	mentor.check()
	check(mentor.get_phase() == "praise", "помыл")
	mentor.acknowledge()

	check(mentor.current_step()["id"] == "driver", "водитель")
	gs.buy_fleet("old_sedan")
	gs.hire(0)
	mentor.check()
	mentor.acknowledge()

	check(mentor.current_step()["id"] == "shift" and mentor.get_phase() == "wait", "смена ждёт усталости")
	gs.get_team()[0]["hours"] = 9.0
	mentor.tick()
	check(mentor.get_phase() == "say", "устал — дед подсказал")
	mentor.acknowledge()
	gs.change_tired_shifts()
	mentor.check()
	mentor.acknowledge()

	check(mentor.current_step()["id"] == "rivals", "конкуренты")
	mentor.acknowledge()
	mentor.notify_page(3)
	check(mentor.current_step()["id"] == "rivals" and mentor.get_phase() == "task", "не та вкладка")
	mentor.notify_page(4)
	check(mentor.get_phase() == "praise", "заглянул на рынок")
	mentor.acknowledge()
	mentor.acknowledge()
	mentor.notify_page(3)
	mentor.acknowledge()
	check(mentor.current_step()["id"] == "bye", "прощание")
	mentor.acknowledge()
	check(mentor.is_tutorial_done(), "обучение пройдено")
	check(tasks[tasks.size() - 1][0] == "", "плашка задания спрятана")

	# Сохранение и продолжение.
	gs.save_game()
	var pair2: Array = _make()
	await process_frame
	pair2[1].setup(pair2[0])
	check(pair2[1].is_tutorial_done(), "после загрузки обучение пройдено")

	# Советы после обучения: поломка — реплика, но не чаще паузы.
	said.clear()
	mentor._quiet_until = 0.0
	gs.get_garage()[0]["health"] = 0.0
	mentor.tick()
	check(said.size() == 1 and said[0][1] == "quip", "реакция на поломку")
	mentor.on_event("caught")
	check(said.size() == 1, "пауза между советами")
	mentor._quiet_until = 0.0
	mentor.on_event("caught")
	check(said.size() == 2 and _last_said().length() > 0, "шутка про пакость")
	mentor.set_tips(false)
	mentor._quiet_until = 0.0
	mentor.on_event("captured")
	check(said.size() == 2, "советы выключены — молчит")

	# Пропуск и повтор обучения.
	mentor.restart_tutorial()
	check(mentor.get_step_index() == 0 and not mentor.is_tutorial_done(), "обучение заново")
	mentor.skip_tutorial()
	check(mentor.is_tutorial_done(), "пропуск")

	# Ветеран без истории деда — без обучения.
	gs.mentor = {}
	gs.lifetime_earned = 1e6
	var veteran: Node = load("res://scripts/mentor.gd").new()
	root.add_child(veteran)
	veteran.setup(gs)
	check(veteran.is_tutorial_done(), "старый игрок без обучения")

	gs.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
