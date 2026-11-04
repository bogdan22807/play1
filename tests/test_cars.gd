extends SceneTree

func _init() -> void:
	var gs = load("res://autoload/game_state.gd").new()
	root.add_child(gs)
	await process_frame
	gs.reset_progress()
	var ok := true
	var base: float = gs.get_tap_power()
	print("start car=", gs.get_car_id(), " tap=", base)
	ok = ok and gs.get_car_id() == "rickshaw" and not gs.can_rent_car("old_sedan")
	gs.coins = 100.0
	ok = ok and gs.can_rent_car("old_sedan") and not gs.can_buy_car("old_sedan")
	ok = ok and gs.rent_car("old_sedan")
	print("rented tap=", gs.get_tap_power(), " coins=", gs.coins, " buy cost=", gs.get_car_buy_cost("old_sedan"))
	ok = ok and is_equal_approx(gs.get_tap_power(), base * 2.5 * 0.7)
	ok = ok and is_equal_approx(gs.get_car_buy_cost("old_sedan"), 1140.0)
	gs.coins = 1140.0
	ok = ok and gs.buy_car("old_sedan") and not gs.is_car_rented()
	ok = ok and is_equal_approx(gs.get_tap_power(), base * 2.5)
	ok = ok and gs.get_owned_car_count() == 1 and gs.is_achievement_done("first_car")
	gs.coins = 900.0
	ok = ok and gs.rent_car("city_taxi") and gs.is_car_rented()
	ok = ok and not gs.can_rent_car("old_sedan") and not gs.can_buy_car("old_sedan")
	gs.set_company_name("   Жёлтая молния   ")
	gs.save_game()
	var gs2 = load("res://autoload/game_state.gd").new()
	root.add_child(gs2)
	await process_frame
	print("loaded car=", gs2.get_car_id(), " rented=", gs2.is_car_rented(), " owned=", gs2.is_car_owned("old_sedan"), " name=[", gs2.company_name, "]")
	ok = ok and gs2.get_car_id() == "city_taxi" and gs2.is_car_rented() and gs2.is_car_owned("old_sedan") and gs2.company_name == "Жёлтая молния"
	gs2.coins = 1e12
	gs2.sell_company() if gs2.can_sell_company() else null
	gs2.reset_progress()
	ok = ok and gs2.get_car_id() == "rickshaw" and gs2.company_name == ""
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
