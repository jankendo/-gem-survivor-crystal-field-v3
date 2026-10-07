extends RefCounted

const PlayerScript = preload("res://scripts/systems/Player.gd")
const IosPerformanceBudgetScript = preload("res://scripts/systems/IosPerformanceBudgetSystem.gd")

func run(tree: SceneTree, config: Dictionary) -> Dictionary:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	game.set_process(false)
	game.state.start_new_run(int(config.get("seed", 8800)), String(config.get("category", "balance")))
	game.state.balance_data["max_enemies"] = 140
	game.state.balance_data["max_gems"] = 240
	game.state.balance_data["max_projectiles"] = 180
	game.state.balance_data["max_enemy_projectiles"] = 90
	game.state.balance_data["max_effects"] = 90
	game.state.weapons = (config.get("weapons", {}) as Dictionary).duplicate(true)
	game.state.passives = (config.get("passives", {}) as Dictionary).duplicate(true)
	game.state.unlocked_weapon_ids = game.state.weapons.keys()
	game.state.unlocked_passive_ids = game.state.passives.keys()
	game.state.max_hp = int(config.get("hp", 1200))
	game.state.hp = game.state.max_hp
	game.state.gem_turret_charge = 999
	var selected = 0
	var damage_at_five = 0
	for tick in range(720):
		game.touch_direction = _movement_direction(game.state, String(config.get("strategy", "circle")), tick)
		game._process(1.0)
		if game.state.level_up_pending and not game.state.level_up_options.is_empty():
			game._select_reward(selected % game.state.level_up_options.size())
			selected += 1
		if damage_at_five == 0 and game.state.elapsed_seconds >= 300.0:
			damage_at_five = _total_damage(game.state.weapon_damage_by_id)
		if tick % 60 == 0:
			await tree.process_frame
		if game.state.game_over:
			break
		if game.state.elapsed_seconds >= 600.0:
			break
	var metrics = {
		"category": String(config.get("category", "")),
		"elapsed": game.state.elapsed_seconds,
		"kills": game.state.kills,
		"damage": _total_damage(game.state.weapon_damage_by_id),
		"damage_at_five": damage_at_five,
		"damage_taken": game.state.max_hp - game.state.hp,
		"enemy_count": game.state.enemies.size(),
		"enemy_soft_cap": game.state.max_enemies(),
		"enemy_hard_budget": IosPerformanceBudgetScript.new().get_int("max_enemies_total", 700),
		"projectile_count": game.state.projectiles.size(),
		"game_over": game.state.game_over,
		"boss_minutes": game.state.boss_spawned_minutes.duplicate(),
		"level": game.state.level
	}
	tree.root.remove_child(game)
	game.free()
	await tree.process_frame
	return metrics

func _movement_direction(state, strategy: String, tick: int) -> Vector2:
	var nearest = null
	var nearest_distance = INF
	for enemy in state.enemies:
		var distance = enemy.position.distance_to(state.player_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	var circle = Vector2.RIGHT.rotated(float(tick) * 0.075)
	if nearest == null:
		return circle
	var toward = (nearest.position - state.player_position).normalized()
	match strategy:
		"melee":
			return (toward + circle * 0.28).normalized()
		"retreat":
			return (-toward + circle * 0.42).normalized()
		_:
			return circle

func _total_damage(damage_by_id: Dictionary) -> int:
	var total = 0
	for value in damage_by_id.values():
		total += int(value)
	return total
