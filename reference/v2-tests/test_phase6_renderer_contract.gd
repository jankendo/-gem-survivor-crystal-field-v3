extends RefCounted

const HarnessScript = preload("res://tests/Phase6BenchmarkHarness.gd")

func run(t) -> void:
	var method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_method := String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	t.assert_eq(method, "gl_compatibility", "Phase 6 should use the 2D-friendly Compatibility renderer")
	t.assert_eq(mobile_method, "gl_compatibility", "mobile renderer should match the adopted Compatibility renderer")
	var features: PackedStringArray = ProjectSettings.get_setting("application/config/features", PackedStringArray())
	t.assert_true(features.has("4.7"), "project features should record the adopted Godot 4.7 format")
	t.assert_true(features.has("GL Compatibility"), "project features should record GL Compatibility")
	t.assert_true(not features.has("Forward Plus"), "project features should not silently return to Forward+")
	var version: Dictionary = Engine.get_version_info()
	t.assert_eq(int(version.get("major", 0)), 4, "Phase 6 engine contract should remain on Godot 4")
	t.assert_eq(int(version.get("minor", 0)), 7, "Phase 6 engine contract should run on Godot 4.7")
	var harness = HarnessScript.new()
	t.assert_true(RenderingServer.has_method("get_current_rendering_method"), "Godot 4.7 should expose runtime renderer reporting")
	t.assert_eq(harness._rendering_method(), "gl_compatibility", "runtime renderer should match the adopted Compatibility renderer")
	var config := ConfigFile.new()
	t.assert_eq(config.load("res://export_presets.cfg"), OK, "export presets should load for renderer contract")
	t.assert_true(String(config.get_value("preset.0", "exclude_filter", "")).find("tests/*") >= 0, "Windows export should keep tests out of release artifacts")
	t.assert_true(String(config.get_value("preset.1.options", "application/bundle_identifier", "")) == "com.jankendo14.gemsurvivor", "iOS bundle identifier should remain compatible")
