extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const GemLifecycleScript = preload("res://scripts/systems/GemLifecycleSystem.gd")
const GemVisualScript = preload("res://scripts/systems/GemCollectionVisualBatchSystem.gd")
const GlobalCollectionScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const EnemySnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const EnemyBatchScript = preload("res://scripts/systems/EnemyVisualBatchSystem.gd")
const EnemyPrewarmScript = preload("res://scripts/systems/EnemySpawnVisualPrewarmSystem.gd")
const WarpScript = preload("res://scripts/systems/WarpRoomSystem.gd")
const SaveScript = preload("res://scripts/systems/SaveSystem.gd")
const TouchControlScript = preload("res://scripts/systems/TouchControlSystem.gd")

func state(seed: int = 101010):
	var value = StateScript.new()
	value.start_new_run(seed, "phase10-%d" % seed)
	return value

func gem_persistence(t) -> void:
	var s = state()
	s.gem_lifecycle_qa_enabled = true
	var lifecycle = GemLifecycleScript.new()
	for index in range(1200):
		lifecycle.spawn(s, Vector2(2000 + index * 2, 1800 + index), 1 + index % 9)
	var count: int = s.gems.size()
	var total := lifecycle.total_exp(s.gems)
	s.camera_position = Vector2.ZERO
	s.configure_render_profile("ios_extreme_lite", false)
	s.trim_runtime_arrays()
	t.assert_eq(s.gems.size(), count, "1,200 gems remain after visual profile and trim")
	t.assert_eq(lifecycle.total_exp(s.gems), total, "gem EXP total remains exact")
	t.assert_eq(int(lifecycle.snapshot(s).get("removed", -1)), 0, "no unexplained removal is recorded")

func gem_lifecycle_reasons(t) -> void:
	var s = state()
	s.gem_lifecycle_qa_enabled = true
	var lifecycle = GemLifecycleScript.new()
	var gem = lifecycle.spawn(s, s.player_position, 7)
	t.assert_true(lifecycle.remove(s, gem, GemLifecycleScript.RemovalReason.COLLECTED), "explicit collection removes gem")
	var report := lifecycle.snapshot(s)
	t.assert_eq(int(report.get("spawned", 0)), 1, "spawn is counted")
	t.assert_eq(int(report.get("collected", 0)), 1, "collection is counted")
	t.assert_eq(int(report.get("removal_reasons", {}).get("collected", 0)), 1, "removal reason is retained")

func gem_visual_separation(t) -> void:
	var s = state()
	var lifecycle = GemLifecycleScript.new()
	for index in range(1200):
		lifecycle.spawn(s, Vector2(index, index * 2), 2)
	var before_ids: Array = s.gems.map(func(gem): return gem.get_instance_id())
	var batch := GemVisualScript.new().make_batch("test", s.gems.map(func(gem): return gem.position), 1200, 2400, s.player_position, 4)
	t.assert_eq(int(batch.get("representative_count", -1)), 4, "visual batch uses four representatives")
	t.assert_eq(s.gems.map(func(gem): return gem.get_instance_id()), before_ids, "visual batch does not mutate simulation gems")

func global_collection_exact(t) -> void:
	var s = state()
	var lifecycle = GemLifecycleScript.new()
	for index in range(1200):
		lifecycle.spawn(s, s.player_position + Vector2(index % 30, index / 30), 1 + index % 4)
	var expected := 0
	for index in range(s.gems.size()):
		s.pickup_combo_count = index + 1
		var gem = s.gems[index]
		expected += maxi(1, int(round(float(gem.value) * s.get_gem_value_multiplier(gem.position) * s.get_combo_exp_multiplier())))
	s.pickup_combo_count = 0
	var result := GlobalCollectionScript.new().collect_all(s, [], "magnet", 1.0)
	t.assert_eq(int(result.get("count", 0)), 1200, "all gems are logically collected")
	t.assert_eq(int(result.get("exp", 0)), expected, "all collection EXP is exact")
	t.assert_true(s.gems.is_empty(), "only collection empties active gems")

func scan_removed(t) -> void:
	var game_source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	var state_source := FileAccess.get_file_as_string("res://scripts/core/SurvivorState.gd")
	t.assert_true(not FileAccess.file_exists("res://scripts/systems/CrystalSurveySystem.gd"), "survey runtime script is removed")
	for token in ["action_scan", "survey_resonance", "scan_hold", "scan_telemetry"]:
		t.assert_true(game_source.find(token) < 0 and state_source.find(token) < 0, "%s is absent from runtime" % token)
	t.assert_true(not TouchControlScript.ACTIONS.has("action_scan"), "touch action list has no removed action")

func scan_save_migration(t) -> void:
	var old := {
		"best_score": 44,
		"survey_resonance": 3,
		"scan_progress": {"a": true},
		"scan_telemetry": {"count": 8},
		"settings": {"scan_enabled": true, "scan_tutorial_seen": true}
	}
	var migrated: Dictionary = SaveScript.new()._with_defaults(old)
	t.assert_eq(int(migrated.get("best_score", 0)), 44, "unrelated save progress remains")
	for key in ["survey_resonance", "scan_progress", "scan_telemetry"]:
		t.assert_true(not migrated.has(key), "legacy field %s is ignored and cleaned" % key)
	t.assert_true(not migrated.get("settings", {}).has("scan_enabled"), "legacy setting is cleaned")

func enemy_all_tier_ultralite(t) -> void:
	var enemies := _enemy_fixture()
	var snapshot = EnemySnapshotScript.new()
	snapshot.reserve(700)
	var before := _enemy_signature(enemies)
	var first := snapshot.build_snapshot(enemies, Vector2(600, 400), Vector2(1600, 1000), 12.0, {"minimal": true})
	var resize_count := int(first.get("resize_count", -1))
	var second := snapshot.build_snapshot(enemies, Vector2(600, 400), Vector2(1600, 1000), 12.1, {"minimal": true})
	t.assert_eq(_enemy_signature(enemies), before, "render snapshot never mutates enemy simulation")
	t.assert_eq(int(second.get("resize_count", -2)), resize_count, "snapshot capacity is reused")
	t.assert_true(not second.has("commands"), "snapshot does not allocate per-enemy command dictionaries")
	var batch := EnemyBatchScript.new().batch_commands(second)
	t.assert_true(int(batch.get("critical_count", 0)) >= 4, "elite, boss and special critical enemies remain visible")

func enemy_spawn_prewarm(t) -> void:
	var s = state()
	var snapshot = EnemySnapshotScript.new()
	var report := EnemyPrewarmScript.new().prewarm(s, snapshot)
	t.assert_true(int(report.get("enemy_types", 0)) >= s.enemy_defs.size(), "all enemy archetypes are resolved")
	t.assert_true(int(report.get("pool_size", 0)) > 0, "enemy pool is prewarmed")
	t.assert_true(int(report.get("snapshot_capacity", 0)) >= s.max_enemies(), "snapshot storage is reserved")

func warp_determinism(t) -> void:
	var a = _warp_state(4040)
	var b = _warp_state(4040)
	var wa = WarpScript.new()
	var wb = WarpScript.new()
	wa.initialize_run(a)
	wb.initialize_run(b)
	t.assert_eq(a.warp_portals, b.warp_portals, "same seed and room identity produce identical portal content")
	var kinds: Dictionary = {}
	var sample = _warp_state(100)
	for seed in range(100, 140):
		sample.rng.set_seed_value(seed)
		var system = WarpScript.new()
		system.initialize_run(sample)
		kinds[String(sample.warp_portals[0].get("kind", ""))] = true
	t.assert_true(kinds.has("heaven") and kinds.has("hell"), "seed range produces both room kinds")

func warp_placement_100_seed(t) -> void:
	var s = _warp_state(1000)
	for seed in range(1000, 1100):
		s.rng.set_seed_value(seed)
		var system = WarpScript.new()
		system.initialize_run(s)
		t.assert_eq(s.warp_portals.size(), 1, "one cave room receives one portal for seed %d" % seed)
		var portal: Dictionary = s.warp_portals[0]
		t.assert_true(s.is_walkable_position(portal.get("position", Vector2.INF), 22.0), "portal is on safe floor for seed %d" % seed)

func warp_flow(t, requested_kind: String) -> void:
	var pair := _warp_with_kind(requested_kind)
	var s = pair[0]
	var system = pair[1]
	var main_gems: Array = []
	var lifecycle = GemLifecycleScript.new()
	for index in range(24):
		lifecycle.spawn(s, Vector2(300 + index, 400), index + 1)
	main_gems = s.gems
	var main_enemies: Array = s.enemies
	var main_map: Dictionary = s.map_data
	var main_elapsed: float = float(s.elapsed_seconds)
	s.player_position = s.warp_portals[0].get("position", Vector2.ZERO)
	t.assert_true(system.process_entry(s, []), "portal entry succeeds")
	t.assert_eq(s.warp_room_kind, requested_kind, "requested deterministic room kind entered")
	t.assert_true(not is_same(s.map_data, main_map) and not is_same(s.enemies, main_enemies), "isolated room owns separate arrays")
	t.assert_true(not s.warp_room_exit_ready, "exit is unavailable before clear")
	_clear_all_waves(s, system)
	t.assert_true(s.warp_room_exit_ready, "exit appears after all waves and enemies clear")
	var score_after: int = int(s.score)
	system.process_challenge(s, 0.0, [])
	t.assert_eq(s.score, score_after, "reward cannot be committed twice")
	s.player_position = s.warp_room_exit_position
	system.process_challenge(s, 0.0, [])
	t.assert_true(not s.warp_room_active, "exit returns to main field")
	t.assert_true(is_same(s.map_data, main_map) and is_same(s.enemies, main_enemies), "main map and enemy arrays are restored")
	t.assert_true(is_same(s.gems, main_gems), "main field gems survive round trip")
	t.assert_eq(s.elapsed_seconds, main_elapsed, "main survival clock does not advance in fixture")
	t.assert_true(s.invincible_timer >= 1.0, "return grants contact protection")

func ios_layout_without_scan(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	t.assert_true(source.find("touch_scan_button") < 0, "iOS HUD has no removed button")
	t.assert_true(source.find("action_scan") < 0, "iOS HUD has no removed touch action")
	t.assert_true(source.find("touch_drone_button") >= 0 and source.find("touch_speed_button") >= 0, "remaining actions are preserved")

func _warp_state(seed: int):
	var s = state(seed)
	var source: Dictionary = s.map_data.get("rooms", [])[0]
	var cave := source.duplicate(true)
	cave["id"] = "cave_phase10"
	cave["shape"] = "cave_room"
	s.map_data["rooms"] = [cave]
	return s

func _warp_with_kind(kind: String) -> Array:
	var s = _warp_state(1)
	for seed in range(1, 500):
		s.rng.set_seed_value(seed)
		var system = WarpScript.new()
		system.initialize_run(s)
		if String(s.warp_portals[0].get("kind", "")) == kind:
			return [s, system]
	return []

func _clear_all_waves(s, system) -> void:
	for guard in range(16):
		system.process_challenge(s, 0.1, [])
		for enemy in s.enemies:
			s.release_runtime("enemy", enemy)
		s.enemies.clear()
		if s.warp_room_exit_ready:
			return

func _enemy_fixture() -> Array:
	var result: Array = []
	for index in range(600):
		var type_id := "slime"
		var data := {"hp": 20, "radius": 18.0}
		if index % 100 == 0:
			type_id = "elite"
			data = {"hp": 100, "radius": 28.0, "elite": true}
		result.append(EnemyScript.new(type_id, data, Vector2(80 + index % 30 * 32, 80 + index / 30 * 32)))
	result.append(EnemyScript.new("boss_a", {"hp": 800, "radius": 52.0, "boss": true, "elite": true}, Vector2(600, 400)))
	return result

func _enemy_signature(enemies: Array) -> int:
	var rows: Array = []
	for enemy in enemies:
		rows.append([enemy.type, enemy.position, enemy.hp, enemy.zone_id])
	return rows.hash()
