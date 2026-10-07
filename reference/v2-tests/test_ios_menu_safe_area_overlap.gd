extends RefCounted

const SafeScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const GuardScript = preload("res://scripts/systems/IosSafeAreaGuardSystem.gd")

func run(t) -> void:
	for orientation in ["landscape_left", "landscape_right"]:
		var safe := SafeScript.new().safe_rect_for_orientation(Vector2(1334, 750), orientation, 16.0)
		var footer := Rect2(Vector2(safe.position.x, safe.end.y - 64.0), Vector2(safe.size.x, 64.0))
		var dialog := Rect2(safe.get_center() - Vector2(240, 150), Vector2(480, 300))
		t.assert_true(GuardScript.new().violations({"footer": footer, "dialog": dialog}, safe).is_empty(), "menu footer and dialog must fit both orientations")
