extends RefCounted

const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var system = ShopEntitlementSystemScript.new()
	var save := SaveSystemScript.new("user://test_shop_entitlement_system.save")
	var data := save.load_data()
	t.assert_true(system.is_usable(data, "weapon", "magic_bolt"), "starter weapon should be usable")
	t.assert_true(not system.is_usable(data, "weapon", "laser_lance"), "nonstarter weapon should not be usable before purchase")
	data["stats"]["total_crystals"] = 20
	var newly: Dictionary = system.publish_available_from_conditions(data)
	t.assert_true((newly.get("weapon", []) as Array).has("laser_lance"), "condition should publish weapon to shop")
	t.assert_true(system.is_available_for_purchase(data, "weapon", "laser_lance"), "published weapon should be available for purchase")
	t.assert_true(not system.is_usable(data, "weapon", "laser_lance"), "published weapon should still be unusable before purchase")
