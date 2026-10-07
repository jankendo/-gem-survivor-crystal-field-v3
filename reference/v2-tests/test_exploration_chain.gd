extends RefCounted

const ExplorationChainSystemScript = preload("res://scripts/systems/ExplorationChainSystem.gd")

func run(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(662, "chain")
	var system = ExplorationChainSystemScript.new()
	var events: Array = []
	for i in range(5):
		events = [{"type": "field_drop_pickup"}]
		system.process(state, 0.1, events)
	t.assert_eq(state.exploration_chain, 5, "five exploration actions should build chain x5")
	t.assert_eq(state.exploration_chain_max, 5, "maximum chain should be recorded")
	t.assert_true(state.exploration_chain_currency_bonus >= 5, "chain x2 should grant currency bonus")
	t.assert_true(state.dynamic_drop_rate_multiplier >= 1.5, "chain x3 should boost drop rate")
	t.assert_true(state.gem_fever_timer > 0.0, "chain x4 should trigger gem fever")
	t.assert_true(state.rare_drop_multiplier >= 1.75, "chain x5 should boost rare drops")
	system.process(state, 61.0, [])
	t.assert_eq(state.exploration_chain, 0, "chain should expire after the configured window")
