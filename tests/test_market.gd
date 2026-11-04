extends SceneTree
## Рынок: доли, реклама, пакости (успех, поимка, месть), выкуп, захват, регионы, сохранение.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _make_state() -> Node:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	return gs


func _init() -> void:
	var gs := _make_state()
	await process_frame
	gs.reset_progress()
	gs.set_company_name("Жёлтая молния")

	# Доли складываются в 100%.
	var total: float = gs.get_market_share()
	for raw: Variant in gs.get_competitors():
		total += gs.get_competitor_share(str(raw["id"]))
	check(is_equal_approx(total, 1.0), "доли в сумме 100%")
	check(gs.get_market_share() < 0.01, "на старте доля почти ноль")
	check(not gs.can_open_region("europe"), "Европа закрыта до захвата")
	check(gs.get_region_block_reason("europe").contains("Бангкок"), "причина: сначала Бангкок")

	# Реклама поднимает долю, одна кампания за раз.
	gs.coins = 1e9
	var before: float = gs.get_market_share()
	check(gs.buy_ad("flyers"), "купили листовки")
	check(gs.get_market_share() > before, "реклама подняла долю")
	check(not gs.can_buy_ad("tv"), "вторая кампания ждёт окончания первой")
	check(gs.get_ad_left() > 290, "реклама идёт 5 минут")

	# Пакость: подменяем случайность, чтобы проверить обе ветки.
	seed(1)
	var wolf_power: float = gs.get_competitor_power("wolf")
	var outcomes: Dictionary = {"caught": 0, "ok": 0}
	for attempt in 40:
		gs._trick_ready.clear()
		gs.coins = 1e9
		var rating_before: float = gs.rating
		var power_before: float = gs.get_competitor_power("wolf")
		var result: Dictionary = gs.play_trick("wolf", "nails")
		check(result["ok"], "пакость сыграна")
		if result["caught"]:
			outcomes["caught"] += 1
			check(gs.rating < rating_before or gs.rating == 1.0, "поймали — рейтинг вниз")
			check(str(result["text"]).contains("Жёлтая молния"), "реплика с названием компании")
		else:
			outcomes["ok"] += 1
			check(gs.get_competitor_power("wolf") < power_before, "сработало — волк слабее")
		gs.rating = 4.0
	check(outcomes["caught"] > 0 and outcomes["ok"] > 0, "бывает и так, и так: %s" % outcomes)
	check(not gs.can_play_trick("wolf", "nails"), "после пакости — пауза")
	check(gs.get_competitor_power("wolf") < wolf_power, "волк ослаб")

	# Переманивание — навсегда.
	var lotus_perm: float = 0.0
	for attempt in 20:
		gs._trick_ready.clear()
		gs.coins = 1e9
		gs.play_trick("lotus", "pies")
	check(gs.get_competitor_lost_drivers("lotus") > 0.0, "у лотоса переманили водителей")
	lotus_perm = gs.get_competitor_power("lotus")

	# Временные удары проходят.
	gs._rival_cuts["elephant"] = [{"cut": 0.5, "until": gs._now() - 1}]
	gs._tick_market()
	check(gs.get_competitor_cuts("elephant").is_empty(), "истёкший удар убран")

	# Выкуп: слабый дешевле.
	var cost_strong: float = gs.get_competitor_cost("elephant")
	var refuse_strong: float = gs.get_buyout_refuse_chance("elephant")
	gs._rival_perm["elephant"] = 0.1
	check(gs.get_competitor_cost("elephant") < cost_strong, "ослабленный дешевле")
	check(gs.get_buyout_refuse_chance("elephant") < refuse_strong, "слабый сговорчивее")
	var bought: bool = false
	for attempt in 50:
		gs._buyout_ready.clear()
		gs.coins = 1e9
		var result: Dictionary = gs.offer_buyout("elephant")
		if result["ok"]:
			bought = true
			break
		check(result["refused"] and not gs.can_offer_buyout("elephant"), "отказ — пауза")
	check(bought and gs.is_competitor_owned("elephant"), "выкупили слона")
	check(gs.get_competitor_share("elephant") == 0.0, "у выкупленного доли нет")

	# Захват: все выкуплены — Бангкок наш.
	var captured_text: Array = []
	gs.home_captured.connect(func(text: String) -> void: captured_text.append(text))
	for id in ["wolf", "lotus"]:
		gs._owned_competitors[id] = 1
	var income_before: float = gs.get_income_multiplier()
	gs._tick_market()
	check(gs.is_home_captured(), "Бангкок захвачен")
	check(captured_text.size() == 1 and captured_text[0].contains("Жёлтая молния"), "поздравление с названием")
	check(gs.get_income_multiplier() > income_before, "бонус за захват")
	check(gs.is_achievement_done("king_of_bangkok"), "достижение за захват")
	gs.reputation = 10000
	check(gs.can_open_region("europe"), "Европа открылась")

	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(gs2.is_home_captured() and gs2.is_competitor_owned("elephant"), "рынок сохранился")
	check(gs2.get_competitor_lost_drivers("lotus") > 0.0, "переманенные водители сохранились")

	# Захват по доле.
	gs2.reset_progress()
	check(not gs2.is_home_captured(), "сброс возвращает рынок")
	gs2._rival_perm = {"wolf": 0.001, "lotus": 0.001, "elephant": 0.001}
	gs2.coins = 1e8
	gs2.buy_fleet("business")
	gs2.hire(0)
	gs2._recalc_income()
	gs2._tick_market()
	check(gs2.get_market_share() >= 0.5 and gs2.is_home_captured(), "захват по доле: %s" % gs2.get_market_share())

	gs2.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
