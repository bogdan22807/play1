extends Control
## Зелёная купюра с «$», которая вылетает при тапе и летит в счётчик денег.
## Рисуется вектором; размер маленький, поэтому десятки купюр не нагружают кадр.

const PAPER := Color("4cc77a")
const PAPER_DARK := Color("1f9d55")
const INK := Color("0f5c33")

const Baker := preload("res://scripts/baker.gd")

var shade: float = 0.0
var bake_mode: bool = false
var _texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bake_mode:
		# Художник рисует купюру 54×30 в удвоенном масштабе (картинка 108×60 — чётко на любом экране).
		size = Vector2(54, 30)
		return
	size = Vector2(54, 30)
	pivot_offset = size / 2.0
	# Четыре оттенка купюр печём один раз — дальше каждая купюра одна картинка.
	var step: float = snappedf(shade, 0.33)
	var key: String = "bill|%.2f" % step
	if Baker.has(key):
		_texture = Baker.get_cached(key)
	else:
		var painter: Control = get_script().new()
		painter.bake_mode = true
		painter.shade = step
		_texture = Baker.texture(get_tree(), key, Vector2i(108, 60), painter)


func _draw() -> void:
	if not bake_mode:
		if _texture != null:
			draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2))
	var paper: Color = PAPER.lerp(Color("7ddc9c"), shade)
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color(0, 0, 0, 0.18))
	var box := StyleBoxFlat.new()
	box.bg_color = paper
	box.border_color = PAPER_DARK
	box.set_border_width_all(2)
	box.set_corner_radius_all(5)
	draw_style_box(box, rect)
	# Внутренняя рамка и овал с «$».
	draw_rect(rect.grow(-5), Color(PAPER_DARK, 0.55), false, 1.5)
	draw_circle(size / 2.0, size.y * 0.32, Color(1, 1, 1, 0.55))
	# Узор-гильош по бокам, номиналы в углах и блик по диагонали.
	for k in 3:
		draw_arc(Vector2(size.x * 0.18, size.y / 2.0), 3.0 + k * 2.5, -PI / 2.0, PI / 2.0, 8, Color(PAPER_DARK, 0.4), 1.0)
		draw_arc(Vector2(size.x * 0.82, size.y / 2.0), 3.0 + k * 2.5, PI / 2.0, PI * 1.5, 8, Color(PAPER_DARK, 0.4), 1.0)
	var font: Font = get_theme_default_font()
	for corner in [Vector2(7, 11), Vector2(size.x - 13, size.y - 4)]:
		draw_string(font, corner, "1", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
	draw_string(font, Vector2(0, size.y * 0.5 + 8), "$", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, INK)
	draw_colored_polygon(PackedVector2Array([Vector2(size.x * 0.55, 2), Vector2(size.x * 0.68, 2), Vector2(size.x * 0.45, size.y - 2), Vector2(size.x * 0.32, size.y - 2)]), Color(1, 1, 1, 0.18))
