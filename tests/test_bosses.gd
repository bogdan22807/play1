extends SceneTree
## Правки «Косяки игры»: инопланетянин, выкуп главного босса по 5%, продажа с 3-го острова,
## рост цены найма от общего числа нанятых.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	gs.set_company_name("Тест")

	# Найм: каждый нанятый +5% к цене; увольнение цену не сбрасывает.
	gs.coins = 1e9
	for i in 3:
		gs.buy_fleet("old_sedan")
	var person: Dictionary = gs.get_candidates()[0]
	var price_0: float = gs.get_hire_cost(person)
	check(gs.hire(0), "наняли первого")
	var price_1: float = gs.get_hire_cost(person)
	check(price_1 >= floorf(price_0 * 1.05) and price_1 > price_0, "второй дороже на 5%%: %s → %s" % [price_0, price_1])
	var uid: int = int(gs.get_team()[0]["uid"])
	check(gs.fire(uid), "уволили")
	check(is_equal_approx(gs.get_hire_cost(person), price_1), "после увольнения цена не вернулась назад")
	check(gs.hire(0), "наняли снова")
	check(gs.get_hire_cost(person) > price_1, "и снова дороже — считается каждый найм")
	for p: Variant in gs.get_team().duplicate():
		gs.fire(int(p["uid"]))

	# Инопланетянин: 5★, +70%%, зарплата 5%%, не устаёт, улетает через час, цену найма не двигает.
	var hire_price: float = gs.get_hire_cost(person)
	gs.sell_garage_car("old_sedan")
	check(gs.get_garage().size() == 2, "две машины")
	check(gs.hire_alien(), "инопланетянин нанят за ролик")
	check(gs.hire_alien(), "можно взять второго — по одному на машину")
	check(gs.get_alien_count() == 2, "двое инопланетян в команде")
	check(not gs.hire_alien(), "третьему не на чем ездить")
	check(is_equal_approx(gs.get_hire_cost(person), hire_price), "инопланетяне не дорожат найм")
	var alien: Dictionary = gs.get_team()[0]
	check(int(alien.get("stars", 0)) == 5 and bool(alien.get("alien", false)), "5 звёзд")
	check(is_equal_approx(gs.get_salary_share(alien), 0.05), "зарплата 5%%")
	check(is_equal_approx(gs.get_driver_power(alien), 1.7), "доход +70%%: %s" % gs.get_driver_power(alien))
	check(gs.get_alien_left(alien) > 3590 and gs.get_alien_left(alien) <= 3600, "работает час")
	var left: Array = []
	gs.alien_left.connect(func(n: String) -> void: left.append(n))
	for p: Variant in gs.get_team():
		p["until"] = int(Time.get_unix_time_from_system()) - 1
	gs._expire_aliens()
	check(gs.get_alien_count() == 0 and left.size() == 2, "через час улетели домой")

	# Главный босс: канат не тянется, компанию выкупают долями по 5%%.
	var boss: String = "elephant"
	check(gs.is_boss(boss) and not gs.is_boss("wolf") and not gs.is_boss("lotus"), "на острове два помощника и главный босс")
	gs._owned_competitors["wolf"] = 1
	gs._owned_competitors["lotus"] = 1
	check(gs.get_active_rival() == boss, "после помощников — главный босс")
	gs.coins = 0.0
	check(not gs.can_buy_share(boss), "без денег долю не купить")
	var power_0: float = gs.get_competitor_power(boss)
	var price_a: float = gs.get_share_price(boss)
	gs.coins = 1e15
	check(gs.buy_boss_share(boss)["ok"], "купили 5%%")
	check(gs.get_boss_shares(boss) == 1 and is_equal_approx(gs.get_duel_progress(), 0.05), "выкуплено 5%%")
	check(gs.get_share_price(boss) > price_a, "следующая доля дороже")
	check(is_equal_approx(gs.get_competitor_power(boss), power_0 * 0.95), "босс ослаб на 5%%")
	gs._tick_market(3600.0)
	check(float(gs._rope.get(boss, 0.0)) == 0.0, "канат с боссом не тянется")
	for i in 19:
		gs.buy_boss_share(boss)
	check(gs.is_competitor_owned(boss), "100%% — компания ваша")
	check(not gs.buy_boss_share(boss)["ok"], "больше долей нет")
	gs.save_game()
	gs.load_game()
	check(gs.is_competitor_owned(boss), "выкуп сохранился")

	# Продажа компании: только с 3-го острова, франшиза от ×1,3 до ×3.
	gs.lifetime_earned = 1e30
	check(not gs.can_sell_company(), "с одним островом продать нельзя")
	check(gs.get_sell_block_reason().contains("3-й остров"), "подсказка про 3-й остров")
	gs._opened_regions["europe"] = 1
	gs._opened_regions["africa"] = 1
	check(gs.can_sell_company(), "с тремя островами можно")
	check(is_equal_approx(gs.get_preview_franchise(), 3.0), "франшиза не больше ×3")
	gs.lifetime_earned = 0.0
	check(gs.get_preview_franchise() >= 1.3, "франшиза не меньше ×1,3")

	gs.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
