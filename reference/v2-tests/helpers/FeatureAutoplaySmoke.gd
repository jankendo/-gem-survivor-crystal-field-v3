extends RefCounted
class_name FeatureAutoplaySmoke

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const SelectionActionSystemScript = preload("res://scripts/systems/SelectionActionSystem.gd")
const FieldDropSpawnSystemScript = preload("res://scripts/systems/FieldDropSpawnSystem.gd")
const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")
const ResonanceMagnetSystemScript = preload("res://scripts/systems/ResonanceMagnetSystem.gd")
const RecallDroneSystemScript = preload("res://scripts/systems/RecallDroneSystem.gd")
const CharacterEvolutionSystemScript = preload("res://scripts/systems/CharacterEvolutionSystem.gd")

func run(kind: String) -> bool:
	match kind:
		"shop":
			return _shop()
		"exp":
			return _exp()
		"drop":
			return _drop()
		"field_equipment":
			return _field_equipment()
		"resonance":
			return _resonance()
		"magnet":
			return _magnet()
		"drone":
			return _drone()
		"character_evolution":
			return _character_evolution()
		"character_balance":
			return _character_evolution()
		"exp_curve":
			return _exp()
	return false

func _shop() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-levelup-reroll")
	var selection = SelectionActionSystemScript.new()
	selection.begin_run(state, {"currency_sink_levels": {"levelup_reroll_capacity": 2}, "stats": {}})
	state.level_up_pending = true
	return state.selection_reroll_max >= 3 and selection.consume_reroll(state, []) and state.selection_reroll_remaining == state.selection_reroll_max - 1

func _exp() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-exp")
	var base = state.get_gem_value_multiplier()
	state.debug_exp_multiplier = 5.0
	return state.normal_exp_balance_multiplier() >= 1.20 and state.get_gem_value_multiplier() > base * 4.9

func _drop() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-drop")
	var count = state.field_drops.size()
	state.elapsed_seconds = 1800.0
	FieldDropSpawnSystemScript.new().process(state, 1.0, [])
	return state.field_drops.size() == count and not bool(state.field_drops[0].get("expired", false))

func _field_equipment() -> bool:
	var a = SurvivorState.new()
	var b = SurvivorState.new()
	a.start_new_run(0, "auto-field-equipment-a")
	b.start_new_run(0, "auto-field-equipment-b")
	return not a.field_equipment.is_empty() and not b.field_equipment.is_empty() and str(a.field_equipment) != str(b.field_equipment)

func _resonance() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-resonance")
	state.passives["resonance_magnet_core"] = 1
	state.resonance_magnet_timer = 0.1
	_add_gems(state, 12)
	ResonanceMagnetSystemScript.new().process(state, 0.2, [])
	return state.gems.is_empty() and state.gems_collected_by_passive >= 12

func _magnet() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-magnet")
	state.gems.clear()
	_add_gems(state, 80)
	state.field_drops = [{"id": "magnet_ore", "position": state.player_position, "radius": 24.0, "collected": false}]
	FieldDropSystemScript.new().process(state, 0.1, [])
	return state.gems.is_empty() and state.gems_collected_by_magnet >= 80

func _drone() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-drone")
	state.gems.clear()
	_add_gems(state, 80)
	state.recall_drone_ready = true
	RecallDroneSystemScript.new().activate(state, [])
	return state.gems.is_empty() and state.gems_collected_by_drone >= 80

func _character_evolution() -> bool:
	var state = SurvivorState.new()
	state.start_new_run(0, "auto-character-evolution")
	state.character_evolution_unlocked_ids = ["noah"]
	state.level = 20
	state.elapsed_seconds = 601.0
	state.gems_collected = 300
	var system = CharacterEvolutionSystemScript.new()
	return system.apply_evolution(state, []) and state.character_evolved

func _add_gems(state, count: int) -> void:
	for i in range(count):
		state.gems.append(ExpGemScript.new(state.player_position + Vector2(120.0 + float(i % 20) * 8.0, float(i / 20) * 8.0), 5))
