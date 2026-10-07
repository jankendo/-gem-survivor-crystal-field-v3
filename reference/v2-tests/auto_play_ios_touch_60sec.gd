extends SceneTree

const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: 60s movement, actions, pause, selection, result retry.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game: GameScreen = _find_game(main)
	_assert(game != null, "touch start should open the game")
	if game == null:
		return
	game.state.max_hp = 9999
	game.state.hp = 9999
	var start: Vector2 = game.state.player_position
	var selected := false
	for i in range(330):
		if i == 5:
			ExpSystemScript.new().add_exp(game.state, game.state.exp_to_next, [])
		var direction := Vector2.RIGHT.rotated(float(i) * 0.07)
		if not game.state.gems.is_empty():
			direction = (game.state.gems[0].position - game.state.player_position).normalized()
		game.virtual_joystick.direction_changed.emit(direction)
		game._process(0.2)
		if game.state.level_up_pending:
			game._refresh()
			if not game.state.level_up_options.is_empty():
				game.reward_popup.selection.select_index(0)
				selected = true
		if i == 40:
			game.state.recall_drone_ready = true
			game._on_touch_action_started("action_drone")
		if i % 10 == 0:
			await process_frame
	game.virtual_joystick.direction_changed.emit(Vector2.ZERO)
	_assert(game.state.player_position.distance_to(start) > 20.0, "virtual joystick should move the player")
	_assert(game.state.elapsed_seconds >= 60.0, "touch autoplay should reach 60 seconds")
	_assert(selected or game.state.level >= 2, "touch card selection should resolve level-up")
	game._on_touch_action_started("action_pause")
	_assert(game.state.paused, "touch pause should pause")
	game._on_touch_action_started("action_pause")
	_assert(not game.state.paused, "touch pause should resume")
	game.state.game_over = true
	game.state.game_over_reason = "iOS touch test"
	game._finish_game([])
	await process_frame
	var result := _find_result(main)
	_assert(result != null, "touch run should reach result")
	if result != null:
		var retry := _find_button(result, "もう一度")
		_assert(retry != null, "result should expose touch retry")
		if retry != null:
			retry.pressed.emit()
			await process_frame
			_assert(_find_game(main) != null, "touch retry should start another run")
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

func _find_result(node: Node) -> ResultView:
	if node is ResultView:
		return node
	for child in node.get_children():
		var found := _find_result(child)
		if found != null:
			return found
	return null

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
