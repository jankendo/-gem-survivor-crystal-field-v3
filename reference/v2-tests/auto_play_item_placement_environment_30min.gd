extends SceneTree

const Harness = preload("res://tests/phase4_environment_autoplay.gd")

func _initialize() -> void:
	var summary := Harness.new().simulate_item_placement_with_environment(1800, 100, "item_placement_environment_30min")
	quit(0 if int(summary.get("invalid_count", 0)) == 0 and int(summary.get("environment_variant_mismatch_count", 0)) == 0 else 1)
