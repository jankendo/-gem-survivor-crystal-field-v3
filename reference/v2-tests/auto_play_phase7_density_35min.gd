extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, 35, "res://test-output/phase7/density_35min.csv", 1.0, 30.0 * 60.0, 600)
	_finish(failures)

func _finish(failures: Array) -> void:
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

