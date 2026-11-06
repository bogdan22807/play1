extends Control
## Канат противостояния: вы слева, босс справа. Узел стартует в центре и ползёт к вам,
## пока вы тянете (сильнее соперника); у вашего края — финишный флажок, там соперник сдаётся.
## Без progress (старый режим) узел показывает соотношение сил по логарифмической шкале.

const Portrait := preload("res://scripts/boss_portrait.gd")
const CarArt := preload("res://scripts/car_art.gd")

const ROPE := Color("c8925a")
const ROPE_DARK := Color("9c6b3c")
const KNOT := Color("e5484d")
const TRACK := Color("fdeccf")
const PLAYER_BG := Color("ffc93c")

var player_model: String = "old_sedan"
var rival_color: Color = Color("a0aec8")
## Ваша сила / сила соперника (0..1 и больше).
var ratio: float = 0.0
## Где канат: 0 — в центре, 1 — перетянули к себе. Меньше 0 — берём по соотношению сил.
var progress: float = -1.0
var _shown: float = 0.0
var _time: float = 0.0
var _portrait: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 170)
	_portrait = Portrait.new()
	add_child(_portrait)
	resized.connect(_place)


func set_rival(look: Dictionary, color: Color) -> void:
	_portrait.set_look(look)
	rival_color = color
	queue_redraw()


## Узел: 0 — у вас (далеко), 0.5 — центр (догнали).
func _target() -> float:
	if progress >= 0.0:
		return 0.5 - 0.5 * clampf(progress, 0.0, 1.0)
	if ratio <= 0.0:
		return 0.0
	return 0.5 * (1.0 + clampf(log(ratio) / log(10.0) / 2.0, -1.0, 0.0))


func _place() -> void:
	if _portrait == null:
		return
	var side: float = size.y
	_portrait.position = Vector2(size.x - side, 0)
	_portrait.size = Vector2(side, side)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Перерисовываем, только пока узел едет к новому месту.
	var target: float = _target()
	if absf(_shown - target) < 0.0005:
		return
	_shown = lerpf(_shown, target, clampf(delta * 3.0, 0.0, 1.0))
	if absf(_shown - target) < 0.0005:
		_shown = target
	queue_redraw()


func _draw() -> void:
	var side: float = size.y
	var left_center := Vector2(side / 2.0, side / 2.0)
	var right_center := Vector2(size.x - side / 2.0, side / 2.0)
	var y: float = side / 2.0
	var rope_left: float = side * 0.9
	var rope_right: float = size.x - side * 0.9
	# Дорожка под канатом: ваша половина тёплая, половина соперника — его цветом.
	var track := Rect2(Vector2(side * 0.5, y - side * 0.2), Vector2(size.x - side, side * 0.4))
	_round_rect(track, side * 0.2, TRACK)
	var middle: float = lerpf(rope_left, rope_right, 0.5)
	_round_rect(Rect2(Vector2(middle, track.position.y), Vector2(track.end.x - middle, track.size.y)), side * 0.2, Color(rival_color, 0.35))
	# Канат с косыми витками; чуть провисает.
	var sag: float = 0.0
	draw_line(Vector2(rope_left, y + sag), Vector2(rope_right, y + sag), ROPE, side * 0.09)
	var step: float = side * 0.12
	var x: float = rope_left
	while x < rope_right:
		draw_line(Vector2(x, y + sag - side * 0.04), Vector2(x + step * 0.5, y + sag + side * 0.04), ROPE_DARK, 2.0)
		x += step
	# Финишный флажок: у вашего края в режиме каната, иначе в центре.
	var flag_x: float = rope_left + side * 0.05 if progress >= 0.0 else middle
	draw_line(Vector2(flag_x, y - side * 0.42), Vector2(flag_x, y + side * 0.3), Color("1c2b4d"), 3.0)
	for row in 2:
		for col in 3:
			var cell := Rect2(Vector2(flag_x + col * side * 0.07, y - side * 0.42 + row * side * 0.07), Vector2(side * 0.07, side * 0.07))
			draw_rect(cell, Color("1c2b4d") if (row + col) % 2 == 0 else Color.WHITE)
	# Узел-бант.
	var knot := Vector2(lerpf(rope_left, rope_right, _shown), y + sag)
	draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(-side * 0.14, -side * 0.1), knot + Vector2(-side * 0.14, side * 0.1)]), KNOT)
	draw_colored_polygon(PackedVector2Array([knot, knot + Vector2(side * 0.14, -side * 0.1), knot + Vector2(side * 0.14, side * 0.1)]), KNOT)
	draw_circle(knot, side * 0.07, KNOT.darkened(0.2))
	# Вы: жёлтый значок с вашей машиной.
	draw_circle(left_center, side * 0.5, Color.WHITE)
	draw_circle(left_center, side * 0.46, PLAYER_BG)
	var info: Dictionary = CarArt.style(player_model)
	var unit: float = minf(side * 0.7 / float(info.get("length", 1.0)), side * 0.45 / float(info.get("width", 0.5)))
	CarArt.draw_car(self, left_center, 0.0, player_model, unit)
	# Подпись «вы» и рамка у босса рисуются поверх портрета не нужно — портрет сам с рамкой.
	draw_arc(right_center, side * 0.5, 0, TAU, 48, rival_color.darkened(0.2), 4.0)


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
