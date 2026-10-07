extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9101)
	t.assert_true(not state.map_data.is_empty(), "map data should exist")
	t.assert_true(state.item_placement_system.validator.reachable_lookup.size() > 0, "reachable component should be cached")
	Utils.assert_active_pickups_valid(t, state, "validator")
