extends SceneTree

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func _initialize() -> void:
	var save = SaveSystemScript.new()
	save.save_help_seen(true)
	save.update_settings({
		"touch_tutorial_seen": true,
		"touch_ui_mode": "auto",
		"qa_telemetry_enabled": false,
	})
	print("Full test shard prerequisites prepared.")
	quit(0)
