extends RefCounted

const Navigation = preload("res://scripts/systems/FieldEventNavigationSystem.gd")

func run(t) -> void:
	var state := {
		"active_field_event": {"target_kind": "danger_zone", "target_runtime_id": "event_1"},
		"danger_zones": [{"runtime_id": "other", "position": Vector2.ONE}, {"runtime_id": "event_1", "position": Vector2(8, 9)}],
		"navigation_targets": {},
		"player_position": Vector2.ZERO,
	}
	Navigation.new().update(state)
	var target: Dictionary = state.navigation_targets.get("field_event", {})
	t.assert_eq(target.get("runtime_id"), "event_1", "event navigation must point to the exact runtime object")
	t.assert_eq(target.get("position"), Vector2(8, 9), "event navigation must use exact target position")
