extends SceneTree

const IosLayoutDiagnosticSystemScript = preload("res://scripts/systems/IosLayoutDiagnosticSystem.gd")

func _initialize() -> void:
	var sizes := [
		Vector2(1334, 750),
		Vector2(1792, 828),
		Vector2(2532, 1170),
		Vector2(2796, 1290),
		Vector2(2388, 1668),
		Vector2(2732, 2048)
	]
	var diagnostic = IosLayoutDiagnosticSystemScript.new()
	if not diagnostic.export_snapshots("res://test-output/screenshots/ios_layout/layout_rects.json", sizes, {}):
		push_error("Failed to export iOS layout QA rectangles.")
		quit(1)
		return
	for size in sizes:
		var row: Dictionary = diagnostic.snapshot(size)
		if float(row["action_button_extent"]) < 64.0 or float(row["joystick_visual_extent"]) < 180.0:
			push_error("iOS layout QA failed at %s" % str(size))
			quit(1)
			return
	print("AutoPlay iOS Layout QA OK: six device profiles exported.")
	quit(0)

