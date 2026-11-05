extends Control
## Карта мира: острова-континенты на океане, пунктир маршрута между ними.
## Рисуется кодом, картинок нет. Тап по острову — сигнал island_pressed.
##
## У каждого острова свой силуэт, пляж, горы, лес, городок и достопримечательность.
## Всё неподвижное (океан, острова, подписи) один раз «запекается» в картинку,
## каждый кадр рисуется только пульсирующее кольцо острова, за который идёт борьба.

signal island_pressed(island_id: String)

# >>> PALETTE
const OCEAN := Color("45a7f5")
const OCEAN_DEEP := Color("368fe0")
const WAVE := Color(1, 1, 1, 0.2)
const SAND := Color("e9d8a6")
const LOCKED := Color("d4dbe4")
# <<< PALETTE
const ROUTE := Color(1, 1, 1, 0.45)
const TAXI := Color("ffc107")
const INK := Color("2a2a48")
const SNOW := Color("ffffff")
const ROCK := Color("8d8f9e")
const PALM := Color("2f8a46")
const TRUNK := Color("8d6e63")
const WINDOW := Color("fff3c4")

## Острова из regions.json: id, name, city, x, y (0..1), color.
var islands: Array = []
## id острова -> "captured", "front", "available", "locked".
var states: Dictionary = {}
var selected: String = ""
var _pulse: float = 0.0
var _redraw_left: float = 0.0
var _bake: SubViewport
var _art: Control
var _overlay: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_bake = SubViewport.new()
	_bake.disable_3d = true
	_bake.transparent_bg = false
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bake)
	_art = Control.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake.add_child(_art)
	_art.draw.connect(_draw_art)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	resized.connect(_rebake)
	_rebake()


func set_data(new_islands: Array, new_states: Dictionary, new_selected: String) -> void:
	var changed: bool = new_islands != islands or new_states != states or new_selected != selected
	islands = new_islands
	states = new_states
	selected = new_selected
	if changed:
		_rebake()


func _rebake() -> void:
	if _bake == null or size.x <= 0.0 or size.y <= 0.0:
		return
	_bake.size = Vector2i(ceili(size.x), ceili(size.y))
	_art.size = size
	_art.queue_redraw()
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	_overlay.queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse = fmod(_pulse + delta, 2.0)
	# Пульсирующее кольцо — хватит 15 кадров в секунду.
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 0.066
		_overlay.queue_redraw()


func _radius() -> float:
	return minf(size.x, size.y) * 0.115


func _center(info: Dictionary) -> Vector2:
	return Vector2(float(info.get("x", 0.5)) * size.x, float(info.get("y", 0.5)) * size.y)


func _draw_overlay() -> void:
	if _bake == null:
		return
	_overlay.draw_texture(_bake.get_texture(), Vector2.ZERO)
	var r: float = _radius()
	for raw: Variant in islands:
		var info: Dictionary = raw
		var id: String = str(info.get("id", ""))
		var center: Vector2 = _center(info)
		if str(states.get(id, "locked")) == "front":
			var ring: float = r * (1.35 + 0.1 * sin(_pulse * PI))
			_overlay.draw_arc(center, ring, 0, TAU, 48, Color(TAXI, 0.85), 5.0)
		if id == selected:
			_overlay.draw_arc(center, r * 1.55, 0, TAU, 48, Color.WHITE, 3.0)


# --- Неподвижная картина: рисуется один раз ---------------------------------------

func _draw_art() -> void:
	var c: CanvasItem = _art
	if size.x < 1.0 or size.y < 1.0:
		return
	c.draw_rect(Rect2(Vector2.ZERO, size), OCEAN)
	# Глубина: тёмные полосы у краёв и пятна поглубже.
	c.draw_rect(Rect2(Vector2(0, size.y * 0.9), Vector2(size.x, size.y * 0.1)), OCEAN_DEEP)
	for spot in [Vector2(0.12, 0.6), Vector2(0.62, 0.62), Vector2(0.35, 0.3), Vector2(0.9, 0.12)]:
		c.draw_circle(Vector2(spot.x * size.x, spot.y * size.y), size.x * 0.09, Color(OCEAN_DEEP, 0.45))
	for index in 34:
		var wave_pos := Vector2(fmod(index * 173.0, size.x), fmod(index * 97.0 + 40.0, size.y))
		c.draw_arc(wave_pos, 14.0, PI * 1.1, PI * 1.9, 8, WAVE, 3.0)
		c.draw_arc(wave_pos + Vector2(26, 0), 14.0, PI * 1.1, PI * 1.9, 8, WAVE, 3.0)

	for index in range(1, islands.size()):
		c.draw_dashed_line(_center(islands[index - 1]), _center(islands[index]), ROUTE, 5.0, 18.0)

	var font: Font = get_theme_default_font()
	var r: float = _radius()
	for raw: Variant in islands:
		var info: Dictionary = raw
		var id: String = str(info.get("id", ""))
		var state: String = str(states.get(id, "locked"))
		var center: Vector2 = _center(info)
		_draw_island(c, id, center, r, Color(str(info.get("color", "81c784"))), state)
		var title: String = str(info.get("name", id))
		_draw_text(c, font, center + Vector2(0, r * 1.45), title, 30, Color.WHITE)
		_draw_text(c, font, center + Vector2(0, r * 1.45 + 32), _state_text(state, info), 22, _state_color(state))


## Силуэт острова: несколько «пятен» своей раскладки для каждого острова.
func _blobs(id: String, r: float) -> Array:
	match id:
		"asia":
			return [[Vector2(0, 0), 1.0], [Vector2(0.6, -0.4), 0.7], [Vector2(-0.55, 0.3), 0.6], [Vector2(0.35, 0.55), 0.5]]
		"europe":
			return [[Vector2(0, 0), 0.9], [Vector2(-0.6, -0.25), 0.6], [Vector2(0.55, 0.15), 0.65], [Vector2(0.1, -0.6), 0.45]]
		"africa":
			return [[Vector2(0, -0.2), 1.0], [Vector2(0.1, 0.55), 0.7], [Vector2(-0.45, -0.5), 0.55], [Vector2(0.5, -0.35), 0.5]]
		"south_america":
			return [[Vector2(0, -0.3), 0.85], [Vector2(-0.05, 0.4), 0.7], [Vector2(0.1, 0.85), 0.45], [Vector2(0.5, -0.4), 0.5]]
		"north_america":
			return [[Vector2(0, 0), 1.0], [Vector2(-0.6, -0.45), 0.65], [Vector2(0.55, -0.35), 0.6], [Vector2(0.2, 0.6), 0.45]]
		_:
			return [[Vector2(0, 0), 0.95], [Vector2(0.55, 0.2), 0.55], [Vector2(-0.6, -0.1), 0.5], [Vector2(0.95, 0.75), 0.25]]


func _draw_island(c: CanvasItem, id: String, center: Vector2, r: float, color: Color, state: String) -> void:
	var land: Color = color
	var locked: bool = state == "locked"
	if state == "available":
		land = color.darkened(0.15)
	var blobs: Array = _blobs(id, r)
	# Мелководье, песок, суша — три слоя.
	for blob: Variant in blobs:
		c.draw_circle(center + blob[0] * r, r * blob[1] * 1.12, Color(1, 1, 1, 0.25))
	for blob: Variant in blobs:
		c.draw_circle(center + blob[0] * r, r * blob[1], SAND)
	for blob: Variant in blobs:
		c.draw_circle(center + blob[0] * r, r * blob[1] * 0.84, land)
	# Светлые и тёмные пятна на суше — рельеф.
	for blob: Variant in blobs:
		c.draw_circle(center + blob[0] * r + Vector2(-0.15, -0.15) * r * blob[1], r * blob[1] * 0.35, land.lightened(0.12))
	_draw_mountains(c, center + Vector2(-0.45, -0.35) * r, r * 0.5, land)
	_draw_palms(c, id, center, r)
	_draw_town(c, center + Vector2(0.25, 0.25) * r, r * 0.55)
	_draw_landmark(c, id, center + Vector2(-0.05, -0.05) * r, r * 0.6)
	if locked:
		# Закрытый остров видно, но он в дымке и под замком.
		for blob: Variant in blobs:
			c.draw_circle(center + blob[0] * r, r * blob[1] * 1.02, Color(LOCKED, 0.6))
		_draw_clouds(c, center + Vector2(0.45, -0.45) * r, r * 0.5)
		return
	if state == "captured":
		_draw_flag(c, center + Vector2(0.55, -0.55) * r, r * 0.5)
	elif state == "front":
		# Маленькое такси на острове, где идёт борьба.
		var car := Rect2(center + Vector2(-r * 0.75, r * 0.45), Vector2(r * 0.42, r * 0.22))
		c.draw_rect(car, TAXI)
		c.draw_rect(Rect2(car.position + Vector2(car.size.x * 0.3, -r * 0.06), Vector2(car.size.x * 0.4, r * 0.06)), INK)
		c.draw_circle(car.position + Vector2(r * 0.09, r * 0.23), r * 0.055, INK)
		c.draw_circle(car.position + Vector2(r * 0.33, r * 0.23), r * 0.055, INK)


func _draw_mountains(c: CanvasItem, at: Vector2, size_r: float, land: Color) -> void:
	for peak in [[Vector2(0, 0), 1.0], [Vector2(0.55, 0.15), 0.75]]:
		var base: Vector2 = at + peak[0] * size_r
		var h: float = size_r * 0.9 * peak[1]
		var w: float = size_r * 0.7 * peak[1]
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, h * 0.4), base + Vector2(0, -h * 0.6), base + Vector2(w, h * 0.4)]), ROCK.lerp(land, 0.25))
		c.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.3, -h * 0.28), base + Vector2(0, -h * 0.6), base + Vector2(w * 0.3, -h * 0.28)]), SNOW)


func _draw_palms(c: CanvasItem, id: String, center: Vector2, r: float) -> void:
	var spots: Array = [Vector2(-0.75, 0.15), Vector2(0.75, -0.1), Vector2(-0.2, 0.7)]
	if id == "europe" or id == "north_america":
		# Тут не пальмы, а ёлки.
		for spot: Vector2 in spots:
			var base: Vector2 = center + spot * r
			for tier in 2:
				var w: float = r * (0.16 - tier * 0.04)
				var top: Vector2 = base + Vector2(0, -r * (0.18 + tier * 0.1))
				c.draw_colored_polygon(PackedVector2Array([top + Vector2(-w, r * 0.16), top, top + Vector2(w, r * 0.16)]), PALM.darkened(0.1 * tier))
		return
	for spot: Vector2 in spots:
		var base: Vector2 = center + spot * r
		c.draw_line(base, base + Vector2(r * 0.04, -r * 0.28), TRUNK, maxf(2.0, r * 0.05))
		var top: Vector2 = base + Vector2(r * 0.04, -r * 0.28)
		for angle in [-2.6, -1.9, -1.2, -0.5]:
			var dir := Vector2(cos(angle), sin(angle))
			c.draw_line(top, top + dir * r * 0.2, PALM, maxf(2.0, r * 0.06))


func _draw_town(c: CanvasItem, at: Vector2, size_r: float) -> void:
	var heights: Array = [0.55, 0.85, 0.65, 1.0, 0.5]
	var w: float = size_r * 0.17
	for index in heights.size():
		var h: float = size_r * float(heights[index])
		var rect := Rect2(at + Vector2(index * w * 1.05 - w * 2.5, -h), Vector2(w, h))
		c.draw_rect(rect, Color("e8ecf3") if index % 2 == 0 else Color("c9d2de"))
		for row in int(h / (w * 0.6)):
			c.draw_rect(Rect2(rect.position + Vector2(w * 0.3, w * 0.25 + row * w * 0.6), Vector2(w * 0.4, w * 0.25)), WINDOW)


## Достопримечательность острова — чтобы острова отличались с первого взгляда.
func _draw_landmark(c: CanvasItem, id: String, at: Vector2, s: float) -> void:
	match id:
		"asia":
			# Пагода в три яруса.
			for tier in 3:
				var w: float = s * (0.5 - tier * 0.12)
				var y: float = -tier * s * 0.28
				c.draw_rect(Rect2(at + Vector2(-w * 0.6, y - s * 0.18), Vector2(w * 1.2, s * 0.18)), Color("e8434f"))
				c.draw_colored_polygon(PackedVector2Array([at + Vector2(-w, y - s * 0.16), at + Vector2(0, y - s * 0.34), at + Vector2(w, y - s * 0.16)]), INK)
			c.draw_line(at + Vector2(0, -s * 0.9), at + Vector2(0, -s * 1.1), Color("ffd54a"), 3.0)
		"europe":
			# Башня-решётка.
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(-s * 0.35, 0), at + Vector2(-s * 0.04, -s * 1.1), at + Vector2(s * 0.04, -s * 1.1), at + Vector2(s * 0.35, 0)]), Color("6d4c41"))
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(-s * 0.16, 0), at + Vector2(0, -s * 0.3), at + Vector2(s * 0.16, 0)]), Color("a1887f"))
			c.draw_line(at + Vector2(-s * 0.22, -s * 0.4), at + Vector2(s * 0.22, -s * 0.4), Color("3e2723"), 3.0)
		"africa":
			# Зонтичная акация и солнце.
			c.draw_line(at, at + Vector2(0, -s * 0.6), TRUNK, maxf(3.0, s * 0.08))
			c.draw_colored_polygon(_ellipse(at + Vector2(0, -s * 0.7), s * 0.55, s * 0.16), PALM)
			c.draw_circle(at + Vector2(s * 0.6, -s * 1.0), s * 0.16, Color("ffe066"))
		"south_america":
			# Гора-«сахарная голова» с канатной дорогой.
			c.draw_colored_polygon(_ellipse(at + Vector2(0, -s * 0.3), s * 0.3, s * 0.5), Color("5d8a5f"))
			c.draw_line(at + Vector2(-s * 0.7, -s * 0.1), at + Vector2(0, -s * 0.78), INK, 2.0)
			c.draw_rect(Rect2(at + Vector2(-s * 0.4, -s * 0.48), Vector2(s * 0.14, s * 0.1)), Color("e8434f"))
		"north_america":
			# Небоскрёбы-близнецы с огнями.
			for side in [-1.0, 1.0]:
				var rect := Rect2(at + Vector2(side * s * 0.18 - s * 0.12, -s * 1.1), Vector2(s * 0.24, s * 1.1))
				c.draw_rect(rect, Color("90a4ae"))
				for row in 6:
					c.draw_rect(Rect2(rect.position + Vector2(s * 0.05, s * 0.08 + row * s * 0.17), Vector2(s * 0.14, s * 0.06)), WINDOW)
		_:
			# Театр-«ракушки» у воды.
			for index in 3:
				var base: Vector2 = at + Vector2(-s * 0.35 + index * s * 0.32, 0)
				c.draw_colored_polygon(PackedVector2Array([base, base + Vector2(s * 0.12, -s * (0.55 - index * 0.1)), base + Vector2(s * 0.34, 0)]), Color.WHITE)
			c.draw_rect(Rect2(at + Vector2(-s * 0.45, 0), Vector2(s * 1.1, s * 0.08)), Color("c9d2de"))


func _draw_flag(c: CanvasItem, at: Vector2, s: float) -> void:
	c.draw_line(at, at + Vector2(0, -s), INK, 3.0)
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -s), at + Vector2(s * 0.7, -s * 0.82), at + Vector2(0, -s * 0.62)]), TAXI)
	c.draw_rect(Rect2(at + Vector2(s * 0.08, -s * 0.92), Vector2(s * 0.12, s * 0.1)), INK)


func _draw_clouds(c: CanvasItem, center: Vector2, r: float) -> void:
	for puff in [[Vector2(-0.3, -0.1), 0.45], [Vector2(0.2, -0.25), 0.5], [Vector2(0.45, 0.15), 0.38], [Vector2(-0.1, 0.25), 0.42]]:
		c.draw_circle(center + puff[0] * r, r * puff[1], Color(1, 1, 1, 0.92))
	c.draw_arc(center + Vector2(0, -r * 0.05), r * 0.16, PI * 1.1, PI * 1.9, 12, Color("9aa5b8"), 4.0)
	c.draw_rect(Rect2(center + Vector2(-r * 0.2, -r * 0.05), Vector2(r * 0.4, r * 0.3)), Color("9aa5b8"))


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 20:
		var angle: float = TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


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
			return Color("ffe082")
		"front":
			return TAXI
		"available":
			return Color("3ddc84")
		_:
			return Color(1, 1, 1, 0.75)


func _draw_text(c: CanvasItem, font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = 360.0
	var pos := Vector2(at.x - width / 2.0, at.y)
	c.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 8, Color(0.1, 0.2, 0.4, 0.8))
	c.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


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
