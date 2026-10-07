extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	var desktop = _simulate("Windows", "standard")
	var ios = _simulate("iOS", "low")
	t.assert_eq(int(ios.enemy_spawn), int(desktop.enemy_spawn), "iOS profile should not reduce actual spawned enemies")
	t.assert_eq(int(ios.boss_spawn), int(desktop.boss_spawn), "iOS profile should not reduce boss spawns")
	t.assert_eq(int(ios.alive), int(desktop.alive), "iOS profile should keep live enemy count parity over same seed")
	t.assert_eq(int(ios.kills), int(desktop.kills), "iOS profile should not alter kill count in spawn-only simulation")

func _simulate(platform: String, quality: String) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(50503)
	ProfileScript.new().apply_to_state(state, {"render_quality": quality}, platform)
	var spawner = SpawnerScript.new()
	var events: Array = []
	for frame in range(300):
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
		"kills": state.kills
	}
