extends RefCounted

const LogScript = preload("res://scripts/systems/IosPerformanceLogSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var path := "user://test_ios_performance_logging.csv"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var state = StateScript.new()
	state.start_new_run(77)
	state.performance_profile_id = "ios_standard"
	var root = Node.new()
	var logger = LogScript.new()
	logger.configure(true, path)
	logger.tick(5.1, state, root)
	t.assert_true(FileAccess.file_exists(path), "iOS performance logger should create a CSV")
	var lines := FileAccess.get_file_as_string(path).split("\n")
	t.assert_true(lines.size() >= 2, "iOS performance logger should write a sample row")
	for column in ["frame_time_ms", "active_enemy_count", "damage_number_count", "control_node_count", "freed_nodes_per_second", "pooled_nodes_count", "memory_estimate_mb", "ios_profile"]:
		t.assert_true(lines[0].contains(column), "performance CSV should include %s" % column)
	root.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
