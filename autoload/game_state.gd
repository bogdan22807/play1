extends Node
## Общее состояние игры.
## Экран только читает эти данные и слушает сигналы — сам экономику не считает.

## Монеты изменились.
signal coins_changed(coins: float)
## Сколько монет даёт один тап.
signal tap_power_changed(power: float)
## Купили улучшение или изменился его уровень.
signal upgrades_changed
## Наняли водителя.
signal drivers_changed
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
var _driver_defs: Array = []
## id водителя -> сколько таких водителей нанято.
var _driver_counts: Dictionary = {}
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
	_driver_defs = _read_json_array(DRIVERS_PATH)
	_city_defs = _read_json_array(CITIES_PATH)
	_region_defs = _read_json_array(REGIONS_PATH)
	_competitor_defs = _read_json_array(COMPETITORS_PATH)
	_achievement_defs = _read_json_array(ACHIEVEMENTS_PATH)
	_car_defs = _read_json_array(CARS_PATH)
	_car_id = _start_car_id()
	_read_balance()
	load_game()
	_recalc_income()
	_note_progress()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
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
	var ride: float = get_flat_tap() * get_car_tap_mult() * (1.0 - get_rent_share())
	return ride * get_income_multiplier() + get_income_per_second() * _tap_from_income


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
	_car_id = car_id
	_car_rented = false
	_after_car_change()
	return true


func _after_car_change() -> void:
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


## Список водителей из data/drivers.json.
func get_drivers() -> Array:
	return _driver_defs


func get_driver_count(driver_id: String) -> int:
	return int(_driver_counts.get(driver_id, 0))


## Цена следующего найма этого типа. Каждый следующий водитель дороже.
func get_driver_cost(driver_id: String) -> float:
	var info: Dictionary = _find_def(_driver_defs, driver_id)
	if info.is_empty():
		return 0.0
	var base_cost: float = float(info.get("base_cost", 1))
	var growth: float = float(info.get("cost_growth", 1.15))
	return _scaled_cost(base_cost, growth, get_driver_count(driver_id))


func can_hire_driver(driver_id: String) -> bool:
	var cost: float = get_driver_cost(driver_id)
	return cost > 0.0 and coins + 0.001 >= cost


func hire_driver(driver_id: String) -> bool:
	if not can_hire_driver(driver_id):
		return false
	coins -= get_driver_cost(driver_id)
	if coins < 0.0:
		coins = 0.0
	_driver_counts[driver_id] = get_driver_count(driver_id) + 1
	_recalc_income()
	_sync_reputation()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	drivers_changed.emit()
	_note_progress()
	save_game()
	return true


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


## Репутация = целые двадцатки тапов за забег плюс каждый нанятый водитель.
func _sync_reputation() -> void:
	var next: int = int(run_taps / TAPS_PER_REPUTATION) + _sum_counts(_driver_counts)
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
	_driver_counts.clear()
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
	_driver_counts.clear()
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
	for raw: Variant in _driver_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var driver_id: String = str(info.get("id", ""))
		var per_second: float = float(info.get("income_per_second", 0))
		total += per_second * float(get_driver_count(driver_id))
	return total * get_income_multiplier()


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
		"drivers": _driver_counts.duplicate(),
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
	_driver_counts = _read_count_dict(data.get("drivers", {}))
	_opened_districts = _read_count_dict(data.get("districts", {}))
	_opened_regions = _read_count_dict(data.get("regions", {}))
	_owned_competitors = _read_count_dict(data.get("competitors", {}))
	run_taps = _read_run_taps(data)
	_sync_reputation()
	franchise = maxf(1.0, float(data.get("franchise", 1.0)))
	# Старое сохранение без поля: уже лежащие монеты считаем заработком забега.
	run_earned = maxf(0.0, float(data.get("run_earned", coins)))
	lifetime_earned = maxf(run_earned, float(data.get("lifetime_earned", run_earned)))
	_done_achievements = _read_id_set(data.get("achievements", []))
	_last_daily_day = maxi(0, int(data.get("last_daily_day", 0)))
	_load_car(data)
	company_name = str(data.get("company_name", "")).strip_edges().substr(0, COMPANY_NAME_MAX)
	_last_exit_unix = maxi(0, int(data.get("last_exit_unix", 0)))
	var saved_offline: float = maxf(0.0, float(data.get("pending_offline_coins", 0)))
	var saved_seconds: float = maxf(0.0, float(data.get("pending_offline_seconds", 0)))
	_refresh_offline_reward(saved_offline, saved_seconds)
	_fold_offline_dust()


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
	var drivers: int = _sum_counts(_driver_counts)
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
			return float(_sum_counts(_driver_counts))
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
