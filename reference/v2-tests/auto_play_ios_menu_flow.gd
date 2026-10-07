extends SceneTree

var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: title, character, shop, collection, achievements, settings, pause and result menus.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	SaveSystem.new().save_help_seen(true)
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await _press_and_expect(main, "キャラクター選択", "characters")
	await _press_and_expect(main, "戻る", "title")
	await _press_and_expect(main, "解放 / 強化", "shop")
	await _press_and_expect(main, "戻る", "title")
	await _press_and_expect(main, "図鑑", "collection")
	await _press_and_expect(main, "戻る", "title")
	await _press_and_expect(main, "実績", "quests")
	await _press_and_expect(main, "戻る", "title")
	await _press_and_expect(main, "設定", "settings")
	_assert(_find_button(main, "タッチ操作説明を再表示") != null, "settings should expose tutorial replay")
	await _press_and_expect(main, "戻る", "title")
	var start := _find_button(main, "開始")
	_assert(start != null, "title should expose touch start")
	if start != null:
		start.pressed.emit()
		await process_frame
	var game := _find_game(main)
	_assert(game != null, "touch start should enter game")
	if game != null:
		game._on_touch_action_started("action_pause")
		_assert(game.state.paused, "touch pause should open pause menu")
		var resume := _find_button(game, "ゲームへ戻る")
		_assert(resume != null, "pause should expose resume")
		if resume != null:
			resume.pressed.emit()
		game.state.game_over = true
		game.state.game_over_reason = "menu flow"
		game._finish_game([])
		await process_frame
		var result := _find_result(main)
		_assert(result != null, "menu flow should reach result")
		if result != null:
			_assert(_find_button(result, "キャラ変更") != null, "result should expose character route")
			_assert(_find_button(result, "強化へ") != null, "result should expose shop route")
			_assert(_find_button(result, "図鑑へ") != null, "result should expose collection route")
	main.queue_free()
	await process_frame

func _press_and_expect(main: Node, label: String, mode: String) -> void:
	var button := _find_button(main, label)
	_assert(button != null, "%s should be tappable" % label)
	if button != null:
		button.pressed.emit()
		await process_frame
		_assert(String(main.screen_mode) == mode, "%s should open %s" % [label, mode])

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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

func _find_result(node: Node) -> ResultView:
	if node is ResultView:
		return node
	for child in node.get_children():
		var found := _find_result(child)
		if found != null:
			return found
	return null
