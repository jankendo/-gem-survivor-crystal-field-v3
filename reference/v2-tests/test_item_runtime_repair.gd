extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9107)
	state.field_drops.append({"id": "test_invalid", "position": Vector2.ZERO, "radius": 24.0, "collected": false})
	var summary: Dictionary = state.validate_active_pickups()
	t.assert_true(int(summary.get("repaired", 0)) > 0 or int(summary.get("skipped", 0)) > 0, "invalid runtime pickup should be repaired or safely removed")
	Utils.assert_active_pickups_valid(t, state, "runtime_repair")
