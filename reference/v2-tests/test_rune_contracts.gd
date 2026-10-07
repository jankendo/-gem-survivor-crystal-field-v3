extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const RuneContractSystemScript = preload("res://scripts/systems/RuneContractSystem.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9110)
	var system = RuneContractSystemScript.new()
	var events: Array = []
	var options = system.make_offer(state, 3)
	t.assert_eq(options.size(), 3, "contract offer should show 3 options including skip")
	t.assert_true(String(options.back().get("kind", "")) == "contract_skip", "contract offer should be skippable")
	var before_hp = state.max_hp
	t.assert_true(system.apply_contract(state, "blood_pact", events), "blood pact should apply")
	t.assert_true(state.get_damage_multiplier() > 1.2, "blood pact should increase damage")
	t.assert_true(state.max_hp < before_hp, "blood pact should reduce max HP")
	t.assert_true(system.apply_contract(state, "skip", events), "skip should be accepted")

