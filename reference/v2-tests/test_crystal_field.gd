extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const PlayerScript = preload("res://scripts/systems/Player.gd")
const CrystalFieldSystemScript = preload("res://scripts/systems/CrystalFieldSystem.gd")

func run(t) -> void:
	test_field_has_walls_and_danger_zones(t)
	test_wall_blocks_player_and_breaks(t)

func test_field_has_walls_and_danger_zones(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(607)
	t.assert_true(state.crystal_walls.size() >= 6, "field should create internal crystal walls")
	t.assert_true(state.danger_zones.size() >= 3, "field should create danger zones")

func test_wall_blocks_player_and_breaks(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(608)
	var wall = state.crystal_walls[0]
	state.player_position = wall.position - Vector2(wall.size.x * 0.5 + 24.0, 0)
	PlayerScript.new().process_movement(state, Vector2.RIGHT, 1.0)
	t.assert_true(not wall.rect().has_point(state.player_position), "player should not end inside crystal wall")
	var events: Array = []
	CrystalFieldSystemScript.new().damage_wall(state, wall, wall.max_hp + 50, events, "test")
	t.assert_eq(state.crystals_destroyed, 1, "breaking a wall should increment crystal counter")
	t.assert_true(state.gems.size() > 0, "breaking a wall should drop gems")

