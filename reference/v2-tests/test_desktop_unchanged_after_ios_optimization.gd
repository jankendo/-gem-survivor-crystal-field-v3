extends RefCounted

const TouchScript = preload("res://scripts/systems/TouchControlSystem.gd")
const InputScript = preload("res://scripts/systems/InputModeSystem.gd")

func run(t) -> void:
	var input = InputScript.new()
	t.assert_eq(input.configure({}, "Windows"), "desktop_keyboard_mouse", "Windows should retain desktop input mode")
	t.assert_true(input.keyboard_hints_allowed(), "desktop keyboard controls must remain enabled")
	var touch = TouchScript.new()
	touch.configure({}, "Windows")
	t.assert_true(not touch.should_show(), "dynamic joystick must remain hidden on Windows by default")
	touch.configure({"touch_ui_mode": "on"}, "Windows")
	t.assert_true(touch.should_show(), "desktop touch preview should remain available")
