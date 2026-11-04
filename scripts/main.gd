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
const COLOR_DANGER := Color("d45d5d")

const PAGE_TAP := 0
const PAGE_UPGRADES := 1
const PAGE_DRIVERS := 2
const PAGE_CITY := 3
const PAGE_MARKET := 4

var _coins_label: Label
var _tap_label: Label
var _income_label: Label
var _reputation_label: Label
var _taxi_button: Button
var _tap_page: Control
var _upgrades_page: Control
var _drivers_page: Control
var _city_page: Control
var _market_page: Control
var _upgrade_list: VBoxContainer
var _driver_list: VBoxContainer
var _city_list: VBoxContainer
var _market_list: VBoxContainer
var _multiplier_label: Label
var _tab_buttons: Array[Button] = []
var _float_layer: Control
var _tap_tween: Tween
var _settings_layer: Control
var _settings_menu: VBoxContainer
var _settings_confirm: VBoxContainer
## id улучшения -> подписи и кнопка этой строки.
var _upgrade_rows: Dictionary = {}
## id водителя -> подписи и кнопка этой строки.
var _driver_rows: Dictionary = {}
var _district_rows: Dictionary = {}
var _region_rows: Dictionary = {}
var _competitor_rows: Dictionary = {}
var _notice_layer: Control
var _notice_title: Label
var _notice_body: Label
var _offline_layer: Control
var _offline_label: Label
var _offline_time_label: Label


func _ready() -> void:
	_apply_theme()
	_build_ui()
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.tap_power_changed.connect(_on_tap_power_changed)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.drivers_changed.connect(_on_drivers_changed)
	GameState.income_changed.connect(_on_income_changed)
	GameState.districts_changed.connect(_on_districts_changed)
	GameState.regions_changed.connect(_on_regions_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.competitors_changed.connect(_on_competitors_changed)
	GameState.offline_reward_ready.connect(_show_offline_popup)
	# Сигнал из автозагрузки мог прийти раньше, чем экран подписался. Берём числа ещё раз.
	_on_coins_changed(GameState.coins)
	_on_tap_power_changed(GameState.get_tap_power())
	_on_income_changed(GameState.get_income_per_second())
	_refresh_upgrades()
	_refresh_drivers()
	_refresh_districts()
	_refresh_regions()
	_refresh_competitors()
	_on_reputation_changed(GameState.reputation)
	_show_offline_popup()


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
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	column.add_child(_build_header())

	var pages := Control.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pages)

	_tap_page = _build_tap_page()
	_tap_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_tap_page)

	_upgrades_page = _build_scroll_page()
	_upgrades_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_upgrades_page)
	_upgrade_list = _upgrades_page.get_child(0).get_child(0) as VBoxContainer
	_build_upgrade_rows()

	_drivers_page = _build_scroll_page()
	_drivers_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_drivers_page)
	_driver_list = _drivers_page.get_child(0).get_child(0) as VBoxContainer
	_build_driver_rows()

	_city_page = _build_scroll_page()
	_city_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_city_page)
	_city_list = _city_page.get_child(0).get_child(0) as VBoxContainer
	_build_city_rows()

	_market_page = _build_scroll_page()
	_market_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_market_page)
	_market_list = _market_page.get_child(0).get_child(0) as VBoxContainer
	_build_market_rows()

	column.add_child(_build_tab_bar())
	_show_page(PAGE_TAP)
	_build_settings_popup()
	_build_notice_popup()
	_build_offline_popup()


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	header.add_child(text_box)

	var caption := Label.new()
	caption.text = "МОНЕТЫ"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 28)
	caption.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(caption)

	# Фиксированная рамка: одна надпись не прыгает по ширине и не оставляет старые цифры.
	var coin_frame := Control.new()
	coin_frame.custom_minimum_size = Vector2(0, 100)
	coin_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_frame.clip_contents = true
	text_box.add_child(coin_frame)

	_coins_label = Label.new()
	_coins_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.clip_contents = true
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coins_label.add_theme_font_size_override("font_size", 80)
	_coins_label.add_theme_color_override("font_color", COLOR_GOLD)
	coin_frame.add_child(_coins_label)

	_tap_label = Label.new()
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.add_theme_font_size_override("font_size", 30)
	_tap_label.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(_tap_label)

	_income_label = Label.new()
	_income_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_income_label.add_theme_font_size_override("font_size", 32)
	_income_label.add_theme_color_override("font_color", COLOR_INCOME)
	text_box.add_child(_income_label)

	_reputation_label = Label.new()
	_reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reputation_label.add_theme_font_size_override("font_size", 30)
	_reputation_label.add_theme_color_override("font_color", Color("8eb6ff"))
	text_box.add_child(_reputation_label)

	var settings_button := Button.new()
	settings_button.text = "Настройки"
	settings_button.custom_minimum_size = Vector2(250, 120)
	settings_button.focus_mode = Control.FOCUS_NONE
	_style_plain_button(settings_button, COLOR_PANEL)
	settings_button.add_theme_color_override("font_color", Color.WHITE)
	settings_button.add_theme_color_override("font_hover_color", Color.WHITE)
	settings_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	settings_button.pressed.connect(_open_settings)
	header.add_child(settings_button)
	return header


func _build_tap_page() -> Control:
	var page := Control.new()
	_taxi_button = Button.new()
	_taxi_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_taxi_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_taxi_button.focus_mode = Control.FOCUS_NONE
	_style_taxi_button(_taxi_button)
	_taxi_button.pressed.connect(_on_taxi_pressed)
	_taxi_button.resized.connect(_on_taxi_resized)
	page.add_child(_taxi_button)
	_build_taxi_face(_taxi_button)

	_float_layer = Control.new()
	_float_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(_float_layer)
	return page


func _build_scroll_page() -> Control:
	var page := Control.new()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	return page


func _build_tab_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	_tab_buttons = [
		_make_tab("Тап"),
		_make_tab("Улучшения"),
		_make_tab("Водители"),
		_make_tab("Город"),
		_make_tab("Рынок"),
	]
	for index in _tab_buttons.size():
		var button: Button = _tab_buttons[index]
		button.pressed.connect(_show_page.bind(index))
		bar.add_child(button)
	return bar


func _make_tab(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 112)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 24)
	button.clip_text = false
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return button


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


func _build_market_rows() -> void:
	var title := Label.new()
	title.text = "РЫНОК"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	_market_list.add_child(title)

	var hint := Label.new()
	hint.text = "Можно предложить выкуп. Конкурент может отказаться, тогда деньги останутся у вас."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_market_list.add_child(hint)

	for raw: Variant in GameState.get_competitors():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var competitor_id: String = str(info.get("id", ""))
		if competitor_id == "":
			continue
		_market_list.add_child(_make_competitor_row(competitor_id, info))


func _make_competitor_row(competitor_id: String, info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	var title := Label.new()
	title.text = str(info.get("name", competitor_id))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 36)
	column.add_child(title)

	var meta := Label.new()
	var chance: float = GameState.get_buyout_refuse_chance(competitor_id) * 100.0
	meta.text = "%s, размер %s. Шанс отказа %s%%." % [
		str(info.get("personality_name", "")),
		GameState.format_number(float(info.get("size", 0))),
		GameState.format_number(chance),
	]
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.add_theme_font_size_override("font_size", 26)
	meta.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(meta)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	column.add_child(description)

	var bonus: float = float(info.get("income_bonus", 0))
	var bonus_label := Label.new()
	bonus_label.text = "После выкупа доход +%s%%" % GameState.format_number(bonus * 100.0)
	bonus_label.add_theme_font_size_override("font_size", 26)
	bonus_label.add_theme_color_override("font_color", COLOR_INCOME)
	column.add_child(bonus_label)

	var offer_button := Button.new()
	offer_button.custom_minimum_size = Vector2(0, 110)
	offer_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(offer_button)
	offer_button.pressed.connect(_on_offer_buyout.bind(competitor_id))
	column.add_child(offer_button)

	_competitor_rows[competitor_id] = offer_button
	return panel


func _on_offer_buyout(competitor_id: String) -> void:
	var result: Dictionary = GameState.offer_buyout(competitor_id)
	var title := "Отказ"
	if bool(result.get("ok", false)):
		title = "Сделка"
	_show_notice(title, str(result.get("text", "")))


func _refresh_competitors() -> void:
	for competitor_id: Variant in _competitor_rows.keys():
		var offer_button: Button = _competitor_rows[competitor_id]
		var id := str(competitor_id)
		if GameState.is_competitor_owned(id):
			offer_button.text = "Компания ваша"
			offer_button.disabled = true
		else:
			var cost: float = GameState.get_competitor_cost(id)
			offer_button.text = "Предложить выкуп\n%s" % GameState.format_number(cost)
			offer_button.disabled = not GameState.can_offer_buyout(id)


func _on_competitors_changed() -> void:
	_refresh_competitors()
	_refresh_districts()


func _build_notice_popup() -> void:
	_notice_layer = Control.new()
	_notice_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_notice_layer.visible = false
	_notice_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_notice_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	var style := _panel_style()
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 40
	style.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)

	_notice_title = _make_center_label("", 44, Color.WHITE)
	box.add_child(_notice_title)
	_notice_body = _make_center_label("", 30, COLOR_MUTED)
	_notice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_notice_body)
	var close_button := _make_settings_button("Понятно", COLOR_BUY, _close_notice)
	box.add_child(close_button)


func _show_notice(title: String, body: String) -> void:
	_notice_title.text = title
	_notice_body.text = body
	_notice_layer.visible = true


func _close_notice() -> void:
	_notice_layer.visible = false


func _build_city_rows() -> void:
	for raw: Variant in GameState.get_cities():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var city: Dictionary = raw
		var title := Label.new()
		title.text = str(city.get("name", "Город"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		_city_list.add_child(title)

		var about := Label.new()
		about.text = str(city.get("description", ""))
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.add_theme_font_size_override("font_size", 26)
		about.add_theme_color_override("font_color", COLOR_MUTED)
		_city_list.add_child(about)

		_multiplier_label = Label.new()
		_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_multiplier_label.add_theme_font_size_override("font_size", 32)
		_multiplier_label.add_theme_color_override("font_color", COLOR_INCOME)
		_city_list.add_child(_multiplier_label)

		var districts: Variant = city.get("districts", [])
		if typeof(districts) != TYPE_ARRAY:
			continue
		for item: Variant in districts:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var info: Dictionary = item
			var district_id: String = str(info.get("id", ""))
			if district_id == "":
				continue
			_city_list.add_child(_make_district_row(district_id, info))
	_build_region_rows()


func _make_district_row(district_id: String, info: Dictionary) -> PanelContainer:
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
	title.text = str(info.get("name", district_id))
	title.add_theme_font_size_override("font_size", 36)
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(description)

	var bonus: float = float(info.get("income_bonus", 0))
	var bonus_label := Label.new()
	bonus_label.text = "Доход +%s%%" % GameState.format_number(bonus * 100.0)
	bonus_label.add_theme_font_size_override("font_size", 26)
	bonus_label.add_theme_color_override("font_color", COLOR_INCOME)
	text_box.add_child(bonus_label)

	var open_button := Button.new()
	open_button.custom_minimum_size = Vector2(230, 130)
	open_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(open_button)
	open_button.pressed.connect(_on_open_district.bind(district_id))
	row.add_child(open_button)

	_district_rows[district_id] = open_button
	return panel


func _build_region_rows() -> void:
	var title := Label.new()
	title.text = "МИР"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	_city_list.add_child(title)

	var hint := Label.new()
	hint.text = "Репутация растёт от заказов: +1 за каждые 20 тапов и за каждого нанятого водителя."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_city_list.add_child(hint)

	for raw: Variant in GameState.get_regions():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var region_id: String = str(info.get("id", ""))
		if region_id == "":
			continue
		_city_list.add_child(_make_region_row(region_id, info))


func _make_region_row(region_id: String, info: Dictionary) -> PanelContainer:
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
	title.text = str(info.get("name", region_id))
	title.add_theme_font_size_override("font_size", 36)
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(description)

	var bonus: float = float(info.get("income_bonus", 0))
	var bonus_label := Label.new()
	bonus_label.text = "Доход +%s%%, нужно репутации: %d" % [
		GameState.format_number(bonus * 100.0),
		int(info.get("reputation", 0)),
	]
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_label.add_theme_font_size_override("font_size", 26)
	bonus_label.add_theme_color_override("font_color", COLOR_INCOME)
	text_box.add_child(bonus_label)

	var reason_label := Label.new()
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason_label.add_theme_font_size_override("font_size", 26)
	reason_label.add_theme_color_override("font_color", COLOR_DANGER)
	text_box.add_child(reason_label)

	var open_button := Button.new()
	open_button.custom_minimum_size = Vector2(230, 130)
	open_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(open_button)
	open_button.pressed.connect(_on_open_region.bind(region_id))
	row.add_child(open_button)

	_region_rows[region_id] = {
		"button": open_button,
		"reason": reason_label,
	}
	return panel


func _on_open_district(district_id: String) -> void:
	GameState.open_district(district_id)


func _on_open_region(region_id: String) -> void:
	GameState.open_region(region_id)


func _refresh_districts() -> void:
	if _multiplier_label != null:
		_multiplier_label.text = "Множитель дохода: x%s" % GameState.format_number(GameState.get_income_multiplier())
	for district_id: Variant in _district_rows.keys():
		var open_button: Button = _district_rows[district_id]
		var id := str(district_id)
		if GameState.is_district_open(id):
			open_button.text = "Открыт"
			open_button.disabled = true
		else:
			var cost: float = GameState.get_district_cost(id)
			open_button.text = "Открыть\n%s" % GameState.format_number(cost)
			open_button.disabled = not GameState.can_open_district(id)


func _refresh_regions() -> void:
	for region_id: Variant in _region_rows.keys():
		var row: Dictionary = _region_rows[region_id]
		var open_button: Button = row["button"]
		var reason_label: Label = row["reason"]
		var id := str(region_id)
		if GameState.is_region_open(id):
			open_button.text = "Открыт"
			open_button.disabled = true
			reason_label.text = ""
		else:
			var cost: float = GameState.get_region_cost(id)
			open_button.text = "Открыть\n%s" % GameState.format_number(cost)
			open_button.disabled = not GameState.can_open_region(id)
			reason_label.text = GameState.get_region_block_reason(id)


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
	var hint := Label.new()
	hint.text = "Водители приносят монеты сами, даже если не нажимать на такси."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_driver_list.add_child(hint)

	for raw: Variant in GameState.get_drivers():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var driver_id: String = str(info.get("id", ""))
		if driver_id == "":
			continue
		_driver_list.add_child(_make_driver_row(driver_id, info))


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


func _build_offline_popup() -> void:
	_offline_layer = Control.new()
	_offline_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_offline_layer.visible = false
	_offline_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_offline_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_offline_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_offline_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	var style := _panel_style()
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 48
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	panel.add_child(box)

	_offline_label = Label.new()
	_offline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_label.add_theme_font_size_override("font_size", 48)
	box.add_child(_offline_label)

	_offline_time_label = Label.new()
	_offline_time_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_offline_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_offline_time_label.add_theme_font_size_override("font_size", 30)
	_offline_time_label.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(_offline_time_label)

	var collect_button := Button.new()
	collect_button.text = "Забрать"
	collect_button.custom_minimum_size = Vector2(0, 120)
	collect_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(collect_button)
	collect_button.add_theme_font_size_override("font_size", 40)
	collect_button.pressed.connect(_on_collect_offline)
	box.add_child(collect_button)


func _show_offline_popup() -> void:
	if not GameState.has_offline_reward():
		_offline_layer.visible = false
		return
	var amount: float = GameState.get_offline_coins()
	_offline_label.text = "Пока вас не было, заработано %s" % GameState.format_number(amount)
	_offline_time_label.text = _offline_time_text()
	_offline_layer.visible = true


func _offline_time_text() -> String:
	var text := "Вас не было: %s" % _format_duration(GameState.get_offline_seconds())
	if GameState.is_offline_capped():
		text += "\nНачислено за 8 часов — это максимум."
	return text


func _format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	if hours > 0 and minutes == 0:
		return "%d ч" % hours
	if hours > 0:
		return "%d ч %d мин" % [hours, minutes]
	if minutes > 0:
		return "%d мин" % minutes
	return "%d сек" % total


func _on_collect_offline() -> void:
	GameState.collect_offline_reward()
	_offline_layer.visible = false


func _on_taxi_resized() -> void:
	_taxi_button.pivot_offset = _taxi_button.size * 0.5


func _on_taxi_pressed() -> void:
	var gained: float = GameState.tap()
	_play_tap_animation()
	_spawn_floating_gain(gained)


## Кнопка чуть сжимается и пружинит обратно.
func _play_tap_animation() -> void:
	_on_taxi_resized()
	if _tap_tween != null and _tap_tween.is_valid():
		_tap_tween.kill()
	_taxi_button.scale = Vector2(0.94, 0.94)
	_tap_tween = create_tween()
	_tap_tween.tween_property(_taxi_button, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Над такси всплывает «+N» и тает.
func _spawn_floating_gain(amount: float) -> void:
	var label := Label.new()
	label.text = "+%s" % GameState.format_number(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", COLOR_INK)
	label.custom_minimum_size = Vector2(320, 90)
	_float_layer.add_child(label)

	var center: Vector2 = _taxi_button.get_global_rect().get_center()
	var local: Vector2 = _float_layer.get_global_transform().affine_inverse() * center
	var jitter: float = randf_range(-70.0, 70.0)
	# Выше шашечки, в пустом жёлтом поле, чтобы цифры не закрывали машину.
	label.position = Vector2(local.x - 160.0 + jitter, local.y - 520.0)

	var float_tween := create_tween()
	float_tween.set_parallel(true)
	float_tween.tween_property(label, "position:y", label.position.y - 160.0, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(label, "modulate:a", 0.0, 0.7)
	float_tween.chain().tween_callback(label.queue_free)


func _show_page(page: int) -> void:
	_tap_page.visible = page == PAGE_TAP
	_upgrades_page.visible = page == PAGE_UPGRADES
	_drivers_page.visible = page == PAGE_DRIVERS
	_city_page.visible = page == PAGE_CITY
	_market_page.visible = page == PAGE_MARKET
	for index in _tab_buttons.size():
		var button: Button = _tab_buttons[index]
		var active: bool = index == page
		var background: Color = COLOR_TAXI if active else COLOR_PANEL
		var font_color: Color = COLOR_INK if active else Color.WHITE
		_style_plain_button(button, background)
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
		button.add_theme_color_override("font_pressed_color", font_color)


func _style_plain_button(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.08)))
	button.add_theme_stylebox_override("focus", _button_style(color))


func _open_settings() -> void:
	_settings_menu.visible = true
	_settings_confirm.visible = false
	_settings_layer.visible = true


func _close_settings() -> void:
	_settings_layer.visible = false


func _ask_reset() -> void:
	_settings_menu.visible = false
	_settings_confirm.visible = true


func _confirm_reset() -> void:
	GameState.reset_progress()
	_close_settings()
	_show_page(PAGE_TAP)
	if _offline_layer != null:
		_offline_layer.visible = false


func _build_settings_popup() -> void:
	_settings_layer = Control.new()
	_settings_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_layer.visible = false
	_settings_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_settings_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	var style := _panel_style()
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 48
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(800, 420)
	panel.add_child(stack)

	_settings_menu = VBoxContainer.new()
	_settings_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_menu.add_theme_constant_override("separation", 24)
	_settings_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_settings_menu)
	_settings_menu.add_child(_make_center_label("Настройки", 52, Color.WHITE))
	var hint := _make_center_label("Сброс стирает монеты, улучшения и водителей. Это для проверки игры.", 28, COLOR_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_menu.add_child(hint)
	_settings_menu.add_child(_make_settings_button("Сбросить прогресс", COLOR_DANGER, _ask_reset))
	_settings_menu.add_child(_make_settings_button("Закрыть", COLOR_PANEL, _close_settings))

	_settings_confirm = VBoxContainer.new()
	_settings_confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_confirm.add_theme_constant_override("separation", 24)
	_settings_confirm.alignment = BoxContainer.ALIGNMENT_CENTER
	_settings_confirm.visible = false
	stack.add_child(_settings_confirm)
	var question := _make_center_label("Точно стереть весь прогресс?", 44, Color.WHITE)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_confirm.add_child(question)
	_settings_confirm.add_child(_make_settings_button("Сбросить", COLOR_DANGER, _confirm_reset))
	_settings_confirm.add_child(_make_settings_button("Отмена", COLOR_PANEL, _open_settings))


func _make_center_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_settings_button(text: String, color: Color, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 110)
	button.focus_mode = Control.FOCUS_NONE
	_style_plain_button(button, color)
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.pressed.connect(callback)
	return button


func _on_buy_upgrade(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)


func _on_hire_driver(driver_id: String) -> void:
	GameState.hire_driver(driver_id)


func _on_coins_changed(value: float) -> void:
	var text := GameState.format_number(value)
	# Пока на экране та же строка, подпись не трогаем — иначе цифры двоятся.
	if _coins_label.text == text:
		return
	_coins_label.text = text
	_refresh_upgrades()
	_refresh_drivers()
	_refresh_districts()
	_refresh_regions()
	_refresh_competitors()


func _on_tap_power_changed(value: float) -> void:
	_tap_label.text = "За тап: %s" % GameState.format_number(value)


func _on_income_changed(value: float) -> void:
	_income_label.text = "Доход в секунду: %s" % GameState.format_number(value)


func _on_upgrades_changed() -> void:
	_refresh_upgrades()


func _on_drivers_changed() -> void:
	_refresh_drivers()


func _on_districts_changed() -> void:
	_refresh_districts()


func _on_regions_changed() -> void:
	_refresh_regions()
	_refresh_districts()


func _on_reputation_changed(value: int) -> void:
	if _reputation_label != null:
		_reputation_label.text = "Репутация: %d" % value
	_refresh_regions()


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
