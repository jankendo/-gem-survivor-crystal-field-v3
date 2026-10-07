extends RefCounted

const InputModeSystemScript = preload("res://scripts/systems/InputModeSystem.gd")

func run(t) -> void:
	var input_mode = InputModeSystemScript.new()
	input_mode.configure({"touch_ui_mode": "auto"}, "Windows")
	t.assert_true(not input_mode.is_touch_mode(), "Windows default must keep desktop keyboard and mouse mode")
	t.assert_true(input_mode.keyboard_hints_allowed(), "Windows default must retain keyboard hints")
	input_mode.configure({"touch_ui_mode": "on"}, "Windows")
	t.assert_true(input_mode.is_touch_mode(), "Windows touch preview must remain opt-in")
	t.assert_true(not input_mode.keyboard_hints_allowed(), "touch preview must use the mobile presentation")

	var player_source := FileAccess.open("res://scripts/systems/Player.gd", FileAccess.READ).get_as_text()
	for key_name in ["KEY_W", "KEY_A", "KEY_S", "KEY_D", "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT"]:
		t.assert_true(player_source.contains(key_name), "desktop movement must retain %s" % key_name)
	var game_source := FileAccess.open("res://scripts/ui/GameScreen.gd", FileAccess.READ).get_as_text()
	for key_name in ["KEY_F", "KEY_R", "KEY_ESCAPE", "KEY_1", "KEY_2", "KEY_3"]:
		t.assert_true(game_source.contains(key_name), "desktop game controls must retain %s" % key_name)
	var speed_source := FileAccess.open("res://scripts/systems/SpeedHoldSystem.gd", FileAccess.READ).get_as_text()
	t.assert_true(speed_source.contains("KEY_SHIFT"), "desktop speed hold must retain Shift")
	var arena_source := FileAccess.open("res://scripts/ui/ArenaView.gd", FileAccess.READ).get_as_text()
	t.assert_true(arena_source.contains("InputEventMouseButton"), "desktop mouse input must remain available")
