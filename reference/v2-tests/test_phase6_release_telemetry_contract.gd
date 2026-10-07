extends RefCounted

const PerformanceLogScript = preload("res://scripts/systems/IosPerformanceLogSystem.gd")
const EnergyLogScript = preload("res://scripts/systems/IosEnergyLogSystem.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

class EnergyRoot:
	extends Node
	var arena_view = null

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(6161)
	var root := EnergyRoot.new()
	var perf_path := "user://test_phase6_perf_disabled.csv"
	var energy_path := "user://test_phase6_energy_disabled.csv"
	_remove_if_exists(perf_path)
	_remove_if_exists(energy_path)
	var performance_logger = PerformanceLogScript.new()
	performance_logger.configure(false, perf_path)
	performance_logger.tick(5.5, state, root)
	t.assert_true(not FileAccess.file_exists(perf_path), "release-standard performance logger should not create CSV output while disabled")
	t.assert_eq(performance_logger.frame_times_ms.size(), 0, "disabled performance logger should skip frame aggregation work")
	var optimizer = OptimizerScript.new()
	optimizer.configure({"battery_saver": false})
	var energy_logger = EnergyLogScript.new()
	energy_logger.configure(false, energy_path)
	energy_logger.tick(5.5, state, root, optimizer)
	t.assert_true(not FileAccess.file_exists(energy_path), "release-standard energy logger should not create CSV output while disabled")
	t.assert_eq(energy_logger.frame_times_5s.size(), 0, "disabled energy logger should skip frame aggregation work")
	performance_logger.configure(true, perf_path)
	performance_logger.tick(5.5, state, root)
	t.assert_true(FileAccess.file_exists(perf_path), "QA-enabled performance logger should create CSV output")
	energy_logger.configure(true, energy_path)
	energy_logger.tick(5.5, state, root, optimizer)
	t.assert_true(FileAccess.file_exists(energy_path), "QA-enabled energy logger should create CSV output")
	root.free()
	_remove_if_exists(perf_path)
	_remove_if_exists(energy_path)

func _remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
