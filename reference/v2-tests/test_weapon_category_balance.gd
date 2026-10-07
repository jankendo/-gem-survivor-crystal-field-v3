extends RefCounted

const WeaponBalanceSystemScript = preload("res://scripts/systems/WeaponBalanceSystem.gd")

func run(t) -> void:
	test_category_numbers_match_design(t)
	test_state_category_multipliers(t)

func _weapons():
	return JSON.parse_string(FileAccess.open("res://data/weapons.json", FileAccess.READ).get_as_text())

func test_category_numbers_match_design(t) -> void:
	var weapons = _weapons()
	var balance = WeaponBalanceSystemScript.new()
	t.assert_true(balance.is_ranged_long_low_damage(weapons["magic_bolt"]), "ranged should be long range and lower damage")
	t.assert_true(balance.is_melee_short_high_damage(weapons["soul_scythe"]), "melee should be short range and high damage")
	t.assert_true(balance.is_explosion_slow_wide(weapons["bomb_seed"]), "explosion should be slow and strong")
	t.assert_true(bool(weapons["thunder_chain"].get("shock_enabled", false)), "lightning should support shock stacks")
	t.assert_true(bool(weapons["poison_mist"].get("dot_enabled", false)), "poison should support dot identity")

func test_state_category_multipliers(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(2026, "balance")
	t.assert_true(state.category_damage_multiplier("soul_scythe") > state.category_damage_multiplier("magic_bolt"), "melee damage multiplier should exceed ranged")
	t.assert_true(state.category_cooldown_multiplier("bomb_seed") > state.category_cooldown_multiplier("magic_bolt"), "explosion cooldown should be longer than ranged")
	t.assert_true(state.category_damage_multiplier("poison_mist") < 1.0, "poison immediate damage should be lower")

