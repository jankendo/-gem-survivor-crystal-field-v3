extends RefCounted

const SpeedLock = preload("res://scripts/systems/SpeedLockSystem.gd")

func run(t) -> void:
	var system = SpeedLock.new()
	system.begin_press()
	system.tick(1.0)
	system.end_press()
	t.assert_eq(system.simulation_multiplier(true), 1.0, "modal state must temporarily force 1x")
	t.assert_true(system.locked, "modal state must retain the lock")
	t.assert_eq(system.simulation_multiplier(false), 2.0, "closing modal must restore the lock")
