extends RefCounted

const Availability = preload("res://scripts/systems/FieldObjectAvailabilitySystem.gd")

func run(t) -> void:
	var state := {"elapsed_seconds": 99.0}
	var object := {"unlock_seconds": 100.0, "collected": false}
	t.assert_true(not Availability.new().is_available_now(state, object), "locked field object must be hidden")
