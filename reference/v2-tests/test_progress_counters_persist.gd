extends RefCounted

const MetaScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	var path := "user://test_progress_counters_persist.save"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
	var save := SaveSystem.new(path)
	save.save_data({})
	var result := MetaScript.new().update_after_run(save, {
		"character_id": "noah",
		"blessing_id": "attack",
		"survival_time": 620.0,
		"kills": 125,
		"crystals_destroyed": 12,
		"chests_opened": 2,
		"field_event_successes": 1,
		"field_drops_collected": 3,
		"field_gimmicks_triggered": 4,
		"rooms_discovered": 5,
		"exploration_rank": "S",
		"weapon_pick_count_by_id": {"magic_bolt": 2},
		"passive_pick_count_by_id": {"might": 1},
		"weapon_kill_counts": {"magic_bolt": 80},
		"rune_contracts": [],
		"boss_defeated_ids": [],
		"weapon_levels": {"magic_bolt": 3},
		"evolved_weapon_ids": [],
		"enemy_seen": [],
		"title_badges": []
	})
	var reloaded := SaveSystem.new(path).load_data()
	t.assert_eq(int(reloaded["stats"]["total_kills"]), 125, "kill progress should persist across SaveSystem instances")
	t.assert_eq(int(reloaded["stats"]["walls_broken"]), 12, "wall progress should persist")
	t.assert_eq(int(reloaded["stats"]["rooms_discovered"]), 5, "room progress should persist")
	t.assert_eq(int(reloaded["stats"]["weapon_pick_count"]["magic_bolt"]), 2, "weapon pick progress should persist")
	t.assert_true((result.get("progress_deltas", []) as Array).size() > 0, "run result should include progressed unlock conditions")
	DirAccess.remove_absolute(absolute)
