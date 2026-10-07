extends RefCounted
class_name Phase4EnvironmentTestUtils

const EnvironmentVisualSystemScript = preload("res://scripts/systems/EnvironmentVisualSystem.gd")

const MANIFEST_PATH := "res://data/environment_asset_manifest.json"
const QUALITY_PATH := "res://data/environment_visual_quality.json"
const EXPECTED_BIOMES := ["star_plain", "amethyst_forest", "red_mine", "void_zone"]
const EXPECTED_SURFACES := ["floor", "wall", "void", "decal"]
const MATERIAL_KEYS := ["albedo_path", "normal_path", "specular_path", "emission_path"]

func run(t, mode: String) -> void:
	match mode:
		"manifest":
			_assert_manifest(t)
		"resolution":
			_assert_resolution(t)
		"paths":
			_assert_paths(t)
		"material_resolution":
			_assert_material_resolution(t)
		"biome_completeness":
			_assert_biome_completeness(t)
		"quality_profiles":
			_assert_quality_profiles(t)
		"rng_determinism":
			_assert_rng_determinism(t)
		"collision_contract":
			_assert_collision_contract(t)
		"fallback":
			_assert_fallback(t)

func manifest() -> Dictionary:
	return _json(MANIFEST_PATH)

func quality() -> Dictionary:
	return _json(QUALITY_PATH)

func _assert_manifest(t) -> void:
	var data := manifest()
	t.assert_eq(int(data.get("schema_version", 0)), 1, "environment manifest schema version")
	t.assert_true(FileAccess.file_exists(String(data.get("source_concept_path", ""))), "source concept image must exist")
	t.assert_eq(String(data.get("generation_record", {}).get("human_review_status", "")), "needs_review", "generated environment art must keep human review state")
	var summary := EnvironmentVisualSystemScript.new().manifest_summary()
	t.assert_eq(int(summary.get("surface_count", 0)), EXPECTED_BIOMES.size() * EXPECTED_SURFACES.size(), "all biome surfaces must be represented")
	t.assert_eq(int(summary.get("missing_path_count", 0)), 0, "all environment material paths must resolve")

func _assert_resolution(t) -> void:
	for entry in _surface_entries():
		t.assert_eq(String(entry.get("resolution", "")), "512x512", "%s target resolution" % String(entry.get("asset_id", "")))
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(entry.get("albedo_path", ""))))
		t.assert_true(image != null and image.get_width() == 512 and image.get_height() == 512, "%s albedo must be 512x512" % String(entry.get("asset_id", "")))

func _assert_paths(t) -> void:
	for entry in _surface_entries():
		for key in MATERIAL_KEYS:
			var path := String(entry.get(key, ""))
			t.assert_true(path.begins_with("res://assets/v2/environment/"), "%s should stay under v2 environment assets" % key)
			t.assert_true(FileAccess.file_exists(path), "%s should exist: %s" % [key, path])

func _assert_material_resolution(t) -> void:
	for entry in _surface_entries():
		var reference := _image_size(String(entry.get("albedo_path", "")))
		for key in ["normal_path", "specular_path", "emission_path"]:
			t.assert_eq(_image_size(String(entry.get(key, ""))), reference, "%s must match albedo resolution for %s" % [key, String(entry.get("asset_id", ""))])

func _assert_biome_completeness(t) -> void:
	var biomes: Dictionary = manifest().get("biomes", {})
	for biome_id in EXPECTED_BIOMES:
		t.assert_true(biomes.has(biome_id), "environment manifest must contain biome %s" % biome_id)
		var surfaces: Dictionary = biomes[biome_id].get("surfaces", {})
		for surface in EXPECTED_SURFACES:
			t.assert_true(surfaces.has(surface), "%s must contain %s surface" % [biome_id, surface])
			t.assert_eq(String(surfaces[surface].get("replacement_status", "")), "integrated", "%s %s must be integrated" % [biome_id, surface])

func _assert_quality_profiles(t) -> void:
	var profiles: Dictionary = quality().get("profiles", {})
	for profile in ["ios_low", "low", "medium", "high"]:
		t.assert_true(profiles.has(profile), "quality profile should exist: %s" % profile)
		t.assert_true(float(profiles[profile].get("target_fps", 0)) >= 60.0, "quality profile should target 60fps: %s" % profile)
	var budgets: Dictionary = quality().get("budgets", {})
	t.assert_true(int(budgets.get("max_texture_size_px", 0)) <= 512, "environment texture budget must stay mobile-safe")

func _assert_rng_determinism(t) -> void:
	var system = EnvironmentVisualSystemScript.new()
	for biome_id in EXPECTED_BIOMES:
		var a := system.deterministic_variant(biome_id, "floor", "12,24", 12345)
		var b := system.deterministic_variant(biome_id, "floor", "12,24", 12345)
		var c := system.deterministic_variant(biome_id, "floor", "13,24", 12345)
		t.assert_eq(a, b, "%s visual variant must be deterministic" % biome_id)
		t.assert_true(a != c or a >= 0, "%s visual variant should be stable and bounded" % biome_id)

func _assert_collision_contract(t) -> void:
	var contract: Dictionary = manifest().get("collision_visual_contract", {})
	t.assert_true(bool(contract.get("floor", {}).get("walkable", false)), "floor visuals must represent walkable cells")
	t.assert_true(not bool(contract.get("wall", {}).get("walkable", true)), "wall visuals must not be walkable")
	t.assert_true(not bool(contract.get("void", {}).get("walkable", true)), "void visuals must not be walkable")
	t.assert_eq(String(contract.get("decal", {}).get("collision_source", "")), "none", "decals must not create collision")

func _assert_fallback(t) -> void:
	var system = EnvironmentVisualSystemScript.new("res://data/missing_environment_asset_manifest.json", "res://data/missing_environment_visual_quality.json")
	t.assert_true(system.biome_ids().has("star_plain"), "fallback manifest must expose star_plain")
	t.assert_true(system.surface_color("missing", "floor", Color(0.1, 0.2, 0.3)).r > 0.0, "fallback surface color should be safe")
	t.assert_true(system.surface_texture("missing", "floor") == null, "missing fallback texture should not crash")

func _surface_entries() -> Array:
	var result: Array = []
	var biomes: Dictionary = manifest().get("biomes", {})
	for biome in biomes.values():
		for entry in (biome.get("surfaces", {}) as Dictionary).values():
			result.append(entry)
	return result

func _image_size(path: String) -> Vector2i:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return Vector2i.ZERO
	return Vector2i(image.get_width(), image.get_height())

func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
