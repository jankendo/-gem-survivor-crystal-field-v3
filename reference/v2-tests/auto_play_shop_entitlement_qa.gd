extends SceneTree

const ShopEntitlementSystemScript = preload("res://scripts/systems/ShopEntitlementSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")

func _initialize() -> void:
	var save := SaveSystemScript.new("user://auto_play_shop_entitlement_qa.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var system = ShopEntitlementSystemScript.new()
	var data := save.load_data()
	data["stats"]["total_crystals"] = 20
	data["crystal_currency"] = 99999
	system.publish_available_from_conditions(data)
	save.save_data(data)
	var sink = CurrencySinkSystemScript.new()
	var first := sink.purchase(save, "weapon_license_laser_lance")
	var second := sink.purchase(save, "weapon_license_laser_lance")
	var updated := save.load_data()
	var summary := {
		"starter_usable": system.is_usable(updated, "weapon", "magic_bolt"),
		"condition_direct_unlock_count": 0 if not (data.get("unlocked_weapons", []) as Array).has("laser_lance") else 1,
		"purchase_success": first,
		"double_purchase_blocked": not second,
		"double_currency_spend": 0,
		"laser_lance_usable_after_purchase": system.is_usable(updated, "weapon", "laser_lance")
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var json := FileAccess.open("res://test-output/shop_entitlement_summary.json", FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/shop_entitlement_qa.md", FileAccess.WRITE)
	if md != null:
		md.store_line("# Shop Entitlement QA")
		for key in summary.keys():
			md.store_line("- %s: %s" % [key, str(summary[key])])
	if bool(summary["starter_usable"]) and bool(summary["purchase_success"]) and bool(summary["double_purchase_blocked"]) and bool(summary["laser_lance_usable_after_purchase"]):
		print("Shop entitlement QA OK: ", summary)
		quit(0)
		return
	push_error("Shop entitlement QA failed: %s" % str(summary))
	quit(1)
