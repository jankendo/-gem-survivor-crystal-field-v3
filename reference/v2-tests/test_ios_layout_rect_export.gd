extends RefCounted

const IosLayoutDiagnosticSystemScript = preload("res://scripts/systems/IosLayoutDiagnosticSystem.gd")

func run(t) -> void:
	var path := "res://test-output/screenshots/ios_layout/layout_rects.json"
	var sizes := [
		Vector2(1334, 750),
		Vector2(1792, 828),
		Vector2(2532, 1170),
		Vector2(2796, 1290),
		Vector2(2388, 1668),
		Vector2(2732, 2048)
	]
	var diagnostic = IosLayoutDiagnosticSystemScript.new()
	t.assert_true(diagnostic.export_snapshots(path, sizes, {}), "iOS layout JSON should export")
	var file := FileAccess.open(path, FileAccess.READ)
	t.assert_true(file != null, "exported layout JSON should be readable")
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		t.assert_true(parsed is Dictionary, "layout export should be valid JSON")
		t.assert_eq((parsed.get("layouts", []) as Array).size(), sizes.size(), "layout export should include every QA size")

