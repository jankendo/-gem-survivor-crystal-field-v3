extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	test_auto_infinite_on(t)
	test_auto_infinite_off(t)

func _exhausted_state():
	var state = SurvivorStateScript.new()
	state.start_new_run(705)
	for id in state.weapon_defs.keys():
		state.weapons[String(id)] = int(state.weapon_defs[id].get("max_level", 8))
	for id in state.passive_defs.keys():
		state.passives[String(id)] = int(state.passive_defs[id].get("max_level", 5))
	state.evolved_weapons = {}
	for evolution_id in state.evolution_defs.keys():
		state.evolved_weapons[String(state.evolution_defs[evolution_id].get("weapon", ""))] = String(evolution_id)
	return state

func test_auto_infinite_on(t) -> void:
	var state = _exhausted_state()
	state.auto_infinite_enabled = true
	var events: Array = []
	ExpSystemScript.new().add_exp(state, 999999, events)
	t.assert_true(not state.level_up_pending, "auto infinite should not open level-up popup")
	t.assert_true(state.auto_infinite_count > 0, "auto infinite should apply at least once")

func test_auto_infinite_off(t) -> void:
	var state = _exhausted_state()
	state.auto_infinite_enabled = false
	state.level_up_options = LevelUpSystemScript.new().prepare_options(state, 3)
	t.assert_true(LevelUpSystemScript.new().options_are_infinite_only(state.level_up_options), "exhausted options should be infinite only")
	var events: Array = []
	ExpSystemScript.new().add_exp(state, 999999, events)
	t.assert_true(state.level_up_pending, "auto infinite off should show popup")

