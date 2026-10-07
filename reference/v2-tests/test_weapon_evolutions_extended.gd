extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EvolutionSystemScript = preload("res://scripts/systems/EvolutionSystem.gd")

func run(t) -> void:
	test_eight_evolutions_are_defined(t)
	test_each_evolution_can_apply(t)

func test_eight_evolutions_are_defined(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(604)
	t.assert_true(state.evolution_defs.keys().size() >= 8, "at least eight evolutions should be data-defined")

func test_each_evolution_can_apply(t) -> void:
	var base = SurvivorStateScript.new()
	base.start_new_run(605)
	for evolution_id in base.evolution_defs.keys():
		var state = SurvivorStateScript.new()
		state.start_new_run(606)
		state.elapsed_seconds = 300.0
		var data = state.evolution_defs[evolution_id]
		var weapon_id = String(data.get("weapon", ""))
		var passive_id = String(data.get("passive", ""))
		state.weapons[weapon_id] = int(data.get("weapon_level", 8))
		state.passives[passive_id] = int(data.get("passive_level", 1))
		var events: Array = []
		t.assert_true(EvolutionSystemScript.new().apply_first_available_evolution(state, events), "evolution should apply for %s" % evolution_id)
		t.assert_true(state.is_weapon_evolved(weapon_id), "weapon should be marked evolved for %s" % weapon_id)
