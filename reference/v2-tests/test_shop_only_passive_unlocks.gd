extends RefCounted

const UnlockSystemScript = preload("res://scripts/systems/UnlockSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_only_passive_unlocks.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["best_survival"] = 300.0
	UnlockSystemScript.new().update_after_run(data)
	t.assert_true(not (data.get("unlocked_passives", []) as Array).has("regen"), "condition should not directly unlock regen")
	t.assert_true(bool(data.get("shop_available", {}).get("passive", {}).get("regen", false)), "condition should publish regen to shop")
