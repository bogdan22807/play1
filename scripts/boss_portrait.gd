extends Control
## Портрет босса конкурента, нарисованный фигурами, как дядя Бун.
## Внешность задаётся словарём look (поле "look" у босса в data/competitors.json):
##   bg, skin, hair, hair_color, beard, glasses, hat, hat_color, extra, mouth, eyes, female.
## Когда босс говорит (talk), рот шевелится.

const OUTLINE := Color("1c2b4d")

var look: Dictionary = {}
var _talk_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_look(new_look: Dictionary) -> void:
	look = new_look
	queue_redraw()


func talk(seconds: float = 2.0) -> void:
	_talk_left = seconds


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_talk_left = maxf(0.0, _talk_left - delta)
	queue_redraw()


func _c(key: String, fallback: String) -> Color:
	return Color(str(look.get(key, fallback)))


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size / 2.0
	var u: float = s / 100.0
	var breath: float = sin(_time * 2.0) * 0.5 * u
	var skin: Color = _c("skin", "e3a96f")
	var skin_dark: Color = skin.darkened(0.18)
	var hair_color: Color = _c("hair_color", "2b2b2b")
	var female: bool = bool(look.get("female", false))

	# Подложка-значок.
	draw_circle(c, 50 * u, Color.WHITE)
	draw_circle(c, 46 * u, _c("bg", "a0aec8"))

	var face := c + Vector2(0, 6 * u + breath)
	# Длинные волосы — позади головы.
	match str(look.get("hair", "")):
		"long":
			draw_colored_polygon(_ellipse(face + Vector2(0, 6) * u, 29 * u, 30 * u), hair_color)
		"curly_long":
			for i in 9:
				var angle: float = PI * 0.15 + PI * 0.7 * float(i) / 8.0
				draw_circle(face + Vector2(cos(angle) * 26, sin(angle) * 20 + 2) * u, 9 * u, hair_color)
			draw_colored_polygon(_ellipse(face + Vector2(0, 2) * u, 28 * u, 26 * u), hair_color)
		"bob":
			draw_colored_polygon(_ellipse(face + Vector2(0, 2) * u, 28 * u, 27 * u), hair_color)

	# Одежда: плечи и воротник по характеру.
	_draw_clothes(c, u, breath)

	# Уши, лицо.
	draw_circle(face + Vector2(-24, 2) * u, 5.5 * u, skin_dark)
	draw_circle(face + Vector2(24, 2) * u, 5.5 * u, skin_dark)
	draw_colored_polygon(_ellipse(face, 24 * u, 26 * u), skin)
	if female or bool(look.get("cheeks", false)):
		draw_circle(face + Vector2(-13, 9) * u, 4.5 * u, Color(1, 0.45, 0.45, 0.35))
		draw_circle(face + Vector2(13, 9) * u, 4.5 * u, Color(1, 0.45, 0.45, 0.35))

	_draw_hair(face, u, hair_color)
	_draw_eyes(face, u)
	_draw_glasses(face, u)
	# Нос.
	draw_circle(face + Vector2(0, 5) * u, 3.6 * u, skin_dark)
	_draw_mouth(face, u)
	_draw_beard(face, u, hair_color)
	_draw_hat(face, u)
	_draw_extra(face, c, u)


func _draw_clothes(c: Vector2, u: float, breath: float) -> void:
	var cloth: Color = _c("cloth", "3fb2ff")
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-36, 48) * u, c + Vector2(-27, 30) * u + Vector2(0, breath),
		c + Vector2(27, 30) * u + Vector2(0, breath), c + Vector2(36, 48) * u,
	]), cloth)
	match str(look.get("collar", "")):
		"shirt":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 30) * u, c + Vector2(0, 42) * u, c + Vector2(11, 30) * u]), Color.WHITE)
		"tie":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 30) * u, c + Vector2(0, 40) * u, c + Vector2(11, 30) * u]), Color.WHITE)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 34) * u, c + Vector2(3, 34) * u, c + Vector2(4, 48) * u, c + Vector2(-4, 48) * u]), _c("accent", "d23c3c"))
		"bowtie":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-11, 30) * u, c + Vector2(0, 40) * u, c + Vector2(11, 30) * u]), Color.WHITE)
			var knot := c + Vector2(0, 36) * u
			draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-8, -4) * u, knot + Vector2(-8, 4) * u]), _c("accent", "d23c3c"))
			draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(8, -4) * u, knot + Vector2(8, 4) * u]), _c("accent", "d23c3c"))
		"leather":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-20, 30) * u, c + Vector2(-4, 46) * u, c + Vector2(-12, 30) * u]), Color("444444"))
			draw_colored_polygon(PackedVector2Array([c + Vector2(20, 30) * u, c + Vector2(4, 46) * u, c + Vector2(12, 30) * u]), Color("444444"))
			draw_line(c + Vector2(0, 34) * u, c + Vector2(0, 48) * u, Color("bbbbbb"), 1.5 * u)
		"scarf":
			draw_colored_polygon(_ellipse(c + Vector2(0, 31) * u, 17 * u, 6 * u), _c("accent", "d23c3c"))
			for i in 3:
				draw_line(c + Vector2(-12 + i * 10, 28) * u, c + Vector2(-10 + i * 10, 34) * u, Color.WHITE, 2 * u)
		"shawl":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-30, 34) * u, c + Vector2(0, 46) * u, c + Vector2(30, 34) * u, c + Vector2(24, 29) * u, c + Vector2(-24, 29) * u,
			]), _c("accent", "c75b7a"))
		"bandana":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 29) * u, c + Vector2(0, 42) * u, c + Vector2(14, 29) * u]), _c("accent", "d23c3c"))
		"blazer":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 30) * u, c + Vector2(0, 42) * u, c + Vector2(9, 30) * u]), Color.WHITE)
			draw_line(c + Vector2(-9, 30) * u, c + Vector2(-2, 46) * u, cloth.darkened(0.3), 2.5 * u)
			draw_line(c + Vector2(9, 30) * u, c + Vector2(2, 46) * u, cloth.darkened(0.3), 2.5 * u)


func _draw_hair(face: Vector2, u: float, color: Color) -> void:
	match str(look.get("hair", "")):
		"short":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -10) * u, 24 * u, 17 * u), color)
		"slick":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -10) * u, 24 * u, 18 * u), color)
			draw_arc(face + Vector2(4, -14) * u, 12 * u, PI * 1.1, PI * 1.8, 10, color.lightened(0.3), 1.5 * u)
			# Бакенбарды.
			draw_rect(Rect2(face + Vector2(-24, -10) * u, Vector2(4, 12) * u), color)
			draw_rect(Rect2(face + Vector2(20, -10) * u, Vector2(4, 12) * u), color)
		"bald_sides":
			draw_circle(face + Vector2(-21, -6) * u, 6 * u, color)
			draw_circle(face + Vector2(21, -6) * u, 6 * u, color)
			draw_arc(face + Vector2(-6, -18) * u, 5 * u, PI, TAU, 8, Color(1, 1, 1, 0.5), 1.5 * u)
		"bun":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -9) * u, 25 * u, 18 * u), color)
			draw_circle(face + Vector2(0, -30) * u, 9 * u, color)
		"curly", "curly_long":
			for i in 7:
				var angle: float = PI + PI * float(i) / 6.0
				draw_circle(face + Vector2(cos(angle) * 21, sin(angle) * 19 - 5) * u, 8 * u, color)
		"pompadour":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -10) * u, 24 * u, 16 * u), color)
			draw_colored_polygon(_ellipse(face + Vector2(4, -27) * u, 18 * u, 8 * u), color)
		"messy":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -10) * u, 24 * u, 17 * u), color)
			for i in 5:
				var x: float = -18 + i * 9
				draw_colored_polygon(PackedVector2Array([
					face + Vector2(x - 4, -22) * u, face + Vector2(x + 2, -33) * u, face + Vector2(x + 5, -22) * u,
				]), color)
		"long", "bob":
			draw_colored_polygon(_half_ellipse(face + Vector2(0, -10) * u, 25 * u, 18 * u), color)
			if str(look.get("hair", "")) == "bob":
				draw_rect(Rect2(face + Vector2(-25, -10) * u, Vector2(7, 22) * u), color)
				draw_rect(Rect2(face + Vector2(18, -10) * u, Vector2(7, 22) * u), color)


func _draw_eyes(face: Vector2, u: float) -> void:
	var kind: String = str(look.get("eyes", "dots"))
	for side in [-1.0, 1.0]:
		var eye := face + Vector2(side * 9, -2) * u
		match kind:
			"sleepy":
				draw_arc(eye, 3.5 * u, 0.1, PI - 0.1, 8, OUTLINE, 2 * u)
			"happy":
				draw_arc(eye + Vector2(0, 2) * u, 3.5 * u, PI + 0.2, TAU - 0.2, 8, OUTLINE, 2 * u)
			"lashes":
				draw_circle(eye, 2.8 * u, OUTLINE)
				draw_line(eye + Vector2(side * 2, -2) * u, eye + Vector2(side * 5, -5) * u, OUTLINE, 1.5 * u)
			_:
				draw_circle(eye, 2.8 * u, OUTLINE)
				draw_circle(eye + Vector2(-0.8, -0.8) * u, 0.9 * u, Color.WHITE)
		# Брови.
		var brow_color: Color = _c("brow", str(look.get("hair_color", "2b2b2b")))
		var tilt: float = -2.0 if kind == "angry" else 0.0
		draw_line(eye + Vector2(-5, -6 + tilt * -side) * u, eye + Vector2(5, -6 + tilt * side) * u, brow_color, 2.5 * u)


func _draw_glasses(face: Vector2, u: float) -> void:
	match str(look.get("glasses", "")):
		"sun":
			for side in [-1.0, 1.0]:
				_round_rect(Rect2(face + Vector2(side * 9 - 7, -6) * u, Vector2(14, 9) * u), 3 * u, OUTLINE)
				draw_line(face + Vector2(side * 9 - 4, -4) * u, face + Vector2(side * 9 - 1, -4) * u, Color(1, 1, 1, 0.6), 1.5 * u)
			draw_line(face + Vector2(-2, -3) * u, face + Vector2(2, -3) * u, OUTLINE, 2 * u)
		"round":
			for side in [-1.0, 1.0]:
				draw_arc(face + Vector2(side * 9, -2) * u, 6 * u, 0, TAU, 16, OUTLINE, 1.8 * u)
			draw_line(face + Vector2(-3, -2) * u, face + Vector2(3, -2) * u, OUTLINE, 1.8 * u)
		"square":
			for side in [-1.0, 1.0]:
				var rect := Rect2(face + Vector2(side * 9 - 6.5, -6.5) * u, Vector2(13, 9) * u)
				draw_rect(rect, OUTLINE, false, 2 * u)
			draw_line(face + Vector2(-2.5, -3) * u, face + Vector2(2.5, -3) * u, OUTLINE, 2 * u)
		"goggles":
			draw_rect(Rect2(face + Vector2(-24, -17) * u, Vector2(48, 4) * u), Color("333333"))
			for side in [-1.0, 1.0]:
				draw_circle(face + Vector2(side * 8, -16) * u, 5.5 * u, Color("333333"))
				draw_circle(face + Vector2(side * 8, -16) * u, 3.8 * u, Color("8fd3ff"))


func _draw_mouth(face: Vector2, u: float) -> void:
	var talking: bool = _talk_left > 0.0
	var at := face + Vector2(0, 14) * u
	var lips: Color = _c("lips", "8b3a3a")
	if talking:
		var open: float = 1.0 + absf(sin(_time * 14.0)) * 4.0
		draw_colored_polygon(_ellipse(at, 5.5 * u, open * u), Color("5a2020"))
		return
	match str(look.get("mouth", "smile")):
		"grin":
			draw_colored_polygon(_half_ellipse_down(at + Vector2(0, -1) * u, 8 * u, 6 * u), Color("5a2020"))
			draw_rect(Rect2(at + Vector2(-6, -1) * u, Vector2(12, 2) * u), Color.WHITE)
			if bool(look.get("gold_tooth", false)):
				draw_rect(Rect2(at + Vector2(1, -1) * u, Vector2(3, 2.5) * u), Color("ffd54a"))
		"smirk":
			draw_arc(at + Vector2(2, -3) * u, 6 * u, PI * 0.15, PI * 0.75, 8, lips, 2.2 * u)
		"flat":
			draw_line(at + Vector2(-5, 0) * u, at + Vector2(5, 0) * u, lips, 2.2 * u)
		"shout":
			draw_colored_polygon(_ellipse(at + Vector2(0, 1) * u, 7 * u, 5.5 * u), Color("5a2020"))
			draw_rect(Rect2(at + Vector2(-5, -4) * u, Vector2(10, 2) * u), Color.WHITE)
		_:
			draw_arc(at + Vector2(0, -4) * u, 6 * u, PI * 0.2, PI * 0.8, 10, lips, 2.2 * u)


func _draw_beard(face: Vector2, u: float, color: Color) -> void:
	var beard_color: Color = _c("beard_color", str(look.get("hair_color", "2b2b2b")))
	match str(look.get("beard", "")):
		"stubble":
			for i in 14:
				var angle: float = PI * 0.15 + PI * 0.7 * float(i) / 13.0
				draw_circle(face + Vector2(cos(angle) * 17, sin(angle) * 17 + 4) * u, 0.9 * u, beard_color.darkened(0.2))
		"walrus":
			var tache := face + Vector2(0, 10) * u
			for side in [-1.0, 1.0]:
				draw_colored_polygon(PackedVector2Array([
					tache + Vector2(0, -2) * u, tache + Vector2(side * 10, -4) * u, tache + Vector2(side * 19, 0) * u,
					tache + Vector2(side * 20, 6) * u, tache + Vector2(side * 9, 4) * u, tache + Vector2(0, 2) * u,
				]), beard_color)
		"thin":
			var tache := face + Vector2(0, 10) * u
			for side in [-1.0, 1.0]:
				draw_line(tache, tache + Vector2(side * 9, -1) * u, beard_color, 2 * u)
				draw_arc(tache + Vector2(side * 11, -3) * u, 2.5 * u, 0, TAU, 8, beard_color, 1.5 * u)
		"mustache":
			var tache := face + Vector2(0, 10) * u
			draw_colored_polygon(_ellipse(tache, 9 * u, 2.8 * u), beard_color)
		"goatee":
			draw_colored_polygon(PackedVector2Array([
				face + Vector2(-6, 19) * u, face + Vector2(6, 19) * u, face + Vector2(0, 30) * u,
			]), beard_color)
			draw_colored_polygon(_ellipse(face + Vector2(0, 10) * u, 8 * u, 2.4 * u), beard_color)
		"full":
			draw_colored_polygon(PackedVector2Array([
				face + Vector2(-22, 6) * u, face + Vector2(-14, 24) * u, face + Vector2(0, 30) * u,
				face + Vector2(14, 24) * u, face + Vector2(22, 6) * u, face + Vector2(12, 17) * u,
				face + Vector2(0, 20) * u, face + Vector2(-12, 17) * u,
			]), beard_color)


func _draw_hat(face: Vector2, u: float) -> void:
	var color: Color = _c("hat_color", "1c2b4d")
	var top := face + Vector2(0, -16) * u
	match str(look.get("hat", "")):
		"beret":
			draw_colored_polygon(_ellipse(top + Vector2(3, -4) * u, 22 * u, 9 * u), color)
			draw_line(top + Vector2(3, -13) * u, top + Vector2(5, -18) * u, color, 2.5 * u)
		"fedora":
			draw_colored_polygon(_ellipse(top + Vector2(0, 2) * u, 32 * u, 5 * u), color)
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-17, 1) * u, top + Vector2(-14, -16) * u, top + Vector2(0, -12) * u,
				top + Vector2(14, -16) * u, top + Vector2(17, 1) * u,
			]), color)
			draw_rect(Rect2(top + Vector2(-17, -3) * u, Vector2(34, 4) * u), _c("accent", "d23c3c"))
		"cowboy":
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-36, -4) * u, top + Vector2(-28, 4) * u, top + Vector2(28, 4) * u, top + Vector2(36, -4) * u,
				top + Vector2(24, 0) * u, top + Vector2(-24, 0) * u,
			]), color)
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-17, 1) * u, top + Vector2(-15, -18) * u, top + Vector2(0, -13) * u,
				top + Vector2(15, -18) * u, top + Vector2(17, 1) * u,
			]), color)
			draw_rect(Rect2(top + Vector2(-17, -4) * u, Vector2(34, 4) * u), color.darkened(0.35))
		"safari":
			draw_colored_polygon(_ellipse(top + Vector2(0, 2) * u, 31 * u, 6 * u), color.darkened(0.1))
			draw_colored_polygon(_half_ellipse(top + Vector2(0, 1) * u, 20 * u, 17 * u), color)
			draw_rect(Rect2(top + Vector2(-20, -4) * u, Vector2(40, 3) * u), color.darkened(0.4))
		"straw":
			draw_colored_polygon(_ellipse(top + Vector2(0, 2) * u, 33 * u, 7 * u), color)
			draw_colored_polygon(_half_ellipse(top + Vector2(0, 1) * u, 18 * u, 13 * u), color)
			draw_rect(Rect2(top + Vector2(-18, -4) * u, Vector2(36, 3) * u), _c("accent", "d23c3c"))
		"cap":
			draw_colored_polygon(_half_ellipse(top + Vector2(0, 2) * u, 25 * u, 15 * u), color)
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-2, 1) * u, top + Vector2(28, 1) * u, top + Vector2(26, 6) * u, top + Vector2(-2, 6) * u,
			]), color.darkened(0.25))
		"fez":
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-12, 0) * u, top + Vector2(-9, -18) * u, top + Vector2(9, -18) * u, top + Vector2(12, 0) * u,
			]), color)
			draw_line(top + Vector2(0, -18) * u, top + Vector2(8, -8) * u, Color("1c1c1c"), 2 * u)
		"nightcap":
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-24, 2) * u, top + Vector2(-8, -20) * u, top + Vector2(26, -14) * u, top + Vector2(22, 2) * u,
			]), color)
			draw_circle(top + Vector2(28, -12) * u, 5 * u, Color.WHITE)
			draw_rect(Rect2(top + Vector2(-24, -1) * u, Vector2(48, 5) * u), Color.WHITE)
		"bush":
			draw_colored_polygon(_ellipse(top + Vector2(0, 2) * u, 32 * u, 5 * u), color)
			draw_colored_polygon(_half_ellipse(top + Vector2(0, 1) * u, 19 * u, 15 * u), color)
			draw_colored_polygon(PackedVector2Array([
				top + Vector2(-32, 2) * u, top + Vector2(-20, 2) * u, top + Vector2(-24, -10) * u,
			]), color.darkened(0.2))
		"tophat":
			draw_colored_polygon(_ellipse(top + Vector2(0, 2) * u, 28 * u, 5 * u), color)
			draw_rect(Rect2(top + Vector2(-15, -24) * u, Vector2(30, 26) * u), color)
			draw_rect(Rect2(top + Vector2(-15, -6) * u, Vector2(30, 5) * u), _c("accent", "d23c3c"))
		"headband":
			draw_rect(Rect2(face + Vector2(-24, -14) * u, Vector2(48, 6) * u), color)


func _draw_extra(face: Vector2, c: Vector2, u: float) -> void:
	for item: Variant in look.get("extra", []):
		match str(item):
			"pearls":
				for i in 9:
					var angle: float = PI * 0.15 + PI * 0.7 * float(i) / 8.0
					draw_circle(c + Vector2(cos(angle) * 16, sin(angle) * 8 + 26) * u, 2.4 * u, Color("fff6e0"))
			"flower":
				var at := face + Vector2(-17, -16) * u
				for i in 5:
					var angle: float = TAU * float(i) / 5.0
					draw_circle(at + Vector2(cos(angle), sin(angle)) * 4.5 * u, 3.6 * u, _c("flower", "ff5d8f"))
				draw_circle(at, 2.8 * u, Color("ffd54a"))
			"earrings":
				draw_circle(face + Vector2(-24, 9) * u, 2.6 * u, Color("ffd54a"))
				draw_circle(face + Vector2(24, 9) * u, 2.6 * u, Color("ffd54a"))
			"hoops":
				draw_arc(face + Vector2(-24, 11) * u, 4 * u, 0, TAU, 12, Color("ffd54a"), 1.8 * u)
				draw_arc(face + Vector2(24, 11) * u, 4 * u, 0, TAU, 12, Color("ffd54a"), 1.8 * u)
			"lipstick":
				pass
			"zzz":
				var font: Font = get_theme_default_font()
				var bob: float = sin(_time * 1.5) * 2 * u
				draw_string(font, face + Vector2(18, -26) * u + Vector2(0, bob), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(9 * u), OUTLINE)
				draw_string(font, face + Vector2(25, -33) * u + Vector2(0, bob), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * u), OUTLINE)
			"star":
				var star := face + Vector2(0, -34) * u
				draw_colored_polygon(_star(star, 5 * u, 2.2 * u), Color.WHITE)
			"sweat":
				draw_circle(face + Vector2(20, -12) * u, 2.5 * u, Color("8fd3ff"))


func _star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius: float = outer if i % 2 == 0 else inner
		var angle: float = -PI / 2.0 + PI * float(i) / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _half_ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 17:
		var angle: float = PI + PI * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


func _half_ellipse_down(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 17:
		var angle: float = PI * float(index) / 16.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


func _ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * maxf(ry, 0.5)))
	return points


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
