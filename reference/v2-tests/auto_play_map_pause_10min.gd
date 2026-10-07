extends SceneTree

func _initialize() -> void:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.elapsed_seconds = 600.0
	game.state.spawn_meter = 1.0
	game._toggle_expanded_map()
	var elapsed_before = game.state.elapsed_seconds
	var spawn_before = game.state.spawn_meter
	for i in range(600):
		game._process(1.0 / 60.0)
	if game.state.elapsed_seconds != elapsed_before or game.state.spawn_meter != spawn_before:
		push_error("map pause autoplay advanced gameplay timers")
		quit(1)
	game._toggle_expanded_map()
	game._process(1.0 / 60.0)
	if game.state.elapsed_seconds <= elapsed_before:
		push_error("map pause autoplay did not resume gameplay")
		quit(1)
	print("AutoPlay Map Pause OK: 10min equivalent pause lock.")
	quit(0)
