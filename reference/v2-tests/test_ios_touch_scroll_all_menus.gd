extends RefCounted

const MobileScrollSystemScript = preload("res://scripts/systems/MobileScrollSystem.gd")

func run(t) -> void:
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	t.assert_eq(MobileScrollSystemScript.DRAG_THRESHOLD, 12.0, "tap and drag must separate at the specified threshold")

	main.show_character_select()
	_assert_axis(t, main, "CharacterCarousel", MobileScrollSystemScript.AXIS_HORIZONTAL)
	main.blessing_expanded = true
	main.show_character_select()
	_assert_descendant_axis(t, _find_named(main, "BlessingSheet"), MobileScrollSystemScript.AXIS_HORIZONTAL, "blessing sheet")

	main.show_shop()
	_assert_axis(t, main, "ShopCategoryChips", MobileScrollSystemScript.AXIS_HORIZONTAL)
	_assert_has_axis(t, main, MobileScrollSystemScript.AXIS_VERTICAL, "shop products")

	main.show_collection()
	_assert_axis(t, main, "CollectionCategoryChips", MobileScrollSystemScript.AXIS_HORIZONTAL)
	_assert_axis(t, main, "CollectionFilterChips", MobileScrollSystemScript.AXIS_HORIZONTAL)
	_assert_has_axis(t, main, MobileScrollSystemScript.AXIS_VERTICAL, "collection entries")

	main.show_quests()
	_assert_axis(t, main, "AchievementFilterChips", MobileScrollSystemScript.AXIS_HORIZONTAL)
	_assert_has_axis(t, main, MobileScrollSystemScript.AXIS_VERTICAL, "achievement entries")

	main.show_settings()
	_assert_axis(t, main, "SettingsCategoryChips", MobileScrollSystemScript.AXIS_HORIZONTAL)
	t.assert_eq(main.mobile_scroll_system.axis_for(main.settings_scroll), MobileScrollSystemScript.AXIS_VERTICAL, "settings must scroll vertically by finger")

	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	t.assert_eq(result.mobile_scroll_system.axis_for(result.scroll), MobileScrollSystemScript.AXIS_VERTICAL, "result details must scroll vertically by finger")
	result.free()
	main.free()
	SaveSystem.new().update_settings(old_settings)

func _assert_axis(t, root: Node, node_name: String, axis: String) -> void:
	var node := _find_named(root, node_name)
	t.assert_true(node is ScrollContainer, "%s must be a ScrollContainer" % node_name)
	if node is ScrollContainer:
		t.assert_eq(root.mobile_scroll_system.axis_for(node), axis, "%s must register mobile %s dragging" % [node_name, axis])
		t.assert_true(node.scroll_deadzone >= 100000, "%s must not depend on the built-in scrollbar drag path" % node_name)

func _assert_descendant_axis(t, root: Node, axis: String, label: String) -> void:
	var scroll := _find_scroll_with_axis(root, axis)
	t.assert_true(scroll != null, "%s must register mobile %s dragging" % [label, axis])

func _assert_has_axis(t, root: Node, axis: String, label: String) -> void:
	var scroll := _find_scroll_with_axis(root, axis)
	t.assert_true(scroll != null, "%s must register mobile %s dragging" % [label, axis])

func _find_scroll_with_axis(node: Node, axis: String) -> ScrollContainer:
	if node == null:
		return null
	if node is ScrollContainer and String(node.get_meta("mobile_scroll_axis", "")) == axis:
		return node
	for child in node.get_children():
		var found := _find_scroll_with_axis(child, axis)
		if found != null:
			return found
	return null

func _find_named(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null
