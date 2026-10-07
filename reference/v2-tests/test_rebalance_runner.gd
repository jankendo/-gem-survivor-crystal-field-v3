extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suites := [
		"res://tests/test_chest_pacing.gd",
		"res://tests/test_chest_evolution_system.gd",
		"res://tests/test_weapon_evolutions_extended.gd",
		"res://tests/test_overclock_system.gd",
		"res://tests/test_boss_patterns.gd",
		"res://tests/test_hp_ui.gd",
		"res://tests/test_performance_limits.gd",
		"res://tests/test_rng.gd",
		"res://tests/test_layout_settings.gd",
		"res://tests/test_currency_system.gd",
		"res://tests/test_melee_rush.gd",
		"res://tests/test_export_preset.gd",
		"res://tests/test_touch_controls_config.gd",
		"res://tests/test_weapon_balance_targets.gd",
		"res://tests/test_passive_balance_targets.gd",
		"res://tests/test_evolution_balance_targets.gd"
	]
	for suite_path in suites:
		print("Running ", suite_path)
		load(suite_path).new().run(self)
	if failures.is_empty():
		print("Rebalance tests passed: ", assertions)
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
