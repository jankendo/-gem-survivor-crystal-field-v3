extends RefCounted

const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")

func run(t) -> void:
	var legacy := {
		"unlocked_weapons": ["magic_bolt", "laser_lance"],
		"unlocked_passives": ["move_speed", "regen"],
		"unlocked_characters": ["noah", "rai"],
		"unlocked_blessings": ["attack", "danger"],
		"selected_character": "rai",
		"selected_blessing": "danger",
		"currency_sink_levels": {},
		"stats": {}
	}
	var migrated := ShopEntitlementSystemScript.new().migrate_save(legacy)
	t.assert_true(not (migrated["unlocked_weapons"] as Array).has("laser_lance"), "legacy condition weapon should be relocked")
	t.assert_true(not (migrated["unlocked_passives"] as Array).has("regen"), "legacy condition passive should be relocked")
	t.assert_eq(String(migrated.get("selected_character", "")), "noah", "locked selected character should be repaired")
	t.assert_eq(String(migrated.get("selected_blessing", "")), "attack", "locked selected blessing should be repaired")
	t.assert_true(bool(migrated.get("shop_migration_notice_pending", false)), "migration notice should be pending once")
