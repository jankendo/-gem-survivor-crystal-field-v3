extends RefCounted

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	t.assert_true(game.pause_overlay.visible, "touch pause overlay should open")
	t.assert_true(game.pause_tab_buttons.size() == 8, "touch pause should expose the Phase 12 tab set")
	for button in game.pause_tab_buttons:
		t.assert_true((button as Button).custom_minimum_size.y >= 56.0, "touch pause tabs should be at least 56px high")
	t.assert_true(_find_button(game, "ゲームへ戻る") != null, "touch pause should expose resume")
	t.assert_true(_find_button(game, "タイトルへ戻る") != null, "touch pause should expose confirmed title return")
	game.free()
	SaveSystem.new().update_settings(old_settings)

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
