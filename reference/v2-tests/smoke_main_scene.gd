extends SceneTree

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Main.tscn could not be loaded.")
		quit(1)
		return
	SaveSystem.new().select_character("noah")
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	if main.get_child_count() <= 0:
		push_error("Title screen did not build any UI children.")
		quit(1)
		return
	main.start_game()
	await process_frame
	var game_screen: GameScreen = _find_game_screen(main)
	if game_screen == null:
		push_error("Start flow did not create GameScreen.")
		quit(1)
		return
	if game_screen.state.hp <= 0 or game_screen.state.max_hp < game_screen.state.hp or game_screen.state.weapons.get("magic_bolt", 0) < 1:
		push_error("Survivor run did not initialize expected player state.")
		quit(1)
		return
	print("Smoke OK: Main title, crystal field survivor arena start.")
	quit(0)

func _find_game_screen(node: Node) -> GameScreen:
	if node is GameScreen:
		return node as GameScreen
	for child in node.get_children():
		var found: GameScreen = _find_game_screen(child)
		if found != null:
			return found
	return null
