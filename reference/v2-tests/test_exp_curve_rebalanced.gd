extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9107)
	t.assert_eq(state._exp_needed_for_level(1), 32, "level 1 required exp should use new formula")
	t.assert_true(state._exp_needed_for_level(10) > state._exp_needed_for_level(5), "required exp should rise")
	var to_90 = 0
	for level in range(1, 90):
		to_90 += state._exp_needed_for_level(level)
	t.assert_true(to_90 > 100000, "level 90 should require far more than early-run exp")
	state.elapsed_seconds = 1500.0
	var before = state._exp_needed_for_level(60)
	state.elapsed_seconds = 1800.0
	var after = state._exp_needed_for_level(60)
	t.assert_eq(after, before, "required exp must depend only on level")
