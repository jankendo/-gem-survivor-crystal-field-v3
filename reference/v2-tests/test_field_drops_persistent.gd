extends RefCounted

const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")

func run(t) -> void:
	test_field_drops_never_despawn(t)
	test_field_drops_respawn_after_pickup(t)
	test_field_drops_persist_until_pickup(t)

func test_field_drops_never_despawn(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "persist-drop")
	var first = state.field_drops[0]
	state.elapsed_seconds = 9999.0
	FieldDropSpawnSystemScript.new().process(state, 1.0, [])
	t.assert_true(not bool(first.get("collected", false)), "field drop should not despawn by time")
	t.assert_true(not bool(first.get("expired", false)), "field drop should not expire by time")

func test_field_drops_respawn_after_pickup(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "persist-respawn")
	var target = _first_drop(state, "heal_ore")
	t.assert_true(not target.is_empty(), "heal ore fixture should exist")
	var count = state.field_drops.size()
	state.elapsed_seconds = float(target.get("unlock_seconds", 0.0)) + 1.0
	state.player_position = target.get("position", state.player_position)
	var events: Array = []
	FieldDropSystemScript.new().process(state, 0.1, events)
	t.assert_true(bool(target.get("collected", false)), "pickup should collect the drop")
	t.assert_true(state.field_drop_respawn_queue.size() > 0, "pickup should schedule a respawn")
	state.elapsed_seconds += 90.0
	FieldDropSpawnSystemScript.new().process(state, 0.3, events)
	t.assert_true(state.field_drops.size() > count, "scheduled consumable drop should respawn after pickup")

func test_field_drops_persist_until_pickup(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "persist-pickup")
	var drop = _first_drop(state, "heal_ore")
	t.assert_true(not drop.is_empty(), "heal ore persistence fixture should exist")
	state.elapsed_seconds = float(drop.get("unlock_seconds", 0.0)) + 1.0
	state.player_position = drop.get("position", state.player_position)
	FieldDropSystemScript.new().process(state, 0.1, [])
	t.assert_true(bool(drop.get("collected", false)), "field drop should disappear only after pickup")

func _first_drop(state, id: String) -> Dictionary:
	for drop in state.field_drops:
		if String(drop.get("id", "")) == id:
			return drop
	return {}
