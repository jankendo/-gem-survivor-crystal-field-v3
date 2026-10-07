extends SceneTree

func _initialize() -> void:
	var state = preload("res://scripts/core/SurvivorState.gd").new()
	var connectivity = preload("res://scripts/systems/MapConnectivitySystem.gd").new()
	state.start_new_run(20260611, "procedural-10min")
	if state.map_data.get("rooms", []).size() < 8 or not connectivity.all_rooms_reachable(state.map_data):
		push_error("Procedural map autoplay connectivity failed")
		quit(1)
	for room in state.map_data.get("rooms", []):
		state.player_position = room.get("position", state.player_position)
		state.update_current_terrain([])
	state.elapsed_seconds = 600.0
	if state.explored_room_ids.size() < 8:
		push_error("Procedural map autoplay exploration failed")
		quit(1)
	print("AutoPlay OK: procedural map 10min simulation, connected rooms, exploration.")
	quit(0)
