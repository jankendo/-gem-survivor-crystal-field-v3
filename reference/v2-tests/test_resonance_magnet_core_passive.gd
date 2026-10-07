extends RefCounted

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const ResonanceMagnetSystemScript = preload("res://scripts/systems/ResonanceMagnetSystem.gd")

func run(t) -> void:
	test_resonance_magnet_exp_bonus(t)
	test_resonance_magnet_periodic_collection(t)

func test_resonance_magnet_exp_bonus(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "resonance-exp")
	var base = state.passive_exp_multiplier()
	state.passives["resonance_magnet_core"] = 1
	t.assert_true(state.passive_exp_multiplier() > base, "resonance magnet should increase exp multiplier")

func test_resonance_magnet_periodic_collection(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "resonance-collect")
	state.passives["resonance_magnet_core"] = 1
	state.resonance_magnet_timer = 0.1
	for i in range(6):
		state.gems.append(ExpGemScript.new(state.player_position + Vector2(100 + i * 10, 0), 5))
	var events: Array = []
	ResonanceMagnetSystemScript.new().process(state, 0.2, events)
	t.assert_eq(state.gems.size(), 0, "resonance magnet should collect nearby gems on timer")
	t.assert_true(state.gems_collected_by_passive >= 6, "passive collection should be counted")
