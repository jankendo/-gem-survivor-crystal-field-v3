extends RefCounted

const CoreScript = preload("res://scripts/performance/EnemySimulationCore.gd")

func run(t) -> void:
	var a = CoreScript.new()
	var b = CoreScript.new()
	for i in range(8):
		var pos := Vector2(float(i * 32), float(i * 9))
		a.spawn("slime", pos, 5 + i, 18.0, 70.0 + float(i))
		b.spawn("slime", pos, 5 + i, 18.0, 70.0 + float(i))
	for frame in range(12):
		var stats_a: Dictionary = a.step_toward(Vector2(420, 180), 0.016, 3)
		var stats_b: Dictionary = b.step_toward(Vector2(420, 180), 0.016, 3)
		t.assert_eq(stats_a.updated, stats_b.updated, "same scheduler input should update the same count")
	t.assert_eq(a.store.alive_count, b.store.alive_count, "deterministic cores should keep alive count equal")
	for index in range(a.store.positions.size()):
		var distance: float = a.store.positions[index].distance_to(b.store.positions[index])
		t.assert_true(distance < 0.001, "deterministic cores should keep positions equal")
