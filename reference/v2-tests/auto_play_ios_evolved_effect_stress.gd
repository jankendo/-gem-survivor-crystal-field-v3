extends SceneTree

const HarnessScript = preload("res://tests/Phase7EffectStressHarness.gd")

func _initialize() -> void:
	var result: Dictionary = HarnessScript.new().run("res://test-output/phase7/ios_evolved_effect_stress")
	quit(0 if bool(result.get("ok", false)) else 1)

