extends SceneTree

const JaText = preload("res://scripts/ui/JaText.gd")
const PlayerScript = preload("res://scripts/systems/Player.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	old_settings = SaveSystemScript.new().load_data().get("settings", {}).duplicate(true)
	SaveSystemScript.new().update_settings({"touch_ui_mode": "auto", "desktop_touch_preview": false})
	await _run()
	SaveSystemScript.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay OK: title, help, movement, auto attack, gem pickup, level up, 60s run, result retry.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	_assert(packed != null, "Main scene should load")
	SaveSystemScript.new().save_help_seen(false)
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	_assert(_tree_has_text(main, JaText.TITLE), "Title should be visible")
	main.request_start()
	await process_frame
	_assert(main.help_visible, "First start should show help")
	_assert(_tree_has_text(main, "WASD / 矢印キーで移動します"), "Help should explain movement")
	main.accept_help()
	await process_frame
	var game: GameScreen = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.max_hp = 9999
	game.state.hp = 9999
	var moved = false
	var killed = false
	var collected = false
	var leveled = false
	var player = PlayerScript.new()
	var start_pos: Vector2 = game.state.player_position
	for i in range(360):
		if game.state.gems.size() > 0:
			var gem = game.state.gems[0]
			var dir: Vector2 = (gem.position - game.state.player_position).normalized()
			player.process_movement(game.state, dir, 0.2)
		else:
			player.process_movement(game.state, Vector2.RIGHT.rotated(float(i) * 0.05), 0.2)
		game._process(0.2)
		if game.state.player_position.distance_to(start_pos) > 20.0:
			moved = true
		if game.state.kills > 0:
			killed = true
		if game.state.gems_collected > 0:
			collected = true
		if game.state.level_up_pending:
			leveled = true
			game._select_reward(0)
		await process_frame
	_assert(moved, "player should move during autoplay")
	_assert(killed, "auto weapons should kill enemies")
	_assert(collected, "player should collect gems")
	_assert(leveled or game.state.level >= 2, "run should level up within 60 seconds")
	_assert(game.state.elapsed_seconds >= 60.0, "autoplay should progress at least 60 seconds")
	game.state.hp = 0
	game.state.game_over = true
	game.state.game_over_reason = "スライムに囲まれました"
	game._finish_game([])
	await process_frame
	var result = _find_result_view(main)
	_assert(result != null, "Result should appear")
	_assert(_tree_has_text(main, "生存時間"), "Result should show survival time")
	if result != null:
		result.retry_requested.emit()
		await process_frame
		_assert(_find_game_screen(main) != null, "Retry should start new run")
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
