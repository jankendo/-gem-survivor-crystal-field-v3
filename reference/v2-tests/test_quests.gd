extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_quests_complete_and_reward_after_run(t)
	test_quest_rewards_unlock_characters(t)

func _fresh_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_quests.save")
	save.save_data({})
	save.reset_play_data("RESET")
	return save

func _summary() -> Dictionary:
	return {
		"score": 500000,
		"survival_time": 1200.0,
		"kills": 5000,
		"crystals_destroyed": 300,
		"chests_opened": 12,
		"max_combo": 500,
		"boss_defeats": 1,
		"boss_defeated_ids": ["boss_30"],
		"rune_contracts": ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
		"weapon_levels": {"magic_bolt": 8},
		"weapon_kill_counts": {"mirror_shard": 1000},
		"evolved_weapon_ids": ["magic_bolt"],
		"evolved_weapon_count": 1,
		"enemy_seen": ["normal"],
		"title_badges": ["終末突破"]
	}

func test_quests_complete_and_reward_after_run(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	var result: Dictionary = meta.update_after_run(save, _summary())
	var completed: Array = result.get("quests_completed", [])
	t.assert_true(completed.has("survive_10"), "10 minute survival quest should complete")
	t.assert_true(completed.has("survive_20"), "20 minute survival quest should complete")
	t.assert_true(completed.has("kill_5000"), "kill quest should complete")
	t.assert_true(completed.has("boss_30"), "boss quest should complete")

func test_quest_rewards_unlock_characters(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	meta.update_after_run(save, _summary())
	var data := save.load_data()
	var available: Dictionary = data.get("shop_available", {}).get("character", {})
	t.assert_true(bool(available.get("atlas", false)), "survive 20 quest should publish Atlas to shop")
	t.assert_true(bool(available.get("gantz", false)), "crystal quest should publish Gantz to shop")
	t.assert_true(bool(available.get("nero", false)), "contract quest should publish Nero to shop")
	t.assert_true(bool(available.get("zero", false)), "boss quest should publish Zero to shop")
	t.assert_true(bool(available.get("collector", false)), "max combo should publish Collector to shop")
	t.assert_true(not (data["unlocked_characters"] as Array).has("atlas"), "quest reward should still require shop purchase")
