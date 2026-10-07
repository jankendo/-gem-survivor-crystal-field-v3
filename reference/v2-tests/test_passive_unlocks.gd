extends RefCounted

const UnlockSystemScript = preload("res://scripts/systems/UnlockSystem.gd")

func run(t) -> void:
	var system = UnlockSystemScript.new()
	var initial = system.initial_passive_ids()
	t.assert_true(initial.has("move_speed"), "move speed should be initially unlocked")
	t.assert_true(not initial.has("regen"), "regeneration should require progression")
	var save_data = {
		"unlocked_weapons": system.initial_weapon_ids(),
		"unlocked_passives": initial.duplicate(),
		"stats": {"best_survival": 300.0}
	}
	var result = system.update_after_run(save_data)
	t.assert_true((result.get("passives_shop_available", []) as Array).has("regen"), "five minute survival should publish regeneration to shop")
	t.assert_true(not (save_data.get("unlocked_passives", []) as Array).has("regen"), "condition should not directly unlock regeneration")
	var state = SurvivorState.new()
	state.start_new_run(82, "passive-unlocks")
	state.unlocked_passive_ids = initial.duplicate()
	t.assert_true(not state.can_offer_passive("regen"), "locked passive must not appear in level-up offers")
	state.unlocked_passive_ids.append("regen")
	t.assert_true(state.can_offer_passive("regen"), "unlocked passive may appear in level-up offers")
