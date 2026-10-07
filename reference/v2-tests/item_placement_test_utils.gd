extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

static func new_state(seed: int = 12345):
	var state = SurvivorStateScript.new()
	state.start_new_run(seed, "")
	return state

static func assert_active_pickups_valid(t, state, label: String = "") -> Dictionary:
	var invalid := {
		"outside_map_count": 0,
		"wall_overlap_count": 0,
		"void_position_count": 0,
		"unreachable_item_count": 0,
		"checked": 0
	}
	_check_dictionary_items(t, state, state.field_drops, "field_drop", invalid, label)
	_check_dictionary_items(t, state, state.field_equipment, "field_equipment", invalid, label)
	_check_dictionary_items(t, state, state.field_gimmicks, "field_gimmick", invalid, label)
	for chest in state.chests:
		_check_position(t, state, chest.position, "chest", 28.0, invalid, label)
	for gem in state.gems:
		_check_position(t, state, gem.position, "exp_gem", 8.0, invalid, label)
	t.assert_eq(invalid["outside_map_count"], 0, "%s outside map pickups" % label)
	t.assert_eq(invalid["wall_overlap_count"], 0, "%s wall overlap pickups" % label)
	t.assert_eq(invalid["void_position_count"], 0, "%s void pickups" % label)
	t.assert_eq(invalid["unreachable_item_count"], 0, "%s unreachable pickups" % label)
	return invalid

static func _check_dictionary_items(t, state, items: Array, pickup_type: String, invalid: Dictionary, label: String) -> void:
	for item in items:
		if not item is Dictionary or bool(item.get("collected", false)) or bool(item.get("destroyed", false)):
			continue
		_check_position(t, state, item.get("position", Vector2.INF), pickup_type, float(item.get("radius", -1.0)), invalid, label)

static func _check_position(t, state, position: Vector2, pickup_type: String, radius: float, invalid: Dictionary, label: String) -> void:
	invalid["checked"] = int(invalid.get("checked", 0)) + 1
	var result: Dictionary = state.pickup_validation_result(position, pickup_type, radius)
	if bool(result.get("ok", false)):
		return
	for reason in result.get("reasons", []):
		match String(reason):
			"outside_map":
				invalid["outside_map_count"] = int(invalid["outside_map_count"]) + 1
			"not_walkable":
				invalid["void_position_count"] = int(invalid["void_position_count"]) + 1
			"wall_clearance":
				invalid["wall_overlap_count"] = int(invalid["wall_overlap_count"]) + 1
			"unreachable":
				invalid["unreachable_item_count"] = int(invalid["unreachable_item_count"]) + 1
	t.assert_true(false, "%s invalid %s at %s reasons=%s" % [label, pickup_type, str(position), str(result.get("reasons", []))])
