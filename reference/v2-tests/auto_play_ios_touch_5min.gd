extends SceneTree

const IosPerformanceBudgetScript = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: 5min keyboard-free run, caps, cards and boss schedule.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true, "render_quality": "low"})
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game: GameScreen = _find_game(main)
	_assert(game != null, "touch menu should start a run")
	if game == null:
		return
	game.state.start_new_run(9055)
	game.state.max_hp = 99999
	game.state.hp = 99999
	game.state.weapons["magic_bolt"] = 5
	game.state.weapons["ice_orbit"] = 3
	for i in range(1520):
		var direction := Vector2.RIGHT.rotated(float(i) * 0.083)
		if not game.state.gems.is_empty():
			direction = (game.state.gems[0].position - game.state.player_position).normalized()
		game.virtual_joystick.direction_changed.emit(direction)
		game._process(0.2)
		if game.state.level_up_pending and not game.state.level_up_options.is_empty():
			game._refresh()
			game.reward_popup.selection.select_index(i % game.state.level_up_options.size())
		if game.state.chest_pending:
			game._on_touch_action_started("action_confirm")
		if i % 15 == 0:
			await process_frame
	_assert(game.state.elapsed_seconds >= 300.0, "touch autoplay should reach five minutes")
	_assert(game.state.kills > 0, "touch autoplay should defeat enemies")
	_assert(game.state.gems_collected > 0, "touch autoplay should collect gems")
	_assert(game.state.boss_spawned_minutes.has(5), "five-minute boss should spawn")
	var hard_enemy_budget := IosPerformanceBudgetScript.new().get_int("max_enemies_total", 700)
	_assert(
		game.state.enemies.size() <= hard_enemy_budget,
		"iOS enemy hard safety budget should hold while protected boss/minion/split spawns may exceed the soft cap, enemies=%d hard_budget=%d" % [game.state.enemies.size(), hard_enemy_budget]
	)
	main.queue_free()
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _find_game(node: Node) -> GameScreen:
	if node is GameScreen:
		return node
	for child in node.get_children():
		var found := _find_game(child)
		if found != null:
			return found
	return null
