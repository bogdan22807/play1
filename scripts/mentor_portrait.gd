extends Control
## Портрет дяди Буна, нарисованный фигурами: кепка таксиста, тёмные очки, пышные седые усы.
## Пока он говорит, усы шевелятся и рот открывается.

const BADGE := Color("ffc93c")
const SKIN := Color("e3a96f")
const SKIN_DARK := Color("c98a52")
const CAP := Color("1c2b4d")
const GLASSES := Color("1c2b4d")
const HAIR := Color("f4f1ea")
const SHIRT := Color("3fb2ff")

var _talk_left: float = 0.0
var _time: float = 0.0
const Baker := preload("res://scripts/baker.gd")
## Молчащий дед — готовая картинка (одна команда); фигурами рисуем, только пока говорит.
var bake_mode: bool = false
var _texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bake_mode:
		set_process(false)
		return
	resized.connect(_request_bake)
	_request_bake()


func _request_bake() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var scale: float = maxf(1.0, get_viewport().get_final_transform().get_scale().x)
	var pixels := Vector2i(ceili(size.x * scale), ceili(size.y * scale))
	var key: String = "mentor|%d|%d" % [pixels.x, pixels.y]
	if Baker.has(key):
		_texture = Baker.get_cached(key)
	else:
		var painter: Control = get_script().new()
		painter.bake_mode = true
		_texture = Baker.texture(get_tree(), key, pixels, painter)
	queue_redraw()


## Дед говорит ещё столько секунд.
func talk(seconds: float = 2.0) -> void:
	_talk_left = seconds


var _redraw_left: float = 0.0


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_talk_left = maxf(0.0, _talk_left - delta)
	# Перерисовываем, только пока говорит (и один раз, когда замолчал).
	if _talk_left > 0.0 or _redraw_left > 0.0:
		_redraw_left = 0.1 if _talk_left > 0.0 else 0.0
		queue_redraw()


func _draw() -> void:
	if not bake_mode and _talk_left <= 0.0 and _texture != null:
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size / 2.0
	var u: float = s / 100.0
	var talking: bool = _talk_left > 0.0
	var breath: float = sin(_time * 2.0) * 0.6 * u
	var wiggle: float = sin(_time * 18.0) * 1.6 * u if talking else 0.0

	# Значок-подложка.
	draw_circle(c, 50 * u, Color.WHITE)
	draw_circle(c, 46 * u, BADGE.darkened(0.1))
	draw_colored_polygon(_ellipse(c + Vector2(0, -6) * u, 42 * u, 38 * u), BADGE)
	draw_colored_polygon(_ellipse(c + Vector2(-8, -22) * u, 24 * u, 14 * u), BADGE.lightened(0.18))
	var face := c + Vector2(0, 4 * u + breath)
	# Шея.
	draw_rect(Rect2(face + Vector2(-9, 14) * u, Vector2(18, 14) * u), SKIN_DARK)
	# Рубашка с воротником, тенью и складками.
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-34, 46) * u, c + Vector2(-26, 26) * u + Vector2(0, breath),
		c + Vector2(26, 26) * u + Vector2(0, breath), c + Vector2(34, 46) * u,
	]), SHIRT)
	draw_colored_polygon(PackedVector2Array([c + Vector2(10, 26) * u + Vector2(0, breath), c + Vector2(26, 26) * u + Vector2(0, breath), c + Vector2(34, 46) * u, c + Vector2(15, 46) * u]), SHIRT.darkened(0.15))
	draw_line(c + Vector2(-24, 28) * u, c + Vector2(-15, 27) * u, SHIRT.lightened(0.3), 2 * u)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 26) * u, c + Vector2(0, 38) * u, c + Vector2(12, 26) * u]), Color.WHITE)
	draw_circle(c + Vector2(0, 41) * u, 1.6 * u, Color("cfd8dc"))
	# Уши и лицо с объёмом: тень снизу-справа, свет на лбу и щеке.
	draw_circle(face + Vector2(-25, 2) * u, 6 * u, SKIN_DARK)
	draw_circle(face + Vector2(25, 2) * u, 6 * u, SKIN_DARK)
	draw_circle(face, 25 * u, SKIN_DARK)
	draw_circle(face + Vector2(-1, -1.5) * u, 23.6 * u, SKIN)
	draw_colored_polygon(_ellipse(face + Vector2(-12, 6) * u, 4.5 * u, 3 * u), Color(1, 0.55, 0.5, 0.35))
	draw_colored_polygon(_ellipse(face + Vector2(12, 6) * u, 4.5 * u, 3 * u), Color(1, 0.55, 0.5, 0.3))
	# Морщинки на лбу.
	draw_arc(face + Vector2(0, -2) * u, 12 * u, PI * 1.25, PI * 1.75, 10, SKIN_DARK, 1.5 * u)
	# Кепка таксиста: купол, околыш в шашечку, козырёк.
	var cap_top := face + Vector2(0, -16 * u)
	draw_colored_polygon(_half_ellipse(cap_top, 27 * u, 16 * u), CAP)
	for index in 9:
		var cell := Rect2(cap_top + Vector2(-27 + index * 6, -1) * u, Vector2(6, 5) * u)
		draw_rect(cell, BADGE if index % 2 == 0 else CAP)
	draw_rect(Rect2(cap_top + Vector2(-27, 4) * u, Vector2(54, 3) * u), CAP)
	draw_colored_polygon(PackedVector2Array([
		cap_top + Vector2(-20, 7) * u, cap_top + Vector2(20, 7) * u,
		cap_top + Vector2(14, 11) * u, cap_top + Vector2(-14, 11) * u,
	]), CAP.darkened(0.3))
	# Блик на кепке и значок такси.
	draw_arc(cap_top + Vector2(-4, -2) * u, 18 * u, PI * 1.15, PI * 1.5, 10, Color(1, 1, 1, 0.3), 2.5 * u)
	_round_rect(Rect2(cap_top + Vector2(-5, -11) * u, Vector2(10, 6) * u), 1.5 * u, BADGE)
	# Брови — кустистые, седые.
	draw_line(face + Vector2(-17, -9) * u, face + Vector2(-5, -11) * u, HAIR, 4 * u)
	draw_line(face + Vector2(5, -11) * u, face + Vector2(17, -9) * u, HAIR, 4 * u)
	# Очки с бликом.
	for side in [-1.0, 1.0]:
		var lens := Rect2(face + Vector2(side * 11 - 8, -7) * u, Vector2(16, 10) * u)
		_round_rect(lens, 4 * u, GLASSES)
		draw_line(lens.position + Vector2(3, 3) * u, lens.position + Vector2(7, 3) * u, Color(1, 1, 1, 0.6), 1.5 * u)
	draw_line(face + Vector2(-3, -3) * u, face + Vector2(3, -3) * u, GLASSES, 2 * u)
	# Нос.
	draw_circle(face + Vector2(0, 5) * u, 5 * u, SKIN_DARK)
	draw_circle(face + Vector2(1, 4) * u, 2 * u, Color(1, 0.75, 0.65, 0.6))
	# Рот: приоткрывается, когда говорит.
	var mouth_open: float = absf(sin(_time * 14.0)) * 4 * u if talking else 1.2 * u
	draw_colored_polygon(_ellipse(face + Vector2(0, 16) * u, 6 * u, mouth_open), Color("6b2f2f"))
	# Пышные усы — два крыла с завитками.
	var tache := face + Vector2(0, 11 * u + wiggle)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			tache + Vector2(0, -3) * u,
			tache + Vector2(side * 10, -5) * u,
			tache + Vector2(side * 20, -1) * u,
			tache + Vector2(side * 23, 5) * u,
			tache + Vector2(side * 17, 3) * u,
			tache + Vector2(side * 9, 4) * u,
			tache + Vector2(0, 2) * u,
		]), HAIR)
		draw_circle(tache + Vector2(side * 22, 3) * u, 3 * u, HAIR)


func _half_ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 17:
		var angle: float = PI + PI * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 20:
		var angle: float = TAU * float(index) / 20.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * maxf(ry, 0.5)))
	return points


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
