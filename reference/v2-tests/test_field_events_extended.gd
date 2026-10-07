extends RefCounted

const FieldEventSystemScript = preload("res://scripts/systems/FieldEventSystem.gd")

func run(t) -> void:
	test_success_and_failure_events(t)
	test_event_hud_lifecycle(t)

func test_success_and_failure_events(t) -> void:
	var system = FieldEventSystemScript.new()
	var success_state = SurvivorState.new()
	success_state.start_new_run(9301, "event-success")
	success_state.elapsed_seconds = 300.0
	var success_events: Array = []
	system.force_start(success_state, "crystal_surge", success_events)
	success_state.crystals_destroyed += 1
	system.process(success_state, 999.0, success_events)
	t.assert_true(_has_event(success_events, "field_event_success"), "completed objective should emit success")

	var fail_state = SurvivorState.new()
	fail_state.start_new_run(9302, "event-fail")
	fail_state.elapsed_seconds = 300.0
	var fail_events: Array = []
	system.force_start(fail_state, "crystal_surge", fail_events)
	system.process(fail_state, 999.0, fail_events)
	t.assert_true(_has_event(fail_events, "field_event_failed"), "missed objective should emit failure")

func _has_event(events: Array, type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == type:
			return true
	return false

func test_event_hud_lifecycle(t) -> void:
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game.state.elapsed_seconds = 300.0
	var events: Array = []
	game.field_event_system.force_start(game.state, "gem_storm", events)
	game._handle_events(events)
	game._refresh()
	t.assert_true(game.message_label.text.find("イベント発生") >= 0, "event start should show notification")
	t.assert_true(game.event_label.text.find("目標：") >= 0, "active event HUD should show objective")
	game.field_event_system.process(game.state, 999.0, events)
	game._handle_events(events)
	t.assert_true(game.message_label.text.find("イベント") >= 0, "event end should show success or failure")
	game.free()
