extends Node
## Прокрутка пальцем для ScrollContainer, как в обычных приложениях телефона.
##
## Godot отдаёт касание той карточке или кнопке, на которую попал палец, и список
## почти не листается. Этот узел слушает касания раньше интерфейса (_input):
## если палец сдвинулся дальше порога — это прокрутка. Тогда нажатие на кнопку
## отменяется (чтобы случайно ничего не купить), список едет за пальцем,
## а после отпускания катится по инерции и плавно тормозит.
##
## Касание на телефоне Godot превращает в нажатие мыши, поэтому слушаем мышь —
## так работает и на телефоне, и на компьютере.

## Сдвиг пальца (в пикселях экрана игры), после которого это уже прокрутка, а не нажатие.
const DRAG_THRESHOLD := 18.0
## Насколько быстро гаснет инерция: чем больше, тем быстрее остановка.
const FRICTION := 3.2
const MIN_SPEED := 30.0

var scroll: ScrollContainer
## Вернёт true, если поверх открыто окно — тогда список под ним не листаем.
var is_blocked: Callable = Callable()

var _tracking: bool = false
var _dragging: bool = false
var _start: Vector2 = Vector2.ZERO
var _last: Vector2 = Vector2.ZERO
var _last_time: float = 0.0
var _velocity: float = 0.0
var _position: float = 0.0
## Свой отменяющий «отпуск кнопки» нам самим ловить не нужно.
var _ignore_next_release: bool = false


func setup(target: ScrollContainer, blocked: Callable = Callable()) -> void:
	scroll = target
	is_blocked = blocked
	# Встроенную прокрутку перетаскиванием выключаем, чтобы не листать дважды. Колесо мыши остаётся.
	scroll.scroll_deadzone = 100000


func _input(event: InputEvent) -> void:
	if scroll == null or not scroll.is_visible_in_tree():
		_tracking = false
		return
	if event is InputEventMouseButton:
		var button: InputEventMouseButton = event
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed:
			if is_blocked.is_valid() and is_blocked.call():
				return
			if scroll.get_global_rect().has_point(button.position) and not _on_slider(button.position):
				_tracking = true
				_dragging = false
				_start = button.position
				_last = button.position
				_last_time = _now()
				_velocity = 0.0
				_position = float(scroll.scroll_vertical)
		else:
			if _ignore_next_release:
				_ignore_next_release = false
				return
			if _tracking and _dragging:
				get_viewport().set_input_as_handled()
				# Палец постоял перед отпусканием — список не разгоняем.
				if _now() - _last_time > 0.15:
					_velocity = 0.0
				_position = float(scroll.scroll_vertical)
				_stopped_at = _now()
			_tracking = false
			_dragging = false
	elif event is InputEventMouseMotion and _tracking:
		var motion: InputEventMouseMotion = event
		if not _dragging and motion.position.distance_to(_start) > DRAG_THRESHOLD:
			_dragging = true
			_cancel_press()
		if _dragging:
			var now: float = _now()
			var dy: float = motion.position.y - _last.y
			var dt: float = maxf(now - _last_time, 0.001)
			# Скорость сглаживаем, чтобы инерция не дёргалась от одного резкого кадра.
			_velocity = lerpf(_velocity, -dy / dt, 0.35)
			_last = motion.position
			_last_time = now
			_scroll_by(-dy)
			get_viewport().set_input_as_handled()


## Касание, начатое на ползунке (группа no_touch_scroll), отдаём ползунку — иначе его не потянуть.
func _on_slider(at: Vector2) -> bool:
	for node: Node in get_tree().get_nodes_in_group("no_touch_scroll"):
		var control := node as Control
		if control != null and control.is_visible_in_tree() and control.get_global_rect().grow(10.0).has_point(at):
			return true
	return false


## Список сейчас едет (палец тянет или катится по инерции) — главный экран в это время
## откладывает тяжёлые обновления, чтобы прокрутка шла ровно.
func is_moving() -> bool:
	return _dragging or (not _tracking and absf(_velocity) >= MIN_SPEED) or _now() - _stopped_at < 0.2


var _stopped_at: float = -10.0


func _process(delta: float) -> void:
	if scroll == null or _tracking or absf(_velocity) < MIN_SPEED:
		return
	var before: float = _position
	_scroll_by(_velocity * delta)
	# Медленный «хвост» инерции гасим быстрее: прокрутка идёт целыми пикселями,
	# и ползущий по пикселю список выглядит дёрганым.
	var friction: float = FRICTION if absf(_velocity) > 160.0 else FRICTION * 3.0
	_velocity *= exp(-friction * delta)
	if absf(_velocity) < MIN_SPEED:
		_stopped_at = _now()
	# Упёрлись в начало или конец списка — стоп.
	if is_equal_approx(before, _position):
		_velocity = 0.0


## Палец поехал — нажатие на кнопку под ним отменяем «отпуском» далеко за экраном.
## Кнопка срабатывает, только если её отпустили над ней, так что покупки не будет.
func _cancel_press() -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(-100000, -100000)
	release.global_position = release.position
	_ignore_next_release = true
	Input.parse_input_event(release)


func _scroll_by(amount: float) -> void:
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var limit: float = maxf(0.0, bar.max_value - bar.page)
	# Колесо мыши могло сдвинуть список — догоняем, если разошлись больше чем на пиксель.
	if absf(_position - float(scroll.scroll_vertical)) > 1.5:
		_position = float(scroll.scroll_vertical)
	_position = clampf(_position + amount, 0.0, limit)
	scroll.scroll_vertical = int(roundf(_position))


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0
