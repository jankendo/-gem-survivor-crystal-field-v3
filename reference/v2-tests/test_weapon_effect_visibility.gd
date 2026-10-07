extends RefCounted

func run(t) -> void:
	test_all_weapons_have_full_effect_metadata(t)
	test_melee_and_lightning_visibility_flags(t)
	test_evolved_effects_are_distinct(t)

func _json(path: String):
	return JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())

func test_all_weapons_have_full_effect_metadata(t) -> void:
	var weapons = _json("res://data/weapons.json")
	var effects = _json("res://data/weapon_effects.json")
	for id in weapons.keys():
		var data = effects.get(String(id), {})
		for key in ["effect_type", "primary_color", "secondary_color", "hit_effect", "evolved_effect_type", "screen_priority", "opacity", "lifetime", "max_effect_count"]:
			t.assert_true(data.has(key), "effect metadata should include %s for %s" % [key, String(id)])
		t.assert_true(data.has("normal") and data.has("evolved"), "normal/evolved effect definitions should exist for %s" % String(id))

func test_melee_and_lightning_visibility_flags(t) -> void:
	var weapons = _json("res://data/weapons.json")
	var effects = _json("res://data/weapon_effects.json")
	for id in weapons.keys():
		var tags: Array = weapons[String(id)].get("tags", [])
		var data = effects[String(id)]
		if tags.has("melee"):
			t.assert_true(bool(data.get("melee_arc", data.get("normal", {}).get("melee_arc", false))), "melee weapon should expose arc visibility for %s" % String(id))
			t.assert_true(bool(data.get("normal", {}).get("area_indicator", false)), "melee weapon should expose area indicator for %s" % String(id))
		if tags.has("lightning"):
			t.assert_true(bool(data.get("lightning_line", false)), "lightning weapon should expose lightning line for %s" % String(id))
			t.assert_true(bool(data.get("shock_icon", false)), "lightning weapon should expose shock icon for %s" % String(id))

func test_evolved_effects_are_distinct(t) -> void:
	var effects = _json("res://data/weapon_effects.json")
	for id in effects.keys():
		var normal = effects[String(id)]["normal"]
		var evolved = effects[String(id)]["evolved"]
		t.assert_true(String(normal.get("effect", "")) != String(evolved.get("effect", "")), "evolved effect should differ for %s" % String(id))
		t.assert_true(String(effects[String(id)].get("effect_type", "")) != String(effects[String(id)].get("evolved_effect_type", "")), "evolved effect type should differ for %s" % String(id))

