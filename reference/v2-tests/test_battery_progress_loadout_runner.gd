extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suites := [
		"res://tests/test_ios_energy_budget.gd",
		"res://tests/test_ios_energy_logging.gd",
		"res://tests/test_ios_battery_saver_settings.gd",
		"res://tests/test_unlock_progress_display.gd",
		"res://tests/test_progress_counters_persist.gd",
		"res://tests/test_result_progress_delta.gd",
		"res://tests/test_wall_collision_smooth_slide.gd",
		"res://tests/test_blessing_effect_descriptions.gd",
		"res://tests/test_blessing_ui_ios_readability.gd",
		"res://tests/test_weapon_passive_toggle_menu.gd",
		"res://tests/test_disable_slot_unlocks.gd",
		"res://tests/test_candidate_pool_respects_disabled_items.gd",
		"res://tests/test_weapon_passive_balance_after_toggle.gd",
		"res://tests/test_desktop_after_progress_toggle_energy_update.gd"
	]
	for suite_path in suites:
		print("Running ", suite_path)
		load(suite_path).new().run(self)
	if failures.is_empty():
		print("Battery/progress/loadout tests passed: ", assertions)
		quit(0)
		return
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
