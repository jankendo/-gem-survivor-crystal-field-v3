extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var state = Utils.new_state(9108)
	var result: Dictionary = state.resolve_pickup_position({
		"pickup_type": "field_drop",
		"position": Vector2(-9999.0, -9999.0),
		"radius": 24.0,
		"origin": state.player_position,
		"min_distance": 999999.0,
		"max_distance": 999999.0,
		"rng": state.rng.stream_rng("test_no_invalid_fallback", 1)
	})
	t.assert_true(not bool(result.get("ok", false)), "impossible placement should fail instead of using an invalid fallback")
	t.assert_eq(result.get("position", Vector2.INF), Vector2.INF, "failed placement must not return origin, zero, or map edge")
