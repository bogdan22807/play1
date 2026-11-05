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
	"nails": "ffe3e3", "pies": "fff1dc", "rumor": "dff0ff",
	"center": "fff1dc", "station": "e3e7ee", "airport": "dff0ff", "sleep": "e6e0ff", "business": "e3f7ea",
}
## Маленькие иконки без подложки — для чипов в шапке.
const BARE := ["chip_income", "chip_star", "chip_rep", "chip_city"]

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
	if not BARE.has(kind):
		_round_rect(Rect2(origin + Vector2(2, 2) * u, Vector2(96, 96) * u), 24 * u, Color(str(BACKS.get(kind, "eeeeee"))))
	match kind:
		"nails":
			_nails(c, u)
		"pies":
			_pies(c, u)
		"rumor":
			_rumor(c, u)
		"center":
			_center_icon(c, u)
		"station":
			_station(c, u)
		"airport":
			_airport(c, u)
		"sleep":
			_sleep(c, u)
		"business":
			_business(c, u)
		"chip_income":
			draw_circle(c, 44 * u, Color("2fbf5f"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -30) * u, c + Vector2(24, 0) * u, c + Vector2(8, 0) * u, c + Vector2(8, 28) * u, c + Vector2(-8, 28) * u, c + Vector2(-8, 0) * u, c + Vector2(-24, 0) * u]), Color.WHITE)
		"chip_star":
			draw_colored_polygon(_star(c, 48 * u, 21 * u), Color("ffc93c"))
			draw_polyline(_star(c, 48 * u, 21 * u) + PackedVector2Array([_star(c, 48 * u, 21 * u)[0]]), Color("d9a21b"), 4 * u)
		"chip_rep":
			# Медаль на ленточке.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -46) * u, c + Vector2(-4, -46) * u, c + Vector2(6, -6) * u, c + Vector2(-12, -6) * u]), Color("3fa3f5"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(22, -46) * u, c + Vector2(4, -46) * u, c + Vector2(-6, -6) * u, c + Vector2(12, -6) * u]), Color("e8434f"))
			draw_circle(c + Vector2(0, 14) * u, 30 * u, Color("ffc93c"))
			draw_circle(c + Vector2(0, 14) * u, 21 * u, Color("ffe082"))
			draw_colored_polygon(_star(c + Vector2(0, 14) * u, 15 * u, 6.5 * u), Color("d9a21b"))
		"chip_city":
			draw_line(c + Vector2(-26, 46) * u, c + Vector2(-26, -44) * u, INK, 7 * u)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -44) * u, c + Vector2(40, -26) * u, c + Vector2(-26, -6) * u]), Color("e8434f"))
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


func _nails(c: Vector2, u: float) -> void:
	# Колесо и рассыпанные гвозди.
	draw_circle(c + Vector2(-8, -6) * u, 28 * u, Color("2f3442"))
	draw_circle(c + Vector2(-8, -6) * u, 14 * u, Color("c9d2de"))
	draw_circle(c + Vector2(-8, -6) * u, 5 * u, Color("8a96a8"))
	for nail in [[Vector2(10, 26), -0.6], [Vector2(26, 14), 0.9], [Vector2(-22, 30), 0.3], [Vector2(30, 32), -1.2]]:
		var at: Vector2 = c + nail[0] * u
		var dir := Vector2(cos(nail[1]), sin(nail[1]))
		draw_line(at - dir * 9 * u, at + dir * 9 * u, Color("6b7385"), 3.5 * u)
		draw_line(at - dir * 9 * u + dir.orthogonal() * 4 * u, at - dir * 9 * u - dir.orthogonal() * 4 * u, Color("6b7385"), 4 * u)
	# Шипение воздуха.
	for index in 3:
		draw_arc(c + Vector2(22, -26) * u, (5 + index * 6) * u, PI * 0.9, PI * 1.6, 8, Color("8fd3ff"), 2.5 * u)


func _pies(c: Vector2, u: float) -> void:
	# Пирог с паром и манящая стрелочка.
	draw_colored_polygon(_half_down(c + Vector2(0, 4) * u, 34 * u, 22 * u), Color("d58a3c"))
	_round_rect(Rect2(c + Vector2(-34, -6) * u, Vector2(68, 14) * u), 7 * u, Color("f2c27b"))
	for index in 4:
		draw_line(c + Vector2(-22 + index * 14, -4) * u, c + Vector2(-16 + index * 14, 4) * u, Color("b8742e"), 2.5 * u)
	for x in [-14, 0, 14]:
		draw_arc(c + Vector2(x, -18) * u, 5 * u, PI * 0.5, PI * 1.5, 6, Color("b0bec5"), 2.5 * u)
		draw_arc(c + Vector2(x + 2, -28) * u, 5 * u, -PI * 0.5, PI * 0.5, 6, Color("b0bec5"), 2.5 * u)
	draw_circle(c + Vector2(28, 30) * u, 8 * u, Color("e8434f"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(20, 26) * u, c + Vector2(36, 26) * u, c + Vector2(28, 40) * u]), Color("e8434f"))


func _rumor(c: Vector2, u: float) -> void:
	# Телефон и облачко со «сплетней».
	_round_rect(Rect2(c + Vector2(-32, -20) * u, Vector2(28, 50) * u), 6 * u, INK)
	_round_rect(Rect2(c + Vector2(-28, -14) * u, Vector2(20, 34) * u), 3 * u, Color("8fd3ff"))
	_round_rect(Rect2(c + Vector2(-6, -40) * u, Vector2(44, 30) * u), 12 * u, Color.WHITE)
	draw_colored_polygon(PackedVector2Array([c + Vector2(2, -12) * u, c + Vector2(-6, -2) * u, c + Vector2(10, -12) * u]), Color.WHITE)
	var font: Font = get_theme_default_font()
	draw_string(font, c + Vector2(2, -18) * u, "!?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * u), Color("e8434f"))


func _half_down(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 17:
		var angle: float = PI * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


func _center_icon(c: Vector2, u: float) -> void:
	# Кафе в центре: чашка с паром и полосатый навес.
	for index in 5:
		draw_rect(Rect2(c + Vector2(-36 + index * 14.4, -34) * u, Vector2(14.4, 14) * u), Color("e8434f") if index % 2 == 0 else Color.WHITE)
	draw_rect(Rect2(c + Vector2(-32, -20) * u, Vector2(64, 46) * u), Color("ffe0b2"))
	_round_rect(Rect2(c + Vector2(-16, 0) * u, Vector2(26, 20) * u), 6 * u, Color.WHITE)
	draw_arc(c + Vector2(13, 9) * u, 6 * u, -PI * 0.5, PI * 0.5, 8, Color.WHITE, 3 * u)
	for x in [-8, 2]:
		draw_arc(c + Vector2(x, -6) * u, 4 * u, PI * 0.5, PI * 1.5, 6, Color("9aa5b8"), 2 * u)


func _station(c: Vector2, u: float) -> void:
	# Поезд у перрона.
	_round_rect(Rect2(c + Vector2(-28, -34) * u, Vector2(56, 54) * u), 12 * u, Color("3fa3f5"))
	_round_rect(Rect2(c + Vector2(-20, -26) * u, Vector2(40, 20) * u), 4 * u, Color("dff4ff"))
	draw_circle(c + Vector2(-14, 8) * u, 5 * u, Color("ffe066"))
	draw_circle(c + Vector2(14, 8) * u, 5 * u, Color("ffe066"))
	draw_line(c + Vector2(-34, 30) * u, c + Vector2(34, 30) * u, INK, 4 * u)
	draw_line(c + Vector2(-16, 20) * u, c + Vector2(-24, 30) * u, INK, 3 * u)
	draw_line(c + Vector2(16, 20) * u, c + Vector2(24, 30) * u, INK, 3 * u)


func _airport(c: Vector2, u: float) -> void:
	# Самолёт по диагонали.
	var body := Color.WHITE
	draw_line(c + Vector2(-30, 30) * u, c + Vector2(30, -30) * u, body, 14 * u)
	draw_circle(c + Vector2(30, -30) * u, 7 * u, body)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -2) * u, c + Vector2(-38, -14) * u, c + Vector2(-34, -6) * u, c + Vector2(-8, 8) * u]), Color("3fa3f5"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(4, 2) * u, c + Vector2(14, 38) * u, c + Vector2(6, 34) * u, c + Vector2(-6, 8) * u]), Color("3fa3f5"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 22) * u, c + Vector2(-34, 16) * u, c + Vector2(-26, 26) * u]), Color("e8434f"))
	draw_line(c + Vector2(-20, 20) * u, c + Vector2(24, -24) * u, Color("c9d2de"), 3 * u)


func _sleep(c: Vector2, u: float) -> void:
	# Домики под луной.
	draw_circle(c + Vector2(22, -26) * u, 13 * u, Color("ffe082"))
	draw_circle(c + Vector2(28, -30) * u, 11 * u, Color(str(BACKS["sleep"])))
	for house in [[Vector2(-20, 4), Color("f28b82")], [Vector2(12, 12), Color("8fd3ff")]]:
		var at: Vector2 = c + house[0] * u
		draw_rect(Rect2(at + Vector2(-14, 0) * u, Vector2(28, 22) * u), house[1])
		draw_colored_polygon(PackedVector2Array([at + Vector2(-18, 2) * u, at + Vector2(0, -16) * u, at + Vector2(18, 2) * u]), INK)
		draw_rect(Rect2(at + Vector2(-5, 6) * u, Vector2(10, 8) * u), Color("fff3c4"))


func _business(c: Vector2, u: float) -> void:
	# Небоскрёбы и портфель.
	for tower in [[Vector2(-30, -38), Vector2(22, 66), "90a4ae"], [Vector2(-6, -28), Vector2(20, 56), "b0bec5"], [Vector2(16, -44), Vector2(18, 72), "78909c"]]:
		var rect := Rect2(c + tower[0] * u, tower[1] * u)
		draw_rect(rect, Color(str(tower[2])))
		for row in int(tower[1].y / 12):
			draw_rect(Rect2(rect.position + Vector2(5, 6 + row * 12) * u, Vector2(tower[1].x - 10, 4) * u), Color("dff4ff"))
	_round_rect(Rect2(c + Vector2(-16, 16) * u, Vector2(32, 22) * u), 4 * u, Color("6d4c41"))
	draw_rect(Rect2(c + Vector2(-6, 10) * u, Vector2(12, 6) * u), Color("6d4c41"), false, 2.5 * u)


func _star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius: float = outer if i % 2 == 0 else inner
		var angle: float = -PI / 2.0 + PI * float(i) / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
