extends RefCounted

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	for label in ["開始", "キャラクター選択", "解放 / 強化", "図鑑", "実績", "設定"]:
		t.assert_true(_find_button(main, label) != null, "touch title should expose %s" % label)
	main.show_character_select()
	t.assert_true(_find_button(main, "このキャラで開始") != null, "character screen should expose a touch start button")
	main.show_settings()
	t.assert_true(_find_button(main, "戻る") != null, "settings should expose a touch back button")
	main.free()

	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	t.assert_true(game.touch_pause_button != null, "game should expose touch pause")
	game._toggle_pause()
	t.assert_true(_find_button(game, "ゲームへ戻る") != null, "pause should expose touch resume")
	game.free()

	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	for label in ["もう一度", "キャラ変更", "強化へ", "図鑑へ", "タイトルへ"]:
		t.assert_true(_find_button(result, label) != null, "result should expose %s" % label)
	result.free()
	SaveSystem.new().update_settings(old_settings)

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
