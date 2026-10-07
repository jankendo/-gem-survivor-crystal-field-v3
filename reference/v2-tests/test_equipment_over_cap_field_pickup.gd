extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const CapacityScript = preload("res://scripts/systems/EquipmentCapacitySystem.gd")
const GrantScript = preload("res://scripts/systems/EquipmentOverCapSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771606, "overcap")
	state.weapons = {
		"magic_bolt": 1,
		"ice_orbit": 1,
		"thunder_chain": 1,
		"bomb_seed": 1,
		"poison_mist": 1
	}
	state.unlocked_weapon_ids.append("soul_scythe")
	var capacity = CapacityScript.new()
	var grant = GrantScript.new()
	t.assert_true(not capacity.can_take(state, "weapon", "laser_lance", true), "locked field pickup should not exceed cap")
	t.assert_true(not capacity.can_take(state, "weapon", "soul_scythe", false), "normal level-up should respect 5 weapon cap")
	t.assert_true(capacity.can_take(state, "weapon", "soul_scythe", true), "field/core pickup should be allowed to exceed cap for unlocked equipment")
	t.assert_true(grant.grant(state, "weapon", "soul_scythe", [], "field_equipment", true), "field grant should add a sixth unlocked weapon")
	t.assert_eq(state.equipment_count_label("weapon"), "6/5 +1", "HUD label should show over-cap count")
