extends Node
## Дядя Бун — старый таксист-наставник. Ведёт обучение по шагам из data/mentor.json,
## потом шутит и подсказывает по событиям. Экран только слушает сигналы и рисует облачко.
##
## Фазы шага: "say" — дед говорит, "task" — игрок выполняет задание,
## "praise" — дед хвалит и выдаёт награду, "wait" — шаг ждёт своего момента
## (машина испачкалась, водитель устал).

## Показать реплику. kind: "step" — шаг обучения, "praise" — похвала, "quip" — шутка или совет.
signal said(text: String, kind: String)
## Плашка с заданием. Пустой текст — спрятать.
signal task_changed(text: String, reward: float)
## Подсветить вкладку (-1 — ничего).
signal highlight_tab(index: int)

const DATA_PATH := "res://data/mentor.json"

var gs: Node
var _data: Dictionary = {}
var _steps: Array = []
## Внутренние часы: считаем секунды тиков, чтобы советы не сыпались подряд.
var _clock: float = 0.0
var _quiet_until: float = 0.0
var _joke_timer: float = 0.0
var _prev_broken: int = 0
var _prev_rating_ok: bool = true
var _prev_garage_full: bool = false
var _prev_tired: int = 0


func setup(state: Node) -> void:
	gs = state
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			_data = parsed
	var steps: Variant = _data.get("steps", [])
	_steps = steps if typeof(steps) == TYPE_ARRAY else []
	_ensure_state()
	_remember_now()


## Новый игрок — с первого шага. Тот, кто уже играл до появления деда, — без обучения:
## иначе награды за давно сделанные шаги посыпались бы разом.
func _ensure_state() -> void:
	if not gs.mentor.is_empty():
		return
	var veteran: bool = gs.lifetime_earned > 1000.0 or not gs.get_team().is_empty()
	gs.mentor = {"step": _steps.size() if veteran else 0, "phase": "say", "tips": true, "base": 0.0, "visited": false}


func _remember_now() -> void:
	_prev_broken = gs.get_broken_count()
	_prev_rating_ok = gs.get_rating() >= 3.5
	_prev_garage_full = gs.is_garage_full()
	_prev_tired = gs.get_tired_count()


func mentor_name() -> String:
	return str(_data.get("name", "Дядя Бун"))


func is_tutorial_done() -> bool:
	return int(gs.mentor.get("step", 0)) >= _steps.size()


func get_step_index() -> int:
	return int(gs.mentor.get("step", 0))


func get_phase() -> String:
	return str(gs.mentor.get("phase", "say"))


func tips_on() -> bool:
	return bool(gs.mentor.get("tips", true))


func set_tips(on: bool) -> void:
	gs.mentor["tips"] = on
	gs.save_game()


func current_step() -> Dictionary:
	var index: int = get_step_index()
	if index < 0 or index >= _steps.size():
		return {}
	return _steps[index]


## Начать или продолжить обучение. Вызывается, когда у компании появилось название.
func begin() -> void:
	if gs == null or not gs.has_company_name():
		return
	if is_tutorial_done():
		task_changed.emit("", 0.0)
		highlight_tab.emit(-1)
		return
	if get_phase() == "praise":
		_advance()
		return
	_enter_step()


func skip_tutorial() -> void:
	gs.mentor["step"] = _steps.size()
	gs.mentor["phase"] = "say"
	task_changed.emit("", 0.0)
	highlight_tab.emit(-1)
	gs.save_game()


func restart_tutorial() -> void:
	gs.mentor["step"] = 0
	gs.mentor["phase"] = "say"
	gs.save_game()
	begin()


## Игрок нажал кнопку в облачке.
func acknowledge() -> void:
	if is_tutorial_done():
		return
	match get_phase():
		"praise":
			_advance()
		"say":
			if str(current_step().get("goal", "")) == "next":
				_complete()
			else:
				gs.mentor["phase"] = "task"
				gs.save_game()


## Игрок открыл вкладку — для заданий «загляни туда-то».
func notify_page(page: int) -> void:
	var step: Dictionary = current_step()
	if step.is_empty() or str(step.get("goal", "")) != "visit" or get_phase() == "wait":
		return
	if int(step.get("page", -1)) == page:
		gs.mentor["visited"] = true
		check()


## Раз в секунду: проверка задания, реакции на события, редкие шутки.
func tick() -> void:
	_clock += 1.0
	check()
	if not is_tutorial_done() or not tips_on():
		_remember_now()
		return
	var broken: int = gs.get_broken_count()
	var rating_ok: bool = gs.get_rating() >= 3.5
	var garage_full: bool = gs.is_garage_full()
	var tired: int = gs.get_tired_count()
	if broken > _prev_broken:
		_quip("car_broken")
	elif _prev_rating_ok and not rating_ok:
		_quip("rating_drop")
	elif garage_full and not _prev_garage_full and not gs.get_team().is_empty():
		_quip("garage_full")
	elif tired > 0 and _prev_tired == 0 and not gs.is_helper_on("dispatcher"):
		_quip("tired")
	_remember_now()
	_joke_timer += 1.0
	if _joke_timer >= float(_data.get("joke_every_seconds", 240)):
		_joke_timer = 0.0
		var jokes: Variant = _data.get("jokes", [])
		if typeof(jokes) == TYPE_ARRAY and not jokes.is_empty() and _clock >= _quiet_until:
			_say_quip(str(jokes[randi() % jokes.size()]))


## Событие снаружи: поймали на пакости, захватили город, вернулся в игру.
func on_event(event: String) -> void:
	if is_tutorial_done() and tips_on():
		_quip(event)


func check() -> void:
	if gs == null or is_tutorial_done() or not gs.has_company_name():
		return
	var step: Dictionary = current_step()
	var phase: String = get_phase()
	if phase == "wait":
		if _when_met(step):
			_enter_step()
		return
	if phase == "praise" or str(step.get("goal", "")) == "next":
		return
	if _goal_met(step):
		_complete()


func _enter_step() -> void:
	var step: Dictionary = current_step()
	if step.is_empty():
		task_changed.emit("", 0.0)
		highlight_tab.emit(-1)
		return
	gs.mentor["visited"] = false
	if step.has("when") and not _when_met(step):
		gs.mentor["phase"] = "wait"
		task_changed.emit("", 0.0)
		highlight_tab.emit(-1)
		gs.save_game()
		return
	gs.mentor["phase"] = "say"
	gs.mentor["base"] = gs.get_run_earned()
	gs.save_game()
	said.emit(_fill(str(step.get("say", ""))), "step")
	task_changed.emit(str(step.get("task", "")), float(step.get("reward", 0)))
	highlight_tab.emit(int(step.get("tab", -1)))


func _when_met(step: Dictionary) -> bool:
	match str(step.get("when", "")):
		"dirty":
			return gs.get_my_clean() < 0.6
		"tired":
			return gs.get_tired_count() > 0
		_:
			return true


func _goal_met(step: Dictionary) -> bool:
	match str(step.get("goal", "")):
		"earn":
			return gs.get_run_earned() - float(gs.mentor.get("base", 0)) >= float(step.get("amount", 0))
		"rent", "tap_level":
			return gs.get_tap_level() >= 1
		"wash":
			return gs.get_my_clean() >= 0.99
		"hire":
			return not gs.get_team().is_empty()
		"shift":
			return gs.get_tired_count() == 0
		"visit":
			return bool(gs.mentor.get("visited", false))
	return false


func _complete() -> void:
	var step: Dictionary = current_step()
	var reward: float = float(step.get("reward", 0))
	gs.grant_reward(reward)
	var praise: String = _fill(str(step.get("praise", "")))
	if praise == "":
		gs.mentor["phase"] = "praise"
		_advance()
		return
	gs.mentor["phase"] = "praise"
	gs.save_game()
	task_changed.emit("", 0.0)
	highlight_tab.emit(-1)
	if reward > 0.0:
		praise += "\nНаграда: +%s" % gs.format_money(reward)
	said.emit(praise, "praise")


func _advance() -> void:
	gs.mentor["step"] = get_step_index() + 1
	gs.mentor["phase"] = "say"
	gs.save_game()
	if is_tutorial_done():
		task_changed.emit("", 0.0)
		highlight_tab.emit(-1)
		_quiet_until = _clock + float(_data.get("tip_cooldown_seconds", 60))
		return
	_enter_step()


func _quip(event: String) -> void:
	if _clock < _quiet_until:
		return
	var events: Variant = _data.get("events", {})
	if typeof(events) != TYPE_DICTIONARY:
		return
	var lines: Variant = events.get(event, [])
	if typeof(lines) != TYPE_ARRAY or lines.is_empty():
		return
	_say_quip(str(lines[randi() % lines.size()]))


func _say_quip(text: String) -> void:
	_quiet_until = _clock + float(_data.get("tip_cooldown_seconds", 60))
	_joke_timer = 0.0
	said.emit(_fill(text), "quip")


func _fill(text: String) -> String:
	var company: String = str(gs.company_name) if str(gs.company_name) != "" else "ваша компания"
	return text.replace("{company}", company)
