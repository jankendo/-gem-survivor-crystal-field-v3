extends RefCounted

const ExplorationMasterySystemScript = preload("res://scripts/systems/ExplorationMasterySystem.gd")
const CurrencySystemScript = preload("res://scripts/systems/CurrencySystem.gd")

func run(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(661, "mastery")
	var events: Array = [
		{"type": "field_drop_pickup", "spawn_distance": 1700.0, "in_danger": true},
		{"type": "gimmick_destroyed", "id": "spawn_rift"},
		{"type": "field_event_success", "id": "gem_storm"}
	]
	var system = ExplorationMasterySystemScript.new()
	system.process(state, events)
	t.assert_eq(state.exploration_score, 75, "mastery should score drop, risk, gimmick and event")
	t.assert_eq(state.exploration_rank, "B", "75 exploration points should reach rank B")
	t.assert_eq(state.field_event_successes, 1, "successful field event should be counted")
	t.assert_true(state.exploration_currency_bonus >= 0.10, "rank B should grant at least 10 percent currency bonus")
	var base_summary = {"survival_time": 600.0, "kills": 100, "exploration_currency_bonus": 0.0, "exploration_chain_currency_bonus": 0}
	var bonus_summary = base_summary.duplicate(true)
	bonus_summary["exploration_currency_bonus"] = state.exploration_currency_bonus
	t.assert_true(
		CurrencySystemScript.new().calculate_run_currency(bonus_summary, {}, {}) >
		CurrencySystemScript.new().calculate_run_currency(base_summary, {}, {}),
		"exploration rank bonus should increase run currency"
	)
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	result.show_summary({"exploration_rank": state.exploration_rank, "exploration_score": state.exploration_score})
	t.assert_true(result.lines.text.find("探索ランク：B") >= 0, "result should display exploration rank")
	result.free()
