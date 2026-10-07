extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const TerrainScript = preload("res://scripts/systems/TerrainRoomSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(3388, "terrain-balance")
	var terrain = TerrainScript.new()
	for id in ["safe_room", "crystal_corridor", "mine_chamber", "danger_den", "healing_oasis", "relic_vault", "boss_arena", "event_room"]:
		t.assert_true(state.terrain_type_defs.has(id), "terrain balance must define %s" % id)
	state.current_terrain_id = "safe_room"
	var safe_spawn = terrain.terrain_value(state, "spawn_mult", 1.0)
	state.current_terrain_id = "danger_den"
	var danger_spawn = terrain.terrain_value(state, "spawn_mult", 1.0)
	var danger_reward = terrain.terrain_value(state, "reward_mult", 1.0)
	state.current_terrain_id = "healing_oasis"
	var oasis_spawn = terrain.terrain_value(state, "spawn_mult", 1.0)
	t.assert_true(danger_spawn > safe_spawn, "danger den must have higher enemy pressure than safe room")
	t.assert_true(danger_reward > 1.3, "danger den must pay a high reward multiplier")
	t.assert_true(oasis_spawn > safe_spawn, "healing oasis must combine recovery with enemy pressure")
	state.current_terrain_id = "crystal_corridor"
	t.assert_true(terrain.terrain_value(state, "spawn_mult", 1.0) >= 1.0, "corridor must maintain contact pressure")
