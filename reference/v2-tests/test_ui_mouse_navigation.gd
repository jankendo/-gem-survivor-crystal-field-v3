extends RefCounted

func run(t) -> void:
	test_title_menu_buttons_click(t)
	test_character_card_click_selects(t)
	test_settings_toggle_click(t)

func _find_button(node: Node, label_part: String) -> Button:
	if node is Button and (node as Button).text.find(label_part) >= 0:
		return node as Button
	for child in node.get_children():
		var found = _find_button(child, label_part)
		if found != null:
			return found
	return null

func test_title_menu_buttons_click(t) -> void:
	SaveSystem.new().save_help_seen(true)
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	var button = _find_button(main, "キャラクター選択")
	t.assert_true(button != null, "title should expose character select mouse button")
	button.pressed.emit()
	t.assert_eq(main.screen_mode, "characters", "clicking character select should open character screen")
	main.free()

func test_character_card_click_selects(t) -> void:
	var save = SaveSystem.new()
	var data := save.load_data()
	data["shop_purchases"]["character"]["mio"] = true
	if not (data["unlocked_characters"] as Array).has("mio"):
		(data["unlocked_characters"] as Array).append("mio")
	data["selected_character"] = "noah"
	save.save_data(data)
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_character_select()
	var button = _find_button(main, "氷術師ミオ")
	t.assert_true(button != null, "character screen should expose Mio card button")
	button.pressed.emit()
	t.assert_eq(SaveSystem.new().selected_character(), "mio", "clicking unlocked character card should select it")
	main.free()

func test_settings_toggle_click(t) -> void:
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_settings()
	var before = bool(SaveSystem.new().get_setting("auto_recall_drone", false))
	var button = _find_button(main, "自動回収ドローン")
	t.assert_true(button != null, "settings should expose auto recall toggle button")
	button.pressed.emit()
	t.assert_eq(bool(SaveSystem.new().get_setting("auto_recall_drone", false)), not before, "clicking settings toggle should update save")
	main.free()
