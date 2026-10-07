extends RefCounted

func run(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/ArenaView.gd")
	var minimap := FileAccess.get_file_as_string("res://scripts/systems/MinimapRenderCache.gd")
	t.assert_true(source.contains('id == "weapon_core"') and source.contains('id == "passive_core"'), "field cores must have distinct symbols")
	t.assert_true(minimap.contains('"weapon_core"') and minimap.contains('"passive_core"'), "minimap cores must have distinct commands")
