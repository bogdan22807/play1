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

	# Дуэли по очереди: сначала Волк, остальные ждут.
	check(gs.get_active_rival() == "wolf", "первая дуэль — с Волком")
	check(gs.get_rival_state("lotus") == "waiting" and gs.get_rival_state("elephant") == "waiting", "остальные ждут")
	check(gs.get_duel_progress() < 0.1, "на старте до Волка далеко")
	check(not gs.can_open_region("europe"), "Европа закрыта до захвата")
	check(gs.get_region_block_reason("europe").contains("Бангкок"), "причина: сначала Бангкок")
	check(not gs.can_play_trick("lotus", "nails"), "пакостить можно только текущему сопернику")

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
	# Канат: слабее — не тянется и ползёт назад; сильнее — тянется, вдвое сильнее — в полную силу.
	check(gs.get_rope_speed(0.5) < 0.0, "слабее — канат ползёт назад")
	check(gs.get_rope_speed(1.0) == 0.0, "на равных — стоит")
	check(gs.get_rope_speed(1.5) > 0.0 and gs.get_rope_speed(1.5) < gs.get_rope_speed(2.0), "чуть сильнее — медленнее")
	check(is_equal_approx(gs.get_rope_speed(2.0), gs.get_rope_speed(10.0)), "вдвое и больше — полная скорость")
	var full_time: float = 1.0 / gs.get_rope_speed(5.0)
	check(full_time >= 600.0, "даже при огромном перевесе на соперника — минимум 10 минут игры: %s" % full_time)
	# Делаем игрока втрое сильнее Волка и тянем.
	gs._rival_cuts["wolf"] = [{"cut": 0.95, "until": gs._now() + 100000, "source": "a"}]
	var cut_ok: bool = gs.get_duel_ratio() >= 2.0
	if not cut_ok:
		gs._rival_perm["wolf"] = gs.get_player_power() / (gs.get_competitor_power("wolf") * 3.0)
	check(gs.get_duel_ratio() >= 2.0, "игрок вдвое сильнее Волка: %s" % gs.get_duel_ratio())
	gs._tick_market(full_time * 0.55)
	check(scenes.has("wolf:half"), "на половине каната Волк нервничает: %s, канат %s" % [str(scenes), gs.get_duel_progress()])
	check(gs.get_rival_state("wolf") == "active", "на половине ещё не сдался")
	check(gs.get_rope_eta() > 0, "видно, сколько ещё тянуть")
	gs._rival_cuts.clear()
	gs._rival_perm.clear()
	gs._rope.clear()
	gs._surrendered.clear()
	gs._rival_age.clear()

	# Реклама добавляет силы, одна кампания за раз.
	gs.coins = 1e9
	var before: float = gs.get_player_power()
	check(gs.buy_ad("flyers"), "купили листовки")
	check(gs.get_player_power() > before, "реклама подняла силу")
	check(not gs.can_buy_ad("tv"), "вторая кампания ждёт окончания первой")
	check(gs.get_ad_left() > 290, "реклама идёт 5 минут")
	check(gs.get_income_multiplier() > 1.49 * gs.get_income_multiplier() / (1.0 + gs.get_ad_boost()), "реклама подняла и доход")
	# Кончилась — доход обычный.
	var income_with_ad: float = gs.get_ride_value()
	gs._ad["until"] = gs._now() - 1
	gs._tick_market()
	check(gs._ad.is_empty() and gs.get_ride_value() < income_with_ad, "после рекламы доход вернулся")

	# Кампании за ролик: без денег, но с паузой.
	gs.coins = 0.0
	check(gs.get_ad_pay("tv") == "video" and gs.can_buy_ad("tv"), "ТВ — за ролик, монеты не нужны")
	check(not gs.can_buy_ad("flyers"), "листовки — только за монеты")
	check(gs.buy_ad("tv") and gs.coins == 0.0, "ТВ запущено бесплатно")
	gs._ad = {}
	check(not gs.can_buy_ad("tv") and gs.get_ad_wait("tv") > 3600, "следующий ролик ТВ не раньше чем через пару часов")
	check(gs.can_buy_ad("billboard"), "билборд — отдельная пауза")
	gs.save_game()
	var gs4 := _make_state()
	await process_frame
	check(gs4.get_ad_wait("tv") > 3600, "пауза ролика сохранилась")
	gs4.queue_free()
	gs._ad_ready.clear()
	gs._ad = {}
	gs._recalc_income()

	# Пакость: проверяем обе ветки.
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
			check(gs.get_competitor_power("wolf") <= power_before, "сработало — волк не сильнее")
		gs.rating = 4.0
		if gs.get_active_rival() != "wolf":
			break
	check(outcomes["caught"] > 0 and outcomes["ok"] > 0, "бывает и так, и так: %s" % outcomes)
	check(gs.get_competitor_power("wolf") < wolf_power, "волк ослаб")
	check(gs.get_competitor_cuts("wolf").size() == 1, "одинаковые пакости не складываются, а продлеваются")
	gs._rival_cuts.clear()
	gs._surrendered.clear()

	# Переманивание — навсегда.
	for attempt in 10:
		gs._trick_ready.clear()
		gs.coins = 1e9
		gs.play_trick("wolf", "pies")
	check(gs.get_competitor_lost_drivers("wolf") > 0.0, "у волка переманили водителей")
	check(gs.get_competitor_lost_drivers("wolf") <= 0.301, "но не больше 30%%: %s" % gs.get_competitor_lost_drivers("wolf"))
	check(not gs.can_play_trick("wolf", "pies"), "больше переманить нельзя")
	gs._rival_perm.clear()
	gs._surrendered.clear()

	# Временные эффекты проходят.
	gs._rival_cuts["wolf"] = [{"cut": 0.5, "until": gs._now() - 1}]
	gs._tick_market()
	check(gs.get_competitor_cuts("wolf").is_empty(), "истёкший удар убран")

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
	gs._rival_attack("elephant")
	check(gs.get_competitor_power("elephant") > elephant_before, "Слон устроил акцию и стал сильнее")
	check(attacks.size() == 3 and str(attacks[0][1]).length() > 30, "ходы с текстом голосом босса: %s" % str(attacks))
	gs._rival_cuts.clear()
	gs.rating = 4.0
	gs._duel_rival = ""
	gs._tick_market()
	check(gs.get_rival_attack_left() > 200, "первый ход соперника — через несколько минут")

	# Догнали — соперник сдаётся, цена зафиксирована, выкуп без отказа.
	var surrenders: Array = []
	gs.rival_surrendered.connect(func(id: String, text: String) -> void: surrenders.append([id, text]))
	gs._rival_perm["wolf"] = 0.00001
	gs.coins = 0.0
	gs._tick_market()
	check(gs.get_rival_state("wolf") == "active", "сила есть, но канат ещё не перетянут — не сдаётся сразу")
	gs._tick_market(3600.0)
	check(gs.get_rival_state("wolf") == "surrendered", "Волк сдался")
	check(surrenders.size() == 1 and str(surrenders[0][1]).contains("Выкуп"), "сообщение о сдаче с ценой")
	check(gs.get_active_rival() == "lotus", "дуэль перешла к Лотосу")
	var price: float = gs.get_competitor_cost("wolf")
	gs._rival_perm.erase("wolf")
	check(is_equal_approx(gs.get_competitor_cost("wolf"), price), "цена не меняется после сдачи")
	check(not gs.can_buy_rival("wolf"), "без денег не купить")
	check(not gs.buy_rival("lotus")["ok"], "несдавшегося не купить")
	gs.coins = price * 3.0
	var deal: Dictionary = gs.buy_rival("wolf")
	check(deal["ok"] and gs.is_competitor_owned("wolf"), "выкупили Волка")
	check(gs.get_city_owned_count() == 1, "выкуплен 1 из 3")
	check(not gs.is_home_captured(), "один выкуп — ещё не захват")

	# Сохранение посреди дуэли.
	gs._rival_age["lotus"] = 1800.0
	gs._rope["lotus"] = 0.4
	gs._surrendered["elephant"] = 12345.0
	gs.save_game()
	var gs3 := _make_state()
	await process_frame
	check(is_equal_approx(float(gs3._rival_age.get("lotus", 0)), 1800.0), "возраст дуэли сохранился")
	check(is_equal_approx(gs3.get_duel_progress(), 0.4), "канат сохранился")
	check(gs3.is_rival_surrendered("elephant") and is_equal_approx(gs3.get_competitor_cost("elephant"), 12345.0), "сдавшийся сохранился")
	gs3.queue_free()
	gs._surrendered.clear()

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
