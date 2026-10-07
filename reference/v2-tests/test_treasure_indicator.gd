extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const ChestScript = preload("res://scripts/core/Chest.gd")

func run(t) -> void:
	test_chest_indicator_state(t)
	test_chest_removed_after_pickup(t)

func test_chest_indicator_state(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(706)
	state.chests.append(ChestScript.new(state.player_position + Vector2(2200, 0)))
	var view = ArenaView.new()
	view.size = Vector2(1280, 720)
	view.bind_state(state)
	var screen_pos = view.world_to_screen(state.chests[0].position)
	t.assert_true(not Rect2(Vector2.ZERO, view.size).has_point(screen_pos), "far chest should be off-screen and need indicator")
	t.assert_true(state.chests[0].position.distance_to(state.player_position) > 1000.0, "distance should be available for indicator")
	view.free()

func test_chest_removed_after_pickup(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(707)
	state.chests.append(ChestScript.new(state.player_position))
	var events: Array = []
	ChestSystem.new().process_pickups(state, events)
	t.assert_true(state.chests.is_empty(), "chest indicator should disappear after pickup because chest is removed")
