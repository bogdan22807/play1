extends SceneTree
## Списывается ровно та сумма, что написана на кнопке: цены округлены до точности показа.

var ok := true


func check(cond: bool, what: String) -> void:
	if not cond:
		ok = false
		printerr("FAIL: ", what)


## Цена на кнопке → обратно в число: «$4.2K» должно означать ровно 4200.
func _exact(gs: Node, price: float, what: String) -> void:
	check(is_equal_approx(gs.round_price(price), price), "%s: цена %s совпадает с надписью %s" % [what, price, gs.format_money(price)])


func _init() -> void:
	var gs: Node = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	gs.set_company_name("Тест")
	for v in [7.3, 4123.0, 123456.0, 999950.0, 1234567.0, 9.87e12]:
		var p: float = gs.round_price(v)
		check(p >= v and is_equal_approx(gs.round_price(p), p), "округление %s → %s" % [v, p])
	gs.coins = 1e15
	# Награды за достижения тоже дают деньги — в этой проверке они мешают считать.
	gs._achievement_defs = []
	for i in 30:
		gs.buy_fleet("city_taxi")
		gs.buy_fleet("comfort")
		gs.hire(0)
	# Свободная машина для найма.
	gs.expand_garage()
	gs.buy_fleet("comfort")
	var checks: Array = [
		["тап", func() -> float: return gs.get_tap_level_cost(), func() -> void: gs.buy_tap_level()],
		["машина", func() -> float: return gs.get_fleet_cost("business"), func() -> void: gs.buy_fleet("business")],
		["найм", func() -> float: return gs.get_hire_cost(gs.get_candidates()[0]), func() -> void: gs.hire(0)],
		["гараж", func() -> float: return float(gs.get_next_expansion().get("cost", 0)), func() -> void: gs.expand_garage()],
		["помощник", func() -> float: return gs.get_helper_cost("washer"), func() -> void: gs.hire_helper("washer")],
		["доля", func() -> float: return gs.get_share_price("wolf"), func() -> void: gs.buy_share("wolf")],
		["стоянка", func() -> float: return gs.get_buyout_price("lotus", "parking"), func() -> void: gs.buy_buyout("lotus", "parking")],
		["листовки", func() -> float: return gs.get_ad_price("flyers"), func() -> void: gs.buy_ad("flyers")],
	]
	for item: Array in checks:
		var price: float = item[1].call()
		_exact(gs, price, item[0])
		var before: float = gs.coins
		gs.set_process(false)
		item[2].call()
		check(is_equal_approx(before - gs.coins, price), "%s: списано %s, на кнопке %s" % [item[0], before - gs.coins, price])
	for upgrade: Variant in gs.get_upgrades():
		var id: String = str(upgrade.get("id", ""))
		var price: float = gs.get_upgrade_cost(id)
		_exact(gs, price, "тюнинг " + id)
		if not gs.can_buy_upgrade(id):
			continue
		var before: float = gs.coins
		gs.buy_upgrade(id)
		check(is_equal_approx(before - gs.coins, price), "тюнинг %s: списано ровно" % id)
	var model: String = str(gs.get_garage()[0].get("model", ""))
	var sell: float = gs.get_sell_value(model)
	check(is_equal_approx(gs.round_income(sell), sell), "продажа: выручка как на кнопке")
	var before_sell: float = gs.coins
	var got: float = gs.sell_garage_car(model)
	check(is_equal_approx(got, sell) and is_equal_approx(gs.coins - before_sell, sell), "продажа: получено ровно %s" % sell)
	gs.reset_progress()
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
