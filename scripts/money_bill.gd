extends Control
## Зелёная купюра с «$», которая вылетает при тапе и летит в счётчик денег.
## Рисуется вектором; размер маленький, поэтому десятки купюр не нагружают кадр.

const PAPER := Color("4cc77a")
const PAPER_DARK := Color("1f9d55")
const INK := Color("0f5c33")

var shade: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(54, 30)
	pivot_offset = size / 2.0


func _draw() -> void:
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
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(0, size.y * 0.5 + 8), "$", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, INK)
