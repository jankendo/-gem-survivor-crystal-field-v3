extends RefCounted

func run(t) -> void:
	var manifest: Dictionary = _json("res://data/environment_asset_manifest.json")
	var contract: Dictionary = manifest.get("visibility_contract", {})
	t.assert_true(float(contract.get("floor_wall_luma_delta_min", 0.0)) >= 0.16, "floor/wall readability threshold should be explicit")
	t.assert_true(float(contract.get("floor_void_luma_delta_min", 0.0)) >= 0.14, "floor/void readability threshold should be explicit")
	t.assert_true(float(contract.get("pickup_floor_luma_delta_min", 0.0)) >= 0.18, "pickup/floor readability threshold should be explicit")
	t.assert_eq(String(manifest.get("generation_record", {}).get("human_review_status", "")), "needs_review", "generated environment art must remain unapproved until human review")
	var quality: Dictionary = _json("res://data/environment_visual_quality.json")
	var ios_low: Dictionary = quality.get("profiles", {}).get("ios_low", {})
	var high: Dictionary = quality.get("profiles", {}).get("high", {})
	t.assert_true(float(ios_low.get("tile_texture_alpha", 1.0)) < float(high.get("tile_texture_alpha", 0.0)), "iOS low should reduce environment texture dominance")
	t.assert_true(int(ios_low.get("decals_per_screen", 999)) < int(high.get("decals_per_screen", 0)), "iOS low should reduce decorative decal count")

func _json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
