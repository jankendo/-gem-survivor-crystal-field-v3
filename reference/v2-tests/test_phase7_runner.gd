extends SceneTree

var failures: Array[String] = []
var assertions := 0

const SUITES: Array[String] = [
	"res://tests/test_visual_effect_budget_system.gd",
	"res://tests/test_visual_effect_priority.gd",
	"res://tests/test_visual_effect_coalescing.gd",
	"res://tests/test_weapon_render_style_cache.gd",
	"res://tests/test_no_simulation_projectile_culling.gd",
	"res://tests/test_no_simulation_gem_culling.gd",
	"res://tests/test_ios_visual_simulation_parity.gd",
	"res://tests/test_minimap_render_cache.gd",
	"res://tests/test_adaptive_arc_segments.gd",
	"res://tests/test_phase7_release_telemetry_disabled.gd",
]

func _initialize() -> void:
	for suite_path in SUITES:
		print("Running ", suite_path)
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("Suite failed to load: %s" % suite_path)
			continue
		var suite = suite_script.new()
		if suite == null or not suite.has_method("run"):
			failures.append("Suite has no run(t): %s" % suite_path)
			continue
		suite.run(self)
	if failures.is_empty():
		print("All Phase 7 tests passed: ", assertions)
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

