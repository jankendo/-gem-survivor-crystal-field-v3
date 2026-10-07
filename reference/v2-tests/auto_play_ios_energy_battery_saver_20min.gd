extends SceneTree

const Harness = preload("res://tests/IosEnergyAutoplayHarness.gd")

func _initialize() -> void:
	var failures: Array = await Harness.new().run(self, true, "res://test-output/ios_energy_log_battery_saver.csv")
	if failures.is_empty():
		print("AutoPlay iOS Energy OK: 20 minute battery saver profile.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
