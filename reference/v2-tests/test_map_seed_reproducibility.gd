extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_text_seed_is_preserved(t)
	test_empty_seed_generates_runtime_seed(t)

func test_text_seed_is_preserved(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(0, "replay-001")
	t.assert_eq(state.map_seed_text, "replay-001", "text seed should be preserved on state")
	t.assert_true(state.map_seed != 0, "text seed should convert to numeric map seed")

func test_empty_seed_generates_runtime_seed(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(12345, "")
	t.assert_eq(state.map_seed, 12345, "fallback numeric seed should be used when seed text is empty")
	t.assert_true(state.map_seed_text != "", "result seed text should be displayed even for random/fallback seed")
