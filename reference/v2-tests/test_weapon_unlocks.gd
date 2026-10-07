extends RefCounted

const UnlockSystemScript = preload("res://scripts/systems/UnlockSystem.gd")

func run(t) -> void:
	var system = UnlockSystemScript.new()
	var initial = system.initial_weapon_ids()
	t.assert_true(initial.has("magic_bolt"), "magic bolt should be initially unlocked")
	t.assert_true(not initial.has("laser_lance"), "laser lance should require progression")
	var save_data = {
		"unlocked_weapons": initial.duplicate(),
		"unlocked_passives": system.initial_passive_ids(),
		"stats": {"total_crystals": 20}
	}
	var result = system.update_after_run(save_data)
	t.assert_true((result.get("weapons_shop_available", []) as Array).has("laser_lance"), "20 destroyed crystals should publish laser lance to shop")
	t.assert_true(not (save_data.get("unlocked_weapons", []) as Array).has("laser_lance"), "condition should not directly unlock laser lance")
	var state = SurvivorState.new()
	state.start_new_run(81, "weapon-unlocks")
	state.unlocked_weapon_ids = initial.duplicate()
	t.assert_true(not state.can_offer_weapon("laser_lance"), "locked weapon must not appear in level-up offers")
	state.unlocked_weapon_ids.append("laser_lance")
	t.assert_true(state.can_offer_weapon("laser_lance"), "unlocked weapon may appear in level-up offers")
