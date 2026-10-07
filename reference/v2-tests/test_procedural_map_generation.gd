extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(441122, "procedural-room-test")
	var map: Dictionary = state.map_data
	t.assert_true(map.get("rooms", []).size() >= 8, "procedural map must contain at least eight rooms")
	t.assert_true(map.get("corridors", []).size() >= 7, "procedural map must contain connecting corridors")
	t.assert_true(bool(map.get("connected", false)), "procedural room graph must be connected")
	t.assert_true(bool(map.get("important_reachable", false)), "important rooms must be reachable")
	t.assert_true(int(map.get("open_corridors", 0)) >= 2, "safe start must have at least two exits")
	t.assert_true(state.map_start_area_is_safe(), "start radius must remain safe")
	var terrain_ids: Array = []
	for room in map.get("rooms", []):
		terrain_ids.append(String(room.get("terrain_id", "")))
	for required in ["safe_room", "mine_chamber", "danger_den", "healing_oasis", "relic_vault", "event_room", "sealed_room", "boss_arena"]:
		t.assert_true(terrain_ids.has(required), "map must include terrain room: %s" % required)
	var breakable_shortcuts = 0
	var structural_walls = 0
	for wall in map.get("wall_specs", []):
		if String(wall.get("kind", "")) == "shortcut" and bool(wall.get("breakable", false)):
			breakable_shortcuts += 1
		if String(wall.get("kind", "")) == "structural" and not bool(wall.get("breakable", true)):
			structural_walls += 1
	t.assert_true(breakable_shortcuts >= 2, "map must provide breakable shortcuts")
	t.assert_true(structural_walls >= 8, "map must provide non-breakable structural walls")
