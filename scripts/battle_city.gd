extends Control
## «Битва за город»: маленький город с тремя таксопарками конкурентов.
## Над каждым — портрет босса. Ваша доля заливает гараж жёлтым снизу вверх,
## у ворот ваши жёлтые такси вытесняют их машины; купленные стоянка и диспетчерская видны на картинке.

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
	custom_minimum_size = Vector2(0, 470)
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
	var ground_y: float = size.y * 0.68
	# Небо с градиентом, город на горизонте, облака, земля и дорога.
	_round_rect(Rect2(Vector2.ZERO, size), 26.0, SKY)
	draw_rect(Rect2(Vector2(0, ground_y * 0.55), Vector2(size.x, ground_y * 0.45)), Color(1, 1, 1, 0.18))
	_skyline(ground_y)
	for cloud in [Vector2(0.18, 0.42), Vector2(0.62, 0.34), Vector2(0.88, 0.47)]:
		var at := Vector2(cloud.x * size.x + fmod(_time * 6.0, 40.0) - 20.0, cloud.y * size.y)
		draw_circle(at, 18, Color(1, 1, 1, 0.75))
		draw_circle(at + Vector2(20, 4), 14, Color(1, 1, 1, 0.75))
		draw_circle(at + Vector2(-18, 6), 12, Color(1, 1, 1, 0.75))
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(size.x, size.y - ground_y)), GROUND)
	draw_rect(Rect2(Vector2(0, ground_y + 22), Vector2(size.x, 30)), ROAD)
	var dash: float = fmod(-_time * 30.0, 52.0)
	while dash < size.x:
		draw_rect(Rect2(Vector2(dash, ground_y + 35), Vector2(26, 4)), LINE)
		dash += 52.0

	var font: Font = get_theme_default_font()
	for index in rivals.size():
		var info: Dictionary = rivals[index]
		var state: String = str(info.get("state", ""))
		var pct: float = clampf(float(info.get("pct", 0)) / 100.0, 0.0, 1.0)
		if state == "owned":
			pct = 1.0
		var parts: Array = info.get("parts", [])
		var x: float = _slot(index)
		var width: float = minf(200.0, size.x / 3.3)
		var height: float = 118.0
		var base := Vector2(x - width / 2.0, ground_y - height)
		var wall: Color = Color(str(info.get("color", "a0aec8")))
		if state == "waiting":
			wall = WAIT
		# Тень и стена гаража цвета компании.
		_round_rect(Rect2(base + Vector2(6, 8), Vector2(width, height)), 12.0, Color(0, 0, 0, 0.12))
		_round_rect(Rect2(base, Vector2(width, height)), 12.0, wall)
		# Ваша доля «заливает» гараж жёлтым снизу вверх.
		if pct > 0.0:
			var fill_h: float = height * pct
			_round_rect(Rect2(base + Vector2(0, height - fill_h), Vector2(width, fill_h)), 12.0, TAXI)
			var stripe_y: float = base.y + height - fill_h
			var cell: float = 8.0
			var cx: float = base.x + 4.0
			var odd: bool = false
			while cx < base.x + width - 4.0:
				draw_rect(Rect2(Vector2(cx, stripe_y), Vector2(minf(cell, base.x + width - 4.0 - cx), 6)), INK if odd else Color.WHITE)
				odd = not odd
				cx += cell
		# Крыша и вывеска «TAXI».
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-10, 6), base + Vector2(width / 2.0, -24), base + Vector2(width + 10, 6),
		]), wall.darkened(0.3) if pct < 1.0 else TAXI.darkened(0.2))
		var sign_rect := Rect2(base + Vector2(width * 0.22, -12), Vector2(width * 0.56, 22))
		_round_rect(sign_rect, 6.0, INK)
		draw_string(font, sign_rect.position + Vector2(0, 17), "TAXI", HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 17, TAXI)
		# Окна и ворота.
		for wx in [0.08, 0.8]:
			_round_rect(Rect2(base + Vector2(width * wx, 24), Vector2(width * 0.12, 22)), 4.0, Color("dff3ff"))
		var gate := Rect2(base + Vector2(width * 0.26, height * 0.36), Vector2(width * 0.48, height * 0.64))
		_round_rect(gate, 6.0, wall.darkened(0.42) if pct < 0.6 else TAXI.darkened(0.3))
		for row in 4:
			var ly: float = gate.position.y + gate.size.y * (row + 1) / 5.0
			draw_line(Vector2(gate.position.x + 3, ly), Vector2(gate.end.x - 3, ly), Color(0, 0, 0, 0.25), 2.0)
		# Машины у гаража: их — цвета компании, ваши — жёлтые. Чем больше доля, тем больше жёлтых.
		var cars: int = 3
		var mine: int = int(roundf(pct * cars))
		if parts.has("fleet_part") and mine < cars:
			mine += 1
		for car in cars:
			var at := Vector2(base.x + width * (0.16 + car * 0.34), ground_y + 14)
			_car(at, TAXI if car < mine else wall.lightened(0.15), car < mine)
		# Купленные части видно прямо на картинке.
		if parts.has("parking"):
			_parking_sign(base + Vector2(-4, height - 54))
		if parts.has("dispatch"):
			_antenna(base + Vector2(width * 0.82, -6))
		# Флажок: ваш, когда компания ваша; замок — если остров ещё не открыт.
		match state:
			"owned":
				_flag(base + Vector2(width / 2.0, -24), TAXI.darkened(0.1), true)
			"waiting":
				_lock(base + Vector2(width / 2.0, height * 0.18))
		# Подпись: название и ваша доля.
		var name_text: String = str(info.get("name", ""))
		var state_text: String = {"owned": "ваш ✓", "active": "ваши %d%%" % int(info.get("pct", 0)), "waiting": "ждёт"}.get(state, "")
		var state_color: Color = {"owned": OWNED.darkened(0.2), "active": INK, "waiting": Color("6b7385")}.get(state, INK)
		_text(font, Vector2(x, size.y - 48), name_text, 24, INK, Color(1, 1, 1, 0.9))
		_text(font, Vector2(x, size.y - 14), state_text, 30, state_color, Color.WHITE)


func _skyline(ground_y: float) -> void:
	var tones := [Color("9fc9ea"), Color("8dbbe0")]
	var x: float = 0.0
	var index: int = 0
	while x < size.x:
		var w: float = 34.0 + float((index * 37) % 30)
		var h: float = 50.0 + float((index * 53) % 70)
		draw_rect(Rect2(Vector2(x, ground_y - h), Vector2(w, h)), tones[index % 2])
		for wy in range(int(ground_y - h + 8), int(ground_y - 8), 14):
			for wx in range(int(x + 6), int(x + w - 6), 10):
				if (wx + wy + index) % 3 != 0:
					draw_rect(Rect2(Vector2(wx, wy), Vector2(4, 6)), Color(1, 1, 1, 0.35))
		x += w + 4.0
		index += 1


func _car(at: Vector2, body: Color, mine: bool) -> void:
	_round_rect(Rect2(at + Vector2(-22, -10), Vector2(44, 16)), 6.0, body)
	_round_rect(Rect2(at + Vector2(-12, -19), Vector2(24, 11)), 4.0, body.darkened(0.08))
	draw_rect(Rect2(at + Vector2(-9, -17), Vector2(18, 6)), Color("bfe6ff"))
	if mine:
		for k in 4:
			draw_rect(Rect2(at + Vector2(-16 + k * 8, -4), Vector2(4, 4)), INK)
	draw_circle(at + Vector2(-12, 7), 5, INK)
	draw_circle(at + Vector2(12, 7), 5, INK)


func _parking_sign(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(10, 20), Vector2(4, 34)), Color("7a8399"))
	_round_rect(Rect2(at, Vector2(26, 26)), 5.0, Color("2b6cb0"))
	draw_string(get_theme_default_font(), at + Vector2(0, 21), "P", HORIZONTAL_ALIGNMENT_CENTER, 26, 22, Color.WHITE)


func _antenna(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -30), INK, 3.0)
	draw_circle(at + Vector2(0, -32), 4, Color("e8434f"))
	var pulse: float = fmod(_time, 1.2) / 1.2
	for k in 2:
		var r: float = 8.0 + (k + pulse) * 8.0
		draw_arc(at + Vector2(0, -32), r, -PI * 0.8, -PI * 0.2, 8, Color(0.91, 0.26, 0.31, 1.0 - pulse * 0.6), 2.0)


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
