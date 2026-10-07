extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	test_exhausted_candidates_still_return_three_options(t)

func test_exhausted_candidates_still_return_three_options(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(601)
	for id in state.weapon_defs.keys():
		state.weapons[String(id)] = int(state.weapon_defs[id].get("max_level", 8))
	for id in state.passive_defs.keys():
		state.passives[String(id)] = int(state.passive_defs[id].get("max_level", 5))
	var options = LevelUpSystemScript.new().prepare_options(state, 3)
	t.assert_eq(options.size(), 3, "exhausted level-up should still show exactly three options")
	var ids: Array = []
	for option in options:
		t.assert_eq(String(option.get("kind", "")), "infinite", "fallback options should be infinite upgrades")
		t.assert_true(not ids.has(String(option.get("id", ""))), "infinite upgrades should not duplicate on one screen")
		ids.append(String(option.get("id", "")))

