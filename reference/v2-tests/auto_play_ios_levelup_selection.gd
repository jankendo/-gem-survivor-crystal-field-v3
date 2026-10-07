extends SceneTree

const RuneContractSystemScript = preload("res://scripts/systems/RuneContractSystem.gd")

var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	if failures.is_empty():
		print("AutoPlay iOS Touch OK: level-up, contract decline card, chest confirm and evolution card selection.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "touch_tutorial_seen": true})
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.level_up_options = game.level_up_system.prepare_options(game.state, 3)
	game.state.level_up_pending = true
	game._refresh()
	var before_level: int = game.state.level
	game.reward_popup.selection.select_index(0)
	_assert(not game.state.level_up_pending, "touch card should resolve level-up selection")
	_assert(game.state.level == before_level, "reward selection should not corrupt level state")

	var events: Array = []
	var contracts = RuneContractSystemScript.new()
	_assert(contracts.offer_after_boss(game.state, events), "contract offer should open")
	game._refresh()
	_assert(not game.reward_popup.selection.request_skip(), "level-up skip action should be disabled during contract selection")
	_assert(game.state.rune_contract_pending, "contract selection should remain open after disabled skip action")
	_assert(game.reward_popup.selection.select_id("contract_skip:skip"), "contract decline card should be tappable")
	_assert(not game.state.rune_contract_pending, "contract decline card should close contract selection")

	game.state.chest_pending = true
	game.state.chest_timer = 2.0
	game._refresh_touch_controls()
	_assert(game.touch_chest_button.visible, "chest should expose touch confirm")
	game._on_touch_action_started("action_confirm")
	_assert(not game.state.chest_pending, "touch confirm should close chest result")

	game.state.level_up_options = [{
		"uid": "overclock:magic_bolt:power",
		"kind": "overclock",
		"id": "power",
		"weapon": "magic_bolt",
		"name_ja": "魔弾過充電",
		"description_ja": "威力を上げる",
		"type_label": "過充電"
	}]
	game.state.level_up_pending = true
	game._refresh()
	_assert(game.reward_popup.selection.select_index(0) != "", "overclock card should be tappable")
	game.queue_free()
	await process_frame

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
