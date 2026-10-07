extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")

func run(t) -> void:
	var hashes: Dictionary = {}
	for profile in ["desktop_standard", "ios_standard", "ios_low"]:
		var state = StateScript.new()
		state.start_new_run(7717)
		var settings := {"render_quality": profile.trim_prefix("desktop_").trim_prefix("ios_")}
		var platform := "iOS" if profile.begins_with("ios_") else "Windows"
		ProfileScript.new().apply_to_state(state, settings, platform)
		hashes[profile] = _simulation_hash(state)
	t.assert_eq(hashes.ios_standard, hashes.desktop_standard, "iOS standard must preserve initial simulation state")
	t.assert_eq(hashes.ios_low, hashes.desktop_standard, "iOS low must preserve initial simulation state")

func _simulation_hash(state) -> int:
	return [
		state.map_signature(),
		state.rng.snapshot(),
		state.max_enemies(),
		state.max_projectiles(),
		state.max_enemy_projectiles(),
		state.max_gems(),
		state.weapons,
		state.score,
		state.exp,
		state.kills,
	].hash()
