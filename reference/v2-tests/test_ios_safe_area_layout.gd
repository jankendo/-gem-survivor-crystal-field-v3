extends RefCounted

const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileHudLayoutSystemScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")

func run(t) -> void:
	var safe_system = MobileSafeAreaSystemScript.new()
	var hud_system = MobileHudLayoutSystemScript.new()
	var sizes := [
		Vector2(1334, 750), Vector2(1792, 828), Vector2(2532, 1170),
		Vector2(2556, 1179), Vector2(2796, 1290), Vector2(2388, 1668),
		Vector2(2732, 2048)
	]
	for size in sizes:
		var safe: Rect2 = safe_system.safe_rect(size, 8.0)
		for handedness in ["right", "left"]:
			var layout: Dictionary = hud_system.layout(size, safe, {"touch_handedness": handedness})
			t.assert_true(safe.encloses(layout["joystick_rect"]), "joystick should stay in safe area at %s" % str(size))
			t.assert_true(safe.encloses(layout["actions_rect"]), "actions should stay in safe area at %s" % str(size))
			t.assert_true(safe.encloses(layout["pause_rect"]), "pause should stay in safe area at %s" % str(size))
			t.assert_true(safe.encloses(layout["minimap_rect"]), "minimap should stay in safe area at %s" % str(size))
			t.assert_true(not layout["joystick_rect"].intersects(layout["minimap_rect"]), "joystick should not overlap minimap at %s" % str(size))
			t.assert_true(not layout["actions_rect"].intersects(layout["minimap_rect"]), "actions should not overlap minimap at %s" % str(size))
			t.assert_true(float(layout["button_extent"]) >= 64.0, "touch target should remain accessible")
	var left_layout: Dictionary = hud_system.layout(Vector2(2556, 1179), safe_system.safe_rect(Vector2(2556, 1179)), {"touch_handedness": "left"})
	t.assert_true(left_layout["joystick_rect"].position.x > left_layout["actions_rect"].position.x, "left handed layout should swap joystick and actions")
