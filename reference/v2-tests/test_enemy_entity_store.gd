extends RefCounted

const StoreScript = preload("res://scripts/performance/EnemyEntityStore.gd")

func run(t) -> void:
	var store = StoreScript.new()
	var id := store.allocate("slime", Vector2(10, 20), 5, 18.0, 70.0)
	t.assert_true(store.is_alive(id), "allocated enemy id should be alive")
	t.assert_eq(store.alive_count, 1, "alive count should increase after allocation")
	t.assert_eq(store.position_of(id), Vector2(10, 20), "position should be stored in SoA array")
	t.assert_true(not store.damage(id, 2), "partial damage should not report lethal")
	t.assert_true(store.damage(id, 3), "lethal damage should report lethal without mutating spawn count")
	t.assert_true(store.remove(id), "dead entity id should be removable")
	t.assert_true(not store.is_alive(id), "removed id should become stale")
	var stats: Dictionary = store.stats()
	t.assert_eq(int(stats.alive), 0, "store stats should expose alive count")
	t.assert_eq(int(stats.removed), 1, "store stats should expose remove count")
