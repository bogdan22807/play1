extends Node
## Прокрутка пальцем: свайп по списку «Машина», начатый на кнопке покупки.
## Список едет за пальцем, после отпускания катится по инерции, покупки не происходит.
## Запуск (нужна сцена: в ней работает GameState): godot --headless res://tests/test_scroll.tscn

## Точка в координатах игры → в координаты окна (так их ждёт Input.parse_input_event).
func _win(pos: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * pos


func _ev_button(game_pos: Vector2, pressed: bool) -> void:
	var pos: Vector2 = _win(game_pos)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	Input.parse_input_event(e)

func _ev_motion(game_pos: Vector2, rel: Vector2) -> void:
	var pos: Vector2 = _win(game_pos)
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)

func _ready() -> void:
	GameState.reset_progress()
	GameState.set_company_name("Тест")
	GameState.coins = 250.0
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main._daily_layer.visible = false
	main._mentor.skip_tutorial()
	main._mentor_bubble.visible = false
	main._show_page(1)
	for i in 5:
		await get_tree().process_frame
	var scroll: ScrollContainer = main._upgrades_page.get_child(0)
	var start := Vector2(940, 700)
	_ev_button(start, true)
	var pos := start
	for i in 10:
		await get_tree().process_frame
		pos += Vector2(0, -60)
		_ev_motion(pos, Vector2(0, -60))
	await get_tree().process_frame
	var at_release: int = scroll.scroll_vertical
	_ev_button(pos, false)
	for i in 60:
		await get_tree().process_frame
	var ok: bool = at_release > 200 and scroll.scroll_vertical > at_release + 100
	ok = ok and is_equal_approx(GameState.coins, 250.0) and GameState.get_car_id() == "rickshaw"
	if not ok:
		printerr("FAIL: release=%d after=%d coins=%s car=%s" % [at_release, scroll.scroll_vertical, GameState.coins, GameState.get_car_id()])
	GameState.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	get_tree().quit(0 if ok else 1)
