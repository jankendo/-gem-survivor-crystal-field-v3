extends RefCounted

const Settlement = preload("res://scripts/systems/RunSettlementSystem.gd")

func run(t) -> void:
	var system = Settlement.new()
	t.assert_true(system.begin(true), "first settlement must be accepted")
	t.assert_true(not system.begin(true), "second settlement must be rejected")
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	game.state.debug_exp_multiplier = 2.0
	game.state.allow_debug_progress = false
	var summaries: Array = []
	game.game_finished.connect(func(summary): summaries.append(summary))
	game._request_manual_run_exit()
	game._request_manual_run_exit()
	t.assert_eq(summaries.size(), 1, "manual exit integration must emit one result")
	t.assert_eq(summaries[0].get("end_reason"), "manual_exit", "manual exit integration must decorate result")
	game.free()
