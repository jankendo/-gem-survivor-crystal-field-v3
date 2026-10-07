extends RefCounted

const GridScript = preload("res://scripts/performance/SpatialHashGrid2D.gd")
const BufferScript = preload("res://scripts/performance/SpatialQueryBuffer.gd")

func run(t) -> void:
	var grid = GridScript.new(128.0)
	var items: Array = []
	for y in range(16):
		for x in range(16):
			items.append({"position": Vector2(x * 96, y * 96), "id": y * 16 + x})
	grid.rebuild(items)
	var buffer = BufferScript.new()
	var nearby: Array = grid.query_radius(Vector2(480, 480), 170.0, buffer)
	t.assert_true(not nearby.is_empty(), "spatial hash should return nearby objects")
	t.assert_true(grid.query_candidates_last < items.size(), "spatial hash query should avoid full-array scan")
	t.assert_eq(buffer.size(), nearby.size(), "query buffer should hold the returned candidates")
	grid.clear()
	grid.insert_id(42, Vector2(20, 20))
	grid.insert_id(77, Vector2(800, 800))
	var ids: Array = grid.query_ids_radius(Vector2.ZERO, 64.0)
	t.assert_true(ids.has(42), "id query should include nearby id")
	t.assert_true(not ids.has(77), "id query should exclude distant id")
