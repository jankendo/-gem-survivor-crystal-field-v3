extends RefCounted

const LoggerScript = preload("res://scripts/systems/IosEnergyLogSystem.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

class EnergyRoot:
	extends Node
	var arena_view = null

func run(t) -> void:
	var path := "user://test_ios_energy_log.csv"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var state = StateScript.new()
	state.start_new_run(4411, "energy-log")
	state.elapsed_seconds = 30.0
	var optimizer = OptimizerScript.new()
	optimizer.configure({"battery_saver": false})
	var logger = LoggerScript.new()
	logger.configure(true, path)
	var root := EnergyRoot.new()
	logger.tick(5.1, state, root, optimizer)
	t.assert_true(FileAccess.file_exists(path), "energy logger should create ios_energy_log.csv")
	var first_lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	t.assert_eq(first_lines.size(), 2, "first energy interval should write one sample")
	for column in ["draw_call_estimate", "overdraw_risk_score", "label_update_count", "haptic_count", "save_write_count", "battery_profile", "energy_score", "estimated_power_risk"]:
		t.assert_true(first_lines[0].contains(column), "energy CSV should include %s" % column)
	logger.tick(1.0, state, root, optimizer)
	var throttled_lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	t.assert_eq(throttled_lines.size(), 2, "energy log writes must be interval limited")
	logger.tick(4.1, state, root, optimizer)
	t.assert_eq(FileAccess.get_file_as_string(path).strip_edges().split("\n").size(), 3, "next interval should append one row")
	t.assert_eq(optimizer.log_write_count, 2, "log write counter should match actual writes")
	root.free()
	DirAccess.remove_absolute(absolute)
