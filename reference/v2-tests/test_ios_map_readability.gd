extends RefCounted

const MobileMapSystemScript = preload("res://scripts/systems/MobileMapSystem.gd")
const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileHudLayoutSystemScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")
const ArenaViewScript = preload("res://scripts/ui/ArenaView.gd")

func run(t) -> void:
	var map_system = MobileMapSystemScript.new()
	var safe_system = MobileSafeAreaSystemScript.new()
	var hud_system = MobileHudLayoutSystemScript.new()
	for size in [Vector2(1334, 750), Vector2(1792, 828), Vector2(2796, 1290), Vector2(2388, 1668)]:
		var settings: Dictionary = map_system.settings_for(size, {})
		t.assert_true(float(settings["minimap_size"]) >= 180.0, "iOS minimap should be readable at %s" % str(size))
		t.assert_true(float(settings["minimap_icon"]) >= 8.0, "important minimap icons should stay visible")
		t.assert_true(float(settings["camera_zoom"]) >= 0.95 and float(settings["camera_zoom"]) <= 1.25, "camera zoom should remain in mobile range")
		var safe := safe_system.safe_rect(size, 16.0)
		var layout := hud_system.layout(size, safe, {})
		t.assert_true(safe.encloses(layout["minimap_rect"]), "minimap must stay in safe area")
		t.assert_true(not layout["minimap_rect"].intersects(layout["actions_rect"]), "minimap must not overlap actions")

	var arena = ArenaViewScript.new()
	arena.configure_mobile({
		"camera_zoom": 1.2,
		"minimap_rect": Rect2(900, 80, 204, 204),
		"expanded_map_rect": Rect2(240, 90, 800, 540),
		"minimap_opacity": 0.76,
		"minimap_icon": 9.0,
		"map_tap_expand": true
	})
	arena.set_map_expanded(true)
	t.assert_true(arena.map_expanded, "expanded map should open")
	arena.set_map_expanded(false)
	t.assert_true(not arena.map_expanded, "expanded map should close")
	arena.free()
