extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9104)
	for item in state.field_equipment:
		var result: Dictionary = state.pickup_validation_result(item.get("position", Vector2.INF), "field_equipment", 22.0)
		t.assert_true(not (result.get("reasons", []) as Array).has("unreachable"), "field equipment should be reachable")
