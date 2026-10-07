extends RefCounted

const StoreScript = preload("res://scripts/performance/EnemyEntityStore.gd")

func run(t) -> void:
	var store = StoreScript.new()
	var first := store.allocate("slime", Vector2.ZERO, 3, 18.0, 70.0)
	var second := store.allocate("bat", Vector2(100, 0), 4, 14.0, 90.0)
	t.assert_eq(store.positions.size(), 2, "two allocations should create two slots")
	t.assert_true(store.remove(first), "first id should be removable")
	var reused := store.allocate("golem", Vector2(40, 50), 12, 24.0, 40.0)
	t.assert_eq(store.index_from_id(reused), store.index_from_id(first), "free list should reuse the released slot")
	t.assert_true(reused != first, "reused slot should receive a new generation id")
	t.assert_true(not store.is_alive(first), "old id must stay stale after slot reuse")
	t.assert_true(store.is_alive(second), "unrelated id should remain alive")
	t.assert_eq(store.positions.size(), 2, "reuse should not grow backing arrays")
	t.assert_eq(store.reused_count, 1, "reuse metric should increment")
