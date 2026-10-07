extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(884422, "collision-pathing")
	var walkable: Dictionary = state.map_data.get("walkable_lookup", {})
	var abyss_position = Vector2(32, 32)
	t.assert_true(not state.is_walkable_position(abyss_position), "un carved grid cell should be abyss")
	var resolved = state.resolve_walkable_position(abyss_position, 18.0, state.player_position)
	t.assert_true(state.is_walkable_position(resolved, 18.0), "collision should resolve requests back to floor")
	var events: Array = []
	var enemy = EnemySpawnerScript.new().spawn_enemy(state, "slime", events)
	t.assert_true(enemy != null and state.is_walkable_position(enemy.position, enemy.radius), "enemy spawn should be on walkable floor")
	t.assert_true(walkable.size() > 0, "dungeon should expose a walkable lookup")

