extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")
const PickupSystemScript = preload("res://scripts/systems/PickupSystem.gd")

func run(t) -> void:
	test_enemy_drop_creates_gem(t)
	test_gem_is_attracted(t)
	test_collect_adds_exp(t)
	test_level_up_occurs(t)

func _state() :
	var state = SurvivorStateScript.new()
	state.start_new_run(33)
	return state

func test_enemy_drop_creates_gem(t) -> void:
	var state = _state()
	var enemy = EnemyScript.new("slime", state.enemy_defs.get("slime", {}), state.player_position + Vector2(40, 0))
	ExpSystemScript.new().drop_for_enemy(state, enemy, [])
	t.assert_eq(state.gems.size(), 1, "enemy defeat should create gem")

func test_gem_is_attracted(t) -> void:
	var state = _state()
	var gem = ExpGemScript.new(state.player_position + Vector2(70, 0), 5)
	state.gems.append(gem)
	PickupSystemScript.new().process_gems(state, 0.1, [])
	t.assert_true(gem.attracting, "gem inside magnet range should attract")

func test_collect_adds_exp(t) -> void:
	var state = _state()
	state.gems.append(ExpGemScript.new(state.player_position, 5))
	var expected = int(round(5.0 * state.get_gem_value_multiplier(state.player_position) * state.get_combo_exp_multiplier()))
	PickupSystemScript.new().process_gems(state, 0.1, [])
	t.assert_eq(state.exp, expected, "collecting gem should add scaled exp")
	t.assert_eq(state.gems_collected, 1, "collecting gem should count")

func test_level_up_occurs(t) -> void:
	var state = _state()
	ExpSystemScript.new().add_exp(state, state.exp_to_next, [])
	t.assert_true(state.level_up_pending, "full exp should open level up")
	t.assert_eq(state.level, 2, "level should increase")
