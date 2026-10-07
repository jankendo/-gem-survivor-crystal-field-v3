extends RefCounted

const SpeedHoldSystemScript = preload("res://scripts/systems/SpeedHoldSystem.gd")

func run(t) -> void:
	var system = SpeedHoldSystemScript.new()
	system.configure({"speed_hold_enabled": true, "speed_hold_key": "tab", "speed_multiplier": 1.5})
	t.assert_eq(system.hold_key, "tab", "speed hold key should be configurable")
	t.assert_eq(system.simulation_multiplier(true, false), 1.5, "pressed speed hold should apply configured multiplier")
	t.assert_eq(system.simulation_multiplier(true, true), 1.0, "blocked state should disable speed hold")
	t.assert_eq(system.simulation_multiplier(false, false), 1.0, "released speed hold should use normal speed")

