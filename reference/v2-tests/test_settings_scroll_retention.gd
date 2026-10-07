extends RefCounted

const ScrollState = preload("res://scripts/ui/settings/SettingsScrollState.gd")

func run(t) -> void:
	var scroll := ScrollContainer.new()
	scroll.scroll_vertical = 123
	var expected := scroll.scroll_vertical
	var state = ScrollState.new()
	state.capture(scroll)
	scroll.scroll_vertical = 0
	state.restore(scroll)
	t.assert_eq(scroll.scroll_vertical, expected, "settings scroll position must be restored")
	scroll.free()
