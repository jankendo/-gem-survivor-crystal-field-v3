extends SceneTree

const Harness = preload("res://tests/phase4_environment_autoplay.gd")

func _initialize() -> void:
	var summary := Harness.new().simulate_environment("ios_low", 600, [20260411, 20260412, 20260413], "environment_ios_low_10min")
	quit(0 if int(summary.get("missing_texture_count", 0)) == 0 and int(summary.get("variant_mismatch_count", 0)) == 0 else 1)
