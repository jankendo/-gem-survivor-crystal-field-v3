extends RefCounted

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	t.assert_true(_find_button(main, "終了") == null, "iOS title must not show an exit button")
	t.assert_true(_minimum_button_height(main) >= 64.0, "iOS title buttons must be at least 64px")
	main.show_shop()
	t.assert_true(_find_named(main, "ShopCategoryChips") is ScrollContainer, "shop categories should scroll horizontally")
	main.show_collection()
	t.assert_true(_find_named(main, "CollectionCategoryChips") is ScrollContainer, "collection categories should scroll horizontally")
	t.assert_true(_find_named(main, "CollectionFilterChips") is ScrollContainer, "collection filters should scroll horizontally")
	main.show_settings()
	t.assert_true(_find_named(main, "SettingsCategoryChips") is ScrollContainer, "settings categories should be tappable horizontal chips")
	t.assert_true(not _tree_text(main).contains("開発者表示"), "developer setting must stay hidden on touch UI")
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
		return node
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null

func _find_named(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_named(child, target)
		if found != null:
			return found
	return null

func _tree_text(node: Node) -> String:
	var parts: Array = []
	if node is Label:
		parts.append((node as Label).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		parts.append(_tree_text(child))
	return "\n".join(parts)
