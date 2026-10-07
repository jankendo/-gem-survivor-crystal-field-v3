extends RefCounted

const TapOnlyNavigationSystemScript = preload("res://scripts/systems/TapOnlyNavigationSystem.gd")

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var auditor = TapOnlyNavigationSystemScript.new()
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	t.assert_true(auditor.audit_screen(main).is_empty(), "touch title should not contain keyboard-only text")
	main.show_help(false)
	t.assert_true(auditor.audit_screen(main).is_empty(), "touch tutorial should not contain keyboard-only text")
	main.free()
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	t.assert_true(auditor.audit_screen(game, false).is_empty(), "touch HUD should not contain keyboard-only text")
	game._toggle_pause()
	for index in [5, 7]:
		game.set_pause_tab(index)
		t.assert_true(auditor.audit_screen(game, false).is_empty(), "touch pause tab %d should not contain keyboard-only text" % index)
	game.free()
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	t.assert_true(auditor.audit_screen(result).is_empty(), "touch result should not contain keyboard-only text")
	result.free()
	SaveSystem.new().update_settings(old_settings)
