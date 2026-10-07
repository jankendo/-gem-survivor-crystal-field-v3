extends SceneTree

const Harness = preload("res://tests/IosPerfAutoplayHarness.gd")

func _initialize() -> void:
	# Nightly proves 0-20 and 20-25 minutes in parallel shards. Start this final
	# interval at 25 minutes with the normal cap fully populated.
	var failures: Array = await Harness.new().run(
		self,
		30,
		"res://test-output/ios_performance_log_30min.csv",
		1.0,
		25.0 * 60.0,
		100000
	)
	if failures.is_empty():
		print("AutoPlay iOS Performance OK: 30 minute synthetic capture.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
