extends RefCounted

const IosLayoutDiagnosticSystemScript = preload("res://scripts/systems/IosLayoutDiagnosticSystem.gd")

func run(t) -> void:
	var diagnostic = IosLayoutDiagnosticSystemScript.new()
	for size in [Vector2(1334, 750), Vector2(1792, 828), Vector2(2796, 1290), Vector2(2388, 1668)]:
		var row: Dictionary = diagnostic.snapshot(size)
		var safe := _rect(row["safe_area"])
		var joystick := _rect(row["joystick_rect"])
		var actions := _rect(row["actions_rect"])
		var minimap := _rect(row["minimap_rect"])
		t.assert_true(float(row["action_button_extent"]) >= 64.0, "action buttons must be at least 64px")
		t.assert_true(float(row["joystick_visual_extent"]) >= 180.0, "joystick visual must be at least 180px")
		t.assert_true(float(row["joystick_touch_extent"]) > float(row["joystick_visual_extent"]), "joystick touch area must exceed its visual")
		t.assert_true(safe.encloses(joystick), "joystick must stay in safe area at %s" % str(size))
		t.assert_true(safe.encloses(actions), "actions must stay in safe area at %s" % str(size))
		t.assert_true(not actions.intersects(minimap), "actions must not overlap minimap at %s" % str(size))

func _rect(data: Dictionary) -> Rect2:
	return Rect2(float(data["x"]), float(data["y"]), float(data["width"]), float(data["height"]))

