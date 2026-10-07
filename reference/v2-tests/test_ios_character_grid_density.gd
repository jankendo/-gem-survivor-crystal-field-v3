extends RefCounted

const MobileUiScaleSystemScript = preload("res://scripts/systems/MobileUiScaleSystem.gd")

func run(t) -> void:
	var scale = MobileUiScaleSystemScript.new()
	var expectations := {
		Vector2(1334, 750): 3,
		Vector2(1792, 828): 4,
		Vector2(2532, 1170): 4,
		Vector2(2796, 1290): 5,
		Vector2(2388, 1668): 8,
		Vector2(2732, 2048): 8
	}
	for size in expectations.keys():
		t.assert_true(scale.character_visible_count(size) >= int(expectations[size]), "character density should meet target at %s" % str(size))
		var metrics: Dictionary = scale.metrics(size)
		t.assert_true(float(metrics["character_card_height"]) <= 136.0, "compact cards should not consume excessive height")

	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on"})
	var main = load("res://scenes/Main.tscn").instantiate()
	main._ready()
	main.show_character_select()
	var carousel := _find_named(main, "CharacterCarousel")
	t.assert_true(carousel is ScrollContainer, "phone character selection should use a horizontal carousel")
	t.assert_true(_count_character_cards(main) == main.meta_system.character_ids().size(), "carousel should expose every character")
	main.blessing_expanded = true
	main.show_character_select()
	var sheet := _find_named(main, "BlessingSheet")
	t.assert_true(sheet != null and sheet.custom_minimum_size.y <= 300.0, "blessing sheet must stay below forty percent of phone height")
	main.free()
	SaveSystem.new().update_settings(old_settings)

func _find_named(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var found := _find_named(child, target)
		if found != null:
			return found
	return null

func _count_character_cards(node: Node) -> int:
	var count := 1 if node is CharacterCard else 0
	for child in node.get_children():
		count += _count_character_cards(child)
	return count

