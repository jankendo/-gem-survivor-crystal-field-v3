extends RefCounted

func run(t) -> void:
	var bosses := _json_dict("res://data/bosses.json")
	t.assert_true(bosses.keys().size() > 0, "boss definitions should exist")
	for id in bosses.keys():
		var data: Dictionary = bosses[id]
		t.assert_true(String(data.get("name_ja", id)) != "", "boss should have Japanese display name")

func _json_dict(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
