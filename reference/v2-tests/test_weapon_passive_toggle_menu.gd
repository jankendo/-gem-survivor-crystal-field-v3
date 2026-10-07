extends RefCounted

const LoadoutScript = preload("res://scripts/systems/LoadoutDisableSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")
const UnlockScript = preload("res://scripts/systems/UnlockSystem.gd")

func run(t) -> void:
	var path := "user://test_weapon_passive_toggle_menu.save"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var save := SaveSystem.new(path)
	var data := save.load_data()
	var state = StateScript.new()
	state.start_new_run(99, "loadout")
	data["unlocked_weapons"] = state.weapon_defs.keys()
	data["unlocked_passives"] = state.passive_defs.keys()
	_mark_all_purchased(data, "weapon", state.weapon_defs.keys())
	_mark_all_purchased(data, "passive", state.passive_defs.keys())
	data["selected_character"] = "noah"
	save.save_data(data)
	var loadout = LoadoutScript.new()
	t.assert_true(not bool(loadout.can_disable(save.load_data(), "weapon", "magic_bolt").get("ok", true)), "selected initial weapon must not be disabled")
	t.assert_true(bool(loadout.set_enabled(save, "weapon", "ice_orbit", false).get("ok", false)), "unlocked non-initial weapon should be switchable OFF")
	t.assert_true(bool(loadout.set_enabled(save, "passive", "regen", false).get("ok", false)), "unlocked passive should be switchable OFF")
	var reloaded := SaveSystem.new(path).load_data()
	t.assert_true((reloaded.get("disabled_weapons", []) as Array).has("ice_orbit"), "disabled weapon should persist")
	t.assert_true((reloaded.get("disabled_passives", []) as Array).has("regen"), "disabled passive should persist")
	var run_state = StateScript.new()
	run_state.start_new_run(100, "loadout-run")
	UnlockScript.new().apply_to_state(run_state, reloaded)
	t.assert_true(not run_state.can_offer_weapon("ice_orbit"), "OFF weapon should not appear as a new candidate")
	t.assert_true(not run_state.can_offer_passive("regen"), "OFF passive should not appear as a new candidate")
	t.assert_true(bool(loadout.set_enabled(save, "weapon", "ice_orbit", true).get("ok", false)), "weapon should be switchable back ON")
	t.assert_true(not (SaveSystem.new(path).load_data().get("disabled_weapons", []) as Array).has("ice_orbit"), "enabled weapon should return to candidate pool")
	DirAccess.remove_absolute(absolute)

func _mark_all_purchased(data: Dictionary, kind: String, ids: Array) -> void:
	var purchases: Dictionary = data.get("shop_purchases", {})
	var table: Dictionary = purchases.get(kind, {})
	for raw_id in ids:
		table[String(raw_id)] = true
	purchases[kind] = table
	data["shop_purchases"] = purchases
