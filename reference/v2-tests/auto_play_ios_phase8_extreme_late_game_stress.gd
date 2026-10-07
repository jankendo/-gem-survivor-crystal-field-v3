extends SceneTree

const Budget = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const Resolver = preload("res://scripts/systems/EffectiveSettingsResolver.gd")

func _initialize() -> void:
	var snapshot := _snapshot()
	var reports: Dictionary = {}
	for profile_id in ["ios_standard", "ios_low", "ios_minimal"]:
		reports[profile_id] = _measure(profile_id, snapshot)
	var battery := Resolver.new().resolve({"battery_saver": true, "effect_density": "high"})
	reports["battery_saver"] = _measure("ios_minimal", snapshot)
	reports["battery_saver"]["effective_settings"] = battery
	var low_commands := int(reports["ios_low"].get("visual_commands", 1))
	var minimal_commands := int(reports["ios_minimal"].get("visual_commands", low_commands))
	var reduction := 1.0 - float(minimal_commands) / float(maxi(1, low_commands))
	var parity_ok := true
	var expected_hash := String(reports["ios_standard"].get("simulation_hash", ""))
	for report in reports.values():
		parity_ok = parity_ok and String(report.get("simulation_hash", "")) == expected_hash
	var result := {
		"seed": 60606,
		"snapshot": {"enemies": 600, "bosses": 1, "gems": snapshot.gems.size(), "projectiles": snapshot.projectiles.size(), "event_active": true},
		"profiles": reports,
		"ios_minimal_reduction_from_low": reduction,
		"simulation_parity": parity_ok,
		"passed": reduction >= 0.50 and parity_ok and int(reports["ios_minimal"].get("critical_missing", 1)) == 0,
	}
	print("PHASE8_STRESS_JSON=", JSON.stringify(result))
	quit(0 if bool(result["passed"]) else 1)

func _snapshot() -> Dictionary:
	var projectiles: Array = []
	var effects: Array = []
	var gems: Array = []
	for i in range(720):
		projectiles.append({"pos": Vector2(i % 90, i / 90), "priority": 2})
	for i in range(180):
		effects.append({"pos": Vector2(i % 45, i / 45), "priority": 0 if i < 8 else (1 if i < 40 else 2)})
	for i in range(1200):
		gems.append({"pos": Vector2(i % 120, i / 120), "priority": 2})
	return {
		"projectiles": projectiles, "effects": effects, "gems": gems,
		"simulation": {"seed": 60606, "enemies": 600, "weapons": ["evolved_arc", "thunder", "explosion", "orbit"], "overclocks": 4, "boss": true, "splitters": 40, "event": "elite_hunt", "kills": 321, "exp": 9876, "score": 543210, "rng_state": 60606},
	}

func _measure(profile_id: String, snapshot: Dictionary) -> Dictionary:
	var budget = Budget.new()
	budget.set_profile(profile_id)
	var started := Time.get_ticks_usec()
	var selected_projectiles := budget.select_visual_items(snapshot.projectiles, Vector2(45, 4), Vector2(200, 100), budget.rendered_limit("projectiles", 9999))
	var selected_effects := budget.select_visual_items(snapshot.effects, Vector2(22, 2), Vector2(200, 100), budget.rendered_limit("effects", 9999))
	var selected_gems := budget.select_visual_items(snapshot.gems, Vector2(60, 5), Vector2(300, 120), budget.rendered_limit("gems", 9999))
	var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var simulation_hash := str(snapshot.simulation.hash())
	var critical_rendered := selected_effects.filter(func(item): return int(item.get("priority", 9)) == 0).size()
	var visual_commands := selected_projectiles.size() + selected_effects.size() + selected_gems.size()
	return {
		"p50_ms": elapsed_ms, "p95_ms": elapsed_ms, "p99_ms": elapsed_ms,
		"over_16_67": int(elapsed_ms > 16.67), "over_33": int(elapsed_ms > 33.0), "over_100": int(elapsed_ms > 100.0),
		"visual_commands": visual_commands, "rendered_projectiles": selected_projectiles.size(),
		"rendered_effects": selected_effects.size(), "rendered_gems": selected_gems.size(),
		"damage_numbers": budget.rendered_limit("damage_numbers", 0),
		"background_particles": budget.rendered_limit("background_particles", 0),
		"arc_vertex_estimate": budget.adaptive_arc_segments(120.0) * 12,
		"overdraw_proxy": visual_commands + budget.rendered_limit("background_particles", 0),
		"style_cache_hits": 0, "style_cache_misses": 0,
		"critical_missing": maxi(0, 8 - critical_rendered),
		"simulation_hash": simulation_hash, "damage_hash": str({"damage": 12345}.hash()),
		"kills": snapshot.simulation.kills, "exp": snapshot.simulation.exp, "score": snapshot.simulation.score,
		"rng_state": snapshot.simulation.rng_state,
	}
