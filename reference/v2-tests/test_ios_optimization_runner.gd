extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suites := [
		"res://tests/test_ios_dynamic_joystick_anywhere_left.gd",
		"res://tests/test_ios_safe_area_notch_landscape.gd",
		"res://tests/test_ios_ui_overlap_regression.gd",
		"res://tests/test_ios_hud_layout_profiles.gd",
		"res://tests/test_ios_menu_safe_area_overlap.gd",
		"res://tests/test_ios_ui_update_throttling.gd",
		"res://tests/test_ios_effect_budget_no_quality_drop.gd",
		"res://tests/test_ios_object_pooling_stability.gd",
		"res://tests/test_ios_spatial_optimization.gd",
		"res://tests/test_ios_performance_logging.gd",
		"res://tests/test_desktop_unchanged_after_ios_optimization.gd"
	]
	for path in suites:
		print("Running ", path)
		load(path).new().run(self)
	if failures.is_empty():
		print("iOS optimization tests passed: ", assertions)
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
		failures.append("%s | expected=%s actual=%s" % [message, expected, actual])
