extends RefCounted

func run(t) -> void:
	test_reset_requires_exact_confirmation(t)
	test_reset_clears_progress_but_keeps_settings(t)

func _dirty_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_save_reset.save")
	save.save_data({})
	save.reset_play_data("RESET")
	save.save_help_seen(true)
	save.add_currency(999)
	save.update_settings({"auto_infinite": false, "auto_recall_drone": true})
	var data := save.load_data()
	data["shop_purchases"]["character"]["mio"] = true
	if not (data["unlocked_characters"] as Array).has("mio"):
		(data["unlocked_characters"] as Array).append("mio")
	data["selected_character"] = "mio"
	data["collection_discovered"]["weapons"]["magic_bolt"] = true
	data["quests_completed"]["survive_10"] = true
	save.save_data(data)
	return save

func test_reset_requires_exact_confirmation(t) -> void:
	var save := _dirty_save()
	t.assert_true(not save.reset_play_data("reset"), "lowercase reset should not clear save data")
	t.assert_eq(save.get_currency(), 999, "failed reset should keep currency")
	t.assert_true(save.is_character_unlocked("mio"), "failed reset should keep unlocked characters")

func test_reset_clears_progress_but_keeps_settings(t) -> void:
	var save := _dirty_save()
	t.assert_true(save.reset_play_data("RESET"), "RESET should clear play progress")
	var data := save.load_data()
	t.assert_eq(int(data.get("crystal_currency", 0)), 0, "reset should clear currency")
	t.assert_true((data["unlocked_characters"] as Array).has("noah"), "reset should keep initial character")
	t.assert_true(not (data["unlocked_characters"] as Array).has("mio"), "reset should clear purchased characters")
	t.assert_eq(String(data.get("selected_character", "")), "noah", "reset should select Noah")
	t.assert_eq(bool(data["settings"].get("auto_infinite", true)), false, "reset should keep auto infinite setting")
	t.assert_eq(bool(data["settings"].get("auto_recall_drone", false)), true, "reset should keep auto recall setting")
	t.assert_true(save.load_help_seen(), "reset should keep help seen flag")
