extends SceneTree
## Смены, усталость и рейтинг компании.

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
	check(is_equal_approx(gs.get_rating(), 4.0) and is_equal_approx(gs.get_rating_multiplier(), 1.0), "старт: 4 звезды, доход ×1")

	gs.coins = 1e6
	gs.buy_fleet("city_taxi")
	gs.buy_fleet("old_sedan")
	gs.hire(0)
	var person: Dictionary = gs.get_team()[0]
	var uid: int = int(person["uid"])
	check(gs.get_driver_hours(person) == 0.0, "новый водитель свежий")

	# Целая чистая машина и свежий водитель: отзывы растут к 5 звёздам (или около, по характеру).
	var fresh_target: float = gs.get_rating_target()
	check(fresh_target > 4.5, "свежий парк тянет рейтинг вверх: %s" % fresh_target)
	for i in 60:
		gs._tick_fleet_wear(1.0)
	check(gs.get_rating() > 4.0, "рейтинг вырос за минуту: %s" % gs.get_rating())
	check(gs.get_rating_multiplier() > 1.0, "высокий рейтинг даёт бонус к доходу")
	check(gs.get_driver_hours(person) > 0.9 and gs.get_driver_hours(person) < 1.1, "минута = игровой час")

	# Только у работающего водителя идут часы.
	gs.buy_fleet("old_sedan")
	gs.hire(0)
	gs.hire(0)
	check(gs.get_team().size() == 3, "трое в команде")

	# 8 часов смены — всё ещё бодрый, дальше устаёт.
	person["hours"] = 8.0
	check(gs.get_tiredness(person) == 0.0 and gs.get_tired_mult(person) == 1.0, "8 часов — норма")
	person["hours"] = 11.0
	check(gs.get_tiredness(person) > 0.4 and gs.get_tired_mult(person) < 1.0, "11 часов — устал")
	person["hours"] = 20.0
	check(gs.get_tiredness(person) == 1.0 and is_equal_approx(gs.get_tired_mult(person), 0.5), "20 часов — валится с ног")
	var tired_rating: float = gs.get_ride_rating(1.0, 1.0, person)
	var fresh_person: Dictionary = person.duplicate()
	fresh_person["hours"] = 0.0
	check(tired_rating < gs.get_ride_rating(1.0, 1.0, fresh_person) - 2.0, "уставший портит отзывы")
	gs._recalc_income()
	var tired_income: float = gs.get_income_per_second()
	check(gs.get_tired_count() >= 1, "есть уставшие")
	check(gs.change_shift(uid) and gs.get_driver_hours(person) == 0.0, "сменили")
	check(gs.get_income_per_second() > tired_income, "после смены доход вырос")
	check(not gs.can_change_shift(uid), "свежего менять незачем")

	# Плохой парк тянет рейтинг вниз, рейтинг ниже 4 режет доход.
	for p: Variant in gs.get_team():
		p["hours"] = 30.0
	for car: Variant in gs.get_garage():
		car["clean"] = 0.0
	gs._my_clean = 0.0
	check(gs.get_rating_target() < 2.5, "грязь и усталость — плохие отзывы: %s" % gs.get_rating_target())
	for i in 200:
		gs._tick_shifts(1.0)
	check(gs.get_rating() < 3.0 and gs.get_rating_multiplier() < 1.0, "рейтинг упал и режет доход: %s" % gs.get_rating())
	check(gs.change_tired_shifts() == 3, "сменили всех уставших")

	# Часы и рейтинг сохраняются.
	gs.get_team()[0]["hours"] = 5.5
	var saved_rating: float = gs.get_rating()
	gs.save_game()
	var gs2 := _make_state()
	await process_frame
	check(is_equal_approx(gs2.get_rating(), saved_rating), "рейтинг сохранился")
	check(is_equal_approx(gs2.get_driver_hours(gs2.get_team()[0]), 5.5), "часы смены сохранились")

	gs2.reset_progress()
	check(is_equal_approx(gs2.get_rating(), 4.0), "сброс возвращает 4 звезды")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
