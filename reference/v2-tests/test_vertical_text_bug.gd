extends RefCounted

const UiLayoutFixSystemScript = preload("res://scripts/systems/UiLayoutFixSystem.gd")

func run(t) -> void:
	test_scroll_children_keep_horizontal_width(t)
	test_real_menu_labels_do_not_collapse(t)
	test_pause_and_result_text_widths(t)

func test_scroll_children_keep_horizontal_width(t) -> void:
	var system = UiLayoutFixSystemScript.new()
	var scroll = ScrollContainer.new()
	var body = VBoxContainer.new()
	var label = Label.new()
	system.prepare_scroll(scroll)
	system.prepare_scroll_child(body, 720.0)
	system.prepare_text(label, 240.0)
	t.assert_true(body.custom_minimum_size.x >= 720.0, "scroll child must keep a horizontal minimum")
	t.assert_true(label.custom_minimum_size.x >= 240.0, "wrapped text must not collapse into vertical glyphs")
	t.assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "labels should wrap by words")
	scroll.free()
	body.free()
	label.free()

func test_real_menu_labels_do_not_collapse(t) -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	for screen in ["quests", "settings", "collection"]:
		if screen == "quests":
			main.show_quests()
		elif screen == "settings":
			main.show_settings()
		else:
			main.show_collection()
		var narrow_long_labels: Array = []
		_collect_narrow_labels(main, narrow_long_labels)
		t.assert_true(narrow_long_labels.is_empty(), "%s labels must not collapse to near-zero width" % screen)
	main.free()

func test_pause_and_result_text_widths(t) -> void:
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	t.assert_true(game.pause_content.custom_minimum_size.x >= 520.0, "pause text must keep a readable width")
	game.free()
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	t.assert_true(result.lines.custom_minimum_size.x >= 880.0, "result text must keep a readable width")
	result.free()

func _collect_narrow_labels(node: Node, result: Array) -> void:
	if node is Label:
		var label := node as Label
		if label.text.length() >= 8 and label.custom_minimum_size.x > 0.0 and label.custom_minimum_size.x < 120.0:
			result.append(label.text)
	for child in node.get_children():
		_collect_narrow_labels(child, result)
