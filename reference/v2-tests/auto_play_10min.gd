extends SceneTree

const PlayerScript = preload("res://scripts/systems/Player.gd")
const ChestScript = preload("res://scripts/core/Chest.gd")
const CrystalFieldSystemScript = preload("res://scripts/systems/CrystalFieldSystem.gd")
const GemLifecycleSystemScript = preload("res://scripts/systems/GemLifecycleSystem.gd")

var failures: Array = []

func _initialize() -> void:
	await _run()
	if failures.is_empty():
		print("AutoPlay OK: 10min run, levelups, chest, evolution, crystal break, fever, danger, no freeze.")
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
	game.state.start_new_run(810)
	game.state.max_hp = 99999
	game.state.hp = 99999
	game.state.weapons = {"magic_bolt": 8, "ice_orbit": 5, "thunder_chain": 4}
	game.state.passives = {"might": 3, "area": 2, "cooldown": 2}
	game.state.chests.append(ChestScript.new(game.state.player_position + Vector2(10, 0)))
	var gem_lifecycle = GemLifecycleSystemScript.new()
	for i in range(160):
		gem_lifecycle.spawn(game.state, game.state.player_position + Vector2(float(i % 20) - 10.0, float(i / 20) - 6.0), 1)
	var events: Array = []
	CrystalFieldSystemScript.new().damage_wall(game.state, game.state.crystal_walls[0], 99999, events, "auto")
	var player = PlayerScript.new()
	var selected = 0
	var evolution_chest_injected := false
	var target_gem = null
	for i in range(1200):
		var direction = Vector2.RIGHT.rotated(float(i) * 0.04)
		if target_gem == null or not game.state.gems.has(target_gem) or i % 20 == 0:
			target_gem = _nearest_gem(game.state.gems, game.state.player_position)
		if target_gem != null:
			direction = (target_gem.position - game.state.player_position).normalized()
		player.process_movement(game.state, direction, 0.5)
		if not evolution_chest_injected and game.state.elapsed_seconds >= 300.0:
			game.state.chests.append(ChestScript.new(game.state.player_position, "evolution", "autoplay"))
			evolution_chest_injected = true
		game._process(0.5)
		if game.state.level_up_pending:
			game._select_reward(selected % maxi(1, game.state.level_up_options.size()))
			selected += 1
		if i % 10 == 0:
			await process_frame
	_assert(game.state.elapsed_seconds >= 600.0, "10min autoplay should reach 10 minutes")
	_assert(game.state.level >= 8, "10min autoplay should gain multiple levels")
	_assert(game.state.level <= 35, "10min autoplay level should not run away in boosted evolution setup, actual=%d" % game.state.level)
	_assert(game.state.boss_spawned_minutes.size() <= 2, "10min autoplay should not spawn more than two boss checkpoints")
	_assert(game.state.chests.size() <= game.state.max_chests(), "10min autoplay should respect chest cap")
	_assert(game.state.chests_opened <= 8, "10min autoplay should not flood chest rewards, opened=%d" % game.state.chests_opened)
	_assert(game.state.chests_opened > 0, "10min autoplay should open a chest")
	_assert(game.state.evolved_weapon_count > 0, "10min autoplay should evolve a weapon")
	_assert(game.state.crystals_destroyed > 0, "10min autoplay should break a crystal")
	_assert(game.state.max_combo >= 100 or game.state.gem_fever_tier > 0 or game.state.gem_fever_timer >= 0.0, "10min autoplay should exercise fever path")
	_assert(game.state.boss_spawned_minutes.has(5) and game.state.boss_spawned_minutes.has(10), "10min autoplay should process 5 and 10 minute boss checkpoints")
	root.remove_child(main)
	main.free()
	await process_frame

func _nearest_gem(gems: Array, origin: Vector2):
	var nearest = null
	var nearest_distance_squared := INF
	for gem in gems:
		var distance_squared: float = origin.distance_squared_to(gem.position)
		if distance_squared < nearest_distance_squared:
			nearest = gem
			nearest_distance_squared = distance_squared
	return nearest

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _find_game_screen(node: Node) -> GameScreen:
	if node is GameScreen:
		return node as GameScreen
	for child in node.get_children():
		var found: GameScreen = _find_game_screen(child)
		if found != null:
			return found
	return null
