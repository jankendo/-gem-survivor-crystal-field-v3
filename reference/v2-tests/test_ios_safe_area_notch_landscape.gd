extends RefCounted

const SafeScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const GuardScript = preload("res://scripts/systems/IosSafeAreaGuardSystem.gd")

func run(t) -> void:
	var safe_system = SafeScript.new()
	var guard = GuardScript.new()
	for orientation in ["landscape_left", "landscape_right"]:
		var safe := safe_system.safe_rect_for_orientation(Vector2(2556, 1179), orientation, 16.0)
		t.assert_true(safe.position.x >= 40.0, "notch side must have guarded horizontal inset")
		t.assert_true(Vector2(2556, 1179).y - safe.end.y >= 40.0, "home indicator must have extra bottom inset")
		var edge_button := Rect2(safe.position, Vector2(64, 64))
		t.assert_true(guard.violations({"button": edge_button}, safe).is_empty(), "guard should accept safe controls")
	var left := safe_system.insets_for_orientation(Vector2(2556, 1179), "landscape_left")
	var right := safe_system.insets_for_orientation(Vector2(2556, 1179), "landscape_right")
	t.assert_true(left.x > left.z and right.z > right.x, "landscape orientation must mirror the notch danger side")
