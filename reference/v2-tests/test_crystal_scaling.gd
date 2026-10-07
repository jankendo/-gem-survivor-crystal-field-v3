extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_crystal_wall_types_and_scaling(t)

func test_crystal_wall_types_and_scaling(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(709)
	var types: Array = []
	for wall in state.crystal_walls:
		if not types.has(wall.wall_type):
			types.append(wall.wall_type)
	t.assert_true(types.has("small_crystal"), "small crystal should exist")
	t.assert_true(types.has("wall_crystal"), "wall crystal should exist")
	t.assert_true(types.has("rich_crystal"), "rich crystal should exist")
	t.assert_true(types.has("cursed_crystal"), "cursed crystal should exist")
	var wall = state.crystal_walls[0]
	var early = wall.max_hp
	state.elapsed_seconds = 1200.0
	wall.rescale_hp(state.crystal_hp_multiplier_for_position(wall.position))
	t.assert_true(wall.max_hp > early, "crystal wall should harden over time")

