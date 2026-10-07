extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9102)
	var result: Dictionary = state.resolve_pickup_position({
		"pickup_type": "field_drop",
		"position": Vector2.ZERO,
		"radius": 24.0,
		"origin": state.player_position,
		"min_distance": 300.0,
		"rng": state.rng.stream_rng("test_invalid_repair", 1)
	})
	t.assert_true(bool(result.get("ok", false)), "invalid pickup candidate should be repaired to a safe cell")
	t.assert_true(state.is_valid_pickup_position(result.get("position", Vector2.INF), "field_drop", 24.0), "repaired pickup should validate")
