extends RefCounted

const TooltipSystemScript = preload("res://scripts/systems/TooltipSystem.gd")

func run(t) -> void:
	test_tooltip_contents(t)
	test_discovery_persists_into_collection(t)

func test_tooltip_contents(t) -> void:
	var defs = JSON.parse_string(FileAccess.open("res://data/field_help.json", FileAccess.READ).get_as_text())
	var entry: Dictionary = defs["drops"]["evolution_core"]
	var system = TooltipSystemScript.new()
	var nearby = system.format_field_help(entry)
	t.assert_true(nearby.find("対処：") >= 0, "nearby tooltip should explain handling")
	t.assert_true(nearby.find("報酬：") >= 0, "nearby tooltip should include reward")
	t.assert_true(nearby.find("おすすめ：") >= 0, "nearby tooltip should include build recommendation")
	t.assert_eq(system.danger_meter(4), "●●●●○", "danger meter should render five steps")

func test_discovery_persists_into_collection(t) -> void:
	var path = "user://test_field_tooltips.save"
	var save = SaveSystem.new(path)
	save.save_data({})
	save.mark_field_discovered("gimmick", "spawn_rift")
	var rows = MetaProgressionSystem.new().collection_rows("field_gimmicks", save.load_data())
	var row = _row(rows, "spawn_rift")
	t.assert_true(bool(row.get("known", false)), "field discovery should persist into collection")
	t.assert_true(String(row.get("detail_ja", "")).find("対処：") >= 0, "field collection should show approach")
	t.assert_true(String(row.get("detail_ja", "")).find("報酬：") >= 0, "field collection should show reward")

func _row(rows: Array, id: String) -> Dictionary:
	for row in rows:
		if String(row.get("id", "")) == id:
			return row
	return {}
