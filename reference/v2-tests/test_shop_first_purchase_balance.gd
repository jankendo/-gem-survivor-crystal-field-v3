extends RefCounted

const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_first_purchase_balance.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["total_crystals"] = 20
	data["crystal_currency"] = 700
	ShopEntitlementSystemScript.new().publish_available_from_conditions(data)
	t.assert_true(ShopEntitlementSystemScript.new().can_purchase(data, "weapon", "laser_lance"), "first meaningful weapon purchase should be reachable near 700 currency")
