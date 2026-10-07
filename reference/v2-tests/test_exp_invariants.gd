extends RefCounted

const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")

func run(t) -> void:
	test_required_exp_depends_only_on_level(t)
	test_gem_value_does_not_change_by_time(t)
	test_gem_drop_rate_does_not_change_by_time(t)
	test_enemy_drop_value_does_not_change_by_time(t)
	test_debug_multiplier_applies_last(t)

func test_required_exp_depends_only_on_level(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(1, "required-exp")
	state.elapsed_seconds = 0.0
	var early = state._exp_needed_for_level(40)
	state.elapsed_seconds = 3600.0
	var late = state._exp_needed_for_level(40)
	t.assert_eq(late, early, "required EXP must depend only on level")

func test_gem_value_does_not_change_by_time(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(1, "gem-value")
	var pos = state.player_position
	state.elapsed_seconds = 0.0
	var early = state.get_gem_value_multiplier(pos)
	state.elapsed_seconds = 3600.0
	var late = state.get_gem_value_multiplier(pos)
	t.assert_eq(late, early, "same gem value multiplier must not change by elapsed time")

func test_gem_drop_rate_does_not_change_by_time(t) -> void:
	var a = SurvivorState.new()
	var b = SurvivorState.new()
	a.start_new_run(1, "drop-rate")
	b.start_new_run(1, "drop-rate")
	a.elapsed_seconds = 0.0
	b.elapsed_seconds = 3600.0
	var early: Array = []
	var late: Array = []
	for i in range(12):
		early.append(a.should_drop_normal_exp())
		late.append(b.should_drop_normal_exp())
	t.assert_eq(str(late), str(early), "normal EXP drop cadence must not change by elapsed time")

func test_enemy_drop_value_does_not_change_by_time(t) -> void:
	var a = SurvivorState.new()
	var b = SurvivorState.new()
	a.start_new_run(1, "enemy-exp")
	b.start_new_run(1, "enemy-exp")
	a.elapsed_seconds = 0.0
	b.elapsed_seconds = 3600.0
	var enemy_a = EnemyScript.new("slime", a.enemy_defs.get("slime", {}), a.player_position + Vector2(40, 0))
	var enemy_b = EnemyScript.new("slime", b.enemy_defs.get("slime", {}), b.player_position + Vector2(40, 0))
	ExpSystemScript.new().drop_for_enemy(a, enemy_a, [])
	ExpSystemScript.new().drop_for_enemy(b, enemy_b, [])
	t.assert_eq(a.gems[0].value, b.gems[0].value, "same enemy must drop the same EXP value at 0s and 3600s")

func test_debug_multiplier_applies_last(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(1, "debug-last")
	var base = state.get_gem_value_multiplier(state.player_position)
	state.debug_exp_multiplier = 20.0
	t.assert_eq(state.get_gem_value_multiplier(state.player_position), base * 20.0, "debug multiplier must apply after all normal gem modifiers")
