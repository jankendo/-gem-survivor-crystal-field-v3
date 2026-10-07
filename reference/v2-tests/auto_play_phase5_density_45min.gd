extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(
		self,
		45,
		"res://test-output/phase5/density_45min.csv",
		1.0,
		40.0 * 60.0,
		600
	)
	if failures.is_empty():
		print("Phase 5 density 45min autoplay OK.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
