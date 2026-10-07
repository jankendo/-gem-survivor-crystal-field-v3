extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(
		self,
		25,
		"res://test-output/ios_performance_log_25min.csv",
		1.0,
		20.0 * 60.0,
		100000
	)
	if failures.is_empty():
		print("iOS performance autoplay 20-25min OK.")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
