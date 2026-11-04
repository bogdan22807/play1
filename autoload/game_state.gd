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

## Сколько монет даёт тап без улучшений.
const BASE_TAP_POWER: float = 1.0
const UPGRADES_PATH := "res://data/upgrades.json"
const DRIVERS_PATH := "res://data/drivers.json"
const CITIES_PATH := "res://data/cities.json"
const REGIONS_PATH := "res://data/regions.json"
const COMPETITORS_PATH := "res://data/competitors.json"
## Сколько тапов нужно для +1 репутации.
const TAPS_PER_REPUTATION := 20
## Сколько монет забега дают +1 к множителю франшизы.
const FRANCHISE_PER_EARNED := 10000.0
## Меньше этой суммы компанию продать нельзя.
const MIN_RUN_TO_SELL := 1000.0
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
## Репутация компании. Нужна, чтобы выходить в новые регионы.
var reputation: int = 0
## Сколько тапов уже накоплено до следующей единицы репутации.
var _taps_toward_reputation: int = 0
## Постоянный множитель. Переживает продажу компании.
var franchise: float = 1.0
## Монеты, полученные за текущий забег. Траты его не уменьшают.
var run_earned: float = 0.0
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


func _ready() -> void:
	_upgrade_defs = _read_json_array(UPGRADES_PATH)
	_driver_defs = _read_json_array(DRIVERS_PATH)
	_city_defs = _read_json_array(CITIES_PATH)
	_region_defs = _read_json_array(REGIONS_PATH)
	_competitor_defs = _read_json_array(COMPETITORS_PATH)
	load_game()
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)


## Пассивный доход капает каждый кадр. Рядом тикает автосохранение.
func _process(delta: float) -> void:
	if _income_per_second > 0.0:
		var step: float = delta
		if step > MAX_INCOME_STEP:
			step = MAX_INCOME_STEP
		_gain_coins(_income_per_second * step)
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
	_run_tap_for_reputation()
	coins_changed.emit(coins)
	return gained


## Сила одного тапа: база плюс бонус каждого купленного уровня.
func get_tap_power() -> float:
	var power: float = BASE_TAP_POWER
	for raw: Variant in _upgrade_defs:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var info: Dictionary = raw
		var upgrade_id: String = str(info.get("id", ""))
		var bonus: float = float(info.get("tap_bonus", 0))
		power += bonus * float(get_upgrade_level(upgrade_id))
	return power * get_income_multiplier()


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
	_add_reputation(1)
	coins_changed.emit(coins)
	drivers_changed.emit()
	save_game()
	return true


func get_income_per_second() -> float:
	return _income_per_second


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
		missing.append("Не хватает монет")
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
		return {"ok": false, "refused": false, "text": "Не хватает монет."}
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


func _add_reputation(amount: int) -> void:
	if amount <= 0:
		return
	reputation += amount
	reputation_changed.emit(reputation)


func _run_tap_for_reputation() -> void:
	_taps_toward_reputation += 1
	if _taps_toward_reputation < TAPS_PER_REPUTATION:
		return
	_taps_toward_reputation = 0
	_add_reputation(1)
	save_game()


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
	reputation = 0
	_taps_toward_reputation = 0
	franchise = 1.0
	run_earned = 0.0
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)
	save_game()


func get_franchise() -> float:
	return franchise


func get_run_earned() -> float:
	return run_earned


## На сколько вырастет франшиза, если продать компанию прямо сейчас.
func get_prestige_bonus() -> float:
	return run_earned / FRANCHISE_PER_EARNED


func can_sell_company() -> bool:
	return run_earned + 0.001 >= MIN_RUN_TO_SELL


## Сбрасывает забег и прибавляет франшизу. Сама франшиза остаётся.
func sell_company() -> bool:
	if not can_sell_company():
		return false
	franchise += get_prestige_bonus()
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
	reputation = 0
	_taps_toward_reputation = 0
	_recalc_income()
	coins_changed.emit(coins)
	tap_power_changed.emit(get_tap_power())
	upgrades_changed.emit()
	drivers_changed.emit()
	districts_changed.emit()
	regions_changed.emit()
	reputation_changed.emit(reputation)
	competitors_changed.emit()
	franchise_changed.emit(franchise)
	save_game()
	return true


func _gain_coins(amount: float) -> void:
	if amount <= 0.0:
		return
	coins += amount
	run_earned += amount


## Игрок нажал «Забрать». До этого момента монеты за отсутствие только ждут.
func collect_offline_reward() -> float:
	var amount: float = _offline_coins
	if amount <= 0.0:
		return 0.0
	_gain_coins(amount)
	_offline_coins = 0.0
	_offline_seconds = 0.0
	_offline_capped = false
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
	_offline_coins = income * total_seconds


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
		"reputation_taps": _taps_toward_reputation,
		"competitors": _owned_competitors.duplicate(),
		"franchise": franchise,
		"run_earned": run_earned,
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
	reputation = maxi(0, int(data.get("reputation", 0)))
	_taps_toward_reputation = maxi(0, int(data.get("reputation_taps", 0)))
	franchise = maxf(1.0, float(data.get("franchise", 1.0)))
	# Старое сохранение без поля: уже лежащие монеты считаем заработком забега.
	run_earned = maxf(0.0, float(data.get("run_earned", coins)))
	_last_exit_unix = maxi(0, int(data.get("last_exit_unix", 0)))
	var saved_offline: float = maxf(0.0, float(data.get("pending_offline_coins", 0)))
	var saved_seconds: float = maxf(0.0, float(data.get("pending_offline_seconds", 0)))
	_refresh_offline_reward(saved_offline, saved_seconds)
	_fold_offline_dust()


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
