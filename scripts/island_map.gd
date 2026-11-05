extends Control
## Карта мира: острова-континенты на океане, пунктир маршрута между ними.
## Рисуется кодом, картинок нет. Тап по острову — сигнал island_pressed.

signal island_pressed(island_id: String)

# >>> PALETTE
const OCEAN := Color("45a7f5")
const OCEAN_DEEP := Color("368fe0")
const WAVE := Color(1, 1, 1, 0.2)
const SAND := Color("e9d8a6")
const LOCKED := Color("d4dbe4")
# <<< PALETTE
const ROUTE := Color(1, 1, 1, 0.35)
const TAXI := Color("ffc107")

## Острова из regions.json: id, name, city, x, y (0..1), color.
var islands: Array = []
## id острова -> "captured", "front", "available", "locked".
var states: Dictionary = {}
var selected: String = ""
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


func set_data(new_islands: Array, new_states: Dictionary, new_selected: String) -> void:
	islands = new_islands
	states = new_states
	selected = new_selected
	queue_redraw()


var _redraw_left: float = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse = fmod(_pulse + delta, 2.0)
	# Пульсирующее кольцо острова — хватит 12 кадров в секунду.
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 0.08
		queue_redraw()


func _radius() -> float:
	return minf(size.x, size.y) * 0.105


func _center(info: Dictionary) -> Vector2:
	return Vector2(float(info.get("x", 0.5)) * size.x, float(info.get("y", 0.5)) * size.y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), OCEAN)
	# Глубина у краёв и волны — чтобы океан не был плоским.
	draw_rect(Rect2(Vector2(0, size.y * 0.9), Vector2(size.x, size.y * 0.1)), OCEAN_DEEP)
	for index in 28:
		var wave_pos := Vector2(fmod(index * 173.0, size.x), fmod(index * 97.0 + 40.0, size.y))
		draw_arc(wave_pos, 14.0, PI * 1.1, PI * 1.9, 8, WAVE, 3.0)
		draw_arc(wave_pos + Vector2(26, 0), 14.0, PI * 1.1, PI * 1.9, 8, WAVE, 3.0)

	for index in range(1, islands.size()):
		draw_dashed_line(_center(islands[index - 1]), _center(islands[index]), ROUTE, 4.0, 16.0)

	var font: Font = get_theme_default_font()
	var r: float = _radius()
	for raw: Variant in islands:
		var info: Dictionary = raw
		var id: String = str(info.get("id", ""))
		var state: String = str(states.get(id, "locked"))
		var center: Vector2 = _center(info)
		var land: Color = Color(str(info.get("color", "81c784")))
		if state == "locked":
			land = LOCKED
		elif state == "available":
			land = land.darkened(0.35)

		if state == "front":
			var ring: float = r * (1.25 + 0.12 * sin(_pulse * PI))
			draw_arc(center, ring, 0, TAU, 48, Color(TAXI, 0.8), 5.0)
		if id == selected:
			draw_arc(center, r * 1.45, 0, TAU, 48, Color.WHITE, 3.0)

		# Остров из трёх пятен: песок по краю, суша внутри.
		var blobs: Array = [
			[Vector2.ZERO, 1.0],
			[Vector2(r * 0.55, -r * 0.35), 0.7],
			[Vector2(-r * 0.55, r * 0.25), 0.65],
		]
		for blob: Variant in blobs:
			draw_circle(center + blob[0], r * blob[1], SAND if state != "locked" else LOCKED.lightened(0.15))
		for blob: Variant in blobs:
			draw_circle(center + blob[0], r * blob[1] * 0.82, land)

		if state == "front":
			# Маленькое такси на острове, где идёт борьба.
			var car := Rect2(center + Vector2(-r * 0.3, -r * 0.18), Vector2(r * 0.6, r * 0.32))
			draw_rect(car, TAXI)
			draw_circle(car.position + Vector2(r * 0.13, r * 0.33), r * 0.08, Color.BLACK)
			draw_circle(car.position + Vector2(r * 0.47, r * 0.33), r * 0.08, Color.BLACK)
		elif state == "captured":
			_draw_text(font, center + Vector2(0, r * 0.15), "★", 54, Color("ffd54a"))

		var title: String = str(info.get("name", id))
		_draw_text(font, center + Vector2(0, r * 1.45), title, 30, Color.WHITE)
		_draw_text(font, center + Vector2(0, r * 1.45 + 32), _state_text(state, info), 22, _state_color(state))


func _state_text(state: String, info: Dictionary) -> String:
	match state:
		"captured":
			return "ваш"
		"front":
			return "борьба · %s" % str(info.get("city", ""))
		"available":
			return "можно открыть"
		_:
			return "закрыт"


func _state_color(state: String) -> Color:
	match state:
		"captured":
			return Color("ffd54a")
		"front":
			return TAXI
		"available":
			return Color("3ddc84")
		_:
			return Color(1, 1, 1, 0.55)


func _draw_text(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = 360.0
	var pos := Vector2(at.x - width / 2.0, at.y)
	draw_string(font, pos + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0, 0, 0, 0.6))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = false
	var at := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		# Выбираем по отпусканию: потянул пальцем — это прокрутка страницы, а не выбор острова.
		pressed = not mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		at = mouse.position
	if not pressed or not Rect2(Vector2.ZERO, size).has_point(at):
		return
	var best: String = ""
	var best_distance: float = _radius() * 1.6
	for raw: Variant in islands:
		var distance: float = at.distance_to(_center(raw))
		if distance < best_distance:
			best_distance = distance
			best = str(raw.get("id", ""))
	if best != "":
		accept_event()
		island_pressed.emit(best)
