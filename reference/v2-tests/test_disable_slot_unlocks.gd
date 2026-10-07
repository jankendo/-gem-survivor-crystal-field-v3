extends RefCounted

const LoadoutScript = preload("res://scripts/systems/LoadoutDisableSystem.gd")
const SinkScript = preload("res://scripts/systems/CurrencySinkSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var path := "user://test_disable_slot_unlocks.save"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var save := SaveSystem.new(path)
	var data := save.load_data()
	var state = StateScript.new()
	state.start_new_run(33, "slots")
	data["unlocked_weapons"] = state.weapon_defs.keys()
	data["unlocked_passives"] = state.passive_defs.keys()
	_mark_all_purchased(data, "weapon", state.weapon_defs.keys())
	_mark_all_purchased(data, "passive", state.passive_defs.keys())
	data["crystal_currency"] = 100000
	save.save_data(data)
	var loadout = LoadoutScript.new()
	t.assert_eq(loadout.slots_for(save.load_data(), "weapon"), 3, "20 unlocked weapons should grant one achievement slot above the base two")
	t.assert_true(SinkScript.new().purchase(save, "weapon_disable_slots"), "shop should sell a weapon OFF slot")
	t.assert_eq(loadout.slots_for(save.load_data(), "weapon"), 4, "shop purchase should increase weapon OFF slots")
	data = save.load_data()
	data["stats"]["best_survival"] = 1800.0
	data["stats"]["exploration_rank_count"]["SS"] = 3
	save.save_data(data)
	t.assert_eq(loadout.slots_for(save.load_data(), "weapon"), 6, "survival and repeated SS achievements should increase slots")
	t.assert_true(loadout.usage_text(save.load_data(), "weapon").contains("0 / 6"), "UI usage text should use current / maximum format")
	for i in range(20):
		SinkScript.new().purchase(save, "weapon_disable_slots")
	t.assert_true(loadout.slots_for(save.load_data(), "weapon") <= LoadoutScript.MAX_SLOTS, "OFF slots must never exceed the maximum")
	DirAccess.remove_absolute(absolute)

func _mark_all_purchased(data: Dictionary, kind: String, ids: Array) -> void:
	var purchases: Dictionary = data.get("shop_purchases", {})
	var table: Dictionary = purchases.get(kind, {})
	for raw_id in ids:
		table[String(raw_id)] = true
	purchases[kind] = table
	data["shop_purchases"] = purchases
