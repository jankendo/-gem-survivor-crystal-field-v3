extends RefCounted

const V2FeedbackDirectorScript = preload("res://scripts/systems/V2FeedbackDirector.gd")

func run(t) -> void:
	test_queue_keeps_highest_priority_items(t)
	test_low_priority_waits_behind_high_priority(t)

func test_queue_keeps_highest_priority_items(t) -> void:
	var director = V2FeedbackDirectorScript.new()
	director.ingest({"type": "boss_spawn", "name": "巨大スライム"}, 1.0)
	for i in range(8):
		director.ingest({"type": "combo_milestone", "message": "combo %d" % i}, 1.1 + float(i) * 0.01)
	t.assert_true(director.queue_size() <= 4, "feedback queue should be capped")
	t.assert_true(int(director.suppressed_count) > 0, "overflowing low priority events should be suppressed")

func test_low_priority_waits_behind_high_priority(t) -> void:
	var director = V2FeedbackDirectorScript.new()
	director.ingest({"type": "v2_momentum_ending", "remaining": 2.0}, 5.0)
	director.ingest({"type": "global_gem_collection", "source": "magnet", "count": 80, "exp": 200}, 5.1)
	t.assert_true(director.active_text().find("全ジェム回収") >= 0, "high priority collection should replace low priority ending warning")
