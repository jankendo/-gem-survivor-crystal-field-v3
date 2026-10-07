extends RefCounted

const InputModeSystemScript = preload("res://scripts/systems/InputModeSystem.gd")
const TouchControlSystemScript = preload("res://scripts/systems/TouchControlSystem.gd")

func run(t) -> void:
	var mode = InputModeSystemScript.new()
	t.assert_eq(mode.configure({}, "Windows"), InputModeSystemScript.DESKTOP_KEYBOARD_MOUSE, "Windows should default to keyboard and mouse")
	t.assert_true(not mode.is_touch_mode(), "desktop default must not use mobile layout")
	t.assert_true(mode.keyboard_hints_allowed(), "desktop key hints must remain available")
	t.assert_eq(mode.configure({"desktop_touch_preview": true}, "Windows"), InputModeSystemScript.DESKTOP_TOUCH_PREVIEW, "desktop preview should explicitly enable mobile UI")

	var controls = TouchControlSystemScript.new()
	controls.configure({}, "Windows")
	t.assert_true(not controls.should_show(), "large touch controls must stay hidden on desktop")
	controls.configure({"touch_ui_mode": "on"}, "Windows")
	t.assert_true(controls.should_show(), "touch controls should appear only in explicit desktop preview")

