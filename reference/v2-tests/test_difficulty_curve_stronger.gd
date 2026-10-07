extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9101)
	var checkpoints = [
		[300.0, 1.8, 1.25, 1.10, 1.8],
		[600.0, 3.0, 1.6, 1.20, 2.5],
		[900.0, 5.0, 2.0, 1.35, 3.2],
		[1200.0, 8.0, 2.6, 1.50, 4.0],
		[1500.0, 12.0, 3.3, 1.65, 4.8],
		[1800.0, 18.0, 4.2, 1.80, 5.8]
	]
	var previous_hp = 0.0
	for row in checkpoints:
		state.elapsed_seconds = float(row[0])
		t.assert_true(state.enemy_hp_multiplier() >= float(row[1]) * 0.98, "enemy HP multiplier should meet curve at %s" % str(row[0]))
		t.assert_true(state.enemy_damage_multiplier() >= float(row[2]) * 0.98, "enemy damage multiplier should meet curve at %s" % str(row[0]))
		t.assert_true(state.enemy_speed_multiplier() >= float(row[3]) * 0.98, "enemy speed multiplier should meet curve at %s" % str(row[0]))
		t.assert_true(state.enemy_spawn_multiplier() >= float(row[4]) * 0.98, "enemy spawn multiplier should meet curve at %s" % str(row[0]))
		t.assert_true(state.enemy_hp_multiplier() > previous_hp, "enemy HP should keep rising")
		previous_hp = state.enemy_hp_multiplier()
	state.elapsed_seconds = 1800.0
	t.assert_eq(state.difficulty_tier(), 7, "30min should enter endless tier")

