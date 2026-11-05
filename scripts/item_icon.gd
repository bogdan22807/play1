extends Control
## Иконки для списков, нарисованные фигурами: помощники, рекламные кампании, тюнинг, гараж.
## kind: washer, mechanic, dispatcher, flyers, billboard, tv, tires, horn, seats, meter, wrap, garage.

const INK := Color("2a2a48")
const TAXI := Color("ffc93c")

const BACKS := {
	"washer": "d6efff", "mechanic": "e3e7ee", "dispatcher": "e6e0ff",
	"flyers": "e8f6e0", "billboard": "dff0ff", "tv": "f0e6ff",
	"tires": "e3e7ee", "horn": "ffe9ec", "seats": "f3e9ff", "meter": "e3f7ea", "wrap": "ffe6f0",
	"garage": "e8f6e0",
}

var kind: String = "":
	set(value):
		kind = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(110, 110)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var u: float = s / 100.0
	var origin := (size - Vector2(s, s)) / 2.0
	var c: Vector2 = origin + Vector2(50, 50) * u
	_round_rect(Rect2(origin + Vector2(2, 2) * u, Vector2(96, 96) * u), 24 * u, Color(str(BACKS.get(kind, "eeeeee"))))
	match kind:
		"washer":
			_washer(c, u)
		"mechanic":
			_mechanic(c, u)
		"dispatcher":
			_dispatcher(c, u)
		"flyers":
			_flyers(c, u)
		"billboard":
			_billboard(c, u)
		"tv":
			_tv(c, u)
		"tires":
			_tires(c, u)
		"horn":
			_horn(c, u)
		"seats":
			_seats(c, u)
		"meter":
			_meter(c, u)
		"wrap":
			_wrap(c, u)
		"garage":
			_garage(c, u)


func _washer(c: Vector2, u: float) -> void:
	# Ведро с пеной и губка.
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-24, -6) * u, c + Vector2(24, -6) * u, c + Vector2(18, 30) * u, c + Vector2(-18, 30) * u,
	]), Color("3fa3f5"))
	draw_rect(Rect2(c + Vector2(-26, -10) * u, Vector2(52, 6) * u), Color("2b7fd0"))
	draw_arc(c + Vector2(0, -8) * u, 20 * u, PI, TAU, 16, INK, 3 * u)
	for bubble in [Vector2(-14, -16), Vector2(-2, -20), Vector2(12, -15), Vector2(22, -26), Vector2(4, -32)]:
		draw_circle(c + bubble * u, 6 * u, Color.WHITE)
		draw_arc(c + bubble * u, 6 * u, 0, TAU, 12, Color("9fd4ff"), 1.5 * u)
	_round_rect(Rect2(c + Vector2(10, 12) * u, Vector2(26, 14) * u), 4 * u, TAXI)
	draw_rect(Rect2(c + Vector2(10, 12) * u, Vector2(26, 4) * u), Color("2fbf5f"))


func _mechanic(c: Vector2, u: float) -> void:
	# Гаечный ключ и отвёртка крест-накрест.
	var steel := Color("8a96a8")
	draw_line(c + Vector2(-22, 22) * u, c + Vector2(16, -16) * u, steel, 9 * u)
	draw_circle(c + Vector2(20, -20) * u, 12 * u, steel)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(20, -20) * u, c + Vector2(22, -34) * u, c + Vector2(34, -22) * u,
	]), Color(str(BACKS["mechanic"])))
	draw_line(c + Vector2(22, 22) * u, c + Vector2(-8, -8) * u, Color("4a5568"), 5 * u)
	draw_line(c + Vector2(28, 28) * u, c + Vector2(14, 14) * u, Color("e8434f"), 10 * u)
	draw_line(c + Vector2(-8, -8) * u, c + Vector2(-18, -18) * u, Color("4a5568"), 3 * u)


func _dispatcher(c: Vector2, u: float) -> void:
	# Рация с антенной и волнами.
	_round_rect(Rect2(c + Vector2(-14, -16) * u, Vector2(28, 46) * u), 6 * u, INK)
	draw_line(c + Vector2(8, -16) * u, c + Vector2(8, -34) * u, INK, 4 * u)
	_round_rect(Rect2(c + Vector2(-9, -10) * u, Vector2(18, 12) * u), 2 * u, Color("8fe3a6"))
	for row in 3:
		for col in 3:
			draw_circle(c + Vector2(-6 + col * 6, 10 + row * 6) * u, 1.8 * u, Color("8a96a8"))
	for index in 2:
		draw_arc(c + Vector2(8, -34) * u, (8 + index * 7) * u, -PI * 0.35, PI * 0.15, 10, Color("6c5ce7"), 2.5 * u)


func _flyers(c: Vector2, u: float) -> void:
	# Стопка листовок с такси.
	for index in 3:
		var shift := Vector2(-8 + index * 6, -4 + index * -4) * u
		var page := Rect2(c + Vector2(-18, -22) * u + shift, Vector2(34, 44) * u)
		draw_rect(page, Color.WHITE)
		draw_rect(page, Color("c9d2de"), false, 1.5 * u)
	var top := c + Vector2(-6, -30) * u
	_round_rect(Rect2(top + Vector2(2, 6) * u, Vector2(30, 12) * u), 3 * u, TAXI)
	for line in 3:
		draw_line(top + Vector2(4, 24 + line * 7) * u, top + Vector2(28, 24 + line * 7) * u, Color("9aa5b8"), 2 * u)


func _billboard(c: Vector2, u: float) -> void:
	# Щит на двух ногах с надписью в шашечку.
	draw_line(c + Vector2(-18, 8) * u, c + Vector2(-18, 36) * u, INK, 4 * u)
	draw_line(c + Vector2(18, 8) * u, c + Vector2(18, 36) * u, INK, 4 * u)
	_round_rect(Rect2(c + Vector2(-36, -28) * u, Vector2(72, 40) * u), 5 * u, Color.WHITE)
	draw_rect(Rect2(c + Vector2(-36, -28) * u, Vector2(72, 40) * u), INK, false, 3 * u)
	for index in 8:
		draw_rect(Rect2(c + Vector2(-32 + index * 8, -6) * u, Vector2(4, 4) * u), INK)
		draw_rect(Rect2(c + Vector2(-28 + index * 8, -2) * u, Vector2(4, 4) * u), INK)
	_round_rect(Rect2(c + Vector2(-28, -22) * u, Vector2(56, 12) * u), 3 * u, TAXI)
	draw_circle(c + Vector2(28, -30) * u, 4 * u, Color("ffe066"))


func _tv(c: Vector2, u: float) -> void:
	# Телевизор с антенной, на экране такси.
	draw_line(c + Vector2(0, -22) * u, c + Vector2(-14, -38) * u, INK, 3 * u)
	draw_line(c + Vector2(0, -22) * u, c + Vector2(14, -38) * u, INK, 3 * u)
	_round_rect(Rect2(c + Vector2(-34, -22) * u, Vector2(68, 50) * u), 8 * u, Color("6c5ce7"))
	_round_rect(Rect2(c + Vector2(-28, -16) * u, Vector2(46, 38) * u), 5 * u, Color("bfe6ff"))
	_round_rect(Rect2(c + Vector2(-22, 2) * u, Vector2(34, 12) * u), 3 * u, TAXI)
	draw_circle(c + Vector2(-14, 15) * u, 3 * u, INK)
	draw_circle(c + Vector2(4, 15) * u, 3 * u, INK)
	draw_circle(c + Vector2(26, -8) * u, 3 * u, Color.WHITE)
	draw_circle(c + Vector2(26, 4) * u, 3 * u, Color.WHITE)


func _tires(c: Vector2, u: float) -> void:
	draw_circle(c, 32 * u, Color("2f3442"))
	for index in 12:
		var angle: float = TAU * float(index) / 12.0
		draw_line(c + Vector2(cos(angle), sin(angle)) * 26 * u, c + Vector2(cos(angle), sin(angle)) * 32 * u, Color("4a5163"), 3 * u)
	draw_circle(c, 17 * u, Color("c9d2de"))
	draw_circle(c, 6 * u, Color("8a96a8"))
	for index in 5:
		var angle: float = TAU * float(index) / 5.0
		draw_circle(c + Vector2(cos(angle), sin(angle)) * 11 * u, 2 * u, Color("8a96a8"))


func _horn(c: Vector2, u: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-26, -6) * u, c + Vector2(-8, -6) * u, c + Vector2(14, -24) * u,
		c + Vector2(14, 24) * u, c + Vector2(-8, 6) * u, c + Vector2(-26, 6) * u,
	]), Color("e8434f"))
	draw_rect(Rect2(c + Vector2(-30, -8) * u, Vector2(8, 16) * u), INK)
	for index in 3:
		draw_arc(c + Vector2(14, 0) * u, (10 + index * 8) * u, -PI * 0.3, PI * 0.3, 10, INK, 3 * u)


func _seats(c: Vector2, u: float) -> void:
	var seat := Color("8b7cf0")
	_round_rect(Rect2(c + Vector2(-20, -34) * u, Vector2(26, 50) * u), 10 * u, seat)
	_round_rect(Rect2(c + Vector2(-20, 8) * u, Vector2(44, 18) * u), 8 * u, seat.darkened(0.15))
	_round_rect(Rect2(c + Vector2(-16, -44) * u, Vector2(18, 10) * u), 4 * u, seat.lightened(0.2))
	draw_line(c + Vector2(-12, -24) * u, c + Vector2(-12, 4) * u, seat.lightened(0.35), 2.5 * u)
	draw_line(c + Vector2(-2, -24) * u, c + Vector2(-2, 4) * u, seat.lightened(0.35), 2.5 * u)
	draw_line(c + Vector2(16, 26) * u, c + Vector2(20, 36) * u, INK, 3 * u)
	draw_line(c + Vector2(-16, 26) * u, c + Vector2(-20, 36) * u, INK, 3 * u)


func _meter(c: Vector2, u: float) -> void:
	_round_rect(Rect2(c + Vector2(-32, -22) * u, Vector2(64, 44) * u), 8 * u, INK)
	_round_rect(Rect2(c + Vector2(-26, -16) * u, Vector2(52, 18) * u), 3 * u, Color("163a2a"))
	var font: Font = get_theme_default_font()
	draw_string(font, c + Vector2(-24, -1) * u, "$ 88.8", HORIZONTAL_ALIGNMENT_LEFT, 50 * u, int(14 * u), Color("5df58b"))
	for index in 3:
		draw_circle(c + Vector2(-16 + index * 16, 12) * u, 4 * u, [Color("e8434f"), TAXI, Color("2fbf5f")][index])
	_round_rect(Rect2(c + Vector2(-10, -32) * u, Vector2(20, 10) * u), 3 * u, TAXI)


func _wrap(c: Vector2, u: float) -> void:
	# Баллончик с краской и цветные брызги.
	for splash in [[Vector2(16, -18), 9, "ff5d8f"], [Vector2(28, -4), 6, "3fb2ff"], [Vector2(22, -32), 5, "2fbf5f"], [Vector2(32, -22), 4, "8b7cf0"]]:
		draw_circle(c + splash[0] * u, splash[1] * u, Color(str(splash[2])))
	_round_rect(Rect2(c + Vector2(-24, -14) * u, Vector2(26, 46) * u), 7 * u, Color("ff5d8f"))
	_round_rect(Rect2(c + Vector2(-18, -24) * u, Vector2(14, 10) * u), 3 * u, Color("8a96a8"))
	draw_rect(Rect2(c + Vector2(-14, -30) * u, Vector2(6, 6) * u), INK)
	draw_rect(Rect2(c + Vector2(-24, 2) * u, Vector2(26, 10) * u), Color.WHITE)


func _garage(c: Vector2, u: float) -> void:
	var wall := Color("3fa3f5")
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-38, -6) * u, c + Vector2(0, -34) * u, c + Vector2(38, -6) * u,
	]), wall.darkened(0.25))
	draw_rect(Rect2(c + Vector2(-32, -8) * u, Vector2(64, 40) * u), wall)
	draw_rect(Rect2(c + Vector2(-22, 2) * u, Vector2(44, 30) * u), Color("dfe7f2"))
	for row in 4:
		draw_line(c + Vector2(-22, 8 + row * 6) * u, c + Vector2(22, 8 + row * 6) * u, Color("9aa5b8"), 2 * u)
	_round_rect(Rect2(c + Vector2(-12, 20) * u, Vector2(24, 10) * u), 3 * u, TAXI)


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
