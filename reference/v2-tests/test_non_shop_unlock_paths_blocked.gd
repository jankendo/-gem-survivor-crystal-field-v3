extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_non_shop_unlock_paths_blocked.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["best_survival"] = 1200.0
	data["stats"]["total_crystals"] = 300
	save.save_data(data)
	var result: Dictionary = MetaProgressionSystemScript.new().update_after_run(save, {
		"character_id": "noah",
		"survival_time": 1.0,
		"kills": 0,
		"crystals_destroyed": 0
	})
	var updated := save.load_data()
	t.assert_true((result.get("characters_unlocked", []) as Array).is_empty(), "after-run should not directly unlock characters")
	t.assert_true(not (updated.get("unlocked_characters", []) as Array).has("atlas"), "quest/result condition should not directly unlock Atlas")
	t.assert_true(bool(updated.get("shop_available", {}).get("character", {}).get("atlas", false)), "Atlas should be shop available instead")
