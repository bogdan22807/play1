extends SceneTree
## Репутация от водителей: копится в игре и пока игрок отдыхает, обнуляется с продажей компании.

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
	check(gs.get_reviews_per_hour() == 0.0, "без водителей отзывов нет")

	gs.coins = 1e9
	for i in 4:
		if gs.is_garage_full():
			gs.expand_garage()
		gs.buy_fleet("city_taxi")
		gs.hire(0)
	var working: int = gs.get_working_driver_count()
	check(working == 4, "все 4 водителя на линии: %d" % working)
	check(is_equal_approx(gs.get_reviews_per_hour(), 25.0 * 2.0), "4 водителя → 25 × √4 = 50 в час: %s" % gs.get_reviews_per_hour())

	# Минута игры: 50 в час → меньше единицы, но дробь копится.
	var before: int = gs.reputation
	var reviews_before: float = gs.run_reviews
	for i in 60:
		gs._tick_second(1.0)
	var gained: float = gs.run_reviews - reviews_before
	check(gained > 0.0 and gained <= 50.0 / 60.0 + 0.001, "за минуту набежала дробь отзывов: %s" % gained)
	check(gs.reputation >= before, "репутация не падает")

	# Без игрока 4 часа: отзывы × доля дохода без игрока (0,8) придут вместе с монетами.
	var per_hour: float = gs.get_reviews_per_hour()
	gs._offline_coins = 0.0
	gs._offline_seconds = 0.0
	gs._last_exit_unix = int(Time.get_unix_time_from_system()) - 4 * 3600
	gs._refresh_offline_reward()
	var expected: int = int(per_hour * gs.get_offline_rate() * 4.0)
	check(abs(gs.get_offline_reviews() - expected) <= 1, "отзывы за 4 часа: %d, ждали %d" % [gs.get_offline_reviews(), expected])
	var rep_before: int = gs.reputation
	gs.collect_offline_reward()
	check(gs.reputation - rep_before >= expected - 1, "репутация пришла с наградой: +%d" % (gs.reputation - rep_before))
	check(gs.get_offline_reviews() == 0, "второй раз не начислится")

	# Подсказка у закрытого острова говорит, когда хватит репутации.
	var reason: String = gs.get_region_block_reason("europe")
	if gs.reputation < gs.get_region_reputation("europe"):
		check(reason.contains("в час"), "подсказка про отзывы: %s" % reason)

	# Сохранение помнит отзывы.
	var saved: float = gs.run_reviews
	gs.save_game()
	gs.run_reviews = 0.0
	gs.load_game()
	check(is_equal_approx(gs.run_reviews, saved), "отзывы пережили сохранение")

	# Большой автопарк помогает, но корнем: 16 водителей дают вдвое больше, чем 4, а не вчетверо.
	check(25.0 * sqrt(16.0) / (25.0 * sqrt(4.0)) == 2.0, "рост корнем")

	gs.reset_progress()
	check(gs.run_reviews == 0.0 and gs.reputation == 0, "сброс обнуляет отзывы")
	print("RESULT ", "PASS" if ok else "FAIL")
	quit()
