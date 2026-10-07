extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: UI layouts, field help, scan, goals, dynamic drops and exploration for 10min.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var save = SaveSystem.new()
	save.save_help_seen(true)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for screen in ["characters", "settings", "quests", "collection"]:
		match screen:
			"characters":
				main.show_character_select()
			"settings":
				main.show_settings()
			"quests":
				main.show_quests()
			"collection":
				main.show_collection()
		await process_frame
		_assert(not _has_collapsed_text(main), "%s screen should not contain collapsed long labels" % screen)
	main.show_title()
	main.request_start()
	await process_frame
	var game = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.max_hp = 999999
	game.state.hp = game.state.max_hp
	game.state.field_drops.append({
		"id": "heal_ore",
		"name_ja": "回復鉱石",
		"position": game.state.player_position + Vector2(90, 0),
		"unlock_seconds": 0.0,
		"radius": 24.0,
		"collected": false,
		"priority": 6,
		"color": [0.42, 1.0, 0.52]
	})
	game.state.field_gimmicks.append({
		"id": "spawn_rift",
		"name_ja": "召喚裂け目",
		"position": game.state.player_position + Vector2(150, 0),
		"unlock_seconds": 0.0,
		"radius": 38.0,
		"hp": 9999,
		"destroyed": false,
		"color": [0.9, 0.2, 1.0]
	})
	game._process(0.1)
	_assert(game.field_help_label.text.find("回復鉱石") >= 0, "nearby drop should show field help")
	game._scan_field_target()
	game._refresh()
	_assert(game.field_help_label.text.find("危険度") >= 0, "scan should show detailed danger information")
	_assert(game.goal_label.text.find("次の目標") >= 0, "goal HUD should be visible")
	game._toggle_pause()
	_assert(not _has_collapsed_text(game.pause_overlay), "pause should not contain collapsed long labels")
	game._toggle_pause()

	var player = PlayerScript.new()
	var step := 0
	while game.state.elapsed_seconds < 600.0 and step < 720:
		game.state.hp = game.state.max_hp
		player.process_movement(game.state, Vector2.RIGHT.rotated(float(step) * 0.04), 1.0)
		game._process(1.0)
		if game.state.level_up_pending:
			game._select_reward(0)
		if step % 90 == 0:
			_collect_nearest_dynamic_drop(game)
			await process_frame
		step += 1
	_assert(game.state.elapsed_seconds >= 600.0, "UI exploration autoplay should reach 10 minutes")
	_assert(game.state.dynamic_drops_spawned > 0, "dynamic drops should spawn")
	_assert(game.state.exploration_score > 0, "exploration score should increase")
	_assert(game.state.field_event_count > 0, "field event should occur")
	_assert(game.goal_label.text.find("次の目標") >= 0, "goal HUD should remain active")
	root.remove_child(main)
	main.free()
	await process_frame

func _collect_nearest_dynamic_drop(game) -> void:
	for drop in game.state.field_drops:
		if bool(drop.get("dynamic", false)) and not bool(drop.get("collected", false)):
			game.state.player_position = drop.get("position", game.state.player_position)
			return

func _has_collapsed_text(node: Node) -> bool:
	if node is Label:
		var label := node as Label
		if label.text.length() >= 8 and label.custom_minimum_size.x > 0.0 and label.custom_minimum_size.x < 120.0:
			return true
	for child in node.get_children():
		if _has_collapsed_text(child):
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

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
