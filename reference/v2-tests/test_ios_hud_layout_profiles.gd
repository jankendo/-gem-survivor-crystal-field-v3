extends RefCounted

const SafeScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const HudScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")
const GuardScript = preload("res://scripts/systems/IosSafeAreaGuardSystem.gd")

func run(t) -> void:
	var sizes := [Vector2(1334, 750), Vector2(1792, 828), Vector2(2532, 1170), Vector2(2556, 1179), Vector2(2796, 1290), Vector2(2388, 1668), Vector2(2732, 2048)]
	for size in sizes:
		for orientation in ["landscape_left", "landscape_right"]:
			var safe := SafeScript.new().safe_rect_for_orientation(size, orientation, 16.0)
			var layout := HudScript.new().layout(size, safe)
			var violations = GuardScript.new().violations({
				"actions": layout.actions_rect, "pause": layout.pause_rect,
				"minimap": layout.minimap_rect, "move_zone": layout.move_zone_rect
			}, safe)
			t.assert_true(violations.is_empty(), "%s %s HUD must remain in safe area" % [size, orientation])
			t.assert_true(float(layout.button_extent) >= 64.0, "touch targets must exceed the 44pt-equivalent floor")
