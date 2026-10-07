extends SceneTree

const Harness = preload("res://tests/IosEnergyAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, false, "res://test-output/ios_energy_log_standard.csv")
	_finish(failures, "standard")

func _finish(failures: Array, profile: String) -> void:
	if failures.is_empty():
		print("AutoPlay iOS Energy OK: 20 minute %s profile." % profile)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
