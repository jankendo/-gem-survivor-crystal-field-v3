extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")
const IosPerformanceBudgetScript = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: 5min run, crystals, combo, boss schedule, caps, result.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	_assert(packed != null, "Main scene should load")
	SaveSystem.new().save_help_seen(true)
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game: GameScreen = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.start_new_run(5050)
	game.state.max_hp = 99999
	game.state.hp = 99999
	game.state.balance_data["max_enemies"] = 260
	game.state.balance_data["max_gems"] = 420
	game.state.balance_data["max_projectiles"] = 260
	game.state.weapons["magic_bolt"] = 4
	game.state.weapons["ice_orbit"] = 3
	game.state.weapons["thunder_chain"] = 3
	game.state.weapons["poison_mist"] = 2
	var player = PlayerScript.new()
	var selected = 0
	for i in range(1550):
		var direction = Vector2.RIGHT.rotated(float(i) * 0.09)
		if game.state.gems.size() > 0:
			direction = (game.state.gems[0].position - game.state.player_position).normalized()
		elif game.state.crystal_walls.size() > 0:
			direction = (game.state.crystal_walls[0].position - game.state.player_position).normalized()
		player.process_movement(game.state, direction, 0.2)
		game._process(0.2)
		if game.state.level_up_pending:
			game._select_reward(selected % maxi(1, game.state.level_up_options.size()))
			selected += 1
		if i % 5 == 0:
			await process_frame
	_assert(game.state.elapsed_seconds >= 300.0, "autoplay should progress at least 5 minutes")
	_assert(game.state.kills > 0, "5min autoplay should kill enemies")
	_assert(game.state.gems_collected > 0, "5min autoplay should collect gems")
	_assert(game.state.boss_spawned_minutes.has(5), "5min boss should spawn")
	var hard_enemy_budget := IosPerformanceBudgetScript.new().get_int("max_enemies_total", 700)
	_assert(
		game.state.enemies.size() <= hard_enemy_budget,
		"enemy hard safety budget should hold while protected boss/minion/split spawns may exceed the soft cap, enemies=%d hard_budget=%d" % [game.state.enemies.size(), hard_enemy_budget]
	)
	game.state.hp = 0
	game.state.game_over = true
	game.state.game_over_reason = "5分検証終了"
	game._finish_game([])
	await process_frame
	_assert(_find_result_view(main) != null, "Result should appear after 5min autoplay")
	root.remove_child(main)
	main.free()
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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
