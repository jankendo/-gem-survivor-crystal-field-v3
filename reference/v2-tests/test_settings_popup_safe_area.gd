extends RefCounted

const Choice = preload("res://scripts/ui/components/SettingsChoiceOption.gd")

func run(t) -> void:
	var choice = Choice.new()
	choice.setup("利き手", "touch_handedness", "right", ["right", "left"], {"right": "右利き", "left": "左利き"})
	t.assert_true(choice.option_button.custom_minimum_size.y >= 52.0, "choice popup target must be touch safe")
	t.assert_true(choice.option_button.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "choice popup must fit responsive width")
	choice.free()
