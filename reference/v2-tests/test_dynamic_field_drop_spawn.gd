extends RefCounted

const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const ObjectiveIndicatorSystemScript = preload("res://scripts/systems/ObjectiveIndicatorSystem.gd")

func run(t) -> void:
	test_force_spawn_is_seed_reproducible(t)
	test_timed_spawn_is_disabled_by_default(t)
	test_forced_drop_never_expires(t)

func _state():
	var state = SurvivorState.new()
	state.start_new_run(8811, "dynamic-drop")
	state.field_drops.clear()
	state.elapsed_seconds = 300.0
	return state

func test_force_spawn_is_seed_reproducible(t) -> void:
	var a = _state()
	var b = _state()
	var system = FieldDropSpawnSystemScript.new()
	var a_drop = system.force_spawn(a, "heal_ore", [])
	var b_drop = system.force_spawn(b, "heal_ore", [])
	t.assert_true(not a_drop.is_empty(), "dynamic drop force spawn should create a drop")
	t.assert_eq(a_drop.get("position"), b_drop.get("position"), "same seed should reproduce dynamic drop position")
	t.assert_true(bool(a_drop.get("dynamic", false)), "spawned drop should be marked dynamic")
	t.assert_true(bool(a_drop.get("persistent", false)), "forced event drop should be persistent")
	t.assert_true(float(a_drop.get("spawn_distance", 0.0)) >= 420.0, "dynamic drop should respect minimum distance")

func test_timed_spawn_is_disabled_by_default(t) -> void:
	var state = _state()
	state.field_drop_spawn_config["base_spawn_chance"] = 1.0
	state.next_dynamic_drop_time = state.elapsed_seconds
	var events: Array = []
	FieldDropSpawnSystemScript.new().process(state, 0.1, events)
	t.assert_true(not _has_event(events, "dynamic_drop_spawn"), "timed dynamic spawn should be disabled")
	t.assert_true(state.dynamic_drops_spawned == 0, "timed dynamic spawn should not update accounting")
	var targets = ObjectiveIndicatorSystemScript.new().targets_for_state(state, 20)
	t.assert_true(not _targets_have_dynamic_drop(targets, state), "no timed dynamic target should be added")

func test_forced_drop_never_expires(t) -> void:
	var state = _state()
	var system = FieldDropSpawnSystemScript.new()
	var events: Array = []
	var drop = system.force_spawn(state, "heal_ore", events)
	state.elapsed_seconds += 9999.0
	system.process(state, 0.1, events)
	t.assert_true(not bool(drop.get("expired", false)), "uncollected forced drop should never expire")
	t.assert_true(not bool(drop.get("collected", false)), "uncollected forced drop should remain until pickup")
	t.assert_true(not _has_event(events, "dynamic_drop_expired"), "expiration should not emit an event")

func _has_event(events: Array, type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == type:
			return true
	return false

func _targets_have_dynamic_drop(targets: Array, state) -> bool:
	for drop in state.field_drops:
		if not bool(drop.get("dynamic", false)):
			continue
		for target in targets:
			if String(target.get("label", "")) == String(drop.get("name_ja", "")):
				return true
	return false
