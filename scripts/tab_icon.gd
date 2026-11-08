extends Control
## Иконка вкладки нижней панели, нарисованная фигурами: город, машина, команда, карта, рынок.

var kind: String = "city":
	set(value):
		kind = value
		if is_inside_tree() and not bake_mode:
			_request_bake()
		queue_redraw()

const Baker := preload("res://scripts/baker.gd")
## true — художник внутри запекания. Обычная иконка показывает готовую картинку.
var bake_mode: bool = false
var _texture: Texture2D
var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
## Красная точка: на вкладке есть что-то срочное.
var badge: bool = false:
	set(value):
		badge = value
		queue_redraw()


## Пульсирующее кольцо: дядя Бун показывает сюда.
var glow: bool = false:
	set(value):
		glow = value
		queue_redraw()
var glow_color: Color = Color("ff4d5e")
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not bake_mode:
		resized.connect(_request_bake)
		_request_bake()
		# Окно сменило плотность пикселей (настройка «Графика») — перепечь под новую чёткость.
		get_viewport().size_changed.connect(_request_bake)


func _request_bake() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var scale: float = maxf(1.0, get_viewport().get_final_transform().get_scale().x)
	var pixels := Vector2i(ceili(size.x * scale), ceili(size.y * scale))
	var key: String = "tab|%s|%d|%d" % [kind, pixels.x, pixels.y]
	if Baker.has(key):
		_texture = Baker.get_cached(key)
	else:
		var painter: Control = get_script().new()
		painter.bake_mode = true
		painter.kind = kind
		_texture = Baker.texture(get_tree(), key, pixels, painter)
	queue_redraw()


func _process(delta: float) -> void:
	if glow and is_visible_in_tree():
		_pulse = fmod(_pulse + delta * 2.5, TAU)
		queue_redraw()


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var o: Vector2 = (size - Vector2(s, s)) / 2.0
	if not bake_mode:
		if _texture != null:
			draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
	else:
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
		return
	if glow:
		var ring: float = s * (0.62 + 0.08 * sin(_pulse))
		draw_arc(o + Vector2(s, s) / 2.0, ring, 0, TAU, 40, Color(glow_color, 0.9), s * 0.08)
	if badge:
		var at := o + Vector2(s * 0.92, s * 0.1)
		draw_circle(at, s * 0.14, Color("1f1645"))
		draw_circle(at, s * 0.11, Color("ff3b5c"))


func _r(o: Vector2, s: float, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s)


const INK := Color("2a2a48")
const SHADE := Color(0, 0, 0, 0.16)
const SHINE := Color(1, 1, 1, 0.45)


func _box(rect: Rect2, radius: float, fill: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)


## Город: три дома разного цвета с горящими окнами и деревце.
func _city(o: Vector2, s: float) -> void:
	draw_rect(_r(o, s, 0.06, 0.9, 0.88, 0.04), SHADE)
	var houses: Array = [[0.08, 0.42, 0.26, 0.5, Color("ff8a65")], [0.36, 0.1, 0.3, 0.82, Color("4fa3e8")], [0.68, 0.3, 0.26, 0.62, Color("9fa8da")]]
	for h: Array in houses:
		var rect: Rect2 = _r(o, s, h[0], h[1], h[2], h[3])
		_box(rect, s * 0.04, h[4])
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.7, 0), Vector2(rect.size.x * 0.3, rect.size.y)), SHADE)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, s * 0.04)), Color(h[4]).darkened(0.25))
		var rows: int = int(rect.size.y / (s * 0.15))
		for row in rows:
			for col in 2:
				var win := Rect2(rect.position + Vector2(rect.size.x * (0.18 + col * 0.42), s * (0.08 + row * 0.15)), Vector2(rect.size.x * 0.24, s * 0.07))
				draw_rect(win, Color("fff3c4") if (row + col) % 3 != 0 else Color("5d7fa3"))
	draw_circle(o + Vector2(0.9, 0.82) * s, s * 0.09, Color("2f8a46"))
	draw_circle(o + Vector2(0.88, 0.79) * s, s * 0.06, Color("46b35c"))


## Машина спереди: жёлтое такси с шашечками, фарами и знаком на крыше.
func _car(o: Vector2, s: float) -> void:
	var body := Color("ffc93c")
	_box(_r(o, s, 0.42, 0.1, 0.16, 0.08), s * 0.02, Color("fff8e1"))
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.22, 0.48) * s, o + Vector2(0.3, 0.2) * s,
		o + Vector2(0.7, 0.2) * s, o + Vector2(0.78, 0.48) * s,
	]), body.darkened(0.06))
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.3, 0.45) * s, o + Vector2(0.35, 0.26) * s, o + Vector2(0.65, 0.26) * s, o + Vector2(0.7, 0.45) * s,
	]), Color("3d5a80"))
	draw_line(o + Vector2(0.38, 0.3) * s, o + Vector2(0.44, 0.42) * s, SHINE, s * 0.03)
	_box(_r(o, s, 0.14, 0.76, 0.16, 0.14), s * 0.03, INK)
	_box(_r(o, s, 0.7, 0.76, 0.16, 0.14), s * 0.03, INK)
	_box(_r(o, s, 0.06, 0.46, 0.88, 0.32), s * 0.08, body)
	draw_rect(_r(o, s, 0.06, 0.66, 0.88, 0.04), body.darkened(0.2))
	for k in 8:
		draw_rect(_r(o, s, 0.16 + k * 0.085, 0.58 + (k % 2) * 0.035, 0.04, 0.035), INK)
	for x in [0.17, 0.83]:
		draw_circle(o + Vector2(x, 0.56) * s, s * 0.06, Color("fff59d"))
		draw_circle(o + Vector2(x - 0.015, 0.545) * s, s * 0.02, Color.WHITE)
	draw_rect(_r(o, s, 0.1, 0.49, 0.8, 0.03), SHINE)


## Команда: таксист в кепке с шашечками.
func _team(o: Vector2, s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.14, 0.94) * s, o + Vector2(0.22, 0.64) * s,
		o + Vector2(0.78, 0.64) * s, o + Vector2(0.86, 0.94) * s,
	]), Color("3fa3f5"))
	draw_colored_polygon(PackedVector2Array([o + Vector2(0.5, 0.64) * s, o + Vector2(0.78, 0.64) * s, o + Vector2(0.86, 0.94) * s, o + Vector2(0.56, 0.94) * s]), SHADE)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0.4, 0.64) * s, o + Vector2(0.5, 0.76) * s, o + Vector2(0.6, 0.64) * s]), Color.WHITE)
	draw_circle(o + Vector2(0.5, 0.4) * s, s * 0.2, Color("e0b48f"))
	draw_circle(o + Vector2(0.54, 0.44) * s, s * 0.16, Color("d29f78"))
	draw_circle(o + Vector2(0.49, 0.39) * s, s * 0.17, Color("e0b48f"))
	draw_circle(o + Vector2(0.43, 0.42) * s, s * 0.022, INK)
	draw_circle(o + Vector2(0.57, 0.42) * s, s * 0.022, INK)
	draw_arc(o + Vector2(0.5, 0.47) * s, s * 0.06, PI * 0.2, PI * 0.8, 8, INK, s * 0.02)
	draw_colored_polygon(PackedVector2Array([o + Vector2(0.29, 0.32) * s, o + Vector2(0.33, 0.14) * s, o + Vector2(0.67, 0.14) * s, o + Vector2(0.71, 0.32) * s]), Color("1c2b4d"))
	for k in 5:
		draw_rect(_r(o, s, 0.3 + k * 0.08, 0.27, 0.04, 0.04), Color("ffc93c"))
	draw_rect(_r(o, s, 0.5, 0.31, 0.3, 0.05), Color("1c2b4d").darkened(0.3))


## Карта: остров с пальмой посреди волн.
func _map(o: Vector2, s: float) -> void:
	draw_circle(o + Vector2(0.5, 0.78) * s, s * 0.42, Color("4cb8f5"))
	draw_circle(o + Vector2(0.5, 0.74) * s, s * 0.3, Color("e9d8a6"))
	draw_circle(o + Vector2(0.48, 0.72) * s, s * 0.22, Color("6fcf6a"))
	draw_circle(o + Vector2(0.44, 0.68) * s, s * 0.1, Color("8fe08a"))
	for x in [0.16, 0.74]:
		draw_arc(o + Vector2(x, 0.96) * s, s * 0.06, PI * 1.1, PI * 1.9, 8, Color.WHITE, s * 0.03)
	draw_line(o + Vector2(0.5, 0.7) * s, o + Vector2(0.56, 0.26) * s, Color("8d6e63"), s * 0.06)
	for leaf: Vector2 in [Vector2(-0.26, 0.08), Vector2(0.26, 0.06), Vector2(-0.14, -0.14), Vector2(0.18, -0.14)]:
		draw_line(o + Vector2(0.56, 0.26) * s, o + (Vector2(0.56, 0.26) + leaf) * s, Color("2f8a46"), s * 0.08)
		draw_line(o + Vector2(0.56, 0.26) * s, o + (Vector2(0.56, 0.26) + leaf * 0.8) * s, Color("46b35c"), s * 0.03)
	draw_circle(o + Vector2(0.53, 0.3) * s, s * 0.035, Color("795548"))
	draw_circle(o + Vector2(0.59, 0.3) * s, s * 0.035, Color("8d6e63"))


## Рынок: зелёные столбики растут, золотая стрелка вверх.
func _market(o: Vector2, s: float) -> void:
	var bars: Array = [[0.1, 0.6, 0.18, 0.3], [0.4, 0.44, 0.18, 0.46], [0.7, 0.26, 0.18, 0.64]]
	for i in bars.size():
		var b: Array = bars[i]
		var rect: Rect2 = _r(o, s, b[0], b[1], b[2], b[3])
		var fill: Color = Color("2fbf5f").lightened(0.15 * (2 - i))
		_box(rect, s * 0.03, fill)
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.65, 0), Vector2(rect.size.x * 0.35, rect.size.y)), SHADE)
		draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.15, s * 0.03), Vector2(rect.size.x * 0.15, rect.size.y - s * 0.06)), SHINE)
	draw_line(o + Vector2(0.1, 0.42) * s, o + Vector2(0.72, 0.1) * s, Color("d9a21b"), s * 0.08)
	draw_line(o + Vector2(0.1, 0.42) * s, o + Vector2(0.72, 0.1) * s, Color("ffc93c"), s * 0.05)
	draw_colored_polygon(PackedVector2Array([
		o + Vector2(0.8, 0.02) * s, o + Vector2(0.88, 0.24) * s, o + Vector2(0.6, 0.16) * s,
	]), Color("ffc93c"))
