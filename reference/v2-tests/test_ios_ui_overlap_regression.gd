extends RefCounted

const SafeScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const HudScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")
const OverlapScript = preload("res://scripts/systems/IosLayoutOverlapSystem.gd")

func run(t) -> void:
	var size := Vector2(1334, 750)
	var safe := SafeScript.new().safe_rect_for_orientation(size, "landscape_left", 16.0)
	var layout := HudScript.new().layout(size, safe)
	var overlaps = OverlapScript.new().overlaps({
		"actions": layout.actions_rect,
		"minimap": layout.minimap_rect,
		"pause": layout.pause_rect,
		"log": layout.log_rect,
		"map": layout.map_rect
	})
	t.assert_true(overlaps.is_empty(), "primary iOS HUD controls must not overlap")
	t.assert_true(not layout.actions_rect.intersects(layout.equipment_rect), "action buttons must not overlap equipment HUD")
