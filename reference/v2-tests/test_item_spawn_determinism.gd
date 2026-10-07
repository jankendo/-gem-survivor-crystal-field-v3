extends RefCounted

const Utils = preload("res://tests/item_placement_test_utils.gd")

func run(t) -> void:
	var a = Utils.new_state(9105)
	var b = Utils.new_state(9105)
	t.assert_eq(a.map_signature(), b.map_signature(), "same seed should keep deterministic map and pickup signature")
	t.assert_eq(_pickup_signature(a), _pickup_signature(b), "same seed should keep deterministic pickup positions")

func _pickup_signature(state) -> String:
	var parts: Array = []
	for source in [state.field_drops, state.field_equipment, state.field_gimmicks]:
		for item in source:
			var pos: Vector2 = item.get("position", Vector2.ZERO)
			parts.append("%s:%s:%d:%d" % [String(item.get("kind", "")), String(item.get("id", "")), int(pos.x), int(pos.y)])
	return "|".join(parts)
