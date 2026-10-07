extends RefCounted

func run(t) -> void:
	test_windows_export_preset(t)
	test_ios_export_preset(t)

func test_windows_export_preset(t) -> void:
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	t.assert_eq(err, OK, "export_presets.cfg should load")
	t.assert_eq(String(config.get_value("preset.0", "name", "")), "Windows Desktop", "Windows export preset name should match")
	t.assert_eq(String(config.get_value("preset.0", "export_path", "")), "builds/ChronoMergeTactics.exe", "export path should target builds exe")
	t.assert_eq(String(config.get_value("preset.0", "include_filter", "")), "", "audio files should not be force-included after sound removal")
	var exclude_filter := String(config.get_value("preset.0", "exclude_filter", ""))
	t.assert_true(exclude_filter.find("tests/*") >= 0, "tests should be excluded from release export")
	t.assert_true(exclude_filter.find("tools/*") >= 0, "tools should be excluded from release export")
	t.assert_true(exclude_filter.find("test-output/*") >= 0, "test output should be excluded from release export")
	t.assert_true(exclude_filter.find("artifacts/*") >= 0, "local CI artifacts should be excluded from release export")
	t.assert_true(exclude_filter.find(".github/*") >= 0, "workflow metadata should be excluded from release export")
	t.assert_eq(bool(config.get_value("preset.0.options", "application/modify_resources", true)), false, "modify_resources should be false to avoid rcedit dependency")

func test_ios_export_preset(t) -> void:
	var config := ConfigFile.new()
	var err := config.load("res://export_presets.cfg")
	t.assert_eq(err, OK, "export_presets.cfg should load for iOS")
	t.assert_eq(String(ProjectSettings.get_setting("application/config/name", "")), "Gem Survivor Crystal Field", "iOS display name should match the release contract")
	t.assert_eq(String(config.get_value("preset.1", "name", "")), "iOS", "iOS export preset should exist")
	t.assert_eq(String(config.get_value("preset.1", "platform", "")), "iOS", "iOS preset platform should match")
	t.assert_eq(String(config.get_value("preset.1.options", "application/bundle_identifier", "")), "com.jankendo14.gemsurvivor", "iOS bundle identifier should match")
	t.assert_true(bool(config.get_value("preset.1.options", "application/export_project_only", false)), "iOS export should generate an unsigned Xcode project")
	t.assert_true(String(config.get_value("preset.1.options", "icons/app_store_1024x1024", "")).find("app_icon_1024.png") >= 0, "iOS app icon should be generated in-project")
