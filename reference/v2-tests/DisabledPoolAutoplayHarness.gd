extends RefCounted
class_name DisabledPoolAutoplayHarness

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelScript = preload("res://scripts/systems/LevelUpSystem.gd")
const ChestScript = preload("res://scripts/systems/ChestSystem.gd")
const DropScript = preload("res://scripts/systems/FieldDropSystem.gd")
const ContractScript = preload("res://scripts/systems/RuneContractSystem.gd")

func run(tree: SceneTree, output_path: String) -> Array:
	var failures: Array = []
	var state = StateScript.new()
	state.start_new_run(77123, "disabled-pool")
	state.max_hp = 999999
	state.hp = 999999
	state.unlocked_weapon_ids = state.weapon_defs.keys()
	state.unlocked_passive_ids = state.passive_defs.keys()
	state.disabled_weapon_ids = ["ice_orbit", "blade_fan"]
	state.disabled_passive_ids = ["regen", "greed"]
	var level_system = LevelScript.new()
	var chest_system = ChestScript.new()
	var drop_system = DropScript.new()
	var selections := 0
	var events: Array = []
	for tick in range(120):
		state.elapsed_seconds += 5.0
		state.level_up_options = level_system.prepare_options(state, 3)
		state.level_up_pending = not state.level_up_options.is_empty()
		for option in state.level_up_options:
			if String(option.get("id", "")) in state.disabled_weapon_ids + state.disabled_passive_ids:
				failures.append("disabled item appeared in the live candidate pool")
				break
		if state.level_up_pending:
			level_system.apply_option(state, String(state.level_up_options[0].get("uid", "")), events)
			selections += 1
		if tick % 12 == 0:
			chest_system.open_chest(state, events, "golden")
		if tick % 20 == 0:
			drop_system._apply_weapon_core(state)
			drop_system._apply_passive_core(state)
	if state.elapsed_seconds < 600.0:
		failures.append("disabled-pool autoplay did not reach ten minutes")
	if selections <= 0:
		failures.append("disabled-pool autoplay never produced a level-up choice")
	if state.weapons.has("ice_orbit") or state.weapons.has("blade_fan"):
		failures.append("disabled weapon was acquired")
	if state.passives.has("regen") or state.passives.has("greed"):
		failures.append("disabled passive was acquired")
	if ContractScript.new().make_offer(state, 3).is_empty():
		failures.append("contract reward pool became unavailable")
	var absolute := ProjectSettings.globalize_path(output_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({
			"elapsed_seconds": state.elapsed_seconds,
			"selections": selections,
			"weapons": state.weapons,
			"passives": state.passives,
			"evolutions": state.evolved_weapons,
			"chests_opened": state.chests_opened,
			"contracts": state.rune_contracts,
			"disabled_weapons": state.disabled_weapon_ids,
			"disabled_passives": state.disabled_passive_ids
		}, "\t"))
	await tree.process_frame
	return failures
