extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func _initialize() -> void:
	var desktop := _simulate("Windows", "standard")
	var ios := _simulate("iOS", "low")
	var summary := {
		"desktop": desktop,
		"ios": ios,
		"enemy_spawn_match": int(desktop.enemy_spawn) == int(ios.enemy_spawn),
		"boss_spawn_match": int(desktop.boss_spawn) == int(ios.boss_spawn),
		"alive_match": int(desktop.alive) == int(ios.alive),
		"kill_match": int(desktop.kills) == int(ios.kills),
		"reward_match": int(desktop.gems) == int(ios.gems) and int(desktop.chests) == int(ios.chests)
	}
	_write_report(summary)
	var ok := bool(summary.enemy_spawn_match) and bool(summary.boss_spawn_match) and bool(summary.alive_match) and bool(summary.kill_match) and bool(summary.reward_match)
	quit(0 if ok else 1)

func _simulate(platform: String, quality: String) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(50505)
	ProfileScript.new().apply_to_state(state, {"render_quality": quality}, platform)
	var spawner = SpawnerScript.new()
	var events: Array = []
	for frame in range(600):
		spawner.process(state, 0.2, events)
		state.elapsed_seconds += 0.2
	var enemy_spawn := 0
	var boss_spawn := 0
	for event in events:
		if String(event.get("type", "")) == "enemy_spawn":
			enemy_spawn += 1
		elif String(event.get("type", "")) == "boss_spawn":
			boss_spawn += 1
	return {
		"enemy_spawn": enemy_spawn,
		"boss_spawn": boss_spawn,
		"alive": state.enemies.size(),
		"kills": state.kills,
		"gems": state.gems.size(),
		"chests": state.chests.size()
	}

func _write_report(summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output/phase5"))
	var json := FileAccess.open("res://test-output/phase5/enemy_parity.json", FileAccess.WRITE)
	json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/phase5/enemy_parity.md", FileAccess.WRITE)
	md.store_line("# Phase 5 Enemy Parity")
	for key in ["enemy_spawn_match", "boss_spawn_match", "alive_match", "kill_match", "reward_match"]:
		md.store_line("- %s: %s" % [key, str(summary[key])])
