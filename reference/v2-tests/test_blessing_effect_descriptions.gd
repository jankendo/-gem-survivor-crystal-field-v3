extends RefCounted

const MetaScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	var meta = MetaScript.new()
	for raw_id in meta.blessings.keys():
		var id := String(raw_id)
		var blessing: Dictionary = meta.blessings[id]
		for key in ["effect_description_ja", "numeric_effects_ja", "recommended_for_ja", "tradeoff_description_ja", "unlock_condition_ja"]:
			t.assert_true(blessing.has(key) and str(blessing.get(key, "")).length() > 0, "%s should define %s" % [id, key])
		var detail := meta.blessing_detail_text(id, SaveSystem.new("user://test_blessing_effects.save").load_data())
		t.assert_true(detail.contains("数値：") and detail.contains("推奨：") and detail.contains("注意："), "%s blessing detail should explain effect, recommendation, and tradeoff" % id)
	var collection := meta.collection_rows("blessings", SaveSystem.new("user://test_blessing_effects.save").load_data())
	t.assert_eq(collection.size(), meta.blessings.size(), "collection should list every blessing")
	t.assert_true(String(collection[0].get("detail_ja", "")).contains("数値："), "blessing collection should expose effect values")
