extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, 1, "res://test-output/phase5/ios_60sec.csv")
	if failures.is_empty():
		print("Phase 5 iOS 60sec performance autoplay OK.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
