extends RefCounted

const TouchActionAuditSystemScript = preload("res://scripts/systems/TouchActionAuditSystem.gd")

var audit = TouchActionAuditSystemScript.new()

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	SaveSystem.new().save_help_seen(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	audit.configure("res://test-output/ios_touch_action_audit.csv")
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	_assert_button(t, main, "開始", "title")
	_assert_button(t, main, "キャラクター選択", "title")
	_assert_button(t, main, "解放 / 強化", "title")
	_assert_button(t, main, "図鑑", "title")
	_assert_button(t, main, "実績", "title")
	_assert_button(t, main, "設定", "title")

	main.show_character_select()
	_assert_button(t, main, "祝福を選ぶ", "character_select")
	_assert_button(t, main, "このキャラで開始", "character_select")
	main.blessing_expanded = true
	main.show_character_select()
	_assert_button(t, main, "閉じる", "blessing_sheet")

	main.show_shop()
	_assert_button(t, main, "戻る", "shop")
	main.show_collection()
	_assert_button(t, main, "戻る", "collection")
	main.show_quests()
	_assert_button(t, main, "すべて", "achievements")
	main.show_settings()
	_assert_button(t, main, "タッチ操作説明を再表示", "settings")

	main.start_game()
	var game := _find_game(main)
	t.assert_true(game != null, "game HUD must be reachable from title")
	if game != null:
		if game.state == null:
			game._ready()
		t.assert_true(game.touch_pause_button.custom_minimum_size.x >= 64.0, "game pause must meet the iOS touch target")
		game._toggle_pause()
		_assert_button(t, game.pause_overlay, "ゲームへ戻る", "pause")
		_assert_button(t, game.pause_overlay, "タイトルへ戻る", "pause")
		game._show_title_confirm()
		_assert_button(t, game.pause_confirm_dialog, "ゲームへ戻る", "pause_confirm")
		_assert_button(t, game.pause_confirm_dialog, "ランを終了して清算", "pause_confirm")
	main.free()
	SaveSystem.new().update_settings(old_settings)

func _assert_button(t, root: Node, text_part: String, screen: String) -> void:
	var button := _find_button(root, text_part)
	t.assert_true(button != null, "%s must expose %s" % [screen, text_part])
	if button == null:
		return
	t.assert_true(not button.disabled, "%s button %s must be enabled" % [screen, text_part])
	t.assert_true(button.mouse_filter == Control.MOUSE_FILTER_STOP, "%s button %s must own its tap" % [screen, text_part])
	t.assert_true(button.custom_minimum_size.y >= 44.0, "%s button %s must meet the 44pt-equivalent target" % [screen, text_part])
	audit.record(screen, button, "reachability", button.get_global_rect().get_center(), "reachable", "pass")

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null

func _find_game(node: Node) -> GameScreen:
	if node is GameScreen:
		return node
	for child in node.get_children():
		var found := _find_game(child)
		if found != null:
			return found
	return null
