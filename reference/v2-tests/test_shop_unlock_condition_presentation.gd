extends RefCounted

const Presenter = preload("res://scripts/systems/ShopUnlockPresentationSystem.gd")

func run(t) -> void:
	var save := {"crystal_currency": 10, "stats": {"total_kills": 50}, "shop_purchases": {}, "shop_available": {}}
	var card := Presenter.new().card(save, "weapon", "soul_scythe", {"name_ja": "魂の大鎌", "description_ja": "斬撃武器"}, 1000)
	var text := String(card.get("text", ""))
	t.assert_true(text.contains("現在") and text.contains("あと"), "shop card must show current and shortage progress")
	t.assert_true(text.contains("購入費用") and text.contains("通貨不足"), "shop card must show currency details")
