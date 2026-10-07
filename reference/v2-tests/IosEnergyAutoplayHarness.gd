extends RefCounted
class_name IosEnergyAutoplayHarness

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const LoggerScript = preload("res://scripts/systems/IosEnergyLogSystem.gd")

class EnergyRoot:
	extends Node
	var arena_view = null

func run(tree: SceneTree, battery_saver: bool, output_path: String) -> Array:
	var failures: Array = []
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(output_path))
	var state = StateScript.new()
	state.start_new_run(65001 if battery_saver else 65000, "energy-saver" if battery_saver else "energy-standard")
	state.enemies.resize(72)
	state.projectiles.resize(36)
	state.enemy_projectiles.resize(12)
	state.hit_flashes.resize(18)
	state.effect_lines.resize(8)
	state.floating_texts.resize(14)
	var optimizer = OptimizerScript.new()
	optimizer.configure({"battery_saver": battery_saver, "low_power_mode": battery_saver})
	var logger = LoggerScript.new()
	logger.configure(true, output_path)
	var root := EnergyRoot.new()
	for i in range(24):
		root.add_child(Node.new())
	var hud_label := Label.new()
	root.add_child(hud_label)
	var initial_nodes := _count_nodes(root)
	var initial_memory := OS.get_static_memory_usage()
	var mid_nodes := initial_nodes
	var mid_score := 0.0
	var end_score := 0.0
	var frame_delta := 1.0 / 60.0
	for iteration in range(72000):
		state.elapsed_seconds += frame_delta
		if iteration % 10 == 0:
			state.ios_pathing_update_count += 1
		optimizer.tick(frame_delta)
		if iteration % 60 == 0:
			optimizer.set_label(hud_label, "時間 %.0f" % state.elapsed_seconds)
		if iteration % 300 == 0:
			optimizer.mark_ui_rebuild()
		logger.tick(frame_delta, state, root, optimizer)
		if state.elapsed_seconds >= 600.0 and mid_score <= 0.0:
			mid_nodes = _count_nodes(root)
			mid_score = optimizer.energy_score(state, root)
	end_score = optimizer.energy_score(state, root)
	var end_nodes := _count_nodes(root)
	var end_memory := OS.get_static_memory_usage()
	var elapsed := maxf(1.0, state.elapsed_seconds)
	var label_rate := float(optimizer.label_update_count) / elapsed
	var label_limit := float(optimizer.budget.get("max_label_updates_per_second", 30))
	var log_interval := float(optimizer.budget.get("max_log_write_interval", 5.0))
	var max_log_writes := int(ceil(elapsed / log_interval)) + 1
	if state.elapsed_seconds < 1199.0:
		failures.append("energy autoplay did not reach 20 simulated minutes")
	if end_score > maxf(mid_score * 1.35, mid_score + 8.0):
		failures.append("energy score grew without a matching workload increase")
	if end_nodes > maxi(initial_nodes, mid_nodes) + 12:
		failures.append("UI node count kept growing during the energy run")
	if label_rate > label_limit:
		failures.append("label update rate exceeded the selected energy budget")
	if optimizer.log_write_count > max_log_writes:
		failures.append("energy log writes exceeded the configured interval")
	if initial_memory > 0 and float(end_memory - initial_memory) / float(initial_memory) > 0.35:
		failures.append("memory grew more than 35 percent during the synthetic energy run")
	if not FileAccess.file_exists(output_path):
		failures.append("energy autoplay did not produce its CSV")
	_write_summary(output_path.get_basename() + "_summary.json", {
		"profile": optimizer.battery_profile,
		"elapsed_seconds": elapsed,
		"initial_nodes": initial_nodes,
		"mid_nodes": mid_nodes,
		"end_nodes": end_nodes,
		"created_nodes_per_second": float(maxi(0, end_nodes - mid_nodes)) / maxf(1.0, elapsed - 600.0),
		"initial_memory": initial_memory,
		"end_memory": end_memory,
		"mid_energy_score": mid_score,
		"end_energy_score": end_score,
		"label_update_count": optimizer.label_update_count,
		"log_write_count": optimizer.log_write_count
	})
	root.free()
	await tree.process_frame
	return failures

func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count

func _write_summary(path: String, data: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
