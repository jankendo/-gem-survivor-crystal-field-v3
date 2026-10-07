extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: 15min unlocks, dynamic drops, field events, mastery and result notifications.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var save = SaveSystem.new()
	save.reset_play_data("RESET")
	save.save_help_seen(true)
	var initial = save.load_data()
	var initial_weapons = (initial.get("unlocked_weapons", []) as Array).size()
	var initial_passives = (initial.get("unlocked_passives", []) as Array).size()
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.max_hp = 999999
	game.state.hp = game.state.max_hp
	var player = PlayerScript.new()
	var step := 0
	while game.state.elapsed_seconds < 900.0 and step < 1100:
		game.state.hp = game.state.max_hp
		player.process_movement(game.state, Vector2.RIGHT.rotated(float(step) * 0.035), 1.0)
		game._process(1.0)
		if game.state.level_up_pending:
			game._select_reward(0)
		if step % 120 == 0:
			_collect_nearest_dynamic_drop(game)
			await process_frame
		step += 1
	_assert(game.state.elapsed_seconds >= 900.0, "unlock/event autoplay should reach 15 minutes")
	_assert(game.state.dynamic_drops_spawned > 0, "dynamic drops should spawn during 15 minutes")
	_assert(game.state.field_event_count > 0, "field events should occur during 15 minutes")

	game.state.kills = maxi(game.state.kills, 1200)
	game.state.crystals_destroyed = maxi(game.state.crystals_destroyed, 100)
	game.state.chests_opened = maxi(game.state.chests_opened, 10)
	game.state.danger_time = maxf(game.state.danger_time, 130.0)
	game.state.max_combo = maxi(game.state.max_combo, 160)
	game.state.weapons["bomb_seed"] = 5
	if not game.state.boss_defeated_ids.has("boss_5"):
		game.state.boss_defeated_ids.append("boss_5")
	if not game.state.boss_defeated_ids.has("boss_10"):
		game.state.boss_defeated_ids.append("boss_10")
	game.state.game_over = true
	game.state.game_over_reason = "15分自動検証完了"
	game._finish_game([])
	await process_frame
	var result = _find_result_view(main)
	var final_data = save.load_data()
	_assert(result != null, "result screen should appear")
	_assert((final_data.get("unlocked_weapons", []) as Array).size() == initial_weapons, "run should not directly unlock weapons")
	_assert((final_data.get("unlocked_passives", []) as Array).size() == initial_passives, "run should not directly unlock passives")
	_assert(_tree_has_text(main, "新武器入荷"), "result should show weapon shop arrival notification")
	_assert(_tree_has_text(main, "新パッシブ入荷"), "result should show passive shop arrival notification")
	root.remove_child(main)
	main.free()
	await process_frame

func _collect_nearest_dynamic_drop(game) -> void:
	var best: Dictionary = {}
	var best_distance := INF
	for drop in game.state.field_drops:
		if not bool(drop.get("dynamic", false)) or bool(drop.get("collected", false)):
			continue
		var distance = (drop.get("position", Vector2.ZERO) as Vector2).distance_to(game.state.player_position)
		if distance < best_distance:
			best = drop
			best_distance = distance
	if not best.is_empty():
		game.state.player_position = best.get("position", game.state.player_position)

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
		var found = _find_game_screen(child)
		if found != null:
			return found
	return null

func _find_result_view(node: Node) -> ResultView:
	if node is ResultView:
		return node as ResultView
	for child in node.get_children():
		var found = _find_result_view(child)
		if found != null:
			return found
	return null

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
