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
var _reputation_label: Label
var _share_label: Label
var _share_fill: ColorRect
var _taxi_button: Button
var _tap_page: Control
var _upgrades_page: Control
var _drivers_page: Control
var _city_page: Control
var _market_page: Control
var _upgrade_list: VBoxContainer
var _driver_list: VBoxContainer
var _district_list: VBoxContainer
var _world_list: VBoxContainer
var _achievement_list: VBoxContainer
var _city_sections: Array[Control] = []
var _city_section_buttons: Array[Button] = []
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
var _team_box: VBoxContainer
var _candidate_box: VBoxContainer
var _staff_summary: Label
var _garage_label: Label
var _expand_button: Button
var _refresh_button: Button
## id машины -> {"count", "button", "note"} для покупки в парк.
var _fleet_rows: Dictionary = {}
## Кнопки, которые зависят от денег: [кнопка, Callable проверки].
var _staff_buttons: Array = []
## uid водителя -> [Label, карточка водителя, карточка машины]: строки, которые обновляются от износа.
var _team_wear_rows: Dictionary = {}
var _fleet_wear_label: Label
var _wash_fleet_button: Button
## uid водителя -> [Label смены, ProgressBar, кнопка «Сменить», карточка водителя].
var _team_shift_rows: Dictionary = {}
var _shift_all_button: Button
## id помощника -> {"status", "button"}.
var _helper_rows: Dictionary = {}
var _rating_label: Label
var _repair_fleet_button: Button
var _my_clean_bar: ProgressBar
var _my_health_bar: ProgressBar
var _my_clean_label: Label
var _my_health_label: Label
var _wash_me_button: Button
var _repair_me_button: Button
var _district_rows: Dictionary = {}
var _region_rows: Dictionary = {}
var _competitor_rows: Dictionary = {}
var _market_status: Label
var _market_bar: HBoxContainer
## "player" или id конкурента -> кусок полоски долей.
var _market_bar_parts: Dictionary = {}
var _market_legend: Label
## id рекламы -> {"status", "button"}.
var _ad_rows: Dictionary = {}
var _notice_layer: Control
var _notice_title: Label
var _notice_body: Label
var _sell_info: Label
var _sell_button: Button
var _sell_layer: Control
var _sell_body: Label
var _achievement_labels: Dictionary = {}
var _toast_layer: PanelContainer
var _toast_label: Label
var _toast_queue: Array = []
var _toast_timer: Timer
var _daily_layer: Control
var _offline_layer: Control
var _offline_label: Label
var _offline_time_label: Label
var _company_label: Label
var _taxi_sign_label: Label
var _car_now_label: Label
var _car_rent_label: Label
## id машины -> {"status", "rent", "buy"}.
var _car_rows: Dictionary = {}
var _name_layer: Control
var _name_edit: LineEdit
var _name_error: Label


func _ready() -> void:
	_apply_theme()
	_build_ui()
	if _toast_layer != null:
		move_child(_toast_layer, get_child_count() - 1)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.tap_power_changed.connect(_on_tap_power_changed)
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.drivers_changed.connect(_on_drivers_changed)
	GameState.income_changed.connect(_on_income_changed)
	GameState.districts_changed.connect(_on_districts_changed)
	GameState.regions_changed.connect(_on_regions_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.competitors_changed.connect(_on_competitors_changed)
	GameState.home_captured.connect(_on_home_captured)
	GameState.franchise_changed.connect(_on_franchise_changed)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)
	GameState.achievements_changed.connect(_refresh_achievements)
	GameState.offline_reward_ready.connect(_show_offline_popup)
	GameState.car_changed.connect(_on_car_changed)
	GameState.garage_changed.connect(_on_drivers_changed)
	GameState.wear_changed.connect(_on_wear_changed)
	GameState.shifts_changed.connect(_on_shifts_changed)
	GameState.helpers_changed.connect(_refresh_helpers)
	GameState.company_changed.connect(_on_company_changed)
	# Сигнал из автозагрузки мог прийти раньше, чем экран подписался. Берём числа ещё раз.
	_on_coins_changed(GameState.coins)
	_on_tap_power_changed(GameState.get_tap_power())
	_on_income_changed(GameState.get_income_per_second())
	_refresh_upgrades()
	_refresh_staff_money()
	_refresh_districts()
	_refresh_regions()
	_refresh_competitors()
	_refresh_sell()
	_on_reputation_changed(GameState.reputation)
	_on_franchise_changed(GameState.get_franchise())
	_refresh_achievements()
	_on_car_changed()
	_on_company_changed(GameState.company_name)
	_on_wear_changed()
	_on_shifts_changed()
	for item: Variant in GameState.take_fresh_achievements():
		if typeof(item) == TYPE_DICTIONARY:
			var info: Dictionary = item
			_enqueue_toast(str(info.get("title", "")), str(info.get("body", "")))
	_show_offline_popup()
	if _offline_layer == null or not _offline_layer.visible:
		_show_daily_popup()
	_show_name_popup()


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

	_city_page = _build_city_page()
	_city_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages.add_child(_city_page)
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
	_build_sell_popup()
	_build_toast()
	_build_daily_popup()
	_build_offline_popup()
	_build_name_popup()


func _build_header() -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	header.add_child(text_box)

	_company_label = Label.new()
	_company_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_label.clip_text = true
	_company_label.add_theme_font_size_override("font_size", 26)
	_company_label.add_theme_color_override("font_color", COLOR_TAXI)
	text_box.add_child(_company_label)

	# Фиксированная рамка: одна надпись не прыгает по ширине и не оставляет старые цифры.
	var coin_frame := Control.new()
	coin_frame.custom_minimum_size = Vector2(0, 72)
	coin_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coin_frame.clip_contents = true
	text_box.add_child(coin_frame)

	_coins_label = Label.new()
	_coins_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.clip_contents = true
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coins_label.add_theme_font_size_override("font_size", 64)
	_coins_label.add_theme_color_override("font_color", COLOR_GOLD)
	coin_frame.add_child(_coins_label)

	_share_label = Label.new()
	_share_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_share_label.add_theme_font_size_override("font_size", 22)
	_share_label.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(_share_label)

	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 10)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.clip_contents = true
	text_box.add_child(track)

	var track_bg := ColorRect.new()
	track_bg.color = COLOR_PANEL
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(track_bg)

	_share_fill = ColorRect.new()
	_share_fill.color = COLOR_INCOME
	_share_fill.anchor_right = 0.0
	_share_fill.anchor_bottom = 1.0
	_share_fill.offset_right = 0.0
	_share_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_share_fill)

	_tap_label = Label.new()
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.add_theme_font_size_override("font_size", 26)
	_tap_label.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(_tap_label)

	_reputation_label = Label.new()
	_reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reputation_label.add_theme_font_size_override("font_size", 26)
	_reputation_label.add_theme_color_override("font_color", Color("c5d4f5"))
	text_box.add_child(_reputation_label)

	var settings_button := Button.new()
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Настройки"
	settings_button.custom_minimum_size = Vector2(84, 84)
	settings_button.focus_mode = Control.FOCUS_NONE
	_style_plain_button(settings_button, COLOR_PANEL)
	settings_button.add_theme_font_size_override("font_size", 40)
	settings_button.add_theme_color_override("font_color", Color.WHITE)
	settings_button.add_theme_color_override("font_hover_color", Color.WHITE)
	settings_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	settings_button.pressed.connect(_open_settings)
	header.add_child(settings_button)
	return header


func _build_tap_page() -> Control:
	var page := Control.new()
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 16)
	page.add_child(column)
	var taxi_holder := Control.new()
	taxi_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(taxi_holder)
	column.add_child(_build_my_car_panel())

	_taxi_button = Button.new()
	_taxi_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_taxi_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_taxi_button.focus_mode = Control.FOCUS_NONE
	_style_taxi_button(_taxi_button)
	_taxi_button.pressed.connect(_on_taxi_pressed)
	_taxi_button.resized.connect(_on_taxi_resized)
	taxi_holder.add_child(_taxi_button)
	_build_taxi_face(_taxi_button)

	_float_layer = Control.new()
	_float_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_float_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(_float_layer)
	return page


## Под такси: чистота и состояние своей машины, кнопки мойки и ремонта.
func _build_my_car_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 6)
	row.add_child(bars)
	_my_clean_label = _add_label(bars, "", 26, COLOR_MUTED)
	_my_clean_bar = _make_bar(Color("4fc3f7"))
	bars.add_child(_my_clean_bar)
	_my_health_label = _add_label(bars, "", 26, COLOR_MUTED)
	_my_health_bar = _make_bar(COLOR_INCOME)
	bars.add_child(_my_health_bar)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	row.add_child(buttons)
	_wash_me_button = _make_service_button(_on_wash_me)
	buttons.add_child(_wash_me_button)
	_repair_me_button = _make_service_button(_on_repair_me)
	buttons.add_child(_repair_me_button)
	return panel


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.step = 0.001
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 18)
	var back := StyleBoxFlat.new()
	back.bg_color = COLOR_BG
	back.set_corner_radius_all(9)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(9)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _make_service_button(callback: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 86)
	button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(button)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	return button


## Цвет полоски: зелёная — всё хорошо, жёлтая — пора, красная — уже теряем деньги.
func _wear_color(value: float) -> Color:
	if value < 0.1:
		return COLOR_DANGER
	if value < 0.5:
		return COLOR_GOLD
	return COLOR_MUTED


func _percent(value: float) -> String:
	return "%d%%" % int(floorf(value * 100.0 + 0.0001))


func _on_wear_changed() -> void:
	if _my_clean_bar != null:
		var clean: float = GameState.get_my_clean()
		var health: float = GameState.get_my_health()
		_my_clean_bar.value = clean
		_my_health_bar.value = health
		_my_clean_label.text = "Чистота %s%s" % [_percent(clean), "  ·  пассажиры морщатся" if clean < 0.5 else ""]
		_my_clean_label.add_theme_color_override("font_color", _wear_color(clean))
		var health_note: String = ""
		if GameState.is_broken(health):
			health_note = "  ·  сломана, еле едет!"
		elif health < 0.5:
			health_note = "  ·  дребезжит"
		_my_health_label.text = "Состояние %s%s" % [_percent(health), health_note]
		_my_health_label.add_theme_color_override("font_color", _wear_color(health))
		var wash: float = GameState.get_my_wash_cost()
		_wash_me_button.text = "Помыть %s" % GameState.format_money(wash) if wash > 0.0 else "Чистая"
		_wash_me_button.disabled = not GameState.can_wash_my_car()
		var repair: float = GameState.get_my_repair_cost()
		_repair_me_button.text = "Починить %s" % GameState.format_money(repair) if repair > 0.0 else "Целая"
		_repair_me_button.disabled = not GameState.can_repair_my_car()
	if _fleet_wear_label != null:
		var broken: int = GameState.get_broken_count()
		_fleet_wear_label.text = "Парк: чистота %s  ·  состояние %s%s" % [
			_percent(GameState.get_fleet_average("clean")),
			_percent(GameState.get_fleet_average("health")),
			"  ·  сломано: %d" % broken if broken > 0 else "",
		]
		_fleet_wear_label.add_theme_color_override("font_color", COLOR_DANGER if broken > 0 else COLOR_MUTED)
		var wash_fleet: float = GameState.get_fleet_wash_cost()
		_wash_fleet_button.text = "Помыть парк\n%s" % GameState.format_money(wash_fleet) if wash_fleet > 0.0 else "Парк\nчистый"
		_wash_fleet_button.disabled = not GameState.can_wash_fleet()
		var repair_fleet: float = GameState.get_fleet_repair_cost()
		_repair_fleet_button.text = "Починить парк\n%s" % GameState.format_money(repair_fleet) if repair_fleet > 0.0 else "Парк\nцелый"
		_repair_fleet_button.disabled = not GameState.can_repair_fleet()
		_staff_summary.text = _staff_summary_text()
	for uid: Variant in _team_wear_rows.keys():
		var entry: Array = _team_wear_rows[uid]
		var label: Label = entry[0]
		if is_instance_valid(label):
			label.text = _team_car_text(entry[1], entry[2])
			var car: Dictionary = entry[2]
			label.add_theme_color_override("font_color", COLOR_DANGER if GameState.is_broken(float(car.get("health", 1))) else COLOR_INCOME)


func _team_car_text(person: Dictionary, car: Dictionary) -> String:
	var text: String = "%s  ·  %s/с  ·  зарплата %d%%" % [
		_car_name(str(car.get("model", ""))),
		GameState.format_money(GameState.get_driver_net_on(person, car)),
		int(roundf(GameState.get_salary_share(person) * 100.0)),
	]
	var health: float = float(car.get("health", 1))
	if GameState.is_broken(health):
		return text + "\nМашина сломана и стоит — почините парк!"
	return text + "\nЧистота %s  ·  состояние %s" % [_percent(float(car.get("clean", 1))), _percent(health)]


## Раз в секунду: часы смен, усталость, рейтинг.
func _on_shifts_changed() -> void:
	_refresh_meta_line()
	_refresh_competitors()
	_refresh_market_share()
	var shift: float = GameState.get_shift_hours()
	for uid: Variant in _team_shift_rows.keys():
		var entry: Array = _team_shift_rows[uid]
		var label: Label = entry[0]
		if not is_instance_valid(label):
			continue
		var bar: ProgressBar = entry[1]
		var button: Button = entry[2]
		var person: Dictionary = entry[3]
		var hours: float = GameState.get_driver_hours(person)
		var tired: float = GameState.get_tiredness(person)
		var state: String = "свежий"
		var color: Color = COLOR_MUTED
		if tired >= 1.0:
			state = "валится с ног, пассажиры жалуются"
			color = COLOR_DANGER
		elif tired > 0.0:
			state = "устал, отзывы хуже"
			color = COLOR_GOLD
		elif hours > shift * 0.75:
			state = "скоро конец смены"
		label.text = "Смена: %.1f ч из %d  ·  %s" % [hours, int(shift), state]
		label.add_theme_color_override("font_color", color)
		bar.value = minf(hours, bar.max_value)
		var fill: StyleBoxFlat = bar.get_theme_stylebox("fill")
		fill.bg_color = color if tired > 0.0 else Color("b39ddb")
		button.disabled = not GameState.can_change_shift(int(uid))
	if _shift_all_button != null:
		var tired_count: int = GameState.get_tired_count()
		_shift_all_button.text = "Сменить уставших: %d" % tired_count if tired_count > 0 else "Все водители в пределах смены"
		_shift_all_button.disabled = tired_count == 0
	if _rating_label != null:
		var now: float = GameState.get_rating()
		var target: float = GameState.get_rating_target()
		var trend: String = "держится"
		if target > now + 0.05:
			trend = "растут к ★%.1f" % target
		elif target < now - 0.05:
			trend = "падают к ★%.1f" % target
		var bonus: int = int(roundf((GameState.get_rating_multiplier() - 1.0) * 100.0))
		_rating_label.text = "Отзывы ★%.1f, %s  ·  доход %s%d%%" % [now, trend, "+" if bonus >= 0 else "", bonus]
		_rating_label.add_theme_color_override("font_color", COLOR_DANGER if target < now - 0.05 else COLOR_GOLD)
	for uid: Variant in _team_wear_rows.keys():
		var entry: Array = _team_wear_rows[uid]
		var car_label: Label = entry[0]
		if is_instance_valid(car_label):
			car_label.text = _team_car_text(entry[1], entry[2])


func _staff_summary_text() -> String:
	var text: String = "Команда приносит %s/с  ·  зарплаты %s/с" % [
		GameState.format_money(GameState.get_income_per_second()),
		GameState.format_money(GameState.get_salary_per_second()),
	]
	if GameState.get_helper_fee_share() > 0.0:
		text += "  ·  помощникам %s/с" % GameState.format_money(GameState.get_helper_fee_per_second())
	return text


func _make_helper_row(info: Dictionary) -> PanelContainer:
	var helper_id: String = str(info.get("id", ""))
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	var text_box := _make_text_box(row)
	_add_label(text_box, str(info.get("name", helper_id)), 34)
	_add_label(text_box, str(info.get("description", "")), 24, COLOR_MUTED)
	var terms: String = "Берёт %d%% дохода водителей" % int(roundf(float(info.get("fee_share", 0)) * 100.0))
	if float(info.get("offline_bonus", 0)) > 0.0:
		terms += "  ·  пока вас нет, парк работает на 100%"
	_add_label(text_box, terms, 24, COLOR_INCOME)
	var status := _add_label(text_box, "", 26, COLOR_GOLD)
	var button := _make_row_button(_on_helper_pressed.bind(helper_id))
	row.add_child(button)
	_helper_rows[helper_id] = {"status": status, "button": button}
	return parts[0]


func _refresh_helpers() -> void:
	for helper_id: Variant in _helper_rows.keys():
		var id := str(helper_id)
		var row: Dictionary = _helper_rows[helper_id]
		var status: Label = row["status"]
		var button: Button = row["button"]
		if not GameState.is_helper_hired(id):
			status.text = ""
			button.text = "Нанять\n%s" % GameState.format_money(GameState.get_helper_cost(id))
			button.disabled = not GameState.can_hire_helper(id)
		elif GameState.is_helper_on(id):
			status.text = "Работает"
			button.text = "Выключить"
			button.disabled = false
		else:
			status.text = "Отдыхает — работа на вас"
			button.text = "Включить"
			button.disabled = false
	if _staff_summary != null:
		_staff_summary.text = _staff_summary_text()


func _on_helper_pressed(helper_id: String) -> void:
	if not GameState.is_helper_hired(helper_id):
		GameState.hire_helper(helper_id)
	else:
		GameState.set_helper_on(helper_id, not GameState.is_helper_on(helper_id))


func _on_change_shift(uid: int) -> void:
	GameState.change_shift(uid)


func _on_shift_all() -> void:
	GameState.change_tired_shifts()


func _on_wash_me() -> void:
	GameState.wash_my_car()


func _on_repair_me() -> void:
	GameState.repair_my_car()


func _on_wash_fleet() -> void:
	GameState.wash_fleet()


func _on_repair_fleet() -> void:
	GameState.repair_fleet()


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
		_make_tab("Машина"),
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

	_taxi_sign_label = Label.new()
	_taxi_sign_label.text = "ТАКСИ"
	_taxi_sign_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_taxi_sign_label.add_theme_font_size_override("font_size", 42)
	_taxi_sign_label.add_theme_color_override("font_color", COLOR_TAXI)
	sign.add_child(_taxi_sign_label)

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


const MARKET_COLORS := {
	"player": Color("ffc107"),
	"wolf": Color("8d99ae"),
	"lotus": Color("f06292"),
	"elephant": Color("a1887f"),
}


func _market_color(id: String) -> Color:
	return MARKET_COLORS.get(id, Color("7e8aa2"))


func _build_market_rows() -> void:
	_market_list.add_child(_make_section_title("Рынок: %s" % GameState.get_home_city()))

	var share_panel := PanelContainer.new()
	share_panel.add_theme_stylebox_override("panel", _panel_style())
	_market_list.add_child(share_panel)
	var share_box := VBoxContainer.new()
	share_box.add_theme_constant_override("separation", 10)
	share_panel.add_child(share_box)
	_market_status = _add_label(share_box, "", 34, COLOR_GOLD)
	_market_bar = HBoxContainer.new()
	_market_bar.custom_minimum_size = Vector2(0, 36)
	_market_bar.add_theme_constant_override("separation", 2)
	share_box.add_child(_market_bar)
	_market_bar_parts["player"] = _make_share_part("player")
	for raw: Variant in GameState.get_competitors():
		var id: String = str(raw.get("id", ""))
		_market_bar_parts[id] = _make_share_part(id)
	_market_legend = _add_label(share_box, "", 26, COLOR_MUTED)
	_add_label(share_box, "Захват города: доля больше 50% или выкупить всех. Доля растёт от дохода, рейтинга и рекламы.", 24, COLOR_MUTED)

	_market_list.add_child(_make_section_title("Реклама"))
	for raw: Variant in GameState.get_ads():
		if typeof(raw) == TYPE_DICTIONARY:
			_market_list.add_child(_make_ad_row(raw))

	_market_list.add_child(_make_section_title("Конкуренты"))
	for raw: Variant in GameState.get_competitors():
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) != "":
			_market_list.add_child(_make_competitor_row(str(raw.get("id", "")), raw))

	_market_list.add_child(_make_sell_panel())


func _make_share_part(id: String) -> ColorRect:
	var part := ColorRect.new()
	part.color = _market_color(id)
	part.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	part.size_flags_stretch_ratio = 0.01
	part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_market_bar.add_child(part)
	return part


func _make_ad_row(info: Dictionary) -> PanelContainer:
	var ad_id: String = str(info.get("id", ""))
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	var text_box := _make_text_box(row)
	_add_label(text_box, str(info.get("name", ad_id)), 34)
	_add_label(text_box, str(info.get("description", "")), 24, COLOR_MUTED)
	_add_label(text_box, "+%d%% к вашей силе на %d мин" % [
		int(roundf(float(info.get("boost", 0)) * 100.0)),
		int(float(info.get("duration", 0)) / 60.0),
	], 24, COLOR_INCOME)
	var status := _add_label(text_box, "", 26, COLOR_GOLD)
	var button := _make_row_button(_on_buy_ad.bind(ad_id))
	row.add_child(button)
	_ad_rows[ad_id] = {"status": status, "button": button}
	return parts[0]


func _make_competitor_row(competitor_id: String, info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _panel_style()
	style.border_width_left = 10
	style.border_color = _market_color(competitor_id)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)

	_add_label(column, str(info.get("name", competitor_id)), 36)
	_add_label(column, str(info.get("personality_name", "")), 26, COLOR_GOLD)
	_add_label(column, str(info.get("description", "")), 24, COLOR_MUTED)
	var share_label := _add_label(column, "", 26, Color.WHITE)
	var effects := _add_label(column, "", 24, COLOR_INCOME)

	var tricks := HBoxContainer.new()
	tricks.add_theme_constant_override("separation", 8)
	column.add_child(tricks)
	var trick_buttons: Dictionary = {}
	for raw: Variant in GameState.get_tricks():
		var trick_id: String = str(raw.get("id", ""))
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 130)
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_plain_button(button, Color("6d4c41"))
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.pressed.connect(_on_trick.bind(competitor_id, trick_id))
		tricks.add_child(button)
		trick_buttons[trick_id] = button

	var offer_button := Button.new()
	offer_button.custom_minimum_size = Vector2(0, 100)
	offer_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(offer_button)
	offer_button.pressed.connect(_on_offer_buyout.bind(competitor_id))
	column.add_child(offer_button)

	_competitor_rows[competitor_id] = {
		"share": share_label,
		"effects": effects,
		"tricks": trick_buttons,
		"tricks_box": tricks,
		"offer": offer_button,
	}
	return panel


func _on_buy_ad(ad_id: String) -> void:
	GameState.buy_ad(ad_id)


func _on_trick(competitor_id: String, trick_id: String) -> void:
	var result: Dictionary = GameState.play_trick(competitor_id, trick_id)
	if not bool(result.get("ok", false)):
		return
	var title: String = "Попались!" if bool(result.get("caught", false)) else "Сработало"
	var body: String = str(result.get("text", ""))
	var revenge: String = str(result.get("revenge", ""))
	if revenge != "":
		body += "\n\nОтвет: " + revenge
	_show_notice(title, body)


func _on_offer_buyout(competitor_id: String) -> void:
	var result: Dictionary = GameState.offer_buyout(competitor_id)
	var title := "Отказ"
	if bool(result.get("ok", false)):
		title = "Сделка"
	_show_notice(title, str(result.get("text", "")))


func _on_home_captured(text: String) -> void:
	_show_notice("%s ваш!" % GameState.get_home_city(), text)


func _mmss(seconds: int) -> String:
	return "%d:%02d" % [int(seconds / 60), seconds % 60]


func _refresh_competitors() -> void:
	if _market_status == null:
		return
	var share: float = GameState.get_market_share()
	if GameState.is_home_captured():
		_market_status.text = "Вы — такси №1! Ваша доля %s" % _share_text(share)
	else:
		_market_status.text = "Ваша доля %s из 50%% нужных" % _share_text(share)
	var legend: PackedStringArray = PackedStringArray(["Вы %s" % _share_text(share)])
	var player_part: ColorRect = _market_bar_parts["player"]
	player_part.size_flags_stretch_ratio = maxf(share, 0.004)
	for raw: Variant in GameState.get_competitors():
		var id: String = str(raw.get("id", ""))
		var rival_share: float = GameState.get_competitor_share(id)
		var part: ColorRect = _market_bar_parts.get(id)
		if part != null:
			part.visible = rival_share > 0.0
			part.size_flags_stretch_ratio = maxf(rival_share, 0.004)
		var short_name: String = str(raw.get("name", id)).replace("Таксопарк ", "")
		legend.append("%s %s" % [short_name, _share_text(rival_share) if rival_share > 0.0 else "— ваш"])
	_market_legend.text = "  ·  ".join(legend)

	var active: Dictionary = GameState.get_active_ad()
	for ad_id: Variant in _ad_rows.keys():
		var row: Dictionary = _ad_rows[ad_id]
		var status: Label = row["status"]
		var button: Button = row["button"]
		var id := str(ad_id)
		if str(active.get("id", "")) == id:
			status.text = "Идёт, осталось %s" % _mmss(GameState.get_ad_left())
		elif not active.is_empty():
			status.text = "Сначала закончится текущая кампания"
		else:
			status.text = ""
		button.text = "Запустить\n%s" % GameState.format_money(GameState.get_ad_price(id))
		button.disabled = not GameState.can_buy_ad(id)

	for competitor_id: Variant in _competitor_rows.keys():
		var id := str(competitor_id)
		var row: Dictionary = _competitor_rows[competitor_id]
		var share_label: Label = row["share"]
		var effects: Label = row["effects"]
		var tricks_box: HBoxContainer = row["tricks_box"]
		var offer: Button = row["offer"]
		var info: Dictionary = {}
		for raw: Variant in GameState.get_competitors():
			if str(raw.get("id", "")) == id:
				info = raw
		if GameState.is_competitor_owned(id):
			share_label.text = "Компания ваша  ·  доход +%d%%" % int(roundf(float(info.get("income_bonus", 0)) * 100.0))
			share_label.add_theme_color_override("font_color", COLOR_INCOME)
			effects.text = ""
			tricks_box.visible = false
			offer.visible = false
			continue
		share_label.text = "Доля %s  ·  возит на %s/с" % [_share_text(GameState.get_competitor_share(id)), GameState.format_money(GameState.get_competitor_power(id))]
		var notes: PackedStringArray = PackedStringArray()
		for cut: Variant in GameState.get_competitor_cuts(id):
			notes.append("−%d%% ещё %s" % [int(roundf(float(cut["cut"]) * 100.0)), _mmss(int(cut["left"]))])
		var lost: float = GameState.get_competitor_lost_drivers(id)
		if lost > 0.0:
			notes.append("переманено водителей: −%d%% навсегда" % int(roundf(lost * 100.0)))
		var wait: int = GameState.get_trick_wait(id)
		if wait > 0:
			notes.append("новая пакость через %s" % _mmss(wait))
		effects.text = "  ·  ".join(notes)
		var tricks: Dictionary = row["tricks"]
		for trick_id: Variant in tricks.keys():
			var button: Button = tricks[trick_id]
			var tid := str(trick_id)
			var trick_name: String = ""
			for raw: Variant in GameState.get_tricks():
				if str(raw.get("id", "")) == tid:
					trick_name = str(raw.get("name", tid))
			button.text = "%s\n%s · риск %d%%" % [
				trick_name,
				GameState.format_money(GameState.get_trick_price(tid)),
				int(roundf(GameState.get_catch_chance(id, tid) * 100.0)),
			]
			button.disabled = not GameState.can_play_trick(id, tid)
		var buy_wait: int = GameState.get_buyout_wait(id)
		if buy_wait > 0:
			offer.text = "Обиделись на прошлое предложение. Ещё %s" % _mmss(buy_wait)
		else:
			offer.text = "Предложить выкуп %s  ·  откажут с шансом %d%%" % [
				GameState.format_money(GameState.get_competitor_cost(id)),
				int(roundf(GameState.get_buyout_refuse_chance(id) * 100.0)),
			]
		offer.disabled = not GameState.can_offer_buyout(id)


func _share_text(share: float) -> String:
	var percent: float = share * 100.0
	if percent >= 10.0 or percent == 0.0:
		return "%d%%" % int(roundf(percent))
	return "%.1f%%" % percent


func _make_sell_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	title.text = "Продать компанию"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	column.add_child(title)

	_sell_info = Label.new()
	_sell_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sell_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_info.add_theme_font_size_override("font_size", 26)
	_sell_info.add_theme_color_override("font_color", COLOR_MUTED)
	column.add_child(_sell_info)

	_sell_button = Button.new()
	_sell_button.text = "Продать компанию"
	_sell_button.custom_minimum_size = Vector2(0, 110)
	_sell_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(_sell_button)
	_sell_button.pressed.connect(_ask_sell)
	column.add_child(_sell_button)
	return panel


func _refresh_sell() -> void:
	if _sell_info == null:
		return
	var now: float = GameState.get_franchise()
	var preview: float = GameState.get_preview_franchise()
	_sell_info.text = "Заработано за все забеги: %s\nБыло ×%s → станет ×%s" % [
		GameState.format_money(GameState.lifetime_earned),
		GameState.format_number(now),
		GameState.format_number(preview),
	]
	var reason: String = GameState.get_sell_block_reason()
	if reason != "":
		_sell_info.text += "\n" + reason
	_sell_button.disabled = not GameState.can_sell_company()
	if _sell_button.disabled:
		_sell_button.text = "Рано продавать"
	else:
		_sell_button.text = "Продать компанию"


func _ask_sell() -> void:
	var now: float = GameState.get_franchise()
	var preview: float = GameState.get_preview_franchise()
	_sell_body.text = "Монеты, улучшения, водители, районы, регионы и выкуп обнулятся.\nРепутация тоже начнётся заново.\n\nФраншиза: ×%s → ×%s" % [
		GameState.format_number(now),
		GameState.format_number(preview),
	]
	_sell_layer.visible = true


func _confirm_sell() -> void:
	_sell_layer.visible = false
	if GameState.sell_company():
		_show_page(PAGE_TAP)
		_show_notice("Компания продана", "Франшиза теперь ×%s. Она умножает весь доход." % GameState.format_number(GameState.get_franchise()))


func _close_sell() -> void:
	_sell_layer.visible = false


func _on_franchise_changed(_value: float) -> void:
	_refresh_meta_line()
	_refresh_sell()


func _build_sell_popup() -> void:
	_sell_layer = Control.new()
	_sell_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sell_layer.visible = false
	_sell_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_sell_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sell_layer.add_child(center)

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
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_make_center_label("Продать компанию?", 44, Color.WHITE))
	_sell_body = _make_center_label("", 28, COLOR_MUTED)
	_sell_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_sell_body)
	box.add_child(_make_settings_button("Продать", COLOR_DANGER, _confirm_sell))
	box.add_child(_make_settings_button("Отмена", COLOR_PANEL, _close_sell))


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


func _build_city_page() -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	page.add_child(_build_city_switch())

	var stack := Control.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(stack)

	var district_page := _build_scroll_page()
	var world_page := _build_scroll_page()
	var achievement_page := _build_scroll_page()
	_city_sections = [district_page, world_page, achievement_page]
	for section: Control in _city_sections:
		section.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.add_child(section)
	_district_list = district_page.get_child(0).get_child(0) as VBoxContainer
	_world_list = world_page.get_child(0).get_child(0) as VBoxContainer
	_achievement_list = achievement_page.get_child(0).get_child(0) as VBoxContainer
	_show_city_section(0)
	return page


func _build_city_switch() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	_city_section_buttons = [
		_make_section_button("Районы"),
		_make_section_button("Мир"),
		_make_section_button("Достижения"),
	]
	for index in _city_section_buttons.size():
		var button: Button = _city_section_buttons[index]
		button.pressed.connect(_show_city_section.bind(index))
		bar.add_child(button)
	return bar


func _make_section_button(title: String) -> Button:
	var button := Button.new()
	button.text = title
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 72)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 26)
	return button


func _show_city_section(index: int) -> void:
	for section_index in _city_sections.size():
		_city_sections[section_index].visible = section_index == index
		var button: Button = _city_section_buttons[section_index]
		var active: bool = section_index == index
		var background: Color = COLOR_TAXI if active else COLOR_PANEL
		var font_color: Color = COLOR_INK if active else Color.WHITE
		_style_plain_button(button, background)
		button.add_theme_color_override("font_color", font_color)
		button.add_theme_color_override("font_hover_color", font_color)
		button.add_theme_color_override("font_pressed_color", font_color)
		button.add_theme_color_override("font_focus_color", font_color)


func _build_city_rows() -> void:
	for raw: Variant in GameState.get_cities():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var city: Dictionary = raw
		var title := Label.new()
		title.text = str(city.get("name", "Город"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		_district_list.add_child(title)

		var about := Label.new()
		about.text = str(city.get("description", ""))
		about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		about.add_theme_font_size_override("font_size", 26)
		about.add_theme_color_override("font_color", COLOR_MUTED)
		_district_list.add_child(about)

		_multiplier_label = Label.new()
		_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_multiplier_label.add_theme_font_size_override("font_size", 32)
		_multiplier_label.add_theme_color_override("font_color", COLOR_INCOME)
		_district_list.add_child(_multiplier_label)

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
			_district_list.add_child(_make_district_row(district_id, info))
	_build_region_rows()
	_build_achievement_rows()


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
	_world_list.add_child(title)

	var hint := Label.new()
	hint.text = "Репутация растёт от заказов: +1 за каждые 20 тапов и за каждого нанятого водителя."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_world_list.add_child(hint)

	for raw: Variant in GameState.get_regions():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var region_id: String = str(info.get("id", ""))
		if region_id == "":
			continue
		_world_list.add_child(_make_region_row(region_id, info))


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
			open_button.text = "Открыть\n%s" % GameState.format_money(cost)
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
			open_button.text = "Открыть\n%s" % GameState.format_money(cost)
			open_button.disabled = not GameState.can_open_region(id)
			reason_label.text = GameState.get_region_block_reason(id)


func _build_upgrade_rows() -> void:
	_build_car_rows()
	_upgrade_list.add_child(_make_section_title("Тюнинг"))
	for raw: Variant in GameState.get_upgrades():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var upgrade_id: String = str(info.get("id", ""))
		if upgrade_id == "":
			continue
		_upgrade_list.add_child(_make_upgrade_row(upgrade_id, info))


func _make_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	return label


## Сверху — на чём ездим сейчас, ниже — машины, которые можно арендовать или купить.
func _build_car_rows() -> void:
	var now_panel := PanelContainer.new()
	now_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	now_panel.add_theme_stylebox_override("panel", _panel_style())
	_upgrade_list.add_child(now_panel)
	var now_box := VBoxContainer.new()
	now_box.add_theme_constant_override("separation", 4)
	now_panel.add_child(now_box)
	_car_now_label = Label.new()
	_car_now_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_car_now_label.add_theme_font_size_override("font_size", 36)
	now_box.add_child(_car_now_label)
	_car_rent_label = Label.new()
	_car_rent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_car_rent_label.add_theme_font_size_override("font_size", 26)
	_car_rent_label.add_theme_color_override("font_color", COLOR_MUTED)
	now_box.add_child(_car_rent_label)

	_upgrade_list.add_child(_make_section_title("Автосалон"))
	var cars: Array = GameState.get_cars()
	# Первая машина — стартовая, её не продают.
	for index in range(1, cars.size()):
		var raw: Variant = cars[index]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var car_id: String = str(info.get("id", ""))
		if car_id != "":
			_upgrade_list.add_child(_make_car_row(car_id, info))


func _make_car_row(car_id: String, info: Dictionary) -> PanelContainer:
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
	title.text = str(info.get("name", car_id))
	title.add_theme_font_size_override("font_size", 36)
	text_box.add_child(title)

	var description := Label.new()
	description.text = str(info.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 26)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	text_box.add_child(description)

	var mult_label := Label.new()
	mult_label.text = "Доход с тапа ×%s" % GameState.format_number(float(info.get("tap_mult", 1)))
	mult_label.add_theme_font_size_override("font_size", 26)
	mult_label.add_theme_color_override("font_color", COLOR_INCOME)
	text_box.add_child(mult_label)

	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.add_theme_color_override("font_color", COLOR_GOLD)
	text_box.add_child(status_label)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	row.add_child(buttons)

	var rent_button := Button.new()
	rent_button.custom_minimum_size = Vector2(230, 110)
	rent_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(rent_button)
	rent_button.pressed.connect(_on_rent_car.bind(car_id))
	buttons.add_child(rent_button)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(230, 110)
	buy_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(buy_button)
	buy_button.pressed.connect(_on_buy_car.bind(car_id))
	buttons.add_child(buy_button)

	_car_rows[car_id] = {"status": status_label, "rent": rent_button, "buy": buy_button}
	return panel


func _on_rent_car(car_id: String) -> void:
	GameState.rent_car(car_id)


func _on_buy_car(car_id: String) -> void:
	GameState.buy_car(car_id)


func _on_car_changed() -> void:
	var info: Dictionary = GameState.get_car_info()
	if _taxi_sign_label != null:
		_taxi_sign_label.text = str(info.get("sign", "ТАКСИ"))
	_refresh_cars()
	_refresh_rate_line()


func _refresh_cars() -> void:
	if _car_now_label == null:
		return
	var info: Dictionary = GameState.get_car_info()
	var current_id: String = GameState.get_car_id()
	_car_now_label.text = "Вы ездите: %s  ·  тап ×%s" % [
		str(info.get("name", "")),
		GameState.format_number(GameState.get_car_tap_mult()),
	]
	if GameState.is_car_rented():
		_car_rent_label.text = "Машина в аренде: владелец забирает %d%% дохода с тапа. Выкупите её — и всё ваше." % int(roundf(GameState.get_rent_share() * 100.0))
	else:
		_car_rent_label.text = "Машина ваша, весь доход с тапа — тоже."
	for car_id: Variant in _car_rows.keys():
		var id := str(car_id)
		var row: Dictionary = _car_rows[car_id]
		var status_label: Label = row["status"]
		var rent_button: Button = row["rent"]
		var buy_button: Button = row["buy"]
		if id == current_id:
			status_label.text = "В аренде, вы на ней ездите" if GameState.is_car_rented() else "Ваша, вы на ней ездите"
		elif GameState.is_car_owned(id):
			status_label.text = "Куплена"
		else:
			status_label.text = ""
		rent_button.text = "Аренда\n%s" % GameState.format_money(GameState.get_car_rent_cost(id))
		rent_button.disabled = not GameState.can_rent_car(id)
		rent_button.visible = not GameState.is_car_owned(id) and id != current_id
		buy_button.text = "Купить\n%s" % GameState.format_money(GameState.get_car_buy_cost(id))
		buy_button.disabled = not GameState.can_buy_car(id)
		buy_button.visible = not GameState.is_car_owned(id)


func _on_company_changed(company_name: String) -> void:
	if _company_label != null:
		_company_label.text = "Такси «%s»" % company_name if company_name != "" else ""


## Окно при первом запуске: игрок называет свою компанию.
func _build_name_popup() -> void:
	_name_layer = Control.new()
	_name_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_name_layer.visible = false
	_name_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_name_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(880, 0)
	var style := _panel_style()
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 44
	style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	panel.add_child(box)
	box.add_child(_make_center_label("Ваше такси", 52, Color.WHITE))
	var hint := _make_center_label("Бангкок ждёт. Как будет называться ваша компания? Конкуренты должны знать, кого бояться.", 28, COLOR_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Например: Жёлтая молния"
	_name_edit.max_length = GameState.COMPANY_NAME_MAX
	_name_edit.custom_minimum_size = Vector2(0, 100)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 36)
	_name_edit.text_submitted.connect(_on_name_submitted)
	box.add_child(_name_edit)

	_name_error = _make_center_label("", 26, COLOR_DANGER)
	box.add_child(_name_error)
	box.add_child(_make_settings_button("Открыть компанию", COLOR_BUY, _on_name_confirm))


func _show_name_popup() -> void:
	if GameState.has_company_name():
		_name_layer.visible = false
		return
	_name_edit.text = ""
	_name_error.text = ""
	_name_layer.visible = true
	move_child(_name_layer, get_child_count() - 1)


func _on_name_submitted(_text: String) -> void:
	_on_name_confirm()


func _on_name_confirm() -> void:
	if not GameState.set_company_name(_name_edit.text):
		_name_error.text = "Без названия клиенты вас не найдут."
		return
	_name_layer.visible = false


func _build_driver_rows() -> void:
	var hint := Label.new()
	hint.text = "Водитель + свободная машина из гаража = доход, даже когда вы не тапаете. Зарплата вычитается сама. Лучшим водителям диспетчер сам даёт лучшие машины."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	_driver_list.add_child(hint)

	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", _panel_style())
	_driver_list.add_child(summary)
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 16)
	summary.add_child(summary_row)
	var summary_text := VBoxContainer.new()
	summary_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(summary_text)
	_garage_label = Label.new()
	_garage_label.add_theme_font_size_override("font_size", 34)
	summary_text.add_child(_garage_label)
	_staff_summary = Label.new()
	_staff_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_staff_summary.add_theme_font_size_override("font_size", 26)
	_staff_summary.add_theme_color_override("font_color", COLOR_INCOME)
	summary_text.add_child(_staff_summary)
	_expand_button = _make_row_button(_on_expand_garage)
	summary_row.add_child(_expand_button)

	var service := PanelContainer.new()
	service.add_theme_stylebox_override("panel", _panel_style())
	_driver_list.add_child(service)
	var service_box := VBoxContainer.new()
	service_box.add_theme_constant_override("separation", 10)
	service.add_child(service_box)
	_rating_label = _add_label(service_box, "", 28, COLOR_GOLD)
	_fleet_wear_label = _add_label(service_box, "", 26, COLOR_MUTED)
	var service_row := HBoxContainer.new()
	service_row.add_theme_constant_override("separation", 12)
	service_box.add_child(service_row)
	_wash_fleet_button = _make_row_button(_on_wash_fleet)
	_wash_fleet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wash_fleet_button.custom_minimum_size = Vector2(0, 100)
	service_row.add_child(_wash_fleet_button)
	_repair_fleet_button = _make_row_button(_on_repair_fleet)
	_repair_fleet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_repair_fleet_button.custom_minimum_size = Vector2(0, 100)
	service_row.add_child(_repair_fleet_button)
	_shift_all_button = _make_row_button(_on_shift_all)
	_shift_all_button.custom_minimum_size = Vector2(0, 90)
	service_box.add_child(_shift_all_button)

	_driver_list.add_child(_make_section_title("Помощники"))
	for raw: Variant in GameState.get_helpers():
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) != "":
			_driver_list.add_child(_make_helper_row(raw))

	_driver_list.add_child(_make_section_title("Команда"))
	_team_box = VBoxContainer.new()
	_team_box.add_theme_constant_override("separation", 16)
	_driver_list.add_child(_team_box)

	_driver_list.add_child(_make_section_title("Кандидаты"))
	_candidate_box = VBoxContainer.new()
	_candidate_box.add_theme_constant_override("separation", 16)
	_driver_list.add_child(_candidate_box)
	_refresh_button = Button.new()
	_refresh_button.custom_minimum_size = Vector2(0, 96)
	_refresh_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(_refresh_button)
	_refresh_button.pressed.connect(_on_refresh_candidates)
	_driver_list.add_child(_refresh_button)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_refresh_candidate_timer)
	add_child(timer)

	_driver_list.add_child(_make_section_title("Купить машину в парк"))
	var cars: Array = GameState.get_cars()
	for index in range(1, cars.size()):
		var raw: Variant = cars[index]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var car_id: String = str(info.get("id", ""))
		if car_id != "":
			_driver_list.add_child(_make_fleet_row(car_id, info))
	_rebuild_staff()


func _make_row_button(callback: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(230, 120)
	button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(button)
	button.pressed.connect(callback)
	return button


func _make_text_box(row: HBoxContainer) -> VBoxContainer:
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)
	return text_box


## Панель-строка: [PanelContainer, HBoxContainer внутри].
func _make_row_panel() -> Array:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	return [panel, row]


func _add_label(box: Container, text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	box.add_child(label)
	return label


func _stars_text(stars: int) -> String:
	return "★".repeat(stars) + "☆".repeat(maxi(0, 3 - stars))


func _person_line(person: Dictionary) -> String:
	var trait_info: Dictionary = GameState.get_trait_info(str(person.get("trait", "")))
	return "%s  ·  %s" % [_stars_text(int(person.get("stars", 1))), str(trait_info.get("name", ""))]


func _car_name(car_id: String) -> String:
	for raw: Variant in GameState.get_cars():
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) == car_id:
			return str(raw.get("name", car_id))
	return car_id


func _make_fleet_row(car_id: String, info: Dictionary) -> PanelContainer:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	var text_box := _make_text_box(row)
	_add_label(text_box, str(info.get("name", car_id)), 36)
	_add_label(text_box, "Водителю: %s/с без звёзд и бонусов" % GameState.format_money(float(info.get("driver_income", 0))), 26, COLOR_INCOME)
	var count_label := _add_label(text_box, "", 28, COLOR_GOLD)
	var note := _add_label(text_box, "", 24, COLOR_MUTED)
	var button := _make_row_button(_on_buy_fleet.bind(car_id))
	row.add_child(button)
	_fleet_rows[car_id] = {"count": count_label, "button": button, "note": note}
	return parts[0]


## Команда и кандидаты меняются по составу — пересобираем их целиком.
func _rebuild_staff() -> void:
	if _team_box == null:
		return
	_staff_buttons.clear()
	_team_wear_rows.clear()
	_team_shift_rows.clear()
	for child in _team_box.get_children():
		child.queue_free()
	for child in _candidate_box.get_children():
		child.queue_free()

	var cars: Dictionary = GameState.get_assignments()
	if GameState.get_team().is_empty():
		_add_label(_team_box, "Пока никого. Купите машину в парк и наймите первого водителя.", 26, COLOR_MUTED)
	for raw: Variant in GameState.get_team():
		var person: Dictionary = raw
		var uid: int = int(person.get("uid", 0))
		var parts: Array = _make_row_panel()
		var row: HBoxContainer = parts[1]
		var text_box := _make_text_box(row)
		_add_label(text_box, str(person.get("name", "")), 34)
		_add_label(text_box, _person_line(person), 26, COLOR_GOLD)
		var car: Dictionary = cars.get(uid, {})
		if car.is_empty():
			_add_label(text_box, "Без машины — купите ещё одну в парк", 26, COLOR_DANGER)
		else:
			var car_label := _add_label(text_box, "", 26, COLOR_INCOME)
			_team_wear_rows[uid] = [car_label, person, car]
		var shift_label := _add_label(text_box, "", 24, COLOR_MUTED)
		var shift_bar := _make_bar(Color("b39ddb"))
		shift_bar.max_value = 14.0
		text_box.add_child(shift_bar)
		var buttons := VBoxContainer.new()
		buttons.add_theme_constant_override("separation", 10)
		row.add_child(buttons)
		var shift_button := Button.new()
		shift_button.text = "Сменить"
		shift_button.custom_minimum_size = Vector2(200, 80)
		shift_button.focus_mode = Control.FOCUS_NONE
		_style_buy_button(shift_button)
		shift_button.add_theme_font_size_override("font_size", 26)
		shift_button.pressed.connect(_on_change_shift.bind(uid))
		buttons.add_child(shift_button)
		var fire_button := Button.new()
		fire_button.text = "Уволить"
		fire_button.custom_minimum_size = Vector2(200, 70)
		fire_button.focus_mode = Control.FOCUS_NONE
		_style_plain_button(fire_button, COLOR_DANGER)
		fire_button.add_theme_font_size_override("font_size", 24)
		fire_button.pressed.connect(_on_fire.bind(uid))
		buttons.add_child(fire_button)
		_team_shift_rows[uid] = [shift_label, shift_bar, shift_button, person]
		_team_box.add_child(parts[0])

	var free_cars: Array = GameState.get_free_garage_cars()
	var candidates: Array = GameState.get_candidates()
	for index in candidates.size():
		var person: Dictionary = candidates[index]
		var parts: Array = _make_row_panel()
		var row: HBoxContainer = parts[1]
		var text_box := _make_text_box(row)
		_add_label(text_box, str(person.get("name", "")), 34)
		_add_label(text_box, _person_line(person), 26, COLOR_GOLD)
		var trait_info: Dictionary = GameState.get_trait_info(str(person.get("trait", "")))
		_add_label(text_box, str(trait_info.get("description", "")), 24, COLOR_MUTED)
		if free_cars.is_empty():
			_add_label(text_box, "Нет свободной машины в гараже", 26, COLOR_DANGER)
		else:
			var free_model: String = str(free_cars[0].get("model", ""))
			_add_label(text_box, "На «%s» ≈ %s/с  ·  зарплата %d%%" % [
				_car_name(free_model),
				GameState.format_money(GameState.get_driver_net(person, free_model)),
				int(roundf(GameState.get_salary_share(person) * 100.0)),
			], 26, COLOR_INCOME)
		var hire_button := _make_row_button(_on_hire.bind(index))
		hire_button.text = "Нанять\n%s" % GameState.format_money(GameState.get_hire_cost(person))
		row.add_child(hire_button)
		_staff_buttons.append([hire_button, GameState.can_hire.bind(index)])
		_candidate_box.add_child(parts[0])
	_refresh_staff_money()
	_on_wear_changed()
	_on_shifts_changed()


## Только то, что зависит от денег: доступность кнопок и цены.
func _refresh_staff_money() -> void:
	if _garage_label == null:
		return
	for pair: Variant in _staff_buttons:
		var button: Button = pair[0]
		var check: Callable = pair[1]
		if is_instance_valid(button):
			button.disabled = not check.call()
	_garage_label.text = "Гараж: %d / %d  ·  водителей: %d" % [
		GameState.get_garage().size(),
		GameState.get_garage_capacity(),
		GameState.get_team().size(),
	]
	_staff_summary.text = _staff_summary_text()
	var step: Dictionary = GameState.get_next_expansion()
	if step.is_empty():
		_expand_button.text = "Гараж\nмаксимум"
		_expand_button.disabled = true
	else:
		_expand_button.text = "+%d мест\n%s" % [int(step.get("add", 0)), GameState.format_money(float(step.get("cost", 0)))]
		_expand_button.disabled = not GameState.can_expand_garage()
	var full: bool = GameState.is_garage_full()
	var worst: String = GameState.get_worst_garage_car()
	for car_id: Variant in _fleet_rows.keys():
		var id := str(car_id)
		var row: Dictionary = _fleet_rows[car_id]
		var count_label: Label = row["count"]
		var button: Button = row["button"]
		var note: Label = row["note"]
		count_label.text = "В парке: %d" % GameState.get_fleet_count(id)
		var price: String = GameState.format_money(GameState.get_fleet_cost(id))
		if full:
			button.text = "Обмен\n%s" % price
			if GameState.get_car_driver_income(id) > GameState.get_car_driver_income(worst):
				note.text = "Гараж полон: отдадите «%s» за %s" % [_car_name(worst), GameState.format_money(GameState.get_trade_in_value(worst))]
			else:
				note.text = "Гараж полон, а эта машина не лучше худшей в парке"
		else:
			button.text = "В парк\n%s" % price
			note.text = ""
		button.disabled = not GameState.can_buy_fleet(id)
	_refresh_candidate_timer()


func _refresh_candidate_timer() -> void:
	if _refresh_button == null:
		return
	var left: int = GameState.get_refresh_left()
	_refresh_button.disabled = left > 0
	_refresh_button.text = "Позвать других кандидатов" if left == 0 else "Новые кандидаты через %d с" % left


func _on_hire(index: int) -> void:
	GameState.hire(index)


func _on_fire(uid: int) -> void:
	GameState.fire(uid)


func _on_buy_fleet(car_id: String) -> void:
	GameState.buy_fleet(car_id)


func _on_expand_garage() -> void:
	GameState.expand_garage()


func _on_refresh_candidates() -> void:
	GameState.refresh_candidates()


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
	_offline_label.text = "Пока вас не было, заработано %s" % GameState.format_money(amount)
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


func _build_achievement_rows() -> void:
	var title := Label.new()
	title.text = "ДОСТИЖЕНИЯ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	_achievement_list.add_child(title)

	for raw: Variant in GameState.get_achievements():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var achievement_id: String = str(info.get("id", ""))
		if achievement_id == "":
			continue
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _panel_style())
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 28)
		panel.add_child(label)
		_achievement_list.add_child(panel)
		_achievement_labels[achievement_id] = label


func _refresh_achievements() -> void:
	for achievement_id: Variant in _achievement_labels.keys():
		var label: Label = _achievement_labels[achievement_id]
		var info: Dictionary = {}
		for raw: Variant in GameState.get_achievements():
			if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) == str(achievement_id):
				info = raw
				break
		var need: float = float(info.get("need", 1))
		var value: float = GameState.get_achievement_value(str(info.get("kind", "")))
		var reward := "+%s" % GameState.format_money(float(info.get("reward_coins", 0)))
		if GameState.is_achievement_done(str(achievement_id)):
			label.text = "%s\nПолучено, награда %s" % [str(info.get("name", "")), reward]
			label.add_theme_color_override("font_color", COLOR_INCOME)
		else:
			label.text = "%s\n%s / %s, награда %s" % [
				str(info.get("name", "")),
				GameState.format_number(minf(value, need)),
				GameState.format_number(need),
				reward,
			]
			label.add_theme_color_override("font_color", Color.WHITE)


func _on_achievement_unlocked(title: String, body: String) -> void:
	_enqueue_toast(title, body)
	_refresh_achievements()


func _enqueue_toast(title: String, body: String) -> void:
	_toast_queue.append("%s\n%s" % [title, body])
	if _toast_layer != null and not _toast_layer.visible:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_layer.visible = false
		return
	_toast_label.text = str(_toast_queue.pop_front())
	_toast_layer.visible = true
	_toast_timer.start(2.2)


func _build_toast() -> void:
	_toast_layer = PanelContainer.new()
	_toast_layer.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_layer.offset_left = -420
	_toast_layer.offset_right = 420
	_toast_layer.offset_top = 36
	_toast_layer.offset_bottom = 190
	_toast_layer.visible = false
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _panel_style()
	style.bg_color = Color("1d4a32")
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_toast_layer.add_theme_stylebox_override("panel", style)
	add_child(_toast_layer)

	_toast_label = _make_center_label("", 30, Color.WHITE)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_layer.add_child(_toast_label)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_show_next_toast)
	add_child(_toast_timer)


func _build_daily_popup() -> void:
	_daily_layer = Control.new()
	_daily_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_daily_layer.visible = false
	_daily_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_daily_layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daily_layer.add_child(center)

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
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	box.add_child(_make_center_label("Ежедневная награда", 44, Color.WHITE))
	box.add_child(_make_center_label("$250.\nЗаходите завтра — награда обновится.", 30, COLOR_MUTED))
	box.add_child(_make_settings_button("Забрать", COLOR_BUY, _on_collect_daily))


func _show_daily_popup() -> void:
	if not GameState.has_daily_reward():
		_daily_layer.visible = false
		return
	_daily_layer.visible = true


func _on_collect_daily() -> void:
	GameState.collect_daily_reward()
	_daily_layer.visible = false


func _on_collect_offline() -> void:
	GameState.collect_offline_reward()
	_offline_layer.visible = false
	_show_daily_popup()


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
	label.text = "+%s" % GameState.format_money(amount)
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
		button.add_theme_color_override("font_focus_color", font_color)


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
	_show_name_popup()


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
	var hint := _make_center_label("Сброс стирает деньги, улучшения и водителей. Это для проверки игры.", 28, COLOR_MUTED)
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


func _on_coins_changed(value: float) -> void:
	_refresh_achievements()
	var text := GameState.format_money(value)
	# Пока на экране та же строка, подпись не трогаем — иначе цифры двоятся.
	if _coins_label.text == text:
		return
	_coins_label.text = text
	_refresh_upgrades()
	_refresh_staff_money()
	_refresh_districts()
	_refresh_regions()
	_refresh_competitors()
	_refresh_sell()
	_refresh_cars()
	_on_wear_changed()
	_refresh_helpers()


func _on_tap_power_changed(_value: float) -> void:
	_refresh_rate_line()


func _on_income_changed(_value: float) -> void:
	_refresh_rate_line()


func _refresh_rate_line() -> void:
	_tap_label.text = "За тап: %s  ·  В секунду: %s" % [
		GameState.format_money(GameState.get_tap_power()),
		GameState.format_money(GameState.get_income_per_second()),
	]
	_refresh_market_share()


func _refresh_market_share() -> void:
	var share: float = GameState.get_market_share()
	var percent: float = share * 100.0
	var text: String
	if percent >= 100.0:
		text = "100%"
	elif percent >= 10.0:
		text = "%d%%" % int(percent)
	else:
		text = "%.1f%%" % percent
	_share_label.text = "Доля рынка, %s: %s" % [GameState.get_home_city(), text]
	_share_fill.anchor_right = share


func _refresh_meta_line() -> void:
	_reputation_label.text = "★ %.1f  ·  Репутация: %d  ·  Франшиза: ×%s" % [
		GameState.get_rating(),
		GameState.reputation,
		GameState.format_number(GameState.get_franchise()),
	]


func _on_upgrades_changed() -> void:
	_refresh_upgrades()


func _on_drivers_changed() -> void:
	_rebuild_staff()


func _on_districts_changed() -> void:
	_refresh_districts()


func _on_regions_changed() -> void:
	_refresh_regions()
	_refresh_districts()


func _on_reputation_changed(_value: int) -> void:
	_refresh_meta_line()
	_refresh_regions()
	_refresh_achievements()


func _refresh_upgrades() -> void:
	for upgrade_id: Variant in _upgrade_rows.keys():
		var row: Dictionary = _upgrade_rows[upgrade_id]
		var level_label: Label = row["level"]
		var buy_button: Button = row["button"]
		var id := str(upgrade_id)
		level_label.text = "Уровень: %d" % GameState.get_upgrade_level(id)
		var cost: float = GameState.get_upgrade_cost(id)
		buy_button.text = "Купить\n%s" % GameState.format_money(cost)
		buy_button.disabled = not GameState.can_buy_upgrade(id)
