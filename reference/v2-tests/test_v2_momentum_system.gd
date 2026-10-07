extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const V2MomentumSystemScript = preload("res://scripts/systems/V2MomentumSystem.gd")

func run(t) -> void:
	test_kill_streak_activates_momentum(t)
	test_no_damage_milestone_and_damage_reset(t)
	test_special_trigger_uses_existing_events(t)

func test_kill_streak_activates_momentum(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(2026)
	var system = V2MomentumSystemScript.new()
	var events: Array = []
	for i in range(20):
		events.append({"type": "enemy_die", "enemy": "slime"})
	system.process(state, 0.1, events)
	t.assert_true(state.v2_momentum_timer > 0.0, "kill streak should activate v2 momentum")
	t.assert_true(state.v2_momentum_score_multiplier > 1.0, "momentum should increase score multiplier")
	t.assert_eq(state.v2_best_kill_streak, 20, "best kill streak should be recorded")
	t.assert_true(_has_event(events, "v2_momentum"), "momentum event should be appended")

func test_no_damage_milestone_and_damage_reset(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(2026)
	var system = V2MomentumSystemScript.new()
	var events: Array = []
	system.process(state, 60.1, events)
	t.assert_true(state.v2_no_damage_best >= 60.0, "no damage timer should advance")
	t.assert_true(_has_event(events, "v2_momentum"), "no damage milestone should add momentum event")
	system.process(state, 0.1, [{"type": "player_damage"}])
	t.assert_eq(int(state.v2_no_damage_timer), 0, "player damage should reset no damage timer")

func test_special_trigger_uses_existing_events(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(2026)
	var system = V2MomentumSystemScript.new()
	var events: Array = [{"type": "evolution", "name": "星砕き"}]
	system.process(state, 0.1, events)
	t.assert_true(state.v2_peak_momentum_tier >= 3, "evolution should activate high tier momentum")
	t.assert_true(state.get_score_multiplier() > 1.0, "active momentum should affect score multiplier")

func _has_event(events: Array, event_type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == event_type:
			return true
	return false

