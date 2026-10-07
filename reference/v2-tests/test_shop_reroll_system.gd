extends RefCounted

const SelectionActionSystemScript = preload("res://scripts/systems/SelectionActionSystem.gd")
const ShopRerollSystemScript = preload("res://scripts/systems/ShopRerollSystem.gd")

func run(t) -> void:
	test_shop_inventory_reroll_is_disabled(t)
	test_levelup_reroll_capacity_uses_permanent_upgrade(t)
	test_legacy_shop_keys_are_ignored(t)

func test_shop_inventory_reroll_is_disabled(t) -> void:
	var save = SaveSystem.new("user://test_shop_reroll_disabled.save")
	save.save_data({"crystal_currency": 9999, "shop_save_seed": 777, "shop_featured_items": [{"id": "old"}]})
	var system = ShopRerollSystemScript.new()
	var result = system.reroll(save)
	t.assert_true(not bool(result.get("ok", true)), "shop inventory reroll should be disabled")
	t.assert_eq(str(save.load_data().get("shop_featured_items", [])), str([{"id": "old"}]), "deprecated shop reroll must not mutate featured items")

func test_levelup_reroll_capacity_uses_permanent_upgrade(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "levelup-reroll-upgrade")
	var selection = SelectionActionSystemScript.new()
	selection.begin_run(state, {"currency_sink_levels": {"levelup_reroll_capacity": 3}, "stats": {}})
	t.assert_eq(state.selection_reroll_max, 4, "permanent upgrade should add level-up rerolls")
	state.level_up_pending = true
	t.assert_true(selection.consume_reroll(state, []), "level-up reroll should consume a run charge")
	t.assert_eq(state.selection_reroll_remaining, 3, "reroll remaining should decrease")

func test_legacy_shop_keys_are_ignored(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "legacy-shop-keys")
	var selection = SelectionActionSystemScript.new()
	selection.begin_run(state, {
		"shop_cycle_id": 999,
		"shop_reroll_count": 99,
		"shop_featured_items": [{"id": "wrong"}],
		"shop_save_seed": 123,
		"currency_sink_levels": {},
		"stats": {}
	})
	t.assert_eq(state.selection_reroll_max, 1, "legacy shop keys must not grant level-up rerolls")
