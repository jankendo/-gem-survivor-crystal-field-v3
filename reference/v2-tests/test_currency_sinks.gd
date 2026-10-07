extends RefCounted

const SinkScript = preload("res://scripts/systems/CurrencySinkSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var system = SinkScript.new()
	var blessings = JSON.parse_string(FileAccess.open("res://data/blessings.json", FileAccess.READ).get_as_text())
	t.assert_true(system.category_ids().size() >= 10, "shop must expose at least ten categories")
	t.assert_true(system.sinks.size() >= 24, "currency sinks must provide long-term purchase choices")
	for sink_id in system.sinks.keys():
		var sink: Dictionary = system.sinks[sink_id]
		if String(sink.get("category", "")) == "blessings":
			t.assert_true(blessings.has(String(sink.get("target", ""))), "blessing shop target must exist in blessings master")
	t.assert_true(system.cost_for("scanner_range", 4) > system.cost_for("scanner_range", 3), "sink price must increase geometrically")
	var save = SaveSystem.new("user://test_currency_sinks.save")
	save.save_data({})
	save.reset_play_data("RESET")
	save.add_currency(100000)
	t.assert_true(system.purchase(save, "scanner_range"), "scanner upgrade should be purchasable")
	t.assert_eq(system.current_level(save.load_data(), "scanner_range"), 1, "purchase must persist sink level")
	var data := save.load_data()
	data["shop_available"]["weapon"]["corridor_blade"] = true
	save.save_data(data)
	t.assert_true(system.purchase(save, "license_corridor_blade"), "weapon license should be purchasable")
	t.assert_true((save.load_data().get("unlocked_weapons", []) as Array).has("corridor_blade"), "weapon license must unlock target")
	var state = StateScript.new()
	state.start_new_run(44, "sink-test")
	system.apply_to_state(state, save.load_data())
	t.assert_true(float(state.currency_sink_levels.get("scanner_range", 0)) >= 1.0, "purchased sink must apply to run state")
	t.assert_true(system.total_remaining_cost(save.load_data()) > 100000, "shop must not be quickly bought out")
