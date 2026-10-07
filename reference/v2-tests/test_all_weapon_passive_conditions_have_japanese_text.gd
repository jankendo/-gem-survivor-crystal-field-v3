extends RefCounted

const Progress = preload("res://scripts/systems/ProgressTrackerSystem.gd")

func run(t) -> void:
	var progress = Progress.new()
	for path in ["res://data/weapon_unlocks.json", "res://data/passive_unlocks.json"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for id in data:
			var entry: Dictionary = data[id]
			t.assert_true(String(entry.get("text_ja", "")).strip_edges() != "", "%s must have Japanese unlock text" % id)
			if bool(entry.get("initial", false)):
				continue
			var row := progress.progress_for_condition({"stats": {}}, entry.get("condition", {}))
			t.assert_true(String(row.get("label", "")).strip_edges() != "" and String(row.get("label", "")) != "条件進捗", "%s condition must have a concrete Japanese label" % id)
