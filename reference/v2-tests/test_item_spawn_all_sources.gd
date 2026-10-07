extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")
const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const ChestSystemScript = preload("res://scripts/systems/ChestSystem.gd")

func run(t) -> void:
	var state = Utils.new_state(9106)
	var events: Array = []
	FieldDropSpawnSystemScript.new().force_spawn(state, "weapon_core", events, "test")
	ChestSystemScript.new().drop_chest(state, Vector2.ZERO, events, "normal", "test")
	Utils.assert_active_pickups_valid(t, state, "all_sources")
