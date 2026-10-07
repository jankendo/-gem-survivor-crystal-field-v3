extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const FieldEventSystemScript = preload("res://scripts/systems/FieldEventSystem.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9109)
	state.elapsed_seconds = 260.0
	var system = FieldEventSystemScript.new()
	var events: Array = []
	system.force_start(state, "gem_storm", events)
	t.assert_eq(String(state.active_field_event.get("id", "")), "gem_storm", "field event should start")
	t.assert_true(state.enemy_spawn_multiplier() > 1.0, "gem storm should carry risk through spawn multiplier")
	system.process(state, 999.0, events)
	t.assert_true(state.active_field_event.is_empty(), "field event should end")
	var before = state.crystal_walls.size()
	system.force_start(state, "crystal_surge", events)
	t.assert_true(state.crystal_walls.size() > before, "crystal surge should add reward crystals")

