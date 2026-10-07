extends SceneTree

const Harness = preload("res://tests/phase4_environment_autoplay.gd")

func _initialize() -> void:
	var summary := Harness.new().simulate_title_navigation("ios_title_navigation")
	quit(0 if bool(summary.get("quit_hidden", false)) and bool(summary.get("start_first", false)) and int(summary.get("visible_action_count", 0)) >= 8 else 1)
