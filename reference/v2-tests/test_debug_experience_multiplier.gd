extends RefCounted

func run(t) -> void:
	test_normal_exp_is_increased(t)
	test_debug_multiplier_applies_after_normal(t)
	test_debug_multiplier_save_protection(t)

func test_normal_exp_is_increased(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(12, "exp-normal")
	t.assert_true(state.normal_exp_balance_multiplier() >= 1.20, "normal exp should be at least 20% higher")

func test_debug_multiplier_applies_after_normal(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(12, "exp-debug")
	var normal = state.get_gem_value_multiplier()
	state.debug_exp_multiplier = 5.0
	t.assert_true(state.get_gem_value_multiplier() >= normal * 4.99, "debug exp multiplier should apply after normal balance multiplier")

func test_debug_multiplier_save_protection(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(12, "exp-save")
	state.debug_exp_multiplier = 10.0
	state.allow_debug_progress = false
	t.assert_true(not state.progress_saving_allowed(), "debug exp should block permanent progress by default")
	state.allow_debug_progress = true
	t.assert_true(state.progress_saving_allowed(), "explicit setting should allow debug progress saving")
