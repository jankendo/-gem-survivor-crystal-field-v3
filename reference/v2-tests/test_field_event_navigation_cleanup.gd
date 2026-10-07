extends RefCounted

const Navigation = preload("res://scripts/systems/FieldEventNavigationSystem.gd")

func run(t) -> void:
	var state := {"active_field_event": {}, "navigation_targets": {"field_event": {"enabled": true}}}
	Navigation.new().update(state)
	t.assert_true(not state.navigation_targets.has("field_event"), "event navigation must clear when event ends")
