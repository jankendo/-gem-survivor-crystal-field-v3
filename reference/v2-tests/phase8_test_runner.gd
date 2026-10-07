extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suites := [
		"res://tests/test_extreme_lite_profile.gd",
		"res://tests/test_extreme_lite_critical_visibility.gd",
		"res://tests/test_battery_saver_effective_settings.gd",
		"res://tests/test_battery_saver_restores_user_settings.gd",
		"res://tests/test_battery_saver_simulation_parity.gd",
		"res://tests/test_speed_lock_system.gd",
		"res://tests/test_touch_speed_lock_integration.gd",
		"res://tests/test_speed_lock_modal_pause.gd",
		"res://tests/test_manual_run_exit_settlement.gd",
		"res://tests/test_manual_exit_emits_once.gd",
		"res://tests/test_manual_exit_debug_progress_block.gd",
		"res://tests/test_manual_exit_result_navigation.gd",
		"res://tests/test_settings_scroll_retention.gd",
		"res://tests/test_settings_choice_popup.gd",
		"res://tests/test_settings_choice_does_not_rebuild_screen.gd",
		"res://tests/test_settings_popup_safe_area.gd",
		"res://tests/test_core_candidates_enabled_only.gd",
		"res://tests/test_core_candidates_unlocked_only.gd",
		"res://tests/test_core_candidates_seed_determinism.gd",
		"res://tests/test_core_visual_identity.gd",
		"res://tests/test_locked_field_objects_hidden.gd",
		"res://tests/test_field_object_unlock_visibility.gd",
		"res://tests/test_field_event_exact_navigation.gd",
		"res://tests/test_field_event_navigation_cleanup.gd",
		"res://tests/test_event_target_priority.gd",
		"res://tests/test_shop_unlock_condition_presentation.gd",
		"res://tests/test_all_weapon_passive_conditions_have_japanese_text.gd",
	]
	for suite_path in suites:
		print("Running ", suite_path)
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("Suite failed to load: %s" % suite_path)
			continue
		suite_script.new().run(self)
	if failures.is_empty():
		print("Phase 8 tests passed: ", assertions)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
