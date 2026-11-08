extends Control
## Живой город сверху: дома, дороги, светофоры, пешеходы, ваше такси, машины водителей
## и конкурентов, смена дня и ночи.
## Тап в любом месте — заказ: сигнал tapped с точкой нажатия.
##
## Как это рисуется, чтобы телефон не грелся:
## - дома, дороги, парк, фонари — один раз «запекаются» в дневную картинку;
## - огни ночного города (окна, круги от фонарей) — во вторую картинку, она проявляется ночью;
## - каждый кадр рисуются только машины, пешеходы, светофоры и затемнение.

signal tapped(at: Vector2)

const CarArt := preload("res://scripts/car_art.gd")
const Baker := preload("res://scripts/baker.gd")
const PersonPainter := preload("res://scripts/person_painter.gd")

# >>> PALETTE
const GROUND := Color("9bdc75")
const SIDEWALK := Color("f4f1e8")
const ROAD := Color("5d6582")
const MARK := Color(1, 1, 1, 0.8)
const PARK := Color("78d562")
const POND := Color("4cb8f5")
const TREE := Color("46b35c")
const TREE_DARK := Color("2f8a46")
const ROOFS := [Color("f28b82"), Color("b39ddb"), Color("4fc3f7"), Color("fff6e6"), Color("a5d6a7"), Color("cfd8dc")]
const PLAYER_RING := Color("ffc93c")
# <<< PALETTE
const CURB := Color("d6d0c2")
const LAMP := Color("3d4458")
const WINDOW_GLOW := Color(1.0, 0.86, 0.45)
const NIGHT := Color(0.04, 0.07, 0.22)
const MAX_FLEET_CARS := 16
const MAX_RIVAL_CARS := 8
const WALKERS := 10

## Светофор: зелёный, жёлтый — секунды. Потом то же для другой оси.
const GREEN_SECONDS := 6.0
const YELLOW_SECONDS := 1.5
## Сутки в игре: секунды на полный круг день → вечер → ночь → утро.
const DAY_SECONDS := 240.0

const SHIRTS := [Color("e8434f"), Color("3fa3f5"), Color("2fbf5f"), Color("8b7cf0"), Color("ff8fab"), Color("26a69a"), Color("ffffff")]
const SKINS := [Color("e0b48f"), Color("c98a5a"), Color("8d5a36"), Color("f1c9a0")]

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
## Пешеходы: по кругу вокруг квартала {"block", "pos" 0..1, "speed", "shirt", "skin"}
## и переходящие дорогу {"from", "to", "t", "speed", ...}.
var _walkers: Array = []
var _crossers: Array = []
var _lamps: Array = []
var _bounce: float = 0.0
var _boost: float = 0.0
var _time: float = 0.0
var _day_time: float = 20.0
var _last_phase: Dictionary = {}
var _spawn_timer: float = 0.0
var _rng := RandomNumberGenerator.new()
var _bake: SubViewport
var _static_layer: Control
var _night_bake: SubViewport
var _night_layer: Control
var _cars_layer: Control
## Горящие лампы светофоров: перерисовка только когда какой-то сигнал сменился.
var _lights_layer: Control
var _lights_signature: int = -1
var _lights_timer: float = 0.0
## Что ещё темнеет ночью (фон всей игры). Меняем раз в полсекунды — это почти бесплатно.
var tint_target: CanvasItem
var _tint_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_rng.seed = 2026
	_bake = _make_bake(false)
	_static_layer = _bake.get_child(0)
	_static_layer.draw.connect(_draw_static)
	_night_bake = _make_bake(true)
	_night_layer = _night_bake.get_child(0)
	_night_layer.draw.connect(_draw_night_lights)
	_cars_layer = Control.new()
	_cars_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cars_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cars_layer)
	_cars_layer.draw.connect(_draw_frame)
	_lights_layer = Control.new()
	_lights_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lights_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_lights_layer)
	_lights_layer.draw.connect(_draw_lights)
	resized.connect(_layout)
	_layout()


func _make_bake(transparent: bool) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.transparent_bg = transparent
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var canvas := Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(canvas)
	return viewport


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


## 0 — день, 1 — глубокая ночь.
func night_amount() -> float:
	var phase: float = fmod(_day_time, DAY_SECONDS) / DAY_SECONDS
	# 0..0.45 день, 0.45..0.55 вечер, 0.55..0.9 ночь, 0.9..1 утро.
	if phase < 0.45:
		return 0.0
	if phase < 0.55:
		return smoothstep(0.45, 0.55, phase)
	if phase < 0.9:
		return 1.0
	return 1.0 - smoothstep(0.9, 1.0, phase)


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_road = clampf(size.x * 0.1, 40.0, 110.0)
	_car_size = _road * 0.8
	_xs = [size.x * 0.1, size.x * 0.5, size.x * 0.9]
	_ys = [size.y * 0.08, size.y * 0.36, size.y * 0.64, size.y * 0.92]
	_build_blocks()
	_build_walkers()
	for car: Dictionary in _cars:
		car["from"] = _clamp_node(car["from"])
		car["to"] = _clamp_node(car["to"])
	if _static_layer != null:
		for pair: Array in [[_bake, _static_layer], [_night_bake, _night_layer]]:
			var viewport: SubViewport = pair[0]
			var canvas: Control = pair[1]
			viewport.size = Vector2i(ceili(size.x), ceili(size.y))
			canvas.size = size
			canvas.queue_redraw()
			viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		_cars_layer.queue_redraw()
		_lights_layer.queue_redraw()


func _clamp_node(node: Vector2i) -> Vector2i:
	return Vector2i(clampi(node.x, 0, 2), clampi(node.y, 0, 3))


## Кварталы между дорогами: дома с деталями, деревья, один парк с прудом и дорожками.
func _build_blocks() -> void:
	_blocks.clear()
	_lamps.clear()
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
			var block: Dictionary = {"rect": rect, "park": ix == 1 and iy == 2, "houses": [], "trees": [], "parked": []}
			var inner: Rect2 = rect.grow(-_road * 0.18)
			if not block["park"]:
				var columns: int = maxi(1, int(inner.size.x / (_road * 1.05)))
				var rows: int = maxi(1, int(inner.size.y / (_road * 1.05)))
				var cell := Vector2(inner.size.x / columns, inner.size.y / rows)
				for cx in columns:
					for cy in rows:
						if rng.randf() < 0.15:
							block["trees"].append(inner.position + cell * Vector2(cx + 0.5, cy + 0.5))
							continue
						var house := Rect2(inner.position + cell * Vector2(cx, cy), cell).grow(-_road * 0.08)
						block["houses"].append({
							"rect": house, "roof": ROOFS[rng.randi() % ROOFS.size()],
							"kind": rng.randi() % 4, "seed": rng.randi(),
						})
			else:
				for index in 7:
					block["trees"].append(inner.position + Vector2(rng.randf() * inner.size.x, rng.randf() * inner.size.y))
			_blocks.append(block)
			# Фонари по углам квартала.
			for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
				if rect.has_point(corner + (rect.get_center() - corner).normalized() * 4.0) and rng.randf() < 0.7:
					_lamps.append(corner + (rect.get_center() - corner).normalized() * _road * 0.12)


func _build_walkers() -> void:
	_walkers.clear()
	_crossers.clear()
	if _blocks.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for index in WALKERS:
		_walkers.append({
			"block": rng.randi() % _blocks.size(), "pos": rng.randf(),
			"speed": rng.randf_range(0.018, 0.035) * (1.0 if rng.randf() < 0.5 else -1.0),
			"shirt": SHIRTS[rng.randi() % SHIRTS.size()], "skin": SKINS[rng.randi() % SKINS.size()],
			"phase": rng.randf() * TAU,
		})


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
	car["t"] = _rng.randf() * 0.5
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


func _is_broken(car: Dictionary) -> bool:
	if car["kind"] == "fleet":
		var info: Dictionary = fleet[car["slot"]] if car["slot"] < fleet.size() else {}
		return bool(info.get("broken", false))
	return false


# --- Светофоры -----------------------------------------------------------------

## Сигнал для машин на перекрёстке: "green", "yellow", "red".
## horizontal — машина едет по горизонтальной дороге. У соседних перекрёстков фаза сдвинута.
func _light(node: Vector2i, horizontal: bool) -> String:
	var cycle: float = (GREEN_SECONDS + YELLOW_SECONDS) * 2.0
	var t: float = fmod(_time + float(node.x * 3 + node.y * 5) * 1.3, cycle)
	var mine: float = t if horizontal else fmod(t + cycle / 2.0, cycle)
	if mine < GREEN_SECONDS:
		return "green"
	if mine < GREEN_SECONDS + YELLOW_SECONDS:
		return "yellow"
	return "red"


func _stop_distance() -> float:
	return _road * 0.5 + _road * 0.42


# --- Каждый кадр ------------------------------------------------------------------

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_day_time += delta
	_bounce = maxf(0.0, _bounce - delta * 4.0)
	_boost = maxf(0.0, _boost - delta)
	_move_cars(delta)
	_move_walkers(delta)
	_cars_layer.queue_redraw()
	_lights_timer -= delta
	var signature: int = _lights_signature
	if _lights_timer <= 0.0:
		_lights_timer = 0.1
		signature = _lights_now()
	if signature != _lights_signature:
		_lights_signature = signature
		_lights_layer.queue_redraw()
	_tint_timer -= delta
	if _tint_timer <= 0.0 and tint_target != null:
		_tint_timer = 0.5
		var tint: Color = Color.WHITE.lerp(Color(0.42, 0.48, 0.78), night_amount())
		if not tint_target.modulate.is_equal_approx(tint):
			tint_target.modulate = tint


func _move_cars(delta: float) -> void:
	var stop_at: float = _stop_distance()
	# Машины на одном отрезке дороги в одну сторону — чтобы сравнивать только их.
	var lanes: Dictionary = {}
	for car: Dictionary in _cars:
		var from: Vector2i = car["from"]
		var to: Vector2i = car["to"]
		var key: int = ((from.x * 4 + from.y) * 16) + to.x * 4 + to.y
		if not lanes.has(key):
			lanes[key] = []
		lanes[key].append(car)
		car["lane"] = key
	for car: Dictionary in _cars:
		if _is_broken(car):
			continue
		var a: Vector2 = _node_pos(car["from"])
		var b: Vector2 = _node_pos(car["to"])
		var length: float = maxf(1.0, a.distance_to(b))
		var speed: float = float(car["speed"]) * size.x * 0.35
		if car["kind"] == "player":
			if player_broken:
				speed *= 0.3
			if _boost > 0.0:
				speed *= 3.0
		var t: float = float(car["t"])
		var left: float = (1.0 - t) * length
		var step: float = speed * delta / length
		# Красный или жёлтый — тормозим у стоп-линии (если уже за ней — проезжаем).
		var horizontal: bool = (car["from"] as Vector2i).y == (car["to"] as Vector2i).y
		if _light(car["to"], horizontal) != "green" and left > stop_at - 2.0:
			var limit: float = 1.0 - stop_at / length
			if t + step > limit:
				step = maxf(0.0, limit - t)
		# Не въезжаем в машину впереди на той же полосе.
		for other: Dictionary in lanes[car["lane"]]:
			if other == car:
				continue
			var ahead: float = (float(other["t"]) - t) * length
			var gap: float = _car_size * (1.45 if car["kind"] == "player" or other["kind"] == "player" else 1.2)
			if ahead > 0.0 and ahead < gap + _car_size * 0.1:
				step = minf(step, maxf(0.0, (ahead - gap) / length))
		car["t"] = t + step
		if car["t"] >= 1.0:
			_next_target(car)


func _move_walkers(delta: float) -> void:
	for walker: Dictionary in _walkers:
		walker["pos"] = fposmod(float(walker["pos"]) + float(walker["speed"]) * delta, 1.0)
	# Новые пешеходы на зебрах: когда машинам этой дороги горит красный (проверка 10 раз в секунду).
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		_age_crossers(delta)
		return
	_spawn_timer = 0.1
	for ix in _xs.size():
		for iy in _ys.size():
			var node := Vector2i(ix, iy)
			for horizontal: bool in [true, false]:
				var key: int = ix * 16 + iy * 2 + (1 if horizontal else 0)
				var light: String = _light(node, horizontal)
				if light == "red" and _last_phase.get(key, "") != "red" and _crossers.size() < 10 and _rng.randf() < 0.55:
					_spawn_crosser(node, horizontal)
				_last_phase[key] = light
	_age_crossers(delta)


func _age_crossers(delta: float) -> void:
	var alive: Array = []
	for crosser: Dictionary in _crossers:
		crosser["t"] = float(crosser["t"]) + float(crosser["speed"]) * delta
		if float(crosser["t"]) < 1.0:
			alive.append(crosser)
	_crossers = alive


## Пешеход переходит дорогу, по которой сейчас стоят машины: по зебре у перекрёстка.
func _spawn_crosser(node: Vector2i, cars_horizontal: bool) -> void:
	var center: Vector2 = _node_pos(node)
	var half: float = _road * 0.5
	var side: float = 1.0 if _rng.randf() < 0.5 else -1.0
	var from: Vector2
	var to: Vector2
	if cars_horizontal:
		# Машины по горизонтали стоят — идём поперёк горизонтальной дороги, вертикально.
		var x: float = center.x + side * (half + _road * 0.22)
		from = Vector2(x, center.y - half - 6)
		to = Vector2(x, center.y + half + 6)
	else:
		var y: float = center.y + side * (half + _road * 0.22)
		from = Vector2(center.x - half - 6, y)
		to = Vector2(center.x + half + 6, y)
	if _rng.randf() < 0.5:
		var swap: Vector2 = from
		from = to
		to = swap
	_crossers.append({
		"from": from, "to": to, "t": 0.0, "speed": _rng.randf_range(0.28, 0.4),
		"shirt": SHIRTS[_rng.randi() % SHIRTS.size()], "skin": SKINS[_rng.randi() % SKINS.size()],
		"phase": _rng.randf() * TAU,
	})


## Точка на тротуаре вокруг квартала, pos 0..1 — путь по кругу.
func _walker_point(walker: Dictionary) -> Array:
	var block: Dictionary = _blocks[int(walker["block"]) % _blocks.size()]
	var rect: Rect2 = (block["rect"] as Rect2).grow(-_road * 0.06)
	var perimeter: float = 2.0 * (rect.size.x + rect.size.y)
	var d: float = float(walker["pos"]) * perimeter
	var dir: Vector2
	var at: Vector2
	if d < rect.size.x:
		at = rect.position + Vector2(d, 0)
		dir = Vector2.RIGHT
	elif d < rect.size.x + rect.size.y:
		at = Vector2(rect.end.x, rect.position.y + d - rect.size.x)
		dir = Vector2.DOWN
	elif d < 2.0 * rect.size.x + rect.size.y:
		at = Vector2(rect.end.x - (d - rect.size.x - rect.size.y), rect.end.y)
		dir = Vector2.LEFT
	else:
		at = Vector2(rect.position.x, rect.end.y - (d - 2.0 * rect.size.x - rect.size.y))
		dir = Vector2.UP
	if float(walker["speed"]) < 0.0:
		dir = -dir
	return [at, dir]


# --- Картинки -----------------------------------------------------------------------

func _draw_static() -> void:
	var c: CanvasItem = _static_layer
	c.draw_rect(Rect2(Vector2.ZERO, size), GROUND)
	_draw_blocks(c)
	_draw_roads(c)
	_draw_road_texture(c)
	_draw_light_housings(c)
	for lamp: Vector2 in _lamps:
		c.draw_circle(lamp + Vector2(2, 3), _road * 0.07, Color(0, 0, 0, 0.25))
		c.draw_circle(lamp, _road * 0.065, LAMP)
		c.draw_circle(lamp, _road * 0.035, Color("e8ecf3"))


## Ночные огни: окна домов и световые пятна фонарей. Проявляются ночью.
func _draw_night_lights() -> void:
	var c: CanvasItem = _night_layer
	for lamp: Vector2 in _lamps:
		for ring in 4:
			c.draw_circle(lamp, _road * (0.7 - ring * 0.14), Color(1.0, 0.9, 0.55, 0.07 + ring * 0.04))
		c.draw_circle(lamp, _road * 0.05, Color(1, 0.97, 0.8))
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for block: Dictionary in _blocks:
		for house: Dictionary in block["houses"]:
			var r: Rect2 = (house["rect"] as Rect2).grow(-6)
			var cols: int = maxi(2, int(r.size.x / 14.0))
			var rows: int = maxi(2, int(r.size.y / 18.0))
			for row in rows:
				for col in cols:
					if rng.randf() < 0.35:
						var win := Rect2(r.position + Vector2((col + 0.3) * r.size.x / cols, (row + 0.3) * r.size.y / rows), Vector2(r.size.x / cols * 0.4, r.size.y / rows * 0.35))
						c.draw_rect(win.grow(3), Color(WINDOW_GLOW, 0.25))
						c.draw_rect(win, WINDOW_GLOW)


func _draw_blocks(c: CanvasItem) -> void:
	for block: Dictionary in _blocks:
		var rect: Rect2 = block["rect"]
		c.draw_rect(rect, CURB)
		c.draw_rect(rect.grow(-3), SIDEWALK)
		# Бордюр с объёмом: светлая кромка сверху-слева, тень снизу-справа.
		c.draw_line(rect.position + Vector2(1, 1), Vector2(rect.end.x - 1, rect.position.y + 1), Color(1, 1, 1, 0.6), 2.0)
		c.draw_line(rect.position + Vector2(1, 1), Vector2(rect.position.x + 1, rect.end.y - 1), Color(1, 1, 1, 0.6), 2.0)
		c.draw_line(Vector2(rect.position.x, rect.end.y - 1), rect.end - Vector2(0, 1), Color(0, 0, 0, 0.18), 2.0)
		c.draw_line(Vector2(rect.end.x - 1, rect.position.y), rect.end - Vector2(1, 0), Color(0, 0, 0, 0.18), 2.0)
		# Плитка тротуара: сетка по всей полосе вдоль кварталов.
		var tile: float = _road * 0.16
		var band: float = _road * 0.12
		var x: float = rect.position.x + tile
		while x < rect.end.x:
			for y0 in [rect.position.y + 3, rect.end.y - band]:
				c.draw_line(Vector2(x, y0), Vector2(x, y0 + band - 3), Color(0, 0, 0, 0.06), 1.0)
			x += tile
		var y: float = rect.position.y + tile
		while y < rect.end.y:
			for x0 in [rect.position.x + 3, rect.end.x - band]:
				c.draw_line(Vector2(x0, y), Vector2(x0 + band - 3, y), Color(0, 0, 0, 0.06), 1.0)
			y += tile
		for edge in [rect.position.y + band, rect.end.y - band]:
			c.draw_line(Vector2(rect.position.x + band, edge), Vector2(rect.end.x - band, edge), Color(0, 0, 0, 0.05), 1.0)
		var inner: Rect2 = rect.grow(-_road * 0.12)
		if block["park"]:
			_draw_park(c, inner)
		for house: Dictionary in block["houses"]:
			_draw_house(c, house)
		for tree: Vector2 in block["trees"]:
			_draw_tree(c, tree, _road * 0.28)


func _draw_park(c: CanvasItem, inner: Rect2) -> void:
	c.draw_rect(inner, PARK)
	# Газон «полосками», как после стрижки.
	var stripe: float = _road * 0.22
	var sx: float = inner.position.x
	var odd: bool = false
	while sx < inner.end.x:
		if odd:
			c.draw_rect(Rect2(Vector2(sx, inner.position.y), Vector2(minf(stripe, inner.end.x - sx), inner.size.y)), Color(1, 1, 1, 0.06))
		odd = not odd
		sx += stripe
	# Кусты по краю парка.
	var bush_x: float = inner.position.x + _road * 0.12
	while bush_x < inner.end.x - _road * 0.1:
		for by in [inner.position.y + _road * 0.1, inner.end.y - _road * 0.1]:
			c.draw_circle(Vector2(bush_x, by) + Vector2(2, 3), _road * 0.07, Color(0, 0, 0, 0.15))
			c.draw_circle(Vector2(bush_x, by), _road * 0.07, TREE_DARK)
			c.draw_circle(Vector2(bush_x - 1.5, by - 1.5), _road * 0.045, TREE)
		bush_x += _road * 0.17
	# Дорожки крест-накрест с бордюром.
	var path := Color("e9dcc0")
	for edge_color in [Color("cbbd9c"), path]:
		var w: float = _road * (0.17 if edge_color != path else 0.14)
		c.draw_line(Vector2(inner.position.x, inner.get_center().y), Vector2(inner.end.x, inner.get_center().y), edge_color, w)
		c.draw_line(Vector2(inner.get_center().x, inner.position.y), Vector2(inner.get_center().x, inner.end.y), edge_color, w)
	var pond_r: float = minf(inner.size.x, inner.size.y) * 0.2
	# Фонтан: каменный бортик с тенью, вода с бликами и кругами.
	c.draw_circle(inner.get_center() + Vector2(3, 4), pond_r * 1.18, Color(0, 0, 0, 0.18))
	c.draw_circle(inner.get_center(), pond_r * 1.18, Color("bfb39a"))
	c.draw_circle(inner.get_center(), pond_r * 1.08, Color("dcd2bb"))
	c.draw_circle(inner.get_center(), pond_r, POND.darkened(0.12))
	c.draw_circle(inner.get_center() + Vector2(-pond_r * 0.08, -pond_r * 0.08), pond_r * 0.9, POND)
	for ring in [0.55, 0.75]:
		c.draw_arc(inner.get_center(), pond_r * ring, 0, TAU, 32, Color(1, 1, 1, 0.35), 1.5)
	c.draw_arc(inner.get_center(), pond_r * 0.85, PI * 1.1, PI * 1.5, 12, Color(1, 1, 1, 0.6), 2.5)
	c.draw_circle(inner.get_center(), pond_r * 0.3, Color("8fd3ff"))
	c.draw_circle(inner.get_center(), pond_r * 0.12, Color.WHITE)
	# Скамейки.
	for spot in [Vector2(0.25, 0.35), Vector2(0.75, 0.65)]:
		var at: Vector2 = inner.position + inner.size * spot
		c.draw_rect(Rect2(at - Vector2(_road * 0.18, _road * 0.05), Vector2(_road * 0.36, _road * 0.1)), Color("8d6e63"))
	# Клумбы.
	for spot in [Vector2(0.15, 0.85), Vector2(0.85, 0.15)]:
		var at: Vector2 = inner.position + inner.size * spot
		for petal in 5:
			var angle: float = TAU * petal / 5.0
			c.draw_circle(at + Vector2(cos(angle), sin(angle)) * _road * 0.06, _road * 0.05, Color("ff8fab"))
		c.draw_circle(at, _road * 0.04, Color("ffe082"))


func _draw_tree(c: CanvasItem, at: Vector2, r: float) -> void:
	# Крона из нескольких «шапок» листвы: тень, тёмный низ, светлый верх, блик.
	c.draw_circle(at + Vector2(r * 0.25, r * 0.35), r * 1.05, Color(0, 0, 0, 0.22))
	var lobes: Array = [Vector2(-0.35, 0.1), Vector2(0.35, 0.15), Vector2(0, -0.3), Vector2(0.05, 0.35)]
	for lobe: Vector2 in lobes:
		c.draw_circle(at + lobe * r, r * 0.62, TREE_DARK)
	for lobe: Vector2 in lobes:
		c.draw_circle(at + lobe * r + Vector2(-r * 0.1, -r * 0.12), r * 0.48, TREE)
	c.draw_circle(at + Vector2(-r * 0.25, -r * 0.35), r * 0.3, TREE.lightened(0.18))
	c.draw_circle(at + Vector2(-r * 0.32, -r * 0.42), r * 0.12, Color(1, 1, 1, 0.25))


## Дом сверху: тень, крыша со скатами, конёк и детали на крыше по типу дома.
func _draw_house(c: CanvasItem, house: Dictionary) -> void:
	var r: Rect2 = house["rect"]
	var roof: Color = house["roof"]
	var kind: int = house["kind"]
	c.draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.18))
	c.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.14))
	# Стена дома видна снизу: светлая штукатурка, окна и дверь — дом «стоит», а не лежит.
	var wall_h: float = minf(r.size.y * 0.22, _road * 0.22)
	var wall := Rect2(Vector2(r.position.x, r.end.y - wall_h), Vector2(r.size.x, wall_h))
	var wall_color: Color = Color("efe6d6") if kind != 3 else Color("cfd8dc")
	c.draw_rect(wall, wall_color.darkened(0.08))
	var wins: int = maxi(2, int(r.size.x / 16.0))
	for w in wins:
		var wx: float = wall.position.x + (w + 0.25) * wall.size.x / wins
		c.draw_rect(Rect2(Vector2(wx, wall.position.y + wall_h * 0.25), Vector2(wall.size.x / wins * 0.5, wall_h * 0.45)), Color("5d7fa3"))
		c.draw_rect(Rect2(Vector2(wx, wall.position.y + wall_h * 0.25), Vector2(wall.size.x / wins * 0.5, wall_h * 0.15)), Color("a9cbe8"))
	if kind != 3:
		c.draw_rect(Rect2(Vector2(wall.get_center().x - wall_h * 0.25, wall.position.y + wall_h * 0.3), Vector2(wall_h * 0.5, wall_h * 0.7)), Color("8d5a3b"))
	r = Rect2(r.position, Vector2(r.size.x, r.size.y - wall_h))
	c.draw_rect(r, roof.darkened(0.3))
	var inner: Rect2 = r.grow(-3)
	if kind == 3:
		# Плоская крыша многоэтажки: бордюр, бак с водой, вентиляция, вертолётная «H».
		c.draw_rect(inner, roof.lightened(0.05))
		c.draw_rect(inner.grow(-5), roof.darkened(0.06))
		# Тень от парапета и будка выхода на крышу.
		c.draw_rect(Rect2(inner.position + Vector2(5, 5), Vector2(inner.size.x - 10, 3)), Color(0, 0, 0, 0.1))
		var hut := Rect2(inner.position + inner.size * Vector2(0.08, 0.66), inner.size * Vector2(0.22, 0.22))
		c.draw_rect(Rect2(hut.position + Vector2(3, 3), hut.size), Color(0, 0, 0, 0.18))
		c.draw_rect(hut, Color("b0bec5"))
		c.draw_rect(Rect2(hut.position, Vector2(hut.size.x, hut.size.y * 0.3)), Color("cfd8dc"))
		c.draw_circle(inner.position + inner.size * Vector2(0.28, 0.3), minf(inner.size.x, inner.size.y) * 0.12, Color("b0bec5"))
		c.draw_circle(inner.position + inner.size * Vector2(0.28, 0.3), minf(inner.size.x, inner.size.y) * 0.07, Color("90a4ae"))
		for v in 2:
			c.draw_rect(Rect2(inner.position + inner.size * Vector2(0.62 + v * 0.14, 0.2), inner.size * Vector2(0.1, 0.1)), Color("78909c"))
		var h_at: Vector2 = inner.position + inner.size * Vector2(0.6, 0.65)
		c.draw_arc(h_at, minf(inner.size.x, inner.size.y) * 0.16, 0, TAU, 20, Color.WHITE, 2.0)
		return
	# Двускатная крыша: светлый и тёмный скат, конёк, черепица.
	var half_h: float = inner.size.y / 2.0
	c.draw_rect(Rect2(inner.position, Vector2(inner.size.x, half_h)), roof.lightened(0.12))
	c.draw_rect(Rect2(inner.position + Vector2(0, half_h), Vector2(inner.size.x, half_h)), roof)
	var row: float = inner.position.y + 7.0
	while row < inner.end.y - 2.0:
		c.draw_line(Vector2(inner.position.x, row), Vector2(inner.end.x, row), Color(0, 0, 0, 0.06), 1.0)
		row += 7.0
	c.draw_line(inner.position + Vector2(0, half_h), inner.position + Vector2(inner.size.x, half_h), roof.darkened(0.3), 3.0)
	c.draw_line(inner.position + Vector2(0, half_h - 2), inner.position + Vector2(inner.size.x, half_h - 2), roof.lightened(0.35), 1.5)
	# Свес крыши: светлая кромка сверху, тень внизу.
	c.draw_line(inner.position, inner.position + Vector2(inner.size.x, 0), roof.lightened(0.3), 2.0)
	c.draw_line(inner.position + Vector2(0, inner.size.y), inner.end, roof.darkened(0.2), 2.0)
	match kind:
		0:
			# Труба с дымоходом.
			var chimney := Rect2(inner.position + inner.size * Vector2(0.2, 0.18), inner.size * Vector2(0.14, 0.18))
			c.draw_rect(chimney, Color("8d6e63"))
			c.draw_rect(chimney.grow(-2), Color("5d4037"))
		1:
			# Солнечные панели.
			for p in 3:
				var panel := Rect2(inner.position + inner.size * Vector2(0.12 + p * 0.27, 0.58), inner.size * Vector2(0.22, 0.28))
				c.draw_rect(panel, Color("2f4a7a"))
				c.draw_line(panel.position + Vector2(panel.size.x / 2.0, 0), panel.position + Vector2(panel.size.x / 2.0, panel.size.y), Color("6c8ebf"), 1.0)
		2:
			# Кондиционер и мансардное окно.
			var dormer := Rect2(inner.position + Vector2(inner.size.x * 0.62, half_h * 0.35), Vector2(inner.size.x * 0.2, half_h * 0.45))
			c.draw_rect(dormer, Color("5bc0eb").darkened(0.2))
			c.draw_rect(dormer.grow(-2), Color("bde7ff"))
			var ac := Rect2(inner.position + inner.size * Vector2(0.15, 0.6), inner.size * Vector2(0.2, 0.2))
			c.draw_rect(ac, Color("cfd8dc"))
			c.draw_circle(ac.get_center(), ac.size.x * 0.32, Color("90a4ae"))


func _draw_roads(c: CanvasItem) -> void:
	var half: float = _road / 2.0
	for x: float in _xs:
		c.draw_rect(Rect2(Vector2(x - half, 0), Vector2(_road, size.y)), ROAD)
	for y: float in _ys:
		c.draw_rect(Rect2(Vector2(0, y - half), Vector2(size.x, _road)), ROAD)
	# Края полос и пунктир посередине.
	for x: float in _xs:
		c.draw_dashed_line(Vector2(x, 0), Vector2(x, size.y), MARK, 2.0, 14.0)
		for edge in [-1.0, 1.0]:
			c.draw_line(Vector2(x + edge * (half - 4), 0), Vector2(x + edge * (half - 4), size.y), Color(1, 1, 1, 0.35), 1.5)
	for y: float in _ys:
		c.draw_dashed_line(Vector2(0, y), Vector2(size.x, y), MARK, 2.0, 14.0)
		for edge in [-1.0, 1.0]:
			c.draw_line(Vector2(0, y + edge * (half - 4)), Vector2(size.x, y + edge * (half - 4)), Color(1, 1, 1, 0.35), 1.5)
	# Перекрёстки: чистый асфальт, зебры со всех четырёх сторон, стоп-линии, люки.
	for x: float in _xs:
		for y: float in _ys:
			c.draw_rect(Rect2(Vector2(x - half, y - half), Vector2(_road, _road)), ROAD)
			for stripe in 5:
				var offset: float = -half + _road * (0.08 + stripe * 0.19)
				c.draw_rect(Rect2(Vector2(x + offset, y - half - _road * 0.34), Vector2(_road * 0.1, _road * 0.24)), MARK)
				c.draw_rect(Rect2(Vector2(x + offset, y + half + _road * 0.1), Vector2(_road * 0.1, _road * 0.24)), MARK)
				c.draw_rect(Rect2(Vector2(x - half - _road * 0.34, y + offset), Vector2(_road * 0.24, _road * 0.1)), MARK)
				c.draw_rect(Rect2(Vector2(x + half + _road * 0.1, y + offset), Vector2(_road * 0.24, _road * 0.1)), MARK)
			var stop: float = half + _road * 0.4
			c.draw_line(Vector2(x - half, y - stop), Vector2(x, y - stop), Color.WHITE, 3.0)
			c.draw_line(Vector2(x, y + stop), Vector2(x + half, y + stop), Color.WHITE, 3.0)
			c.draw_line(Vector2(x + stop, y - half), Vector2(x + stop, y), Color.WHITE, 3.0)
			c.draw_line(Vector2(x - stop, y), Vector2(x - stop, y + half), Color.WHITE, 3.0)
			c.draw_circle(Vector2(x + half * 0.45, y - half * 0.45), _road * 0.06, Color("4a5168"))


## Асфальт «живой»: крапинки, заплатки, трещины и решётки ливнёвки (рисуется один раз).
func _draw_road_texture(c: CanvasItem) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var half: float = _road / 2.0
	var lanes: Array = []
	for x: float in _xs:
		lanes.append(Rect2(Vector2(x - half, 0), Vector2(_road, size.y)))
	for y: float in _ys:
		lanes.append(Rect2(Vector2(0, y - half), Vector2(size.x, _road)))
	for lane: Rect2 in lanes:
		var count: int = int(lane.size.x * lane.size.y / 260.0)
		for k in count:
			var at := lane.position + Vector2(rng.randf() * lane.size.x, rng.randf() * lane.size.y)
			c.draw_rect(Rect2(at, Vector2(2, 2)), Color(1, 1, 1, 0.05) if rng.randf() < 0.5 else Color(0, 0, 0, 0.08))
		# Пара заплаток и трещина на каждой улице.
		for k in 2:
			var at := lane.position + Vector2(rng.randf() * lane.size.x, rng.randf() * lane.size.y)
			var patch := Vector2(_road * rng.randf_range(0.2, 0.35), _road * rng.randf_range(0.15, 0.25))
			c.draw_rect(Rect2(at, patch), ROAD.darkened(0.08))
		var crack := lane.position + Vector2(rng.randf() * lane.size.x, rng.randf() * lane.size.y)
		var points := PackedVector2Array([crack])
		for k in 4:
			crack += Vector2(rng.randf_range(-6, 10), rng.randf_range(-6, 10))
			points.append(crack)
		c.draw_polyline(points, Color(0, 0, 0, 0.18), 1.2)
	# Ливнёвки у бордюра рядом с перекрёстками.
	for x: float in _xs:
		for y: float in _ys:
			for at in [Vector2(x - half + 3, y - half - _road * 0.6), Vector2(x + half - 3 - _road * 0.14, y + half + _road * 0.5)]:
				var grate := Rect2(at, Vector2(_road * 0.14, _road * 0.08))
				c.draw_rect(grate, Color("3e4457"))
				for bar in 4:
					c.draw_line(grate.position + Vector2(grate.size.x * (bar + 0.5) / 4.0, 1), grate.position + Vector2(grate.size.x * (bar + 0.5) / 4.0, grate.size.y - 1), Color("6b7385"), 1.0)
			# Люк: обод и рифление.
			var hatch := Vector2(x + half * 0.45, y - half * 0.45)
			c.draw_arc(hatch, _road * 0.06, 0, TAU, 16, Color("6b7385"), 1.5)
			c.draw_line(hatch - Vector2(_road * 0.04, 0), hatch + Vector2(_road * 0.04, 0), Color("6b7385"), 1.0)
			c.draw_line(hatch - Vector2(0, _road * 0.04), hatch + Vector2(0, _road * 0.04), Color("6b7385"), 1.0)


## Каждый кадр: картинка города, ночь, пешеходы, машины с фарами, светофоры.
func _draw_frame() -> void:
	var c: CanvasItem = _cars_layer
	c.draw_texture(_bake.get_texture(), Vector2.ZERO)
	var night: float = night_amount()
	if night > 0.01:
		c.draw_rect(Rect2(Vector2.ZERO, size), Color(NIGHT, 0.55 * night))
		c.draw_texture(_night_bake.get_texture(), Vector2.ZERO, Color(1, 1, 1, night))
	_draw_people(c)
	var player: Dictionary = {}
	for car: Dictionary in _cars:
		if night > 0.05:
			_draw_headlights(c, car, night)
		match car["kind"]:
			"player":
				player = car
			"fleet":
				var info: Dictionary = fleet[car["slot"]] if car["slot"] < fleet.size() else {}
				var broken: bool = bool(info.get("broken", false))
				CarArt.draw_baked(c, _car_pos(car), _car_angle(car), str(info.get("model", "old_sedan")), _car_size, Color(0, 0, 0, 0), float(info.get("dirt", 0)), broken)
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if broken:
					_draw_smoke(c, _car_pos(car))
			"rival":
				var color: Color = rival_colors[car["slot"]] if car["slot"] < rival_colors.size() else Color.GRAY
				CarArt.draw_baked(c, _car_pos(car), _car_angle(car), "old_sedan", _car_size * 0.95, color)
				c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not player.is_empty():
		var pos: Vector2 = _car_pos(player)
		var pulse: float = 1.0 + 0.08 * sin(_time * 4.0)
		c.draw_arc(pos, _car_size * 0.85 * pulse, 0, TAU, 32, Color(PLAYER_RING, 0.7), 4.0)
		var scale_up: float = 1.25 + 0.25 * _bounce
		CarArt.draw_baked(c, pos + Vector2(0, -10.0 * _bounce), _car_angle(player), player_model, _car_size * scale_up, Color(0, 0, 0, 0), player_dirt, player_broken)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if player_broken:
			_draw_smoke(c, pos)
		var font: Font = get_theme_default_font()
		c.draw_string_outline(font, pos + Vector2(-60, -_car_size * 1.05), "ВЫ", HORIZONTAL_ALIGNMENT_CENTER, 120, 28, 8, Color.WHITE)
		c.draw_string(font, pos + Vector2(-60, -_car_size * 1.05), "ВЫ", HORIZONTAL_ALIGNMENT_CENTER, 120, 28, PLAYER_RING)


## Фары: два светлых конуса впереди и красные огни сзади.
func _draw_headlights(c: CanvasItem, car: Dictionary, night: float) -> void:
	var pos: Vector2 = _car_pos(car)
	var angle: float = _car_angle(car)
	var forward := Vector2(cos(angle), sin(angle))
	var side := Vector2(-forward.y, forward.x)
	var nose: Vector2 = pos + forward * _car_size * 0.48
	var reach: float = _car_size * 1.6
	var spread: float = _car_size * 0.55
	c.draw_colored_polygon(PackedVector2Array([
		nose + side * _car_size * 0.18, nose - side * _car_size * 0.18,
		nose + forward * reach - side * spread, nose + forward * reach + side * spread,
	]), Color(1.0, 0.95, 0.7, 0.22 * night))
	var tail: Vector2 = pos - forward * _car_size * 0.5
	c.draw_circle(tail + side * _car_size * 0.14, _car_size * 0.1, Color(1, 0.15, 0.1, 0.5 * night))
	c.draw_circle(tail - side * _car_size * 0.14, _car_size * 0.1, Color(1, 0.15, 0.1, 0.5 * night))


const LIGHT_COLORS := {"red": Color("ff4d5e"), "yellow": Color("ffd54a"), "green": Color("4cff8a")}
const LIGHT_ORDER := ["red", "yellow", "green"]


func _light_box(center: Vector2, horizontal: bool) -> Rect2:
	var half: float = _road * 0.5
	var at: Vector2 = center + (Vector2(half + _road * 0.2, -half - _road * 0.2) if horizontal else Vector2(-half - _road * 0.2, half + _road * 0.2))
	return Rect2(at - Vector2(_road * 0.1, _road * 0.2), Vector2(_road * 0.2, _road * 0.4))


func _lamp_at(body: Rect2, color_name: String) -> Vector2:
	return body.position + Vector2(body.size.x / 2.0, body.size.y * (0.18 + LIGHT_ORDER.find(color_name) * 0.32))


## Корпуса светофоров с погасшими лампами — в неподвижную картинку.
func _draw_light_housings(c: CanvasItem) -> void:
	for x: float in _xs:
		for y: float in _ys:
			for horizontal: bool in [true, false]:
				var body: Rect2 = _light_box(Vector2(x, y), horizontal)
				c.draw_rect(Rect2(body.position + Vector2(2, 3), body.size), Color(0, 0, 0, 0.25))
				c.draw_rect(body, Color("2a2a48"))
				for color_name: String in LIGHT_ORDER:
					c.draw_circle(_lamp_at(body, color_name), _road * 0.055, Color(LIGHT_COLORS[color_name], 0.18))


## Сумма всех сигналов: меняется, когда хоть один светофор переключился.
func _lights_now() -> int:
	var signature: int = 0
	for ix in _xs.size():
		for iy in _ys.size():
			var node := Vector2i(ix, iy)
			signature = signature * 9 + LIGHT_ORDER.find(_light(node, true)) * 3 + LIGHT_ORDER.find(_light(node, false))
	return signature + int(size.x) * 7919


## Горящая лампа каждого светофора.
func _draw_lights() -> void:
	var c: CanvasItem = _lights_layer
	for ix in _xs.size():
		for iy in _ys.size():
			var node := Vector2i(ix, iy)
			var center: Vector2 = _node_pos(node)
			for horizontal: bool in [true, false]:
				var light: String = _light(node, horizontal)
				var at: Vector2 = _lamp_at(_light_box(center, horizontal), light)
				var color: Color = LIGHT_COLORS[light]
				c.draw_circle(at, _road * 0.1, Color(color, 0.3))
				c.draw_circle(at, _road * 0.055, color)


func _draw_people(c: CanvasItem) -> void:
	for walker: Dictionary in _walkers:
		var point: Array = _walker_point(walker)
		_draw_person(c, point[0], point[1], walker)
	for crosser: Dictionary in _crossers:
		var from: Vector2 = crosser["from"]
		var to: Vector2 = crosser["to"]
		var at: Vector2 = from.lerp(to, float(crosser["t"]))
		_draw_person(c, at, (to - from).normalized(), crosser)


## Человечек сверху: ноги шагают, плечи-рубашка, голова.
func _draw_person(c: CanvasItem, at: Vector2, dir: Vector2, info: Dictionary) -> void:
	var r: float = _road * 0.1
	var side := Vector2(-dir.y, dir.x)
	var swing: float = sin(_time * 9.0 + float(info.get("phase", 0.0))) * r * 0.9
	var leg := Vector2(r * 0.7, r * 0.7)
	c.draw_rect(Rect2(at + side * r * 0.45 + dir * swing - leg / 2.0, leg), Color("2a2a48"))
	c.draw_rect(Rect2(at - side * r * 0.45 - dir * swing - leg / 2.0, leg), Color("2a2a48"))
	# Тело и голова — готовая картинка (круги дорого пересчитывать каждый кадр).
	var shirt: Color = info.get("shirt", Color.WHITE)
	var skin: Color = info.get("skin", Color("e0b48f"))
	var key: String = "person|%s|%s" % [shirt.to_html(false), skin.to_html(false)]
	var tex: Texture2D = Baker.get_cached(key)
	if tex == null:
		var painter: Control = PersonPainter.new()
		painter.shirt = shirt
		painter.skin = skin
		tex = Baker.texture(get_tree(), key, Vector2i(48, 48), painter)
	var box: float = r / 0.3
	c.draw_texture_rect(tex, Rect2(at - Vector2(box, box) / 2.0, Vector2(box, box)), false)


func _draw_smoke(c: CanvasItem, at: Vector2) -> void:
	for index in 3:
		var phase: float = fmod(_time * 0.7 + index * 0.33, 1.0)
		var puff: Vector2 = at + Vector2(sin(phase * 6.0 + index) * 6.0, -phase * _car_size * 1.2)
		c.draw_circle(puff, _car_size * (0.15 + phase * 0.25), Color(0.75, 0.75, 0.78, 0.55 * (1.0 - phase)))


## Касание на телефоне Godot сам превращает в нажатие мыши — слушаем только его,
## иначе один тап засчитается дважды.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			tapped.emit(mouse.position)
