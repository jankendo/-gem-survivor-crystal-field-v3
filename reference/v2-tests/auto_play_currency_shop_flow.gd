extends SceneTree

func _initialize() -> void:
	var save = SaveSystem.new("user://auto_currency_shop.save")
	save.save_data({})
	save.reset_play_data("RESET")
	save.add_currency(20000)
	var data := save.load_data()
	data["shop_available"]["weapon"]["corridor_blade"] = true
	save.save_data(data)
	var system = preload("res://scripts/systems/CurrencySinkSystem.gd").new()
	if not system.purchase(save, "scanner_range") or not system.purchase(save, "license_corridor_blade"):
		push_error("Currency shop autoplay purchase failed")
		quit(1)
	print("AutoPlay OK: currency shop categories, geometric purchase, weapon license.")
	quit(0)
