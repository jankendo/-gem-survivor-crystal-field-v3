extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_only_character_unlocks.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["weapon_highest_levels"]["thunder_chain"] = 8
	save.save_data(data)
	var newly := MetaProgressionSystemScript.new().check_character_unlocks(save)
	var updated := save.load_data()
	t.assert_true(newly.has("rai"), "condition should publish Rai to shop")
	t.assert_true(not (updated.get("unlocked_characters", []) as Array).has("rai"), "condition should not directly unlock Rai")
	t.assert_true(bool(updated.get("shop_available", {}).get("character", {}).get("rai", false)), "Rai should be listed as shop available")
