extends SceneTree

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	var suite_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			suite_path = argument.trim_prefix("--suite=")
	if suite_path == "" or not ResourceLoader.exists(suite_path):
		push_error("Pass an existing suite with --suite=res://tests/test_name.gd")
		quit(2)
		return
	print("Running ", suite_path)
	var suite_script = load(suite_path)
	if suite_script == null or not suite_script.can_instantiate():
		push_error("Suite failed to load: %s" % suite_path)
		quit(2)
		return
	var suite = suite_script.new()
	if suite == null or not suite.has_method("run"):
		push_error("Suite has no run(t): %s" % suite_path)
		quit(2)
		return
	suite.run(self)
	if failures.is_empty():
		print("Single suite passed: ", assertions)
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
