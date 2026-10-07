extends RefCounted

func run(t) -> void:
	test_character_collection_and_pause_layouts(t)

func test_character_collection_and_pause_layouts(t) -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_character_select()
	t.assert_eq(main.screen_mode, "characters", "character screen should open")
	t.assert_true(_max_control_width(main) >= 720.0, "character screen should reserve a readable main column")
	t.assert_true(_find_text(main, "祝福を選ぶ"), "blessing selector should be integrated into character details")
	t.assert_true(not main.blessing_expanded, "blessing list should be folded by default")
	main.collection_tab_index = 6
	main.show_collection()
	t.assert_eq(main.collection_tabs.size(), 10, "collection should include blessings and three field categories")
	t.assert_true(_find_text(main, "ドロップ"), "field drop collection tab should be visible")
	main.free()

	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	t.assert_eq(game.pause_tabs.size(), 8, "pause menu should merge weapon and passive into the equipment tab")
	t.assert_true(game.pause_content.custom_minimum_size.x >= 520.0, "pause center column should stay readable")
	t.assert_true(game.pause_summary.custom_minimum_size.x >= 260.0, "pause summary text should stay readable")
	t.assert_true(game.hp_bar.custom_minimum_size.y <= 18.0, "HUD HP bar should remain compact")
	t.assert_true(game.goal_label.custom_minimum_size.x >= 280.0, "goal HUD should keep a readable width")
	game.free()

	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	t.assert_true(result.scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "result details should scroll instead of clipping")
	t.assert_true(result.lines.custom_minimum_size.x >= 880.0, "result details should not collapse")
	result.free()

func _max_control_width(node: Node) -> float:
	var result := 0.0
	if node is Control:
		result = (node as Control).custom_minimum_size.x
	for child in node.get_children():
		result = maxf(result, _max_control_width(child))
	return result

func _find_text(node: Node, text_part: String) -> bool:
	if node is Button and (node as Button).text.find(text_part) >= 0:
		return true
	if node is Label and (node as Label).text.find(text_part) >= 0:
		return true
	for child in node.get_children():
		if _find_text(child, text_part):
			return true
	return false
