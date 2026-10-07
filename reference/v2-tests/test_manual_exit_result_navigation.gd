extends RefCounted

func run(t) -> void:
	var game_source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/ui/Main.gd")
	t.assert_true(game_source.contains("game_finished.emit(run_settlement_system.decorate_summary"), "manual exit must use the result signal")
	t.assert_true(not main_source.contains("game.title_requested.connect(show_title)"), "game must not bypass result navigation")
