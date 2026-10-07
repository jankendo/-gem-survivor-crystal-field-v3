extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var a = StateScript.new()
	var b = StateScript.new()
	a.start_new_run(771605, "field-equipment")
	b.start_new_run(771605, "field-equipment")
	t.assert_eq(a.map_generator.signature(a.map_data), b.map_generator.signature(b.map_data), "field equipment placement should be seed reproducible")
	var max_per_run := int(a.field_equipment_defs.get("config", {}).get("max_per_run", 8))
	t.assert_true(a.field_equipment.size() > 0 and a.field_equipment.size() <= max_per_run, "field equipment count should respect max_per_run")
	for equipment in a.field_equipment:
		t.assert_true(String(equipment.get("name_ja", "")) != "", "field equipment must have a visible name")
		t.assert_true(String(equipment.get("icon", "")) != "", "field equipment must have a minimap icon hint")
		t.assert_true(bool(equipment.get("allow_over_cap", false)), "field equipment should be an over-cap source")
