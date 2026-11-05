extends Control
## Фон всей игры: небо с мягким градиентом, солнце, облака и силуэты города внизу —
## два слоя домов (дальний светлее), огоньки окон, телебашня, пальмы.
## Картина один раз «запекается» в изображение и рисуется одной текстурой за кадр.

var top_color: Color = Color("6ccaf7")
var bottom_color: Color = Color("3a8fdc")

var _bake: SubViewport
var _art: Control
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake = SubViewport.new()
	_bake.disable_3d = true
	_bake.transparent_bg = false
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bake)
	_art = Control.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bake.add_child(_art)
	_art.draw.connect(_draw_art)
	resized.connect(_rebake)
	_rebake()


func _rebake() -> void:
	if _bake == null or size.x <= 0.0 or size.y <= 0.0:
		return
	_bake.size = Vector2i(ceili(size.x), ceili(size.y))
	_art.size = size
	_art.queue_redraw()
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()


func _draw() -> void:
	if _bake != null:
		draw_texture(_bake.get_texture(), Vector2.ZERO)


func _draw_art() -> void:
	var c: CanvasItem = _art
	var w: float = size.x
	var h: float = size.y
	# Небо: вертикальный градиент.
	c.draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top_color, top_color, bottom_color, bottom_color]))
	# Солнце с ореолом.
	var sun := Vector2(w * 0.82, h * 0.09)
	for ring in 5:
		c.draw_circle(sun, w * (0.2 - ring * 0.03), Color(1, 1, 0.85, 0.05 + ring * 0.02))
	c.draw_circle(sun, w * 0.06, Color(1, 0.98, 0.85, 0.75))
	# Облака.
	_rng.seed = 7
	for index in 9:
		var at := Vector2(_rng.randf_range(-0.1, 1.05) * w, _rng.randf_range(0.05, 0.55) * h)
		_cloud(c, at, _rng.randf_range(0.6, 1.3) * w * 0.05, 0.16 + _rng.randf() * 0.1)
	# Дальний город — светлый, полупрозрачный.
	_skyline(c, h * 0.78, h * 0.2, Color(1, 1, 1, 0.13), 11, 0.0)
	# Ближний город — темнее, с окнами.
	_skyline(c, h * 0.86, h * 0.22, Color(0.11, 0.25, 0.5, 0.22), 23, 1.0)
	# Земля внизу.
	c.draw_rect(Rect2(Vector2(0, h * 0.94), Vector2(w, h * 0.06)), Color(0.1, 0.22, 0.45, 0.25))


func _cloud(c: CanvasItem, at: Vector2, r: float, alpha: float) -> void:
	var color := Color(1, 1, 1, alpha)
	c.draw_circle(at, r, color)
	c.draw_circle(at + Vector2(r * 1.1, r * 0.2), r * 0.8, color)
	c.draw_circle(at + Vector2(-r * 1.0, r * 0.25), r * 0.7, color)
	c.draw_circle(at + Vector2(r * 0.3, -r * 0.5), r * 0.75, color)


## Ряд домов от земли вверх: прямоугольники разной высоты, крыши, окна, телебашня, пальмы.
func _skyline(c: CanvasItem, ground: float, max_height: float, color: Color, seed_value: int, windows: float) -> void:
	_rng.seed = seed_value
	var x: float = -20.0
	var tower_done: bool = false
	while x < size.x + 20.0:
		var bw: float = _rng.randf_range(0.05, 0.11) * size.x
		var bh: float = _rng.randf_range(0.25, 1.0) * max_height
		var rect := Rect2(Vector2(x, ground - bh), Vector2(bw, bh + size.y))
		c.draw_rect(rect, color)
		# Крыши: плоская с антенной, ступенька или купол.
		match _rng.randi() % 4:
			0:
				c.draw_line(Vector2(x + bw * 0.5, ground - bh), Vector2(x + bw * 0.5, ground - bh - max_height * 0.12), color, 3.0)
			1:
				c.draw_rect(Rect2(Vector2(x + bw * 0.2, ground - bh - max_height * 0.06), Vector2(bw * 0.6, max_height * 0.06)), color)
			2:
				c.draw_circle(Vector2(x + bw * 0.5, ground - bh), bw * 0.3, color)
		if windows > 0.0:
			var cols: int = maxi(2, int(bw / 22.0))
			var rows: int = int(bh / 26.0)
			for row in rows:
				for col in cols:
					if _rng.randf() < 0.45:
						var win := Rect2(Vector2(x + 8 + col * (bw - 16) / cols, ground - bh + 12 + row * 26), Vector2(7, 9))
						c.draw_rect(win, Color(1, 0.95, 0.7, 0.28 * windows))
		# Одна телебашня на дальнем плане.
		if not tower_done and windows == 0.0 and x > size.x * 0.55:
			tower_done = true
			var base := Vector2(x + bw + 24, ground)
			c.draw_line(base, base + Vector2(0, -max_height * 1.55), color, 8.0)
			c.draw_circle(base + Vector2(0, -max_height * 1.2), 18.0, color)
			c.draw_line(base + Vector2(0, -max_height * 1.55), base + Vector2(0, -max_height * 1.8), color, 3.0)
		x += bw + _rng.randf_range(2.0, 14.0)
	# Пальмы между домами на ближнем плане.
	if windows > 0.0:
		for index in 4:
			var px: float = _rng.randf_range(0.05, 0.95) * size.x
			var top := Vector2(px + 8, ground - max_height * 0.35)
			c.draw_line(Vector2(px, ground), top, color, 6.0)
			for angle in [-2.7, -2.1, -1.5, -0.9, -0.4]:
				var dir := Vector2(cos(angle), sin(angle))
				c.draw_line(top, top + dir * max_height * 0.22, color, 7.0)
