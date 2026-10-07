extends SceneTree

func _initialize() -> void:
	var quality := _json("res://data/environment_visual_quality.json")
	var profiles: Dictionary = quality.get("profiles", {})
	var ios_low: Dictionary = profiles.get("ios_low", {})
	var high: Dictionary = profiles.get("high", {})
	var summary := {
		"ios_low_tile_texture_alpha": ios_low.get("tile_texture_alpha", 0.0),
		"high_tile_texture_alpha": high.get("tile_texture_alpha", 0.0),
		"ios_low_decals_per_screen": ios_low.get("decals_per_screen", 0),
		"high_decals_per_screen": high.get("decals_per_screen", 0),
		"material_maps_disabled_on_ios_low": not bool(ios_low.get("material_maps", true))
	}
	_write_report(summary)
	var ok := float(summary.ios_low_tile_texture_alpha) < float(summary.high_tile_texture_alpha) and int(summary.ios_low_decals_per_screen) < int(summary.high_decals_per_screen) and bool(summary.material_maps_disabled_on_ios_low)
	quit(0 if ok else 1)

func _json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func _write_report(summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output/phase5"))
	var json := FileAccess.open("res://test-output/phase5/visual_adaptation.json", FileAccess.WRITE)
	json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/phase5/visual_adaptation.md", FileAccess.WRITE)
	md.store_line("# Phase 5 Visual Adaptation")
	for key in summary.keys():
		md.store_line("- %s: %s" % [key, str(summary[key])])
