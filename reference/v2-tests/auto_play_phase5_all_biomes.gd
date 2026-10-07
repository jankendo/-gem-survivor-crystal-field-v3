extends SceneTree

const Harness = preload("res://tests/phase4_environment_autoplay.gd")

func _initialize() -> void:
	var summary := Harness.new().simulate_environment("ios_low", 600, [20260501, 20260502, 20260503, 20260504], "phase5_all_biomes")
	var ok := int(summary.get("missing_texture_count", 0)) == 0 and int(summary.get("variant_mismatch_count", 0)) == 0
	quit(0 if ok else 1)
