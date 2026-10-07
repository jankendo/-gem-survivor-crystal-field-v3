extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_enemy_scaling_increases(t)
	test_boss_and_crystal_scaling_increases(t)

func test_enemy_scaling_increases(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(703)
	var values: Array = []
	for seconds in [300.0, 600.0, 900.0, 1200.0, 1500.0, 1800.0]:
		state.elapsed_seconds = seconds
		values.append(state.enemy_hp_multiplier() + state.enemy_spawn_multiplier() + state.enemy_damage_multiplier())
	for i in range(1, values.size()):
		t.assert_true(float(values[i]) > float(values[i - 1]), "difficulty should rise at each checkpoint")

func test_boss_and_crystal_scaling_increases(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(704)
	t.assert_true(state.boss_hp_multiplier_for_minute(30) > state.boss_hp_multiplier_for_minute(5), "boss HP multiplier should rise by minute")
	state.elapsed_seconds = 0.0
	var early = state.crystal_hp_multiplier_for_position(Vector2(400, 400))
	state.elapsed_seconds = 1800.0
	var late = state.crystal_hp_multiplier_for_position(Vector2(5800, 5800))
	t.assert_true(late > early * 2.0, "crystal HP should rise with time and biome")

