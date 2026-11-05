extends Control
## Главный экран. Весь интерфейс собирается в коде, сцена остаётся пустой.
## Экран не хранит экономику: он просит GameState и рисует то, что пришло в сигналах.

# >>> PALETTE
## Палитра «warm». Меняется целиком: все цвета экрана берутся отсюда.
const COLOR_BG_TOP := Color("6ccaf7")
const COLOR_BG_BOTTOM := Color("3a8fdc")
const COLOR_BG := Color("3a8fdc")
const COLOR_TEXT := Color("2a2a48")
const COLOR_MUTED := Color("52607c")
const COLOR_INK := Color("2a2a48")
const COLOR_PANEL := Color("fffaf0")
const COLOR_PANEL_EDGE := Color("e6dcc8")
const COLOR_ACCENT := Color("ffc93c")
const COLOR_GOLD := Color("2b6cb0")
const COLOR_MONEY := Color("1f9d55")
const COLOR_PILL := Color("2a2a48")
const COLOR_CHIP := Color("fffaf0")
const COLOR_DOCK := Color("fffaf0")
const COLOR_BUY := Color("2fbf5f")
const COLOR_BUY_HOVER := Color("47c672")
const COLOR_BUY_PRESSED := Color("2aab55")
const COLOR_DISABLED := Color("e6e2da")
const COLOR_INCOME := Color("1b8f43")
const COLOR_DANGER := Color("e8434f")
const COLOR_TRICK := Color("2f4a7a")
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
## Чип репутации в шапке.
var _rep_label: Label
var _share_label: Label
const CityView := preload("res://scripts/city_view.gd")
const CarIcon := preload("res://scripts/car_icon.gd")
var _city: Control
const TouchScroll := preload("res://scripts/touch_scroll.gd")
## Какая вкладка открыта и нужно ли обновить её списки (деньги поменялись).
var _current_page: int = 0
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
## Список машин в гараже по моделям, с кнопкой «Продать».
var _garage_box: VBoxContainer
## uid водителя -> его строка в «Команде» (живёт, пока водитель в команде).
var _team_rows: Dictionary = {}
var _team_empty: Label
## Что было в списке кандидатов: если не изменилось — не пересобираем.
var _candidate_signature: String = ""
var _garage_signature: String = ""
var _staff_stale: bool = false
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
## Рисованный город с тремя таксопарками на вкладке «Рынок».
var _battle_city: Control
## id рекламы -> {"status", "button"}.
var _ad_rows: Dictionary = {}
## Для какого острова собрана вкладка «Рынок». Фронт сменился — пересобираем.
var _market_built_for: String = "-"
const IslandMap := preload("res://scripts/island_map.gd")
const BossPortrait := preload("res://scripts/boss_portrait.gd")
const DuelRope := preload("res://scripts/duel_rope.gd")
const BattleCity := preload("res://scripts/battle_city.gd")
const ItemIcon := preload("res://scripts/item_icon.gd")
const SkyBackground := preload("res://scripts/sky_background.gd")
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
## Окно-заглушка рекламного ролика.
const VIDEO_STUB_SECONDS := 5.0
var _video_layer: Control
var _video_label: Label
var _video_button: Button
var _video_left: float = 0.0
var _video_reward: Callable = Callable()
## Сцены с боссами конкурентов.
const ATTACK_TOAST_SECONDS := 8.0
var _story_layer: Control
var _story_face: Control
var _story_name: Label
var _story_title: Label
var _story_you: Label
var _story_text: Label
var _story_buttons: VBoxContainer
var _story_queue: Array = []
var _notice_title: Label
var _notice_body: Label
var _sell_info: Label
var _sell_button: Button
var _sell_layer: Control
var _sell_body: Label
var _achievement_labels: Dictionary = {}
var _quest_total_label: Label
var _quest_total_bar: ProgressBar
## Плитки сводки команды: id -> [значение, подпись].
var _team_tiles: Dictionary = {}
var _toast_layer: PanelContainer
var _toast_label: Label
var _toast_queue: Array = []
var _toast_face: Control
## Линия тапа под шапкой.
var _tap_line: Button
var _tap_line_fill: Panel
var _tap_line_label: Label
var _tap_line_text: String = ""
## Карточка «Что дальше» на главном экране: текст цели и вкладка, куда она ведёт (-1 — тут же).
var _goal_panel: PanelContainer
var _goal_label: Label
var _goal_arrow: Label
var _goal_page: int = -1
var _toast_timer: Timer
var _daily_layer: Control
var _offline_layer: Control
var _offline_label: Label
var _offline_time_label: Label
var _company_label: Label
## id машины -> {"status", "rent", "buy"}.
var _name_layer: Control
var _name_edit: LineEdit
var _name_error: Label


func _ready() -> void:
	# Без ограничения: кадры идут с частотой экрана (60, 90, 120 Гц).
	Engine.max_fps = 0
	_apply_theme()
	_build_sounds()
	_build_ui()
	if _toast_layer != null:
		move_child(_toast_layer, get_child_count() - 1)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.tap_power_changed.connect(func(_value: float) -> void: _mark("rate"))
	GameState.upgrades_changed.connect(_on_upgrades_changed)
	GameState.drivers_changed.connect(func() -> void: _mark("staff"); _mark("city"))
	GameState.income_changed.connect(func(_value: float) -> void: _mark("rate"))
	GameState.districts_changed.connect(_on_districts_changed)
	GameState.regions_changed.connect(_on_regions_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.competitors_changed.connect(func() -> void: _mark("competitors"); _mark("city"))
	GameState.island_captured.connect(_on_island_captured)
	GameState.rival_surrendered.connect(_on_rival_surrendered)
	GameState.rival_attacked.connect(_on_rival_attacked)
	GameState.rival_story.connect(_on_rival_story)
	GameState.franchise_changed.connect(_on_franchise_changed)
	GameState.achievement_unlocked.connect(_on_achievement_unlocked)
	GameState.achievements_changed.connect(_refresh_achievements)
	GameState.offline_reward_ready.connect(_show_offline_popup)
	GameState.car_changed.connect(_on_car_changed)
	GameState.garage_changed.connect(func() -> void: _mark("staff"); _mark("city"))
	GameState.wear_changed.connect(func() -> void: _mark("wear"); _mark("city"))
	GameState.shifts_changed.connect(func() -> void: _mark("shifts"); _mark("city"))
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
	_col(label, color)
	return label


func _build_ui() -> void:
	# Фон: небо, облака и силуэты города (рисуется один раз в картинку).
	var background: Control = SkyBackground.new()
	background.top_color = COLOR_BG_TOP
	background.bottom_color = COLOR_BG_BOTTOM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_build_video_popup()
	_build_story_popup()
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
	_col(_mentor_text, COLOR_TEXT)
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
	_col(_mentor_task_label, Color.WHITE)
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
	_set_toggle(_mentor_tips_button, _mentor.tips_on())


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
	for layer: Variant in [_notice_layer, _sell_layer, _settings_layer, _offline_layer, _daily_layer, _video_layer, _story_layer]:
		var popup: Control = layer
		if popup != null and popup.visible:
			if popup == _notice_layer:
				_close_notice()
			elif popup == _video_layer:
				_cancel_video()
			elif popup == _story_layer:
				_close_story()
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

	# Деньги — в спокойной кремовой «пилюле» с зелёной монетой.
	var pill_center := CenterContainer.new()
	header.add_child(pill_center)
	var pill := PanelContainer.new()
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = COLOR_PANEL
	pill_style.set_corner_radius_all(60)
	pill_style.border_width_bottom = 5
	pill_style.border_color = COLOR_PANEL_EDGE
	pill_style.content_margin_left = 14
	pill_style.content_margin_right = 34
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", pill_style)
	pill_center.add_child(pill)
	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 12)
	pill.add_child(pill_row)
	var coin := _make_coin()
	pill_row.add_child(coin)
	# Фиксированная ширина: цифры не прыгают и не оставляют старых знаков.
	var coin_frame := Control.new()
	coin_frame.custom_minimum_size = Vector2(380, 72)
	coin_frame.clip_contents = true
	pill_row.add_child(coin_frame)
	_coins_label = Label.new()
	_coins_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display(_coins_label, 58, COLOR_MONEY)
	coin_frame.add_child(_coins_label)

	# Чипы: доход в секунду, рейтинг, город борьбы.
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	header.add_child(chips)
	chips.add_theme_constant_override("separation", 8)
	_tap_label = _make_chip(chips, COLOR_CHIP, "chip_income")
	_reputation_label = _make_chip(chips, COLOR_CHIP, "chip_star")
	_rep_label = _make_chip(chips, COLOR_CHIP, "chip_rep")
	_share_label = _make_chip(chips, COLOR_CHIP, "chip_city")

	# Линия тапа: копится от денег, наполнилась — тап по ней покупает следующий уровень.
	_tap_line = Button.new()
	_tap_line.custom_minimum_size = Vector2(0, 76)
	_tap_line.focus_mode = Control.FOCUS_NONE
	_tap_line.clip_contents = true
	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = COLOR_PANEL
	empty_style.set_corner_radius_all(38)
	empty_style.border_width_bottom = 5
	empty_style.border_color = COLOR_PANEL_EDGE
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		_tap_line.add_theme_stylebox_override(state, empty_style)
	_tap_line.pressed.connect(_on_tap_line)
	header.add_child(_tap_line)
	_tap_line_fill = Panel.new()
	_tap_line_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tap_line_fill.anchor_bottom = 1.0
	_tap_line_fill.offset_left = 6
	_tap_line_fill.offset_top = 6
	_tap_line_fill.offset_bottom = -9
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(COLOR_BUY, 0.35)
	fill_style.set_corner_radius_all(32)
	_tap_line_fill.add_theme_stylebox_override("panel", fill_style)
	_tap_line.add_child(_tap_line_fill)
	_tap_line_label = Label.new()
	_tap_line_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tap_line_label.offset_bottom = -3
	_tap_line_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tap_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tap_line_label.add_theme_font_size_override("font_size", 27)
	_tap_line_label.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
	_col(_tap_line_label, COLOR_TEXT)
	_tap_line.add_child(_tap_line_label)
	return header


## Линия тапа: сколько накоплено до следующего уровня и что он даст.
func _refresh_tap_line() -> void:
	if _tap_line == null:
		return
	var cost: float = GameState.get_tap_level_cost()
	var ready: bool = GameState.can_buy_tap_level()
	var part: float = clampf(GameState.coins / maxf(cost, 0.001), 0.0, 1.0)
	_tap_line_fill.anchor_right = part
	_tap_line_fill.offset_right = -6.0 * part
	var fill_style: StyleBoxFlat = _tap_line_fill.get_theme_stylebox("panel")
	fill_style.bg_color = COLOR_BUY if ready else Color(COLOR_BUY, 0.35)
	var now_mult: float = GameState.get_car_tap_mult()
	var next_mult: float = GameState.get_level_tap_mult(GameState.get_tap_level() + 1)
	var next_car: String = GameState.get_next_level_car()
	var gain: String = "тап ×%s → ×%s" % [_mult_text(now_mult), _mult_text(next_mult)]
	if next_car != "":
		gain += " · %s" % _car_name(next_car)
	var text: String = "Нажмите: %s" % gain if ready else "%s / %s · %s" % [GameState.format_money(GameState.coins), GameState.format_money(cost), gain]
	# Текст и цвет трогаем, только если что-то поменялось: иначе лишняя перерисовка.
	if text != _tap_line_text:
		_tap_line_text = text
		_tap_line_label.text = text
		_col(_tap_line_label, Color.WHITE if ready else COLOR_TEXT)


func _mult_text(value: float) -> String:
	if value >= 100.0:
		return GameState.format_number(roundf(value))
	return ("%.1f" % value).replace(".0", "").replace(".", ",")


func _on_tap_line() -> void:
	if GameState.buy_tap_level():
		_refresh_tap_line()


## Золотая монета с долларом, нарисованная из кругов.
func _make_coin() -> Control:
	var coin := Panel.new()
	coin.custom_minimum_size = Vector2(60, 60)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BUY
	style.set_corner_radius_all(35)
	style.set_border_width_all(5)
	style.border_color = Color("1f8f45")
	coin.add_theme_stylebox_override("panel", style)
	var sign := Label.new()
	sign.text = "$"
	sign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_display(sign, 34, Color.WHITE)
	coin.add_child(sign)
	return coin


## Цветной чип с текстом. Возвращает подпись, чтобы её обновлять.
func _make_chip(parent: Container, color: Color, icon_kind: String = "") -> Label:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(26)
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.35)
	style.content_margin_left = 10 if icon_kind != "" else 18
	style.content_margin_right = 16
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	chip.add_theme_stylebox_override("panel", style)
	parent.add_child(chip)
	var holder: Container = chip
	if icon_kind != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		chip.add_child(row)
		var icon: Control = ItemIcon.new()
		icon.kind = icon_kind
		icon.badge = false
		icon.custom_minimum_size = Vector2(30, 30)
		row.add_child(icon)
		holder = row
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 25)
	label.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
	_col(label, _text_on(color))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	holder.add_child(label)
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
	var hint := _make_center_label("", 28, Color.WHITE)
	_tap_hint = hint
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hint.offset_top = 6
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_constant_override("outline_size", 10)
	hint.add_theme_color_override("font_outline_color", Color("1c2b4d"))
	taxi_holder.add_child(hint)

	# «Что дальше»: одна понятная цель под подсказкой, тап ведёт на нужную вкладку.
	_goal_panel = PanelContainer.new()
	_goal_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_goal_panel.offset_top = 56
	_goal_panel.offset_left = 24
	_goal_panel.offset_right = -24
	_goal_panel.offset_bottom = 56
	_goal_panel.grow_vertical = Control.GROW_DIRECTION_END
	var goal_style := StyleBoxFlat.new()
	goal_style.bg_color = Color(COLOR_PANEL, 0.96)
	goal_style.set_corner_radius_all(36)
	goal_style.set_border_width_all(4)
	goal_style.border_color = COLOR_ACCENT
	goal_style.content_margin_left = 22
	goal_style.content_margin_right = 22
	goal_style.content_margin_top = 12
	goal_style.content_margin_bottom = 12
	_goal_panel.add_theme_stylebox_override("panel", goal_style)
	_goal_panel.gui_input.connect(_on_goal_input)
	taxi_holder.add_child(_goal_panel)
	var goal_row := HBoxContainer.new()
	goal_row.add_theme_constant_override("separation", 14)
	goal_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_panel.add_child(goal_row)
	var goal_box := VBoxContainer.new()
	goal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_box.add_theme_constant_override("separation", 0)
	goal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_row.add_child(goal_box)
	var goal_title := _add_label(goal_box, "Что дальше", 24, COLOR_GOLD)
	goal_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_label = _add_label(goal_box, "", 30, COLOR_TEXT)
	_goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_arrow = _add_label(goal_row, "›", 56, COLOR_GOLD)
	_goal_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_goal_arrow.autowrap_mode = TextServer.AUTOWRAP_OFF
	_goal_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var goal_timer := Timer.new()
	goal_timer.wait_time = 1.0
	goal_timer.autostart = true
	goal_timer.timeout.connect(_refresh_goal)
	page.add_child(goal_timer)

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


## Следующая цель: [текст, вкладка]. Сначала то, что горит (поломки, усталость),
## потом то, что уже можно купить, и в конце — текущая дуэль.
func _next_goal() -> Array:
	if GameState.is_broken(GameState.get_my_health()):
		return ["Ваша машина сломана — почините её кнопкой внизу", -1]
	if GameState.get_broken_count() > 0:
		return ["В парке сломалась машина — почините в «Команде»", PAGE_DRIVERS]
	if GameState.get_tired_count() > 0:
		return ["Водители устали — смените смену в «Команде»", PAGE_DRIVERS]
	for raw: Variant in GameState.get_competitors():
		var rival_id: String = str(raw.get("id", ""))
		if GameState.is_rival_surrendered(rival_id):
			var boss_name: String = str(GameState.get_boss(rival_id).get("name", _rival_name(rival_id)))
			if GameState.can_buy_rival(rival_id):
				return ["%s сдаётся — выкупите на «Рынке»!" % boss_name, PAGE_MARKET]
			return ["Копите на выкуп: %s ждёт %s" % [boss_name, GameState.format_money(GameState.get_competitor_cost(rival_id))], PAGE_MARKET]
	if GameState.has_free_car():
		for index in GameState.get_candidates().size():
			if GameState.can_hire(index):
				return ["Есть свободная машина — наймите водителя в «Команде»", PAGE_DRIVERS]
	if GameState.can_buy_tap_level():
		return ["Полоска тапа наполнилась — нажмите на неё вверху!", -1]
	for raw: Variant in GameState.get_regions():
		var region_id: String = str(raw.get("id", ""))
		if GameState.can_open_region(region_id):
			return ["Можно открыть новый остров: %s" % str(raw.get("name", "")), PAGE_CITY]
	var rival: String = GameState.get_active_rival()
	if rival != "":
		var boss: String = str(GameState.get_boss(rival).get("name", _rival_name(rival)))
		var progress: float = GameState.get_duel_progress()
		if progress < 0.5:
			return ["Догоните %s: нужно сильнее в %s" % [boss, _ratio_text(1.0 / maxf(progress, 0.0001))], PAGE_MARKET]
		return ["Догоните %s: вы на %d%% его силы" % [boss, int(progress * 100.0)], PAGE_MARKET]
	if GameState.get_front_island() == "":
		return ["Все острова ваши — откройте новый на «Карте»", PAGE_CITY]
	return ["Тапайте по городу и копите на машины получше", -1]


func _refresh_goal() -> void:
	if _goal_panel == null:
		return
	# Пока идёт обучение, цель задаёт дядя Бун.
	_goal_panel.visible = _mentor_task_text == "" and GameState.has_company_name()
	if not _goal_panel.visible:
		return
	var goal: Array = _next_goal()
	_goal_label.text = str(goal[0])
	_goal_page = int(goal[1])
	_goal_arrow.visible = _goal_page >= 0


func _on_goal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_goal_panel.accept_event()
		if _goal_page >= 0:
			_show_page(_goal_page)


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


## Обновляем только то, что видно на открытой вкладке: остальное — когда её откроют.
func _on_wear_changed() -> void:
	if _my_clean_bar != null and _current_page == PAGE_TAP:
		var clean: float = GameState.get_my_clean()
		var health: float = GameState.get_my_health()
		_my_clean_bar.value = clean
		_my_health_bar.value = health
		_my_clean_label.text = "Чистота %s%s" % [_percent(clean), "  ·  пассажиры морщатся" if clean < 0.5 else ""]
		_col(_my_clean_label, _wear_color(clean))
		var health_note: String = ""
		if GameState.is_broken(health):
			health_note = "  ·  сломана, еле едет!"
		elif health < 0.5:
			health_note = "  ·  дребезжит"
		_my_health_label.text = "Состояние %s%s" % [_percent(health), health_note]
		_col(_my_health_label, _wear_color(health))
		var wash: float = GameState.get_my_wash_cost()
		_wash_me_button.text = "Помыть %s" % GameState.format_money(wash) if wash > 0.0 else "Чистая"
		_wash_me_button.disabled = not GameState.can_wash_my_car()
		var repair: float = GameState.get_my_repair_cost()
		_repair_me_button.text = "Починить %s" % GameState.format_money(repair) if repair > 0.0 else "Целая"
		_repair_me_button.disabled = not GameState.can_repair_my_car()
	if _fleet_wear_label != null and _current_page == PAGE_UPGRADES:
		var broken: int = GameState.get_broken_count()
		_fleet_wear_label.text = "Парк: чистота %s  ·  состояние %s%s" % [
			_percent(GameState.get_fleet_average("clean")),
			_percent(GameState.get_fleet_average("health")),
			"  ·  сломано: %d" % broken if broken > 0 else "",
		]
		_col(_fleet_wear_label, COLOR_DANGER if broken > 0 else COLOR_MUTED)
		var wash_fleet: float = GameState.get_fleet_wash_cost()
		_wash_fleet_button.text = "Помыть парк\n%s" % GameState.format_money(wash_fleet) if wash_fleet > 0.0 else "Парк\nчистый"
		_wash_fleet_button.disabled = not GameState.can_wash_fleet()
		var repair_fleet: float = GameState.get_fleet_repair_cost()
		_repair_fleet_button.text = "Починить парк\n%s" % GameState.format_money(repair_fleet) if repair_fleet > 0.0 else "Парк\nцелый"
		_repair_fleet_button.disabled = not GameState.can_repair_fleet()
	if _current_page != PAGE_DRIVERS:
		return
	if _staff_summary != null:
		_staff_summary.text = _staff_summary_text()
		_refresh_team_tiles()
	for uid: Variant in _team_wear_rows.keys():
		var entry: Array = _team_wear_rows[uid]
		var label: Label = entry[0]
		if is_instance_valid(label):
			label.text = _team_car_text(entry[1], entry[2])
			var car: Dictionary = entry[2]
			_col(label, COLOR_DANGER if GameState.is_broken(float(car.get("health", 1))) else COLOR_INCOME)


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
	_refresh_market_share()
	if _current_page != PAGE_DRIVERS:
		return
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
		_col(label, color)
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
		_col(_rating_label, COLOR_DANGER if target < now - 0.05 else COLOR_GOLD)
	for uid: Variant in _team_wear_rows.keys():
		var entry: Array = _team_wear_rows[uid]
		var car_label: Label = entry[0]
		if is_instance_valid(car_label):
			car_label.text = _team_car_text(entry[1], entry[2])


func _make_stat_tile(parent: Container, icon_kind: String, caption: String) -> Array:
	var tile := PanelContainer.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL.darkened(0.03)
	style.set_corner_radius_all(22)
	style.set_border_width_all(2)
	style.border_color = COLOR_PANEL_EDGE
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	tile.add_theme_stylebox_override("panel", style)
	parent.add_child(tile)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	tile.add_child(row)
	var icon: Control = ItemIcon.new()
	icon.kind = icon_kind
	icon.custom_minimum_size = Vector2(76, 76)
	row.add_child(icon)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	var value := Label.new()
	value.add_theme_font_size_override("font_size", 32)
	value.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
	_col(value, COLOR_TEXT)
	box.add_child(value)
	var label := _add_label(box, caption, 22, COLOR_MUTED)
	return [value, label]


## Сводка команды в плитках: что приносит, что съедает, отзывы.
func _refresh_team_tiles() -> void:
	if _team_tiles.is_empty():
		return
	var income: float = GameState.get_income_per_second()
	_tile("income", "+%s/с" % GameState.format_money(income), "Команда приносит", COLOR_INCOME)
	_tile("salary", "−%s/с" % GameState.format_money(GameState.get_salary_per_second()), "Зарплаты водителям", COLOR_DANGER)
	var fee: float = GameState.get_helper_fee_per_second() if GameState.get_helper_fee_share() > 0.0 else 0.0
	_tile("helpers", "−%s/с" % GameState.format_money(fee) if fee > 0.0 else "—", "Помощникам" if fee > 0.0 else "Помощников нет", COLOR_DANGER if fee > 0.0 else COLOR_MUTED)
	var now: float = GameState.get_rating()
	var target: float = GameState.get_rating_target()
	var trend: String = "держатся"
	if target > now + 0.05:
		trend = "растут к %.1f" % target
	elif target < now - 0.05:
		trend = "падают к %.1f" % target
	_tile("rating", "★ %.1f" % now, "Отзывы %s" % trend, COLOR_DANGER if target < now - 0.05 else COLOR_TEXT)
	var bonus: int = int(roundf((GameState.get_rating_multiplier() - 1.0) * 100.0))
	_tile("bonus", "%s%d%%" % ["+" if bonus >= 0 else "", bonus], "К доходу от отзывов", COLOR_INCOME if bonus >= 0 else COLOR_DANGER)
	var tired: int = GameState.get_tired_count()
	_tile("team", "%d" % GameState.get_team().size(), "Устали: %d" % tired if tired > 0 else "Все бодрые", COLOR_TEXT)


func _tile(id: String, value: String, caption: String, color: Color) -> void:
	var parts: Array = _team_tiles[id]
	var value_label: Label = parts[0]
	var caption_label: Label = parts[1]
	value_label.text = value
	caption_label.text = caption
	_col(value_label, color)


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
	row.add_child(_make_item_icon(helper_id))
	var text_box := _make_text_box(row)
	_add_label(text_box, str(info.get("name", helper_id)), 34)
	_add_label(text_box, str(info.get("description", "")), 26, COLOR_MUTED)
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
		_refresh_team_tiles()


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
	for layer: Variant in [_notice_layer, _sell_layer, _settings_layer, _offline_layer, _daily_layer, _name_layer, _video_layer, _story_layer]:
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
	label.add_theme_font_size_override("font_size", 24)
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
const RIVAL_COLORS := [Color("a0aec8"), Color("f48fb1"), Color("9fa8da"), Color("80cbc4")]


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
	_battle_city = null
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
		# Реклама нужна и без соперников: она поднимает доход.
		_add_ad_section()
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
	_battle_city = BattleCity.new()
	ladder_box.add_child(_battle_city)
	_market_status = _add_label(ladder_box, "", 30, COLOR_TEXT)
	_market_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_label(ladder_box, "Бьёмся по очереди: догоните текущего по силе — он сдастся и предложит выкуп.", 24, COLOR_MUTED)

	for raw: Variant in GameState.get_competitors():
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) != "":
			_market_list.add_child(_make_competitor_row(str(raw.get("id", "")), raw))

	_add_ad_section()
	_market_list.add_child(_make_sell_panel())


## Кнопки и таймеры рекламных кампаний — и при соперниках, и без них.
func _refresh_ads() -> void:
	var active: Dictionary = GameState.get_active_ad()
	for ad_id: Variant in _ad_rows.keys():
		var row: Dictionary = _ad_rows[ad_id]
		var status: Label = row["status"]
		var button: Button = row["button"]
		var id := str(ad_id)
		var video: bool = GameState.get_ad_pay(id) == "video"
		# Таймер — прямо на кнопке, на месте цены.
		if str(active.get("id", "")) == id:
			status.text = "Кампания идёт!"
			button.text = "Идёт\n%s" % _wait_text(GameState.get_ad_left())
		elif not active.is_empty():
			status.text = "Сначала закончится текущая кампания"
			button.text = "Через\n%s" % _wait_text(GameState.get_ad_left())
		elif video and GameState.get_ad_wait(id) > 0:
			status.text = _ad_duel_hint(id)
			button.text = "Ролик через\n%s" % _wait_text(GameState.get_ad_wait(id))
		elif video:
			status.text = _ad_duel_hint(id)
			button.text = "▶ Смотреть\nролик"
		else:
			status.text = _ad_duel_hint(id)
			button.text = "Запустить\n%s" % GameState.format_money(GameState.get_ad_price(id))
		button.disabled = not GameState.can_buy_ad(id)
		_timer_look(button, button.text.contains(":"))


func _add_ad_section() -> void:
	_market_list.add_child(_make_section_title("Рекламная кампания"))
	for raw: Variant in GameState.get_ads():
		if typeof(raw) == TYPE_DICTIONARY:
			_market_list.add_child(_make_ad_row(raw))


func _make_ad_row(info: Dictionary) -> PanelContainer:
	var ad_id: String = str(info.get("id", ""))
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	row.add_child(_make_item_icon(ad_id))
	var text_box := _make_text_box(row)
	_add_label(text_box, str(info.get("name", ad_id)), 34)
	_add_label(text_box, str(info.get("description", "")), 26, COLOR_MUTED)
	var pay_text: String = "за просмотр ролика" if str(info.get("pay", "coins")) == "video" else "за монеты"
	_add_label(text_box, "+%d%% к доходу на %d мин · %s" % [
		int(roundf(float(info.get("boost", 0)) * 100.0)),
		int(float(info.get("duration", 0)) / 60.0),
		pay_text,
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

	# Шапка: портрет босса, компания, босс и характер.
	var boss: Dictionary = GameState.get_boss(competitor_id)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	column.add_child(head)
	var face: Control = BossPortrait.new()
	face.set_look(boss.get("look", {}))
	face.custom_minimum_size = Vector2(110, 110)
	head.add_child(face)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 2)
	head.add_child(names)
	var title := _add_label(names, str(info.get("name", competitor_id)), 34)
	var mood := _add_label(names, "%s · %s" % [str(boss.get("name", "")), str(info.get("personality_name", "")).to_lower()], 28, COLOR_GOLD)
	var status := _add_label(column, "", 32, COLOR_TEXT)

	# Канат: вы слева, босс справа, узел ползёт к финишному флажку.
	var bar: Control = DuelRope.new()
	bar.set_rival(boss.get("look", {}), _market_color(competitor_id))
	column.add_child(bar)
	var powers := _add_label(column, "", 28, COLOR_TEXT)
	powers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var effects := _add_label(column, "", 24, COLOR_INCOME)
	var description := _add_label(column, "%s %s" % [str(info.get("description", "")), str(boss.get("style", ""))], 24, COLOR_MUTED)
	var hint := _add_label(column, "", 24, COLOR_MUTED)

	var tricks := HBoxContainer.new()
	tricks.add_theme_constant_override("separation", 8)
	column.add_child(tricks)
	var trick_buttons: Dictionary = {}
	for raw: Variant in GameState.get_tricks():
		var trick_id: String = str(raw.get("id", ""))
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 200)
		button.focus_mode = Control.FOCUS_NONE
		_style_plain_button(button, COLOR_TRICK)
		button.pressed.connect(_on_trick.bind(competitor_id, trick_id))
		# Картинка пакости сверху, подпись снизу — кнопку видно издалека.
		var trick_face := VBoxContainer.new()
		trick_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		trick_face.offset_top = 10
		trick_face.offset_bottom = -14
		trick_face.offset_left = 6
		trick_face.offset_right = -6
		trick_face.alignment = BoxContainer.ALIGNMENT_CENTER
		trick_face.add_theme_constant_override("separation", 2)
		trick_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(trick_face)
		var picture: Control = ItemIcon.new()
		picture.kind = trick_id
		picture.custom_minimum_size = Vector2(0, 82)
		picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trick_face.add_child(picture)
		var caption := Label.new()
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.add_theme_font_size_override("font_size", 21)
		caption.add_theme_font_override("font", load("res://assets/fonts/Inter-Bold.otf"))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trick_face.add_child(caption)
		button.set_meta("caption", caption)
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
	if GameState.get_ad_pay(ad_id) == "video":
		if GameState.can_buy_ad(ad_id):
			_show_rewarded(func() -> void: GameState.buy_ad(ad_id))
		return
	GameState.buy_ad(ad_id)


# --- Рекламный ролик за награду ----------------------------------------------

## Показывает ролик и после просмотра вызывает on_reward.
## Пока рекламной сети нет — заглушка: окно с отсчётом. Сюда потом подключим AdMob и т.п.
func _show_rewarded(on_reward: Callable) -> void:
	_video_reward = on_reward
	_video_left = VIDEO_STUB_SECONDS
	_video_layer.visible = true
	_refresh_video()


func _build_video_popup() -> void:
	_video_layer = Control.new()
	_video_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video_layer.visible = false
	_video_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_video_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_layer.add_child(center)
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
	box.add_child(_display(_make_center_label("Рекламный ролик", 44, Color.WHITE), 46, COLOR_GOLD))
	_video_label = _make_center_label("", 30, COLOR_MUTED)
	_video_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_video_label)
	_video_button = _make_settings_button("", COLOR_BUY, _finish_video)
	box.add_child(_video_button)
	box.add_child(_make_settings_button("Закрыть без награды", COLOR_DISABLED, _cancel_video))


func _refresh_video() -> void:
	var done: bool = _video_left <= 0.0
	_video_label.text = "Здесь будет настоящий рекламный ролик.\n%s" % (
		"Досмотрели — забирайте награду!" if done else "Осталось %d с…" % int(ceilf(_video_left)))
	_video_button.text = "Получить награду" if done else "Смотрим…"
	_video_button.disabled = not done


func _process(delta: float) -> void:
	_tick_video(delta)
	_run_one_job()


func _tick_video(delta: float) -> void:
	if _video_layer == null or not _video_layer.visible or _video_left <= 0.0:
		return
	_video_left -= delta
	_refresh_video()


func _finish_video() -> void:
	_video_layer.visible = false
	var reward: Callable = _video_reward
	_video_reward = Callable()
	if reward.is_valid():
		reward.call()


func _cancel_video() -> void:
	_video_layer.visible = false
	_video_reward = Callable()


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
		_show_story({"id": competitor_id, "beat": "deal", "text": str(result.get("text", ""))})


func _on_rival_surrendered(competitor_id: String, text: String) -> void:
	_show_story({"id": competitor_id, "beat": "surrender", "text": text})
	_mentor.on_event("surrender")


## Ход соперника висит подольше (тап — закрыть), с именем босса: чтобы успеть прочитать.
func _on_rival_attacked(competitor_id: String, text: String) -> void:
	var boss: Dictionary = GameState.get_boss(competitor_id)
	var who: String = str(boss.get("name", _rival_name(competitor_id)))
	_enqueue_toast("%s делает ход" % who, text, ATTACK_TOAST_SECONDS, boss.get("look", {}))
	_mentor.on_event("rival_attack")


func _on_rival_story(competitor_id: String, beat: String) -> void:
	var text: String = ""
	match beat:
		"intro":
			text = GameState.boss_line(competitor_id, "intro")
		"half":
			text = GameState.boss_line(competitor_id, "half")
	if text != "":
		_show_story({"id": competitor_id, "beat": beat, "text": text})


# --- Сцены с боссами конкурентов ----------------------------------------------

## Окно-диалог: значок босса, имя, реплика и ответы игрока. Сцены идут по очереди.
func _show_story(scene: Dictionary) -> void:
	if _story_layer.visible:
		_story_queue.append(scene)
		return
	var competitor_id: String = str(scene.get("id", ""))
	var boss: Dictionary = GameState.get_boss(competitor_id)
	var boss_name: String = str(boss.get("name", _rival_name(competitor_id)))
	_story_face.set_look(boss.get("look", {}))
	_story_face.talk(2.5)
	_story_name.text = boss_name
	_story_title.text = str(boss.get("title", _rival_name(competitor_id)))
	_story_you.visible = false
	_story_text.text = str(scene.get("text", ""))
	for child in _story_buttons.get_children():
		_story_buttons.remove_child(child)
		child.queue_free()
	var beat: String = str(scene.get("beat", ""))
	var replies: Array = GameState.get_boss_replies(competitor_id) if beat == "intro" else []
	if replies.is_empty():
		var label: String = {"half": "Посмотрим, кто кого!", "surrender": "Понятно", "deal": "По рукам!"}.get(beat, "Понятно")
		_story_buttons.add_child(_make_settings_button(label, COLOR_BUY, _close_story))
	else:
		for reply: Variant in replies:
			var button := _make_settings_button(str(reply["say"]), COLOR_SKY, _on_story_reply.bind(str(reply["say"]), str(reply["answer"])))
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.add_theme_font_size_override("font_size", 28)
			_story_buttons.add_child(button)
	_story_layer.visible = true


## Игрок ответил боссу — босс отвечает на ответ.
func _on_story_reply(said: String, answer: String) -> void:
	_story_you.text = "Вы: «%s»" % said
	_story_you.visible = true
	_story_text.text = answer
	_story_face.talk(2.0)
	for child in _story_buttons.get_children():
		_story_buttons.remove_child(child)
		child.queue_free()
	_story_buttons.add_child(_make_settings_button("Ну, посмотрим!", COLOR_BUY, _close_story))


func _close_story() -> void:
	_story_layer.visible = false
	if not _story_queue.is_empty():
		_show_story(_story_queue.pop_front())


func _build_story_popup() -> void:
	_story_layer = Control.new()
	_story_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_layer.visible = false
	_story_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_story_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_story_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	var style := _panel_style()
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 36
	style.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	box.add_child(head)
	_story_face = BossPortrait.new()
	_story_face.custom_minimum_size = Vector2(160, 160)
	head.add_child(_story_face)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(names)
	_story_name = Label.new()
	_display(_story_name, 42, COLOR_GOLD)
	names.add_child(_story_name)
	_story_title = _add_label(names, "", 26, COLOR_MUTED)

	_story_you = _add_label(box, "", 28, COLOR_MUTED)
	_story_text = _add_label(box, "", 32, COLOR_TEXT)
	_story_buttons = VBoxContainer.new()
	_story_buttons.add_theme_constant_override("separation", 12)
	box.add_child(_story_buttons)


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


## Серая кнопка с таймером: текст тёмный и чёткий, а не бледный, чтобы время было видно.
func _timer_look(button: Button, waiting: bool) -> void:
	var color: Color = COLOR_TEXT if waiting else Color(_text_on(COLOR_DISABLED), 0.55)
	_col(button, color, "font_disabled_color")


## «4:32» или «1 ч 05 мин» — для таймеров на кнопках.
func _wait_text(seconds: int) -> String:
	if seconds >= 3600:
		return "%d ч %02d мин" % [int(seconds / 3600), int(seconds % 3600 / 60)]
	return _mmss(seconds)


func _mmss(seconds: int) -> String:
	return "%d:%02d" % [int(seconds / 60), seconds % 60]


func _refresh_competitors() -> void:
	_rebuild_market_if_needed()
	_refresh_ads()
	if _market_status == null:
		return
	var rivals: Array = GameState.get_competitors()
	_market_status.text = "Выкуплено %d из %d — выкупите всех, и %s ваш" % [GameState.get_city_owned_count(), rivals.size(), GameState.get_front_city()]
	var scene: Array = []
	for raw: Variant in rivals:
		var id: String = str(raw.get("id", ""))
		scene.append({
			"look": GameState.get_boss(id).get("look", {}),
			"color": _market_color(id).to_html(false),
			"name": str(raw.get("name", id)).replace("Таксопарк ", "").replace("«", "").replace("»", ""),
			"state": GameState.get_rival_state(id),
		})
	if _battle_city != null:
		_battle_city.set_rivals(scene, GameState.get_front_city())


	for raw: Variant in rivals:
		var id: String = str(raw.get("id", ""))
		if _competitor_rows.has(id):
			_refresh_rival_row(id, raw)


func _refresh_rival_row(id: String, info: Dictionary) -> void:
	var row: Dictionary = _competitor_rows[id]
	var status: Label = row["status"]
	var bar: Control = row["bar"]
	var powers: Label = row["powers"]
	var hint: Label = row["hint"]
	var effects: Label = row["effects"]
	var tricks_box: HBoxContainer = row["tricks_box"]
	var buy: Button = row["buy"]
	var state: String = GameState.get_rival_state(id)
	var full: bool = state == "active"
	# Подробности — только у текущего соперника, остальные карточки короткие.
	for key: String in ["powers", "effects", "description", "hint"]:
		var label: Label = row[key]
		label.visible = full
	bar.visible = full
	tricks_box.visible = full
	buy.visible = state == "surrendered"
	var short_name: String = str(info.get("name", id)).replace("Таксопарк ", "")
	match state:
		"owned":
			status.text = "Компания ваша  ·  доход +%d%%" % int(roundf(float(info.get("income_bonus", 0)) * 100.0))
			_col(status, COLOR_INCOME)
			return
		"surrendered":
			status.text = "Сдался и ждёт выкупа. Купите — и доход +%d%%." % int(roundf(float(info.get("income_bonus", 0)) * 100.0))
			_col(status, COLOR_GOLD)
			buy.text = "Выкупить за %s" % GameState.format_money(GameState.get_competitor_cost(id))
			buy.disabled = not GameState.can_buy_rival(id)
			return
		"waiting":
			status.text = "Ждёт своей очереди · возит на %s/с" % GameState.format_money(GameState.get_competitor_power(id))
			_col(status, COLOR_MUTED)
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			return
	var mine: float = GameState.get_player_power()
	var theirs: float = GameState.get_competitor_power(id)
	_col(status, COLOR_TEXT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if theirs <= 0.0 or mine >= theirs:
		status.text = "Вы догнали! Сейчас сдадутся"
	elif theirs / maxf(mine, 0.001) >= 1.5:
		status.text = "Нужно стать сильнее в %s" % _ratio_text(theirs / maxf(mine, 0.001))
	else:
		status.text = "Осталось +%d%% силы!" % maxi(1, int(ceilf((theirs / maxf(mine, 0.001) - 1.0) * 100.0)))
	bar.set("ratio", mine / maxf(theirs, 0.001))
	bar.set("player_model", GameState.get_car_id())
	powers.text = "Вы %s/с  —  %s %s/с" % [GameState.format_money(mine), short_name, GameState.format_money(theirs)]
	var tips: PackedStringArray = PackedStringArray()
	tips.append("Сила — это доход в секунду плюс заказы с тапов.")
	if GameState.get_active_ad().is_empty():
		tips.append("Рекламная кампания поднимает доход, а с ним и силу — обгоните на ней, и победа засчитается.")
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
	effects.text = "• " + "\n• ".join(notes) if not notes.is_empty() else ""
	var tricks: Dictionary = row["tricks"]
	for trick_id: Variant in tricks.keys():
		var button: Button = tricks[trick_id]
		var tid := str(trick_id)
		var trick_name: String = ""
		for raw: Variant in GameState.get_tricks():
			if str(raw.get("id", "")) == tid:
				trick_name = str(raw.get("name", tid))
		var trick_wait: int = GameState.get_trick_wait(id)
		var caption: Label = button.get_meta("caption")
		if trick_wait > 0:
			caption.text = "%s\nснова через %s" % [trick_name, _wait_text(trick_wait)]
		else:
			caption.text = "%s\n%s · риск %d%%" % [
				trick_name,
				GameState.format_money(GameState.get_trick_price(tid)),
				int(roundf(GameState.get_catch_chance(id, tid) * 100.0)),
			]
		button.disabled = not GameState.can_play_trick(id, tid)
		# Подпись — отдельная метка: цвет ставим сами (на сером — тёмный, чтобы таймер читался).
		_col(caption, _text_on(COLOR_TRICK) if not button.disabled else (COLOR_TEXT if trick_wait > 0 else COLOR_MUTED))
		caption.get_parent().modulate = Color(1, 1, 1, 1.0 if not button.disabled or trick_wait > 0 else 0.7)


## Подсказка у кампании: хватит ли её, чтобы обогнать текущего соперника.
func _ad_duel_hint(ad_id: String) -> String:
	var rival_id: String = GameState.get_active_rival()
	if rival_id == "":
		return ""
	var boost: float = 0.0
	for raw: Variant in GameState.get_ads():
		if str(raw.get("id", "")) == ad_id:
			boost = float(raw.get("boost", 0))
	var short_name: String = _rival_name(rival_id).replace("Таксопарк ", "")
	if GameState.get_player_power() * (1.0 + boost) >= GameState.get_competitor_power(rival_id):
		return "С ней вы обгоните %s — он сдастся!" % short_name
	return "Обогнать %s пока не хватит, но доход вырастет." % short_name


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
	_col(_sell_info, COLOR_MUTED)
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
var _more_name: Label
var _more_sub: Label
var _more_tiles: Dictionary = {}
## true — окно названия открыто из «Ещё» (переименование), а не при первом запуске.
var _renaming: bool = false


## «Ещё»: карточка компании с плитками, настройки строками с картинками, обучение, сброс.
func _build_more_rows() -> void:
	# Карточка компании: эмблема-такси, название, кнопка «переименовать», плитки с цифрами.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style())
	_more_list.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 14)
	card.add_child(card_box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 18)
	card_box.add_child(head)
	var emblem: Control = ItemIcon.new()
	emblem.kind = "taxi"
	emblem.custom_minimum_size = Vector2(130, 130)
	head.add_child(emblem)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(names)
	_more_name = Label.new()
	_more_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_display(_more_name, 40, COLOR_TEXT)
	names.add_child(_more_name)
	_more_sub = _add_label(names, "", 24, COLOR_MUTED)
	var rename := Button.new()
	rename.custom_minimum_size = Vector2(100, 100)
	rename.focus_mode = Control.FOCUS_NONE
	rename.flat = true
	rename.pressed.connect(_rename_company)
	var pencil: Control = ItemIcon.new()
	pencil.kind = "pencil"
	pencil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rename.add_child(pencil)
	head.add_child(rename)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	card_box.add_child(grid)
	for tile: Array in [["rating", "chip_star", "Рейтинг"], ["rep", "chip_rep", "Репутация"],
			["franchise", "crown", "Франшиза"], ["earned", "money_bag", "Заработано всего"],
			["islands", "island", "Острова"], ["rivals", "handshake", "Выкуплено"],
			["team", "driver", "Водителей"], ["tap", "tap", "Уровень тапа"]]:
		_more_tiles[tile[0]] = _make_stat_tile(grid, str(tile[1]), str(tile[2]))

	_more_list.add_child(_make_section_title("Настройки"))
	_music_button = _make_setting_row("music", "Музыка", "Спокойная мелодия на фоне", _toggle_music)
	_sound_button = _make_setting_row("sound", "Звук и вибрация", "Звон тапов и покупок", _toggle_sound)
	_refresh_sound_button()
	_mentor_tips_button = _make_setting_row("", "Советы дяди Буна", "Шутки и подсказки деда", _toggle_mentor_tips)

	_more_list.add_child(_make_section_title("Обучение"))
	_make_action_row("restart", "Пройти обучение заново", "Дядя Бун снова всё покажет", "Начать", COLOR_BUY, _restart_tutorial)

	_more_list.add_child(_make_section_title("Опасная зона"))
	_make_action_row("trash", "Сбросить прогресс", "Сотрёт всю игру и название компании", "Сбросить", COLOR_DANGER, _ask_reset)
	var version := _make_center_label("Такси Кликер · сделано с любовью к жёлтым машинам", 22, Color.WHITE)
	_on_background(version)
	_more_list.add_child(version)


## Строка настройки: картинка, название, пояснение и переключатель справа.
func _make_setting_row(icon_kind: String, title: String, hint: String, callback: Callable) -> Button:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	if icon_kind == "":
		var boon: Control = MentorPortrait.new()
		boon.custom_minimum_size = Vector2(100, 100)
		row.add_child(boon)
	else:
		row.add_child(_make_item_icon(icon_kind))
	var text_box := _make_text_box(row)
	_add_label(text_box, title, 32)
	_add_label(text_box, hint, 24, COLOR_MUTED)
	var toggle := Button.new()
	toggle.custom_minimum_size = Vector2(170, 84)
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", 28)
	toggle.pressed.connect(callback)
	row.add_child(toggle)
	_more_list.add_child(parts[0])
	return toggle


func _make_action_row(icon_kind: String, title: String, hint: String, button_text: String, color: Color, callback: Callable) -> void:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	row.add_child(_make_item_icon(icon_kind))
	var text_box := _make_text_box(row)
	_add_label(text_box, title, 32)
	_add_label(text_box, hint, 24, COLOR_MUTED)
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(170, 84)
	button.focus_mode = Control.FOCUS_NONE
	_style_plain_button(button, color)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	row.add_child(button)
	_more_list.add_child(parts[0])


## Переключатель «вкл/выкл»: зелёный — включено, серый — выключено.
func _set_toggle(button: Button, on: bool) -> void:
	if button == null:
		return
	button.text = "Вкл" if on else "Выкл"
	_style_plain_button(button, COLOR_BUY if on else COLOR_DISABLED)


func _rename_company() -> void:
	_name_edit.text = GameState.company_name
	_name_error.text = ""
	_renaming = true
	_name_layer.visible = true
	move_child(_name_layer, get_child_count() - 1)


func _refresh_more() -> void:
	if _more_name == null:
		return
	if _mentor != null:
		_refresh_mentor_buttons()
	_more_name.text = "«%s»" % GameState.company_name
	_more_sub.text = "Такси №1 в %d из %d городов" % [GameState.get_captured_count(), GameState.get_regions().size()] if GameState.get_captured_count() > 0 else "Борьба за %s" % GameState.get_front_city()
	_more_tile("rating", "★ %.1f" % GameState.get_rating())
	_more_tile("rep", GameState.format_number(float(GameState.reputation)))
	_more_tile("franchise", "×%s" % GameState.format_number(GameState.get_franchise()))
	_more_tile("earned", GameState.format_money(GameState.lifetime_earned))
	_more_tile("islands", "%d из %d" % [GameState.get_captured_count(), GameState.get_regions().size()])
	_more_tile("rivals", "%d из %d" % [GameState.get_achievement_value("competitors"), GameState.get_all_competitor_count()])
	_more_tile("team", "%d" % GameState.get_team().size())
	_more_tile("tap", "%d" % GameState.get_tap_level())


func _more_tile(id: String, value: String) -> void:
	var parts: Array = _more_tiles.get(id, [])
	if parts.is_empty():
		return
	var label: Label = parts[0]
	label.text = value


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
		_col(about, COLOR_MUTED)
		_district_list.add_child(about)

		_multiplier_label = Label.new()
		_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_multiplier_label.add_theme_font_size_override("font_size", 32)
		_col(_multiplier_label, COLOR_INCOME)
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
	row.add_child(_make_item_icon(district_id))

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
	_col(description, COLOR_MUTED)
	text_box.add_child(description)

	var bonus: float = float(info.get("income_bonus", 0))
	var bonus_label := Label.new()
	bonus_label.text = "Доход +%s%%" % GameState.format_number(bonus * 100.0)
	bonus_label.add_theme_font_size_override("font_size", 26)
	_col(bonus_label, COLOR_INCOME)
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
	_build_garage_rows(_upgrade_list)
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


func _on_car_changed() -> void:
	_refresh_cars()
	_sync_city()
	_refresh_rate_line()


func _refresh_cars() -> void:
	_refresh_tap_line()


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
	_col(_name_edit, COLOR_TEXT)
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
	if _renaming:
		_renaming = false
		_refresh_more()
		return
	_mentor.begin()


func _build_driver_rows() -> void:
	var hint := Label.new()
	hint.text = "Водитель + свободная машина из гаража = доход, даже когда вы не тапаете. Зарплата вычитается сама. Машины — во вкладке «Машина»."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 26)
	_on_background(hint)
	_driver_list.add_child(hint)

	var service := PanelContainer.new()
	service.add_theme_stylebox_override("panel", _panel_style())
	_driver_list.add_child(service)
	var service_box := VBoxContainer.new()
	service_box.add_theme_constant_override("separation", 10)
	service.add_child(service_box)
	# Плитки с картинками: доход команды, зарплаты, помощники, отзывы, бонус, состав.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	service_box.add_child(grid)
	for tile: Array in [["income", "chart", "Команда приносит"], ["salary", "wallet", "Зарплаты"],
			["helpers", "dispatcher", "Помощникам"], ["rating", "chip_star", "Отзывы"],
			["bonus", "money_bag", "Бонус к доходу"], ["team", "team", "Водителей"]]:
		_team_tiles[tile[0]] = _make_stat_tile(grid, str(tile[1]), str(tile[2]))
	_staff_summary = Label.new()
	_staff_summary.visible = false
	service_box.add_child(_staff_summary)
	_rating_label = Label.new()
	_rating_label.visible = false
	service_box.add_child(_rating_label)
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
	_rebuild_staff()


## Весь гараж во вкладке «Машина»: места, мойка и ремонт парка, машины, покупка.
func _build_garage_rows(list: VBoxContainer) -> void:
	list.add_child(_make_section_title("Гараж"))
	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", _panel_style())
	list.add_child(summary)
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 16)
	summary.add_child(summary_row)
	summary_row.add_child(_make_item_icon("garage"))
	var summary_text := VBoxContainer.new()
	summary_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(summary_text)
	_garage_label = Label.new()
	_garage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_garage_label.add_theme_font_size_override("font_size", 34)
	summary_text.add_child(_garage_label)
	_fleet_wear_label = _add_label(summary_text, "", 26, COLOR_MUTED)
	_expand_button = _make_row_button(_on_expand_garage)
	summary_row.add_child(_expand_button)

	var service := PanelContainer.new()
	service.add_theme_stylebox_override("panel", _panel_style())
	list.add_child(service)
	var service_row := HBoxContainer.new()
	service_row.add_theme_constant_override("separation", 12)
	service.add_child(service_row)
	_wash_fleet_button = _make_row_button(_on_wash_fleet)
	_wash_fleet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_wash_fleet_button.custom_minimum_size = Vector2(0, 100)
	service_row.add_child(_wash_fleet_button)
	_repair_fleet_button = _make_row_button(_on_repair_fleet)
	_repair_fleet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_repair_fleet_button.custom_minimum_size = Vector2(0, 100)
	service_row.add_child(_repair_fleet_button)

	list.add_child(_make_section_title("Машины в гараже"))
	_garage_box = VBoxContainer.new()
	_garage_box.add_theme_constant_override("separation", 16)
	list.add_child(_garage_box)

	list.add_child(_make_section_title("Купить машину в гараж"))
	var cars: Array = GameState.get_cars()
	for index in range(1, cars.size()):
		var raw: Variant = cars[index]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var car_id: String = str(info.get("id", ""))
		if car_id != "":
			list.add_child(_make_fleet_row(car_id, info))


func _make_item_icon(kind: String) -> Control:
	var icon: Control = ItemIcon.new()
	icon.kind = kind
	icon.custom_minimum_size = Vector2(110, 110)
	return icon


## Портрет водителя: внешность выбирается по имени — у одного человека всегда одно лицо.
## Черты характера видны: соня зевает, гонщик в очках, караоке поёт, жадный с золотым зубом.
func _make_driver_face(person: Dictionary) -> Control:
	var face: Control = BossPortrait.new()
	face.custom_minimum_size = Vector2(110, 110)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.set_look(_driver_look(person))
	return face


const DRIVER_SKINS := ["c98a5a", "b47a4c", "e0b48f", "a8774e", "d9a06b", "8d5a36", "f1c9a0"]
const DRIVER_HAIR := ["1e1e1e", "2b1a10", "3b2a20", "4e342e", "141414"]
const DRIVER_BACKS := ["bfe6ff", "c8f0d0", "e6e0ff", "ffd9e3", "d7f2f5", "e8f6e0"]
const DRIVER_SHIRTS := ["3fa3f5", "2fbf5f", "8b7cf0", "e8434f", "26a69a", "5c6bc0"]
const FEMALE_HINTS := ["Бабушка", "Тётя", "Пим", "Нок", "Мэй", "Тара"]
const OLD_HINTS := ["Бабушка", "Дядя", "Дед", "Тётя"]


func _driver_look(person: Dictionary) -> Dictionary:
	var name_text: String = str(person.get("name", ""))
	var seed_value: int = absi(name_text.hash())
	var pick := func(list: Array, shift: int) -> String:
		return str(list[(seed_value >> shift) % list.size()])
	var female: bool = FEMALE_HINTS.any(func(hint: String) -> bool: return name_text.begins_with(hint))
	var old: bool = OLD_HINTS.any(func(hint: String) -> bool: return name_text.begins_with(hint))
	var look: Dictionary = {
		"bg": pick.call(DRIVER_BACKS, 0),
		"skin": pick.call(DRIVER_SKINS, 3),
		"hair_color": "e8e8e8" if old else pick.call(DRIVER_HAIR, 6),
		"cloth": pick.call(DRIVER_SHIRTS, 9),
		"collar": "shirt",
		"mouth": "smile",
		"female": female,
	}
	if female:
		look["hair"] = "bun" if old else ["long", "bob", "curly_long"][(seed_value >> 12) % 3]
		look["eyes"] = "lashes"
		look["lips"] = "c2185b"
	else:
		look["hair"] = "bald_sides" if old else ["short", "slick", "messy", "curly"][(seed_value >> 12) % 4]
		if (seed_value >> 15) % 3 == 0:
			look["beard"] = "walrus" if old else ["mustache", "stubble"][(seed_value >> 17) % 2]
		# Половина водителей — в таксистской кепке.
		if (seed_value >> 19) % 2 == 0:
			look["hat"] = "cap"
			look["hat_color"] = "2a2a48"
	if old:
		look["glasses"] = "round"
	match str(person.get("trait", "")):
		"sleepy":
			look["eyes"] = "sleepy"
			look["extra"] = ["zzz"]
		"racer":
			look["glasses"] = "goggles"
			look["mouth"] = "grin"
		"karaoke":
			look["mouth"] = "shout"
		"greedy":
			look["mouth"] = "grin"
			look["gold_tooth"] = true
		"talker":
			look["mouth"] = "grin"
		"honest":
			look["eyes"] = "happy"
	return look


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
	panel.add_theme_stylebox_override("panel", _shared_panel())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	return [panel, row]


## Цвет шрифта меняем, только если он правда другой: каждая смена темы заставляет
## Godot пересчитывать оформление, и при частых обновлениях это даёт подёргивания.
func _col(control: Control, color: Color, item: String = "font_color") -> void:
	var key: String = "_c_" + item
	if control.has_meta(key) and control.get_meta(key) == color:
		return
	control.set_meta(key, color)
	control.add_theme_color_override(item, color)


func _add_label(box: Container, text: String, font_size: int, color: Color = COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	_col(label, color)
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
## Команда и кандидаты. Строки не пересоздаются целиком: у оставшихся водителей
## строка живёт дальше, создаются только новые. Создание строки дорогое (тексты,
## кнопки), и полная пересборка давала заметный рывок при каждой покупке.
func _rebuild_staff() -> void:
	if _team_box == null:
		return
	# Команда и гараж видны на двух вкладках. На других — просто запомним, что пора обновить.
	if _current_page != PAGE_DRIVERS and _current_page != PAGE_UPGRADES:
		_staff_stale = true
		return
	_staff_stale = false
	var cars: Dictionary = GameState.get_assignments()
	var team: Array = GameState.get_team()
	var present: Dictionary = {}
	for raw: Variant in team:
		present[int(raw.get("uid", 0))] = true
	for uid: Variant in _team_rows.keys():
		if not present.has(uid):
			var gone: Dictionary = _team_rows[uid]
			(gone["panel"] as Control).queue_free()
			_team_rows.erase(uid)
			_team_wear_rows.erase(uid)
			_team_shift_rows.erase(uid)
	if _team_empty == null:
		_team_empty = _add_label(_team_box, "Пока никого. Купите машину в гараж и наймите первого водителя.", 26, COLOR_MUTED)
	_team_empty.visible = team.is_empty()
	var order: int = 1
	for raw: Variant in team:
		var person: Dictionary = raw
		var uid: int = int(person.get("uid", 0))
		if not _team_rows.has(uid):
			_team_rows[uid] = _make_team_row(person, uid)
		var entry: Dictionary = _team_rows[uid]
		_team_box.move_child(entry["panel"], order)
		order += 1
		var car: Dictionary = cars.get(uid, {})
		var car_label: Label = entry["car"]
		var no_car: Label = entry["no_car"]
		car_label.visible = not car.is_empty()
		no_car.visible = car.is_empty()
		if car.is_empty():
			_team_wear_rows.erase(uid)
		else:
			_team_wear_rows[uid] = [car_label, person, car]
		_team_shift_rows[uid] = [entry["shift_label"], entry["shift_bar"], entry["shift_button"], person]

	_rebuild_garage_list()

	# Кандидаты меняются редко (найм, «позвать других»): пересобираем, только если что-то изменилось.
	var free_cars: Array = GameState.get_free_garage_cars()
	var free_model: String = "" if free_cars.is_empty() else str(free_cars[0].get("model", ""))
	var candidates: Array = GameState.get_candidates()
	var signature: String = "%s|%d|%s" % [free_model, team.size(), ",".join(candidates.map(func(p: Variant) -> String: return str(p.get("name", ""))))]
	if signature != _candidate_signature:
		_candidate_signature = signature
		_staff_buttons.clear()
		for child in _candidate_box.get_children():
			child.queue_free()
		for index in candidates.size():
			_candidate_box.add_child(_make_candidate_row(candidates[index], index, free_model))
	_refresh_staff_money()
	_on_wear_changed()
	_on_shifts_changed()


func _make_team_row(person: Dictionary, uid: int) -> Dictionary:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	row.add_child(_make_driver_face(person))
	var text_box := _make_text_box(row)
	_add_label(text_box, str(person.get("name", "")), 34)
	_add_label(text_box, _person_line(person), 26, COLOR_GOLD)
	var no_car := _add_label(text_box, "Без машины — купите ещё одну в гараж", 26, COLOR_DANGER)
	var car_label := _add_label(text_box, "", 26, COLOR_INCOME)
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
	_team_box.add_child(parts[0])
	return {
		"panel": parts[0], "car": car_label, "no_car": no_car,
		"shift_label": shift_label, "shift_bar": shift_bar, "shift_button": shift_button,
	}


func _make_candidate_row(person: Dictionary, index: int, free_model: String) -> PanelContainer:
	var parts: Array = _make_row_panel()
	var row: HBoxContainer = parts[1]
	row.add_child(_make_driver_face(person))
	var text_box := _make_text_box(row)
	_add_label(text_box, str(person.get("name", "")), 34)
	_add_label(text_box, _person_line(person), 26, COLOR_GOLD)
	var trait_info: Dictionary = GameState.get_trait_info(str(person.get("trait", "")))
	_add_label(text_box, str(trait_info.get("description", "")), 26, COLOR_MUTED)
	if free_model == "":
		_add_label(text_box, "Нет свободной машины в гараже", 26, COLOR_DANGER)
	else:
		_add_label(text_box, "На «%s» ≈ %s/с  ·  зарплата %d%%" % [
			_car_name(free_model),
			GameState.format_money(GameState.get_driver_net(person, free_model)),
			int(roundf(GameState.get_salary_share(person) * 100.0)),
		], 26, COLOR_INCOME)
	var hire_button := _make_row_button(_on_hire.bind(index))
	hire_button.text = "Нанять\n%s" % GameState.format_money(GameState.get_hire_cost(person))
	row.add_child(hire_button)
	_staff_buttons.append([hire_button, GameState.can_hire.bind(index)])
	return parts[0]


## Только то, что зависит от денег: доступность кнопок и цены.
func _refresh_staff_money() -> void:
	if _garage_label == null:
		return
	if _current_page == PAGE_DRIVERS:
		for pair: Variant in _staff_buttons:
			var button: Button = pair[0]
			var check: Callable = pair[1]
			if is_instance_valid(button):
				button.disabled = not check.call()
		_staff_summary.text = _staff_summary_text()
		_refresh_team_tiles()
		_refresh_candidate_timer()
		return
	if _current_page != PAGE_UPGRADES:
		return
	# Текст собираем целиком и ставим один раз: каждая смена текста — пересчёт раскладки.
	var garage_text: String = "Гараж: %d / %d  ·  водителей: %d" % [
		GameState.get_garage().size(),
		GameState.get_garage_capacity(),
		GameState.get_team().size(),
	]
	if GameState.get_island_garage_slots() > 0:
		garage_text += "\nдома %d + на островах %d" % [GameState.get_home_garage_capacity(), GameState.get_island_garage_slots()]
	if GameState.get_garage().size() > GameState.get_garage_capacity():
		garage_text += "\nМашин больше, чем мест: лишние можно продать"
	_garage_label.text = garage_text
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
				note.text = "Гараж полон: расширьте его или продайте машину в списке выше"
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


## Машины гаража сгруппированы по моделям: сколько, сколько без водителя, продать одну.
func _rebuild_garage_list() -> void:
	if _garage_box == null:
		return
	# Пересобираем, только если поменялся состав гаража или команды.
	var counts: PackedStringArray = PackedStringArray()
	for car: Variant in GameState.get_garage():
		counts.append(str(car.get("model", "")))
	var signature: String = "%s|%d" % [",".join(counts), GameState.get_team().size()]
	if signature == _garage_signature:
		return
	_garage_signature = signature
	for child in _garage_box.get_children():
		_garage_box.remove_child(child)
		child.queue_free()
	var models: Array = []
	for car: Variant in GameState.get_garage():
		var model: String = str(car.get("model", ""))
		if not models.has(model):
			models.append(model)
	if models.is_empty():
		_add_label(_garage_box, "Гараж пуст. Купите машину в парк ниже.", 26, COLOR_MUTED)
		return
	for model: String in models:
		var parts: Array = _make_row_panel()
		var row: HBoxContainer = parts[1]
		row.add_child(_make_car_icon(model))
		var text_box := _make_text_box(row)
		var count: int = GameState.get_fleet_count(model)
		var free: int = GameState.get_free_count(model)
		_add_label(text_box, "%s ×%d" % [_car_name(model), count], 34)
		if free > 0:
			_add_label(text_box, "Без водителя: %d — продадим сначала её" % free, 24, COLOR_GOLD)
		elif GameState.get_garage().size() > GameState.get_team().size():
			_add_label(text_box, "Водитель пересядет на свободную машину", 24, COLOR_MUTED)
		else:
			_add_label(text_box, "Свободных машин нет: один водитель останется без машины", 24, COLOR_DANGER)
		var button := _make_row_button(_on_sell_garage_car.bind(model))
		button.text = "Продать 1\n+%s" % GameState.format_money(GameState.get_sell_value(model))
		_style_plain_button(button, COLOR_DANGER)
		button.add_theme_font_size_override("font_size", 28)
		row.add_child(button)
		_garage_box.add_child(parts[0])


func _on_sell_garage_car(model: String) -> void:
	var value: float = GameState.sell_garage_car(model)
	if value > 0.0:
		_enqueue_toast("Продано", "«%s» ушла за %s" % [_car_name(model), GameState.format_money(value)])


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
	row.add_child(_make_item_icon(upgrade_id))

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
	_col(description, COLOR_MUTED)
	text_box.add_child(description)

	var level_label := Label.new()
	level_label.add_theme_font_size_override("font_size", 28)
	_col(level_label, COLOR_GOLD)
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
var _panel_shared: StyleBoxFlat


## Общий стиль карточки для строк списков — один на всех, не создаём заново.
func _shared_panel() -> StyleBoxFlat:
	if _panel_shared == null:
		_panel_shared = _panel_style()
	return _panel_shared


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
	_col(label, COLOR_TITLE)
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
## Готовые стили кнопок: одинаковые кнопки делят один стиль, а не создают свой.
var _button_styles: Dictionary = {}


func _button_style(color: Color, flat: bool = false) -> StyleBoxFlat:
	var key: String = "%s/%s" % [color.to_html(), flat]
	if _button_styles.has(key):
		return _button_styles[key]
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(26)
	style.border_width_bottom = 2 if flat else 8
	style.border_color = color.darkened(0.35)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12 if not flat else 16
	style.content_margin_bottom = 12
	_button_styles[key] = style
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
	_col(_offline_time_label, COLOR_MUTED)
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


## Иконка задания по его виду.
const QUEST_ICONS := {
	"earned": "money_bag", "tap_level": "tap", "cars": "taxi", "drivers": "driver", "garage": "garage",
	"districts": "center", "regions": "island", "competitors": "handshake", "captured": "chip_city",
	"reputation": "chip_rep", "upgrades": "mechanic", "helpers": "dispatcher", "rating": "chip_star",
	"franchise": "crown",
}


## Задания: по одному текущему в каждой цепочке (деньги, водители, острова…).
## Выполненные исчезают, у текущих — полоска и «ещё сколько осталось».
func _build_achievement_rows() -> void:
	_achievement_list.add_child(_make_section_title("Задания"))
	var head := PanelContainer.new()
	head.add_theme_stylebox_override("panel", _panel_style())
	_achievement_list.add_child(head)
	var head_box := VBoxContainer.new()
	head_box.add_theme_constant_override("separation", 8)
	head.add_child(head_box)
	_quest_total_label = _add_label(head_box, "", 30, COLOR_TEXT)
	_quest_total_bar = _make_bar(COLOR_BUY)
	head_box.add_child(_quest_total_bar)
	_add_label(head_box, "Выполнил задание — награда сразу в кошелёк, а на его месте появляется следующее, посложнее.", 24, COLOR_MUTED)
	for raw: Variant in GameState.get_achievements():
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var achievement_id: String = str(info.get("id", ""))
		if achievement_id == "":
			continue
		var parts: Array = _make_row_panel()
		var row: HBoxContainer = parts[1]
		row.add_child(_make_item_icon(str(QUEST_ICONS.get(str(info.get("kind", "")), "chip_star"))))
		var text_box := _make_text_box(row)
		_add_label(text_box, str(info.get("name", "")), 32)
		_add_label(text_box, str(info.get("description", "")), 24, COLOR_MUTED)
		var bar := _make_bar(COLOR_BUY)
		text_box.add_child(bar)
		var progress := _add_label(text_box, "", 24, COLOR_GOLD)
		var reward_box := VBoxContainer.new()
		reward_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(reward_box)
		var reward := _make_center_label("Награда\n+%s" % GameState.format_money(float(info.get("reward_coins", 0))), 24, COLOR_INCOME)
		reward.custom_minimum_size = Vector2(170, 0)
		reward_box.add_child(reward)
		_achievement_list.add_child(parts[0])
		_achievement_labels[achievement_id] = {"panel": parts[0], "bar": bar, "progress": progress, "info": info}


func _refresh_achievements() -> void:
	var defs: Array = GameState.get_achievements()
	var done: int = 0
	# В каждой цепочке показываем только первое невыполненное задание.
	var shown_kinds: Dictionary = {}
	for raw: Variant in defs:
		var achievement_id: String = str(raw.get("id", ""))
		var entry: Dictionary = _achievement_labels.get(achievement_id, {})
		if entry.is_empty():
			continue
		var panel: Control = entry["panel"]
		if GameState.is_achievement_done(achievement_id):
			done += 1
			panel.visible = false
			continue
		var kind: String = str(raw.get("kind", ""))
		if shown_kinds.has(kind):
			panel.visible = false
			continue
		shown_kinds[kind] = true
		panel.visible = true
		var need: float = float(raw.get("need", 1))
		var value: float = minf(GameState.get_achievement_value(kind), need)
		var bar: ProgressBar = entry["bar"]
		bar.max_value = need
		bar.value = value
		var progress: Label = entry["progress"]
		var shown_value: String = GameState.format_money(value) if kind == "earned" else ("%.1f" % value if kind == "rating" else GameState.format_number(value))
		var shown_need: String = GameState.format_money(need) if kind == "earned" else ("%.1f" % need if kind == "rating" else GameState.format_number(need))
		progress.text = "%s из %s" % [shown_value, shown_need]
	if _quest_total_label != null:
		_quest_total_label.text = "Выполнено %d из %d" % [done, defs.size()]
		_quest_total_bar.max_value = maxf(1.0, float(defs.size()))
		_quest_total_bar.value = done


func _on_achievement_unlocked(title: String, body: String) -> void:
	_enqueue_toast(title, body)
	_refresh_achievements()


func _enqueue_toast(title: String, body: String, seconds: float = 2.2, look: Dictionary = {}) -> void:
	_toast_queue.append(["%s\n%s" % [title, body], seconds, look])
	if _toast_layer != null and not _toast_layer.visible:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toast_layer.visible = false
		return
	var next: Array = _toast_queue.pop_front()
	_toast_label.text = str(next[0])
	var look: Dictionary = next[2] if next.size() > 2 else {}
	_toast_face.visible = not look.is_empty()
	if not look.is_empty():
		_toast_face.set_look(look)
		_toast_face.talk(2.0)
	_toast_layer.visible = true
	# Долгие сообщения можно закрыть тапом, короткие пропускают тапы насквозь.
	var seconds: float = float(next[1])
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_STOP if seconds > 3.0 else Control.MOUSE_FILTER_IGNORE
	_toast_timer.start(seconds)


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
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_BUY
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_toast_layer.add_theme_stylebox_override("panel", style)
	add_child(_toast_layer)

	var toast_row := HBoxContainer.new()
	toast_row.add_theme_constant_override("separation", 16)
	toast_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(toast_row)
	_toast_face = BossPortrait.new()
	_toast_face.custom_minimum_size = Vector2(110, 110)
	_toast_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast_face.visible = false
	toast_row.add_child(_toast_face)
	_toast_label = _make_center_label("", 30, COLOR_INK)
	_display(_toast_label, 32, COLOR_INK)
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_row.add_child(_toast_label)

	_toast_layer.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and not event.pressed:
			_toast_timer.stop()
			_show_next_toast())
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
	_col(label, COLOR_GOLD)
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
	_set_toggle(_music_button, _music_on)
	_set_toggle(_sound_button, _sound_on)


func _show_page(page: int) -> void:
	_current_page = page
	if _mentor != null:
		_mentor.notify_page(page)
	if _staff_stale and (page == PAGE_DRIVERS or page == PAGE_UPGRADES):
		_rebuild_staff()
	if _coins_label != null:
		_refresh_page(page)
		_on_wear_changed()
		_on_shifts_changed()
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
		_col(label, tint)


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
	_col(label, color)
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
	_mark("tapline")
	var text := GameState.format_money(value)
	# Пока на экране та же строка, подпись не трогаем — иначе цифры двоятся.
	if _coins_label.text == text:
		return
	_coins_label.text = text
	# Доход капает каждый кадр. Перестраивать все меню так часто — тормоза на телефоне,
	# поэтому открытую вкладку обновляем 4 раза в секунду, остальные — когда их откроют.
	_mark("page")


# --- Плавность: тяжёлые обновления экрана по одному за кадр -------------------
## Сигналы игры только помечают, что пора обновить. Каждый кадр выполняется не больше
## одного обновления, и каждое — не чаще своего интервала. Так нет «тяжёлых» кадров,
## из-за которых картинка подёргивается.

const JOB_GAP := {
	"tapline": 0.25, "page": 0.25, "wear": 0.2, "shifts": 0.5, "city": 0.3,
	"staff": 0.0, "competitors": 0.25, "rate": 0.25,
}
var _dirty: Dictionary = {}
var _job_last: Dictionary = {}
var _job_order: Array = ["staff", "tapline", "rate", "wear", "page", "competitors", "shifts", "city"]
var _job_cursor: int = 0


func _mark(job: String) -> void:
	_dirty[job] = true


func _run_one_job() -> void:
	if _dirty.is_empty():
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	for step in _job_order.size():
		var job: String = _job_order[(_job_cursor + step) % _job_order.size()]
		if not _dirty.has(job):
			continue
		if now - float(_job_last.get(job, -100.0)) < float(JOB_GAP.get(job, 0.25)):
			continue
		_job_cursor = (_job_cursor + step + 1) % _job_order.size()
		_dirty.erase(job)
		_job_last[job] = now
		_do_job(job)
		return


func _do_job(job: String) -> void:
	match job:
		"tapline":
			_refresh_tap_line()
		"page":
			_refresh_page(_current_page)
		"wear":
			_on_wear_changed()
		"shifts":
			_on_shifts_changed()
		"city":
			_sync_city()
		"staff":
			_rebuild_staff()
		"competitors":
			if _current_page == PAGE_MARKET:
				_refresh_competitors()
			elif _current_page == PAGE_CITY:
				_refresh_districts()
		"rate":
			_refresh_rate_line()


func _refresh_page(page: int) -> void:
	match page:
		PAGE_TAP:
			_on_wear_changed()
		PAGE_UPGRADES:
			_refresh_upgrades()
			_refresh_staff_money()
			_on_wear_changed()
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
	_tap_label.text = "%s/с" % GameState.format_money(GameState.get_income_per_second())
	if _tap_hint != null:
		_tap_hint.text = "Тап по городу — заказ на %s" % GameState.format_money(GameState.get_tap_power())
	_refresh_market_share()


## Чип в шапке: город борьбы, сколько конкурентов выкуплено, полоска — текущая дуэль.
func _refresh_market_share() -> void:
	if GameState.get_front_island() == "":
		_share_label.text = "Острова %d/%d" % [GameState.get_captured_count(), GameState.get_regions().size()]
		return
	_share_label.text = "%s %d/%d" % [GameState.get_front_city(), GameState.get_city_owned_count(), GameState.get_competitors().size()]



func _refresh_meta_line() -> void:
	_reputation_label.text = "%.1f" % GameState.get_rating()
	_rep_label.text = GameState.format_number(float(GameState.reputation))
	_refresh_tab_badges()
	if _current_page == PAGE_CITY:
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
