extends RefCounted

const SpeedLock = preload("res://scripts/systems/SpeedLockSystem.gd")

func run(t) -> void:
	var system = SpeedLock.new()
	system.configure(2.0, 0.9)
	system.begin_press()
	system.tick(0.91)
	t.assert_true(system.locked, "long press must lock speed")
	system.end_press()
	t.assert_eq(system.simulation_multiplier(false), 2.0, "locked speed must remain active after release")
	system.begin_press()
	system.tick(0.1)
	system.end_press()
	t.assert_true(not system.locked, "short tap while locked must unlock")
