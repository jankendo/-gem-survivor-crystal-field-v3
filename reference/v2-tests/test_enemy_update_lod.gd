extends RefCounted

const SchedulerScript = preload("res://scripts/performance/EnemyFrameScheduler.gd")

func run(t) -> void:
	var scheduler = SchedulerScript.new()
	t.assert_eq(scheduler.update_interval_for_distance(240.0), 0.05, "near enemies should update frequently")
	t.assert_eq(scheduler.update_interval_for_distance(900.0), 0.20, "mid distance enemies should update at medium cadence")
	t.assert_eq(scheduler.update_interval_for_distance(1600.0), 0.35, "far enemies should update at sparse cadence")
	t.assert_eq(scheduler.update_interval_for_distance(1600.0, true), 0.0, "bosses should not receive LOD delay")
	var active := [10, 20, 30, 40, 50]
	var first: Array = scheduler.select_indices(active, 3)
	var second: Array = scheduler.select_indices(active, 3)
	t.assert_eq(first, [10, 20, 30], "scheduler should start from cursor")
	t.assert_eq(second, [40, 50, 10], "scheduler should rotate work without starvation")
