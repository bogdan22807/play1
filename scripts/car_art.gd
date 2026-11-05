extends RefCounted
## Рисунки машин сверху. Картинок в проекте нет — всё рисуется фигурами.
## Машина смотрит вправо (+X), центр в точке pos. size — длина обычной машины в пикселях.

const STYLES := {
	"rickshaw": {"length": 0.72, "width": 0.42, "body": Color("43a047"), "roof": Color("a5d6a7"), "kind": "rickshaw"},
	"old_sedan": {"length": 0.96, "width": 0.46, "body": Color("c8b88a"), "roof": Color("ddd0a8"), "kind": "sedan", "patch": Color("9e8f64")},
	"city_taxi": {"length": 0.98, "width": 0.46, "body": Color("ffc107"), "roof": Color("ffd54f"), "kind": "taxi"},
	"comfort": {"length": 1.04, "width": 0.48, "body": Color("eceff1"), "roof": Color("ffffff"), "kind": "sedan"},
	"business": {"length": 1.1, "width": 0.5, "body": Color("263238"), "roof": Color("37474f"), "kind": "business"},
	"electric": {"length": 1.0, "width": 0.48, "body": Color("26c6da"), "roof": Color("80deea"), "kind": "electric"},
	"minivan": {"length": 1.12, "width": 0.52, "body": Color("1e88e5"), "roof": Color("64b5f6"), "kind": "minivan"},
	"limo": {"length": 1.7, "width": 0.52, "body": Color("212121"), "roof": Color("303030"), "kind": "limo"},
}
const GLASS := Color("1c2a3a")
const HEADLIGHT := Color("fff59d")
const TAILLIGHT := Color("e53935")
const DIRT := Color("6d4c2f")


static func style(model: String) -> Dictionary:
	return STYLES.get(model, STYLES["old_sedan"])


## Длина машины этой модели при заданном размере, чтобы раскладывать машины без наложения.
static func length_of(model: String, size: float) -> float:
	return float(style(model).get("length", 1.0)) * size


## Нарисовать машину. body_override — цвет кузова для машин конкурентов.
## dirt 0..1 — насколько машина грязная, broken — стоит без движения, серее.
static func draw_car(canvas: CanvasItem, pos: Vector2, angle: float, model: String, size: float,
		body_override: Color = Color(0, 0, 0, 0), dirt: float = 0.0, broken: bool = false) -> void:
	var info: Dictionary = style(model)
	var length: float = float(info.get("length", 1.0)) * size
	var width: float = float(info.get("width", 0.46)) * size
	var body: Color = info.get("body", Color.WHITE)
	var roof: Color = info.get("roof", Color.WHITE)
	if body_override.a > 0.0:
		body = body_override
		roof = body_override.lightened(0.25)
	if broken:
		body = body.lerp(Color("555a66"), 0.55)
		roof = roof.lerp(Color("666b77"), 0.55)
	canvas.draw_set_transform(pos, angle, Vector2.ONE)
	var half := Vector2(length, width) * 0.5

	# Тень и кузов.
	_round_rect(canvas, Rect2(-half + Vector2(3, 5), Vector2(length, width)), width * 0.32, Color(0, 0, 0, 0.28))
	var kind: String = str(info.get("kind", "sedan"))
	if kind == "rickshaw":
		_draw_rickshaw(canvas, length, width, body, roof)
	else:
		_round_rect(canvas, Rect2(-half, Vector2(length, width)), width * 0.32, body)
		_draw_cabin(canvas, kind, length, width, roof, info)
		# Фары спереди, стоп-сигналы сзади.
		for side in [-1.0, 1.0]:
			canvas.draw_rect(Rect2(Vector2(half.x - size * 0.05, side * width * 0.3 - size * 0.035), Vector2(size * 0.05, size * 0.07)), HEADLIGHT)
			canvas.draw_rect(Rect2(Vector2(-half.x, side * width * 0.3 - size * 0.03), Vector2(size * 0.04, size * 0.06)), TAILLIGHT)
	if dirt > 0.02:
		# Пятна грязи: чем грязнее, тем больше и темнее.
		var spots: Array = [Vector2(-0.3, -0.25), Vector2(0.15, 0.3), Vector2(0.35, -0.15), Vector2(-0.05, 0.05)]
		for spot: Vector2 in spots:
			canvas.draw_circle(Vector2(spot.x * length, spot.y * width), width * 0.2 * (0.5 + dirt), Color(DIRT, 0.55 * dirt))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_cabin(canvas: CanvasItem, kind: String, length: float, width: float, roof: Color, info: Dictionary) -> void:
	var front: float = length * 0.5
	var glass_w: float = width * 0.8
	if kind == "limo":
		# Длинный салон с окнами по бокам.
		canvas.draw_rect(Rect2(Vector2(front - length * 0.24, -glass_w / 2.0), Vector2(length * 0.08, glass_w)), GLASS)
		canvas.draw_rect(Rect2(Vector2(-front + length * 0.08, -glass_w / 2.0), Vector2(length * 0.06, glass_w)), GLASS)
		_round_rect(canvas, Rect2(Vector2(-front + length * 0.14, -width * 0.38), Vector2(length * 0.62, width * 0.76)), width * 0.15, roof)
		for index in 4:
			var x: float = -front + length * (0.2 + index * 0.13)
			canvas.draw_rect(Rect2(Vector2(x, -width * 0.42), Vector2(length * 0.09, width * 0.06)), GLASS)
			canvas.draw_rect(Rect2(Vector2(x, width * 0.36), Vector2(length * 0.09, width * 0.06)), GLASS)
		return
	var box: bool = kind == "minivan"
	var windshield_x: float = front - length * (0.36 if box else 0.4)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(windshield_x, -glass_w / 2.0),
		Vector2(windshield_x + length * 0.12, -glass_w / 2.0 + width * 0.06),
		Vector2(windshield_x + length * 0.12, glass_w / 2.0 - width * 0.06),
		Vector2(windshield_x, glass_w / 2.0),
	]), GLASS)
	var rear_x: float = -front + length * (0.08 if box else 0.12)
	canvas.draw_rect(Rect2(Vector2(rear_x, -glass_w / 2.0 + width * 0.05), Vector2(length * 0.08, glass_w - width * 0.1)), GLASS)
	var roof_rect := Rect2(Vector2(rear_x + length * 0.08, -width * 0.38), Vector2(windshield_x - rear_x - length * 0.08, width * 0.76))
	_round_rect(canvas, roof_rect, width * 0.12, roof)
	var center: Vector2 = roof_rect.get_center()
	match kind:
		"taxi":
			# Шашечки на крыше и светящийся знак.
			var cell: float = width * 0.12
			for column in 5:
				for row in 2:
					if (column + row) % 2 == 0:
						canvas.draw_rect(Rect2(center + Vector2((column - 2.5) * cell, (row - 1) * cell), Vector2(cell, cell)), Color.BLACK)
			canvas.draw_rect(Rect2(center + Vector2(-cell * 0.6, -cell * 2.2), Vector2(cell * 1.2, cell * 0.8)), Color("fff8e1"))
		"business":
			canvas.draw_line(Vector2(-length * 0.45, 0), Vector2(length * 0.45, 0), Color("b0bec5"), 2.0)
		"electric":
			var s: float = width * 0.3
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-s * 0.2, -s), center + Vector2(s * 0.5, -s * 0.1), center + Vector2(0, -s * 0.05),
				center + Vector2(s * 0.2, s), center + Vector2(-s * 0.5, s * 0.1), center + Vector2(0, s * 0.05),
			]), Color("fff176"))
		"minivan":
			for side in [-1.0, 1.0]:
				canvas.draw_line(Vector2(roof_rect.position.x, side * width * 0.3), Vector2(roof_rect.end.x, side * width * 0.3), Color("cfd8dc"), 2.0)
	if info.has("patch"):
		# Старый седан: заплатка другого цвета на двери.
		canvas.draw_rect(Rect2(Vector2(-length * 0.05, width * 0.3), Vector2(length * 0.18, width * 0.2)), info["patch"])


static func _draw_rickshaw(canvas: CanvasItem, length: float, width: float, body: Color, roof: Color) -> void:
	var half_l: float = length / 2.0
	# Переднее колесо и руль велосипеда, сзади тент над сиденьем.
	canvas.draw_line(Vector2(half_l * 0.1, 0), Vector2(half_l, 0), Color("37474f"), width * 0.12)
	canvas.draw_rect(Rect2(Vector2(half_l * 0.75, -width * 0.1), Vector2(width * 0.35, width * 0.2)), Color("212121"))
	canvas.draw_line(Vector2(half_l * 0.55, -width * 0.3), Vector2(half_l * 0.55, width * 0.3), Color("90a4ae"), width * 0.08)
	_round_rect(canvas, Rect2(Vector2(-half_l, -width / 2.0), Vector2(length * 0.62, width)), width * 0.2, body)
	_round_rect(canvas, Rect2(Vector2(-half_l + length * 0.05, -width * 0.42), Vector2(length * 0.42, width * 0.84)), width * 0.25, roof)
	canvas.draw_circle(Vector2(half_l * 0.3, 0), width * 0.16, Color("ffcc80"))


## Стили закруглённых прямоугольников живут в кэше: город рисует десятки машин каждый кадр.
static var _boxes: Dictionary = {}


static func _round_rect(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var corner: int = int(maxf(1.0, radius))
	var key: String = "%s|%d" % [color.to_html(true), corner]
	var box: StyleBoxFlat = _boxes.get(key)
	if box == null:
		box = StyleBoxFlat.new()
		box.bg_color = color
		box.set_corner_radius_all(corner)
		box.anti_aliasing = true
		_boxes[key] = box
	canvas.draw_style_box(box, rect)
