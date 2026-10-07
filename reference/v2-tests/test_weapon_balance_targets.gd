extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const WeaponBalanceSystemScript = preload("res://scripts/systems/WeaponBalanceSystem.gd")

func run(t) -> void:
	test_category_identity(t)
	test_weak_categories_received_targeted_support(t)
	test_weapon_metadata_matches_runtime_targets(t)

func _state():
	var state = SurvivorStateScript.new()
	state.start_new_run(4202)
	return state

func test_category_identity(t) -> void:
	var state = _state()
	t.assert_true(float(state.weapon_defs["magic_bolt"].get("range", 0.0)) > float(state.weapon_defs["soul_scythe"].get("range", 0.0)), "ranged weapons should reach farther than melee weapons")
	t.assert_true(state.category_damage_multiplier("soul_scythe") > state.category_damage_multiplier("magic_bolt"), "melee should retain higher immediate damage than ranged")
	t.assert_true(state.category_area_multiplier("poison_mist") > 1.0, "poison should retain wide area identity")
	t.assert_true(state.category_cooldown_multiplier("bomb_seed") > 1.0, "explosion should retain a slower attack cycle")
	t.assert_eq(bool(state.weapon_defs["poison_mist"].get("dot_enabled", false)), true, "poison weapons should expose damage-over-time behavior")
	t.assert_eq(bool(state.weapon_defs["thunder_chain"].get("shock_enabled", false)), true, "lightning weapons should expose shock behavior")
	t.assert_true(_average_cooldown(state, "explosion") > _average_cooldown(state, "ranged"), "explosion weapons should have a longer average cooldown than ranged weapons")

func test_weak_categories_received_targeted_support(t) -> void:
	var state = _state()
	t.assert_true(state.category_damage_multiplier("poison_mist") >= 0.84, "poison immediate damage should meet the rebalance floor")
	t.assert_true(state.category_damage_multiplier("sonic_wave") >= 0.84, "knockback damage should meet the rebalance floor")
	t.assert_true(state.category_area_multiplier("rune_gate") >= 1.12, "deploy weapons should receive a meaningful area bonus")
	t.assert_true(state.category_cooldown_multiplier("rune_gate") <= 0.92, "deploy weapons should deploy more consistently")

func test_weapon_metadata_matches_runtime_targets(t) -> void:
	var state = _state()
	var balance = WeaponBalanceSystemScript.new()
	t.assert_true(balance.damage_multiplier_for_category("deploy") == state.category_damage_multiplier("rune_gate"), "shared category balance helper should match runtime values")
	t.assert_eq(float(state.weapon_defs["rune_gate"].get("base_cooldown_score", 0.0)), 2.45, "rune gate metadata should reflect its faster cycle")
	t.assert_eq(float(state.weapon_defs["sonic_wave"].get("base_cooldown_score", 0.0)), 1.7, "sonic wave metadata should reflect its faster cycle")
	t.assert_true(float(state.weapon_defs["guardian_wall"].get("base_damage_score", 9.0)) < 1.0, "defense weapons should keep restrained direct damage")
	t.assert_true(float(state.weapon_defs["gem_turret"].get("base_damage_score", 9.0)) < 0.9, "gem weapons should keep weak early damage")

func _average_cooldown(state, category: String) -> float:
	var values: Array = []
	for data in state.weapon_defs.values():
		if String(data.get("category", "")) == category:
			values.append(float(data.get("base_cooldown_score", data.get("cooldown", 0.0))))
	var total = 0.0
	for value in values:
		total += float(value)
	return total / float(maxi(1, values.size()))
