extends RefCounted

const TitleScreenControllerScript = preload("res://scripts/ui/main/TitleScreenController.gd")
const ShopScreenControllerScript = preload("res://scripts/ui/main/ShopScreenController.gd")
const CollectionScreenControllerScript = preload("res://scripts/ui/main/CollectionScreenController.gd")
const MainScreenStateScript = preload("res://scripts/ui/main/MainScreenState.gd")

func run(t) -> void:
	test_title_controller_defines_required_actions(t)
	test_shop_controller_wraps_categories(t)
	test_collection_controller_tracks_tab_filter_sort(t)
	test_screen_state_tracks_previous_screen(t)

func test_title_controller_defines_required_actions(t) -> void:
	var controller = TitleScreenControllerScript.new()
	var ids := []
	for action in controller.actions():
		ids.append(String(action.get("id", "")))
	for id in ["start", "characters", "shop", "loadout", "collection", "quests", "settings", "help", "reset", "quit"]:
		t.assert_true(ids.has(id), "title action list should include %s" % id)
	t.assert_true(int(controller.actions()[0].get("tier", 0)) == 1, "start should be the primary tier")

func test_shop_controller_wraps_categories(t) -> void:
	var controller = ShopScreenControllerScript.new()
	var ids := ["characters", "meta", "blessings"]
	controller.category_index = 0
	t.assert_eq(controller.move(-1, ids), 2, "shop category should wrap left")
	t.assert_eq(controller.move(1, ids), 0, "shop category should wrap right")
	t.assert_eq(controller.select(99, ids), 2, "shop category select should clamp")

func test_collection_controller_tracks_tab_filter_sort(t) -> void:
	var controller = CollectionScreenControllerScript.new()
	t.assert_eq(controller.move_tab(-1), controller.tabs.size() - 1, "collection tab should wrap left")
	t.assert_eq(controller.select_filter(99, 3), 2, "collection filter should clamp")
	t.assert_eq(controller.select_sort(99, 2), 1, "collection sort should clamp")

func test_screen_state_tracks_previous_screen(t) -> void:
	var state = MainScreenStateScript.new()
	state.set_screen("shop")
	state.set_screen("collection")
	t.assert_eq(state.previous, "shop", "screen state should keep previous screen")
	t.assert_true(state.is_menu_screen(), "collection should be a menu screen")
