extends RefCounted

const TrackerScript = preload("res://scripts/systems/ProgressTrackerSystem.gd")
const MetaScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const UnlockScript = preload("res://scripts/systems/UnlockSystem.gd")
const CardScript = preload("res://scripts/ui/components/AchievementCard.gd")

func run(t) -> void:
	var save_data := SaveSystem.new("user://test_unlock_progress_display.save").load_data()
	save_data["stats"]["total_kills"] = 320
	save_data["stats"]["total_crystals"] = 42
	save_data["stats"]["best_survival"] = 452.0
	var tracker = TrackerScript.new()
	var text := tracker.progress_text(save_data, {"type": "total_kills", "value": 500})
	t.assert_true(text.contains("320 / 500"), "single unlock condition should show current and target")
	t.assert_true(text.contains("64%"), "single unlock condition should show percent")
	var multi := tracker.progress_text(save_data, {"conditions": [
		{"type": "total_kills", "value": 500},
		{"type": "total_crystals", "value": 100},
		{"type": "survive_seconds", "seconds": 600}
	]})
	t.assert_true(multi.contains("320 / 500") and multi.contains("42 / 100") and multi.contains("7:32 / 10:00"), "multiple unlock conditions should each show progress")

	var unlocks = UnlockScript.new()
	var weapon_id := _first_locked_id(unlocks.weapon_unlocks, save_data.get("unlocked_weapons", []))
	var passive_id := _first_locked_id(unlocks.passive_unlocks, save_data.get("unlocked_passives", []))
	t.assert_true(unlocks.progress_text("weapons", weapon_id, save_data).contains(" / "), "weapon unlock should show current and target")
	t.assert_true(unlocks.progress_text("passives", passive_id, save_data).contains(" / "), "passive unlock should show current and target")
	var meta = MetaScript.new()
	var locked_character := _first_locked_character(meta, save_data)
	t.assert_true(meta.unlock_text(locked_character, save_data).contains(" / "), "character unlock should show current and target")
	t.assert_true(meta.blessing_detail_text("mining", save_data).contains("42 / 100"), "locked blessing should show progress")

	var card = CardScript.new()
	card.setup("撃破実績", "敵を倒す", "100貨", false, tracker.progress_for_condition(save_data, {"type": "total_kills", "value": 500}))
	t.assert_true(card.label.text.contains("320 / 500"), "achievement card should show numeric progress")
	t.assert_eq(int(card.progress_bar.value), 320, "achievement progress bar should reflect current value")
	card.free()

func _first_locked_id(defs: Dictionary, unlocked: Array) -> String:
	for raw_id in defs.keys():
		var id := String(raw_id)
		if not unlocked.has(id):
			return id
	return String(defs.keys()[0])

func _first_locked_character(meta, save_data: Dictionary) -> String:
	for raw_id in meta.character_ids():
		var id := String(raw_id)
		if not meta.is_character_unlocked(save_data, id):
			return id
	return "noah"
