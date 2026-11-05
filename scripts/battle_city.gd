extends Control
## «Битва за город»: маленький город с тремя таксопарками конкурентов.
## Над каждым — портрет босса; по виду понятно, что с ним:
## ваш (жёлтый гараж и ваш флаг), дуэль (пульсирует, скрещённые ключи),
## сдался (белый флаг), ждёт (серый, с замком).

const Portrait := preload("res://scripts/boss_portrait.gd")

const SKY := Color("bfe6ff")
const GROUND := Color("9bdc75")
const ROAD := Color("5d6582")
const LINE := Color("f4f1e8")
const INK := Color("2a2a48")
const TAXI := Color("ffc93c")
const OWNED := Color("2fbf5f")
const ACTIVE := Color("e8434f")
const WAIT := Color("b8bfcc")

## [{"look", "color", "name", "state"}]
var rivals: Array = []
var city_name: String = ""
var _portraits: Array = []
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 450)
	resized.connect(_place)


func set_rivals(new_rivals: Array, new_city: String) -> void:
	rivals = new_rivals
	city_name = new_city
	while _portraits.size() < rivals.size():
		var face: Control = Portrait.new()
		add_child(face)
		_portraits.append(face)
	for index in _portraits.size():
		var face: Control = _portraits[index]
		face.visible = index < rivals.size()
		if face.visible:
			face.set_look(rivals[index].get("look", {}))
			face.modulate = Color(1, 1, 1, 0.55) if str(rivals[index].get("state", "")) == "waiting" else Color.WHITE
	_place()
	queue_redraw()


func _slot(index: int) -> float:
	var count: int = maxi(1, rivals.size())
	return size.x * (float(index) + 0.5) / float(count)


func _place() -> void:
	var side: float = minf(130.0, size.x / 4.0)
	for index in _portraits.size():
		var face: Control = _portraits[index]
		face.size = Vector2(side, side)
		face.position = Vector2(_slot(index) - side / 2.0, 6)


var _redraw_left: float = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	# Пульс и облака — достаточно 10 кадров в секунду.
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 0.1
		queue_redraw()


func _draw() -> void:
	var ground_y: float = size.y * 0.66
	# Небо, облака, земля и дорога.
	_round_rect(Rect2(Vector2.ZERO, size), 26.0, SKY)
	for cloud in [Vector2(0.18, 0.5), Vector2(0.62, 0.42), Vector2(0.88, 0.55)]:
		var at := Vector2(cloud.x * size.x + fmod(_time * 6.0, 40.0) - 20.0, cloud.y * size.y)
		draw_circle(at, 20, Color(1, 1, 1, 0.8))
		draw_circle(at + Vector2(22, 4), 16, Color(1, 1, 1, 0.8))
		draw_circle(at + Vector2(-20, 6), 14, Color(1, 1, 1, 0.8))
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(size.x, size.y - ground_y)), GROUND)
	draw_rect(Rect2(Vector2(0, ground_y + 8), Vector2(size.x, 30)), ROAD)
	var dash: float = 0.0
	while dash < size.x:
		draw_rect(Rect2(Vector2(dash, ground_y + 21), Vector2(26, 4)), LINE)
		dash += 52.0

	var font: Font = get_theme_default_font()
	for index in rivals.size():
		var info: Dictionary = rivals[index]
		var state: String = str(info.get("state", ""))
		var x: float = _slot(index)
		var width: float = minf(190.0, size.x / 3.4)
		var height: float = 110.0
		var base := Vector2(x - width / 2.0, ground_y - height)
		var wall: Color = Color(str(info.get("color", "a0aec8")))
		if state == "owned":
			wall = TAXI
		elif state == "waiting":
			wall = WAIT
		# Пульсирующая подсветка у того, с кем дуэль.
		if state == "active":
			var glow: float = 0.5 + 0.5 * sin(_time * 4.0)
			_round_rect(Rect2(base - Vector2(10, 10), Vector2(width + 20, height + 14)), 18.0, Color(ACTIVE, 0.25 + 0.25 * glow))
		# Гараж: стена, крыша, ворота в шашечку.
		_round_rect(Rect2(base, Vector2(width, height)), 12.0, wall)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-8, 4), base + Vector2(width / 2.0, -26), base + Vector2(width + 8, 4),
		]), wall.darkened(0.25))
		var gate := Rect2(base + Vector2(width * 0.2, height * 0.38), Vector2(width * 0.6, height * 0.62))
		draw_rect(gate, wall.darkened(0.35))
		for row in 4:
			draw_line(gate.position + Vector2(0, gate.size.y * (row + 1) / 5.0), gate.position + Vector2(gate.size.x, gate.size.y * (row + 1) / 5.0), wall.darkened(0.5), 2.0)
		# Флажок/значок состояния на крыше.
		match state:
			"owned":
				_flag(base + Vector2(width - 12, 2), TAXI.darkened(0.1), true)
			"surrendered":
				_flag(base + Vector2(width - 12, 2), Color.WHITE, false)
			"waiting":
				_lock(base + Vector2(width / 2.0, height * 0.2))
			"active":
				_swords(base + Vector2(width / 2.0, height * 0.18))
		# Подпись: название и состояние.
		var name_text: String = str(info.get("name", ""))
		var state_text: String = {"owned": "ваш", "surrendered": "сдался", "active": "дуэль!", "waiting": "ждёт"}.get(state, "")
		var state_color: Color = {"owned": OWNED.darkened(0.2), "surrendered": INK, "active": ACTIVE, "waiting": Color("6b7385")}.get(state, INK)
		_text(font, Vector2(x, size.y - 50), name_text, 24, INK, Color(1, 1, 1, 0.9))
		_text(font, Vector2(x, size.y - 16), state_text, 28, state_color, Color.WHITE)


func _flag(top: Vector2, color: Color, checker: bool) -> void:
	draw_line(top, top + Vector2(0, -46), INK, 4.0)
	var cloth := PackedVector2Array([top + Vector2(0, -46), top + Vector2(40, -38), top + Vector2(0, -28)])
	draw_colored_polygon(cloth, color)
	if checker:
		draw_rect(Rect2(top + Vector2(4, -42), Vector2(8, 6)), INK)
		draw_rect(Rect2(top + Vector2(14, -37), Vector2(8, 5)), INK)


func _lock(center: Vector2) -> void:
	draw_arc(center + Vector2(0, -6), 11, PI, TAU, 12, INK, 4.0)
	_round_rect(Rect2(center + Vector2(-15, -6), Vector2(30, 24)), 5.0, INK)
	draw_circle(center + Vector2(0, 6), 3.5, WAIT)


func _swords(center: Vector2) -> void:
	var wobble: float = sin(_time * 6.0) * 0.08
	for side in [-1.0, 1.0]:
		var angle: float = side * (PI * 0.25 + wobble)
		var dir := Vector2(sin(angle), -cos(angle))
		var from: Vector2 = center + dir * -22
		var to: Vector2 = center + dir * 22
		draw_line(from, to, Color.WHITE, 7.0)
		draw_line(from, to, INK, 3.0)
		draw_circle(to, 7, Color.WHITE)
		draw_circle(to, 4, INK)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, outline: Color) -> void:
	var width: float = size.x / maxf(1.0, float(rivals.size()))
	var pos := Vector2(at.x - width / 2.0, at.y)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 6, outline)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
