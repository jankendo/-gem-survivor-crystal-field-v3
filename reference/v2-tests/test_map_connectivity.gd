extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ConnectivityScript = preload("res://scripts/systems/MapConnectivitySystem.gd")

func run(t) -> void:
	var connectivity = ConnectivityScript.new()
	var state_a = StateScript.new()
	var state_b = StateScript.new()
	var state_c = StateScript.new()
	state_a.start_new_run(882211, "same-layout")
	state_b.start_new_run(882211, "same-layout")
	state_c.start_new_run(882212, "other-layout")
	t.assert_eq(state_a.map_signature(), state_b.map_signature(), "same seed must reproduce rooms and corridors")
	t.assert_true(state_a.map_signature() != state_c.map_signature(), "different seed must change room layout")
	t.assert_true(connectivity.all_rooms_reachable(state_a.map_data), "all generated rooms must be reachable")
	t.assert_true(connectivity.important_rooms_reachable(state_a.map_data), "all important generated rooms must be reachable")
	t.assert_true(connectivity.exit_count(state_a.map_data, "room_00") >= 2, "start room must expose multiple exits")
