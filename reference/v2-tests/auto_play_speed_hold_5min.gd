extends SceneTree

func _initialize() -> void:
	var speed = preload("res://scripts/systems/SpeedHoldSystem.gd").new()
	speed.configure({"speed_hold_enabled": true, "speed_hold_key": "left_shift", "speed_multiplier": 2.0})
	var elapsed = 0.0
	for i in range(9000):
		elapsed += (1.0 / 60.0) * speed.simulation_multiplier(true, false)
	if elapsed < 299.9 or elapsed > 300.1:
		push_error("Speed hold autoplay failed to reach five simulated minutes")
		quit(1)
	if speed.simulation_multiplier(true, true) != 1.0:
		push_error("Speed hold autoplay failed blocked-state rule")
		quit(1)
	print("AutoPlay OK: speed hold reaches 5min at x2 and disables during blocked UI.")
	quit(0)

