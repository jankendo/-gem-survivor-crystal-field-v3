extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EquipmentHudSystemScript = preload("res://scripts/systems/EquipmentHudSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(31337, "equipment-hud")
	state.passives["might"] = 2
	state.evolved_magic_bolt = true
	var hud = EquipmentHudSystemScript.new()
	hud.configure({"weapon_hud_enabled": true, "passive_hud_enabled": true})
	t.assert_true(hud.weapon_text(state).find("[進化]") >= 0, "weapon HUD should mark evolved weapons")
	t.assert_true(hud.passive_text(state).find("Lv2") >= 0, "passive HUD should show levels")
	hud.configure({"weapon_hud_enabled": false, "passive_hud_enabled": false})
	t.assert_eq(hud.weapon_text(state), "", "weapon HUD should be hideable")
	t.assert_eq(hud.passive_text(state), "", "passive HUD should be hideable")

