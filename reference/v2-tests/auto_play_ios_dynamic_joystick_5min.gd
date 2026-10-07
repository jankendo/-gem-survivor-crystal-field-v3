extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, 5, "res://test-output/ios_perf_5min.csv")
	_finish(failures, "AutoPlay iOS Dynamic Joystick OK: 5 minutes with independent move touch.")

func _finish(failures: Array, message: String) -> void:
	if failures.is_empty():
		print(message)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
