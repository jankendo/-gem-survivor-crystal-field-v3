extends RefCounted

const V2FeedbackDirectorScript = preload("res://scripts/systems/V2FeedbackDirector.gd")

func run(t) -> void:
	test_director_shows_single_active_banner(t)
	test_paused_tick_does_not_consume_duration(t)
	test_duplicate_event_is_suppressed(t)

func test_director_shows_single_active_banner(t) -> void:
	var director = V2FeedbackDirectorScript.new()
	director.ingest({"type": "v2_momentum", "label": "連続撃破", "tier": 1, "score_multiplier": 1.04}, 10.0)
	t.assert_true(director.active_text().find("連続撃破") >= 0, "director should show rush banner")
	director.ingest({"type": "evolution", "name": "星砕き"}, 10.1)
	t.assert_true(director.active_text().find("武器進化") >= 0, "critical evolution should replace normal momentum banner")
	t.assert_eq(director.queue_size(), 0, "higher priority replacement should not create a second active banner")

func test_paused_tick_does_not_consume_duration(t) -> void:
	var director = V2FeedbackDirectorScript.new()
	director.ingest({"type": "boss_warning", "message": "ボス接近"}, 20.0)
	var before: Dictionary = director.current.duplicate(true)
	director.tick(10.0, true)
	t.assert_eq(float(director.current.get("remaining", 0.0)), float(before.get("remaining", 0.0)), "paused state should not consume banner time")

func test_duplicate_event_is_suppressed(t) -> void:
	var director = V2FeedbackDirectorScript.new()
	director.ingest({"type": "build_synergy", "id": "gem_engine", "name": "ジェム機関"}, 30.0)
	director.ingest({"type": "build_synergy", "id": "gem_engine", "name": "ジェム機関"}, 30.4)
	t.assert_eq(int(director.suppressed_count), 1, "same feedback event should be deduped")
