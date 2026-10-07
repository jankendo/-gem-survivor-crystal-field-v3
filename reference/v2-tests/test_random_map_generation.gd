extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_same_seed_same_map(t)
	test_different_seed_different_map(t)
	test_start_area_safe_and_open(t)

func _state(seed_text: String):
	var state = SurvivorStateScript.new()
	state.start_new_run(0, seed_text)
	return state

func test_same_seed_same_map(t) -> void:
	var a = _state("crystal-seed")
	var b = _state("crystal-seed")
	t.assert_eq(a.map_signature(), b.map_signature(), "same seed should generate identical map")

func test_different_seed_different_map(t) -> void:
	var a = _state("crystal-seed-a")
	var b = _state("crystal-seed-b")
	t.assert_true(a.map_signature() != b.map_signature(), "different seeds should generate different maps")

func test_start_area_safe_and_open(t) -> void:
	var state = _state("safe-start")
	t.assert_true(state.map_start_area_is_safe(), "start area should be free from walls and danger zones")
	t.assert_true(int(state.map_data.get("open_corridors", 0)) >= 4, "map should keep multiple open corridors")
	t.assert_true(state.crystal_walls.size() >= 18, "random map should generate crystal wall clusters")
