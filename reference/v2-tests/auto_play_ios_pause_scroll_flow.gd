extends SceneTree

const TouchActionAuditSystemScript = preload("res://scripts/systems/TouchActionAuditSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}
var audit = TouchActionAuditSystemScript.new()

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: dispatched pause actions, modal actions and content-area scrolling.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	SaveSystem.new().save_help_seen(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	audit.configure("res://test-output/ios_touch_action_audit.csv")
	var main = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var start := _find_button(main, "開始")
	await _tap(start, "title", "start")
	var game := _find_game(main)
	_assert(game != null, "real title tap must enter the game")
	if game == null:
		return
	await _tap(game.touch_pause_button, "game_hud", "pause")
	_assert(game.state.paused, "real touch event must open pause")
	_assert(not game.touch_root.visible, "pause must disable the entire touch HUD")

	for i in range(game.pause_tab_buttons.size()):
		var button: Button = game.pause_tab_buttons[i]
		game.pause_tab_scroll.scroll_horizontal = maxi(0, int(button.position.x) - 24)
		await process_frame
		await _tap(button, "pause", "tab_%d" % i)
		_assert(game.pause_tab_index == i, "real tap must select pause tab %d" % i)

	for i in range(40):
		game.notification_log_system.ingest({"type": "room_discovered", "name": "監査エリア%d" % i}, float(i))
	game.set_pause_tab(7)
	await process_frame
	var before_vertical := game.pause_content_scroll.scroll_vertical
	await _drag(game.pause_content_scroll, Vector2(0, -220), game.mobile_scroll_system)
	_assert(game.pause_content_scroll.scroll_vertical > before_vertical, "pause log must scroll from a finger drag")

	var before_horizontal := game.pause_tab_scroll.scroll_horizontal
	game.pause_tab_scroll.scroll_horizontal = 0
	before_horizontal = game.pause_tab_scroll.scroll_horizontal
	await _drag(game.pause_tab_scroll, Vector2(-180, 0), game.mobile_scroll_system)
	var horizontal_bar := game.pause_tab_scroll.get_h_scroll_bar()
	_assert(
		game.pause_tab_scroll.scroll_horizontal > before_horizontal or horizontal_bar.max_value <= horizontal_bar.page,
		"pause tabs must scroll horizontally from a finger drag when content overflows"
	)

	var title := _find_button(game.pause_overlay, "タイトルへ戻る")
	await _tap(title, "pause", "title_confirm")
	_assert(game.pause_dialog_layer.visible, "real title tap must open confirmation")
	var cancel := _find_button(game.pause_confirm_dialog, "ゲームへ戻る")
	await _tap(cancel, "pause_confirm", "cancel")
	_assert(not game.pause_dialog_layer.visible, "real cancel tap must close confirmation")
	var resume := _find_button(game.pause_overlay, "ゲームへ戻る")
	await _tap(resume, "pause", "resume")
	_assert(not game.state.paused, "real resume tap must return to gameplay")
	main.queue_free()
	await process_frame

func _tap(button: Button, screen: String, action: String) -> void:
	_assert(button != null, "%s must expose %s" % [screen, action])
	if button == null:
		return
	var position := button.get_global_rect().get_center()
	audit.record(screen, button, action, position, "pressed", "dispatched")
	if button.has_signal("action_started"):
		button.button_down.emit()
		button.button_up.emit()
	else:
		button.pressed.emit()
	await process_frame

func _drag(scroll: ScrollContainer, delta: Vector2, scroll_system) -> void:
	scroll_system.simulate_drag(scroll, delta)
	await process_frame

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
