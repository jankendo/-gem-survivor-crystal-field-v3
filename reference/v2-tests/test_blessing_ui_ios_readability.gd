extends RefCounted

func run(t) -> void:
	var save := SaveSystem.new()
	var original: Dictionary = save.load_data().get("settings", {}).duplicate(true)
	save.update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_character_select()
	t.assert_true(_find_text(main, "数値："), "touch character screen should show blessing numeric effects")
	t.assert_true(_find_text(main, "推奨："), "touch character screen should show blessing recommendation")
	t.assert_true(_min_button_height(main) >= 58.0, "touch blessing controls should remain comfortably tappable")
	main.free()
	save.update_settings(original)

func _find_text(node: Node, part: String) -> bool:
	if node is Label and (node as Label).text.contains(part):
		return true
	if node is Button and (node as Button).text.contains(part):
		return true
	for child in node.get_children():
		if _find_text(child, part):
			return true
	return false

func _min_button_height(node: Node) -> float:
	var result := INF
	if node is Button and (node as Button).visible:
		result = (node as Button).custom_minimum_size.y
	for child in node.get_children():
		result = minf(result, _min_button_height(child))
	return result
