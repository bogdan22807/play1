extends SceneTree
## Рынок: дуэли по очереди, рост соперника, ответные ходы, реклама, пакости, сдача и выкуп, захват, сохранение.

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

	# Доли можно выкупать у всех троих сразу, в любом порядке.
	check(gs.get_active_rival() == "wolf", "первый в списке — Волк")
	check(gs.get_rival_state("lotus") == "active" and gs.get_rival_state("elephant") == "active", "все трое доступны сразу")
	check(gs.get_rival_state("eurobolt") == "waiting", "соперники других островов ждут")
	check(gs.get_duel_progress() == 0.0, "на старте ничего не выкуплено")
	check(not gs.can_open_region("europe"), "Европа закрыта до захвата")
	check(gs.get_region_block_reason("europe").contains("Бангкок"), "причина: сначала Бангкок")
	check(not gs.can_buy_buyout("eurobolt", "parking"), "выкупать части можно только у соперников своего острова")

	# У каждого конкурента свой босс с сюжетом, среди боссов есть женщины.
	var women: int = 0
	for raw: Variant in gs._competitor_defs:
		var id: String = str(raw["id"])
		var boss: Dictionary = gs.get_boss(id)
		var full: bool = boss.has("name") and boss.has("intro") and boss.has("half") and boss.has("surrender")
		check(full and gs.get_boss_replies(id).size() == 2 and boss["attacks"].size() >= 3, "сюжет босса %s" % id)
		if str(boss.get("gender", "")) == "f":
			women += 1
	check(women >= 5, "женщин-боссов: %d" % women)
	check(gs.boss_line("lotus", "intro").contains("Жёлтая молния"), "босс обращается к компании по имени")

	# Сюжет: знакомство в начале дуэли и реплика на половине пути — по одному разу.
	var scenes: Array = []
	gs.rival_story.connect(func(id: String, beat: String) -> void: scenes.append(id + ":" + beat))
	gs._tick_market(0.0)
	gs._tick_market(0.0)
	check(scenes == ["wolf:intro"], "знакомство с Волком один раз: %s" % str(scenes))
	# Знакомство — один раз; на половине выкупа босс нервничает.
	gs.coins = 1e15
	for k in 10:
		check(gs.buy_share("lotus")["ok"], "доля Лотоса")
	check(scenes.has("lotus:half"), "на 50%% Лотос нервничает: %s" % str(scenes))
	gs.buy_share("wolf")
	check(is_equal_approx(gs.get_duel_progress("lotus"), 0.5) and is_equal_approx(gs.get_duel_progress("wolf"), 0.05), "доли то одного, то другого")
	gs._boss_shares.clear()
	scenes.clear()
	gs._ad = {}
	check(gs.can_buy_ad("tv") and gs.get_ad_wait("tv") == 0, "следующий ролик ТВ — сразу")
	check(gs.buy_ad("billboard") and gs.get_ad_left("billboard") > 590, "билборд идёт 10 минут")
	gs.save_game()
	var gs4 := _make_state()
	await process_frame
	check(gs4.get_ad_left("billboard") > 590, "идущий ролик сохранился")
	gs4.queue_free()
	gs._ad_ready.clear()
	gs._ad = {}
	gs._recalc_income()

	# Части компании: стоянка, машины, диспетчерская — по разу у каждого, навсегда урезают доход и цену долей.
	var wolf_power: float = gs.get_competitor_power("wolf")
	var share_before: float = gs.get_share_price("wolf")
	gs.coins = 0.0
	check(not gs.can_buy_buyout("wolf", "parking"), "без денег стоянку не купить")
	gs.coins = 1e15
	var deal: Dictionary = gs.buy_buyout("wolf", "parking")
	check(deal["ok"] and gs.has_buyout("wolf", "parking"), "стоянка Волка ваша")
	check(not gs.can_buy_buyout("wolf", "parking"), "второй раз ту же стоянку не купить")
	check(is_equal_approx(gs.get_competitor_power("wolf"), wolf_power * 0.92), "доход Волка −8%%")
	check(gs.get_share_price("wolf") < share_before, "доля Волка подешевела")
	check(gs.can_buy_buyout("lotus", "parking"), "у Лотоса своя стоянка")
	gs.buy_buyout("wolf", "fleet_part")
	gs.buy_buyout("wolf", "dispatch")
	check(is_equal_approx(gs.get_buyout_factor("wolf"), 0.92 * 0.9 * 0.88), "все три части вместе")
	# Выгода есть, но небольшая: части стоят чуть меньше, чем экономят на долях.
	var parts_cost: float = 0.0
	for raw: Variant in gs.get_buyouts():
		parts_cost += gs.get_buyout_price("wolf", str(raw["id"]))
	var all_shares_full: float = 0.0
	var all_shares_cut: float = 0.0
	for k in 20:
		all_shares_full += share_before * pow(1.08, k)
		all_shares_cut += gs.get_share_price("wolf") * pow(1.08, k)
	var saved: float = all_shares_full - all_shares_cut
	check(saved > parts_cost and saved < parts_cost * 1.6, "части окупаются, но не сильно: экономия %s, цена %s" % [saved, parts_cost])
	gs.save_game()
	var gs5 := _make_state()
	await process_frame
	check(gs5.has_buyout("wolf", "dispatch"), "части сохранились")
	gs5.queue_free()
	# Конкуренты не растут со временем.
	var before_wait: float = gs.get_competitor_power("lotus")
	gs._tick_market(36000.0)
	check(is_equal_approx(gs.get_competitor_power("lotus"), before_wait), "конкуренты не растут")
	gs._buyouts.clear()

	# Ответные ходы по характеру.
	var attacks: Array = []
	gs.rival_attacked.connect(func(id: String, text: String) -> void: attacks.append([id, text]))
	gs._rival_cuts.clear()
	gs.coins = 0.0
	gs._garage = [{"model": "old_sedan", "clean": 1.0, "health": 1.0}]
	gs._my_health = 1.0
	gs._rival_attack("wolf")
	check(gs._my_health < 1.0 and float(gs._garage[0]["health"]) < 1.0, "Волк бьёт по машинам")
	var rating_before_attack: float = gs.rating
	gs._rival_attack("lotus")
	check(gs.rating < rating_before_attack, "Лотос портит рейтинг")
	var elephant_before: float = gs.get_competitor_power("elephant")
	gs.rating = 4.0
	gs._rival_attack("elephant")
	check(gs.get_competitor_power("elephant") == elephant_before and gs.rating < 4.0, "Слон устроил акцию: сильнее не стал, но отзывы просели")
	check(attacks.size() == 3 and str(attacks[0][1]).length() > 30, "ходы с текстом голосом босса: %s" % str(attacks))
	gs._rival_cuts.clear()
	gs.rating = 4.0
	gs._duel_rival = ""
	gs._tick_market()
	check(gs.get_rival_attack_left() > 200, "первый ход соперника — через несколько минут")

	gs.coins = 0.0
	check(not gs.can_buy_share("wolf"), "без денег долю не купить")
	gs.coins = 1e15
	for k in 20:
		gs.buy_share("wolf")
	check(gs.is_competitor_owned("wolf"), "выкупили Волка целиком")
	check(gs.get_city_owned_count() == 1, "выкуплен 1 из 3")
	check(not gs.is_home_captured(), "один выкуп — ещё не захват")
	gs._tick_market(3600.0)
	check(gs._surrendered.is_empty(), "никто не сдаётся — только выкуп")

	# Сохранение посреди выкупа и перенос старого каната.
	gs._boss_shares["lotus"] = 6
	gs._rope["elephant"] = 0.6
	gs._surrendered["lotus_x"] = 1.0
	gs.save_game()
	var gs3 := _make_state()
	await process_frame
	check(gs3.get_boss_shares("lotus") == 6, "доли сохранились")
	check(gs3.get_boss_shares("elephant") == 6, "старый канат 60%% стал 30%% компании")
	check(gs3._rope.is_empty() and gs3._surrendered.is_empty(), "канат и сдача из старых сохранений убраны")
	gs3.queue_free()
	gs._rope.clear()
	gs._surrendered.clear()
	gs._boss_shares.clear()

	# Захват: все выкуплены — Бангкок наш.
	var captured_text: Array = []
	gs.island_captured.connect(func(_island: String, text: String) -> void: captured_text.append(text))
	for id in ["lotus", "elephant"]:
		gs._owned_competitors[id] = 1
	var income_before: float = gs.get_income_multiplier()
	gs._tick_market()
	check(gs.is_home_captured(), "Бангкок захвачен")
	check(captured_text.size() == 1 and captured_text[0].contains("Жёлтая молния"), "поздравление с названием")
	check(gs.get_income_multiplier() > income_before, "бонус за захват")
	check(gs.is_achievement_done("king_of_bangkok"), "достижение за захват")
	gs.reputation = 10000
	gs.coins = 1e12
	check(gs.can_open_region("europe"), "Европа открылась")

	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(gs2.is_home_captured() and gs2.is_competitor_owned("elephant"), "рынок сохранился")
	gs2.reset_progress()
	check(not gs2.is_home_captured() and gs2.get_active_rival() == "wolf", "сброс возвращает рынок")

	gs2.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
