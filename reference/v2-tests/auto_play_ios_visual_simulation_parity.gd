extends SceneTree

const HarnessScript = preload("res://tests/Phase7EffectStressHarness.gd")

func _initialize() -> void:
	var result: Dictionary = HarnessScript.new().run("res://test-output/phase7/visual_simulation_parity")
	if not bool(result.get("simulation_parity", false)):
		push_error("Phase 7 visual profiles changed simulation state.")
		quit(1)
		return
	quit(0)

