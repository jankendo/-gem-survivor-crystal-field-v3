extends SceneTree

const FirstRunTelemetryScript = preload("res://scripts/systems/FirstRunTelemetry.gd")

func _initialize() -> void:
	var summary: Dictionary = FirstRunTelemetryScript.new().qa_summary()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var json := FileAccess.open("res://test-output/first_run_experience_summary.json", FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/first_run_experience_qa.md", FileAccess.WRITE)
	if md != null:
		md.store_line("# First Run Experience QA")
		for key in summary.keys():
			md.store_line("- %s: %s" % [key, str(summary[key])])
	print("First-run QA OK: ", summary)
	quit(0)
