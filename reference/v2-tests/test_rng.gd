extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	test_same_seed_same_ints(t)
	test_same_seed_same_enemy_pick(t)
	test_same_seed_same_shuffle(t)

func test_same_seed_same_ints(t) -> void:
	var a = RunRng.new()
	var b = RunRng.new()
	a.set_seed_value(2026)
	b.set_seed_value(2026)
	var seq_a: Array = []
	var seq_b: Array = []
	for i in range(8):
		seq_a.append(a.next_int(100))
		seq_b.append(b.next_int(100))
	t.assert_eq(seq_a, seq_b, "same seed should produce same integers")

func test_same_seed_same_enemy_pick(t) -> void:
	var a = SurvivorStateScript.new()
	var b = SurvivorStateScript.new()
	a.start_new_run(77)
	b.start_new_run(77)
	a.elapsed_seconds = 300.0
	b.elapsed_seconds = 300.0
	var spawner = EnemySpawnerScript.new()
	var seq_a: Array = []
	var seq_b: Array = []
	for i in range(12):
		seq_a.append(spawner.pick_enemy_type(a))
		seq_b.append(spawner.pick_enemy_type(b))
	t.assert_eq(seq_a, seq_b, "same seed should produce same enemy picks")

func test_same_seed_same_shuffle(t) -> void:
	var a = RunRng.new()
	var b = RunRng.new()
	a.set_seed_value(3030)
	b.set_seed_value(3030)
	var values = ["a", "b", "c", "d", "e"]
	var shuffled_a = a.shuffled(values)
	var shuffled_b = b.shuffled(values)
	t.assert_eq(shuffled_a, shuffled_b, "same seed should produce the same shuffled order")
	t.assert_eq(values, ["a", "b", "c", "d", "e"], "shuffled should not mutate its input")
