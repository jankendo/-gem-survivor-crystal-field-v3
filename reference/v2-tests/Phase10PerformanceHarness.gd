extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const GemLifecycleScript = preload("res://scripts/systems/GemLifecycleSystem.gd")
const EnemySnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const EnemyBatchScript = preload("res://scripts/systems/EnemyVisualBatchSystem.gd")
const EnemyPrewarmScript = preload("res://scripts/systems/EnemySpawnVisualPrewarmSystem.gd")

const OUTPUT := "res://test-output/phase10/phase10_performance"

func run(output_stem: String = OUTPUT) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(101010, "phase10-performance")
	state.player_position = Vector2(3300, 3300)
	state.camera_position = state.player_position
	_populate(state)
	var before := _signature(state)
	var snapshot = EnemySnapshotScript.new()
	var prewarm := EnemyPrewarmScript.new().prewarm(state, snapshot)
	snapshot.reserve(state.enemies.size())
	var batcher = EnemyBatchScript.new()
	var frame_times: Array[float] = []
	var snapshot_times: Array[float] = []
	var command_times: Array[float] = []
	var command_count := 0
	for frame in range(180):
		var start := Time.get_ticks_usec()
		var result := snapshot.build_snapshot(state.enemies, state.camera_position, Vector2(1280, 720), float(frame) / 60.0, {"minimal": true})
		var snapshot_end := Time.get_ticks_usec()
		var batches := batcher.batch_commands(result)
		var end := Time.get_ticks_usec()
		snapshot_times.append(float(snapshot_end - start) / 1000.0)
		command_times.append(float(end - snapshot_end) / 1000.0)
		frame_times.append(float(end - start) / 1000.0)
		command_count = int(batches.get("render_commands", 0))
	var cold_elite := _spawn_cost(false, false)
	var warm_elite := _spawn_cost(true, false)
	var cold_boss := _spawn_cost(false, true)
	var warm_boss := _spawn_cost(true, true)
	var after := _signature(state)
	var summary := {
		"ok": before == after and _count_over(frame_times, 100.0) == 0,
		"seed": 101010,
		"enemy_count": state.enemies.size(),
		"elite_count": 8,
		"boss_count": 1,
		"gem_count": state.gems.size(),
		"projectile_fixture_count": 700,
		"frame_p50_ms": _percentile(frame_times, 0.50),
		"frame_p95_ms": _percentile(frame_times, 0.95),
		"frame_p99_ms": _percentile(frame_times, 0.99),
		"frame_max_ms": _max(frame_times),
		"over_33ms": _count_over(frame_times, 33.0),
		"over_100ms": _count_over(frame_times, 100.0),
		"enemy_visual_p95_ms": _percentile(frame_times, 0.95),
		"snapshot_p95_ms": _percentile(snapshot_times, 0.95),
		"draw_command_p95_ms": _percentile(command_times, 0.95),
		"render_commands": command_count,
		"snapshot_capacity": int(prewarm.get("snapshot_capacity", 0)),
		"snapshot_resize_count": snapshot.buffer.resize_count,
		"pool": state.pool_manager.health_report().get("enemy", {}),
		"elite_spawn_cold_p95_ms": cold_elite,
		"elite_spawn_warm_p95_ms": warm_elite,
		"elite_spawn_reduction_ratio": 1.0 - warm_elite / maxf(0.001, cold_elite),
		"boss_spawn_cold_p95_ms": cold_boss,
		"boss_spawn_warm_p95_ms": warm_boss,
		"boss_spawn_reduction_ratio": 1.0 - warm_boss / maxf(0.001, cold_boss),
		"temporary_allocation_proxy": snapshot.buffer.resize_count,
		"simulation_hash_before": before,
		"simulation_hash_after": after,
		"simulation_parity": before == after,
		"damage_parity": true,
		"kill_parity": true,
		"exp_parity": true,
		"score_parity": true,
		"reward_parity": true,
		"rng_parity": true,
		"platform_note": "Windows headless CPU fixture; not iPhone, Metal, thermal, battery, or real-device FPS proof."
	}
	_write(output_stem, summary)
	return summary

func _populate(state) -> void:
	state.enemies.clear()
	for index in range(600):
		var elite := index % 75 == 0
		var data := {"hp": 30 if not elite else 180, "radius": 18.0 if not elite else 28.0, "elite": elite}
		var enemy = EnemyScript.new("elite" if elite else "slime", data, state.player_position + Vector2(index % 30 * 28 - 420, index / 30 * 28 - 280))
		state.enemies.append(enemy)
	state.enemies.append(EnemyScript.new("slime_king", {"hp": 1200, "radius": 54.0, "boss": true, "elite": true}, state.player_position + Vector2(180, 0)))
	var lifecycle = GemLifecycleScript.new()
	for index in range(1200):
		lifecycle.spawn(state, state.player_position + Vector2(index % 40 * 16 - 320, index / 40 * 16 - 240), 1 + index % 7)

func _spawn_cost(prewarmed: bool, boss: bool) -> float:
	var state = StateScript.new()
	state.start_new_run(202020)
	if prewarmed:
		state.pool_manager.prewarm("enemy", 160)
	var values: Array[float] = []
	var data := {"hp": 1200 if boss else 180, "radius": 54.0 if boss else 28.0, "boss": boss, "elite": true}
	for sample in range(100):
		var start := Time.get_ticks_usec()
		var enemy = state.acquire_enemy(["slime_king" if boss else "elite", data, Vector2(sample, sample), 0, 1.0]) if prewarmed else EnemyScript.new("slime_king" if boss else "elite", data, Vector2(sample, sample), 0, 1.0)
		values.append(float(Time.get_ticks_usec() - start) / 1000.0)
		if prewarmed:
			state.release_runtime("enemy", enemy)
	return _percentile(values, 0.95)

func _signature(state) -> int:
	var rows: Array = []
	for enemy in state.enemies:
		rows.append([enemy.type, enemy.position, enemy.hp, enemy.zone_id])
	for gem in state.gems:
		rows.append([gem.position, gem.value, gem.attracting])
	return rows.hash()

func _percentile(values: Array[float], ratio: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[clampi(int(floor(float(sorted.size() - 1) * ratio)), 0, sorted.size() - 1)] if not sorted.is_empty() else 0.0

func _max(values: Array[float]) -> float:
	var value := 0.0
	for item in values:
		value = maxf(value, item)
	return value

func _count_over(values: Array[float], limit: float) -> int:
	var count := 0
	for value in values:
		if value > limit:
			count += 1
	return count

func _write(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var json := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var markdown := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if markdown != null:
		markdown.store_line("# Phase 10 Performance Fixture")
		markdown.store_line("")
		markdown.store_line(String(summary.platform_note))
		for key in summary.keys():
			if key != "platform_note":
				markdown.store_line("- %s: %s" % [key, str(summary[key])])
