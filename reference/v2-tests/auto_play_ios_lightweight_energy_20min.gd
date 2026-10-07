extends SceneTree

const DefaultsScript = preload("res://scripts/systems/IosDefaultSettingsSystem.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

var failures: Array = []

func _initialize() -> void:
	var settings = DefaultsScript.new().apply_defaults({}, "iOS")
	var optimizer = OptimizerScript.new()
	optimizer.configure(settings)
	var state = StateScript.new()
	state.start_new_run(881606, "ios-lightweight")
	state.elapsed_seconds = 1200.0
	state.enemies.resize(80)
	state.projectiles.resize(40)
	state.hit_flashes.resize(12)
	_assert(int(optimizer.budget.get("target_fps", 0)) == 30, "iOS lightweight should use 30 fps budget")
	_assert(bool(settings.get("battery_saver", false)), "iOS lightweight should keep battery saver on")
	_assert(optimizer.estimated_power_risk(optimizer.energy_score(state, null)) != "high", "20min equivalent lightweight estimate should avoid high risk")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay iOS lightweight energy OK: 20min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
