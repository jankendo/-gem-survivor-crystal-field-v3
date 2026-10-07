extends RefCounted

const UnlockSystemScript = preload("res://scripts/systems/UnlockSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const CurrencySinkSystemScript = preload("res://scripts/systems/CurrencySinkSystem.gd")

func run(t) -> void:
	var save := SaveSystemScript.new("user://test_shop_only_weapon_unlocks.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var data := save.load_data()
	data["stats"]["total_crystals"] = 20
	UnlockSystemScript.new().update_after_run(data)
	t.assert_true(not (data.get("unlocked_weapons", []) as Array).has("laser_lance"), "condition should not directly unlock laser_lance")
	t.assert_true(bool(data.get("shop_available", {}).get("weapon", {}).get("laser_lance", false)), "condition should publish laser_lance to shop")
	data["crystal_currency"] = 99999
	save.save_data(data)
	t.assert_true(CurrencySinkSystemScript.new().purchase(save, "weapon_license_laser_lance"), "shop purchase should unlock laser_lance")
	t.assert_true((save.load_data().get("unlocked_weapons", []) as Array).has("laser_lance"), "purchased laser_lance should be usable")
