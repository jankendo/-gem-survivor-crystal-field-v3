extends RefCounted

func run(t) -> void:
	test_hp_bar_tracks_numeric_hp(t)
	test_damage_flash_state_is_visible(t)

func test_hp_bar_tracks_numeric_hp(t) -> void:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game.state.hp = 42
	game.state.max_hp = 120
	game._refresh()
	t.assert_true(game.hp_label.text.find("42 / 120") >= 0, "HP label should show numeric HP")
	t.assert_eq(int(game.hp_bar.value), 42, "HP bar should track current HP")
	game.free()

func test_damage_flash_state_is_visible(t) -> void:
	var game: GameScreen = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game.state.hp = 8
	game.state.damage_flash_timer = 0.2
	game._refresh()
	t.assert_true(game.state.hp_ratio() < 0.10, "low HP should be detectable for red edge")
	t.assert_true(game.state.damage_flash_timer > 0.0, "damage flash timer should be set")
	game.free()

