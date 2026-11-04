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
const COLOR_PANEL := Color("262b3a")
const COLOR_BUY := Color("3d7eff")
const COLOR_BUY_HOVER := Color("548dff")
const COLOR_BUY_PRESSED := Color("2c63d6")
const COLOR_DISABLED := Color("3a4054")
const COLOR_INCOME := Color("3ddc84")

var _coins_label: Label
var _tap_label: Label
var _income_label: Label
var _taxi_button: Button
var _upgrade_list: VBoxContainer
## id улучшения -> подписи и кнопка этой строки.
var _upgrade_rows: Dictionary = {}
## id водителя -> подписи и кнопка этой строки.
var _driver_rows: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	_build_ui()
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.tap_power_changed.connect(_on_tap_power_changed)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.drivers_changed.connect(_on_drivers_changed)
	GameState.income_changed.connect(_on_income_changed)
	# Сигнал из автозагрузки мог прийти раньше, чем экран подписался. Берём числа ещё раз.
	_on_coins_changed(GameState.coins)
	_on_tap_power_changed(GameState.get_tap_power())
	_on_income_changed(GameState.get_income_per_second())
	_refresh_upgrades()
	_refresh_drivers()


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

	_income_label = Label.new()
	_income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_income_label.add_theme_font_size_override("font_size", 34)
	_income_label.add_theme_color_override("font_color", COLOR_INCOME)
	column.add_child(_income_label)

	_taxi_button = Button.new()
	_taxi_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_taxi_button.custom_minimum_size = Vector2(0, 700)
	_taxi_button.focus_mode = Control.FOCUS_NONE
	_style_taxi_button(_taxi_button)
	_taxi_button.pressed.connect(_on_taxi_pressed)
	column.add_child(_taxi_button)
	_build_taxi_face(_taxi_button)

	var upgrades_title := Label.new()
	upgrades_title.text = "УЛУЧШЕНИЯ"
	upgrades_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrades_title.add_theme_font_size_override("font_size", 36)
	upgrades_title.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(upgrades_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_upgrade_list = VBoxContainer.new()
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_upgrade_list)
	_build_upgrade_rows()
	_build_driver_rows()


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


func _build_upgrade_rows() -> void:
	for raw: Variant in GameState.get_upgrades():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var upgrade_id: String = str(info.get("id", ""))
		if upgrade_id == "":
			continue
		_upgrade_list.add_child(_make_upgrade_row(upgrade_id, info))


func _build_driver_rows() -> void:
	var title := Label.new()
	title.text = "ВОДИТЕЛИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COLOR_MUTED)
	_upgrade_list.add_child(title)

	var hint := Label.new()
	hint.text = "Водители приносят монеты сами, даже если не нажимать на такси."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_upgrade_list.add_child(hint)

	for raw: Variant in GameState.get_drivers():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var driver_id: String = str(info.get("id", ""))
		if driver_id == "":
			continue
		_upgrade_list.add_child(_make_driver_row(driver_id, info))


func _make_driver_row(driver_id: String, info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title := Label.new()
	title.text = str(info.get("name", driver_id))
	title.add_theme_font_size_override("font_size", 36)
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(description)

	var rate: float = float(info.get("income_per_second", 0))
	var rate_label := Label.new()
	rate_label.text = "Приносит %s в секунду" % GameState.format_number(rate)
	rate_label.add_theme_font_size_override("font_size", 26)
	rate_label.add_theme_color_override("font_color", COLOR_INCOME)
	text_box.add_child(rate_label)

	var count_label := Label.new()
	count_label.add_theme_font_size_override("font_size", 28)
	count_label.add_theme_color_override("font_color", COLOR_GOLD)
	text_box.add_child(count_label)

	var hire_button := Button.new()
	hire_button.custom_minimum_size = Vector2(230, 130)
	hire_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(hire_button)
	hire_button.pressed.connect(_on_hire_driver.bind(driver_id))
	row.add_child(hire_button)

	_driver_rows[driver_id] = {
		"count": count_label,
		"button": hire_button,
	}
	return panel


func _make_upgrade_row(upgrade_id: String, info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title := Label.new()
	title.text = str(info.get("name", upgrade_id))
	title.add_theme_font_size_override("font_size", 36)
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(description)

	var level_label := Label.new()
	level_label.add_theme_font_size_override("font_size", 28)
	level_label.add_theme_color_override("font_color", COLOR_GOLD)
	text_box.add_child(level_label)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(230, 130)
	buy_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(buy_button)
	buy_button.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
	row.add_child(buy_button)

	_upgrade_rows[upgrade_id] = {
		"level": level_label,
		"button": buy_button,
	}
	return panel


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(24)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _style_buy_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_style(COLOR_BUY))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_BUY_HOVER))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_BUY_PRESSED))
	button.add_theme_stylebox_override("disabled", _button_style(COLOR_DISABLED))
	button.add_theme_stylebox_override("focus", _button_style(COLOR_BUY))
	button.add_theme_font_size_override("font_size", 28)


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(20)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_taxi_pressed() -> void:
	GameState.tap()


func _on_buy_upgrade(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)


func _on_hire_driver(driver_id: String) -> void:
	GameState.hire_driver(driver_id)


func _on_coins_changed(value: float) -> void:
	_coins_label.text = GameState.format_number(value)
	_refresh_upgrades()
	_refresh_drivers()


func _on_tap_power_changed(value: float) -> void:
	_tap_label.text = "За тап: %s" % GameState.format_number(value)


func _on_income_changed(value: float) -> void:
	_income_label.text = "Доход в секунду: %s" % GameState.format_number(value)


func _on_upgrades_changed() -> void:
	_refresh_upgrades()


func _on_drivers_changed() -> void:
	_refresh_drivers()


func _refresh_upgrades() -> void:
	for upgrade_id: Variant in _upgrade_rows.keys():
		var row: Dictionary = _upgrade_rows[upgrade_id]
		var level_label: Label = row["level"]
		var buy_button: Button = row["button"]
		var id := str(upgrade_id)
		level_label.text = "Уровень: %d" % GameState.get_upgrade_level(id)
		var cost: float = GameState.get_upgrade_cost(id)
		buy_button.text = "Купить\n%s" % GameState.format_number(cost)
		buy_button.disabled = not GameState.can_buy_upgrade(id)


func _refresh_drivers() -> void:
	for driver_id: Variant in _driver_rows.keys():
		var row: Dictionary = _driver_rows[driver_id]
		var count_label: Label = row["count"]
		var hire_button: Button = row["button"]
		var id := str(driver_id)
		count_label.text = "Нанято: %d" % GameState.get_driver_count(id)
		var cost: float = GameState.get_driver_cost(id)
		hire_button.text = "Нанять\n%s" % GameState.format_number(cost)
		hire_button.disabled = not GameState.can_hire_driver(id)
