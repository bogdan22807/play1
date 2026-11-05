extends Control
## Иконка вкладки нижней панели, нарисованная фигурами: город, машина, команда, карта, рынок.

var kind: String = "city":
	set(value):
		kind = value
		queue_redraw()
var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
## Красная точка: на вкладке есть что-то срочное.
var badge: bool = false:
	set(value):
		badge = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var o: Vector2 = (size - Vector2(s, s)) / 2.0
	match kind:
		"city":
			_city(o, s)
		"car":
			_car(o, s)
		"team":
			_team(o, s)
		"map":
			_map(o, s)
		"market":
			_market(o, s)
	if badge:
		var at := o + Vector2(s * 0.92, s * 0.1)
		draw_circle(at, s * 0.14, Color("1f1645"))
		draw_circle(at, s * 0.11, Color("ff3b5c"))


func _r(o: Vector2, s: float, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s)


func _city(o: Vector2, s: float) -> void:
	draw_rect(_r(o, s, 0.08, 0.42, 0.24, 0.5), color)
	draw_rect(_r(o, s, 0.36, 0.12, 0.28, 0.8), color)
	draw_rect(_r(o, s, 0.68, 0.3, 0.24, 0.62), color)
	var hole := Color("1f1645", 0.85)
	for row in 4:
		draw_rect(_r(o, s, 0.42, 0.2 + row * 0.16, 0.06, 0.08), hole)
		draw_rect(_r(o, s, 0.52, 0.2 + row * 0.16, 0.06, 0.08), hole)
	for row in 2:
		draw_rect(_r(o, s, 0.15, 0.52 + row * 0.16, 0.1, 0.08), hole)
		draw_rect(_r(o, s, 0.75, 0.42 + row * 0.18, 0.1, 0.08), hole)


func _car(o: Vector2, s: float) -> void:
	# Машина спереди: крыша, кузов, фары, колёса.
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.24, 0.48) * s, o + Vector2(0.32, 0.22) * s,
		o + Vector2(0.68, 0.22) * s, o + Vector2(0.76, 0.48) * s,
	]), color)
	draw_rect(_r(o, s, 0.08, 0.46, 0.84, 0.3), color)
	draw_rect(_r(o, s, 0.36, 0.28, 0.28, 0.16), Color("1f1645", 0.85))
	draw_circle(o + Vector2(0.2, 0.6) * s, s * 0.06, Color("1f1645", 0.85))
	draw_circle(o + Vector2(0.8, 0.6) * s, s * 0.06, Color("1f1645", 0.85))
	draw_rect(_r(o, s, 0.14, 0.76, 0.16, 0.12), color)
	draw_rect(_r(o, s, 0.7, 0.76, 0.16, 0.12), color)


func _team(o: Vector2, s: float) -> void:
	# Таксист в кепке.
	draw_circle(o + Vector2(0.5, 0.36) * s, s * 0.18, color)
	draw_rect(_r(o, s, 0.3, 0.14, 0.4, 0.1), color)
	draw_rect(_r(o, s, 0.5, 0.2, 0.3, 0.05), color)
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.14, 0.92) * s, o + Vector2(0.22, 0.62) * s,
		o + Vector2(0.78, 0.62) * s, o + Vector2(0.86, 0.92) * s,
	]), color)


func _map(o: Vector2, s: float) -> void:
	# Остров с пальмой на волне.
	draw_arc(o + Vector2(0.5, 1.15) * s, s * 0.5, PI * 1.2, PI * 1.8, 16, color, s * 0.08)
	draw_circle(o + Vector2(0.5, 0.78) * s, s * 0.26, color)
	draw_line(o + Vector2(0.5, 0.62) * s, o + Vector2(0.56, 0.24) * s, color, s * 0.07)
	for leaf: Vector2 in [Vector2(-0.24, 0.06), Vector2(0.24, 0.04), Vector2(-0.12, -0.12), Vector2(0.16, -0.12)]:
		draw_line(o + Vector2(0.56, 0.24) * s, o + (Vector2(0.56, 0.24) + leaf) * s, color, s * 0.08)


func _market(o: Vector2, s: float) -> void:
	# Столбики растут, стрелка вверх.
	draw_rect(_r(o, s, 0.1, 0.6, 0.18, 0.3), color)
	draw_rect(_r(o, s, 0.4, 0.44, 0.18, 0.46), color)
	draw_rect(_r(o, s, 0.7, 0.26, 0.18, 0.64), color)
	draw_line(o + Vector2(0.1, 0.42) * s, o + Vector2(0.72, 0.1) * s, color, s * 0.07)
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.78, 0.04) * s, o + Vector2(0.86, 0.22) * s, o + Vector2(0.62, 0.16) * s,
	]), color)
