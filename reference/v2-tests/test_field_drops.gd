extends RefCounted

const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")

func run(t) -> void:
	test_drops_are_seed_reproducible(t)
	test_powerful_drops_avoid_start(t)
	test_drop_caps_hold(t)
	test_time_lock_prevents_early_pickup(t)

func _state(seed_text: String):
	var state = SurvivorState.new()
	state.start_new_run(0, seed_text)
	return state

func _drop_signature(state) -> String:
	var parts: Array = []
	for drop in state.field_drops:
		var p: Vector2 = drop.get("position", Vector2.ZERO)
		parts.append("%s:%d:%d" % [String(drop.get("id", "")), int(p.x), int(p.y)])
	return "|".join(parts)

func test_drops_are_seed_reproducible(t) -> void:
	var a = _state("drop-seed")
	var b = _state("drop-seed")
	t.assert_eq(_drop_signature(a), _drop_signature(b), "same seed should reproduce field drops")

func test_powerful_drops_avoid_start(t) -> void:
	var state = _state("drop-distance")
	var center = state.field_size * 0.5
	for drop in state.field_drops:
		if String(drop.get("id", "")) in ["weapon_core", "evolution_core", "overclock_core", "cursed_relic"]:
			var def: Dictionary = state.field_drop_defs.get(String(drop.get("id", "")), {})
			t.assert_true((drop.get("position", Vector2.ZERO) as Vector2).distance_to(center) >= float(def.get("min_distance", 1000.0)), "powerful drop should avoid start: %s" % String(drop.get("id", "")))

func test_drop_caps_hold(t) -> void:
	var state = _state("drop-caps")
	var counts = {}
	for drop in state.field_drops:
		var id = String(drop.get("id", ""))
		counts[id] = int(counts.get(id, 0)) + 1
	for id in state.field_drop_defs.keys():
		t.assert_true(int(counts.get(String(id), 0)) <= int(state.field_drop_defs[String(id)].get("max_per_run", 0)), "drop cap should hold for %s" % String(id))

func test_time_lock_prevents_early_pickup(t) -> void:
	var state = _state("drop-lock")
	var system = FieldDropSystemScript.new()
	var target = {}
	for drop in state.field_drops:
		if float(drop.get("unlock_seconds", 0.0)) >= 480.0:
			target = drop
			break
	t.assert_true(not target.is_empty(), "locked high value drop should exist")
	state.player_position = target.get("position", state.player_position)
	state.elapsed_seconds = 1.0
	system.process(state, 0.1, [])
	t.assert_true(not bool(target.get("collected", false)), "locked drop should not collect early")
	state.elapsed_seconds = float(target.get("unlock_seconds", 0.0)) + 1.0
	system.process(state, 0.1, [])
	t.assert_true(bool(target.get("collected", false)), "locked drop should collect after unlock")
