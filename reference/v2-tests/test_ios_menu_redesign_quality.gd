extends RefCounted

func run(t) -> void:
	test_equipment_components_exist(t)
	test_audio_removed_from_settings_copy(t)

func test_equipment_components_exist(t) -> void:
	for path in [
		"res://scripts/ui/components/EquipmentGridView.gd",
		"res://scripts/ui/components/EquipmentIconCell.gd",
		"res://scripts/ui/components/EquipmentDetailSheet.gd",
		"res://scripts/ui/components/EquipmentFilterChips.gd",
		"res://scripts/ui/components/EquipmentStatsPanel.gd"
	]:
		t.assert_true(FileAccess.file_exists(path), "equipment redesign component should exist: %s" % path)

func test_audio_removed_from_settings_copy(t) -> void:
	var text = FileAccess.open("res://scripts/ui/Main.gd", FileAccess.READ).get_as_text()
	t.assert_true(text.find("音声は廃止済み") >= 0, "iOS settings should present removed audio state")
	t.assert_true(text.find("GridContainer") >= 0, "menu code should retain grid-based surfaces")
