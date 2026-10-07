extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_candidate_pool_filtering.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["shop_available"]["weapon"]["laser_lance"] = true
	save.save_data(data)
	var state = SurvivorStateScript.new()
	state.start_new_run(9201, "")
	MetaProgressionSystemScript.new().apply_to_state(state, "noah", "attack", save.load_data())
	t.assert_true(not state.unlocked_weapon_ids.has("laser_lance"), "shop available but unpurchased weapon should not enter candidate pool")
