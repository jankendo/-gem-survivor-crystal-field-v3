extends RefCounted

func run(t) -> void:
	test_esc_pause_surface_exists(t)
	test_pause_tabs_show_runtime_state(t)
	test_pause_settings_toggle_text(t)

func _game() -> GameScreen:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	return game

func test_esc_pause_surface_exists(t) -> void:
	var game := _game()
	game._toggle_pause()
	t.assert_true(game.state.paused, "pause should set state.paused")
	t.assert_true(game.pause_overlay.visible, "pause overlay should become visible")
	t.assert_true(game.pause_content.text.find("ステータス") >= 0, "pause should open on status tab")
	game.free()

func test_pause_tabs_show_runtime_state(t) -> void:
	var game := _game()
	game._toggle_pause()
	game.set_pause_tab(1, "weapon")
	t.assert_true(game.pause_equipment_grid.visible, "equipment tab should show the weapon and passive grid")
	t.assert_eq(game.pause_equipment_grid.selected_kind, "weapon", "2-key compatible focus should select weapons")
	game.set_pause_tab(5)
	t.assert_true(game.pause_content.text.find("ルーン契約") >= 0, "contract tab should show rune contract state")
	t.assert_true(_find_button(game.pause_overlay, "タイトルへ戻る") != null, "pause should include title return action")
	game.free()

func test_pause_settings_toggle_text(t) -> void:
	var game := _game()
	game._toggle_pause()
	game.set_pause_tab(6)
	t.assert_true(game.pause_content.text.find("無限強化だけ自動選択") >= 0, "settings tab should expose auto infinite setting")
	t.assert_true(game.pause_content.text.find("自動回収ドローン") >= 0, "settings tab should expose auto recall drone setting")
	game.free()

func _find_button(node: Node, label_part: String) -> Button:
	if node is Button and (node as Button).text.find(label_part) >= 0:
		return node as Button
	for child in node.get_children():
		var found = _find_button(child, label_part)
		if found != null:
			return found
	return null
