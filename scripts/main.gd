extends Control
## Главный экран. Весь интерфейс собирается в коде, сцена остаётся пустой.
## Экран не хранит экономику: он просит GameState и рисует то, что пришло в сигналах.

# >>> PALETTE
## Палитра «sky». Меняется целиком: все цвета экрана берутся отсюда.
const COLOR_BG_TOP := Color("62c6ff")
const COLOR_BG_BOTTOM := Color("2b8ae6")
const COLOR_BG := Color("2b8ae6")
const COLOR_TEXT := Color("1c2b4d")
const COLOR_MUTED := Color("5c6d90")
const COLOR_INK := Color("1c2b4d")
const COLOR_PANEL := Color("ffffff")
const COLOR_PANEL_EDGE := Color("b8d6f2")
const COLOR_ACCENT := Color("ffc93c")
const COLOR_GOLD := Color("c77d00")
const COLOR_MONEY := Color("ffd23f")
const COLOR_PILL := Color("1c2b4d")
const COLOR_CHIP := Color("ffffff")
const COLOR_DOCK := Color("ffffff")
const COLOR_BUY := Color("2fbf5f")
const COLOR_BUY_HOVER := Color("47c672")
const COLOR_BUY_PRESSED := Color("2aab55")
const COLOR_DISABLED := Color("d5e2f0")
const COLOR_INCOME := Color("1e9e4a")
const COLOR_DANGER := Color("ff4d5e")
const COLOR_TRICK := Color("ff8a3d")
const COLOR_SKY := Color("3fb2ff")
const COLOR_SHIFT := Color("8c9eff")
const COLOR_TITLE := Color("ffffff")
const COLOR_TITLE_OUTLINE := Color("1c4f8f")
const COLOR_TAXI := Color("ffc107")
const COLOR_TAXI_PRESSED := Color("e0a800")
const COLOR_WINDOW := Color("26324a")
# <<< PALETTE

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
const CityView := preload("res://scripts/city_view.gd")
const CarIcon := preload("res://scripts/car_icon.gd")
var _city: Control
const TouchScroll := preload("res://scripts/touch_scroll.gd")
## Какая вкладка открыта и нужно ли обновить её списки (деньги поменялись).
var _current_page: int = 0
var _ui_dirty: bool = false
const Mentor := preload("res://scripts/mentor.gd")
const MentorPortrait := preload("res://scripts/mentor_portrait.gd")
var _mentor: Node
var _mentor_bubble: PanelContainer
var _mentor_portrait: Control
var _mentor_text: Label
var _mentor_button: Button
var _mentor_skip: Button
var _mentor_task: PanelContainer
var _mentor_task_label: Label
var _mentor_kind: String = ""
var _mentor_last_step_text: String = ""
var _mentor_task_text: String = ""
var _mentor_hide_timer: Timer
var _mentor_tips_button: Button
var _tap_hint: Label
var _sfx_tap: AudioStreamPlayer
var _sfx_buy: AudioStreamPlayer
var _sound_on: bool = true
var _sound_button: Button
var _music: AudioStreamPlayer
var _music_on: bool = true
var _music_button: Button
var _last_coins: float = -1.0
const SETTINGS_PATH := "user://settings.cfg"
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
## Шапка вкладки «Рынок»: сколько конкурентов города выкуплено.
var _market_status: Label
## id конкурента -> Label-ступенька на лестнице соперников.
var _ladder_steps: Dictionary = {}
## id рекламы -> {"status", "button"}.
var _ad_rows: Dictionary = {}
## Для какого острова собрана вкладка «Рынок». Фронт сменился — пересобираем.
var _market_built_for: String = "-"
const IslandMap := preload("res://scripts/island_map.gd")
var _island_map: Control
var _selected_island: String = ""
var _world_progress: Label
var _island_title: Label
var _island_description: Label
var _island_status: Label
var _island_reason: Label
var _island_button: Button
var _notice_layer: Control
var _notice_queue: Array = []
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
var _car_now_label: Label
var _car_rent_label: Label
## id машины -> {"status", "rent", "buy"}.
var _car_rows: Dictionary = {}
var _name_layer: Control
var _name_edit: LineEdit
var _name_error: Label


func _ready() -> void:
	_apply_theme()
	_build_sounds()
	_build_ui()
	var ui_timer := Timer.new()
	ui_timer.wait_time = 0.25
	ui_timer.autostart = true
	ui_timer.timeout.connect(_flush_ui)
	add_child(ui_timer)
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
	GameState.island_captured.connect(_on_island_captured)
	GameState.rival_surrendered.connect(_on_rival_surrendered)
	GameState.rival_attacked.connect(_on_rival_attacked)
	GameState.franchise_changed.connect(_on_franchise_changed)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)
	GameState.achievements_changed.connect(_refresh_achievements)
	GameState.offline_reward_ready.connect(_show_offline_popup)
	GameState.car_changed.connect(_on_car_changed)
	GameState.garage_changed.connect(_on_drivers_changed)
	GameState.wear_changed.connect(_on_wear_changed)
	GameState.shifts_changed.connect(_on_shifts_changed)
	GameState.helpers_changed.connect(_refresh_helpers)
	GameState.wear_changed.connect(_sync_city)
	GameState.shifts_changed.connect(_sync_city)
	GameState.drivers_changed.connect(_sync_city)
	GameState.competitors_changed.connect(_sync_city)
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
	_sync_city()
	_last_coins = GameState.coins
	GameState.shifts_changed.connect(_mentor.tick)
	_mentor.begin()
	for item: Variant in GameState.take_fresh_achievements():
		if typeof(item) == TYPE_DICTIONARY:
			var info: Dictionary = item
			_enqueue_toast(str(info.get("title", "")), str(info.get("body", "")))
	_show_offline_popup()
	if _offline_layer == null or not _offline_layer.visible:
		_show_daily_popup()
	_show_name_popup()


var _display_font: Font


## Шрифты лежат в проекте: Inter SemiBold для текста, Inter Display Black Italic для денег и заголовков.
func _apply_theme() -> void:
	var theme := Theme.new()
	var body: Font = load("res://assets/fonts/Inter-SemiBold.otf")
	_display_font = load("res://assets/fonts/InterDisplay-BlackItalic.otf")
	theme.default_font = body
	theme.default_font_size = 30
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_TEXT)
	theme.set_color("font_pressed_color", "Button", COLOR_TEXT)
	theme.set_color("font_focus_color", "Button", COLOR_TEXT)
	theme.set_color("font_disabled_color", "Button", Color(COLOR_TEXT, 0.45))
	var bold: Font = load("res://assets/fonts/Inter-Bold.otf")
	theme.set_font("font", "Button", bold)
	self.theme = theme


## Заголовок крупным наклонным шрифтом — «на скорости».
func _display(label: Label, font_size: int, color: Color = COLOR_TEXT) -> Label:
	label.add_theme_font_override("font", _display_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _build_ui() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, COLOR_BG_TOP)
	gradient.set_color(1, COLOR_BG_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var background := TextureRect.new()
	background.texture = texture
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_margin = margin
	add_child(margin)
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)

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
	_build_mentor()
	_build_settings_popup()
	_build_notice_popup()
	_build_sell_popup()
	_build_toast()
	_build_daily_popup()
	_build_offline_popup()
	_build_name_popup()


# --- Дядя Бун -------------------------------------------------------------------

## Облачко с портретом над вкладками и плашка с заданием. Тапы по городу не перекрывает.
func _build_mentor() -> void:
	_mentor = Mentor.new()
	add_child(_mentor)
	_mentor.setup(GameState)
	_mentor.said.connect(_on_mentor_said)
	_mentor.task_changed.connect(_on_mentor_task)
	_mentor.highlight_tab.connect(_on_mentor_highlight)

	_mentor_bubble = PanelContainer.new()
	_mentor_bubble.anchor_left = 0.0
	_mentor_bubble.anchor_right = 1.0
	_mentor_bubble.anchor_top = 1.0
	_mentor_bubble.anchor_bottom = 1.0
	_mentor_bubble.offset_left = 24
	_mentor_bubble.offset_right = -24
	_mentor_bubble.offset_bottom = -188
	_mentor_bubble.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_mentor_bubble.visible = false
	var style := _panel_style()
	style.bg_color = Color.WHITE
	style.set_border_width_all(4)
	style.border_width_bottom = 10
	style.border_color = COLOR_ACCENT.darkened(0.15)
	_mentor_bubble.add_theme_stylebox_override("panel", style)
	add_child(_mentor_bubble)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_mentor_bubble.add_child(row)
	_mentor_portrait = MentorPortrait.new()
	_mentor_portrait.custom_minimum_size = Vector2(170, 170)
	_mentor_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_mentor_portrait)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	row.add_child(box)
	var title := Label.new()
	title.text = _mentor.mentor_name()
	_display(title, 34, COLOR_TEXT)
	box.add_child(title)
	_mentor_text = Label.new()
	_mentor_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mentor_text.add_theme_font_size_override("font_size", 28)
	_mentor_text.add_theme_color_override("font_color", COLOR_TEXT)
	box.add_child(_mentor_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	_mentor_button = _make_settings_button("Понял", COLOR_BUY, _on_mentor_button)
	_mentor_button.custom_minimum_size = Vector2(0, 90)
	_mentor_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_mentor_button)
	_mentor_skip = Button.new()
	_mentor_skip.text = "Пропустить обучение"
	_mentor_skip.flat = true
	_mentor_skip.focus_mode = Control.FOCUS_NONE
	_mentor_skip.add_theme_font_size_override("font_size", 22)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		_mentor_skip.add_theme_color_override(state, COLOR_MUTED)
	_mentor_skip.pressed.connect(_on_mentor_skip)
	buttons.add_child(_mentor_skip)

	_mentor_task = PanelContainer.new()
	_mentor_task.anchor_left = 0.5
	_mentor_task.anchor_right = 0.5
	# Под шапкой: не закрывает полоски машины и кнопки внизу.
	_mentor_task.anchor_top = 0.0
	_mentor_task.anchor_bottom = 0.0
	_mentor_task.offset_top = 336
	_mentor_task.grow_vertical = Control.GROW_DIRECTION_END
	_mentor_task.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_mentor_task.visible = false
	_mentor_task.mouse_filter = Control.MOUSE_FILTER_STOP
	_mentor_task.gui_input.connect(_on_mentor_task_input)
	var pill := StyleBoxFlat.new()
	pill.bg_color = COLOR_PILL
	pill.set_corner_radius_all(40)
	pill.set_border_width_all(4)
	pill.border_color = COLOR_ACCENT
	pill.content_margin_left = 10
	pill.content_margin_right = 26
	pill.content_margin_top = 6
	pill.content_margin_bottom = 6
	_mentor_task.add_theme_stylebox_override("panel", pill)
	add_child(_mentor_task)
	var task_row := HBoxContainer.new()
	task_row.add_theme_constant_override("separation", 12)
	task_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mentor_task.add_child(task_row)
	var mini: Control = MentorPortrait.new()
	mini.custom_minimum_size = Vector2(72, 72)
	task_row.add_child(mini)
	_mentor_task_label = Label.new()
	_mentor_task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mentor_task_label.add_theme_font_size_override("font_size", 26)
	_mentor_task_label.add_theme_color_override("font_color", Color.WHITE)
	_mentor_task_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	task_row.add_child(_mentor_task_label)

	_mentor_hide_timer = Timer.new()
	_mentor_hide_timer.one_shot = true
	_mentor_hide_timer.timeout.connect(_hide_mentor_quip)
	add_child(_mentor_hide_timer)


func _on_mentor_said(text: String, kind: String) -> void:
	# Шутка не перебивает урок или похвалу.
	if kind == "quip" and _mentor_bubble.visible and _mentor_kind != "quip":
		return
	_mentor_kind = kind
	if kind == "step":
		_mentor_last_step_text = text
	_mentor_text.text = text
	match kind:
		"praise":
			_mentor_button.text = "Спасибо, дядя Бун!"
		"quip":
			_mentor_button.text = "Ха!"
		_:
			var step: Dictionary = _mentor.current_step()
			_mentor_button.text = "Дальше" if str(step.get("goal", "")) == "next" else "Понял"
	_mentor_skip.visible = kind == "step" and not _mentor.is_tutorial_done()
	_mentor_bubble.visible = true
	_mentor_task.visible = false
	_mentor_portrait.talk(minf(4.0, 0.6 + text.length() * 0.025))
	_mentor_bubble.pivot_offset = Vector2(_mentor_bubble.size.x / 2.0, _mentor_bubble.size.y)
	_mentor_bubble.scale = Vector2(0.9, 0.9)
	var pop := create_tween()
	pop.tween_property(_mentor_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if kind == "quip":
		_mentor_hide_timer.start(8.0)
	else:
		_mentor_hide_timer.stop()


func _on_mentor_button() -> void:
	_play(_sfx_tap)
	var kind: String = _mentor_kind
	_mentor_bubble.visible = false
	_mentor_kind = ""
	if kind == "step" or kind == "praise":
		_mentor.acknowledge()
	_refresh_mentor_task()


func _hide_mentor_quip() -> void:
	if _mentor_kind == "quip":
		_mentor_bubble.visible = false
		_mentor_kind = ""
		_refresh_mentor_task()


func _on_mentor_skip() -> void:
	_mentor_bubble.visible = false
	_mentor_kind = ""
	_mentor.skip_tutorial()


func _on_mentor_task(text: String, reward: float) -> void:
	_mentor_task_text = text
	if text != "":
		_mentor_task_label.text = "%s  ·  +%s" % [text, GameState.format_money(reward)] if reward > 0.0 else text
	_refresh_mentor_task()


func _refresh_mentor_task() -> void:
	_mentor_task.visible = _mentor_task_text != "" and not _mentor_bubble.visible


## Тап по плашке — дед повторяет, что нужно сделать.
func _on_mentor_task_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_mentor_task.accept_event()
		_on_mentor_said(_mentor_last_step_text, "repeat")


func _on_mentor_highlight(index: int) -> void:
	for tab_index in _tab_icons.size():
		var icon: Control = _tab_icons[tab_index][0]
		icon.glow = tab_index == index


func _toggle_mentor_tips() -> void:
	_mentor.set_tips(not _mentor.tips_on())
	_refresh_mentor_buttons()


func _restart_tutorial() -> void:
	_show_page(PAGE_TAP)
	_mentor.restart_tutorial()


func _refresh_mentor_buttons() -> void:
	if _mentor_tips_button != null:
		_mentor_tips_button.text = "Советы дяди Буна: включены" if _mentor.tips_on() else "Советы дяди Буна: выключены"


# --- Телефон ---------------------------------------------------------------------

var _screen_margin: MarginContainer


## Отступы под «чёлку», вырез камеры и полоску «Домой»: телефон сам сообщает безопасную зону.
func _apply_safe_area() -> void:
	if _screen_margin == null:
		return
	var top: float = 36.0
	var bottom: float = 20.0
	var left: float = 28.0
	var right: float = 28.0
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if window.x > 0.0 and window.y > 0.0 and safe.size.x > 0 and safe.size.y > 0:
		var scale: Vector2 = get_viewport_rect().size / window
		top = maxf(top, float(safe.position.y) * scale.y + 12.0)
		bottom = maxf(bottom, (window.y - float(safe.end.y)) * scale.y + 8.0)
		left = maxf(left, float(safe.position.x) * scale.x + 8.0)
		right = maxf(right, (window.x - float(safe.end.x)) * scale.x + 8.0)
	_screen_margin.add_theme_constant_override("margin_top", int(top))
	_screen_margin.add_theme_constant_override("margin_bottom", int(bottom))
	_screen_margin.add_theme_constant_override("margin_left", int(left))
	_screen_margin.add_theme_constant_override("margin_right", int(right))


## Кнопка «Назад» на Android: закрыть окно → вернуться в город → выйти с сохранением.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	for layer: Variant in [_notice_layer, _sell_layer, _settings_layer, _offline_layer, _daily_layer]:
		var popup: Control = layer
		if popup != null and popup.visible:
			if popup == _notice_layer:
				_close_notice()
			else:
				popup.visible = false
			return
	if _mentor_bubble != null and _mentor_bubble.visible:
		_on_mentor_button()
		return
	if not _tap_page.visible:
		_show_page(PAGE_TAP)
		return
	GameState.save_game()
	get_tree().quit()


func _build_header() -> VBoxContainer:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	_company_label = Label.new()
	_company_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_company_label.clip_text = true
	_display(_company_label, 30, COLOR_TITLE)
	_company_label.add_theme_constant_override("outline_size", 8)
	_company_label.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
	header.add_child(_company_label)

	# Деньги — в тёмной «пилюле» с золотой монетой.
	var pill_center := CenterContainer.new()
	header.add_child(pill_center)
	var pill := PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = COLOR_PILL
	pill_style.set_corner_radius_all(60)
	pill_style.set_border_width_all(4)
	pill_style.border_color = COLOR_MONEY
	pill_style.content_margin_left = 18
	pill_style.content_margin_right = 40
	pill_style.content_margin_top = 6
	pill_style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", pill_style)
	pill_center.add_child(pill)
	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 14)
	pill.add_child(pill_row)
	var coin := _make_coin()
	pill_row.add_child(coin)
	# Фиксированная ширина: цифры не прыгают и не оставляют старых знаков.
	var coin_frame := Control.new()
	coin_frame.custom_minimum_size = Vector2(440, 84)
	coin_frame.clip_contents = true
	pill_row.add_child(coin_frame)
	_coins_label = Label.new()
	_coins_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display(_coins_label, 70, COLOR_MONEY)
	coin_frame.add_child(_coins_label)

	# Чипы: доход в секунду, рейтинг, доля рынка.
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	header.add_child(chips)
	_tap_label = _make_chip(chips, COLOR_CHIP)
	_reputation_label = _make_chip(chips, COLOR_CHIP)
	_share_label = _make_chip(chips, COLOR_CHIP)

	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 10)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.clip_contents = true
	header.add_child(track)
	var track_bg := ColorRect.new()
	track_bg.color = COLOR_PANEL_EDGE
	track_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(track_bg)
	_share_fill = ColorRect.new()
	_share_fill.color = COLOR_ACCENT
	_share_fill.anchor_right = 0.0
	_share_fill.anchor_bottom = 1.0
	_share_fill.offset_right = 0.0
	_share_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_share_fill)
	return header


## Золотая монета с долларом, нарисованная из кругов.
func _make_coin() -> Control:
	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(70, 70)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_GOLD
	style.set_corner_radius_all(35)
	style.set_border_width_all(5)
	style.border_color = Color("e0a800")
	coin.add_theme_stylebox_override("panel", style)
	var sign := Label.new()
	sign.text = "$"
	sign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_display(sign, 40, Color("8a5a00"))
	coin.add_child(sign)
	return coin


## Цветной чип с текстом. Возвращает подпись, чтобы её обновлять.
func _make_chip(parent: Container, color: Color) -> Label:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(26)
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.35)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
	label.add_theme_color_override("font_color", _text_on(color))
	chip.add_child(label)
	return label


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

	_city = CityView.new()
	_city.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_city.tapped.connect(_on_city_tapped)
	taxi_holder.add_child(_city)
	var hint := _make_center_label("", 26, Color.WHITE)
	_tap_hint = hint
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_top = 8
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_constant_override("outline_size", 6)
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	taxi_holder.add_child(hint)

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
	_my_clean_bar = _make_bar(COLOR_SKY)
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
	back.bg_color = COLOR_PANEL_EDGE
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
	if _current_page == PAGE_MARKET:
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
		fill.bg_color = color if tired > 0.0 else COLOR_SHIFT
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
	# Листаем пальцем за любое место, с инерцией. Тонкая полоска прокрутки справа.
	var touch: Node = TouchScroll.new()
	page.add_child(touch)
	touch.setup(scroll, _is_modal_open)
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(COLOR_TITLE_OUTLINE, 0.45)
	grabber.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", grabber)
	bar.add_theme_stylebox_override("grabber_pressed", grabber)
	bar.add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	bar.custom_minimum_size = Vector2(8, 0)
	return page


## Открыто окно поверх экрана — списки под ним не листаем.
func _is_modal_open() -> bool:
	for layer: Variant in [_notice_layer, _sell_layer, _settings_layer, _offline_layer, _daily_layer, _name_layer]:
		var popup: Control = layer
		if popup != null and popup.visible:
			return true
	return false


const TABS := [["city", "Город"], ["car", "Машина"], ["team", "Команда"], ["map", "Карта"], ["market", "Рынок"]]
const TabIcon := preload("res://scripts/tab_icon.gd")
## Иконки вкладок, чтобы перекрашивать активную и ставить красную точку.
var _tab_icons: Array = []


func _build_tab_bar() -> Control:
	var dock := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DOCK
	style.set_corner_radius_all(40)
	style.border_width_bottom = 8
	style.border_color = COLOR_PANEL_EDGE
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	dock.add_theme_stylebox_override("panel", style)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	dock.add_child(bar)
	_tab_buttons = []
	_tab_icons = []
	for index in TABS.size():
		var button := _make_tab(TABS[index][0], TABS[index][1])
		button.pressed.connect(_show_page.bind(index))
		bar.add_child(button)
		_tab_buttons.append(button)
	return dock


func _make_tab(kind: String, title: String) -> Button:
	var button := Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 124)
	button.focus_mode = Control.FOCUS_NONE
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon: Control = TabIcon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(0, 62)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(icon)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	_tab_icons.append([icon, label])
	return button


## Красная точка на «Команде»: кто-то устал или машина сломана.
func _refresh_tab_badges() -> void:
	if _tab_icons.size() < 3:
		return
	var icon: Control = _tab_icons[PAGE_DRIVERS][0]
	icon.badge = GameState.get_tired_count() > 0 or GameState.get_broken_count() > 0


## Цвета на полоске долей: игрок жёлтый, конкуренты острова — по порядку.
const RIVAL_COLORS := [Color("a0aec8"), Color("ffb347"), Color("c39bff"), Color("5ee6c7")]


func _market_color(id: String) -> Color:
	if id == "player":
		return COLOR_TAXI
	var rivals: Array = GameState.get_competitors()
	for index in rivals.size():
		if str(rivals[index].get("id", "")) == id:
			return RIVAL_COLORS[index % RIVAL_COLORS.size()]
	return RIVAL_COLORS[0]


func _build_market_rows() -> void:
	_market_built_for = GameState.get_front_island()
	_competitor_rows.clear()
	_ladder_steps.clear()
	_ad_rows.clear()
	_market_status = null
	if _market_built_for == "":
		_market_list.add_child(_make_section_title("Рынок"))
		var calm := PanelContainer.new()
		calm.add_theme_stylebox_override("panel", _panel_style())
		_market_list.add_child(calm)
		var calm_box := VBoxContainer.new()
		calm_box.add_theme_constant_override("separation", 12)
		calm.add_child(calm_box)
		_add_label(calm_box, "Все открытые острова — ваши. Конкурентов нет, можно выдохнуть.", 30, COLOR_GOLD)
		_add_label(calm_box, "Откройте следующий остров на карте — там новые соперники и новый город.", 26, COLOR_MUTED)
		var to_map := _make_row_button(_go_to_map)
		to_map.text = "Открыть карту"
		to_map.custom_minimum_size = Vector2(0, 100)
		calm_box.add_child(to_map)
		_market_list.add_child(_make_sell_panel())
		return
	_market_list.add_child(_make_section_title("Битва за %s" % GameState.get_front_city()))

	# Лестница: соперники по очереди, от слабого к сильному.
	var ladder_panel := PanelContainer.new()
	ladder_panel.add_theme_stylebox_override("panel", _panel_style())
	_market_list.add_child(ladder_panel)
	var ladder_box := VBoxContainer.new()
	ladder_box.add_theme_constant_override("separation", 12)
	ladder_panel.add_child(ladder_box)
	_market_status = _add_label(ladder_box, "", 34, COLOR_GOLD)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 10)
	ladder_box.add_child(steps)
	for raw: Variant in GameState.get_competitors():
		var id: String = str(raw.get("id", ""))
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		steps.add_child(chip)
		var chip_label := Label.new()
		chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		chip_label.add_theme_font_size_override("font_size", 22)
		chip.add_child(chip_label)
		_ladder_steps[id] = chip_label
	_add_label(ladder_box, "Соперники идут по очереди. Догоните текущего по силе — он сдастся и предложит выкуп. Выкупите всех — город ваш.", 24, COLOR_MUTED)

	for raw: Variant in GameState.get_competitors():
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) != "":
			_market_list.add_child(_make_competitor_row(str(raw.get("id", "")), raw))

	_market_list.add_child(_make_section_title("Реклама — рывок на время"))
	for raw: Variant in GameState.get_ads():
		if typeof(raw) == TYPE_DICTIONARY:
			_market_list.add_child(_make_ad_row(raw))

	_market_list.add_child(_make_sell_panel())


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

	var title := _add_label(column, str(info.get("name", competitor_id)), 36)
	var mood := _add_label(column, str(info.get("personality_name", "")), 26, COLOR_GOLD)
	var description := _add_label(column, str(info.get("description", "")), 24, COLOR_MUTED)
	var status := _add_label(column, "", 30, COLOR_TEXT)

	# Канат: жёлтое — ваша сила, цвет соперника — сколько ещё не хватает.
	var bar := HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, 40)
	bar.add_theme_constant_override("separation", 0)
	column.add_child(bar)
	var mine := ColorRect.new()
	mine.color = COLOR_TAXI
	mine.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(mine)
	var theirs := ColorRect.new()
	theirs.color = _market_color(competitor_id)
	theirs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theirs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(theirs)
	var powers := _add_label(column, "", 26, COLOR_TEXT)
	var hint := _add_label(column, "", 24, COLOR_MUTED)
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
		_style_plain_button(button, COLOR_TRICK)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_trick.bind(competitor_id, trick_id))
		tricks.add_child(button)
		trick_buttons[trick_id] = button

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(0, 110)
	buy_button.focus_mode = Control.FOCUS_NONE
	_style_buy_button(buy_button)
	buy_button.pressed.connect(_on_buy_rival.bind(competitor_id))
	column.add_child(buy_button)

	_competitor_rows[competitor_id] = {
		"mood": mood,
		"description": description,
		"status": status,
		"bar": bar,
		"mine": mine,
		"theirs": theirs,
		"powers": powers,
		"hint": hint,
		"effects": effects,
		"tricks": trick_buttons,
		"tricks_box": tricks,
		"buy": buy_button,
		"title": title,
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
	if bool(result.get("caught", false)):
		_mentor.on_event("caught")


func _on_buy_rival(competitor_id: String) -> void:
	var result: Dictionary = GameState.buy_rival(competitor_id)
	if bool(result.get("ok", false)):
		_show_notice("Сделка", str(result.get("text", "")))


func _on_rival_surrendered(competitor_id: String, text: String) -> void:
	_show_notice("Сдаются!", text)
	_mentor.on_event("surrender")


func _on_rival_attacked(competitor_id: String, text: String) -> void:
	_enqueue_toast("Ход соперника", text)
	_mentor.on_event("rival_attack")


func _on_island_captured(island_id: String, text: String) -> void:
	_show_notice("%s ваш!" % str(GameState.get_island_info(island_id).get("city", "Город")), text)
	_selected_island = ""
	_refresh_regions()
	_mentor.on_event("captured")


func _go_to_map() -> void:
	_show_page(PAGE_CITY)
	_show_city_section(0)


## Сменился остров борьбы — собираем вкладку «Рынок» заново.
func _rebuild_market_if_needed() -> void:
	if _market_list == null or _market_built_for == GameState.get_front_island():
		return
	for child in _market_list.get_children():
		_market_list.remove_child(child)
		child.queue_free()
	_build_market_rows()
	_refresh_sell()


func _mmss(seconds: int) -> String:
	return "%d:%02d" % [int(seconds / 60), seconds % 60]


func _refresh_competitors() -> void:
	_rebuild_market_if_needed()
	if _market_status == null:
		return
	var rivals: Array = GameState.get_competitors()
	_market_status.text = "Выкуплено %d из %d" % [GameState.get_city_owned_count(), rivals.size()]
	for raw: Variant in rivals:
		var id: String = str(raw.get("id", ""))
		var chip_label: Label = _ladder_steps.get(id)
		if chip_label == null:
			continue
		var short_name: String = str(raw.get("name", id)).replace("Таксопарк ", "")
		var state: String = GameState.get_rival_state(id)
		var state_text: String = {"owned": "ваш", "surrendered": "сдался", "active": "дуэль", "waiting": "ждёт"}.get(state, "")
		chip_label.text = "%s\n%s" % [short_name, state_text]
		var chip: PanelContainer = chip_label.get_parent()
		var color: Color = {"owned": COLOR_BUY, "surrendered": COLOR_ACCENT, "active": COLOR_TRICK, "waiting": COLOR_DISABLED}.get(state, COLOR_DISABLED)
		var chip_style := StyleBoxFlat.new()
		chip_style.bg_color = color
		chip_style.set_corner_radius_all(18)
		chip_style.content_margin_top = 8
		chip_style.content_margin_bottom = 8
		chip_style.content_margin_left = 6
		chip_style.content_margin_right = 6
		chip.add_theme_stylebox_override("panel", chip_style)
		chip_label.add_theme_color_override("font_color", _text_on(color))

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

	for raw: Variant in rivals:
		var id: String = str(raw.get("id", ""))
		if _competitor_rows.has(id):
			_refresh_rival_row(id, raw)


func _refresh_rival_row(id: String, info: Dictionary) -> void:
	var row: Dictionary = _competitor_rows[id]
	var status: Label = row["status"]
	var bar: HBoxContainer = row["bar"]
	var powers: Label = row["powers"]
	var hint: Label = row["hint"]
	var effects: Label = row["effects"]
	var tricks_box: HBoxContainer = row["tricks_box"]
	var buy: Button = row["buy"]
	var state: String = GameState.get_rival_state(id)
	var full: bool = state == "active"
	# Подробности — только у текущего соперника, остальные карточки короткие.
	for key: String in ["mood", "description", "powers", "hint", "effects"]:
		var label: Label = row[key]
		label.visible = full
	bar.visible = full
	tricks_box.visible = full
	buy.visible = state == "surrendered"
	var short_name: String = str(info.get("name", id)).replace("Таксопарк ", "")
	match state:
		"owned":
			status.text = "Компания ваша  ·  доход +%d%%" % int(roundf(float(info.get("income_bonus", 0)) * 100.0))
			status.add_theme_color_override("font_color", COLOR_INCOME)
			return
		"surrendered":
			status.text = "Сдался и ждёт выкупа. Купите — и доход +%d%%." % int(roundf(float(info.get("income_bonus", 0)) * 100.0))
			status.add_theme_color_override("font_color", COLOR_GOLD)
			buy.text = "Выкупить за %s" % GameState.format_money(GameState.get_competitor_cost(id))
			buy.disabled = not GameState.can_buy_rival(id)
			return
		"waiting":
			status.text = "Следующий соперник. Сейчас возит на %s/с — и тоже растёт, когда до него дойдёт очередь." % GameState.format_money(GameState.get_competitor_power(id))
			status.add_theme_color_override("font_color", COLOR_MUTED)
			return
	var mine: float = GameState.get_player_power()
	var theirs: float = GameState.get_competitor_power(id)
	var progress: float = GameState.get_duel_progress()
	status.add_theme_color_override("font_color", COLOR_TEXT)
	if theirs <= 0.0 or mine >= theirs:
		status.text = "Вы догнали! Сейчас сдадутся."
	elif theirs / maxf(mine, 0.001) >= 1.5:
		status.text = "Дуэль: нужно стать сильнее в %s" % _ratio_text(theirs / maxf(mine, 0.001))
	else:
		status.text = "Дуэль: осталось +%d%% силы" % maxi(1, int(ceilf((theirs / maxf(mine, 0.001) - 1.0) * 100.0)))
	var mine_part: ColorRect = row["mine"]
	var theirs_part: ColorRect = row["theirs"]
	mine_part.size_flags_stretch_ratio = maxf(progress, 0.01)
	theirs_part.size_flags_stretch_ratio = maxf(1.0 - progress, 0.0)
	theirs_part.visible = progress < 1.0
	powers.text = "Вы %s/с  —  %s %s/с" % [GameState.format_money(mine), short_name, GameState.format_money(theirs)]
	var tips: PackedStringArray = PackedStringArray()
	tips.append("Сила — это доход в секунду плюс заказы с тапов.")
	if GameState.get_active_ad().is_empty():
		tips.append("Реклама даёт рывок на несколько минут — обгоните на нём, и победа засчитается.")
	tips.append("Пакости ослабляют соперника, но могут поймать.")
	hint.text = " ".join(tips)
	var notes: PackedStringArray = PackedStringArray()
	var growth: float = GameState.get_rival_growth(id)
	if growth > 1.001:
		notes.append("вырос за дуэль на +%d%% (максимум +%d%%)" % [
			int(roundf((growth - 1.0) * 100.0)), int(roundf((GameState.get_rival_growth_cap() - 1.0) * 100.0))])
	for cut: Variant in GameState.get_competitor_cuts(id):
		var value: float = float(cut["cut"])
		if value >= 0.0:
			notes.append("−%d%% от пакости ещё %s" % [int(roundf(value * 100.0)), _mmss(int(cut["left"]))])
		else:
			notes.append("их акция +%d%% ещё %s" % [int(roundf(-value * 100.0)), _mmss(int(cut["left"]))])
	var lost: float = GameState.get_competitor_lost_drivers(id)
	if lost > 0.0:
		notes.append("переманено водителей: −%d%% навсегда" % int(roundf(lost * 100.0)))
	var attack_left: int = GameState.get_rival_attack_left()
	if attack_left > 0:
		notes.append("их ход через %s: %s" % [_mmss(attack_left), _attack_text(GameState.get_rival_attack_kind(id))])
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


func _rival_name(competitor_id: String) -> String:
	for raw: Variant in GameState.get_competitors():
		if str(raw.get("id", "")) == competitor_id:
			return str(raw.get("name", competitor_id))
	return competitor_id


func _attack_text(kind: String) -> String:
	match kind:
		"health":
			return "побьют машины"
		"rating":
			return "испортят отзывы"
		"promo":
			return "устроят акцию"
	return "что-то задумали"


## «9 раз», «2,4 раза», «23 раза»: во сколько раз соперник сильнее.
func _ratio_text(ratio: float) -> String:
	if ratio < 10.0 and not is_equal_approx(snappedf(ratio, 0.1), roundf(ratio)):
		return "%s раза" % ("%.1f" % ratio).replace(".", ",")
	var whole: int = int(roundf(ratio)) if ratio < 10.0 else int(ceilf(ratio))
	var last: int = whole % 10
	var tens: int = whole % 100
	var word: String = "раза" if last >= 2 and last <= 4 and (tens < 12 or tens > 14) else "раз"
	return "%d %s" % [whole, word]


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
	box.add_child(_make_center_label("Продать компанию?", 44, COLOR_TEXT))
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

	_notice_title = _display(_make_center_label("", 44, Color.WHITE), 46, COLOR_GOLD)
	box.add_child(_notice_title)
	_notice_body = _make_center_label("", 30, COLOR_MUTED)
	_notice_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_notice_body)
	var close_button := _make_settings_button("Понятно", COLOR_BUY, _close_notice)
	box.add_child(close_button)


## Окна не перекрывают друг друга: пока открыто одно, следующие ждут очереди
## (например, сразу два сдавшихся соперника).
func _show_notice(title: String, body: String) -> void:
	if _notice_layer.visible:
		_notice_queue.append([title, body])
		return
	_notice_title.text = title
	_notice_body.text = body
	_notice_layer.visible = true


func _close_notice() -> void:
	_notice_layer.visible = false
	if not _notice_queue.is_empty():
		var next: Array = _notice_queue.pop_front()
		_show_notice(str(next[0]), str(next[1]))


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
	var more_page := _build_scroll_page()
	_city_sections = [world_page, district_page, achievement_page, more_page]
	for section: Control in _city_sections:
		section.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.add_child(section)
	_district_list = district_page.get_child(0).get_child(0) as VBoxContainer
	_world_list = world_page.get_child(0).get_child(0) as VBoxContainer
	_achievement_list = achievement_page.get_child(0).get_child(0) as VBoxContainer
	_more_list = more_page.get_child(0).get_child(0) as VBoxContainer
	_build_more_rows()
	_show_city_section(0)
	return page


func _build_city_switch() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	_city_section_buttons = [
		_make_section_button("Мир"),
		_make_section_button("Районы"),
		_make_section_button("Награды"),
		_make_section_button("Ещё"),
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
		_style_plain_button(button, COLOR_ACCENT if active else COLOR_PANEL)


var _more_list: VBoxContainer
var _more_stats: Label


## «Ещё»: сводка компании, звук, сброс. Сюда переехали настройки из шестерёнки.
func _build_more_rows() -> void:
	_more_list.add_child(_make_section_title("Компания"))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	_more_list.add_child(panel)
	_more_stats = _add_label(panel, "", 28, COLOR_TEXT)
	_more_list.add_child(_make_section_title("Настройки"))
	_music_button = _make_settings_button("", COLOR_SKY, _toggle_music)
	_more_list.add_child(_music_button)
	_sound_button = _make_settings_button("", COLOR_SKY, _toggle_sound)
	_more_list.add_child(_sound_button)
	_refresh_sound_button()
	_mentor_tips_button = _make_settings_button("", COLOR_ACCENT, _toggle_mentor_tips)
	_more_list.add_child(_mentor_tips_button)
	_more_list.add_child(_make_settings_button("Пройти обучение заново", COLOR_PANEL, _restart_tutorial))
	_more_list.add_child(_make_settings_button("Сбросить прогресс", COLOR_DANGER, _ask_reset))
	_on_background(_add_label(_more_list, "Сброс стирает весь прогресс и название компании. Это для проверки игры.", 24))


func _refresh_more() -> void:
	if _more_stats == null:
		return
	if _mentor != null:
		_refresh_mentor_buttons()
	_more_stats.text = "Такси «%s»\nРейтинг: ★ %.1f\nРепутация: %d\nФраншиза: ×%s\nЗаработано за всё время: %s\nОстровов: %d из %d" % [
		GameState.company_name,
		GameState.get_rating(),
		GameState.reputation,
		GameState.format_number(GameState.get_franchise()),
		GameState.format_money(GameState.lifetime_earned),
		GameState.get_captured_count(),
		GameState.get_regions().size(),
	]


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
	_world_list.add_child(_make_section_title("Карта мира"))
	_world_progress = _on_background(_add_label(_world_list, "", 26))

	_island_map = IslandMap.new()
	_island_map.custom_minimum_size = Vector2(0, 860)
	_island_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_island_map.island_pressed.connect(_on_island_pressed)
	_world_list.add_child(_island_map)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style())
	_world_list.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	_island_title = _add_label(box, "", 38)
	_island_description = _add_label(box, "", 26, COLOR_MUTED)
	_island_status = _add_label(box, "", 28, COLOR_GOLD)
	_island_reason = _add_label(box, "", 26, COLOR_DANGER)
	_island_button = _make_row_button(_on_island_button)
	_island_button.custom_minimum_size = Vector2(0, 110)
	box.add_child(_island_button)
	_on_background(_add_label(_world_list, "Репутация растёт от заказов: +1 за каждые 20 тапов и за каждого водителя. Открытый остров — свой гараж на 20 машин. Захваченный — +25% дохода навсегда.", 24))


## Состояние острова для карты.
func _island_state(island_id: String) -> String:
	if GameState.is_island_captured(island_id):
		return "captured"
	if GameState.is_region_open(island_id):
		return "front" if GameState.get_front_island() == island_id else "available"
	if GameState.can_open_region(island_id) or GameState.get_region_block_reason(island_id).find("Сначала") < 0:
		return "available"
	return "locked"


func _on_island_pressed(island_id: String) -> void:
	_selected_island = island_id
	_refresh_regions()


func _on_island_button() -> void:
	var id: String = _selected_island
	if GameState.is_region_open(id):
		if not GameState.is_island_captured(id):
			_show_page(PAGE_MARKET)
		return
	GameState.open_region(id)


func _default_island() -> String:
	var front: String = GameState.get_front_island()
	if front != "":
		return front
	for raw: Variant in GameState.get_regions():
		if not GameState.is_region_open(str(raw.get("id", ""))):
			return str(raw.get("id", ""))
	var regions: Array = GameState.get_regions()
	return "" if regions.is_empty() else str(regions[regions.size() - 1].get("id", ""))


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
	if _island_map == null:
		return
	if _selected_island == "":
		_selected_island = _default_island()
	var states: Dictionary = {}
	for raw: Variant in GameState.get_regions():
		var id: String = str(raw.get("id", ""))
		states[id] = _island_state(id)
	_island_map.set_data(GameState.get_regions(), states, _selected_island)
	_world_progress.text = "Ваши острова: %d из %d. Нажмите на остров, чтобы узнать о нём." % [
		GameState.get_captured_count(),
		GameState.get_regions().size(),
	]

	var info: Dictionary = GameState.get_island_info(_selected_island)
	var id: String = _selected_island
	_island_title.text = "%s · %s" % [str(info.get("name", "")), str(info.get("city", ""))]
	_island_description.text = str(info.get("description", ""))
	var rivals: PackedStringArray = PackedStringArray()
	for raw: Variant in GameState.get_island_competitors(id):
		rivals.append(str(raw.get("name", "")))
	var bonus: int = int(roundf(float(info.get("income_bonus", 0)) * 100.0))
	var bonus_text: String = ""
	if not GameState.is_region_open(id):
		bonus_text = "\nПосле открытия: свой гараж на %d машин, доход +%d%%" % [int(info.get("garage_slots", 0)), bonus]
	_island_reason.text = ""
	_island_button.visible = true
	match str(states.get(id, "locked")):
		"captured":
			_island_status.text = "Ваш остров ★ Все конкуренты позади."
			_island_button.visible = false
		"front":
			var rival_id: String = GameState.get_active_rival()
			var duel_text: String = "Все сдались — осталось выкупить."
			if rival_id != "":
				var progress: float = GameState.get_duel_progress()
				if progress < 0.5:
					duel_text = "Сейчас дуэль: %s, нужно стать сильнее в %s." % [
						_rival_name(rival_id), _ratio_text(1.0 / maxf(progress, 0.0001))]
				else:
					duel_text = "Сейчас дуэль: %s, вы на %d%% его силы." % [_rival_name(rival_id), int(floorf(progress * 100.0))]
			_island_status.text = "Идёт борьба за %s. Выкуплено %d из %d. %s" % [
				str(info.get("city", "")), GameState.get_city_owned_count(), GameState.get_competitors().size(), duel_text]
			_island_button.text = "К рынку"
			_island_button.disabled = false
		_:
			_island_status.text = "Соперники: %s%s" % [", ".join(rivals), bonus_text]
			_island_button.text = "Открыть остров\n%s" % GameState.format_money(GameState.get_region_cost(id))
			_island_button.disabled = not GameState.can_open_region(id)
			_island_reason.text = GameState.get_region_block_reason(id)


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
	_display(label, 44, COLOR_TITLE)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
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
	row.add_child(_make_car_icon(car_id))

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
	_refresh_cars()
	_sync_city()
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
	_refresh_more()


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
	box.add_child(_display(_make_center_label("Ваше такси", 52, COLOR_TEXT), 56, COLOR_TEXT))
	var hint := _make_center_label("Бангкок ждёт. Как будет называться ваша компания? Конкуренты должны знать, кого бояться.", 28, COLOR_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Например: Жёлтая молния"
	_name_edit.max_length = GameState.COMPANY_NAME_MAX
	_name_edit.custom_minimum_size = Vector2(0, 100)
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.add_theme_font_size_override("font_size", 36)
	var field := StyleBoxFlat.new()
	field.bg_color = Color.WHITE
	field.set_corner_radius_all(22)
	field.set_border_width_all(4)
	field.border_color = COLOR_PANEL_EDGE
	field.content_margin_left = 20
	field.content_margin_right = 20
	var focused: StyleBoxFlat = field.duplicate()
	focused.border_color = COLOR_ACCENT
	_name_edit.add_theme_stylebox_override("normal", field)
	_name_edit.add_theme_stylebox_override("focus", focused)
	_name_edit.add_theme_color_override("font_color", COLOR_TEXT)
	_name_edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)
	_name_edit.add_theme_color_override("caret_color", COLOR_TEXT)
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
	_mentor.begin()


func _build_driver_rows() -> void:
	var hint := Label.new()
	hint.text = "Водитель + свободная машина из гаража = доход, даже когда вы не тапаете. Зарплата вычитается сама. Лучшим водителям диспетчер сам даёт лучшие машины."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	_on_background(hint)
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


func _add_label(box: Container, text: String, font_size: int, color: Color = COLOR_TEXT) -> Label:
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


func _make_car_icon(car_id: String) -> Control:
	var icon: Control = CarIcon.new()
	icon.model = car_id
	icon.custom_minimum_size = Vector2(150, 90)
	return icon


func _make_fleet_row(car_id: String, info: Dictionary) -> PanelContainer:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	row.add_child(_make_car_icon(car_id))
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
		var shift_bar := _make_bar(COLOR_SHIFT)
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
	if GameState.get_island_garage_slots() > 0:
		_garage_label.text += "\nдома %d + на островах %d" % [GameState.get_home_garage_capacity(), GameState.get_island_garage_slots()]
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


## Плашка: светлее фона, с тёмной кромкой снизу — как объёмная карточка.
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(30)
	style.border_width_bottom = 8
	style.border_color = COLOR_PANEL_EDGE
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 22
	return style


## Кнопка покупки: лаймовая, когда хватает денег; тёмный текст на ярком.
func _style_buy_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _button_style(COLOR_BUY))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_BUY_HOVER))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_BUY_PRESSED, true))
	button.add_theme_stylebox_override("disabled", _button_style(COLOR_DISABLED, true))
	button.add_theme_stylebox_override("focus", _button_style(COLOR_BUY))
	button.add_theme_font_size_override("font_size", 28)
	_set_button_text(button, COLOR_BUY)


## Подпись прямо на фоне, не на карточке: цвет и обводка как у заголовков.
func _on_background(label: Label) -> Label:
	label.add_theme_color_override("font_color", COLOR_TITLE)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", COLOR_TITLE_OUTLINE)
	return label


## Тёмный текст на светлой кнопке, белый — на тёмной.
func _text_on(fill: Color) -> Color:
	return COLOR_INK if fill.get_luminance() > 0.55 else Color.WHITE


func _set_button_text(button: Button, fill: Color) -> void:
	var text: Color = _text_on(fill)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text)
	button.add_theme_color_override("font_disabled_color", Color(_text_on(COLOR_DISABLED), 0.55))


## Объёмная кнопка: кромка снизу темнее. Нажатая — кромка тоньше, кнопка «проседает».
func _button_style(color: Color, flat: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(26)
	style.border_width_bottom = 2 if flat else 8
	style.border_color = color.darkened(0.35)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12 if not flat else 16
	style.content_margin_bottom = 12
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
			label.add_theme_color_override("font_color", COLOR_TEXT)


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
	# Под шапкой: не закрывает деньги и не спорит с облачком дяди Буна внизу. Золотая, как награда.
	_toast_layer.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_layer.offset_left = -400
	_toast_layer.offset_right = 400
	_toast_layer.offset_top = 400
	_toast_layer.offset_bottom = 540
	_toast_layer.visible = false
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _panel_style()
	style.bg_color = COLOR_MONEY
	style.border_color = COLOR_MONEY.darkened(0.3)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_toast_layer.add_theme_stylebox_override("panel", style)
	add_child(_toast_layer)

	_toast_label = _make_center_label("", 30, COLOR_INK)
	_display(_toast_label, 32, COLOR_INK)
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
	box.add_child(_display(_make_center_label("Ежедневная награда", 44, Color.WHITE), 46, COLOR_GOLD))
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
	_mentor.on_event("welcome_back")


## Над такси всплывает «+N» и тает.
func _spawn_floating_gain(amount: float, at_global: Vector2) -> void:
	var label := Label.new()
	label.text = "+%s" % GameState.format_money(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.custom_minimum_size = Vector2(320, 80)
	_float_layer.add_child(label)

	var local: Vector2 = _float_layer.get_global_transform().affine_inverse() * at_global
	label.position = Vector2(local.x - 160.0 + randf_range(-30.0, 30.0), local.y - 110.0)

	var float_tween := create_tween()
	float_tween.set_parallel(true)
	float_tween.tween_property(label, "position:y", label.position.y - 160.0, 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(label, "modulate:a", 0.0, 0.7)
	float_tween.chain().tween_callback(label.queue_free)


func _on_city_tapped(at: Vector2) -> void:
	var gained: float = GameState.tap()
	_city.bounce()
	_spawn_floating_gain(gained, _city.get_global_transform() * at)
	_play(_sfx_tap, randf_range(0.92, 1.12))
	# Лёгкий отклик в руке. Вместе со звуком выключается в «Ещё».
	if _sound_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(12)


## Кто ездит по городу: ваша машина, машины водителей, конкуренты по их доле рынка.
func _sync_city() -> void:
	if _city == null:
		return
	var fleet: Array = []
	var cars: Dictionary = GameState.get_assignments()
	for person: Variant in GameState.get_team():
		var car: Dictionary = cars.get(int(person.get("uid", 0)), {})
		if car.is_empty():
			continue
		fleet.append({
			"model": str(car.get("model", "old_sedan")),
			"dirt": 1.0 - float(car.get("clean", 1)),
			"broken": GameState.is_broken(float(car.get("health", 1))),
		})
	var rivals: Array = []
	for raw: Variant in GameState.get_competitors():
		var id: String = str(raw.get("id", ""))
		var share: float = GameState.get_competitor_share(id)
		if share <= 0.0:
			continue
		for index in clampi(int(roundf(share * 8.0)), 1, 5):
			rivals.append(_market_color(id))
	_city.set_state(GameState.get_car_id(), 1.0 - GameState.get_my_clean(),
		GameState.is_broken(GameState.get_my_health()), fleet, rivals)


# --- Звук ---------------------------------------------------------------------

## Звуки синтезируем сами: короткий «дзынь» тапа и двойной «чинг» покупки. Файлов не нужно.
func _build_sounds() -> void:
	_sfx_tap = AudioStreamPlayer.new()
	_sfx_tap.stream = _make_tone([[780.0, 1180.0, 0.07]], 0.35)
	_sfx_tap.max_polyphony = 6
	add_child(_sfx_tap)
	_sfx_buy = AudioStreamPlayer.new()
	_sfx_buy.stream = _make_tone([[988.0, 988.0, 0.08], [1318.0, 1318.0, 0.16]], 0.3)
	_sfx_buy.max_polyphony = 3
	add_child(_sfx_buy)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_sound_on = bool(config.get_value("audio", "sound", true))
		_music_on = bool(config.get_value("audio", "music", true))
	# Фоновая мелодия «Бангкокский бриз» (tools/make_music.py), тихо и по кругу.
	_music = AudioStreamPlayer.new()
	var track: AudioStreamOggVorbis = load("res://assets/music/bangkok_breeze.ogg")
	if track != null:
		track.loop = true
		_music.stream = track
	_music.volume_db = -9.0
	add_child(_music)
	if _music_on:
		_music.play()


## notes — [начальная частота, конечная, длительность]; громкость спадает к концу каждой ноты.
func _make_tone(notes: Array, volume: float) -> AudioStreamWAV:
	var rate: int = 22050
	var data := PackedByteArray()
	for note: Variant in notes:
		var samples: int = int(rate * float(note[2]))
		var phase: float = 0.0
		for index in samples:
			var progress: float = float(index) / float(samples)
			var freq: float = lerpf(float(note[0]), float(note[1]), progress)
			phase += TAU * freq / float(rate)
			var envelope: float = minf(1.0, progress * 30.0) * pow(1.0 - progress, 2.0)
			var value: float = (sin(phase) + 0.3 * sin(phase * 2.0)) * envelope * volume
			var sample: int = clampi(int(value * 32767.0), -32768, 32767)
			data.append(sample & 0xFF)
			data.append((sample >> 8) & 0xFF)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream


func _play(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player == null or not _sound_on:
		return
	player.pitch_scale = pitch
	player.play()


func _toggle_sound() -> void:
	_sound_on = not _sound_on
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "sound", _sound_on)
	config.save(SETTINGS_PATH)
	_refresh_sound_button()
	_play(_sfx_buy)


func _toggle_music() -> void:
	_music_on = not _music_on
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("audio", "music", _music_on)
	config.save(SETTINGS_PATH)
	if _music_on:
		_music.play()
	else:
		_music.stop()
	_refresh_sound_button()


func _refresh_sound_button() -> void:
	if _music_button != null:
		_music_button.text = "Музыка: включена" if _music_on else "Музыка: выключена"
	if _sound_button != null:
		_sound_button.text = "Звук и вибрация: включены" if _sound_on else "Звук и вибрация: выключены"


func _show_page(page: int) -> void:
	_current_page = page
	if _mentor != null:
		_mentor.notify_page(page)
	if _coins_label != null:
		_refresh_page(page)
	_tap_page.visible = page == PAGE_TAP
	_upgrades_page.visible = page == PAGE_UPGRADES
	_drivers_page.visible = page == PAGE_DRIVERS
	_city_page.visible = page == PAGE_CITY
	_market_page.visible = page == PAGE_MARKET
	for index in _tab_buttons.size():
		var button: Button = _tab_buttons[index]
		var active: bool = index == page
		var tab_style := StyleBoxFlat.new()
		tab_style.set_corner_radius_all(32)
		tab_style.bg_color = COLOR_ACCENT if active else Color(0, 0, 0, 0)
		if active:
			tab_style.border_width_bottom = 6
			tab_style.border_color = COLOR_ACCENT.darkened(0.35)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, tab_style)
		var parts: Array = _tab_icons[index]
		var icon: Control = parts[0]
		var label: Label = parts[1]
		var tint: Color = _text_on(COLOR_ACCENT) if active else COLOR_MUTED
		icon.color = tint
		label.add_theme_color_override("font_color", tint)


func _style_plain_button(button: Button, color: Color) -> void:
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.08), true))
	button.add_theme_stylebox_override("focus", _button_style(color))
	button.add_theme_stylebox_override("disabled", _button_style(COLOR_DISABLED, true))
	_set_button_text(button, color)


func _open_settings() -> void:
	_settings_menu.visible = true
	_settings_confirm.visible = false
	_settings_layer.visible = true


func _close_settings() -> void:
	_settings_layer.visible = false


func _ask_reset() -> void:
	_settings_menu.visible = false
	_settings_confirm.visible = true
	_settings_layer.visible = true


func _confirm_reset() -> void:
	GameState.reset_progress()
	_mentor.setup(GameState)
	_mentor_bubble.visible = false
	_mentor_task_text = ""
	_refresh_mentor_task()
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
	stack.custom_minimum_size = Vector2(800, 560)
	panel.add_child(stack)

	_settings_menu = VBoxContainer.new()
	_settings_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_menu.add_theme_constant_override("separation", 24)
	_settings_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(_settings_menu)
	_settings_menu.add_child(_make_center_label("Настройки", 52, COLOR_TEXT))
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
	var question := _display(_make_center_label("Точно стереть весь прогресс?", 44, COLOR_TEXT), 44, COLOR_TEXT)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_confirm.add_child(question)
	_settings_confirm.add_child(_make_settings_button("Сбросить", COLOR_DANGER, _confirm_reset))
	_settings_confirm.add_child(_make_settings_button("Отмена", COLOR_PANEL, _close_settings))


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
	button.pressed.connect(callback)
	return button


func _on_buy_upgrade(upgrade_id: String) -> void:
	GameState.buy_upgrade(upgrade_id)


func _on_coins_changed(value: float) -> void:
	if _last_coins >= 0.0 and value < _last_coins - 0.5:
		_play(_sfx_buy)
	_last_coins = value
	var text := GameState.format_money(value)
	# Пока на экране та же строка, подпись не трогаем — иначе цифры двоятся.
	if _coins_label.text == text:
		return
	_coins_label.text = text
	# Доход капает каждый кадр. Перестраивать все меню так часто — тормоза на телефоне,
	# поэтому открытую вкладку обновляем 4 раза в секунду, остальные — когда их откроют.
	_ui_dirty = true


func _flush_ui() -> void:
	if not _ui_dirty:
		return
	_ui_dirty = false
	_refresh_page(_current_page)


func _refresh_page(page: int) -> void:
	match page:
		PAGE_TAP:
			_on_wear_changed()
		PAGE_UPGRADES:
			_refresh_upgrades()
			_refresh_cars()
		PAGE_DRIVERS:
			_refresh_staff_money()
			_on_wear_changed()
			_refresh_helpers()
		PAGE_CITY:
			_refresh_districts()
			_refresh_regions()
			_refresh_achievements()
			_refresh_more()
		PAGE_MARKET:
			_refresh_competitors()
			_refresh_sell()


func _on_tap_power_changed(_value: float) -> void:
	_refresh_rate_line()


func _on_income_changed(_value: float) -> void:
	_refresh_rate_line()


func _refresh_rate_line() -> void:
	_tap_label.text = "+%s/с" % GameState.format_money(GameState.get_income_per_second())
	if _tap_hint != null:
		_tap_hint.text = "Тап по городу — заказ на %s" % GameState.format_money(GameState.get_tap_power())
	_refresh_market_share()


## Чип в шапке: город борьбы, сколько конкурентов выкуплено, полоска — текущая дуэль.
func _refresh_market_share() -> void:
	if GameState.get_front_island() == "":
		_share_label.text = "Острова %d/%d" % [GameState.get_captured_count(), GameState.get_regions().size()]
		_share_fill.anchor_right = 1.0
		return
	_share_label.text = "%s %d/%d" % [GameState.get_front_city(), GameState.get_city_owned_count(), GameState.get_competitors().size()]
	_share_fill.anchor_right = GameState.get_duel_progress()


func _refresh_meta_line() -> void:
	_reputation_label.text = "★ %.1f" % GameState.get_rating()
	_refresh_tab_badges()
	_refresh_more()


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
