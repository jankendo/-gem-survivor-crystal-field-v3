extends RefCounted

func run(t) -> void:
	test_audio_manager_is_noop(t)
	test_no_audio_files_are_exported(t)
	test_no_sound_assets_remain(t)
	test_settings_show_audio_removed(t)

func test_audio_manager_is_noop(t) -> void:
	var manager = AudioManager.new()
	t.assert_true(manager.audio_disabled, "AudioManager should declare audio disabled")
	t.assert_true(not manager.play_sfx("attack"), "AudioManager should not play attack sounds")
	t.assert_eq(manager.audio_event_count, 0, "AudioManager should not count audio events")
	t.assert_eq(manager.get_child_count(), 0, "AudioManager should not create AudioStreamPlayer children")
	manager.free()

func test_no_audio_files_are_exported(t) -> void:
	var config = ConfigFile.new()
	t.assert_eq(config.load("res://export_presets.cfg"), OK, "export presets should load")
	t.assert_eq(String(config.get_value("preset.0", "include_filter", "")), "", "Windows export should not include raw audio")
	t.assert_eq(String(config.get_value("preset.1", "include_filter", "")), "", "iOS export should not include raw audio")

func test_no_sound_assets_remain(t) -> void:
	var dir = DirAccess.open("res://assets/sounds")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			t.assert_true(not file_name.ends_with(".wav") and not file_name.ends_with(".wav.import"), "sound asset should be removed: %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func test_settings_show_audio_removed(t) -> void:
	var text = FileAccess.open("res://scripts/ui/Main.gd", FileAccess.READ).get_as_text()
	t.assert_true(text.find("音声は廃止済み") >= 0, "settings screen should explain removed audio")
	t.assert_true(text.find("BGM音量") < 0, "settings screen should hide BGM volume")
	t.assert_true(text.find("SE音量") < 0, "settings screen should hide SE volume")
