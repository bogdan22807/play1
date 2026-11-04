extends Control
## Главный экран. Весь интерфейс собирается в коде, сцена остаётся пустой.
## Экран не хранит экономику: он просит GameState и рисует то, что пришло в сигналах.

const COLOR_BG := Color("1a1d27")
const COLOR_TAXI := Color("ffc107")
const COLOR_TAXI_PRESSED := Color("e0a800")
const COLOR_INK := Color("1a1d27")
const COLOR_GOLD := Color("ffd54a")
const COLOR_MUTED := Color("a8b0c4")
const COLOR_WINDOW := Color("26324a")

var _coins_label: Label
var _tap_label: Label
var _taxi_button: Button


func _ready() -> void:
	_apply_theme()
	_build_ui()
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.tap_power_changed.connect(_on_tap_power_changed)
	# Сигнал из автозагрузки мог прийти раньше, чем экран подписался. Берём числа ещё раз.
	_on_coins_changed(GameState.coins)
	_on_tap_power_changed(GameState.get_tap_power())


func _apply_theme() -> void:
	var theme := Theme.new()
	var font := SystemFont.new()
	# Берём системный шрифт: встроенный шрифт Godot не всегда рисует русские буквы.
	font.font_names = PackedStringArray([
		"Noto Sans",
		"DejaVu Sans",
		"Liberation Sans",
		"Segoe UI",
		"Arial",
		"Roboto",
		"sans-serif",
	])
	theme.default_font = font
	theme.default_font_size = 32
	theme.set_color("font_color", "Label", Color.WHITE)
	self.theme = theme


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = COLOR_BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 72)
	margin.add_theme_constant_override("margin_bottom", 64)
	add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var caption := Label.new()
	caption.text = "МОНЕТЫ"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 36)
	caption.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(caption)

	_coins_label = Label.new()
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.add_theme_font_size_override("font_size", 96)
	_coins_label.add_theme_color_override("font_color", COLOR_GOLD)
	column.add_child(_coins_label)

	_tap_label = Label.new()
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.add_theme_font_size_override("font_size", 36)
	_tap_label.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(_tap_label)

	_taxi_button = Button.new()
	_taxi_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_taxi_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_taxi_button.custom_minimum_size = Vector2(0, 900)
	_taxi_button.focus_mode = Control.FOCUS_NONE
	_style_taxi_button(_taxi_button)
	_taxi_button.pressed.connect(_on_taxi_pressed)
	column.add_child(_taxi_button)
	_build_taxi_face(_taxi_button)


func _style_taxi_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _taxi_style(COLOR_TAXI))
	button.add_theme_stylebox_override("hover", _taxi_style(COLOR_TAXI))
	button.add_theme_stylebox_override("pressed", _taxi_style(COLOR_TAXI_PRESSED))
	button.add_theme_stylebox_override("focus", _taxi_style(COLOR_TAXI))


func _taxi_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(64)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style


## Рисуем такси из прямоугольников: картинок в проекте нет.
func _build_taxi_face(parent: Button) -> void:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 18)
	parent.add_child(column)

	var sign_center := CenterContainer.new()
	sign_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(sign_center)

	var sign := PanelContainer.new()
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sign_style := StyleBoxFlat.new()
	sign_style.bg_color = COLOR_INK
	sign_style.set_corner_radius_all(10)
	sign_style.content_margin_left = 28
	sign_style.content_margin_right = 28
	sign_style.content_margin_top = 6
	sign_style.content_margin_bottom = 6
	sign.add_theme_stylebox_override("panel", sign_style)
	sign_center.add_child(sign)

	var sign_label := Label.new()
	sign_label.text = "ТАКСИ"
	sign_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_label.add_theme_font_size_override("font_size", 42)
	sign_label.add_theme_color_override("font_color", COLOR_TAXI)
	sign.add_child(sign_label)

	var windows := HBoxContainer.new()
	windows.alignment = BoxContainer.ALIGNMENT_CENTER
	windows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	windows.add_theme_constant_override("separation", 28)
	column.add_child(windows)
	windows.add_child(_make_window())
	windows.add_child(_make_window())

	var wheels := HBoxContainer.new()
	wheels.alignment = BoxContainer.ALIGNMENT_CENTER
	wheels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheels.add_theme_constant_override("separation", 300)
	column.add_child(wheels)
	wheels.add_child(_make_wheel())
	wheels.add_child(_make_wheel())

	var hint := Label.new()
	hint.text = "ЖМИ"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 72)
	hint.add_theme_color_override("font_color", COLOR_INK)
	column.add_child(hint)


func _make_window() -> ColorRect:
	var window := ColorRect.new()
	window.custom_minimum_size = Vector2(180, 110)
	window.color = COLOR_WINDOW
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return window


func _make_wheel() -> Panel:
	var wheel := Panel.new()
	wheel.custom_minimum_size = Vector2(84, 84)
	wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_INK
	style.set_corner_radius_all(42)
	wheel.add_theme_stylebox_override("panel", style)
	return wheel


func _on_taxi_pressed() -> void:
	GameState.tap()


func _on_coins_changed(value: float) -> void:
	_coins_label.text = GameState.format_number(value)


func _on_tap_power_changed(value: float) -> void:
	_tap_label.text = "За тап: %s" % GameState.format_number(value)
