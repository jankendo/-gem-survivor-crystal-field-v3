extends SceneTree

const MobileScrollSystemScript = preload("res://scripts/systems/MobileScrollSystem.gd")
const TouchActionAuditSystemScript = preload("res://scripts/systems/TouchActionAuditSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}
var audit = TouchActionAuditSystemScript.new()

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: title-to-result menu taps and content-area swipe scrolling.")
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

	await _tap(_find_button(main, "キャラクター選択"), "title", "character_select")
	_assert(main.screen_mode == "characters", "character select tap must change screens")
	var carousel := _find_named(main, "CharacterCarousel") as ScrollContainer
	var selected_before: String = String(main.selected_character_id)
	var carousel_before := carousel.scroll_horizontal
	main.mobile_scroll_system.simulate_drag(carousel, Vector2(-260, 0))
	await process_frame
	_assert(carousel.scroll_horizontal > carousel_before, "character cards must move from a content-area horizontal drag")
	_assert(main.selected_character_id == selected_before, "character swipe must not misfire a card tap")
	await _tap(_find_button(main, "祝福を選ぶ"), "character_select", "open_blessing")
	_assert(_find_named(main, "BlessingSheet") != null, "blessing sheet must open from a tap")
	await _tap(_find_button(main, "閉じる"), "blessing_sheet", "close")
	await _tap(_find_button(main, "戻る"), "character_select", "back")

	await _tap(_find_button(main, "解放 / 強化"), "title", "shop")
	await _tap(_find_button(main, "永続強化"), "shop", "meta_category")
	var shop_scroll := _find_scroll_axis(main, MobileScrollSystemScript.AXIS_VERTICAL)
	var currency_before := int(main.save_data.get("crystal_currency", 0))
	await _ensure_vertical_overflow(shop_scroll)
	var shop_before := shop_scroll.scroll_vertical
	main.mobile_scroll_system.simulate_drag(shop_scroll, Vector2(0, -260))
	await process_frame
	_assert(_scrolled_or_fits(shop_scroll, shop_before), "shop products must move from a content-area vertical drag when content overflows")
	_assert(int(main.save_data.get("crystal_currency", 0)) == currency_before, "shop drag must not trigger purchase")
	await _tap(_find_button(main, "戻る"), "shop", "back")

	await _tap(_find_button(main, "図鑑"), "title", "collection")
	var collection_scroll := _find_scroll_axis(main, MobileScrollSystemScript.AXIS_VERTICAL)
	await _ensure_vertical_overflow(collection_scroll)
	var collection_before := collection_scroll.scroll_vertical
	main.mobile_scroll_system.simulate_drag(collection_scroll, Vector2(0, -240))
	await process_frame
	_assert(_scrolled_or_fits(collection_scroll, collection_before), "collection must move from a content-area vertical drag when content overflows")
	await _tap(_find_button(main, "戻る"), "collection", "back")

	await _tap(_find_button(main, "実績"), "title", "achievements")
	var achievement_scroll := _find_scroll_axis(main, MobileScrollSystemScript.AXIS_VERTICAL)
	await _ensure_vertical_overflow(achievement_scroll)
	var achievement_before := achievement_scroll.scroll_vertical
	main.mobile_scroll_system.simulate_drag(achievement_scroll, Vector2(0, -240))
	await process_frame
	_assert(_scrolled_or_fits(achievement_scroll, achievement_before), "achievements must move from a content-area vertical drag when content overflows")
	await _tap(_find_button(main, "戻る"), "achievements", "back")

	await _tap(_find_button(main, "設定"), "title", "settings")
	var settings_before: int = main.settings_scroll.scroll_vertical
	await _ensure_vertical_overflow(main.settings_scroll)
	settings_before = main.settings_scroll.scroll_vertical
	main.mobile_scroll_system.simulate_drag(main.settings_scroll, Vector2(0, -280))
	await process_frame
	_assert(_scrolled_or_fits(main.settings_scroll, settings_before), "settings must move from a content-area vertical drag when content overflows")
	await _tap(_find_button(main, "戻る"), "settings", "back")

	await _tap(_find_button(main, "開始"), "title", "start")
	var game := _find_game(main)
	_assert(game != null, "start tap must enter the game")
	if game == null:
		return
	game.state.level_up_options = game.level_up_system.prepare_options(game.state, 3)
	game.state.level_up_pending = true
	game._refresh()
	await process_frame
	var reward := _find_reward_button(game.reward_popup)
	_assert(reward != null, "level-up must expose a tappable reward card")
	await _tap(reward, "levelup", "select_reward")
	_assert(not game.state.level_up_pending, "reward card tap must resolve level-up")
	await _tap(game.touch_pause_button, "game_hud", "pause")
	_assert(game.state.paused, "pause must open from the touch button")
	await _tap(_find_button(game.pause_overlay, "ゲームへ戻る"), "pause", "resume")
	_assert(not game.state.paused, "pause resume must restore the run")

	game.state.game_over = true
	game.state.game_over_reason = "full ui flow"
	game._finish_game([])
	await process_frame
	var result := _find_result(main)
	_assert(result != null, "full UI flow must reach result")
	if result != null:
		await _ensure_vertical_overflow(result.scroll)
		var result_before := result.scroll.scroll_vertical
		result.mobile_scroll_system.simulate_drag(result.scroll, Vector2(0, -280))
		await process_frame
		_assert(_scrolled_or_fits(result.scroll, result_before), "result details must move from a content-area vertical drag when content overflows")
		for label in ["もう一度", "キャラ変更", "強化へ", "図鑑へ", "タイトルへ"]:
			_assert(_find_button(result, label) != null, "result must expose %s" % label)
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

func _ensure_vertical_overflow(scroll: ScrollContainer) -> void:
	var bar := scroll.get_v_scroll_bar()
	if bar.max_value > bar.page:
		return
	if scroll.get_child_count() > 0 and scroll.get_child(0) is Control:
		var content := scroll.get_child(0) as Control
		content.custom_minimum_size.y = maxf(content.custom_minimum_size.y, bar.page + 360.0)
		scroll.queue_sort()
		await process_frame
		await process_frame

func _scrolled_or_fits(scroll: ScrollContainer, before: int) -> bool:
	var bar := scroll.get_v_scroll_bar()
	return scroll.scroll_vertical > before or bar.max_value <= bar.page

func _find_scroll_axis(node: Node, axis: String) -> ScrollContainer:
	if node is ScrollContainer and String(node.get_meta("mobile_scroll_axis", "")) == axis:
		return node
	for child in node.get_children():
		var found := _find_scroll_axis(child, axis)
		if found != null:
			return found
	return null

func _find_named(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null

func _find_reward_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and not (child as Button).disabled:
			return child
		var found := _find_reward_button(child)
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

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
