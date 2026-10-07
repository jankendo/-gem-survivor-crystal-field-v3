extends RefCounted

const MobileUiScaleSystemScript = preload("res://scripts/systems/MobileUiScaleSystem.gd")
const MobileSafeAreaSystemScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const MobileHudLayoutSystemScript = preload("res://scripts/systems/MobileHudLayoutSystem.gd")

func run(t) -> void:
	var scale = MobileUiScaleSystemScript.new()
	var safe_system = MobileSafeAreaSystemScript.new()
	var hud_system = MobileHudLayoutSystemScript.new()
	for size in [Vector2(2388, 1668), Vector2(2732, 2048)]:
		var metrics: Dictionary = scale.metrics(size)
		t.assert_eq(String(metrics["profile"]), "tablet", "4:3 iPad should use tablet layout")
		t.assert_true(int(metrics["visible_characters"]) >= 8, "iPad should show at least eight characters")
		t.assert_true(float(metrics["joystick_outer"]) <= 196.0, "iPad joystick should not be oversized")
		var safe := safe_system.safe_rect(size, 16.0)
		var layout: Dictionary = hud_system.layout(size, safe, {})
		t.assert_true(float(layout["button_extent"]) <= 86.0, "iPad buttons should remain proportionate")
		t.assert_true(float(layout["minimap_rect"].size.x) >= 180.0, "iPad minimap should remain readable")

	t.assert_true(scale.classify(Vector2(2796, 1290)) == "large_phone", "wide Pro Max must not be mistaken for iPad")

