extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9103)
	for drop in state.field_drops:
		if bool(drop.get("collected", false)):
			continue
		var result: Dictionary = state.pickup_validation_result(drop.get("position", Vector2.INF), "field_drop", float(drop.get("radius", 24.0)))
		t.assert_true(not (result.get("reasons", []) as Array).has("wall_clearance"), "field drop should have wall clearance")
