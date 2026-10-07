extends RefCounted

const TouchControlSystemScript = preload("res://scripts/systems/TouchControlSystem.gd")
const PerformanceProfileSystemScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const InputModeSystemScript = preload("res://scripts/systems/InputModeSystem.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_touch_visibility_and_sizes(t)
	test_combined_direction_is_bounded(t)
	test_ios_performance_profile(t)
	test_touch_settings_are_persisted(t)
	test_input_modes_and_touch_actions(t)

func test_touch_visibility_and_sizes(t) -> void:
	var system = TouchControlSystemScript.new()
	system.configure({}, "Windows")
	t.assert_true(not system.should_show(), "auto touch UI should stay hidden on Windows")
	system.configure({"touch_ui_mode": "auto", "virtual_joystick_enabled": true}, "iOS")
	t.assert_true(system.should_show_joystick(), "auto touch UI should show the joystick on iOS")
	system.configure({"touch_ui_mode": "on", "virtual_joystick_enabled": false, "touch_button_size": "large"}, "Windows")
	t.assert_true(system.should_show(), "forced touch UI should show on desktop for testing")
	t.assert_true(not system.should_show_joystick(), "joystick toggle should be honored")
	t.assert_eq(system.button_extent(), 92.0, "large touch buttons should use the accessible extent")

func test_combined_direction_is_bounded(t) -> void:
	var system = TouchControlSystemScript.new()
	var direction = system.combined_direction(Vector2.RIGHT, Vector2.DOWN)
	t.assert_true(absf(direction.length() - 1.0) < 0.001, "combined keyboard and touch direction should be normalized")

func test_ios_performance_profile(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(4201)
	var profile = PerformanceProfileSystemScript.new().apply_to_state(state, {"render_quality": "low"}, "iOS")
	t.assert_eq(profile, "ios_low", "iOS low quality should select the mobile profile")
	t.assert_eq(state.max_enemies(), 600, "iOS low profile should not reduce enemy count")
	t.assert_eq(state.max_projectiles(), 500, "iOS low profile should preserve simulation projectiles")
	var limits: Dictionary = PerformanceProfileSystemScript.new().ui_limits({"render_quality": "low"}, "iOS")
	t.assert_eq(int(limits.max_rendered_projectiles), 120, "iOS low profile should cap rendered projectiles only")

func test_touch_settings_are_persisted(t) -> void:
	var save = SaveSystem.new("user://test_touch_controls_config.save")
	save.save_data({"settings": {
		"touch_ui_mode": "on",
		"virtual_joystick_enabled": false,
		"touch_button_size": "large",
		"touch_button_opacity": 0.64,
		"touch_handedness": "left",
		"render_quality": "low"
	}})
	var settings: Dictionary = save.load_data().get("settings", {})
	t.assert_eq(String(settings.get("touch_ui_mode", "")), "on", "touch UI mode should persist")
	t.assert_eq(bool(settings.get("virtual_joystick_enabled", true)), false, "virtual joystick toggle should persist")
	t.assert_eq(String(settings.get("touch_button_size", "")), "large", "touch button size should persist")
	t.assert_eq(String(settings.get("touch_handedness", "")), "left", "touch handedness should persist")
	t.assert_true(absf(float(settings.get("touch_button_opacity", 0.0)) - 0.64) < 0.001, "touch button opacity should persist")
	t.assert_eq(String(settings.get("render_quality", "")), "low", "render quality should persist")

func test_input_modes_and_touch_actions(t) -> void:
	var mode = InputModeSystemScript.new()
	t.assert_eq(mode.configure({}, "iOS"), "ios_touch", "iOS should force touch mode")
	t.assert_true(not mode.keyboard_hints_allowed(), "iOS should not expose keyboard hints")
	t.assert_eq(mode.configure({"touch_ui_mode": "on"}, "Windows"), "desktop_touch_preview", "Windows should support touch preview")
	var controls = TouchControlSystemScript.new()
	controls.configure({"touch_ui_mode": "on", "touch_handedness": "left"}, "Windows")
	controls.set_action_pressed("action_drone", true)
	t.assert_true(controls.consume_action("action_drone"), "touch action should be consumable")
	t.assert_true(controls.controls_swapped(), "left handed mode should swap controls")
