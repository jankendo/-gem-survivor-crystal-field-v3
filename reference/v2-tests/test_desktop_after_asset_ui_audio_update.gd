extends RefCounted

func run(t) -> void:
	var save_settings = SaveSystem.new()._with_defaults({}).get("settings", {})
	t.assert_true(bool(save_settings.get("audio_disabled", true)), "desktop defaults should keep audio disabled")
	t.assert_eq(float(save_settings.get("bgm_volume", 0.0)), 0.0, "desktop BGM volume should default to zero")
	t.assert_true(FileAccess.file_exists("res://tools/asset_generation_manifest.json"), "generated asset manifest should ship with the project")
	var config = ConfigFile.new()
	t.assert_eq(config.load("res://export_presets.cfg"), OK, "export preset should load after asset/audio update")
	t.assert_eq(String(config.get_value("preset.0", "name", "")), "Windows Desktop", "desktop export preset should remain")
