extends RefCounted

const SystemScript = preload("res://scripts/systems/DynamicVirtualJoystickSystem.gd")

func run(t) -> void:
	var system = SystemScript.new()
	var safe := Rect2(96, 30, 1160, 660)
	system.configure(Vector2(1334, 750), safe, {"move_control_mode": "dynamic", "touch_handedness": "right"})
	for point in [Vector2(180, 80), Vector2(320, 360), Vector2(220, 650)]:
		t.assert_true(system.begin_touch(1, point), "dynamic joystick should start anywhere in the safe left half")
		t.assert_true(system.drag_touch(1, point + Vector2(70, 0)), "move touch should keep its own touch id")
		t.assert_true(system.direction.x > 0.0, "drag should produce movement")
		t.assert_true(not system.begin_touch(2, Vector2(300, 300)), "a second finger must not steal movement")
		t.assert_true(system.end_touch(1), "movement touch should release")
	t.assert_true(not system.begin_touch(3, Vector2(1100, 300)), "right action area must not start right-handed movement")
	t.assert_true(not system.begin_touch(4, Vector2(300, 300), true), "buttons and scroll surfaces must have priority")
	system.configure(Vector2(1334, 750), safe, {"move_control_mode": "dynamic", "touch_handedness": "left"})
	t.assert_true(system.begin_touch(5, Vector2(1000, 300)), "left-handed mode should move the start zone to the right")
	system.end_touch(5)
	var fixed := Rect2(120, 500, 196, 196)
	system.configure(Vector2(1334, 750), safe, {"move_control_mode": "fixed"}, fixed)
	t.assert_true(not system.begin_touch(6, Vector2(400, 300)), "fixed mode should reject touches outside its control")
	t.assert_true(system.begin_touch(6, fixed.get_center()), "fixed mode should remain available")
	system.end_touch(6)
	system.configure(Vector2(1334, 750), safe, {"move_control_mode": "dynamic"}, fixed)
	t.assert_true(system.begin_touch(7, safe.position + Vector2(2, 2)), "safe edge should still accept movement input")
	var visual_rect := Rect2(system.visual_origin() - Vector2.ONE * system.radius, Vector2.ONE * system.radius * 2.0)
	t.assert_true(safe.encloses(visual_rect), "visual outer ring should clamp inside the safe area")
