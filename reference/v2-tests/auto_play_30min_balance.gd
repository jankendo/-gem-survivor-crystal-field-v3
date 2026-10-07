extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")
const ExpSystemScript = preload("res://scripts/systems/ExpSystem.gd")
const IosPerformanceBudgetScript = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: 30min balance, scaling, bosses, auto infinite, caps.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	SaveSystem.new().save_help_seen(true)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.request_start()
	await process_frame
	var game: GameScreen = _find_game_screen(main)
	_assert(game != null, "GameScreen should start")
	if game == null:
		return
	game.state.start_new_run(830)
	game.state.max_hp = 999999
	game.state.hp = 999999
	game.state.balance_data["max_enemies"] = 260
	game.state.balance_data["max_gems"] = 520
	game.state.balance_data["max_projectiles"] = 300
	game.state.balance_data["max_enemy_projectiles"] = 180
	game.state.auto_infinite_enabled = true
	var test_weapons = ["magic_bolt", "soul_scythe", "thunder_chain", "poison_mist", "bomb_seed", "rune_gate"]
	var test_passives = ["might", "cooldown", "area", "regen", "armor", "projectile_count"]
	for id in test_weapons:
		game.state.weapons[id] = int(game.state.weapon_defs[id].get("max_level", 8))
	for id in test_passives:
		game.state.passives[id] = int(game.state.passive_defs[id].get("max_level", 5))
	for evolution_id in game.state.evolution_defs.keys():
		var weapon_id = String(game.state.evolution_defs[evolution_id].get("weapon", ""))
		if test_weapons.has(weapon_id):
			game.state.evolved_weapons[weapon_id] = String(evolution_id)
	game.state.evolved_weapon_count = game.state.evolved_weapons.keys().size()
	var player = PlayerScript.new()
	var exp_system = ExpSystemScript.new()
	var early_hp = 0.0
	var late_hp = 0.0
	var early_spawn = 0.0
	var late_spawn = 0.0
	var simulation_steps := 0
	while game.state.elapsed_seconds < 1800.0 and simulation_steps < 1860:
		var i := simulation_steps
		if not is_instance_valid(game):
			failures.append("GameScreen should stay alive during 30min balance simulation")
			return
		if early_hp <= 0.0 and game.state.elapsed_seconds >= 60.0:
			early_hp = game.state.enemy_hp_multiplier()
			early_spawn = game.state.enemy_spawn_multiplier()
		if late_hp <= 0.0 and game.state.elapsed_seconds >= 1740.0:
			late_hp = game.state.enemy_hp_multiplier()
			late_spawn = game.state.enemy_spawn_multiplier()
		game.state.hp = game.state.max_hp
		game.state.game_over = false
		player.process_movement(game.state, Vector2.RIGHT.rotated(float(i) * 0.03), 1.0)
		game._process(1.0)
		if i % 90 == 0:
			exp_system.add_exp(game.state, game.state.exp_to_next + 10, [])
		if game.state.level_up_pending:
			game._select_reward(0)
		if i % 30 == 0:
			await process_frame
		simulation_steps += 1
	_assert(game.state.elapsed_seconds >= 1800.0, "30min autoplay should reach 30 minutes")
	_assert(late_hp > early_hp, "enemy scaling should rise during 30min autoplay")
	_assert(late_hp >= early_hp * 8.0, "enemy HP scaling should be clearly stronger by 30min")
	_assert(late_spawn >= early_spawn * 3.0, "enemy spawn scaling should clearly rise by 30min")
	_assert(game.state.boss_spawned_minutes.has(30), "30min boss should spawn")
	_assert(game.state.boss_spawned_minutes.size() <= 6, "boss checkpoints should not exceed 5min pacing through 30min")
	_assert(_boss_count(game.state) <= 1, "boss simultaneous count should stay at one")
	_assert(game.state.chests.size() <= game.state.max_chests(), "chest cap should hold during 30min autoplay")
	_assert(game.state.chests_opened <= 24, "30min autoplay should not flood chest rewards, opened=%d" % game.state.chests_opened)
	_assert(game.state.auto_infinite_count > 0, "auto infinite should apply in exhausted build")
	var hard_enemy_budget := IosPerformanceBudgetScript.new().get_int("max_enemies_total", 700)
	_assert(
		game.state.enemies.size() <= hard_enemy_budget,
		"enemy hard safety budget should hold while protected boss/minion/split spawns may exceed the soft cap, enemies=%d hard_budget=%d" % [game.state.enemies.size(), hard_enemy_budget]
	)
	_assert(game.state.projectiles.size() <= game.state.max_projectiles(), "projectile cap should hold")
	_assert(game.state.enemy_projectiles.size() <= game.state.max_enemy_projectiles(), "enemy projectile cap should hold")
	root.remove_child(main)
	main.free()
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _boss_count(state) -> int:
	var count = 0
	for enemy in state.enemies:
		if enemy.boss:
			count += 1
	return count

func _find_game_screen(node: Node) -> GameScreen:
	if node is GameScreen:
		return node as GameScreen
	for child in node.get_children():
		var found: GameScreen = _find_game_screen(child)
		if found != null:
			return found
	return null
