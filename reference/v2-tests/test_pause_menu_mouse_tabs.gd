extends RefCounted

func run(t) -> void:
	test_pause_tabs_click(t)
	test_pause_title_requires_confirm(t)

func _find_button(node: Node, label_part: String) -> Button:
	if node is Button and (node as Button).text.find(label_part) >= 0:
		return node as Button
	for child in node.get_children():
		var found = _find_button(child, label_part)
		if found != null:
			return found
	return null

func test_pause_tabs_click(t) -> void:
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	var button = _find_button(game, "進化条件")
	t.assert_true(button != null, "pause menu should expose evolution tab button")
	button.pressed.emit()
	t.assert_eq(game.pause_tab_index, 2, "clicking evolution tab should change tab")
	t.assert_true(game.pause_content.text.find("進化条件") >= 0, "evolution tab content should show")
	game.free()

func test_pause_title_requires_confirm(t) -> void:
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	var button = _find_button(game, "タイトルへ戻る")
	t.assert_true(button != null, "pause footer should expose title button")
	button.pressed.emit()
	t.assert_true(game.pause_confirm_dialog.visible, "title return should show confirmation dialog")
	game.free()
