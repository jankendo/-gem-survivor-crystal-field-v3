extends RefCounted

func run(t) -> void:
	test_evolution_shortage_text(t)
	test_evolution_wait_text(t)
	test_evolution_ready_text(t)

func _game() -> GameScreen:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()
	game.set_pause_tab(2)
	return game

func test_evolution_shortage_text(t) -> void:
	var game := _game()
	game.state.weapons["magic_bolt"] = 7
	game.state.passives.erase("might")
	game.set_pause_tab(2)
	t.assert_true(game.pause_content.text.find("条件不足") >= 0, "evolution UI should show shortages")
	t.assert_true(game.pause_content.text.find("武器Lv不足") >= 0, "evolution UI should show weapon level shortage")
	t.assert_true(game.pause_content.text.find("素材不足") >= 0, "evolution UI should show passive shortage")
	game.free()

func test_evolution_ready_text(t) -> void:
	var game := _game()
	game.state.elapsed_seconds = 300.0
	game.state.weapons["magic_bolt"] = 8
	game.state.passives["might"] = 3
	game.set_pause_tab(2)
	t.assert_true(game.pause_content.text.find("宝箱で進化可能") >= 0, "evolution UI should show chest-ready evolution")
	game.free()

func test_evolution_wait_text(t) -> void:
	var game := _game()
	game.state.weapons["magic_bolt"] = 8
	game.state.passives["might"] = 3
	game.state.elapsed_seconds = 120.0
	game.set_pause_tab(2)
	t.assert_true(game.pause_content.text.find("進化解禁まで") >= 0, "evolution UI should explain the time gate")
	game.free()
