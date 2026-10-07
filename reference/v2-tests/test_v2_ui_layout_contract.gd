extends RefCounted

func run(t) -> void:
	test_title_exposes_required_hierarchy(t)
	test_game_has_v2_feedback_hud_nodes(t)
	test_result_action_buttons_are_reachable(t)

func test_title_exposes_required_hierarchy(t) -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	t.assert_eq(main.screen_mode, "title", "main should start on title")
	for label in ["ゲーム開始", "キャラクター選択", "強化", "図鑑", "実績", "設定", "遊び方", "終了"]:
		t.assert_true(_find_button(main, label) != null, "title should expose required button: %s" % label)
	var start_button := _find_button(main, "ゲーム開始")
	t.assert_true(start_button.custom_minimum_size.y >= 48.0, "primary title button should keep a desktop touchable height")
	t.assert_true(_find_node(main, "V2TitleKeyVisual") != null, "title should include v2 key visual when manifest asset resolves")
	main.free()

func test_game_has_v2_feedback_hud_nodes(t) -> void:
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	t.assert_true(game.v2_momentum_panel != null, "game HUD should include v2 momentum panel")
	t.assert_true(game.v2_feedback_panel != null, "game HUD should include v2 feedback panel")
	t.assert_true(game.v2_momentum_panel.custom_minimum_size.x >= 180.0, "momentum panel should keep readable width")
	t.assert_true(game.v2_feedback_panel.custom_minimum_size.x >= 260.0, "feedback panel should keep readable width")
	game.free()

func test_result_action_buttons_are_reachable(t) -> void:
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	for label in ["もう一度", "キャラ変更", "強化へ", "図鑑へ", "タイトルへ"]:
		t.assert_true(_find_button(result, label) != null, "result should expose next-action button: %s" % label)
	result.free()

func _find_button(node: Node, label_part: String) -> Button:
	if node is Button and (node as Button).text.find(label_part) >= 0:
		return node as Button
	for child in node.get_children():
		var found = _find_button(child, label_part)
		if found != null:
			return found
	return null

func _find_node(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found = _find_node(child, node_name)
		if found != null:
			return found
	return null
