extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(20260611, "true-dungeon-suite")
	var map: Dictionary = state.map_data
	t.assert_eq(int(map.get("grid_width", 0)), 120, "dungeon should use configured grid width")
	t.assert_eq(int(map.get("grid_height", 0)), 120, "dungeon should use configured grid height")
	t.assert_true(map.get("rooms", []).size() >= 12, "dungeon should contain many rooms")
	t.assert_true(int(map.get("room_shape_count", 0)) >= 5, "dungeon should vary room shapes")
	t.assert_true(int(map.get("corridor_shape_count", 0)) >= 3, "dungeon should vary corridor shapes")
	t.assert_true(int(map.get("open_corridors", 0)) >= 4, "start room should have at least four exits")
	t.assert_true(int(map.get("loop_count", 0)) >= 1, "dungeon should include loop routes")
	t.assert_true(bool(map.get("connected", false)), "all dungeon rooms should be connected")
	t.assert_true(not bool(map.get("cross_like", true)), "dungeon should not report a fixed cross layout")
	t.assert_true(float(map.get("walkable_ratio", 1.0)) < 0.40, "abyss should occupy most of the field")
	t.assert_true(state.is_walkable_position(state.player_position, 18.0), "player should start on walkable floor")

