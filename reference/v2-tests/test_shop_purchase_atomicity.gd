extends RefCounted

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_purchase_atomicity.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["total_crystals"] = 20
	data["shop_available"]["weapon"]["laser_lance"] = true
	data["crystal_currency"] = 99999
	save.save_data(data)
	var sink = CurrencySinkSystemScript.new()
	var before := int(save.load_data().get("crystal_currency", 0))
	t.assert_true(sink.purchase(save, "weapon_license_laser_lance"), "first purchase should succeed")
	var after_first := int(save.load_data().get("crystal_currency", 0))
	t.assert_true(after_first < before, "first purchase should spend currency")
	t.assert_true(not sink.purchase(save, "weapon_license_laser_lance"), "second purchase should fail")
	t.assert_eq(int(save.load_data().get("crystal_currency", 0)), after_first, "failed second purchase should not spend currency")
