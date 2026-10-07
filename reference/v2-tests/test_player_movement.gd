extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const PlayerScript = preload("res://scripts/systems/Player.gd")

func run(t) -> void:
	test_movement_direction(t)
	test_field_clamp(t)

func _state() :
	var state = SurvivorStateScript.new()
	state.start_new_run(11)
	return state

func test_movement_direction(t) -> void:
	var state = _state()
	var start = state.player_position
	PlayerScript.new().process_movement(state, Vector2.RIGHT, 1.0)
	t.assert_true(state.player_position.x > start.x, "player should move right")
	t.assert_eq(roundi(state.player_position.y), roundi(start.y), "single-axis movement should keep y")

func test_field_clamp(t) -> void:
	var state = _state()
	state.player_position = Vector2(2, 2)
	PlayerScript.new().process_movement(state, Vector2(-1, -1), 2.0)
	t.assert_true(state.player_position.x >= 0.0 and state.player_position.y >= 0.0, "player should stay inside field")
