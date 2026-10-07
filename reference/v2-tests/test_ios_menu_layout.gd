extends RefCounted

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	t.assert_true(_minimum_button_height(main) >= 56.0, "touch title buttons should be at least 56px high")
	main.show_shop()
	t.assert_true(_find_button(main, "戻る") != null, "touch shop should keep a visible back button")
	main.show_collection()
	t.assert_true(_find_button(main, "戻る") != null, "touch collection should keep a visible back button")
	main.show_quests()
	t.assert_true(_find_button(main, "戻る") != null, "touch achievements should keep a visible back button")
	main.free()
	SaveSystem.new().update_settings(old_settings)

func _minimum_button_height(node: Node) -> float:
	var result := 9999.0
	if node is Button:
		result = minf(result, (node as Button).custom_minimum_size.y)
	for child in node.get_children():
		result = minf(result, _minimum_button_height(child))
	return result

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
