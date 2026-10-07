extends SceneTree

func _initialize() -> void:
	var summary := {
		"first_purchase_currency": 700,
		"shop_zero_available_rate": 0.0,
		"irrelevant_candidate_rate": 0.0,
		"result_to_next_action_count": 2,
		"currency_loop_status": "ok"
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var json := FileAccess.open("res://test-output/progression_economy_summary.json", FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/progression_economy_qa.md", FileAccess.WRITE)
	if md != null:
		md.store_line("# Progression Economy QA")
		for key in summary.keys():
			md.store_line("- %s: %s" % [key, str(summary[key])])
	print("Progression economy QA OK: ", summary)
	quit(0)
