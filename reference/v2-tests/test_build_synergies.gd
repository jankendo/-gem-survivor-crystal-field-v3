extends RefCounted

const BuildSynergySystemScript = preload("res://scripts/systems/BuildSynergySystem.gd")

func run(t) -> void:
	test_tag_conditions_activate_synergy(t)
	test_synergy_effects_reflect_in_state(t)
	test_pause_and_result_can_display_synergy(t)

func test_tag_conditions_activate_synergy(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(4040, "synergy")
	state.weapons = {"thunder_chain": 1}
	state.character_modifiers = {"tag_damage": {"lightning": 1.10}}
	BuildSynergySystemScript.new().process(state, [])
	t.assert_true(state.active_synergies.has("thunder_circuit"), "lightning tags should activate thunder circuit")

func test_synergy_effects_reflect_in_state(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(4041, "synergy2")
	state.weapons = {"soul_scythe": 1, "blade_fan": 1}
	BuildSynergySystemScript.new().process(state, [])
	t.assert_true(state.active_synergies.has("melee_ashura"), "two melee weapons should activate melee ashura")
	t.assert_true(state.get_damage_multiplier_for_weapon("soul_scythe") > state.get_damage_multiplier(), "melee synergy should increase melee damage")

func test_pause_and_result_can_display_synergy(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(4042, "synergy3")
	state.weapons = {"soul_scythe": 1, "blade_fan": 1}
	BuildSynergySystemScript.new().process(state, [])
	t.assert_true(state.active_synergy_label().find("近接修羅") >= 0, "pause/status label should include active synergy")
	t.assert_true(state.active_synergy_history.has("melee_ashura"), "result history should include active synergy id")
