extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const RewardScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")

func run(t) -> void:
	test_generated_equipment_is_unlocked_and_enabled(t)
	test_sanitize_replaces_disabled_equipment(t)

func test_generated_equipment_is_unlocked_and_enabled(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771607, "unlocked-field-equipment")
	t.assert_true(state.field_equipment.size() > 0, "field equipment should be generated")
	for equipment in state.field_equipment:
		var kind = String(equipment.get("kind", "weapon"))
		var id = String(equipment.get("id", ""))
		if kind == "weapon":
			t.assert_true(state.unlocked_weapon_ids.has(id), "field weapon should be unlocked: %s" % id)
			t.assert_true(not state.disabled_weapon_ids.has(id), "field weapon should not be disabled: %s" % id)
		else:
			t.assert_true(state.unlocked_passive_ids.has(id), "field passive should be unlocked: %s" % id)
			t.assert_true(not state.disabled_passive_ids.has(id), "field passive should not be disabled: %s" % id)
		t.assert_true(not state.run_sealed_option_uids.has("%s:%s" % [kind, id]), "field equipment should not be run-sealed: %s:%s" % [kind, id])

func test_sanitize_replaces_disabled_equipment(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771608, "sanitize-field-equipment")
	var target = _first_weapon_equipment(state)
	t.assert_true(not target.is_empty(), "test should find a field weapon")
	var disabled_id = String(target.get("id", ""))
	state.disabled_weapon_ids.append(disabled_id)
	var result: Dictionary = RewardScript.new().sanitize_for_state(state)
	t.assert_true(int(result.get("replaced", 0)) + int(result.get("conversion_only", 0)) >= 1, "sanitize should handle disabled field equipment")
	for equipment in state.field_equipment:
		if String(equipment.get("kind", "")) == "weapon" and not bool(equipment.get("invalid_conversion_only", false)):
			t.assert_true(String(equipment.get("id", "")) != disabled_id, "disabled field weapon should not remain claimable")

func _first_weapon_equipment(state) -> Dictionary:
	for equipment in state.field_equipment:
		if String(equipment.get("kind", "")) == "weapon":
			return equipment
	return {}
