extends RefCounted

func run(t) -> void:
	test_all_character_assets_exist(t)
	test_secret_locked_assets_exist(t)

func test_all_character_assets_exist(t) -> void:
	var characters = JSON.parse_string(FileAccess.open("res://data/characters.json", FileAccess.READ).get_as_text())
	for id in characters.keys():
		var path = "res://assets/survivor/characters/%s.svg" % String(id)
		t.assert_true(FileAccess.file_exists(path), "character asset should exist: %s" % path)

func test_secret_locked_assets_exist(t) -> void:
	t.assert_true(FileAccess.file_exists("res://assets/survivor/characters/secret_ghost_locked.svg"), "locked Ghost silhouette should exist")
	t.assert_true(FileAccess.file_exists("res://assets/survivor/characters/secret_collector_locked.svg"), "locked Collector silhouette should exist")
	t.assert_true(FileAccess.file_exists("res://assets/survivor/characters/secret_nameless_reaper_locked.svg"), "locked Reaper silhouette should exist")
