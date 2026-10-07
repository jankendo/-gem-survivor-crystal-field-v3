extends SceneTree

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const V2MomentumSystemScript = preload("res://scripts/systems/V2MomentumSystem.gd")

func _initialize() -> void:
	var seeds := [20260201, 20260202, 20260203]
	var summaries: Array = []
	var failed := false
	for seed in seeds:
		var summary := _simulate_seed(seed)
		summaries.append(summary)
		if not _within_targets(summary):
			failed = true
	_write_reports(summaries)
	if failed:
		push_error("V2 momentum 10 minute balance target failed. See test-output/v2_momentum_balance_report.md")
		quit(1)
	else:
		print("V2 momentum 10 minute balance target passed.")
		quit(0)

func _simulate_seed(seed: int) -> Dictionary:
	var state = SurvivorStateScript.new()
	state.start_new_run(seed)
	var system = V2MomentumSystemScript.new()
	var score_samples := 0
	var max_multiplier := 1.0
	var abnormal_chain := false
	for second in range(600):
		state.elapsed_seconds = float(second)
		var events := _events_for_second(second, seed)
		system.process(state, 1.0, events)
		max_multiplier = maxf(max_multiplier, float(state.v2_momentum_score_multiplier))
		state.add_score(160 if float(state.v2_momentum_timer) > 0.0 else 100)
		score_samples += 1
		if float(state.v2_momentum_timer) > 18.0:
			abnormal_chain = true
	state.elapsed_seconds = 600.0
	system.process(state, 20.0, [])
	var uptime := float(state.v2_momentum_active_time_total) / 600.0
	var weighted := float(state.v2_momentum_weighted_multiplier_sum) / maxf(0.001, float(state.v2_momentum_weighted_time))
	var score_ratio := float(state.v2_momentum_score_bonus) / maxf(1.0, float(state.score))
	return {
		"seed": seed,
		"character": "noah",
		"simulated_seconds": score_samples,
		"trigger_count": int(state.v2_momentum_triggers),
		"trigger_counts": state.v2_momentum_trigger_counts.duplicate(true),
		"uptime_ratio": uptime,
		"uptime_percent": uptime * 100.0,
		"max_tier": int(state.v2_peak_momentum_tier),
		"weighted_multiplier": weighted,
		"max_multiplier": max_multiplier,
		"score": int(state.score),
		"momentum_score_bonus": int(state.v2_momentum_score_bonus),
		"momentum_score_ratio": score_ratio,
		"suppressed_duplicates": int(state.v2_momentum_suppressed_duplicates),
		"permanent_maintain": float(state.v2_momentum_timer) > 0.0,
		"abnormal_chain": abnormal_chain,
		"main_trigger": system.most_common_trigger(state)
	}

func _events_for_second(second: int, seed: int) -> Array:
	var events: Array = []
	if second > 0 and second % 52 == 0:
		for i in range(50):
			events.append({"type": "enemy_die", "enemy": "slime", "kill_id": "%d-%d-%d" % [seed, second, i]})
	if second in [150, 330, 510]:
		events.append({"type": "global_gem_collection", "source": "magnet", "count": 75, "exp": 180})
		events.append({"type": "global_gem_collection", "source": "magnet", "count": 75, "exp": 180})
	if second in [300]:
		events.append({"type": "enemy_die", "enemy": "boss_5", "kills": second})
		events.append({"type": "enemy_die", "enemy": "boss_5", "kills": second})
	if second in [420]:
		events.append({"type": "evolution", "weapon": "magic_bolt", "evolution": "starbreaker_bolt"})
		events.append({"type": "evolution", "weapon": "magic_bolt", "evolution": "starbreaker_bolt"})
	if second in [240, 480]:
		events.append({"type": "build_synergy", "id": "gem_engine"})
	return events

func _within_targets(summary: Dictionary) -> bool:
	var uptime := float(summary.get("uptime_percent", 0.0))
	var weighted := float(summary.get("weighted_multiplier", 0.0))
	var max_multiplier := float(summary.get("max_multiplier", 0.0))
	var score_ratio := float(summary.get("momentum_score_ratio", 0.0)) * 100.0
	return (
		uptime >= 8.0 and uptime <= 35.0
		and weighted >= 1.02 and weighted <= 1.10
		and max_multiplier <= 1.20
		and score_ratio >= 3.0 and score_ratio <= 12.0
		and not bool(summary.get("permanent_maintain", false))
		and not bool(summary.get("abnormal_chain", false))
		and int(summary.get("suppressed_duplicates", 0)) > 0
	)

func _write_reports(summaries: Array) -> void:
	var summary_path := "res://test-output/v2_momentum_balance_summary.json"
	var report_path := "res://test-output/v2_momentum_balance_report.md"
	var absolute := ProjectSettings.globalize_path(summary_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(summary_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"runs": summaries}, "\t"))
	var lines := [
		"# V2 Momentum 10 Minute Balance Report",
		"",
		"Simulated 600 seconds for 3 deterministic seeds. Targets: uptime 8-35%, weighted multiplier 1.02-1.10, max multiplier <=1.20, Momentum score contribution 3-12%.",
		""
	]
	for summary in summaries:
		lines.append("## Seed %d" % int(summary.get("seed", 0)))
		lines.append("- Character: %s" % String(summary.get("character", "")))
		lines.append("- Trigger count: %d" % int(summary.get("trigger_count", 0)))
		lines.append("- Trigger counts: %s" % JSON.stringify(summary.get("trigger_counts", {})))
		lines.append("- Uptime: %.2f%%" % float(summary.get("uptime_percent", 0.0)))
		lines.append("- Weighted multiplier: %.4f" % float(summary.get("weighted_multiplier", 0.0)))
		lines.append("- Max multiplier: %.2f" % float(summary.get("max_multiplier", 0.0)))
		lines.append("- Momentum score: +%d / %.2f%%" % [int(summary.get("momentum_score_bonus", 0)), float(summary.get("momentum_score_ratio", 0.0)) * 100.0])
		lines.append("- Suppressed duplicates: %d" % int(summary.get("suppressed_duplicates", 0)))
		lines.append("- Permanent maintain: %s" % str(bool(summary.get("permanent_maintain", false))))
		lines.append("- Abnormal chain: %s" % str(bool(summary.get("abnormal_chain", false))))
		lines.append("")
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	report.store_string("\n".join(lines))
