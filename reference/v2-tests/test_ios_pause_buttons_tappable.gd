extends RefCounted

const MobileScrollSystemScript = preload("res://scripts/systems/MobileScrollSystem.gd")

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game._toggle_pause()

	t.assert_true(game.pause_backdrop.visible, "pause must show a full-screen input blocker")
	t.assert_true(game.pause_overlay.visible, "pause menu must be visible")
	t.assert_true(not game.touch_root.visible, "touch HUD must be hidden while pause owns input")
	t.assert_true(game.touch_root.get_index() < game.pause_backdrop.get_index(), "touch HUD must stay below the pause backdrop")
	t.assert_true(game.pause_backdrop.get_index() < game.pause_overlay.get_index(), "pause menu must render above its backdrop")
	t.assert_true(game.pause_overlay.get_index() < game.pause_dialog_layer.get_index(), "confirmation dialog layer must be topmost")
	t.assert_eq(game.pause_backdrop.mouse_filter, Control.MOUSE_FILTER_STOP, "pause backdrop must stop game input")
	t.assert_eq(game.pause_overlay.mouse_filter, Control.MOUSE_FILTER_STOP, "pause surface must own pause input")
	t.assert_eq(game.pause_dialog_layer.mouse_filter, Control.MOUSE_FILTER_STOP, "dialog layer must own modal input")
	t.assert_eq(game.mobile_scroll_system.axis_for(game.pause_content_scroll), MobileScrollSystemScript.AXIS_VERTICAL, "pause content must use finger vertical scrolling")
	t.assert_eq(game.mobile_scroll_system.axis_for(game.pause_tab_scroll), MobileScrollSystemScript.AXIS_HORIZONTAL, "pause tabs must use finger horizontal scrolling")

	for i in range(game.pause_tab_buttons.size()):
		var tab: Button = game.pause_tab_buttons[i]
		t.assert_true(not tab.disabled, "pause tab %d must be enabled" % i)
		t.assert_true(tab.custom_minimum_size.y >= 56.0, "pause tab %d must meet touch target height" % i)
		tab.pressed.emit()
		t.assert_eq(game.pause_tab_index, i, "pause tab %d must respond to pressed" % i)

	var settings := _find_button(game.pause_overlay, "設定")
	var title := _find_button(game.pause_overlay, "タイトルへ戻る")
	var resume := _find_button(game.pause_overlay, "ゲームへ戻る")
	t.assert_true(settings != null and not settings.disabled, "pause settings action must be tappable")
	t.assert_true(title != null and not title.disabled, "pause title action must be tappable")
	t.assert_true(resume != null and not resume.disabled, "pause resume action must be tappable")
	if title != null:
		title.pressed.emit()
		t.assert_true(game.pause_dialog_layer.visible and game.pause_confirm_dialog.visible, "title action must open the modal confirmation layer")
		var cancel := _find_button(game.pause_confirm_dialog, "ゲームへ戻る")
		var confirm := _find_button(game.pause_confirm_dialog, "ランを終了して清算")
		t.assert_true(cancel != null and cancel.custom_minimum_size.y >= 64.0, "cancel must be a large touch target")
		t.assert_true(confirm != null and confirm.custom_minimum_size.y >= 64.0, "confirm must be a large touch target")
		if cancel != null:
			cancel.pressed.emit()
			t.assert_true(not game.pause_dialog_layer.visible, "cancel must close the modal layer")
	if resume != null:
		resume.pressed.emit()
		t.assert_true(not game.state.paused, "resume must return to gameplay")
	game.free()
	SaveSystem.new().update_settings(old_settings)

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
