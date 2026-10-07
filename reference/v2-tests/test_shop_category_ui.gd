extends RefCounted

func run(t) -> void:
	SaveSystem.new().save_help_seen(true)
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_shop()
	t.assert_true(main.shop_category_system.category_ids().size() >= 10, "shop UI must have ten category tabs")
	t.assert_true(_tree_has_text(main, "所持クリスタル貨"), "shop UI must always show owned currency")
	t.assert_true(_tree_has_text(main, "おすすめ"), "shop UI must show recommendation")
	t.assert_true(_tree_has_text(main, "武器ライセンス"), "shop UI must show license tab")
	main.free()

func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.find(expected) >= 0:
		return true
	if node is Button and (node as Button).text.find(expected) >= 0:
		return true
	for child in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false
