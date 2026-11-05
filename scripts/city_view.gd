extends Control
## Город сверху: дороги, кварталы, дома, ваше такси, машины водителей и конкурентов.
## Тап в любом месте — заказ: сигнал tapped с точкой нажатия.

signal tapped(at: Vector2)

const CarArt := preload("res://scripts/car_art.gd")

const GROUND := Color("7fcf6a")
const SIDEWALK := Color("f6d5a8")
const ROAD := Color("4a4570")
const MARK := Color(1, 1, 1, 0.8)
const PARK := Color("5fd068")
const POND := Color("4cc9f0")
const TREE := Color("3dbb67")
const TREE_DARK := Color("238a4a")
const ROOFS := [Color("ff7f6e"), Color("ffc857"), Color("5bc0eb"), Color("9b5de5"), Color("f15bb5"), Color("00c49a"), Color("ff9f1c"), Color("e9ecef")]
const PLAYER_RING := Color("ff4fa3")
const MAX_FLEET_CARS := 16
const MAX_RIVAL_CARS := 8

## Что показать: машина игрока, машины водителей, цвета машин конкурентов.
var player_model: String = "rickshaw"
var player_dirt: float = 0.0
var player_broken: bool = false
var fleet: Array = []
var rival_colors: Array = []

var _xs: Array = []
var _ys: Array = []
var _road: float = 60.0
var _car_size: float = 50.0
var _blocks: Array = []
## Машины на дорогах: {"kind", "slot", "from", "to", "t", "speed"}.
var _cars: Array = []
var _bounce: float = 0.0
var _boost: float = 0.0
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.seed = 2026
	resized.connect(_layout)
	_layout()


## Обновить, кто ездит по городу. Машины, которые уже едут, остаются на своих местах.
func set_state(new_player_model: String, new_player_dirt: float, new_player_broken: bool, new_fleet: Array, new_rivals: Array) -> void:
	player_model = new_player_model
	player_dirt = new_player_dirt
	player_broken = new_player_broken
	fleet = new_fleet.slice(0, MAX_FLEET_CARS)
	rival_colors = new_rivals.slice(0, MAX_RIVAL_CARS)
	_sync_cars()


## Такси подпрыгивает и рвётся вперёд.
func bounce() -> void:
	_bounce = 1.0
	_boost = 0.35


func player_position() -> Vector2:
	for car: Dictionary in _cars:
		if car["kind"] == "player":
			return _car_pos(car)
	return size / 2.0


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_road = clampf(size.x * 0.1, 40.0, 110.0)
	_car_size = _road * 0.8
	_xs = [size.x * 0.1, size.x * 0.5, size.x * 0.9]
	_ys = [size.y * 0.08, size.y * 0.36, size.y * 0.64, size.y * 0.92]
	_build_blocks()
	for car: Dictionary in _cars:
		car["from"] = _clamp_node(car["from"])
		car["to"] = _clamp_node(car["to"])
	queue_redraw()


func _clamp_node(node: Vector2i) -> Vector2i:
	return Vector2i(clampi(node.x, 0, 2), clampi(node.y, 0, 3))


## Кварталы между дорогами: дома, деревья, один парк с прудом.
func _build_blocks() -> void:
	_blocks.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var half: float = _road / 2.0
	var xs: Array = [-_road] + _xs + [size.x + _road]
	var ys: Array = [-_road] + _ys + [size.y + _road]
	for ix in xs.size() - 1:
		for iy in ys.size() - 1:
			var rect := Rect2(Vector2(xs[ix] + half, ys[iy] + half), Vector2(xs[ix + 1] - xs[ix] - _road, ys[iy + 1] - ys[iy] - _road))
			if rect.size.x <= 4.0 or rect.size.y <= 4.0:
				continue
			var block: Dictionary = {"rect": rect, "park": ix == 1 and iy == 2, "houses": [], "trees": []}
			var inner: Rect2 = rect.grow(-_road * 0.18)
			if not block["park"]:
				var columns: int = maxi(1, int(inner.size.x / (_road * 1.05)))
				var rows: int = maxi(1, int(inner.size.y / (_road * 1.05)))
				var cell := Vector2(inner.size.x / columns, inner.size.y / rows)
				for cx in columns:
					for cy in rows:
						if rng.randf() < 0.18:
							block["trees"].append(inner.position + cell * Vector2(cx + 0.5, cy + 0.5))
							continue
						var house := Rect2(inner.position + cell * Vector2(cx, cy), cell).grow(-_road * 0.08)
						block["houses"].append({"rect": house, "roof": ROOFS[rng.randi() % ROOFS.size()], "ac": rng.randf() < 0.6})
			else:
				for index in 7:
					block["trees"].append(inner.position + Vector2(rng.randf() * inner.size.x, rng.randf() * inner.size.y))
			_blocks.append(block)


## Число машин на дорогах подгоняем под игру: лишние уезжают, новые выезжают с края.
func _sync_cars() -> void:
	var want: Dictionary = {"player": 1, "fleet": fleet.size(), "rival": rival_colors.size()}
	var have: Dictionary = {"player": 0, "fleet": 0, "rival": 0}
	var kept: Array = []
	for car: Dictionary in _cars:
		var kind: String = car["kind"]
		if have[kind] < want[kind]:
			car["slot"] = have[kind]
			have[kind] += 1
			kept.append(car)
	_cars = kept
	for kind: String in ["player", "fleet", "rival"]:
		while have[kind] < want[kind]:
			_cars.append(_new_car(kind, have[kind]))
			have[kind] += 1


func _new_car(kind: String, slot: int) -> Dictionary:
	var start := Vector2i(_rng.randi_range(0, 2), _rng.randi_range(0, 3))
	if kind == "player":
		start = Vector2i(1, 1)
	var car: Dictionary = {"kind": kind, "slot": slot, "from": start, "to": start, "t": 1.0}
	car["speed"] = {"player": 0.55, "fleet": 0.45, "rival": 0.4}[kind] * _rng.randf_range(0.85, 1.15)
	_next_target(car)
	car["t"] = _rng.randf()
	return car


## На перекрёстке — случайный поворот, но не назад, если есть выбор.
func _next_target(car: Dictionary) -> void:
	var here: Vector2i = car["to"]
	var came: Vector2i = car["from"]
	var options: Array = []
	for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var next: Vector2i = here + step
		if next.x >= 0 and next.x <= 2 and next.y >= 0 and next.y <= 3 and next != came:
			options.append(next)
	if options.is_empty():
		options.append(came)
	car["from"] = here
	car["to"] = options[_rng.randi() % options.size()]
	car["t"] = 0.0


func _node_pos(node: Vector2i) -> Vector2:
	if _xs.is_empty():
		return Vector2.ZERO
	return Vector2(_xs[node.x], _ys[node.y])


## Правостороннее движение: машина держится своей полосы.
func _car_pos(car: Dictionary) -> Vector2:
	var a: Vector2 = _node_pos(car["from"])
	var b: Vector2 = _node_pos(car["to"])
	var direction: Vector2 = (b - a).normalized()
	var lane: Vector2 = Vector2(-direction.y, direction.x) * _road * 0.24
	return a.lerp(b, car["t"]) + lane


func _car_angle(car: Dictionary) -> float:
	return (_node_pos(car["to"]) - _node_pos(car["from"])).angle()


func _is_stopped(car: Dictionary) -> bool:
	if car["kind"] == "fleet":
		var info: Dictionary = fleet[car["slot"]] if car["slot"] < fleet.size() else {}
		return bool(info.get("broken", false))
	return false


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_bounce = maxf(0.0, _bounce - delta * 4.0)
	_boost = maxf(0.0, _boost - delta)
	for car: Dictionary in _cars:
		if _is_stopped(car):
			continue
		var length: float = maxf(1.0, _node_pos(car["from"]).distance_to(_node_pos(car["to"])))
		var speed: float = float(car["speed"]) * size.x * 0.35
		if car["kind"] == "player":
			if player_broken:
				speed *= 0.3
			if _boost > 0.0:
				speed *= 3.0
		car["t"] = float(car["t"]) + speed * delta / length
		if car["t"] >= 1.0:
			_next_target(car)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	_draw_blocks()
	_draw_roads()
	var player: Dictionary = {}
	for car: Dictionary in _cars:
		match car["kind"]:
			"player":
				player = car
			"fleet":
				var info: Dictionary = fleet[car["slot"]] if car["slot"] < fleet.size() else {}
				var broken: bool = bool(info.get("broken", false))
				CarArt.draw_car(self, _car_pos(car), _car_angle(car), str(info.get("model", "old_sedan")), _car_size, Color(0, 0, 0, 0), float(info.get("dirt", 0)), broken)
				if broken:
					_draw_smoke(_car_pos(car))
			"rival":
				var color: Color = rival_colors[car["slot"]] if car["slot"] < rival_colors.size() else Color.GRAY
				CarArt.draw_car(self, _car_pos(car), _car_angle(car), "old_sedan", _car_size * 0.95, color)
	if not player.is_empty():
		var pos: Vector2 = _car_pos(player)
		var pulse: float = 1.0 + 0.08 * sin(_time * 4.0)
		draw_arc(pos, _car_size * 0.85 * pulse, 0, TAU, 32, Color(PLAYER_RING, 0.7), 4.0)
		var scale_up: float = 1.25 + 0.25 * _bounce
		CarArt.draw_car(self, pos + Vector2(0, -10.0 * _bounce), _car_angle(player), player_model, _car_size * scale_up, Color(0, 0, 0, 0), player_dirt, player_broken)
		if player_broken:
			_draw_smoke(pos)
		var font: Font = get_theme_default_font()
		draw_string_outline(font, pos + Vector2(-60, -_car_size * 1.05), "ВЫ", HORIZONTAL_ALIGNMENT_CENTER, 120, 28, 8, Color.WHITE)
		draw_string(font, pos + Vector2(-60, -_car_size * 1.05), "ВЫ", HORIZONTAL_ALIGNMENT_CENTER, 120, 28, PLAYER_RING)


func _draw_blocks() -> void:
	for block: Dictionary in _blocks:
		var rect: Rect2 = block["rect"]
		draw_rect(rect, SIDEWALK)
		var inner: Rect2 = rect.grow(-_road * 0.12)
		if block["park"]:
			draw_rect(inner, PARK)
			draw_circle(inner.get_center(), minf(inner.size.x, inner.size.y) * 0.22, POND)
			draw_circle(inner.get_center() + Vector2(-6, -6), minf(inner.size.x, inner.size.y) * 0.08, Color(1, 1, 1, 0.15))
		for house: Dictionary in block["houses"]:
			var r: Rect2 = house["rect"]
			# Двускатная крыша сверху: тень, кромка, светлый и тёмный скат, конёк.
			var roof: Color = house["roof"]
			draw_rect(Rect2(r.position + Vector2(5, 7), r.size), Color(0, 0, 0, 0.22))
			draw_rect(r, roof.darkened(0.3))
			var inner_roof: Rect2 = r.grow(-3)
			var half_h: float = inner_roof.size.y / 2.0
			draw_rect(Rect2(inner_roof.position, Vector2(inner_roof.size.x, half_h)), roof.lightened(0.12))
			draw_rect(Rect2(inner_roof.position + Vector2(0, half_h), Vector2(inner_roof.size.x, half_h)), roof)
			draw_line(inner_roof.position + Vector2(0, half_h), inner_roof.position + Vector2(inner_roof.size.x, half_h), roof.darkened(0.25), 3.0)
			if house["ac"]:
				var dormer := Rect2(inner_roof.position + Vector2(inner_roof.size.x * 0.62, half_h * 0.35), Vector2(inner_roof.size.x * 0.2, half_h * 0.45))
				draw_rect(dormer, Color("5bc0eb").darkened(0.2))
				draw_rect(dormer.grow(-2), Color("bde7ff"))
		for tree: Vector2 in block["trees"]:
			draw_circle(tree + Vector2(3, 4), _road * 0.28, Color(0, 0, 0, 0.25))
			draw_circle(tree, _road * 0.28, TREE_DARK)
			draw_circle(tree + Vector2(-3, -3), _road * 0.2, TREE)


func _draw_roads() -> void:
	var half: float = _road / 2.0
	for x: float in _xs:
		draw_rect(Rect2(Vector2(x - half, 0), Vector2(_road, size.y)), ROAD)
	for y: float in _ys:
		draw_rect(Rect2(Vector2(0, y - half), Vector2(size.x, _road)), ROAD)
	for x: float in _xs:
		draw_dashed_line(Vector2(x, 0), Vector2(x, size.y), MARK, 2.0, 14.0)
	for y: float in _ys:
		draw_dashed_line(Vector2(0, y), Vector2(size.x, y), MARK, 2.0, 14.0)
	# Зебры у перекрёстков.
	for x: float in _xs:
		for y: float in _ys:
			draw_rect(Rect2(Vector2(x - half, y - half), Vector2(_road, _road)), ROAD)
			for stripe in 4:
				var offset: float = -half + _road * (0.12 + stripe * 0.22)
				draw_rect(Rect2(Vector2(x + offset, y - half - 10), Vector2(_road * 0.1, 8)), MARK)
				draw_rect(Rect2(Vector2(x + offset, y + half + 2), Vector2(_road * 0.1, 8)), MARK)


func _draw_smoke(at: Vector2) -> void:
	for index in 3:
		var phase: float = fmod(_time * 0.7 + index * 0.33, 1.0)
		var puff: Vector2 = at + Vector2(sin(phase * 6.0 + index) * 6.0, -phase * _car_size * 1.2)
		draw_circle(puff, _car_size * (0.15 + phase * 0.25), Color(0.75, 0.75, 0.78, 0.55 * (1.0 - phase)))


## Касание на телефоне Godot сам превращает в нажатие мыши — слушаем только его,
## иначе один тап засчитается дважды.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			tapped.emit(mouse.position)
