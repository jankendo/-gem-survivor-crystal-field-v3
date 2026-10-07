extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EvolutionSystemScript = preload("res://scripts/systems/EvolutionSystem.gd")
const OverclockSystemScript = preload("res://scripts/systems/OverclockSystem.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

func run(t) -> void:
	test_first_evolution_is_time_gated(t)
	test_evolutions_cannot_chain_immediately(t)
	test_overclock_waits_after_evolution(t)
	test_evolution_improves_its_weapon_without_buffing_every_category(t)
	test_overclock_has_limit_and_tradeoff(t)

func _ready_state():
	var state = SurvivorStateScript.new()
	state.start_new_run(4204)
	state.weapons["magic_bolt"] = 8
	state.passives["might"] = 3
	return state

func test_first_evolution_is_time_gated(t) -> void:
	var state = _ready_state()
	state.elapsed_seconds = 299.0
	t.assert_true(not state.has_available_evolution(), "first evolution must not be available before five minutes")
	state.elapsed_seconds = 300.0
	t.assert_true(state.has_available_evolution(), "first evolution should unlock at five minutes when build conditions are met")

func test_evolutions_cannot_chain_immediately(t) -> void:
	var state = _ready_state()
	state.elapsed_seconds = 300.0
	var events: Array = []
	t.assert_true(EvolutionSystemScript.new().apply_first_available_evolution(state, events), "first eligible evolution should apply")
	var second = _prepare_second_evolution(state)
	t.assert_true(second != "", "test fixture should find a second evolution")
	state.elapsed_seconds = 479.0
	t.assert_true(not state.has_available_evolution(), "a second evolution must wait for the three-minute cooldown")
	state.elapsed_seconds = 480.0
	t.assert_true(state.has_available_evolution(), "a second evolution should unlock after the cooldown")

func test_overclock_waits_after_evolution(t) -> void:
	var state = _ready_state()
	state.elapsed_seconds = 300.0
	EvolutionSystemScript.new().apply_first_available_evolution(state, [])
	state.elapsed_seconds = 419.0
	t.assert_true(OverclockSystemScript.new().available_overclocks(state).is_empty(), "overclock should wait two minutes after evolution")
	state.elapsed_seconds = 420.0
	t.assert_true(not OverclockSystemScript.new().available_overclocks(state).is_empty(), "overclock should become available after the delay")

func test_evolution_improves_its_weapon_without_buffing_every_category(t) -> void:
	var normal = _ready_state()
	var evolved = _ready_state()
	normal.elapsed_seconds = 300.0
	evolved.elapsed_seconds = 300.0
	normal.enemies = [EnemyScript.new("elite", normal.enemy_defs["elite"], normal.player_position + Vector2(120, 0))]
	evolved.enemies = [EnemyScript.new("elite", evolved.enemy_defs["elite"], evolved.player_position + Vector2(120, 0))]
	EvolutionSystemScript.new().apply_first_available_evolution(evolved, [])
	WeaponSystemScript.new().process(normal, 1.0, [])
	WeaponSystemScript.new().process(evolved, 1.0, [])
	t.assert_true(evolved.projectiles.size() > normal.projectiles.size(), "magic bolt evolution should improve its attack output")
	t.assert_eq(evolved.category_damage_multiplier("soul_scythe"), normal.category_damage_multiplier("soul_scythe"), "one evolution must not globally buff unrelated categories")

func test_overclock_has_limit_and_tradeoff(t) -> void:
	var state = _ready_state()
	t.assert_eq(int(state.balance_data.get("overclock_max_per_weapon", 0)), 2, "overclock should have a per-weapon cap")
	var descriptions: Array = []
	for entry in state.overclock_defs.get("starbreaker_bolt", []):
		descriptions.append(String(entry.get("description_ja", "")))
	var joined = " ".join(descriptions)
	t.assert_true(joined.find("-") >= 0 or joined.find("自傷") >= 0 or joined.find("低下") >= 0, "at least one major overclock should disclose a tradeoff")

func _prepare_second_evolution(state) -> String:
	for evolution_id in state.evolution_defs.keys():
		var data: Dictionary = state.evolution_defs[evolution_id]
		var weapon_id = String(data.get("weapon", ""))
		if weapon_id == "magic_bolt":
			continue
		state.weapons[weapon_id] = int(data.get("weapon_level", 8))
		state.passives[String(data.get("passive", ""))] = int(data.get("passive_level", 1))
		return weapon_id
	return ""
