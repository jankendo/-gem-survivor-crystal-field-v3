extends RefCounted

const Objective = preload("res://scripts/systems/ObjectiveIndicatorSystem.gd")
const State = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = State.new()
	state.start_new_run(60606, "event-priority")
	state.elapsed_seconds = 10.0
	state.current_goals = []
	state.field_drops = []
	state.field_equipment = []
	state.chests = []
	state.field_gimmicks = []
	state.danger_zones = [{"position": Vector2(20, 0)}]
	state.gems = []
	state.player_position = Vector2.ZERO
	state.navigation_targets = {"field_event": {"enabled": true, "position": Vector2(100, 0), "label": "イベント結晶壁"}}
	var targets := Objective.new().targets_for_state(state, 3)
	t.assert_eq(targets[0].get("label"), "イベント結晶壁", "exact event target must outrank generic danger target")
