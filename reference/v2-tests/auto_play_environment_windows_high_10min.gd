extends SceneTree

const Harness = preload("res://tests/phase4_environment_autoplay.gd")

func _initialize() -> void:
	var summary := Harness.new().simulate_environment("high", 600, [20260421, 20260422, 20260423], "environment_windows_high_10min")
	quit(0 if int(summary.get("missing_texture_count", 0)) == 0 and int(summary.get("variant_mismatch_count", 0)) == 0 else 1)
