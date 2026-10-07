extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const PickupScript = preload("res://scripts/systems/FieldEquipmentPickupSystem.gd")

func run(t) -> void:
	test_invalid_pickup_converts_to_score(t)
	test_unlocked_over_cap_pickup_accepts(t)

func test_invalid_pickup_converts_to_score(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771609, "invalid-field-equipment")
	state.field_equipment = [{
		"runtime_id": "invalid_locked_weapon",
		"kind": "weapon",
		"id": "laser_lance",
		"name_ja": "武器：レーザーランス",
		"position": state.player_position,
		"radius": 34.0,
		"collected": false
	}]
	var before_score = state.score
	var events: Array = []
	PickupScript.new().process(state, 0.1, events)
	t.assert_true(state.field_equipment[0].get("collected", false), "invalid field equipment should be collected as conversion")
	t.assert_true(state.score > before_score, "invalid field equipment should award score")
	t.assert_true(state.pending_field_equipment_choice.is_empty(), "invalid field equipment should not leave a stuck choice")
	t.assert_true(_has_event(events, "field_equipment_converted"), "conversion event should be emitted")

func test_unlocked_over_cap_pickup_accepts(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771610, "overcap-field-equipment")
	state.weapons = {
		"magic_bolt": 1,
		"ice_orbit": 1,
		"thunder_chain": 1,
		"bomb_seed": 1,
		"poison_mist": 1
	}
	state.field_equipment = [{
		"runtime_id": "valid_overcap_weapon",
		"kind": "weapon",
		"id": "blade_fan",
		"name_ja": "武器：ブレードファン",
		"position": state.player_position,
		"radius": 34.0,
		"allow_over_cap": true,
		"collected": false
	}]
	var pickup = PickupScript.new()
	var events: Array = []
	pickup.process(state, 0.1, events)
	t.assert_true(state.level_up_pending, "valid field equipment should open a responsive choice")
	t.assert_true(pickup.accept_current(state, String(state.level_up_options[0].get("uid", "")), events), "valid field equipment should accept by uid")
	t.assert_true(state.weapons.has("blade_fan"), "over-cap field equipment should be granted")
	t.assert_true(state.weapons.size() >= 6, "field equipment should allow sixth weapon")
	t.assert_true(state.pending_field_equipment_choice.is_empty(), "field equipment choice should close after accept")

func _has_event(events: Array, event_type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == event_type:
			return true
	return false
