extends SceneTree

const Harness = preload("res://tests/Phase6BenchmarkHarness.gd")

func _initialize() -> void:
	var summary: Dictionary = await Harness.new().run(self, 60.0, "res://test-output/phase6/baseline_4_2_forward_plus", "Godot 4.2 Forward+ baseline", 60606)
	if bool(summary.get("ok", false)):
		print("Phase 6 baseline benchmark OK.")
		quit(0)
		return
	push_error(String(summary.get("error", "Phase 6 baseline benchmark failed")))
	quit(1)

