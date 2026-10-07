extends SceneTree

func _initialize() -> void:
	var state = preload("res://scripts/core/SurvivorState.gd").new()
	var spawner = preload("res://scripts/systems/EnemySpawner.gd").new()
	state.start_new_run(20260611, "autoplay-true-dungeon")
	var events: Array = []
	for room in state.map_data.get("rooms", []):
		state.player_position = room.get("position", state.player_position)
		state.update_current_terrain(events)
		for i in range(3):
			var enemy = spawner.spawn_enemy(state, "slime", events)
			if enemy == null or not state.is_walkable_position(enemy.position, enemy.radius):
				push_error("True dungeon autoplay produced invalid enemy position")
				quit(1)
	state.elapsed_seconds = 600.0
	if state.explored_room_ids.size() < 12 or not bool(state.map_data.get("connected", false)):
		push_error("True dungeon autoplay did not explore connected rooms")
		quit(1)
	print("AutoPlay OK: true dungeon 10min traversal, floor collision and enemy spawns.")
	quit(0)

