extends RefCounted

func run(t) -> void:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game.state.elapsed_seconds = 42.0
	game.state.spawn_meter = 0.5
	game._toggle_expanded_map()
	t.assert_true(game.map_expanded, "expanded map should open")
	t.assert_true(game.state.pause_reasons.has("map"), "map pause reason should be active")
	var elapsed_before = game.state.elapsed_seconds
	var spawn_before = game.state.spawn_meter
	var enemy_positions = []
	for enemy in game.state.enemies:
		enemy_positions.append(enemy.position)
	game._process(1.0)
	t.assert_eq(game.state.elapsed_seconds, elapsed_before, "elapsed time should not advance while map is open")
	t.assert_eq(game.state.spawn_meter, spawn_before, "spawn timer should not advance while map is open")
	for i in range(enemy_positions.size()):
		t.assert_eq(game.state.enemies[i].position, enemy_positions[i], "enemy position should not advance while map is open")
	game._toggle_expanded_map()
	t.assert_true(not game.state.pause_reasons.has("map"), "map pause reason should clear when map closes")
	game.free()
