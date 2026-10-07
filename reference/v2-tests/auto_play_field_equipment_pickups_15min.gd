extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const PickupScript = preload("res://scripts/systems/FieldEquipmentPickupSystem.gd")

var failures: Array = []

func _initialize() -> void:
	var state = StateScript.new()
	state.start_new_run(881605, "auto-field-equipment")
	var pickup = PickupScript.new()
	var events: Array = []
	var picked := 0
	for equipment in state.field_equipment:
		var kind := String(equipment.get("kind", "weapon"))
		var item_id := String(equipment.get("id", ""))
		if kind == "weapon":
			_assert(state.unlocked_weapon_ids.has(item_id) and not state.disabled_weapon_ids.has(item_id), "field autoplay found locked or disabled weapon")
		else:
			_assert(state.unlocked_passive_ids.has(item_id) and not state.disabled_passive_ids.has(item_id), "field autoplay found locked or disabled passive")
		if picked >= 3:
			break
		state.player_position = equipment.get("position", state.player_position)
		pickup.process(state, 0.1, events)
		if state.level_up_pending and not state.level_up_options.is_empty():
			pickup.accept_current(state, String(state.level_up_options[0].get("uid", "")), events)
			picked += 1
	_assert(state.field_equipment_collected >= 3, "15min equivalent should collect field equipment")
	_assert(state.reward_room_pickups >= 3, "field equipment should count as reward-room pickups")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay field equipment pickups OK: 15min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
