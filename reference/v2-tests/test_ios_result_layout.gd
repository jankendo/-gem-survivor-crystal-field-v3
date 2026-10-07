extends RefCounted

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	for label in ["もう一度", "キャラ変更", "強化へ", "図鑑へ", "タイトルへ"]:
		var button := _find_button(result, label)
		t.assert_true(button != null, "touch result should expose %s" % label)
		if button != null:
			t.assert_true(button.custom_minimum_size.y >= 56.0, "touch result buttons should be at least 56px high")
	t.assert_true(result.scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL, "result details should remain scrollable")
	result.free()
	SaveSystem.new().update_settings(old_settings)

func _find_button(node: Node, text_part: String) -> Button:
	if node is Button and (node as Button).text.contains(text_part):
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_part)
		if found != null:
			return found
	return null
