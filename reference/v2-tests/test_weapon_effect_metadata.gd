extends RefCounted

func run(t) -> void:
	test_all_weapons_have_effect_metadata(t)
	test_evolved_effects_differ_from_normal(t)

func _effects():
	var file = FileAccess.open("res://data/weapon_effects.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func test_all_weapons_have_effect_metadata(t) -> void:
	var effects = _effects()
	var weapons = JSON.parse_string(FileAccess.open("res://data/weapons.json", FileAccess.READ).get_as_text())
	for id in weapons.keys():
		t.assert_true(effects.has(String(id)), "weapon effect metadata should exist for %s" % String(id))
		var normal = effects[String(id)].get("normal", {})
		var color = normal.get("color", [])
		t.assert_true(color is Array and color.size() >= 3, "normal effect color should exist for %s" % String(id))
		t.assert_true(String(normal.get("shape", "")) != "", "normal effect shape should exist for %s" % String(id))
		t.assert_true(String(normal.get("effect", "")) != "", "normal effect type should exist for %s" % String(id))

func test_evolved_effects_differ_from_normal(t) -> void:
	var effects = _effects()
	for id in effects.keys():
		var normal = effects[String(id)].get("normal", {})
		var evolved = effects[String(id)].get("evolved", {})
		t.assert_true(not evolved.is_empty(), "evolved effect metadata should exist for %s" % String(id))
		t.assert_true(String(normal.get("shape", "")) != String(evolved.get("shape", "")) or String(normal.get("effect", "")) != String(evolved.get("effect", "")), "evolved effect should differ from normal for %s" % String(id))
