extends RefCounted

func run(t) -> void:
	test_first_time_help_flow(t)
	test_title_h_reopens_help(t)

func test_first_time_help_flow(t) -> void:
	var save := SaveSystem.new()
	save.save_help_seen(false)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.show_title()
	main.request_start()
	t.assert_true(main.help_visible, "first Enter should show help before game")
	main.accept_help()
	t.assert_true(save.load_help_seen(), "accepting help should save seen flag")
	t.assert_true(main.current_screen is GameScreen, "Enter on help should start Endless")
	main.free()

	var second: Node = load("res://scenes/Main.tscn").instantiate()
	second.show_title()
	second.request_start()
	t.assert_true(second.current_screen is GameScreen, "second Enter should skip help")
	second.free()

func test_title_h_reopens_help(t) -> void:
	var save := SaveSystem.new()
	save.save_help_seen(true)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	main.show_title()
	main.show_help(false)
	t.assert_true(main.help_visible, "H from title should show help")
	main.accept_help()
	t.assert_true(main.title_visible, "Enter from manual help should return to title")
	main.free()
