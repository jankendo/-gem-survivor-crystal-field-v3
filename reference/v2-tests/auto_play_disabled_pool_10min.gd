extends SceneTree

const Harness = preload("res://tests/DisabledPoolAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, "res://test-output/disabled_pool_10min.json")
	_finish(failures)

func _finish(failures: Array) -> void:
	if failures.is_empty():
		print("AutoPlay Disabled Pool OK: 10 minute equivalent.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
