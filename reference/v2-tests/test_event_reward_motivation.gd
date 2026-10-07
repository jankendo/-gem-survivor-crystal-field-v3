extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EventScript = preload("res://scripts/systems/FieldEventSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771602, "event-motivation")
	for event in state.field_event_defs.get("events", []):
		t.assert_true(String(event.get("risk", "")) != "", "event should display risk")
		t.assert_true(String(event.get("reward", "")) != "", "event should display reward")
		t.assert_true(String(event.get("success_condition_ja", "")) != "", "event should display success condition")
		t.assert_true(String(event.get("failure_condition_ja", "")) != "", "event should display failure condition")
		t.assert_true((event.get("reward_candidates", []) as Array).size() > 0, "event should pre-display candidate rewards")
	var system = EventScript.new()
	var events: Array = []
	system.force_start(state, "gem_storm", events)
	t.assert_true(String(state.active_field_event.get("reward", "")).find("スキップ") >= 0, "started event should retain visible reward motivation")
	state.field_event_timer = 0.0
	system.process(state, 0.1, events)
	var rewarded := false
	for event in events:
		if String(event.get("type", "")) == "field_event_reward":
			rewarded = true
	t.assert_true(rewarded, "successful event should emit a concrete reward event")
