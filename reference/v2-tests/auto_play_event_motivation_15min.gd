extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EventScript = preload("res://scripts/systems/FieldEventSystem.gd")

var failures: Array = []

func _initialize() -> void:
	var state = StateScript.new()
	state.start_new_run(881604, "auto-event-motivation")
	var system = EventScript.new()
	var events: Array = []
	for id in ["gem_storm", "elite_hunt", "danger_bloom"]:
		system.force_start(state, id, events)
		_assert(String(state.active_field_event.get("risk", "")) != "", "%s should expose risk" % id)
		_assert(String(state.active_field_event.get("reward", "")) != "", "%s should expose reward" % id)
		if id == "elite_hunt":
			state.event_elite_reward_pending = false
		elif id == "danger_bloom":
			state.danger_time = float(state.active_field_event.get("start_danger_time", 0.0)) + 12.0
		state.field_event_timer = 0.0
		system.process(state, 0.1, events)
	var reward_count := 0
	for event in events:
		if String(event.get("type", "")) == "field_event_reward":
			reward_count += 1
	_assert(reward_count >= 3, "15min event motivation run should grant concrete rewards")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay event motivation OK: 15min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
