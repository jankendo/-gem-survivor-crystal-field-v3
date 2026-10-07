extends RefCounted

const GridScript = preload("res://scripts/systems/SpatialHashGrid.gd")

class Point:
	extends RefCounted
	var position := Vector2.ZERO
	func _init(value: Vector2) -> void:
		position = value

func run(t) -> void:
	var items: Array = []
	for y in range(20):
		for x in range(20):
			items.append(Point.new(Vector2(x, y) * 100.0))
	var grid = GridScript.new(160.0)
	grid.rebuild(items)
	var nearby := grid.query_radius(Vector2(500, 500), 180.0)
	t.assert_true(not nearby.is_empty(), "spatial query should find nearby items")
	t.assert_true(grid.query_candidates_last < items.size(), "nearby query must avoid a full-array scan")
