extends Node
## Общее состояние игры.
## Экран только читает эти данные и слушает сигналы — сам экономику не считает.

## Монеты изменились.
signal coins_changed(coins: float)
## Сколько монет даёт один тап.
signal tap_power_changed(power: float)
## Купили улучшение или изменился его уровень.
signal upgrades_changed
## Изменилась команда водителей или кандидаты.
signal drivers_changed
## Изменился гараж: купили машину, обменяли или расширили.
signal garage_changed
## Изменились чистота или состояние машин.
signal wear_changed
## Изменились часы смен или рейтинг компании (раз в секунду и после «Сменить»).
signal shifts_changed
## Наняли, включили или выключили помощника.
signal helpers_changed
## Стали такси №1 на острове.
signal island_captured(island_id: String, text: String)
## Догнали соперника: он сдаётся и готов продаться.
signal rival_surrendered(competitor_id: String, text: String)
## Соперник ответил ударом.
signal rival_attacked(competitor_id: String, text: String)
## Сюжетная сцена босса: "intro" — знакомство, "half" — игрок догнал половину его силы.
signal rival_story(competitor_id: String, beat: String)
## Изменился пассивный доход в секунду.
signal income_changed(income: float)
## Пора показать окно «Пока вас не было».
signal offline_reward_ready
## Открыли район.
signal districts_changed
## Изменилась репутация.
signal reputation_changed(reputation: int)
## Открыли регион мира.
signal regions_changed
## Выкупили конкурента или он отказал.
signal competitors_changed
signal franchise_changed(franchise: float)
signal achievement_unlocked(title: String, body: String)
signal achievements_changed
## Сменилась машина игрока: арендовали, купили или пересели.
signal car_changed
## Игрок назвал компанию.
signal company_changed(company_name: String)

## Сколько монет даёт тап без улучшений.
const BASE_TAP_POWER: float = 1.0
const UPGRADES_PATH := "res://data/upgrades.json"
const DRIVERS_PATH := "res://data/drivers.json"
const CITIES_PATH := "res://data/cities.json"
const REGIONS_PATH := "res://data/regions.json"
const COMPETITORS_PATH := "res://data/competitors.json"
const ACHIEVEMENTS_PATH := "res://data/achievements.json"
const BALANCE_PATH := "res://data/balance.json"
const CARS_PATH := "res://data/cars.json"
const HELPERS_PATH := "res://data/helpers.json"
const MARKET_PATH := "res://data/market.json"
## Длина названия компании.
const COMPANY_NAME_MAX := 24
const DAILY_COINS := 250.0
## Сколько тапов нужно для +1 репутации.
const TAPS_PER_REPUTATION := 20
## Продавать можно, когда новая франшиза больше текущей хотя бы на 10%.
const FRANCHISE_MIN_STEP := 1.1
## Если кадр завис дольше секунды, не начисляем доход за всю паузу.
const MAX_INCOME_STEP := 1.0
const SAVE_PATH := "user://save.json"
const AUTOSAVE_SECONDS := 10.0
## Доход копится не дольше 8 часов отсутствия.
const MAX_OFFLINE_SECONDS := 8.0 * 60.0 * 60.0
## Короткий перезапуск не показывает окно.
const MIN_OFFLINE_SECONDS := 5

## Текущие монеты игрока.
var coins: float = 0.0

var _upgrade_defs: Array = []
## id улучшения -> сколько раз его купили.
var _upgrade_levels: Dictionary = {}
## Настройки водителей из data/drivers.json: имена, звёзды, черты.
var _staff: Dictionary = {}
## Машины в гараже для водителей: {"model", "clean", "health"}. clean и health — от 0 до 1.
var _garage: Array = []
## Сколько раз расширяли гараж.
var _garage_level: int = 0
## Нанятые водители: {"uid", "name", "stars", "trait"}.
var _team: Array = []
## Кандидаты на найм, в том же виде, но без uid.
var _candidates: Array = []
var _next_uid: int = 1
## Когда последний раз звали новых кандидатов (unix).
var _candidates_unix: int = 0
## Сколько вернули за старых водителей при переносе сохранения. Показываем один раз.
var _legacy_refund: float = 0.0
var _fleet_growth: float = 1.15
var _trade_in_share: float = 0.5
## Версия состава парка и команды и кэши, которые от неё зависят.
var _staff_version: int = 0
var _garage_cache: Array = []
var _garage_cache_key: String = ""
var _assign_cache: Dictionary = {}
var _assign_cache_key: String = ""
var _fleet_counts: Dictionary = {}
var _worst_index: int = -1
var _fleet_stats_key: String = ""
## Дела «раз в секунду», которые ещё не сделаны (по одному за кадр), и длина этой секунды.
var _tick_queue: Array = []
var _tick_seconds: float = 1.0
var _garage_start: int = 5
var _garage_expansions: Array = []
## Во сколько раз дороже каждое расширение гаража после списка из balance.json.
var _garage_expansion_growth: float = 100.0
## Франшиза = 1 + weight * корень(заработок всех забегов / reference). Из balance.json.
var _franchise_reference: float = 1e9
var _franchise_weight: float = 0.5
## Чистота и состояние своей машины, от 0 до 1.
var _my_clean: float = 1.0
var _my_health: float = 1.0
## Настройки износа из balance.json.
var _wear: Dictionary = {}
## Износ парка считаем раз в секунду, а не каждый кадр.
var _wear_left: float = 1.0
## Настройки смен и рейтинга из balance.json.
var _shift_cfg: Dictionary = {}
var _rating_cfg: Dictionary = {}
## Рейтинг компании, 1..5. Плавно идёт к оценке текущих поездок — как копятся отзывы.
var rating: float = 4.0
var _helper_defs: Array = []
## id помощника -> 1 нанят и работает, 0 нанят, но выключен. Нет ключа — не нанят.
var _helpers: Dictionary = {}
## Настройки рынка: реклама, пакости, характеры (data/market.json).
var _market: Dictionary = {}
## id конкурента -> [{"cut", "until"}]: временные удары по его силе.
var _rival_cuts: Dictionary = {}
## id конкурента -> постоянный множитель силы (переманенные водители).
var _rival_perm: Dictionary = {}
## id конкурента -> unix, до которого нельзя снова пакостить / предлагать выкуп.
var _trick_ready: Dictionary = {}
## id конкурента -> цена выкупа: он проиграл дуэль и ждёт, когда его купят.
var _surrendered: Dictionary = {}
## id конкурента -> сколько секунд игры с ним идёт дуэль (от этого он растёт).
var _rival_age: Dictionary = {}
## С кем шла дуэль в прошлую секунду: сменился соперник — заводим таймер его первого хода.
var _duel_rival: String = ""
## Секунд игры до следующего ответного хода соперника.
var _rival_attack_in: float = 0.0
## id конкурента -> {"intro": 1, "half": 1}: какие сцены босса игрок уже видел.
## Не сбрасывается при продаже компании, чтобы знакомства не повторялись.
var _story_seen: Dictionary = {}
## Текущая реклама: {"id", "until"}. Пусто — рекламы нет.
var _ad: Dictionary = {}
## id кампании за ролик -> unix, когда её снова можно запустить.
var _ad_ready: Dictionary = {}
## Прогресс дяди Буна: шаг обучения, включены ли советы. Хранит и меняет scripts/mentor.gd.
var mentor: Dictionary = {}
## id острова -> 1, если стали там такси №1. Захват открывает дорогу на следующий остров.
var _captured: Dictionary = {}
var _city_defs: Array = []
## id района -> 1, если район уже открыт.
var _opened_districts: Dictionary = {}
var _region_defs: Array = []
var _competitor_defs: Array = []
## id конкурента -> 1, если компания уже выкуплена.
var _owned_competitors: Dictionary = {}
## id региона -> 1, если регион уже открыт.
var _opened_regions: Dictionary = {}
## Репутация компании. Не копится сама: её каждый раз считает формула.
var reputation: int = 0
## Сколько раз нажали на такси за текущий забег.
var run_taps: int = 0
## Постоянный множитель. Переживает продажу компании.
var franchise: float = 1.0
## Монеты, полученные за текущий забег. Траты его не уменьшают.
var run_earned: float = 0.0
## Заработок за все забеги. Не сбрасывается продажей компании.
var lifetime_earned: float = 0.0
var _achievement_defs: Array = []
## id достижения -> 1, если награда уже выдана.
var _done_achievements: Dictionary = {}
## Номер суток unix. 0 значит награду ещё ни разу не забирали.
var _last_daily_day: int = 0
var _fresh_achievements: Array = []
var _income_per_second: float = 0.0
## Время последнего сохранения. От него считаем, сколько игра не работала.
var _last_exit_unix: int = 0
var _autosave_left: float = AUTOSAVE_SECONDS
## Награда за отсутствие. В монеты попадает только после кнопки «Забрать».
var _offline_coins: float = 0.0
var _offline_seconds: float = 0.0
var _offline_capped: bool = false
## Телефон свернули: пока игра на паузе, доход в _process не капает.
var _paused_in_background: bool = false
## Доля пассивного дохода, которая добавляется к каждому тапу.
var _tap_from_income: float = 0.01
## Доход в секунду, при котором доля мирового рынка становится 100%.
var _world_market_size: float = 600000000.0
## Какая доля обычного дохода капает, пока игра закрыта. 0.8 = 80%.
var _offline_income_rate: float = 0.8
var _car_defs: Array = []
## На какой машине игрок ездит сам. Первая в cars.json — стартовая.
var _car_id: String = ""
## Уровень линии тапа (0 — начало). Он же задаёт машину игрока.
var _tap_level: int = 0
## Цена первого уровня линии тапа.
var _tap_level_first_cost: float = 40.0
## Во сколько раз растёт тап за каждые TAP_STEPS уровней после последней машины.
var _tap_after_last_mult: float = 1.6
## Название компании. Пустое, пока игрок его не ввёл.
var company_name: String = ""


func _ready() -> void:
	_upgrade_defs = _read_json_array(UPGRADES_PATH)
	_staff = _read_json_dict(DRIVERS_PATH)
	_city_defs = _read_json_array(CITIES_PATH)
	_region_defs = _read_json_array(REGIONS_PATH)
	_competitor_defs = _read_json_array(COMPETITORS_PATH)
	_achievement_defs = _read_json_array(ACHIEVEMENTS_PATH)
	_car_defs = _read_json_array(CARS_PATH)
	_helper_defs = _read_json_array(HELPERS_PATH)
	_market = _read_json_dict(MARKET_PATH)
	_car_id = _start_car_id()
	_read_balance()
	load_game()
	_fill_candidates()
	_recalc_income()
	_note_progress()
	_announce_legacy_refund()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	garage_changed.emit()
	helpers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)
	car_changed.emit()
	company_changed.emit(company_name)


## Пассивный доход капает каждый кадр. Рядом тикает автосохранение.
func _process(delta: float) -> void:
	if _income_per_second > 0.0:
		var step: float = delta
		if step > MAX_INCOME_STEP:
			step = MAX_INCOME_STEP
		_gain_coins(_income_per_second * step)
		coins_changed.emit(coins)
	_tick_fleet_wear(minf(delta, MAX_INCOME_STEP))
	_autosave_left -= delta
	if _autosave_left <= 0.0:
		_autosave_left = AUTOSAVE_SECONDS
		save_game()


## Сворачивание, уход в фон и закрытие окна сразу пишут сохранение.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused_in_background = true
		save_game()
		return
	if what == NOTIFICATION_APPLICATION_RESUMED and _paused_in_background:
		_paused_in_background = false
		# Пока игра была свёрнута, _process не шёл. Догоняем это время один раз.
		_refresh_offline_reward()
		if _fold_offline_dust():
			coins_changed.emit(coins)
		if has_offline_reward():
			offline_reward_ready.emit()
		save_game()
		return
	if what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()


## Игрок нажал на такси. Возвращает, сколько монет добавилось.
func tap() -> float:
	var gained: float = get_tap_power()
	_gain_coins(gained)
	_wear_my_car()
	run_taps += 1
	_sync_reputation()
	_note_progress()
	coins_changed.emit(coins)
	return gained


## Плоская часть тапа из улучшений. Множители районов на неё ещё не надеты.
func get_flat_tap() -> float:
	var power: float = BASE_TAP_POWER
	for raw: Variant in _upgrade_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var upgrade_id: String = str(info.get("id", ""))
		var bonus: float = float(info.get("tap_bonus", 0))
		power += bonus * float(get_upgrade_level(upgrade_id))
	return power


## Сила тапа: улучшения × машина (минус аренда) × множители плюс доля дохода в секунду.
func get_tap_power() -> float:
	var ride: float = get_ride_value() * get_my_condition_mult()
	return ride + get_income_per_second() * _tap_from_income


## Сколько приносит поездка на исправной чистой машине (после аренды и множителей).
func get_ride_value() -> float:
	return get_flat_tap() * get_car_tap_mult() * (1.0 - get_rent_share()) * get_income_multiplier()


# --- Машина игрока ---------------------------------------------------------

## Список машин из data/cars.json, от худшей к лучшей.
func get_cars() -> Array:
	return _car_defs


func get_car_id() -> String:
	return _car_id


func get_car_info() -> Dictionary:
	return _find_def(_car_defs, _car_id)


## Сколько машин пройдено по линии тапа (стартовая не считается). Для достижений.
func get_owned_car_count() -> int:
	return _car_index_for_level(_tap_level)


## Во сколько раз машина умножает доход с тапа: множитель текущего уровня линии.
func get_car_tap_mult() -> float:
	return get_level_tap_mult(_tap_level)


## Аренды больше нет: весь доход с тапа ваш.
func get_rent_share() -> float:
	return 0.0


# --- Линия тапа: копим, покупаем уровень, тап дороже -------------------------
## Уровни идут по машинам cars.json: между соседними машинами TAP_STEPS шагов.
## Каждые TAP_STEPS уровней игрок пересаживается в следующую машину.
## После последней машины уровни продолжаются бесконечно с тем же ростом.

const TAP_STEPS := 3


func get_tap_level() -> int:
	return _tap_level


func _car_index_for_level(level: int) -> int:
	return mini(int(level / TAP_STEPS), maxi(0, _car_defs.size() - 1))


func _car_value(index: int, key: String) -> float:
	return float(_car_defs[clampi(index, 0, _car_defs.size() - 1)].get(key, 0))


## Значение на уровне по «опорам» машин: между машинами — плавный геометрический шаг,
## после последней — тот же рост, что между двумя последними.
func _level_curve(level: int, key: String) -> float:
	var last: int = _car_defs.size() - 1
	if last <= 0:
		return 1.0
	var index: int = int(level / TAP_STEPS)
	var part: float = float(level % TAP_STEPS) / float(TAP_STEPS)
	if index >= last:
		var ratio: float = _car_value(last, key) / maxf(0.000001, _car_value(last - 1, key))
		# После лимузина тап растёт медленнее: иначе линия обгоняет всю остальную игру.
		if key == "tap_mult":
			ratio = _tap_after_last_mult
		return _car_value(last, key) * pow(ratio, float(level - last * TAP_STEPS) / float(TAP_STEPS))
	var from: float = _car_value(index, key)
	var to: float = _car_value(index + 1, key)
	return from * pow(to / maxf(0.000001, from), part)


func get_level_tap_mult(level: int) -> float:
	return maxf(1.0, _level_curve(level, "tap_mult"))


## Сколько стоит следующий уровень линии.
func get_tap_level_cost() -> float:
	var next: int = _tap_level + 1
	if next < TAP_STEPS:
		# Первые шаги до первой машины: от tap_level_first_cost до её цены.
		var target: float = _car_value(1, "buy_cost")
		var part: float = float(next - 1) / float(TAP_STEPS - 1)
		return ceilf(_tap_level_first_cost * pow(target / _tap_level_first_cost, part))
	return ceilf(_level_curve(next, "buy_cost"))


## Машина, в которую пересядем на следующем уровне. Пусто — машина та же.
func get_next_level_car() -> String:
	var now: int = _car_index_for_level(_tap_level)
	var next: int = _car_index_for_level(_tap_level + 1)
	return str(_car_defs[next].get("id", "")) if next != now else ""


func can_buy_tap_level() -> bool:
	return coins + 0.001 >= get_tap_level_cost()


func buy_tap_level() -> bool:
	if not can_buy_tap_level():
		return false
	coins = maxf(0.0, coins - get_tap_level_cost())
	_tap_level += 1
	var car_id: String = str(_car_defs[_car_index_for_level(_tap_level)].get("id", _car_id))
	if car_id != _car_id:
		_car_id = car_id
		_my_clean = 1.0
		_my_health = 1.0
	_after_car_change()
	return true


func _after_car_change() -> void:
	_my_clean = 1.0
	_my_health = 1.0
	wear_changed.emit()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	car_changed.emit()
	_note_progress()
	save_game()


func _start_car_id() -> String:
	if _car_defs.is_empty() or typeof(_car_defs[0]) != TYPE_DICTIONARY:
		return ""
	var first: Dictionary = _car_defs[0]
	return str(first.get("id", ""))


## Место машины в списке. -1, если такой нет.
func _car_index(car_id: String) -> int:
	for index in _car_defs.size():
		var raw: Variant = _car_defs[index]
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("id", "")) == car_id:
			return index
	return -1


func _reset_car() -> void:
	_my_clean = 1.0
	_my_health = 1.0
	_car_id = _start_car_id()
	_tap_level = 0


# --- Награды дяди Буна ------------------------------------------------------

## Награда за задание обучения: деньги сразу в кошелёк.
func grant_reward(amount: float) -> void:
	if amount <= 0.0:
		return
	_gain_coins(amount)
	coins_changed.emit(coins)
	_note_progress()
	save_game()


# --- Название компании -----------------------------------------------------

func has_company_name() -> bool:
	return company_name != ""


## Обрезает пробелы и длину. Возвращает false, если имя пустое.
func set_company_name(raw_name: String) -> bool:
	var clean: String = raw_name.strip_edges().substr(0, COMPANY_NAME_MAX)
	if clean == "":
		return false
	company_name = clean
	company_changed.emit(company_name)
	save_game()
	return true


## Список улучшений из data/upgrades.json. Экран только читает его.
func get_upgrades() -> Array:
	return _upgrade_defs


func get_upgrade_level(upgrade_id: String) -> int:
	return int(_upgrade_levels.get(upgrade_id, 0))


## Цена следующего уровня. Каждый уровень дороже предыдущего примерно в 1.15 раза.
func get_upgrade_cost(upgrade_id: String) -> float:
	var info: Dictionary = _find_def(_upgrade_defs, upgrade_id)
	if info.is_empty():
		return 0.0
	var base_cost: float = float(info.get("base_cost", 1))
	var growth: float = float(info.get("cost_growth", 1.15))
	return _scaled_cost(base_cost, growth, get_upgrade_level(upgrade_id))


func can_buy_upgrade(upgrade_id: String) -> bool:
	var cost: float = get_upgrade_cost(upgrade_id)
	return cost > 0.0 and coins + 0.001 >= cost


## Списывает монеты и поднимает уровень. Возвращает false, если монет не хватает.
func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	coins -= get_upgrade_cost(upgrade_id)
	if coins < 0.0:
		coins = 0.0
	_upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	_note_progress()
	save_game()
	return true


# --- Гараж -----------------------------------------------------------------

## Машины в гараже, от лучшей модели к худшей. Карточки те же, что внутри: их можно менять.
func get_garage() -> Array:
	var key: String = _staff_key()
	if _garage_cache_key == key:
		return _garage_cache
	var sorted: Array = _garage.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		return get_car_driver_income(str(a.get("model", ""))) > get_car_driver_income(str(b.get("model", ""))))
	_garage_cache = sorted
	_garage_cache_key = key
	return sorted


## Состав парка и команды. Пока он тот же, сортировки и «кто на какой машине» берём из кэша —
## их считают много раз в секунду, а пересортировка каждый раз давала рывки.
func _staff_key() -> String:
	return "%d/%d/%d" % [_staff_version, _garage.size(), _team.size()]


func _staff_touched() -> void:
	_staff_version += 1


## Мест в гаражах: родной гараж с расширениями плюс свой гараж на каждом открытом острове.
func get_garage_capacity() -> int:
	return get_home_garage_capacity() + get_island_garage_slots()


func get_home_garage_capacity() -> int:
	var capacity: int = _garage_start
	for index in _garage_level:
		capacity += int(_expansion_at(index).get("add", 0))
	return capacity


## Места в гаражах на открытых островах (кроме родного).
func get_island_garage_slots() -> int:
	var slots: int = 0
	for raw: Variant in _region_defs:
		if typeof(raw) == TYPE_DICTIONARY and not bool(raw.get("home", false)) and is_region_open(str(raw.get("id", ""))):
			slots += int(raw.get("garage_slots", 0))
	return slots


func is_garage_full() -> bool:
	return _garage.size() >= get_garage_capacity()


## Следующее расширение гаража. Лимита нет: после расширений из balance.json
## каждое следующее даёт столько же мест и стоит в garage_expansion_growth раз дороже.
func get_next_expansion() -> Dictionary:
	return _expansion_at(_garage_level)


func _expansion_at(index: int) -> Dictionary:
	if _garage_expansions.is_empty():
		return {"cost": 4000.0 * pow(_garage_expansion_growth, index), "add": 5}
	if index < _garage_expansions.size():
		var step: Variant = _garage_expansions[index]
		return step if typeof(step) == TYPE_DICTIONARY else {}
	var last: Dictionary = _garage_expansions[_garage_expansions.size() - 1]
	var extra: int = index - _garage_expansions.size() + 1
	return {
		"cost": floorf(float(last.get("cost", 0)) * pow(_garage_expansion_growth, extra)),
		"add": int(last.get("add", 5)),
	}


func can_expand_garage() -> bool:
	var step: Dictionary = get_next_expansion()
	return not step.is_empty() and coins + 0.001 >= float(step.get("cost", 0))


func expand_garage() -> bool:
	if not can_expand_garage():
		return false
	coins = maxf(0.0, coins - float(get_next_expansion().get("cost", 0)))
	_garage_level += 1
	_after_staff_change()
	return true


## Сколько базовой выручки в секунду даёт машина водителю (без звёзд и множителей).
func get_car_driver_income(car_id: String) -> float:
	return maxf(0.0, float(_find_def(_car_defs, car_id).get("driver_income", 0)))


func get_fleet_count(car_id: String) -> int:
	_refresh_fleet_stats()
	return int(_fleet_counts.get(car_id, 0))


## Сколько машин каждой модели и какая худшая — считаем один раз на состав парка.
func _refresh_fleet_stats() -> void:
	var key: String = _staff_key()
	if _fleet_stats_key == key:
		return
	_fleet_stats_key = key
	_fleet_counts.clear()
	_worst_index = -1
	for index in _garage.size():
		var model: String = str(_garage[index].get("model", ""))
		_fleet_counts[model] = int(_fleet_counts.get(model, 0)) + 1
		if _worst_index < 0 or get_car_driver_income(model) < get_car_driver_income(str(_garage[_worst_index].get("model", ""))):
			_worst_index = index


## Модель самой слабой машины гаража — её отдают в обмен, когда места нет.
func get_worst_garage_car() -> String:
	var index: int = _worst_garage_index()
	return "" if index < 0 else str(_garage[index].get("model", ""))


func _worst_garage_index() -> int:
	_refresh_fleet_stats()
	return _worst_index


func get_trade_in_value(car_id: String) -> float:
	return floorf(maxf(0.0, float(_find_def(_car_defs, car_id).get("buy_cost", 0))) * _trade_in_share)


## Цена машины в парк. Каждая следующая такая же — дороже.
## Когда гараж полон, из цены вычитается обмен слабой машины.
func get_fleet_cost(car_id: String) -> float:
	var info: Dictionary = _find_def(_car_defs, car_id)
	var price: float = _scaled_cost(float(info.get("buy_cost", 0)), _fleet_growth, get_fleet_count(car_id))
	if is_garage_full():
		price = maxf(1.0, price - get_trade_in_value(get_worst_garage_car()))
	return price


func can_buy_fleet(car_id: String) -> bool:
	if _car_index(car_id) <= 0:
		return false
	if is_garage_full():
		var worst: String = get_worst_garage_car()
		if worst == "" or get_car_driver_income(car_id) <= get_car_driver_income(worst):
			return false
	return coins + 0.001 >= get_fleet_cost(car_id)


## Покупка в парк. Если гараж полон — самая слабая машина уходит в обмен.
func buy_fleet(car_id: String) -> bool:
	if not can_buy_fleet(car_id):
		return false
	coins = maxf(0.0, coins - get_fleet_cost(car_id))
	if is_garage_full():
		_garage.remove_at(_worst_garage_index())
	_garage.append(_new_car(car_id))
	_after_staff_change()
	return true


## За сколько можно продать машину из гаража: половина базовой цены (как при обмене).
func get_sell_value(car_id: String) -> float:
	return get_trade_in_value(car_id)


## Продать одну машину этой модели. Сначала уходит свободная (без водителя),
## среди них — самая потрёпанная. Возвращает вырученные деньги, 0 — продать нечего.
func sell_garage_car(car_id: String) -> float:
	var busy: Array = get_assignments().values()
	var best: int = -1
	var best_free: bool = false
	for index in _garage.size():
		var car: Dictionary = _garage[index]
		if str(car.get("model", "")) != car_id:
			continue
		var free: bool = not busy.any(func(other: Variant) -> bool: return is_same(other, car))
		var better: bool = best < 0 or (free and not best_free)
		if not better and free == best_free:
			better = float(car.get("health", 1)) < float(_garage[best].get("health", 1))
		if better:
			best = index
			best_free = free
	if best < 0:
		return 0.0
	var value: float = get_sell_value(car_id)
	_garage.remove_at(best)
	_gain_coins(value)
	_after_staff_change()
	return value


## Сколько машин этой модели сейчас без водителя.
func get_free_count(car_id: String) -> int:
	var count: int = 0
	for car: Variant in get_free_garage_cars():
		if str(car.get("model", "")) == car_id:
			count += 1
	return count


# --- Износ: мойка и ремонт ----------------------------------------------------

func _new_car(model: String) -> Dictionary:
	return {"model": model, "clean": 1.0, "health": 1.0}


func _wear_value(key: String, fallback: float) -> float:
	return float(_wear.get(key, fallback))


func is_broken(health: float) -> bool:
	return health < _wear_value("broken_below", 0.1)


## Во сколько раз грязь и поломка режут доход. 1 — всё в порядке.
## Грязь: ниже 50% доход плавно падает до dirty_min_mult.
## Состояние: ниже 50% падает до worn_min_mult, а ниже broken_below машина сломана.
func get_condition_mult(clean: float, health: float, broken_mult: float) -> float:
	var clean_mult: float = 1.0
	if clean < 0.5:
		clean_mult = lerpf(_wear_value("dirty_min_mult", 0.75), 1.0, clampf(clean / 0.5, 0.0, 1.0))
	var health_mult: float = 1.0
	var broken: float = _wear_value("broken_below", 0.1)
	if is_broken(health):
		health_mult = broken_mult
	elif health < 0.5:
		health_mult = lerpf(_wear_value("worn_min_mult", 0.6), 1.0, (health - broken) / (0.5 - broken))
	return clean_mult * health_mult


## Сломанная машина водителя стоит и ничего не приносит.
func get_fleet_condition_mult(car: Dictionary) -> float:
	if car.is_empty():
		return 0.0
	return get_condition_mult(float(car.get("clean", 1)), float(car.get("health", 1)), 0.0)


## Своя сломанная машина всё равно едет, хоть и еле-еле: игрок не застрянет без денег.
func get_my_condition_mult() -> float:
	return get_condition_mult(_my_clean, _my_health, _wear_value("player_broken_mult", 0.3))


func get_my_clean() -> float:
	return _my_clean


func get_my_health() -> float:
	return _my_health


## Мойка своей машины: столько тапов исправной машины, сколько стоит полная мойка, по доле грязи.
func get_my_wash_cost() -> float:
	return _service_cost(get_ride_value() * _wear_value("player_wash_taps", 20), 1.0 - _my_clean)


func get_my_repair_cost() -> float:
	return _service_cost(get_ride_value() * _wear_value("player_repair_taps", 80), 1.0 - _my_health)


func can_wash_my_car() -> bool:
	return _my_clean < 0.999 and coins + 0.001 >= get_my_wash_cost()


func can_repair_my_car() -> bool:
	return _my_health < 0.999 and coins + 0.001 >= get_my_repair_cost()


func wash_my_car() -> bool:
	if not can_wash_my_car():
		return false
	coins = maxf(0.0, coins - get_my_wash_cost())
	_my_clean = 1.0
	_after_service()
	return true


func repair_my_car() -> bool:
	if not can_repair_my_car():
		return false
	coins = maxf(0.0, coins - get_my_repair_cost())
	_my_health = 1.0
	_after_service()
	return true


## Мойка всего парка: у каждой машины своя цена — по её выручке и грязи.
func get_fleet_wash_cost() -> float:
	var total: float = 0.0
	for car: Variant in _garage:
		var full: float = get_car_driver_income(str(car.get("model", ""))) * _wear_value("fleet_wash_seconds", 20)
		total += _service_cost(full, 1.0 - float(car.get("clean", 1)), 0.0)
	return ceilf(total)


func get_fleet_repair_cost() -> float:
	var total: float = 0.0
	for car: Variant in _garage:
		var full: float = get_car_driver_income(str(car.get("model", ""))) * _wear_value("fleet_repair_seconds", 150)
		total += _service_cost(full, 1.0 - float(car.get("health", 1)), 0.0)
	return ceilf(total)


func can_wash_fleet() -> bool:
	var cost: float = get_fleet_wash_cost()
	return cost > 0.0 and coins + 0.001 >= cost


func can_repair_fleet() -> bool:
	var cost: float = get_fleet_repair_cost()
	return cost > 0.0 and coins + 0.001 >= cost


func wash_fleet() -> bool:
	if not can_wash_fleet():
		return false
	coins = maxf(0.0, coins - get_fleet_wash_cost())
	for car: Variant in _garage:
		car["clean"] = 1.0
	_recalc_income()
	_after_service()
	return true


func repair_fleet() -> bool:
	if not can_repair_fleet():
		return false
	coins = maxf(0.0, coins - get_fleet_repair_cost())
	for car: Variant in _garage:
		car["health"] = 1.0
	_recalc_income()
	_after_service()
	return true


## Средние чистота и состояние парка, для шапки вкладки. Пустой гараж — 1.
func get_fleet_average(key: String) -> float:
	if _garage.is_empty():
		return 1.0
	var total: float = 0.0
	for car: Variant in _garage:
		total += float(car.get(key, 1))
	return total / float(_garage.size())


func get_broken_count() -> int:
	var count: int = 0
	for car: Variant in _garage:
		if is_broken(float(car.get("health", 1))):
			count += 1
	return count


## Цена услуги по доле работы. Совсем чистое и целое ничего не стоит.
func _service_cost(full_cost: float, share: float, minimum: float = 1.0) -> float:
	if share <= 0.001:
		return 0.0
	return maxf(minimum, ceilf(full_cost * clampf(share, 0.0, 1.0)))


func _after_service() -> void:
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	wear_changed.emit()
	save_game()


func _wear_my_car() -> void:
	_my_clean = maxf(0.0, _my_clean - _wear_value("tap_clean", 0.0015))
	_my_health = maxf(0.0, _my_health - _wear_value("tap_health", 0.0003))
	tap_power_changed.emit(get_tap_power())
	wear_changed.emit()


## Машины с водителем пачкаются и ломаются, пока работают. Только пока игра открыта.
## Раз в секунду: достижения, смены, помощники, рынок, износ парка.
## Чтобы не было одного «тяжёлого» кадра, эти дела раскладываются по соседним кадрам.
func _tick_fleet_wear(step: float) -> void:
	if not _tick_queue.is_empty():
		_run_tick_part(str(_tick_queue.pop_front()))
		return
	_wear_left -= step
	if _wear_left > 0.0:
		return
	_tick_seconds = 1.0 - _wear_left
	_wear_left = 1.0
	_tick_queue = ["progress", "shifts", "helpers", "market", "wear"]
	_run_tick_part(str(_tick_queue.pop_front()))


## Целая игровая секунда разом (для тестов и догонялок).
func _tick_second(seconds: float = 1.0) -> void:
	_tick_queue.clear()
	_tick_seconds = seconds
	for part: String in ["progress", "shifts", "helpers", "market", "wear"]:
		_run_tick_part(part)


func _run_tick_part(part: String) -> void:
	match part:
		"progress":
			_note_progress()
		"shifts":
			_tick_shifts(_tick_seconds)
		"helpers":
			_run_helpers(_tick_seconds)
		"market":
			_tick_market(_tick_seconds)
		"wear":
			_wear_fleet(_tick_seconds)


func _wear_fleet(seconds: float) -> void:
	if _team.is_empty():
		return
	var clean_rate: float = _wear_value("fleet_clean_per_second", 0.0016667)
	var health_rate: float = _wear_value("fleet_health_per_second", 0.00033333)
	for car: Variant in get_assignments().values():
		car["clean"] = maxf(0.0, float(car.get("clean", 1)) - clean_rate * seconds)
		car["health"] = maxf(0.0, float(car.get("health", 1)) - health_rate * seconds)
	_recalc_income()
	tap_power_changed.emit(get_tap_power())
	wear_changed.emit()


# --- Смены и рейтинг -----------------------------------------------------------

func _shift_value(key: String, fallback: float) -> float:
	return float(_shift_cfg.get(key, fallback))


func _rating_value(key: String, fallback: float) -> float:
	return float(_rating_cfg.get(key, fallback))


func get_shift_hours() -> float:
	return _shift_value("shift_hours", 8)


func get_driver_hours(person: Dictionary) -> float:
	return maxf(0.0, float(person.get("hours", 0)))


## 0 — свежий или в пределах смены, 1 — валится с ног.
func get_tiredness(person: Dictionary) -> float:
	var shift: float = get_shift_hours()
	var exhausted: float = maxf(shift + 0.1, _shift_value("exhausted_hours", 14))
	return clampf((get_driver_hours(person) - shift) / (exhausted - shift), 0.0, 1.0)


## Уставший водитель возит медленнее: доход падает до tired_min_mult.
func get_tired_mult(person: Dictionary) -> float:
	return lerpf(1.0, _shift_value("tired_min_mult", 0.5), get_tiredness(person))


## Оценка одной поездки, 1..5: грязь, поломки, усталость, характер водителя.
func get_ride_rating(clean: float, health: float, person: Dictionary = {}) -> float:
	var value: float = _rating_value("base", 5)
	if clean < 0.5:
		value -= _rating_value("dirty_penalty", 1.5) * (1.0 - clean / 0.5)
	if is_broken(health):
		value -= _rating_value("broken_penalty", 3)
	elif health < 0.5:
		value -= _rating_value("worn_penalty", 1.5) * (1.0 - health / 0.5)
	if not person.is_empty():
		value -= _rating_value("tired_penalty", 2.5) * get_tiredness(person)
		value += float(get_trait_info(str(person.get("trait", ""))).get("rating_bonus", 0))
		value += float(get_star_info(int(person.get("stars", 1))).get("rating_bonus", 0))
	return clampf(value, 1.0, 5.0)


## Куда сейчас тянутся отзывы: средняя оценка своей поездки и всех работающих водителей.
func get_rating_target() -> float:
	var total: float = get_ride_rating(_my_clean, _my_health)
	var count: int = 1
	var cars: Dictionary = get_assignments()
	for raw: Variant in _team:
		var person: Dictionary = raw
		var car: Dictionary = cars.get(int(person.get("uid", 0)), {})
		if car.is_empty():
			continue
		total += get_ride_rating(float(car.get("clean", 1)), float(car.get("health", 1)), person)
		count += 1
	return total / float(count)


func get_rating() -> float:
	return rating


## 4 звезды — обычный доход. Каждая звезда выше или ниже — ±mult_per_star.
func get_rating_multiplier() -> float:
	return maxf(0.1, 1.0 + (rating - 4.0) * _rating_value("mult_per_star", 0.15))


func can_change_shift(uid: int) -> bool:
	var person: Dictionary = _find_person(uid)
	return not person.is_empty() and get_driver_hours(person) >= 0.5


## Выходит сменщик: часы водителя обнуляются.
func change_shift(uid: int) -> bool:
	if not can_change_shift(uid):
		return false
	_find_person(uid)["hours"] = 0.0
	_after_shift_change()
	return true


func get_tired_count() -> int:
	var count: int = 0
	for person: Variant in _team:
		if get_driver_hours(person) >= get_shift_hours():
			count += 1
	return count


## Сменить всех, кто отработал смену.
func change_tired_shifts() -> int:
	var changed: int = 0
	for person: Variant in _team:
		if get_driver_hours(person) >= get_shift_hours():
			person["hours"] = 0.0
			changed += 1
	if changed > 0:
		_after_shift_change()
	return changed


func _find_person(uid: int) -> Dictionary:
	for person: Variant in _team:
		if int(person.get("uid", 0)) == uid:
			return person
	return {}


func _after_shift_change() -> void:
	_recalc_income()
	tap_power_changed.emit(get_tap_power())
	shifts_changed.emit()
	save_game()


## Раз в секунду: часы идут у тех, кто за рулём, рейтинг плавно тянется к оценке поездок.
func _tick_shifts(seconds: float) -> void:
	var hour: float = maxf(1.0, _shift_value("hour_seconds", 60))
	var cars: Dictionary = get_assignments()
	for person: Variant in _team:
		if cars.has(int(person.get("uid", 0))):
			person["hours"] = get_driver_hours(person) + seconds / hour
	var target: float = get_rating_target()
	var step: float = _rating_value("ease_per_second", 0.02) * seconds
	var before: float = rating
	rating = move_toward(rating, target, step)
	if not is_equal_approx(before, rating):
		_recalc_income()
		tap_power_changed.emit(get_tap_power())
		_note_progress()
	shifts_changed.emit()


# --- Помощники ----------------------------------------------------------------

func get_helpers() -> Array:
	return _helper_defs


func is_helper_hired(helper_id: String) -> bool:
	return _helpers.has(helper_id)


func is_helper_on(helper_id: String) -> bool:
	return int(_helpers.get(helper_id, 0)) > 0


func get_helper_cost(helper_id: String) -> float:
	return maxf(0.0, float(_find_def(_helper_defs, helper_id).get("cost", 0)))


func get_hired_helper_count() -> int:
	return _helpers.size()


func can_hire_helper(helper_id: String) -> bool:
	if is_helper_hired(helper_id) or _find_def(_helper_defs, helper_id).is_empty():
		return false
	return coins + 0.001 >= get_helper_cost(helper_id)


func hire_helper(helper_id: String) -> bool:
	if not can_hire_helper(helper_id):
		return false
	coins = maxf(0.0, coins - get_helper_cost(helper_id))
	_helpers[helper_id] = 1
	_after_helpers_change()
	return true


## Включить или выключить нанятого помощника. Повторно платить не нужно.
func set_helper_on(helper_id: String, on: bool) -> bool:
	if not is_helper_hired(helper_id):
		return false
	_helpers[helper_id] = 1 if on else 0
	_after_helpers_change()
	return true


## Какую долю дохода водителей забирают включённые помощники.
func get_helper_fee_share() -> float:
	var total: float = 0.0
	for raw: Variant in _helper_defs:
		if typeof(raw) == TYPE_DICTIONARY and is_helper_on(str(raw.get("id", ""))):
			total += float(raw.get("fee_share", 0))
	return clampf(total, 0.0, 0.9)


## Сколько дохода в секунду уходит помощникам.
func get_helper_fee_per_second() -> float:
	var share: float = get_helper_fee_share()
	if share >= 1.0:
		return 0.0
	return get_income_per_second() / (1.0 - share) * share


## Доля обычного дохода, которая капает без игрока. Диспетчер поднимает её.
func get_offline_rate() -> float:
	var rate: float = _offline_income_rate
	if is_helper_on("dispatcher"):
		rate += float(_find_def(_helper_defs, "dispatcher").get("offline_bonus", 0))
	return clampf(rate, 0.0, 1.0)


func _after_helpers_change() -> void:
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	helpers_changed.emit()
	_note_progress()
	save_game()


## Раз в секунду: мойщик моет, механик чинит одну машину, диспетчер меняет смены.
func _run_helpers(seconds: float) -> void:
	var touched: bool = false
	if is_helper_on("washer"):
		if _my_clean < 0.5:
			_my_clean = 1.0
			touched = true
		for car: Variant in _garage:
			if float(car.get("clean", 1)) < 0.5:
				car["clean"] = 1.0
				touched = true
	if is_helper_on("mechanic"):
		touched = _mechanic_step(seconds) or touched
	if is_helper_on("dispatcher"):
		for person: Variant in _team:
			if get_driver_hours(person) >= get_shift_hours():
				person["hours"] = 0.0
				touched = true
	if touched:
		_recalc_income()
		tap_power_changed.emit(get_tap_power())
		wear_changed.emit()


## Механик берёт самую изношенную машину (свою или из парка) ниже 60% и подтягивает её.
func _mechanic_step(seconds: float) -> bool:
	var speed: float = float(_find_def(_helper_defs, "mechanic").get("repair_per_second", 0.01)) * seconds
	var worst: Dictionary = {}
	var worst_health: float = 0.6
	for car: Variant in _garage:
		var health: float = float(car.get("health", 1))
		if health < worst_health:
			worst = car
			worst_health = health
	if _my_health < worst_health:
		_my_health = minf(1.0, _my_health + speed)
		return true
	if worst.is_empty():
		return false
	worst["health"] = minf(1.0, worst_health + speed)
	return true


# --- Водители ----------------------------------------------------------------

func get_team() -> Array:
	return _team


func get_candidates() -> Array:
	return _candidates


func get_star_info(stars: int) -> Dictionary:
	for raw: Variant in _staff.get("stars", []):
		if typeof(raw) == TYPE_DICTIONARY and int(raw.get("stars", 0)) == stars:
			return raw
	return {}


func get_trait_info(trait_id: String) -> Dictionary:
	return _find_def(_staff.get("traits", []), trait_id)


## Цена найма: подъёмные по звёздам, каждый следующий водитель дороже.
func get_hire_cost(person: Dictionary) -> float:
	var base: float = float(get_star_info(int(person.get("stars", 1))).get("hire_cost", 40))
	return _scaled_cost(base, float(_staff.get("hire_growth", 1.5)), _team.size())


## Доля дохода, которую водитель забирает себе.
func get_salary_share(person: Dictionary) -> float:
	var share: float = float(get_star_info(int(person.get("stars", 1))).get("salary", 0.2))
	share += float(get_trait_info(str(person.get("trait", ""))).get("salary_bonus", 0))
	return clampf(share, 0.0, 0.9)


## Насколько водитель лучше обычного: звёзды и черта характера.
func get_driver_power(person: Dictionary) -> float:
	var mult: float = float(get_star_info(int(person.get("stars", 1))).get("income_mult", 1))
	mult *= 1.0 + float(get_trait_info(str(person.get("trait", ""))).get("income_bonus", 0))
	return maxf(0.0, mult)


## Машины без водителя, от лучшей к худшей.
func get_free_garage_cars() -> Array:
	var busy: Array = get_assignments().values()
	var free: Array = []
	for car: Variant in get_garage():
		if not busy.any(func(other: Variant) -> bool: return is_same(other, car)):
			free.append(car)
	return free


func has_free_car() -> bool:
	return _garage.size() > _team.size()


func can_hire(index: int) -> bool:
	if index < 0 or index >= _candidates.size() or not has_free_car():
		return false
	return coins + 0.001 >= get_hire_cost(_candidates[index])


func hire(index: int) -> bool:
	if not can_hire(index):
		return false
	var person: Dictionary = _candidates[index].duplicate()
	coins = maxf(0.0, coins - get_hire_cost(person))
	person["uid"] = _next_uid
	person["hours"] = 0.0
	_next_uid += 1
	_team.append(person)
	_candidates[index] = _make_candidate()
	_after_staff_change()
	return true


func fire(uid: int) -> bool:
	for index in _team.size():
		if int(_team[index].get("uid", 0)) == uid:
			_team.remove_at(index)
			_after_staff_change()
			return true
	return false


## Через сколько секунд можно позвать новых кандидатов. 0 — уже можно.
func get_refresh_left() -> int:
	var wait: int = int(_staff.get("refresh_seconds", 60))
	var passed: int = int(Time.get_unix_time_from_system()) - _candidates_unix
	return clampi(wait - passed, 0, wait)


func refresh_candidates() -> bool:
	if get_refresh_left() > 0:
		return false
	_candidates.clear()
	_fill_candidates()
	_candidates_unix = int(Time.get_unix_time_from_system())
	drivers_changed.emit()
	save_game()
	return true


## Кто на какой машине: сильнейшим водителям — лучшие машины.
## Возвращает uid -> карточку машины из гаража.
func get_assignments() -> Dictionary:
	var key: String = _staff_key()
	if _assign_cache_key == key:
		return _assign_cache
	var people: Array = _team.duplicate()
	people.sort_custom(func(a: Variant, b: Variant) -> bool:
		return get_driver_power(a) > get_driver_power(b))
	var cars: Array = get_garage()
	var result: Dictionary = {}
	for index in mini(people.size(), cars.size()):
		result[int(people[index].get("uid", 0))] = cars[index]
	_assign_cache = result
	_assign_cache_key = key
	return result


## Чистый доход водителя в секунду на исправной чистой машине этой модели.
func get_driver_net(person: Dictionary, car_id: String) -> float:
	var gross: float = get_car_driver_income(car_id) * get_driver_power(person)
	return gross * (1.0 - get_salary_share(person)) * get_income_multiplier()


## То же, но с учётом грязи и поломок конкретной машины.
func get_driver_net_on(person: Dictionary, car: Dictionary) -> float:
	var model: String = str(car.get("model", ""))
	return get_driver_net(person, model) * get_fleet_condition_mult(car) * get_tired_mult(person)


## Сколько в секунду уходит на зарплаты.
func get_salary_per_second() -> float:
	var total: float = 0.0
	var cars: Dictionary = get_assignments()
	for raw: Variant in _team:
		var person: Dictionary = raw
		var car: Dictionary = cars.get(int(person.get("uid", 0)), {})
		var gross: float = get_car_driver_income(str(car.get("model", ""))) * get_driver_power(person)
		total += gross * get_salary_share(person) * get_fleet_condition_mult(car) * get_tired_mult(person)
	return total * get_income_multiplier()


func _after_staff_change() -> void:
	_staff_touched()
	_recalc_income()
	_sync_reputation()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	garage_changed.emit()
	drivers_changed.emit()
	_note_progress()
	save_game()


func _fill_candidates() -> void:
	var wanted: int = maxi(1, int(_staff.get("candidates", 3)))
	while _candidates.size() < wanted:
		_candidates.append(_make_candidate())


## Случайный человек: имя без повторов, звёзды по шансам, случайная черта.
func _make_candidate() -> Dictionary:
	var taken: Dictionary = {}
	for raw: Variant in _team + _candidates:
		taken[str(raw.get("name", ""))] = true
	var free_names: Array = []
	for raw: Variant in _staff.get("names", []):
		if not taken.has(str(raw)):
			free_names.append(str(raw))
	var person_name: String = "Новичок"
	if not free_names.is_empty():
		person_name = free_names[randi() % free_names.size()]
	var stars: int = 1
	var roll: float = randf()
	for raw: Variant in _staff.get("stars", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		roll -= float(raw.get("chance", 0))
		if roll < 0.0:
			stars = int(raw.get("stars", 1))
			break
	var traits: Array = _staff.get("traits", [])
	var trait_id: String = "none"
	if not traits.is_empty():
		trait_id = str(traits[randi() % traits.size()].get("id", "none"))
	return {"name": person_name, "stars": stars, "trait": trait_id}


func _reset_staff() -> void:
	rating = _rating_value("start", 4)
	_helpers.clear()
	_staff_touched()
	_garage.clear()
	_garage_level = 0
	_team.clear()
	_candidates.clear()
	_candidates_unix = 0
	_fill_candidates()


func get_income_per_second() -> float:
	return _income_per_second


## Доля рынка острова, где идёт борьба, 0..1. Без борьбы — весь рынок ваш.
func get_market_share() -> float:
	if get_front_island() == "":
		return 1.0
	var total: float = get_market_total()
	return 0.0 if total <= 0.0 else get_player_power() / total


## Районы, регионы и франшиза умножают и тап, и пассивный доход.
## Рекламная кампания тоже умножает доход, пока идёт.
func get_income_multiplier() -> float:
	return _district_multiplier() * _region_multiplier() * _competitor_multiplier() * franchise * get_rating_multiplier() * (1.0 + get_ad_boost())


func get_cities() -> Array:
	return _city_defs


func is_district_open(district_id: String) -> bool:
	return int(_opened_districts.get(district_id, 0)) > 0


func get_district_cost(district_id: String) -> float:
	var info: Dictionary = _find_district(district_id)
	return maxf(0.0, float(info.get("cost", 0)))


func can_open_district(district_id: String) -> bool:
	if is_district_open(district_id) or _find_district(district_id).is_empty():
		return false
	return coins + 0.001 >= get_district_cost(district_id)


func open_district(district_id: String) -> bool:
	if not can_open_district(district_id):
		return false
	coins -= get_district_cost(district_id)
	if coins < 0.0:
		coins = 0.0
	_opened_districts[district_id] = 1
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	districts_changed.emit()
	_note_progress()
	save_game()
	return true


func _district_multiplier() -> float:
	var bonus: float = 0.0
	for raw: Variant in _city_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var city: Dictionary = raw
		var districts: Variant = city.get("districts", [])
		if typeof(districts) != TYPE_ARRAY:
			continue
		for item: Variant in districts:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var info: Dictionary = item
			var district_id: String = str(info.get("id", ""))
			if is_district_open(district_id):
				bonus += float(info.get("income_bonus", 0))
	return 1.0 + bonus


## Острова-регионы по порядку маршрута. Первый — родной (Азия), открыт всегда.
func get_regions() -> Array:
	return _region_defs


func _is_home_island(region_id: String) -> bool:
	return bool(_find_def(_region_defs, region_id).get("home", false))


func is_region_open(region_id: String) -> bool:
	return _is_home_island(region_id) or int(_opened_regions.get(region_id, 0)) > 0


func is_island_captured(region_id: String) -> bool:
	return int(_captured.get(region_id, 0)) > 0


func get_captured_count() -> int:
	return _captured.size()


func get_region_cost(region_id: String) -> float:
	var info: Dictionary = _find_def(_region_defs, region_id)
	return maxf(0.0, float(info.get("cost", 0)))


func get_region_reputation(region_id: String) -> int:
	var info: Dictionary = _find_def(_region_defs, region_id)
	return maxi(0, int(info.get("reputation", 0)))


## Остров перед этим по маршруту. Пустой словарь у первого.
func _previous_island(region_id: String) -> Dictionary:
	var previous: Dictionary = {}
	for raw: Variant in _region_defs:
		if str(raw.get("id", "")) == region_id:
			return previous
		previous = raw
	return {}


## Пустая строка, если регион можно открыть. Иначе текст, чего не хватает.
func get_region_block_reason(region_id: String) -> String:
	if is_region_open(region_id):
		return ""
	var missing: PackedStringArray = PackedStringArray()
	var previous: Dictionary = _previous_island(region_id)
	if not previous.is_empty() and not is_island_captured(str(previous.get("id", ""))):
		missing.append("Сначала станьте такси №1 в городе %s" % str(previous.get("city", previous.get("name", ""))))
	var need_reputation: int = get_region_reputation(region_id)
	if reputation < need_reputation:
		missing.append("Не хватает репутации: %d" % (need_reputation - reputation))
	if coins + 0.001 < get_region_cost(region_id):
		missing.append("Не хватает денег")
	if missing.is_empty():
		return ""
	return "\n".join(missing)


func can_open_region(region_id: String) -> bool:
	if is_region_open(region_id) or _find_def(_region_defs, region_id).is_empty():
		return false
	var previous: Dictionary = _previous_island(region_id)
	if not previous.is_empty() and not is_island_captured(str(previous.get("id", ""))):
		return false
	if reputation < get_region_reputation(region_id):
		return false
	return coins + 0.001 >= get_region_cost(region_id)


func open_region(region_id: String) -> bool:
	if not can_open_region(region_id):
		return false
	coins -= get_region_cost(region_id)
	if coins < 0.0:
		coins = 0.0
	_opened_regions[region_id] = 1
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	regions_changed.emit()
	competitors_changed.emit()
	garage_changed.emit()
	_note_progress()
	save_game()
	return true


func _region_multiplier() -> float:
	var bonus: float = 0.0
	for raw: Variant in _region_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var region_id: String = str(info.get("id", ""))
		if is_region_open(region_id):
			bonus += float(info.get("income_bonus", 0))
	return 1.0 + bonus


# --- Рынок: конкуренты, реклама, пакости, выкуп -----------------------------

## Остров, где сейчас идёт борьба: первый открытый, но не захваченный. Пусто — все открытые ваши.
func get_front_island() -> String:
	for raw: Variant in _region_defs:
		var region_id: String = str(raw.get("id", ""))
		if is_region_open(region_id) and not is_island_captured(region_id):
			return region_id
	return ""


func get_island_info(region_id: String) -> Dictionary:
	return _find_def(_region_defs, region_id)


## Город, за который сейчас борьба. Пусто, если борьбы нет.
func get_front_city() -> String:
	return str(get_island_info(get_front_island()).get("city", ""))


## Конкуренты острова, где идёт борьба.
func get_competitors() -> Array:
	return get_island_competitors(get_front_island())


func get_island_competitors(region_id: String) -> Array:
	var result: Array = []
	if region_id == "":
		return result
	for raw: Variant in _competitor_defs:
		if typeof(raw) == TYPE_DICTIONARY and str(raw.get("island", "")) == region_id:
			result.append(raw)
	return result


## Захвачен ли родной остров (Азия).
func is_home_captured() -> bool:
	for raw: Variant in _region_defs:
		if bool(raw.get("home", false)):
			return is_island_captured(str(raw.get("id", "")))
	return false


func is_competitor_owned(competitor_id: String) -> bool:
	return int(_owned_competitors.get(competitor_id, 0)) > 0


func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _market_value(key: String, fallback: float) -> float:
	return float(_market.get(key, fallback))


func _personality(competitor_id: String) -> Dictionary:
	var kind: String = str(_find_def(_competitor_defs, competitor_id).get("personality", ""))
	var all: Variant = _market.get("personalities", {})
	if typeof(all) != TYPE_DICTIONARY:
		return {}
	var found: Variant = all.get(kind, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


## Подставляем название компании игрока в реплики конкурентов.
func _say(text: String) -> String:
	var name_text: String = company_name if company_name != "" else "ваша компания"
	return text.replace("{company}", name_text)


## Сколько заказов перехватывает игрок: доход водителей плюс тапы. Реклама уже внутри дохода.
func get_player_power() -> float:
	return _player_earning()


func _player_earning() -> float:
	return get_income_per_second() + get_ride_value() * _market_value("player_tap_rate", 3)


## Сила конкурента: база, рост за время дуэли, минус переманенные водители, плюс-минус действующие эффекты.
## Отрицательный «удар» — это его собственная акция: тогда он сильнее.
func get_competitor_power(competitor_id: String) -> float:
	if is_competitor_owned(competitor_id):
		return 0.0
	var info: Dictionary = _find_def(_competitor_defs, competitor_id)
	var power: float = float(info.get("power", 0)) * float(_rival_perm.get(competitor_id, 1.0))
	power *= get_rival_growth(competitor_id)
	var now: int = _now()
	for raw: Variant in _rival_cuts.get(competitor_id, []):
		if int(raw.get("until", 0)) > now:
			power *= 1.0 - clampf(float(raw.get("cut", 0)), -1.0, 0.95)
	return power


func get_market_total() -> float:
	var total: float = get_player_power()
	for raw: Variant in get_competitors():
		total += get_competitor_power(str(raw.get("id", "")))
	return total


## Доля конкурента среди всех такси города. Нужна только для картинки города (сколько чужих машин).
func get_competitor_share(competitor_id: String) -> float:
	var total: float = get_market_total()
	return 0.0 if total <= 0.0 else get_competitor_power(competitor_id) / total


## Действующие эффекты на конкуренте: [{"cut", "left"}], left — секунд до конца.
## cut > 0 — ваша пакость ослабила его, cut < 0 — его акция усилила.
func get_competitor_cuts(competitor_id: String) -> Array:
	var result: Array = []
	var now: int = _now()
	for raw: Variant in _rival_cuts.get(competitor_id, []):
		var left: int = int(raw.get("until", 0)) - now
		if left > 0:
			result.append({"cut": float(raw.get("cut", 0)), "left": left})
	return result


func get_competitor_lost_drivers(competitor_id: String) -> float:
	return 1.0 - float(_rival_perm.get(competitor_id, 1.0))


# Дуэли

func _duel_value(key: String, fallback: Variant) -> Variant:
	var duel: Variant = _market.get("duel", {})
	if typeof(duel) != TYPE_DICTIONARY:
		return fallback
	return duel.get(key, fallback)


## С кем сейчас дуэль: первый конкурент города, который ещё не выкуплен и не сдался.
func get_active_rival() -> String:
	for raw: Variant in get_competitors():
		var competitor_id: String = str(raw.get("id", ""))
		if not is_competitor_owned(competitor_id) and not is_rival_surrendered(competitor_id):
			return competitor_id
	return ""


## "owned" — выкуплен, "surrendered" — сдался и ждёт выкупа, "active" — дуэль сейчас, "waiting" — следующий.
func get_rival_state(competitor_id: String) -> String:
	if is_competitor_owned(competitor_id):
		return "owned"
	if is_rival_surrendered(competitor_id):
		return "surrendered"
	if competitor_id == get_active_rival():
		return "active"
	return "waiting"


func is_rival_surrendered(competitor_id: String) -> bool:
	return _surrendered.has(competitor_id) and not is_competitor_owned(competitor_id)


## Во сколько раз конкурент вырос за время дуэли: растёт, пока вы с ним бьётесь, но не бесконечно.
func get_rival_growth(competitor_id: String) -> float:
	var hours: float = float(_rival_age.get(competitor_id, 0.0)) / 3600.0
	var cap: float = float(_duel_value("growth_cap", 1.6))
	return minf(cap, 1.0 + hours * float(_duel_value("growth_per_hour", 0.25)))


func get_rival_growth_cap() -> float:
	return float(_duel_value("growth_cap", 1.6))


## Прогресс дуэли 0..1: ваша сила относительно силы соперника. 1 — догнали, он сдаётся.
func get_duel_progress() -> float:
	var rival_id: String = get_active_rival()
	if rival_id == "":
		return 1.0
	var rival_power: float = get_competitor_power(rival_id)
	if rival_power <= 0.0:
		return 1.0
	return clampf(get_player_power() / rival_power, 0.0, 1.0)


## Сколько конкурентов города уже выкуплено.
func get_city_owned_count() -> int:
	var count: int = 0
	for raw: Variant in get_competitors():
		if is_competitor_owned(str(raw.get("id", ""))):
			count += 1
	return count


## Цена выкупа сдавшегося: зафиксирована в момент сдачи.
func get_competitor_cost(competitor_id: String) -> float:
	if _surrendered.has(competitor_id):
		return float(_surrendered[competitor_id])
	return _surrender_price(competitor_id)


func _surrender_price(competitor_id: String) -> float:
	var seconds: float = float(_duel_value("price_seconds", 180))
	return ceilf(maxf(1.0, get_competitor_power(competitor_id) * seconds))


func can_buy_rival(competitor_id: String) -> bool:
	return is_rival_surrendered(competitor_id) and coins + 0.001 >= get_competitor_cost(competitor_id)


## Выкуп сдавшегося конкурента: без отказа, по цене, назначенной при сдаче.
func buy_rival(competitor_id: String) -> Dictionary:
	var info: Dictionary = _find_def(_competitor_defs, competitor_id)
	if info.is_empty():
		return {"ok": false, "text": "Такой компании нет."}
	if is_competitor_owned(competitor_id):
		return {"ok": false, "text": "Эта компания уже ваша."}
	if not is_rival_surrendered(competitor_id):
		return {"ok": false, "text": "Сначала обгоните их — тогда сами придут продаваться."}
	if not can_buy_rival(competitor_id):
		return {"ok": false, "text": "Не хватает денег на выкуп."}
	coins = maxf(0.0, coins - get_competitor_cost(competitor_id))
	_owned_competitors[competitor_id] = 1
	_surrendered.erase(competitor_id)
	_rival_cuts.erase(competitor_id)
	_after_market_change()
	return {"ok": true, "text": _say(str(info.get("success_text", "Сделка состоялась.")))}


## Эффект на сопернике. Тот же самый не складывается, а продлевается: двадцать гвоздей подряд не помогут.
func _add_effect(competitor_id: String, source: String, cut: float, duration: int) -> void:
	var cuts: Array = []
	for raw: Variant in _rival_cuts.get(competitor_id, []):
		if str(raw.get("source", "")) != source:
			cuts.append(raw)
	cuts.append({"cut": cut, "until": _now() + duration, "source": source})
	_rival_cuts[competitor_id] = cuts


## Сколько секунд до следующего хода соперника (только пока идёт игра).
func get_rival_attack_left() -> int:
	return maxi(0, int(ceilf(_rival_attack_in)))


## Какой ход сделает соперник по характеру: "health", "rating" или "promo".
func get_rival_attack_kind(competitor_id: String) -> String:
	return str(_personality(competitor_id).get("attack", ""))


func _duel_text(key: String, competitor_id: String) -> String:
	var own_key: String = {"surrender_texts": "surrender", "attack_texts": "attacks"}.get(key, "")
	if own_key != "" and get_boss(competitor_id).has(own_key):
		var line: String = boss_line(competitor_id, own_key)
		if line != "":
			return line
	var kind: String = str(_find_def(_competitor_defs, competitor_id).get("personality", ""))
	var texts: Variant = _duel_value(key, {})
	var text: String = ""
	if typeof(texts) == TYPE_DICTIONARY:
		text = str(texts.get(kind, texts.get("default", "")))
	var rival_name: String = str(_find_def(_competitor_defs, competitor_id).get("name", ""))
	return _say(text.replace("{rival}", rival_name))


func _reset_attack_timer(first: bool) -> void:
	if first:
		_rival_attack_in = float(_duel_value("first_attack", 300))
	else:
		_rival_attack_in = randf_range(float(_duel_value("attack_min", 360)), float(_duel_value("attack_max", 600)))


## Босс конкурента: имя, характер, реплики (data/competitors.json, поле "boss").
func get_boss(competitor_id: String) -> Dictionary:
	var found: Variant = _find_def(_competitor_defs, competitor_id).get("boss", {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


## Реплика босса с подставленным названием компании игрока.
func boss_line(competitor_id: String, key: String) -> String:
	var value: Variant = get_boss(competitor_id).get(key, "")
	if typeof(value) == TYPE_ARRAY:
		var lines: Array = value
		value = lines[randi() % lines.size()] if not lines.is_empty() else ""
	return _say(str(value))


## Ответы игрока на знакомство: [{"say", "answer"}], уже с названием компании.
func get_boss_replies(competitor_id: String) -> Array:
	var result: Array = []
	var raw: Variant = get_boss(competitor_id).get("replies", [])
	if typeof(raw) == TYPE_ARRAY:
		for item: Variant in raw:
			if typeof(item) == TYPE_DICTIONARY:
				result.append({"say": _say(str(item.get("say", ""))), "answer": _say(str(item.get("answer", "")))})
	return result


func is_story_seen(competitor_id: String, beat: String) -> bool:
	var seen: Variant = _story_seen.get(competitor_id, {})
	return typeof(seen) == TYPE_DICTIONARY and seen.has(beat)


func _mark_story(competitor_id: String, beat: String) -> void:
	var seen: Dictionary = _story_seen.get(competitor_id, {})
	seen[beat] = 1
	_story_seen[competitor_id] = seen
	rival_story.emit(competitor_id, beat)
	save_game()


## Сюжетные сцены: знакомство в начале дуэли и реплика на половине пути. Каждая — один раз.
func _tick_story(rival_id: String) -> void:
	if get_boss(rival_id).is_empty():
		return
	if not is_story_seen(rival_id, "intro"):
		_mark_story(rival_id, "intro")
	elif not is_story_seen(rival_id, "half") and get_duel_progress() >= 0.5:
		_mark_story(rival_id, "half")


## Раз в секунду игры: соперник растёт, иногда отвечает ударом, а догнали — сдаётся.
func _tick_duel(seconds: float) -> void:
	var rival_id: String = get_active_rival()
	if rival_id == "":
		return
	if rival_id != _duel_rival:
		_duel_rival = rival_id
		_reset_attack_timer(true)
	_rival_age[rival_id] = float(_rival_age.get(rival_id, 0.0)) + seconds
	if _check_surrender():
		return
	_tick_story(rival_id)
	_rival_attack_in -= seconds
	if _rival_attack_in <= 0.0:
		_reset_attack_timer(false)
		_rival_attack(rival_id)


## Догнали соперника — он сдаётся и ждёт выкупа. Дуэль переходит к следующему.
func _check_surrender() -> bool:
	var rival_id: String = get_active_rival()
	if rival_id == "" or get_player_power() < get_competitor_power(rival_id):
		return false
	_surrendered[rival_id] = _surrender_price(rival_id)
	# Временные эффекты на сдавшемся больше не нужны.
	_rival_cuts.erase(rival_id)
	var text: String = "%s\nВыкуп: %s." % [_duel_text("surrender_texts", rival_id), format_money(_surrendered[rival_id])]
	rival_surrendered.emit(rival_id, text)
	competitors_changed.emit()
	_note_progress()
	save_game()
	return true


## Ответный ход соперника по характеру.
func _rival_attack(rival_id: String) -> void:
	var text: String = _duel_text("attack_texts", rival_id)
	match get_rival_attack_kind(rival_id):
		"health":
			var hit: float = float(_duel_value("attack_health", 0.1))
			_my_health = maxf(0.0, _my_health - hit)
			for car: Variant in _garage:
				car["health"] = maxf(0.0, float(car.get("health", 1)) - hit)
			wear_changed.emit()
			text += " Машины −%d%% здоровья." % int(roundf(hit * 100.0))
		"rating":
			var drop: float = float(_duel_value("attack_rating", 0.25))
			rating = clampf(rating - drop, 1.0, 5.0)
			text += " Рейтинг −%.2f★." % drop
		"promo":
			var boost: float = float(_duel_value("attack_promo", 0.2))
			var duration: int = int(_duel_value("attack_promo_seconds", 300))
			_add_effect(rival_id, "promo", -boost, duration)
			text += " Они сильнее на %d%% ещё %d мин." % [int(roundf(boost * 100.0)), int(duration / 60)]
		_:
			return
	_recalc_income()
	rival_attacked.emit(rival_id, text)
	competitors_changed.emit()
	save_game()


# Реклама

func get_ads() -> Array:
	var ads: Variant = _market.get("ads", [])
	return ads if typeof(ads) == TYPE_ARRAY else []


func get_tricks() -> Array:
	var tricks: Variant = _market.get("tricks", [])
	return tricks if typeof(tricks) == TYPE_ARRAY else []


## Цена растёт вместе с доходом: столько-то секунд вашего заработка (без рекламы), но не меньше минимума.
func _price_by_seconds(info: Dictionary) -> float:
	var by_income: float = _player_earning() / (1.0 + get_ad_boost()) * float(info.get("price_seconds", 60))
	return ceilf(maxf(float(info.get("min_price", 100)), by_income))


func get_ad_price(ad_id: String) -> float:
	return _price_by_seconds(_find_def(get_ads(), ad_id))


func get_active_ad() -> Dictionary:
	if _ad.is_empty() or int(_ad.get("until", 0)) <= _now():
		return {}
	return _find_def(get_ads(), str(_ad.get("id", "")))


func get_ad_left() -> int:
	return maxi(0, int(_ad.get("until", 0)) - _now()) if not get_active_ad().is_empty() else 0


func get_ad_boost() -> float:
	return float(get_active_ad().get("boost", 0))


## Чем платим за кампанию: "coins" — монетами, "video" — просмотром рекламного ролика.
func get_ad_pay(ad_id: String) -> String:
	return str(_find_def(get_ads(), ad_id).get("pay", "coins"))


## Секунд до того, как кампанию за ролик снова можно запустить.
func get_ad_wait(ad_id: String) -> int:
	return maxi(0, int(_ad_ready.get(ad_id, 0)) - _now())


## Одна кампания за раз: новая — только когда закончилась старая.
func can_buy_ad(ad_id: String) -> bool:
	if _find_def(get_ads(), ad_id).is_empty() or not get_active_ad().is_empty():
		return false
	if get_ad_pay(ad_id) == "video":
		return get_ad_wait(ad_id) <= 0
	return coins + 0.001 >= get_ad_price(ad_id)


## Запуск кампании. За «video» зовём только после того, как игрок досмотрел ролик.
func buy_ad(ad_id: String) -> bool:
	if not can_buy_ad(ad_id):
		return false
	var info: Dictionary = _find_def(get_ads(), ad_id)
	if get_ad_pay(ad_id) == "video":
		_ad_ready[ad_id] = _now() + int(info.get("cooldown", 1800))
	else:
		coins = maxf(0.0, coins - get_ad_price(ad_id))
	_ad = {"id": ad_id, "until": _now() + int(info.get("duration", 300))}
	_after_market_change()
	tap_power_changed.emit(get_tap_power())
	return true


# Палки в колёса

func get_trick_price(trick_id: String) -> float:
	return _price_by_seconds(_find_def(get_tricks(), trick_id))


func get_catch_chance(competitor_id: String, trick_id: String) -> float:
	var chance: float = float(_find_def(get_tricks(), trick_id).get("catch", 0.2))
	chance += float(_personality(competitor_id).get("catch_bonus", 0))
	return clampf(chance, 0.05, 0.9)


func get_trick_wait(competitor_id: String) -> int:
	return maxi(0, int(_trick_ready.get(competitor_id, 0)) - _now())


func can_play_trick(competitor_id: String, trick_id: String) -> bool:
	if competitor_id == "" or competitor_id != get_active_rival():
		return false
	# Переманить можно не всех: самые верные водители не уходят даже за пирожки.
	if bool(_find_def(get_tricks(), trick_id).get("permanent", false)) and get_competitor_lost_drivers(competitor_id) >= 1.0 - _market_value("permanent_floor", 0.7) - 0.001:
		return false
	if _find_def(get_tricks(), trick_id).is_empty() or get_trick_wait(competitor_id) > 0:
		return false
	return coins + 0.001 >= get_trick_price(trick_id)


## Пакость конкуренту. Возвращает {"ok", "caught", "text", "revenge"} для окна на экране.
func play_trick(competitor_id: String, trick_id: String) -> Dictionary:
	if not can_play_trick(competitor_id, trick_id):
		return {"ok": false, "caught": false, "text": "Сейчас не получится.", "revenge": ""}
	var rival: Dictionary = _find_def(_competitor_defs, competitor_id)
	var trick: Dictionary = _find_def(get_tricks(), trick_id)
	var price: float = get_trick_price(trick_id)
	coins = maxf(0.0, coins - price)
	_trick_ready[competitor_id] = _now() + int(_market_value("trick_cooldown_seconds", 60))
	var result: Dictionary = {"ok": true, "caught": false, "text": "", "revenge": ""}
	if randf() < get_catch_chance(competitor_id, trick_id):
		var fine: float = price * _market_value("caught_fine_mult", 2.0)
		coins = maxf(0.0, coins - fine)
		rating = clampf(rating - _market_value("caught_rating_hit", 0.3), 1.0, 5.0)
		result["caught"] = true
		result["text"] = "%s\nШтраф %s, рейтинг −%.1f★." % [
			_say(str(rival.get("caught_text", "Вас поймали."))),
			format_money(fine),
			_market_value("caught_rating_hit", 0.3),
		]
	else:
		var cut: float = float(trick.get("cut", 0.2))
		if bool(trick.get("permanent", false)):
			var floor_value: float = _market_value("permanent_floor", 0.7)
			_rival_perm[competitor_id] = maxf(floor_value, float(_rival_perm.get(competitor_id, 1.0)) * (1.0 - cut))
		else:
			_add_effect(competitor_id, trick_id, cut, int(trick.get("duration", 300)))
		result["text"] = "Сработало! %s\nСила конкурента −%d%%." % [str(trick.get("description", "")), int(roundf(cut * 100.0))]
	result["revenge"] = _maybe_revenge(competitor_id)
	_after_market_change()
	return result


## Обидчивые конкуренты отвечают: агрессивный бьёт по машинам, хитрый — по отзывам.
func _maybe_revenge(competitor_id: String) -> String:
	var mood: Dictionary = _personality(competitor_id)
	if randf() >= float(mood.get("revenge_chance", 0)):
		return ""
	var rival: Dictionary = _find_def(_competitor_defs, competitor_id)
	match str(mood.get("revenge", "")):
		"health":
			var hit: float = _market_value("revenge_health_hit", 0.15)
			_my_health = maxf(0.0, _my_health - hit)
			for car: Variant in _garage:
				car["health"] = maxf(0.0, float(car.get("health", 1)) - hit)
			wear_changed.emit()
		"rating":
			rating = clampf(rating - _market_value("revenge_rating_hit", 0.4), 1.0, 5.0)
		_:
			return ""
	_recalc_income()
	return _say(str(rival.get("revenge_text", "")))


func _competitor_multiplier() -> float:
	var bonus: float = 0.0
	for raw: Variant in _competitor_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var competitor_id: String = str(info.get("id", ""))
		if is_competitor_owned(competitor_id):
			bonus += float(info.get("income_bonus", 0))
	bonus += _market_value("capture_bonus", 0.25) * float(_captured.size())
	return 1.0 + bonus


func _after_market_change() -> void:
	_recalc_income()
	_check_surrender()
	_check_capture()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	competitors_changed.emit()
	_note_progress()
	save_game()


## Раз в секунду: чистим закончившиеся эффекты, ведём дуэль и проверяем захват.
func _tick_market(seconds: float = 1.0) -> void:
	var now: int = _now()
	# Кампания кончилась — доход возвращается к обычному.
	if not _ad.is_empty() and int(_ad.get("until", 0)) <= now:
		_ad = {}
		_recalc_income()
		tap_power_changed.emit(get_tap_power())
		competitors_changed.emit()
	for competitor_id: Variant in _rival_cuts.keys():
		var alive: Array = []
		for raw: Variant in _rival_cuts[competitor_id]:
			if int(raw.get("until", 0)) > now:
				alive.append(raw)
		_rival_cuts[competitor_id] = alive
	_tick_duel(seconds)
	_check_capture()


## Захват острова: все его конкуренты выкуплены.
func _check_capture() -> void:
	var island: String = get_front_island()
	var rivals: Array = get_competitors()
	if island == "" or rivals.is_empty():
		return
	for raw: Variant in rivals:
		if not is_competitor_owned(str(raw.get("id", ""))):
			return
	_captured[island] = 1
	_ad = {}
	_recalc_income()
	var city: String = str(get_island_info(island).get("city", ""))
	var text: String = "«%s» — такси №1 в городе %s! Доход +%d%% навсегда." % [
		company_name if company_name != "" else "Ваша компания",
		city,
		int(roundf(_market_value("capture_bonus", 0.25) * 100.0)),
	]
	var next_island: Dictionary = _next_closed_island()
	if next_island.is_empty():
		text += " Это был последний остров — весь мир ездит на вашем такси!"
	else:
		text += " Следующий остров на карте: %s, город %s." % [str(next_island.get("name", "")), str(next_island.get("city", ""))]
	island_captured.emit(island, text)
	competitors_changed.emit()
	regions_changed.emit()
	_note_progress()
	save_game()


func _next_closed_island() -> Dictionary:
	for raw: Variant in _region_defs:
		if not is_region_open(str(raw.get("id", ""))):
			return raw
	return {}


func _reset_market() -> void:
	_owned_competitors = {}
	_rival_cuts.clear()
	_rival_perm.clear()
	_trick_ready.clear()
	_surrendered.clear()
	_rival_age.clear()
	_duel_rival = ""
	_rival_attack_in = 0.0
	_ad = {}
	_captured.clear()


## Репутация = целые двадцатки тапов за забег плюс каждый водитель в команде.
func _sync_reputation() -> void:
	var next: int = int(run_taps / TAPS_PER_REPUTATION) + _team.size()
	if next == reputation:
		return
	reputation = next
	reputation_changed.emit(reputation)


func _find_district(district_id: String) -> Dictionary:
	for raw: Variant in _city_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var city: Dictionary = raw
		var districts: Variant = city.get("districts", [])
		if typeof(districts) != TYPE_ARRAY:
			continue
		for item: Variant in districts:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var info: Dictionary = item
			if str(info.get("id", "")) == district_id:
				return info
	return {}


func has_offline_reward() -> bool:
	return _offline_coins >= 1.0


func get_offline_coins() -> float:
	return _offline_coins


func get_offline_seconds() -> float:
	return _offline_seconds


func is_offline_capped() -> bool:
	return _offline_capped


## Стирает прогресс и сразу записывает пустое сохранение. Кнопка лежит в настройках.
func reset_progress() -> void:
	coins = 0.0
	_upgrade_levels.clear()
	_reset_staff()
	_offline_coins = 0.0
	_offline_seconds = 0.0
	_offline_capped = false
	_opened_districts.clear()
	_opened_regions.clear()
	_reset_market()
	_story_seen.clear()
	run_taps = 0
	franchise = 1.0
	run_earned = 0.0
	lifetime_earned = 0.0
	_done_achievements.clear()
	_last_daily_day = 0
	_fresh_achievements.clear()
	_reset_car()
	company_name = ""
	mentor = {}
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	_sync_reputation()
	drivers_changed.emit()
	garage_changed.emit()
	helpers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)
	achievements_changed.emit()
	car_changed.emit()
	company_changed.emit(company_name)
	save_game()


func get_franchise() -> float:
	return franchise


func get_run_earned() -> float:
	return run_earned


## Какой множитель зафиксируется, если продать компанию сейчас.
func get_preview_franchise() -> float:
	var earned: float = maxf(0.0, lifetime_earned)
	return 1.0 + _franchise_weight * sqrt(earned / maxf(1.0, _franchise_reference))


func can_sell_company() -> bool:
	return get_preview_franchise() + 0.000001 >= franchise * FRANCHISE_MIN_STEP


## Почему кнопка продажи выключена. Пустая строка, если продать уже можно.
func get_sell_block_reason() -> String:
	if can_sell_company():
		return ""
	var preview: float = get_preview_franchise()
	var need: float = franchise * FRANCHISE_MIN_STEP
	return "Сейчас стало бы ×%s. Нужно хотя бы ×%s, это +10%% к текущей франшизе." % [
		format_number(preview),
		format_number(need),
	]


## Сбрасывает забег и прибавляет франшизу. Сама франшиза остаётся.
func sell_company() -> bool:
	if not can_sell_company():
		return false
	franchise = get_preview_franchise()
	coins = 0.0
	run_earned = 0.0
	_upgrade_levels.clear()
	_reset_staff()
	_offline_coins = 0.0
	_offline_seconds = 0.0
	_offline_capped = false
	_opened_districts.clear()
	_opened_regions.clear()
	_reset_market()
	run_taps = 0
	_reset_car()
	_recalc_income()
	_sync_reputation()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	garage_changed.emit()
	helpers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)
	car_changed.emit()
	_note_progress()
	save_game()
	return true


func _gain_coins(amount: float) -> void:
	if amount <= 0.0:
		return
	coins += amount
	run_earned += amount
	lifetime_earned += amount


## Игрок нажал «Забрать». До этого момента монеты за отсутствие только ждут.
func collect_offline_reward() -> float:
	var amount: float = _offline_coins
	if amount <= 0.0:
		return 0.0
	_gain_coins(amount)
	_offline_coins = 0.0
	_offline_seconds = 0.0
	_offline_capped = false
	_note_progress()
	coins_changed.emit(coins)
	save_game()
	return amount


func _sum_income() -> float:
	var total: float = 0.0
	var cars: Dictionary = get_assignments()
	for raw: Variant in _team:
		var person: Dictionary = raw
		var car: Dictionary = cars.get(int(person.get("uid", 0)), {})
		if not car.is_empty():
			total += get_driver_net_on(person, car)
	return total * (1.0 - get_helper_fee_share())


func _recalc_income() -> void:
	_income_per_second = _sum_income()
	income_changed.emit(_income_per_second)


## Считает награду: старое ожидание плюс время с последнего сохранения, но не больше 8 часов.
func _refresh_offline_reward(saved_coins: float = -1.0, saved_seconds: float = -1.0) -> void:
	var base_coins: float = _offline_coins if saved_coins < 0.0 else saved_coins
	var base_seconds: float = _offline_seconds if saved_seconds < 0.0 else saved_seconds
	var gap: int = 0
	if _last_exit_unix > 0:
		gap = int(Time.get_unix_time_from_system()) - _last_exit_unix
		if gap < 0:
			gap = 0
	var total_seconds: float = base_seconds + float(gap)
	_offline_capped = total_seconds > MAX_OFFLINE_SECONDS
	if _offline_capped:
		total_seconds = MAX_OFFLINE_SECONDS
	# Реклама работает, только пока игра открыта.
	var income: float = _sum_income() / (1.0 + get_ad_boost())
	if total_seconds < float(MIN_OFFLINE_SECONDS) or income <= 0.0:
		if base_coins >= 1.0:
			_offline_coins = base_coins
			_offline_seconds = base_seconds
			return
		_offline_coins = 0.0
		_offline_seconds = 0.0
		_offline_capped = false
		return
	_offline_seconds = total_seconds
	_offline_coins = income * get_offline_rate() * total_seconds


## Копейки за пару секунд кладём в кошелёк без окна.
func _fold_offline_dust() -> bool:
	if _offline_coins <= 0.0 or _offline_coins >= 1.0:
		return false
	_gain_coins(_offline_coins)
	_offline_coins = 0.0
	_offline_seconds = 0.0
	_offline_capped = false
	return true


func _scaled_cost(base_cost: float, growth: float, owned: int) -> float:
	var factor: float = growth
	if factor <= 0.0:
		factor = 1.15
	# Маленькая добавка убирает ошибку дробей: 50000 * 1.15 не должно стать 57499.
	var price: float = floorf(base_cost * pow(factor, float(owned)) + 0.000001)
	if price < 1.0:
		return 1.0
	return price


func _find_def(defs: Array, entry_id: String) -> Dictionary:
	for raw: Variant in defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		if str(info.get("id", "")) == entry_id:
			return info
	return {}


## Записывает монеты, улучшения, водителей и время выхода.
func save_game() -> void:
	_last_exit_unix = int(Time.get_unix_time_from_system())
	var data := {
		"coins": coins,
		"upgrades": _upgrade_levels.duplicate(),
		"garage": _garage.duplicate(true),
		"my_clean": _my_clean,
		"mentor": mentor.duplicate(true),
		"helpers": _helpers.duplicate(),
		"rating": rating,
		"my_health": _my_health,
		"garage_level": _garage_level,
		"team": _team.duplicate(true),
		"candidates": _candidates.duplicate(true),
		"next_uid": _next_uid,
		"candidates_unix": _candidates_unix,
		"last_exit_unix": _last_exit_unix,
		"pending_offline_coins": _offline_coins,
		"pending_offline_seconds": _offline_seconds,
		"districts": _opened_districts.duplicate(),
		"regions": _opened_regions.duplicate(),
		"reputation": reputation,
		"run_taps": run_taps,
		"competitors": _owned_competitors.duplicate(),
		"rival_cuts": _rival_cuts.duplicate(true),
		"rival_perm": _rival_perm.duplicate(),
		"trick_ready": _trick_ready.duplicate(),
		"surrendered": _surrendered.duplicate(),
		"rival_age": _rival_age.duplicate(),
		"duel_rival": _duel_rival,
		"rival_attack_in": _rival_attack_in,
		"story_seen": _story_seen.duplicate(true),
		"ad": _ad.duplicate(),
		"ad_ready": _ad_ready.duplicate(),
		"captured": _captured.keys(),
		"franchise": franchise,
		"run_earned": run_earned,
		"lifetime_earned": lifetime_earned,
		"achievements": _done_achievements.keys(),
		"last_daily_day": _last_daily_day,
		"car": _car_id,
		"tap_level": _tap_level,
		"company_name": company_name,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Не удалось сохранить игру: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Читает сохранение. Если файла нет или он битый, игра начинается с нуля.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть сохранение")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Сохранение повреждено, начинаем заново")
		return
	var data: Dictionary = parsed
	coins = maxf(0.0, float(data.get("coins", 0)))
	_upgrade_levels = _read_count_dict(data.get("upgrades", {}))
	_opened_districts = _read_count_dict(data.get("districts", {}))
	_opened_regions = _read_count_dict(data.get("regions", {}))
	_owned_competitors = _read_count_dict(data.get("competitors", {}))
	_load_market(data)
	run_taps = _read_run_taps(data)
	franchise = maxf(1.0, float(data.get("franchise", 1.0)))
	# Старое сохранение без поля: уже лежащие монеты считаем заработком забега.
	run_earned = maxf(0.0, float(data.get("run_earned", coins)))
	lifetime_earned = maxf(run_earned, float(data.get("lifetime_earned", run_earned)))
	_done_achievements = _read_id_set(data.get("achievements", []))
	_last_daily_day = maxi(0, int(data.get("last_daily_day", 0)))
	_load_car(data)
	_my_clean = clampf(float(data.get("my_clean", 1.0)), 0.0, 1.0)
	_my_health = clampf(float(data.get("my_health", 1.0)), 0.0, 1.0)
	var raw_mentor: Variant = data.get("mentor", {})
	mentor = raw_mentor if typeof(raw_mentor) == TYPE_DICTIONARY else {}
	rating = clampf(float(data.get("rating", _rating_value("start", 4))), 1.0, 5.0)
	_helpers.clear()
	var raw_helpers: Variant = data.get("helpers", {})
	if typeof(raw_helpers) == TYPE_DICTIONARY:
		for key: Variant in raw_helpers.keys():
			if not _find_def(_helper_defs, str(key)).is_empty():
				_helpers[str(key)] = 1 if int(raw_helpers[key]) > 0 else 0
	_load_staff(data)
	company_name = str(data.get("company_name", "")).strip_edges().substr(0, COMPANY_NAME_MAX)
	_sync_reputation()
	_last_exit_unix = maxi(0, int(data.get("last_exit_unix", 0)))
	var saved_offline: float = maxf(0.0, float(data.get("pending_offline_coins", 0)))
	var saved_seconds: float = maxf(0.0, float(data.get("pending_offline_seconds", 0)))
	_refresh_offline_reward(saved_offline, saved_seconds)
	_fold_offline_dust()


func _load_market(data: Dictionary) -> void:
	_rival_cuts.clear()
	var cuts: Variant = data.get("rival_cuts", {})
	if typeof(cuts) == TYPE_DICTIONARY:
		for key: Variant in cuts.keys():
			var list: Array = []
			if typeof(cuts[key]) == TYPE_ARRAY:
				for raw: Variant in cuts[key]:
					if typeof(raw) == TYPE_DICTIONARY:
						list.append({
							"cut": clampf(float(raw.get("cut", 0)), -1.0, 0.95),
							"until": int(raw.get("until", 0)),
							"source": str(raw.get("source", "")),
						})
			_rival_cuts[str(key)] = list
	_rival_perm.clear()
	var perm: Variant = data.get("rival_perm", {})
	if typeof(perm) == TYPE_DICTIONARY:
		for key: Variant in perm.keys():
			_rival_perm[str(key)] = clampf(float(perm[key]), _market_value("permanent_floor", 0.7), 1.0)
	_trick_ready = _read_unix_dict(data.get("trick_ready", {}))
	_surrendered = _read_float_dict(data.get("surrendered", {}))
	_rival_age = _read_float_dict(data.get("rival_age", {}))
	_duel_rival = str(data.get("duel_rival", ""))
	_rival_attack_in = maxf(0.0, float(data.get("rival_attack_in", 0.0)))
	_story_seen = {}
	var story: Variant = data.get("story_seen", {})
	if typeof(story) == TYPE_DICTIONARY:
		for key: Variant in story.keys():
			if typeof(story[key]) == TYPE_DICTIONARY:
				var beats: Dictionary = {}
				for beat: Variant in story[key].keys():
					beats[str(beat)] = 1
				_story_seen[str(key)] = beats
	var ad: Variant = data.get("ad", {})
	_ad = {}
	if typeof(ad) == TYPE_DICTIONARY and ad.has("id"):
		_ad = {"id": str(ad.get("id", "")), "until": int(ad.get("until", 0))}
	_ad_ready = _read_unix_dict(data.get("ad_ready", {}))
	_captured = _read_id_set(data.get("captured", []))
	# До этапа 7 захват был один — родной город.
	if bool(data.get("home_captured", false)):
		for raw: Variant in _region_defs:
			if bool(raw.get("home", false)):
				_captured[str(raw.get("id", ""))] = 1


func _read_float_dict(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(raw) == TYPE_DICTIONARY:
		for key: Variant in raw.keys():
			result[str(key)] = maxf(0.0, float(raw[key]))
	return result


func _read_unix_dict(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(raw) == TYPE_DICTIONARY:
		for key: Variant in raw.keys():
			result[str(key)] = int(raw[key])
	return result


## Старые водители-«типы» (до этапа 2): база цены и рост. Нужны только для возврата денег.
const LEGACY_DRIVERS := {
	"trainee": [30.0, 1.16], "driver": [250.0, 1.18], "veteran": [4000.0, 1.22],
	"night_ace": [50000.0, 1.28], "brigadier": [450000.0, 1.32], "column": [4000000.0, 1.36],
	"depot": [35000000.0, 1.4], "network": [300000000.0, 1.45], "holding": [2500000000.0, 1.5],
}


## Гараж и команда из сохранения. Старые «типы» водителей превращаем в деньги.
func _load_staff(data: Dictionary) -> void:
	_garage.clear()
	var raw_garage: Variant = data.get("garage", [])
	if typeof(raw_garage) == TYPE_ARRAY:
		for item: Variant in raw_garage:
			# До этапа 3 в гараже лежали просто id моделей.
			if typeof(item) == TYPE_STRING:
				if _car_index(str(item)) > 0:
					_garage.append(_new_car(str(item)))
				continue
			if typeof(item) != TYPE_DICTIONARY or _car_index(str(item.get("model", ""))) <= 0:
				continue
			_garage.append({
				"model": str(item.get("model", "")),
				"clean": clampf(float(item.get("clean", 1)), 0.0, 1.0),
				"health": clampf(float(item.get("health", 1)), 0.0, 1.0),
			})
	_garage_level = clampi(int(data.get("garage_level", 0)), 0, 1000)
	_team = _read_people(data.get("team", []), true)
	_staff_touched()
	_candidates = _read_people(data.get("candidates", []), false)
	_next_uid = maxi(1, int(data.get("next_uid", 1)))
	for person: Variant in _team:
		_next_uid = maxi(_next_uid, int(person.get("uid", 0)) + 1)
	_candidates_unix = maxi(0, int(data.get("candidates_unix", 0)))
	var legacy: Variant = data.get("drivers", {})
	if typeof(legacy) == TYPE_DICTIONARY:
		var refund: float = 0.0
		for key: Variant in legacy.keys():
			var params: Array = LEGACY_DRIVERS.get(str(key), [])
			if params.is_empty():
				continue
			for owned in maxi(0, int(legacy[key])):
				refund += _scaled_cost(float(params[0]), float(params[1]), owned)
		if refund > 0.0:
			coins += refund
			_legacy_refund = refund


func _read_people(raw: Variant, need_uid: bool) -> Array:
	var result: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item: Variant in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var person: Dictionary = {
			"name": str(item.get("name", "Водитель")),
			"stars": clampi(int(item.get("stars", 1)), 1, 3),
			"trait": str(item.get("trait", "none")),
		}
		if need_uid:
			var uid: int = int(item.get("uid", 0))
			if uid <= 0:
				continue
			person["uid"] = uid
			person["hours"] = maxf(0.0, float(item.get("hours", 0)))
		result.append(person)
	return result


func _announce_legacy_refund() -> void:
	if _legacy_refund <= 0.0:
		return
	var body: String = "Старые водители ушли на пенсию. Вам вернули %s — наймите новую команду." % format_money(_legacy_refund)
	_fresh_achievements.append({"title": "Новые правила найма", "body": body})
	_legacy_refund = 0.0
	save_game()


## Уровень линии тапа из сохранения. До линии сохранялась машина (аренда или покупка):
## переводим её в уровень этой машины.
func _load_car(data: Dictionary) -> void:
	if data.has("tap_level"):
		_tap_level = clampi(int(data.get("tap_level", 0)), 0, 100000)
	else:
		_tap_level = maxi(0, _car_index(str(data.get("car", _start_car_id())))) * TAP_STEPS
	_car_id = str(_car_defs[_car_index_for_level(_tap_level)].get("id", _start_car_id())) if not _car_defs.is_empty() else ""


## Старое сохранение не хранило число тапов. Собираем его из счётчика репутации,
## а если счётчик отстал от водителей — формула всё равно догонит.
func _read_run_taps(data: Dictionary) -> int:
	if data.has("run_taps"):
		return maxi(0, int(data.get("run_taps", 0)))
	var drivers: int = _team.size()
	var stored: int = int(data.get("reputation", 0))
	var from_taps: int = maxi(0, stored - drivers)
	var remainder: int = int(data.get("reputation_taps", 0))
	remainder = clampi(remainder, 0, TAPS_PER_REPUTATION - 1)
	return from_taps * TAPS_PER_REPUTATION + remainder


func get_achievements() -> Array:
	return _achievement_defs


func is_achievement_done(achievement_id: String) -> bool:
	return int(_done_achievements.get(achievement_id, 0)) > 0


func get_achievement_value(kind: String) -> float:
	match kind:
		"earned":
			return lifetime_earned
		"drivers":
			return float(_team.size())
		"districts":
			return float(_opened_districts.size())
		"regions":
			return float(_opened_regions.size())
		"competitors":
			return float(_owned_competitors.size())
		"reputation":
			return float(reputation)
		"upgrades":
			return float(_sum_counts(_upgrade_levels))
		"franchise":
			return franchise
		"cars":
			return float(get_owned_car_count())
		"rating":
			return rating
		"helpers":
			return float(get_hired_helper_count())
		"captured":
			return float(_captured.size())
		_:
			return 0.0


func take_fresh_achievements() -> Array:
	var copy: Array = _fresh_achievements.duplicate()
	_fresh_achievements.clear()
	return copy


func has_daily_reward() -> bool:
	return _last_daily_day != _today_index()


func collect_daily_reward() -> bool:
	if not has_daily_reward():
		return false
	_last_daily_day = _today_index()
	_gain_coins(DAILY_COINS)
	_note_progress()
	coins_changed.emit(coins)
	save_game()
	return true


func _today_index() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


func _note_progress() -> void:
	var guard := 0
	var changed := false
	while guard < 20:
		guard += 1
		var info := _claim_one_achievement()
		if info.is_empty():
			break
		changed = true
		var title := str(info.get("name", "Достижение"))
		var body := _reward_text(info)
		_fresh_achievements.append({"title": title, "body": body})
		achievement_unlocked.emit(title, body)
	if changed:
		achievements_changed.emit()
		save_game()


func _claim_one_achievement() -> Dictionary:
	for raw: Variant in _achievement_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var achievement_id: String = str(info.get("id", ""))
		if achievement_id == "" or is_achievement_done(achievement_id):
			continue
		var need: float = float(info.get("need", 1))
		if get_achievement_value(str(info.get("kind", ""))) + 0.001 < need:
			continue
		_done_achievements[achievement_id] = 1
		_gain_coins(float(info.get("reward_coins", 0)))
		return info
	return {}


func _reward_text(info: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var coins_reward: float = float(info.get("reward_coins", 0))
	if coins_reward > 0.0:
		parts.append("+%s" % format_money(coins_reward))
	var extra_reputation: int = int(info.get("reward_reputation", 0))
	if extra_reputation > 0:
		parts.append("+%d репутации" % extra_reputation)
	if parts.is_empty():
		return "Награда получена"
	return " ".join(parts)


func _sum_counts(source: Dictionary) -> int:
	var total := 0
	for value: Variant in source.values():
		total += int(value)
	return total


func _read_id_set(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item: Variant in raw:
		var achievement_id := str(item)
		if achievement_id != "":
			result[achievement_id] = 1
	return result


func _read_count_dict(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	var source: Dictionary = raw
	for key: Variant in source.keys():
		result[str(key)] = maxi(0, int(source[key]))
	return result


func _read_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		push_error("В файле %s ожидался список" % path)
		return []
	return parsed


func _read_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Не удалось открыть %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("В файле %s ожидался словарь" % path)
		return {}
	return parsed


func _read_balance() -> void:
	var file := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	_tap_from_income = maxf(0.0, float(data.get("tap_from_income", _tap_from_income)))
	_world_market_size = maxf(1.0, float(data.get("world_market_size", _world_market_size)))
	_offline_income_rate = clampf(float(data.get("offline_income_rate", _offline_income_rate)), 0.0, 1.0)
	_tap_level_first_cost = maxf(1.0, float(data.get("tap_level_first_cost", _tap_level_first_cost)))
	_tap_after_last_mult = maxf(1.01, float(data.get("tap_after_last_mult", _tap_after_last_mult)))
	_fleet_growth = maxf(1.0, float(data.get("fleet_growth", _fleet_growth)))
	_trade_in_share = clampf(float(data.get("trade_in_share", _trade_in_share)), 0.0, 1.0)
	_garage_start = maxi(1, int(data.get("garage_start", _garage_start)))
	_franchise_reference = maxf(1.0, float(data.get("franchise_reference", _franchise_reference)))
	_franchise_weight = maxf(0.0, float(data.get("franchise_weight", _franchise_weight)))
	var wear: Variant = data.get("wear", {})
	_wear = wear if typeof(wear) == TYPE_DICTIONARY else {}
	var shifts: Variant = data.get("shifts", {})
	_shift_cfg = shifts if typeof(shifts) == TYPE_DICTIONARY else {}
	var rating_cfg: Variant = data.get("rating", {})
	_rating_cfg = rating_cfg if typeof(rating_cfg) == TYPE_DICTIONARY else {}
	rating = _rating_value("start", 4)
	var expansions: Variant = data.get("garage_expansions", [])
	_garage_expansions = expansions if typeof(expansions) == TYPE_ARRAY else []
	_garage_expansion_growth = maxf(1.0, float(data.get("garage_expansion_growth", _garage_expansion_growth)))


## Сумма в долларах: $999, $1.5K, $-20.
static func format_money(value: float) -> String:
	var text: String = format_number(value)
	if text.begins_with("-"):
		return "-$" + text.substr(1)
	return "$" + text


## Короткий вид числа: 999, 1.5K, 2.3M, 4.1B.
static func format_number(value: float) -> String:
	var sign: String = ""
	var amount: float = value
	if amount < 0.0:
		sign = "-"
		amount = -amount
	if is_nan(amount) or is_inf(amount):
		return "0"

	if amount < 1000.0:
		var rounded: float = snappedf(amount, 0.1)
		if rounded >= 1000.0:
			amount = rounded
		elif is_equal_approx(rounded, roundf(rounded)):
			return "%s%d" % [sign, int(roundf(rounded))]
		else:
			return "%s%.1f" % [sign, rounded]

	var suffixes := PackedStringArray(["K", "M", "B", "T", "Qa", "Qi"])
	var reduced: float = amount
	var tier: int = -1
	while reduced >= 1000.0 and tier < suffixes.size() - 1:
		reduced /= 1000.0
		tier += 1

	# 999 999 округляется до 1000.0K — показываем как 1.0M.
	var text: String = "%.1f" % reduced
	if text.begins_with("1000") and tier < suffixes.size() - 1:
		reduced /= 1000.0
		tier += 1
		text = "%.1f" % reduced

	if tier < 0:
		return "%s%d" % [sign, int(roundf(amount))]
	return "%s%s%s" % [sign, text, suffixes[tier]]
