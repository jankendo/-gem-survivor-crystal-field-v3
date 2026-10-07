extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_initial_collection_visibility(t)
	test_run_discovers_collection_entries(t)

func _fresh_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_collection.save")
	save.save_data({})
	save.reset_play_data("RESET")
	return save

func _has_known(rows: Array, id: String) -> bool:
	for row in rows:
		if String(row.get("id", "")) == id and bool(row.get("known", false)):
			return true
	return false

func test_initial_collection_visibility(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	t.assert_true(_has_known(meta.collection_rows("characters", save.load_data()), "noah"), "initial character should be known in collection")
	t.assert_true(not _has_known(meta.collection_rows("characters", save.load_data()), "ghost"), "locked secret character should not be known")

func test_run_discovers_collection_entries(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	meta.update_after_run(save, {
		"character_id": "noah",
		"survival_time": 300.0,
		"kills": 100,
		"weapon_levels": {"magic_bolt": 8},
		"evolved_weapon_ids": ["magic_bolt"],
		"enemy_seen": ["slime"],
		"boss_defeated_ids": ["boss_5"],
		"rune_contracts": [],
		"title_badges": ["生存者"]
	})
	var data := save.load_data()
	t.assert_true(_has_known(meta.collection_rows("weapons", data), "magic_bolt"), "used weapon should be discovered")
	t.assert_true(_has_known(meta.collection_rows("evolutions", data), "starbreaker_bolt"), "evolved weapon should be discovered")
	t.assert_true(_has_known(meta.collection_rows("enemies", data), "slime"), "seen enemy should be discovered")
	t.assert_true(_has_known(meta.collection_rows("bosses", data), "boss_5"), "defeated boss should be discovered")
