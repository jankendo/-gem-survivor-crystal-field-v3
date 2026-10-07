extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_field_size_and_biomes(t)
	test_outer_boundary_visible_contract(t)

func test_field_size_and_biomes(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(701)
	t.assert_true(state.field_size.x >= 6000.0 and state.field_size.y >= 6000.0, "field should be at least 6000x6000")
	t.assert_true(state.biome_system.biome_count() >= 4, "at least four biomes should exist")
	var names: Array = []
	for biome in state.biome_system.all_biomes():
		names.append(String(biome.get("name_ja", "")))
	t.assert_true(names.has("星屑平原"), "star plain biome should exist")
	t.assert_true(names.has("紫晶の森"), "amethyst biome should exist")
	t.assert_true(names.has("赤熱鉱床"), "red mine biome should exist")
	t.assert_true(names.has("虚無領域"), "void biome should exist")

func test_outer_boundary_visible_contract(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(702)
	state.player_position = Vector2(8, 8)
	state.camera_position = state.player_position
	var view = ArenaView.new()
	view.size = Vector2(1280, 720)
	view.bind_state(state)
	t.assert_true(view._camera_origin().x <= 0.1 and view._camera_origin().y <= 0.1, "camera should clamp near outer boundary so wall is visible")
	view.free()
