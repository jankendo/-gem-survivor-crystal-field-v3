extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const CoreScript = preload("res://scripts/systems/CorePickupChoiceSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771604, "core-choice")
	state.weapons = {
		"magic_bolt": 1,
		"ice_orbit": 1,
		"thunder_chain": 1,
		"bomb_seed": 1,
		"poison_mist": 1
	}
	for id in state.weapons.keys():
		state.weapons[id] = int(state.weapon_defs.get(id, {}).get("max_level", 8))
	state.unlocked_weapon_ids = state.weapons.keys()
	var system = CoreScript.new()
	var events: Array = []
	t.assert_true(not system.open_choice(state, "weapon", {"id": "weapon_core", "position": state.player_position}, events), "full core pool should convert to score instead of offering over-cap equipment")
	t.assert_true(not state.level_up_pending and state.pending_core_choice.is_empty(), "empty core pool must not open selection UI")
	t.assert_true(String(state.message).contains("候補がない"), "empty core pool must explain the fallback")
