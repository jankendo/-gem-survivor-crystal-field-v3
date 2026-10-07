extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const CrystalFieldSystemScript = preload("res://scripts/systems/CrystalFieldSystem.gd")
const RecallDroneSystemScript = preload("res://scripts/systems/RecallDroneSystem.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9111)
	var events: Array = []
	CrystalFieldSystemScript.new().process(state, float(state.balance_data.get("recall_drone_charge_seconds", 180.0)), events)
	t.assert_true(state.recall_drone_ready, "recall drone should charge over time")
	for i in range(5):
		state.gems.append(ExpGemScript.new(state.player_position + Vector2(200 + i * 10, 0), 4))
	var before_multiplier = state.get_gem_value_multiplier()
	t.assert_true(RecallDroneSystemScript.new().activate(state, events), "recall drone should activate when ready")
	t.assert_true(state.recall_drone_active_timer > 0.0, "recall drone should start value bonus window")
	t.assert_true(state.get_gem_value_multiplier() > before_multiplier, "recall drone should add gem value bonus")
	for gem in state.gems:
		t.assert_true(gem.attracting, "recall drone should pull nearby gems")
