extends SceneTree

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("MetaProgression AutoPlay OK: purchase, select character, start run, finish, currency/result/save update.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var save := SaveSystem.new()
	save.save_data({})
	save.reset_play_data("RESET")
	save.save_help_seen(true)
	save.add_currency(300)
	var meta = MetaProgressionSystemScript.new()
	_assert(meta.purchase_character(save, "mio"), "Mio should be purchased before meta autoplay")
	_assert(save.select_character("mio"), "Mio should be selectable after purchase")
	save.select_blessing("attack")

	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game := _find_game_screen(main)
	_assert(game != null, "game should start from title with selected character")
	if game == null:
		return
	_assert(game.state.selected_character_id == "mio", "run should use selected character")
	_assert(game.state.weapons.has("ice_orbit"), "selected character should change initial weapon")

	game.state.max_hp = 9999
	game.state.hp = 9999
	game.state.elapsed_seconds = 600.0
	game.state.kills = 400
	game.state.chests_opened = 2
	game.state.evolved_weapon_count = 1
	game.state.evolved_weapons["ice_orbit"] = "eternal_ice_ring"
	game.state.weapon_kill_counts["ice_orbit"] = 400
	game.state.title_badges = ["生存者"]
	game.state.game_over = true
	game.state.game_over_reason = "メタ進行テスト"
	game._finish_game([])
	await process_frame
	var result := _find_result_view(main)
	_assert(result != null, "result should appear after finishing meta autoplay run")
	_assert(_tree_has_text(main, "獲得クリスタル貨"), "result should show earned crystal currency")
	_assert(save.get_currency() > 0, "run finish should save earned crystal currency")
	root.remove_child(main)
	main.free()
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.find(expected) >= 0:
		return true
	if node is Button and (node as Button).text.find(expected) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false

func _find_game_screen(node: Node) -> GameScreen:
	if node is GameScreen:
		return node as GameScreen
	for child in node.get_children():
		var found: GameScreen = _find_game_screen(child)
		if found != null:
			return found
	return null

func _find_result_view(node: Node) -> ResultView:
	if node is ResultView:
		return node as ResultView
	for child in node.get_children():
		var found: ResultView = _find_result_view(child)
		if found != null:
			return found
	return null
