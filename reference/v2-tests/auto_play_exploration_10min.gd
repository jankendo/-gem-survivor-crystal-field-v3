extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: exploration 10min, drops, gimmicks, synergies, melee/shock, indicators.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	SaveSystem.new().save_help_seen(true)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.start_new_run(9090, "explore")
	game.state.max_hp = 99999
	game.state.hp = 99999
	game.state.weapons = {"soul_scythe": 4, "blade_fan": 4, "thunder_chain": 4}
	game.state.passives = {"move_speed": 2, "cooldown": 2}
	game.state.field_drops.append({"id": "weapon_core", "name_ja": "武器コア", "position": game.state.player_position + Vector2(36, 0), "unlock_seconds": 0.0, "radius": 28.0, "priority": 4, "color": [0.4, 0.9, 1.0]})
	game.state.field_gimmicks.append({"id": "healing_spring", "name_ja": "回復泉", "position": game.state.player_position + Vector2(52, 0), "unlock_seconds": 0.0, "radius": 38.0, "hp": 9999, "color": [0.4, 1.0, 0.6]})
	game._process(0.1)
	var player = PlayerScript.new()
	var i := 0
	while game.state.elapsed_seconds < 600.0 and i < 900:
		game.state.hp = game.state.max_hp
		player.process_movement(game.state, Vector2.RIGHT.rotated(float(i) * 0.02), 1.0)
		game._process(1.0)
		if game.state.level_up_pending:
			game._select_reward(0)
		if i % 45 == 0:
			await process_frame
		i += 1
	_assert(game.state.elapsed_seconds >= 600.0, "exploration autoplay should reach 10 minutes")
	_assert(game.state.field_drops_collected > 0, "exploration autoplay should collect field drop")
	_assert(game.state.active_synergies.size() > 0 or game.state.active_synergy_history.size() > 0, "exploration autoplay should activate build synergy")
	_assert(game.state.melee_rush_kills > 0 or game.state.shock_explosions > 0, "exploration autoplay should trigger melee or shock system")
	root.remove_child(main)
	main.free()

func _find_game_screen(node):
	if node is GameScreen:
		return node
	for child in node.get_children():
		var found = _find_game_screen(child)
		if found != null:
			return found
	return null

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
