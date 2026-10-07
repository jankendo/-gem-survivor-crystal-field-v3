extends RefCounted

const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")

func run(t) -> void:
	var legacy := {
		"unlocked_weapons": ["magic_bolt", "corridor_blade"],
		"currency_sink_levels": {"license_corridor_blade": 1},
		"stats": {}
	}
	var migrated := ShopEntitlementSystemScript.new().migrate_save(legacy)
	t.assert_true((migrated["unlocked_weapons"] as Array).has("corridor_blade"), "legacy purchased weapon license should be preserved")
	t.assert_true(bool(migrated.get("shop_purchases", {}).get("weapon", {}).get("corridor_blade", false)), "legacy license should become purchase record")
