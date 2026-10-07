extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771600, "exploration-reward-rooms")
	t.assert_true(state.field_equipment.size() > 0, "map should place concrete field equipment")
	var center = state.field_size * 0.5
	for equipment in state.field_equipment:
		var pos: Vector2 = equipment.get("position", center)
		t.assert_true(pos.distance_to(center) >= 850.0, "field equipment should not create a strong start-room reward")
		t.assert_true(String(equipment.get("name_ja", "")).find("：") >= 0, "field equipment should show concrete item name")
		t.assert_true(String(equipment.get("room_id", "")) != "", "field equipment should be attached to a reward room")
	t.assert_true(state.navigation_targets.has("field_weapon") or state.navigation_targets.has("field_passive"), "navigation targets should include field equipment")
