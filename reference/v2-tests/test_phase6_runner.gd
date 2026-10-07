extends SceneTree

var failures: Array[String] = []
var assertions := 0

func _initialize() -> void:
	var suites: Array[String] = [
		"res://tests/test_phase6_renderer_contract.gd",
		"res://tests/test_phase6_ui_dirty_refresh_contract.gd",
		"res://tests/test_phase6_arena_cache_contract.gd",
		"res://tests/test_phase6_release_telemetry_contract.gd",
	]
	for suite_path in suites:
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
		print("All Phase 6 tests passed: ", assertions)
		quit(0)
		return
	push_error("%d Phase 6 tests failed." % failures.size())
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
