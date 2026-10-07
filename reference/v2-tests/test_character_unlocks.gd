extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_roster_and_secret_count(t)
	test_currency_purchase_unlock(t)
	test_condition_unlocks(t)
	test_secret_character_masking(t)

func _fresh_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_character_unlocks.save")
	save.save_data({})
	save.reset_play_data("RESET")
	return save

func test_roster_and_secret_count(t) -> void:
	var meta = MetaProgressionSystemScript.new()
	var secret_count := 0
	for id in meta.character_ids():
		if bool(meta.character_data(String(id)).get("secret", false)):
			secret_count += 1
	t.assert_true(meta.character_ids().size() >= 15, "roster should include at least 12 normal and 3 secret characters")
	t.assert_true(secret_count >= 3, "roster should include at least three secret characters")
	t.assert_true(SaveSystem.new("user://test_character_unlocks_roster.save").is_character_unlocked("noah"), "Noah should be unlocked by default")

func test_currency_purchase_unlock(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	save.add_currency(300)
	t.assert_true(meta.purchase_character(save, "mio"), "Mio should be purchasable with 300 crystal currency")
	t.assert_true(save.is_character_unlocked("mio"), "Mio should become unlocked after purchase")
	t.assert_eq(save.get_currency(), 0, "purchase should spend currency")

func test_condition_unlocks(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	var data := save.load_data()
	data["weapon_highest_levels"]["thunder_chain"] = 8
	data["stats"]["total_crystals"] = 300
	save.save_data(data)
	var unlocked := meta.check_character_unlocks(save)
	t.assert_true(unlocked.has("rai"), "Rai should become shop available after Thunder Chain reaches Lv8")
	t.assert_true(unlocked.has("gantz"), "Gantz should become shop available after 300 crystal walls")
	data = save.load_data()
	t.assert_true(bool(data.get("shop_available", {}).get("character", {}).get("rai", false)), "Rai should be listed in shop availability")
	t.assert_true(not save.is_character_unlocked("rai"), "Rai should require shop purchase before use")

func test_secret_character_masking(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	t.assert_eq(meta.display_name("ghost", save.load_data()), "？？？", "locked secret character should hide its name")
	var data := save.load_data()
	data["secret_flags"]["ghost"] = true
	save.save_data(data)
	var unlocked := meta.check_character_unlocks(save)
	t.assert_true(unlocked.has("ghost"), "secret flag should publish Ghost to shop")
	t.assert_eq(meta.display_name("ghost", save.load_data()), "？？？", "unpurchased secret character should keep its name hidden")
