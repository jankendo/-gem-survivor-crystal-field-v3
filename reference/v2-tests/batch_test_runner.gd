extends SceneTree

var failures: Array[String] = []
var assertions := 0
var suite_timings: Array = []

func _initialize() -> void:
	var manifest_path := "res://tests/manifests/fast_gate.json"
	var output_path := "res://test-output/ci/fast_gate_timing.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")
	var manifest := _json(manifest_path)
	if manifest.is_empty():
		push_error("Batch manifest is missing or invalid: %s" % manifest_path)
		quit(2)
		return
	var started := Time.get_ticks_msec()
	for task in manifest.get("tasks", []):
		_run_task(task)
	var total_ms := Time.get_ticks_msec() - started
	var report := {
		"manifest": manifest_path,
		"assertions": assertions,
		"failures": failures,
		"total_ms": total_ms,
		"suites": suite_timings,
	}
	_write_json(output_path, report)
	print("Batch timing JSON: ", output_path)
	for row in suite_timings:
		print("[timing] ", row.id, " ", row.duration_ms, "ms")
	if failures.is_empty():
		print("Batch tests passed: ", assertions, " assertions in ", total_ms, "ms")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _run_task(task: Dictionary) -> void:
	var id := String(task.get("id", task.get("path", "unknown")))
	var path := String(task.get("path", ""))
	var method := String(task.get("method", "run"))
	var started := Time.get_ticks_msec()
	var status := "passed"
	var task_script = load(path)
	if task_script == null or not task_script.can_instantiate():
		failures.append("%s failed to load: %s" % [id, path])
		status = "failed"
	else:
		var instance = task_script.new()
		if instance == null or not instance.has_method(method):
			failures.append("%s has no method %s" % [id, method])
			status = "failed"
		elif String(task.get("kind", "suite")) == "harness":
			var args: Array = task.get("args", [])
			var result = instance.callv(method, args)
			if result is Dictionary and not bool(result.get("ok", false)):
				failures.append("%s harness returned ok=false" % id)
				status = "failed"
		else:
			instance.call(method, self)
	var duration := Time.get_ticks_msec() - started
	suite_timings.append({"id": id, "path": path, "duration_ms": duration, "status": status})

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _write_json(path: String, report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))

