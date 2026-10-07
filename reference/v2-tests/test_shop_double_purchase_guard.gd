extends RefCounted

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_double_purchase_guard.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["best_survival"] = 300.0
	data["shop_available"]["passive"]["regen"] = true
	data["crystal_currency"] = 99999
	save.save_data(data)
	var sink = CurrencySinkSystemScript.new()
	t.assert_true(sink.purchase(save, "passive_license_regen"), "passive purchase should succeed once")
	t.assert_true(not sink.purchase(save, "passive_license_regen"), "passive purchase should be guarded from duplicates")
