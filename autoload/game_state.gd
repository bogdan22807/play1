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
## Длина названия компании.
const COMPANY_NAME_MAX := 24
const DAILY_COINS := 250.0
## Сколько тапов нужно для +1 репутации.
const TAPS_PER_REPUTATION := 20
## Франшиза = 1 + 0.5 * корень из заработка всех забегов, делённого на эту сумму.
const FRANCHISE_REFERENCE := 1000000.0
const FRANCHISE_SQRT_WEIGHT := 0.5
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
var _garage_start: int = 5
var _garage_expansions: Array = []
## Чистота и состояние своей машины, от 0 до 1.
var _my_clean: float = 1.0
var _my_health: float = 1.0
## Настройки износа из balance.json.
var _wear: Dictionary = {}
## Износ парка считаем раз в секунду, а не каждый кадр.
var _wear_left: float = 1.0
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
## Какую долю дохода с тапа забирает владелец арендованной машины. 0.3 = 30%.
var _car_rent_share: float = 0.3
var _car_defs: Array = []
## На какой машине игрок ездит сам. Первая в cars.json — стартовая.
var _car_id: String = ""
## true, если текущая машина взята в аренду.
var _car_rented: bool = false
## id машины -> 1, если машина куплена. Позже их получат водители (этап 2).
var _owned_cars: Dictionary = {}
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
		_note_progress()
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


func is_car_rented() -> bool:
	return _car_rented


func is_car_owned(car_id: String) -> bool:
	return car_id == _start_car_id() or int(_owned_cars.get(car_id, 0)) > 0


## Сколько машин куплено. Стартовая не считается.
func get_owned_car_count() -> int:
	return _owned_cars.size()


## Во сколько раз машина умножает доход с тапа.
func get_car_tap_mult() -> float:
	return maxf(1.0, float(get_car_info().get("tap_mult", 1)))


## Доля тапа, которая уходит за аренду. 0, если машина своя.
func get_rent_share() -> float:
	return _car_rent_share if _car_rented else 0.0


func get_car_rent_cost(car_id: String) -> float:
	return maxf(0.0, float(_find_def(_car_defs, car_id).get("rent_cost", 0)))


## Цена покупки. Если эту машину сейчас арендуем, залог засчитывается.
func get_car_buy_cost(car_id: String) -> float:
	var cost: float = maxf(0.0, float(_find_def(_car_defs, car_id).get("buy_cost", 0)))
	if _car_rented and car_id == _car_id:
		cost = maxf(0.0, cost - get_car_rent_cost(car_id))
	return cost


## Арендовать можно только машину лучше той, на которой ездим.
func can_rent_car(car_id: String) -> bool:
	if _car_index(car_id) <= _car_index(_car_id) or is_car_owned(car_id):
		return false
	var cost: float = get_car_rent_cost(car_id)
	return cost > 0.0 and coins + 0.001 >= cost


## Купить можно машину не хуже текущей, если она ещё не наша.
func can_buy_car(car_id: String) -> bool:
	if _car_index(car_id) < _car_index(_car_id) or is_car_owned(car_id):
		return false
	return coins + 0.001 >= get_car_buy_cost(car_id)


## Платим залог и пересаживаемся. Прошлая аренда просто заканчивается.
func rent_car(car_id: String) -> bool:
	if not can_rent_car(car_id):
		return false
	coins = maxf(0.0, coins - get_car_rent_cost(car_id))
	_park_current_car()
	_car_id = car_id
	_car_rented = true
	_after_car_change()
	return true


## Покупаем и сразу пересаживаемся: машина не хуже текущей.
func buy_car(car_id: String) -> bool:
	if not can_buy_car(car_id):
		return false
	coins = maxf(0.0, coins - get_car_buy_cost(car_id))
	_owned_cars[car_id] = 1
	_park_current_car()
	_car_id = car_id
	_car_rented = false
	_after_car_change()
	return true


## Своя прошлая машина не пропадает: уезжает в гараж к водителям.
func _park_current_car() -> void:
	if _car_rented or _car_id == _start_car_id() or not is_car_owned(_car_id):
		return
	_garage.append({"model": _car_id, "clean": _my_clean, "health": _my_health})
	_recalc_income()
	garage_changed.emit()
	drivers_changed.emit()


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
	_car_rented = false
	_owned_cars.clear()


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
	var sorted: Array = _garage.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		return get_car_driver_income(str(a.get("model", ""))) > get_car_driver_income(str(b.get("model", ""))))
	return sorted


func get_garage_capacity() -> int:
	var capacity: int = _garage_start
	for index in mini(_garage_level, _garage_expansions.size()):
		var step: Variant = _garage_expansions[index]
		if typeof(step) == TYPE_DICTIONARY:
			capacity += int(step.get("add", 0))
	return capacity


func is_garage_full() -> bool:
	return _garage.size() >= get_garage_capacity()


## Следующее расширение гаража. Пустой словарь — расширять больше некуда.
func get_next_expansion() -> Dictionary:
	if _garage_level >= _garage_expansions.size():
		return {}
	var step: Variant = _garage_expansions[_garage_level]
	return step if typeof(step) == TYPE_DICTIONARY else {}


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
	var count: int = 0
	for car: Variant in _garage:
		if str(car.get("model", "")) == car_id:
			count += 1
	return count


## Модель самой слабой машины гаража — её отдают в обмен, когда места нет.
func get_worst_garage_car() -> String:
	var index: int = _worst_garage_index()
	return "" if index < 0 else str(_garage[index].get("model", ""))


func _worst_garage_index() -> int:
	var worst: int = -1
	for index in _garage.size():
		var income: float = get_car_driver_income(str(_garage[index].get("model", "")))
		if worst < 0 or income < get_car_driver_income(str(_garage[worst].get("model", ""))):
			worst = index
	return worst


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
func _tick_fleet_wear(step: float) -> void:
	if _team.is_empty():
		return
	_wear_left -= step
	if _wear_left > 0.0:
		return
	var seconds: float = 1.0 - _wear_left
	_wear_left = 1.0
	var clean_rate: float = _wear_value("fleet_clean_per_second", 0.0016667)
	var health_rate: float = _wear_value("fleet_health_per_second", 0.00033333)
	for car: Variant in get_assignments().values():
		car["clean"] = maxf(0.0, float(car.get("clean", 1)) - clean_rate * seconds)
		car["health"] = maxf(0.0, float(car.get("health", 1)) - health_rate * seconds)
	_recalc_income()
	tap_power_changed.emit(get_tap_power())
	wear_changed.emit()


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
	var people: Array = _team.duplicate()
	people.sort_custom(func(a: Variant, b: Variant) -> bool:
		return get_driver_power(a) > get_driver_power(b))
	var cars: Array = get_garage()
	var result: Dictionary = {}
	for index in mini(people.size(), cars.size()):
		result[int(people[index].get("uid", 0))] = cars[index]
	return result


## Чистый доход водителя в секунду на исправной чистой машине этой модели.
func get_driver_net(person: Dictionary, car_id: String) -> float:
	var gross: float = get_car_driver_income(car_id) * get_driver_power(person)
	return gross * (1.0 - get_salary_share(person)) * get_income_multiplier()


## То же, но с учётом грязи и поломок конкретной машины.
func get_driver_net_on(person: Dictionary, car: Dictionary) -> float:
	var model: String = str(car.get("model", ""))
	return get_driver_net(person, model) * get_fleet_condition_mult(car)


## Сколько в секунду уходит на зарплаты.
func get_salary_per_second() -> float:
	var total: float = 0.0
	var cars: Dictionary = get_assignments()
	for raw: Variant in _team:
		var person: Dictionary = raw
		var car: Dictionary = cars.get(int(person.get("uid", 0)), {})
		var gross: float = get_car_driver_income(str(car.get("model", ""))) * get_driver_power(person)
		total += gross * get_salary_share(person) * get_fleet_condition_mult(car)
	return total * get_income_multiplier()


func _after_staff_change() -> void:
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
	_garage.clear()
	_garage_level = 0
	_team.clear()
	_candidates.clear()
	_candidates_unix = 0
	_fill_candidates()


func get_income_per_second() -> float:
	return _income_per_second


## 0..1. Считается от пассивного дохода и размера рынка из balance.json.
func get_market_share() -> float:
	if _world_market_size <= 0.0:
		return 0.0
	return clampf(get_income_per_second() / _world_market_size, 0.0, 1.0)


## Районы, регионы и франшиза умножают и тап, и пассивный доход.
func get_income_multiplier() -> float:
	return _district_multiplier() * _region_multiplier() * _competitor_multiplier() * franchise


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


func get_regions() -> Array:
	return _region_defs


func is_region_open(region_id: String) -> bool:
	return int(_opened_regions.get(region_id, 0)) > 0


func get_region_cost(region_id: String) -> float:
	var info: Dictionary = _find_def(_region_defs, region_id)
	return maxf(0.0, float(info.get("cost", 0)))


func get_region_reputation(region_id: String) -> int:
	var info: Dictionary = _find_def(_region_defs, region_id)
	return maxi(0, int(info.get("reputation", 0)))


## Пустая строка, если регион можно открыть. Иначе текст, чего не хватает.
func get_region_block_reason(region_id: String) -> String:
	if is_region_open(region_id):
		return ""
	var missing: PackedStringArray = PackedStringArray()
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


func get_competitors() -> Array:
	return _competitor_defs


func is_competitor_owned(competitor_id: String) -> bool:
	return int(_owned_competitors.get(competitor_id, 0)) > 0


func get_competitor_cost(competitor_id: String) -> float:
	var info: Dictionary = _find_def(_competitor_defs, competitor_id)
	return maxf(0.0, float(info.get("base_cost", 0)))


## Шанс отказа: чем крупнее парк и жёстче характер, тем выше.
func get_buyout_refuse_chance(competitor_id: String) -> float:
	var info: Dictionary = _find_def(_competitor_defs, competitor_id)
	if info.is_empty():
		return 1.0
	var chance: float = 0.04 * float(info.get("size", 1))
	match str(info.get("personality", "")):
		"aggressive":
			chance += 0.12
		"cunning":
			chance += 0.18
		"family":
			chance -= 0.05
	return clampf(chance, 0.05, 0.85)


func can_offer_buyout(competitor_id: String) -> bool:
	if is_competitor_owned(competitor_id) or _find_def(_competitor_defs, competitor_id).is_empty():
		return false
	return coins + 0.001 >= get_competitor_cost(competitor_id)


## Деньги списываются только если конкурент согласился.
func offer_buyout(competitor_id: String) -> Dictionary:
	var info: Dictionary = _find_def(_competitor_defs, competitor_id)
	if info.is_empty():
		return {"ok": false, "refused": false, "text": "Такой компании нет."}
	if is_competitor_owned(competitor_id):
		return {"ok": false, "refused": false, "text": "Эта компания уже ваша."}
	if not can_offer_buyout(competitor_id):
		return {"ok": false, "refused": false, "text": "Не хватает денег."}
	if randf() < get_buyout_refuse_chance(competitor_id):
		return {
			"ok": false,
			"refused": true,
			"text": str(info.get("refuse_text", "Нет, мы не продаёмся.")),
		}
	coins -= get_competitor_cost(competitor_id)
	if coins < 0.0:
		coins = 0.0
	_owned_competitors[competitor_id] = 1
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	competitors_changed.emit()
	_note_progress()
	save_game()
	return {
		"ok": true,
		"refused": false,
		"text": str(info.get("success_text", "Сделка состоялась.")),
	}


func _competitor_multiplier() -> float:
	var bonus: float = 0.0
	for raw: Variant in _competitor_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var competitor_id: String = str(info.get("id", ""))
		if is_competitor_owned(competitor_id):
			bonus += float(info.get("income_bonus", 0))
	return 1.0 + bonus


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
	_owned_competitors.clear()
	run_taps = 0
	franchise = 1.0
	run_earned = 0.0
	lifetime_earned = 0.0
	_done_achievements.clear()
	_last_daily_day = 0
	_fresh_achievements.clear()
	_reset_car()
	company_name = ""
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	_sync_reputation()
	drivers_changed.emit()
	garage_changed.emit()
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
	return 1.0 + FRANCHISE_SQRT_WEIGHT * sqrt(earned / FRANCHISE_REFERENCE)


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
	_owned_competitors.clear()
	run_taps = 0
	_reset_car()
	_recalc_income()
	_sync_reputation()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	garage_changed.emit()
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
	return total


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
	var income: float = _sum_income()
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
	_offline_coins = income * _offline_income_rate * total_seconds


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
		"franchise": franchise,
		"run_earned": run_earned,
		"lifetime_earned": lifetime_earned,
		"achievements": _done_achievements.keys(),
		"last_daily_day": _last_daily_day,
		"car": _car_id,
		"car_rented": _car_rented,
		"owned_cars": _owned_cars.keys(),
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
	_load_staff(data)
	company_name = str(data.get("company_name", "")).strip_edges().substr(0, COMPANY_NAME_MAX)
	_sync_reputation()
	_last_exit_unix = maxi(0, int(data.get("last_exit_unix", 0)))
	var saved_offline: float = maxf(0.0, float(data.get("pending_offline_coins", 0)))
	var saved_seconds: float = maxf(0.0, float(data.get("pending_offline_seconds", 0)))
	_refresh_offline_reward(saved_offline, saved_seconds)
	_fold_offline_dust()


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
	_garage_level = clampi(int(data.get("garage_level", 0)), 0, _garage_expansions.size())
	_team = _read_people(data.get("team", []), true)
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
		result.append(person)
	return result


func _announce_legacy_refund() -> void:
	if _legacy_refund <= 0.0:
		return
	var body: String = "Старые водители ушли на пенсию. Вам вернули %s — наймите новую команду." % format_money(_legacy_refund)
	_fresh_achievements.append({"title": "Новые правила найма", "body": body})
	_legacy_refund = 0.0
	save_game()


## Машина из сохранения. Незнакомый id (машину убрали из cars.json) — стартовая.
func _load_car(data: Dictionary) -> void:
	_owned_cars.clear()
	for car_id: Variant in _read_id_set(data.get("owned_cars", [])).keys():
		if _car_index(str(car_id)) > 0:
			_owned_cars[str(car_id)] = 1
	_car_id = str(data.get("car", _start_car_id()))
	_car_rented = bool(data.get("car_rented", false))
	if _car_index(_car_id) < 0:
		_car_id = _start_car_id()
		_car_rented = false
	if _car_id == _start_car_id():
		_car_rented = false
	elif not _car_rented and not is_car_owned(_car_id):
		_car_rented = true


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
	_car_rent_share = clampf(float(data.get("car_rent_share", _car_rent_share)), 0.0, 0.9)
	_fleet_growth = maxf(1.0, float(data.get("fleet_growth", _fleet_growth)))
	_trade_in_share = clampf(float(data.get("trade_in_share", _trade_in_share)), 0.0, 1.0)
	_garage_start = maxi(1, int(data.get("garage_start", _garage_start)))
	var wear: Variant = data.get("wear", {})
	_wear = wear if typeof(wear) == TYPE_DICTIONARY else {}
	var expansions: Variant = data.get("garage_expansions", [])
	_garage_expansions = expansions if typeof(expansions) == TYPE_ARRAY else []


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
