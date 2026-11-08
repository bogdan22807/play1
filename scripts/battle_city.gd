extends Control
## «Битва за город»: маленький город с тремя таксопарками конкурентов.
## Над каждым — портрет босса. Ваша доля заливает гараж жёлтым снизу вверх,
## у ворот ваши жёлтые такси вытесняют их машины; купленные стоянка и диспетчерская видны на картинке.

const Portrait := preload("res://scripts/boss_portrait.gd")

const SKY := Color("bfe6ff")
const GROUND := Color("9bdc75")
const ROAD := Color("5d6582")
const LINE := Color("f4f1e8")
const INK := Color("2a2a48")
const TAXI := Color("ffc93c")
const OWNED := Color("2fbf5f")
const ACTIVE := Color("e8434f")
const WAIT := Color("b8bfcc")

## [{"look", "color", "name", "state"}]
var rivals: Array = []
var city_name: String = ""
var _portraits: Array = []
var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 470)
	resized.connect(_place)


func set_rivals(new_rivals: Array, new_city: String) -> void:
	rivals = new_rivals
	city_name = new_city
	while _portraits.size() < rivals.size():
		var face: Control = Portrait.new()
		add_child(face)
		_portraits.append(face)
	for index in _portraits.size():
		var face: Control = _portraits[index]
		face.visible = index < rivals.size()
		if face.visible:
			face.set_look(rivals[index].get("look", {}))
			face.modulate = Color(1, 1, 1, 0.55) if str(rivals[index].get("state", "")) == "waiting" else Color.WHITE
	_place()
	queue_redraw()


func _slot(index: int) -> float:
	var count: int = maxi(1, rivals.size())
	return size.x * (float(index) + 0.5) / float(count)


func _place() -> void:
	var side: float = minf(130.0, size.x / 4.0)
	for index in _portraits.size():
		var face: Control = _portraits[index]
		face.size = Vector2(side, side)
		face.position = Vector2(_slot(index) - side / 2.0, 6)


var _redraw_left: float = 0.0
## Анимация покупки: индекс гаража и время старта (-1 — нет анимации).
var _anim_index: int = -1
var _anim_start: float = 0.0
var _anim_text: String = "+5%"
const ANIM_TIME := 1.6


## Покупка доли или части: жёлтое такси въезжает в гараж соперника, над ним всплывает «+5%».
func play_buy(index: int, text: String = "+5%") -> void:
	_anim_index = index
	_anim_start = _time
	_anim_text = text
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	if _anim_index >= 0:
		if _time - _anim_start > ANIM_TIME:
			_anim_index = -1
		queue_redraw()
		return
	# Пульс и облака — достаточно 10 кадров в секунду.
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 0.1
		queue_redraw()


func _draw() -> void:
	var ground_y: float = size.y * 0.68
	# Небо с градиентом, город на горизонте, облака, земля и дорога.
	_round_rect(Rect2(Vector2.ZERO, size), 26.0, SKY)
	draw_rect(Rect2(Vector2(0, ground_y * 0.55), Vector2(size.x, ground_y * 0.45)), Color(1, 1, 1, 0.18))
	_skyline(ground_y)
	for cloud in [Vector2(0.18, 0.42), Vector2(0.62, 0.34), Vector2(0.88, 0.47)]:
		var at := Vector2(cloud.x * size.x + fmod(_time * 6.0, 40.0) - 20.0, cloud.y * size.y)
		draw_circle(at, 18, Color(1, 1, 1, 0.75))
		draw_circle(at + Vector2(20, 4), 14, Color(1, 1, 1, 0.75))
		draw_circle(at + Vector2(-18, 6), 12, Color(1, 1, 1, 0.75))
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(size.x, size.y - ground_y)), GROUND)
	draw_rect(Rect2(Vector2(0, ground_y + 22), Vector2(size.x, 30)), ROAD)
	var dash: float = fmod(-_time * 30.0, 52.0)
	while dash < size.x:
		draw_rect(Rect2(Vector2(dash, ground_y + 35), Vector2(26, 4)), LINE)
		dash += 52.0

	var font: Font = get_theme_default_font()
	for index in rivals.size():
		var info: Dictionary = rivals[index]
		var state: String = str(info.get("state", ""))
		var pct: float = clampf(float(info.get("pct", 0)) / 100.0, 0.0, 1.0)
		if state == "owned":
			pct = 1.0
		var parts: Array = info.get("parts", [])
		var x: float = _slot(index)
		var width: float = minf(200.0, size.x / 3.3)
		var height: float = 118.0
		var base := Vector2(x - width / 2.0, ground_y - height)
		var wall: Color = Color(str(info.get("color", "a0aec8")))
		if state == "waiting":
			wall = WAIT
		var style: String = str(info.get("style", ""))
		if style == "cunning":
			height = 150.0
			base = Vector2(x - width / 2.0, ground_y - height)
		# Тень и стена цвета компании.
		_round_rect(Rect2(base + Vector2(6, 8), Vector2(width, height)), 12.0, Color(0, 0, 0, 0.12))
		_round_rect(Rect2(base, Vector2(width, height)), 10.0 if style != "cunning" else 6.0, wall)
		# Ваша доля «заливает» здание жёлтым снизу вверх.
		var fill_h: float = height * pct
		if pct > 0.0:
			_round_rect(Rect2(base + Vector2(0, height - fill_h), Vector2(width, fill_h)), 10.0, TAXI)
		# У каждого соперника своё здание.
		match style:
			"aggressive":
				_biker_garage(base, width, height, wall)
			"cunning":
				_glass_office(base, width, height, wall)
			"family":
				_family_house(base, width, height, wall)
			_:
				draw_colored_polygon(PackedVector2Array([
					base + Vector2(-10, 6), base + Vector2(width / 2.0, -24), base + Vector2(width + 10, 6),
				]), wall.darkened(0.3))
		# Шашечки по линии вашей доли.
		if pct > 0.0 and pct < 1.0:
			var stripe_y: float = base.y + height - fill_h
			var cell: float = 8.0
			var cx: float = base.x + 2.0
			var odd: bool = false
			while cx < base.x + width - 2.0:
				draw_rect(Rect2(Vector2(cx, stripe_y - 3), Vector2(minf(cell, base.x + width - 2.0 - cx), 6)), INK if odd else Color.WHITE)
				odd = not odd
				cx += cell
		# Вывеска TAXI.
		var sign_rect := Rect2(base + Vector2(width * 0.25, 6), Vector2(width * 0.5, 22))
		_round_rect(sign_rect, 6.0, INK)
		draw_string(font, sign_rect.position + Vector2(0, 17), "TAXI", HORIZONTAL_ALIGNMENT_CENTER, sign_rect.size.x, 17, TAXI)
		# Ворота.
		var gate := Rect2(base + Vector2(width * 0.28, height - 64), Vector2(width * 0.44, 64))
		var gate_color: Color = wall.darkened(0.45) if pct < 0.6 else TAXI.darkened(0.3)
		if style == "family":
			gate_color = Color("8d5a3b") if pct < 0.6 else TAXI.darkened(0.3)
		_round_rect(gate, 6.0, gate_color)
		for row in 4:
			var ly: float = gate.position.y + gate.size.y * (row + 1) / 5.0
			draw_line(Vector2(gate.position.x + 3, ly), Vector2(gate.end.x - 3, ly), Color(0, 0, 0, 0.25), 2.0)
		# Вспышка при покупке.
		if _anim_index == index:
			var t: float = (_time - _anim_start) / ANIM_TIME
			var flash: float = clampf(1.0 - absf(t - 0.55) * 4.0, 0.0, 1.0)
			if flash > 0.0:
				_round_rect(Rect2(base - Vector2(6, 6), Vector2(width + 12, height + 12)), 14.0, Color(1, 1, 0.7, 0.45 * flash))
		# Машины у гаража: их — цвета компании, ваши — жёлтые. Чем больше доля, тем больше жёлтых.
		var cars: int = 3
		var mine: int = int(roundf(pct * cars))
		if parts.has("fleet_part") and mine < cars:
			mine += 1
		for car in cars:
			var at := Vector2(base.x + width * (0.16 + car * 0.34), ground_y + 14)
			_car(at, TAXI if car < mine else wall.lightened(0.15), car < mine)
		# Купленные части видно прямо на картинке.
		if parts.has("parking"):
			_parking_sign(base + Vector2(-4, height - 54))
		if parts.has("dispatch"):
			_antenna(base + Vector2(width * 0.82, -6))
		# Флажок: ваш, когда компания ваша; замок — если остров ещё не открыт.
		match state:
			"owned":
				_flag(base + Vector2(width / 2.0, -24), TAXI.darkened(0.1), true)
			"waiting":
				_lock(base + Vector2(width / 2.0, height * 0.18))
		# Подпись: название и ваша доля.
		var name_text: String = str(info.get("name", ""))
		var state_text: String = {"owned": "ваш ✓", "active": "ваши %d%%" % int(info.get("pct", 0)), "waiting": "ждёт"}.get(state, "")
		var state_color: Color = {"owned": OWNED.darkened(0.2), "active": INK, "waiting": Color("6b7385")}.get(state, INK)
		_text(font, Vector2(x, size.y - 48), name_text, 24, INK, Color(1, 1, 1, 0.9))
		_text(font, Vector2(x, size.y - 14), state_text, 30, state_color, Color.WHITE)
	_draw_buy_anim(ground_y, font)


## Жёлтое такси едет по дороге к гаражу, потом над гаражом всплывает «+5%» и искры.
func _draw_buy_anim(ground_y: float, font: Font) -> void:
	if _anim_index < 0 or _anim_index >= rivals.size():
		return
	var t: float = clampf((_time - _anim_start) / ANIM_TIME, 0.0, 1.0)
	var target_x: float = _slot(_anim_index)
	var drive: float = clampf(t / 0.55, 0.0, 1.0)
	drive = 1.0 - pow(1.0 - drive, 3.0)
	if t < 0.6:
		var car_x: float = lerpf(-40.0, target_x, drive)
		var car_y: float = ground_y + 30.0 - (12.0 * drive if drive > 0.85 else 0.0)
		draw_set_transform(Vector2(car_x, car_y), 0.0, Vector2(1.5, 1.5))
		_car(Vector2.ZERO, TAXI, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 3:
			draw_circle(Vector2(car_x - 40.0 - k * 14.0, car_y + 6.0), 5.0 - k, Color(1, 1, 1, 0.6 - k * 0.15))
	if t > 0.5:
		var up: float = (t - 0.5) / 0.5
		var alpha: float = 1.0 - maxf(0.0, up - 0.6) / 0.4
		var y: float = ground_y - 30.0 - up * 50.0
		var w: float = 160.0
		draw_string_outline(font, Vector2(target_x - w / 2.0, y), _anim_text, HORIZONTAL_ALIGNMENT_CENTER, w, 44, 8, Color(1, 1, 1, alpha))
		draw_string(font, Vector2(target_x - w / 2.0, y), _anim_text, HORIZONTAL_ALIGNMENT_CENTER, w, 44, Color(OWNED.darkened(0.15), alpha))
		for k in 8:
			var angle: float = TAU * k / 8.0 + up
			var r: float = 30.0 + up * 60.0
			draw_circle(Vector2(target_x, ground_y - 50.0) + Vector2(cos(angle), sin(angle)) * r, 5.0 * (1.0 - up) + 1.0, Color(TAXI, alpha))


func _biker_garage(base: Vector2, width: float, height: float, wall: Color) -> void:
	# Кирпичная коробка с плоской крышей, бочка и гаечный ключ на стене.
	var line := Color(0, 0, 0, 0.16)
	var y: float = base.y + 34.0
	var row: int = 0
	while y < base.y + height - 2.0:
		draw_line(Vector2(base.x + 2, y), Vector2(base.x + width - 2, y), line, 2.0)
		var bx: float = base.x + (10.0 if row % 2 == 0 else 24.0)
		while bx < base.x + width - 4.0:
			draw_line(Vector2(bx, y), Vector2(bx, minf(y + 12.0, base.y + height - 2.0)), line, 2.0)
			bx += 28.0
		y += 12.0
		row += 1
	draw_rect(Rect2(base + Vector2(-6, -8), Vector2(width + 12, 12)), wall.darkened(0.45))
	draw_rect(Rect2(base + Vector2(-6, -12), Vector2(width + 12, 5)), INK)
	# Бочка у стены.
	_round_rect(Rect2(base + Vector2(width - 18, height - 30), Vector2(22, 30)), 4.0, Color("c0392b"))
	draw_line(base + Vector2(width - 18, height - 20), base + Vector2(width + 4, height - 20), Color(0, 0, 0, 0.35), 2.0)
	draw_line(base + Vector2(width - 18, height - 10), base + Vector2(width + 4, height - 10), Color(0, 0, 0, 0.35), 2.0)


func _glass_office(base: Vector2, width: float, height: float, wall: Color) -> void:
	# Стеклянный офис: сетка окон с бликами и золотая полоса по крыше.
	var glass := Color(0.75, 0.9, 1.0, 0.55)
	var top: float = base.y + 36.0
	var bottom: float = base.y + height - 72.0
	var cols: int = 4
	var col_w: float = (width - 16.0) / float(cols)
	var y: float = top
	while y < bottom:
		for col in cols:
			var cell := Rect2(Vector2(base.x + 8.0 + col * col_w + 2.0, y), Vector2(col_w - 4.0, 14.0))
			draw_rect(cell, glass)
			draw_line(cell.position + Vector2(3, 11), cell.position + Vector2(10, 3), Color(1, 1, 1, 0.7), 2.0)
		y += 18.0
	draw_rect(Rect2(base + Vector2(-4, -6), Vector2(width + 8, 8)), Color("d4a017"))
	draw_rect(Rect2(base + Vector2(width / 2.0 - 2, -26), Vector2(4, 20)), INK)
	draw_circle(base + Vector2(width / 2.0, -28), 4, Color("e8434f"))


func _family_house(base: Vector2, width: float, height: float, wall: Color) -> void:
	# Старый семейный двор: доски, черепичная крыша с трубой и дымком, цветы в горшках.
	for k in range(1, int(width / 14.0)):
		draw_line(Vector2(base.x + k * 14.0, base.y + 32.0), Vector2(base.x + k * 14.0, base.y + height - 2.0), Color(0, 0, 0, 0.1), 2.0)
	var roof := PackedVector2Array([base + Vector2(-12, 8), base + Vector2(width / 2.0, -34), base + Vector2(width + 12, 8)])
	draw_colored_polygon(roof, Color("c2553b"))
	for k in 3:
		var t: float = (k + 1) / 4.0
		draw_line(base + Vector2(-12 + (width / 2.0 + 12) * t, 8 - 42 * t), base + Vector2(width + 12 - (width / 2.0 + 12) * t, 8 - 42 * t), Color(0, 0, 0, 0.18), 2.0)
	draw_rect(Rect2(base + Vector2(width * 0.72, -36), Vector2(14, 30)), Color("8d5a3b"))
	for k in 3:
		var drift: float = fmod(_time * 12.0 + k * 14.0, 42.0)
		draw_circle(base + Vector2(width * 0.72 + 7 + drift * 0.4, -40 - drift), 5.0 + drift * 0.12, Color(1, 1, 1, 0.55 - drift / 90.0))
	for fx in [6.0, width - 22.0]:
		_round_rect(Rect2(base + Vector2(fx, height - 16), Vector2(16, 14)), 3.0, Color("b5651d"))
		draw_circle(base + Vector2(fx + 5, height - 20), 5, Color("e8434f"))
		draw_circle(base + Vector2(fx + 11, height - 22), 5, Color("ffc93c"))


func _skyline(ground_y: float) -> void:
	var tones := [Color("9fc9ea"), Color("8dbbe0")]
	var x: float = 0.0
	var index: int = 0
	while x < size.x:
		var w: float = 34.0 + float((index * 37) % 30)
		var h: float = 50.0 + float((index * 53) % 70)
		draw_rect(Rect2(Vector2(x, ground_y - h), Vector2(w, h)), tones[index % 2])
		for wy in range(int(ground_y - h + 8), int(ground_y - 8), 14):
			for wx in range(int(x + 6), int(x + w - 6), 10):
				if (wx + wy + index) % 3 != 0:
					draw_rect(Rect2(Vector2(wx, wy), Vector2(4, 6)), Color(1, 1, 1, 0.35))
		x += w + 4.0
		index += 1


func _car(at: Vector2, body: Color, mine: bool) -> void:
	_round_rect(Rect2(at + Vector2(-22, -10), Vector2(44, 16)), 6.0, body)
	_round_rect(Rect2(at + Vector2(-12, -19), Vector2(24, 11)), 4.0, body.darkened(0.08))
	draw_rect(Rect2(at + Vector2(-9, -17), Vector2(18, 6)), Color("bfe6ff"))
	if mine:
		for k in 4:
			draw_rect(Rect2(at + Vector2(-16 + k * 8, -4), Vector2(4, 4)), INK)
	draw_circle(at + Vector2(-12, 7), 5, INK)
	draw_circle(at + Vector2(12, 7), 5, INK)


func _parking_sign(at: Vector2) -> void:
	draw_rect(Rect2(at + Vector2(10, 20), Vector2(4, 34)), Color("7a8399"))
	_round_rect(Rect2(at, Vector2(26, 26)), 5.0, Color("2b6cb0"))
	draw_string(get_theme_default_font(), at + Vector2(0, 21), "P", HORIZONTAL_ALIGNMENT_CENTER, 26, 22, Color.WHITE)


func _antenna(at: Vector2) -> void:
	draw_line(at, at + Vector2(0, -30), INK, 3.0)
	draw_circle(at + Vector2(0, -32), 4, Color("e8434f"))
	var pulse: float = fmod(_time, 1.2) / 1.2
	for k in 2:
		var r: float = 8.0 + (k + pulse) * 8.0
		draw_arc(at + Vector2(0, -32), r, -PI * 0.8, -PI * 0.2, 8, Color(0.91, 0.26, 0.31, 1.0 - pulse * 0.6), 2.0)


func _flag(top: Vector2, color: Color, checker: bool) -> void:
	draw_line(top, top + Vector2(0, -46), INK, 4.0)
	var cloth := PackedVector2Array([top + Vector2(0, -46), top + Vector2(40, -38), top + Vector2(0, -28)])
	draw_colored_polygon(cloth, color)
	if checker:
		draw_rect(Rect2(top + Vector2(4, -42), Vector2(8, 6)), INK)
		draw_rect(Rect2(top + Vector2(14, -37), Vector2(8, 5)), INK)


func _lock(center: Vector2) -> void:
	draw_arc(center + Vector2(0, -6), 11, PI, TAU, 12, INK, 4.0)
	_round_rect(Rect2(center + Vector2(-15, -6), Vector2(30, 24)), 5.0, INK)
	draw_circle(center + Vector2(0, 6), 3.5, WAIT)


func _swords(center: Vector2) -> void:
	var wobble: float = sin(_time * 6.0) * 0.08
	for side in [-1.0, 1.0]:
		var angle: float = side * (PI * 0.25 + wobble)
		var dir := Vector2(sin(angle), -cos(angle))
		var from: Vector2 = center + dir * -22
		var to: Vector2 = center + dir * 22
		draw_line(from, to, Color.WHITE, 7.0)
		draw_line(from, to, INK, 3.0)
		draw_circle(to, 7, Color.WHITE)
		draw_circle(to, 4, INK)


func _text(font: Font, at: Vector2, text: String, font_size: int, color: Color, outline: Color) -> void:
	var width: float = size.x / maxf(1.0, float(rivals.size()))
	var pos := Vector2(at.x - width / 2.0, at.y)
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 6, outline)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


func _round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(radius))
	draw_style_box(box, rect)
