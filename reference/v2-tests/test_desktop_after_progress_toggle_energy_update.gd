extends RefCounted

func run(t) -> void:
	var player_source := FileAccess.get_file_as_string("res://scripts/systems/Player.gd")
	for key_name in ["KEY_W", "KEY_A", "KEY_S", "KEY_D", "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT"]:
		t.assert_true(player_source.contains(key_name), "desktop movement should retain %s" % key_name)
	var game_source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	for key_name in ["KEY_F", "KEY_R", "KEY_ESCAPE", "KEY_1", "KEY_2", "KEY_3"]:
		t.assert_true(game_source.contains(key_name), "desktop actions should retain %s" % key_name)
	t.assert_true(FileAccess.get_file_as_string("res://scripts/systems/SpeedHoldSystem.gd").contains("KEY_SHIFT"), "desktop speed hold should retain Shift")
	var save := SaveSystem.new()
	var original: Dictionary = save.load_data().get("settings", {}).duplicate(true)
	save.update_settings({"touch_ui_mode": "off"})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_loadout()
	t.assert_eq(main.screen_mode, "loadout", "desktop should open weapon/passive management")
	t.assert_true(_find_text(main, "武器OFF枠："), "desktop loadout should show OFF slot usage")
	main.show_quests()
	t.assert_true(_find_text(main, "現在："), "desktop achievements should show progress")
	main.show_character_select()
	t.assert_true(_find_text(main, "数値："), "desktop character screen should show blessing effects")
	main.free()
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	t.assert_true(not game.touch_root.visible or not game.touch_control_system.should_show(), "desktop should not show the iOS HUD by default")
	game.free()
	save.update_settings(original)

func _find_text(node: Node, part: String) -> bool:
	if node is Label and (node as Label).text.contains(part):
		return true
	if node is Button and (node as Button).text.contains(part):
		return true
	for child in node.get_children():
		if _find_text(child, part):
			return true
	return false
