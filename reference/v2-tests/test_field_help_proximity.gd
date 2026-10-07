extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const FieldHelpSystemScript = preload("res://scripts/systems/FieldHelpSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(910)
	state.player_position = Vector2(500, 500)
	state.field_drops = [{"id": "healing_crystal", "position": Vector2(540, 500), "collected": false, "unlock_seconds": 0.0}]
	var events: Array = []
	var target := FieldHelpSystemScript.new().process(state, events)
	t.assert_true(not target.is_empty(), "nearby field target is explained automatically")
	t.assert_true(events.any(func(event): return event.get("type", "") == "field_discovery"), "normal proximity discovery remains active")
