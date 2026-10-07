extends RefCounted

const Choice = preload("res://scripts/ui/components/SettingsChoiceOption.gd")

func run(t) -> void:
	var choice = Choice.new()
	choice.setup("エフェクト量", "effect_density", "minimal", ["minimal", "low"], {"minimal": "極限軽量", "low": "少なめ"})
	t.assert_true(choice.option_button is OptionButton, "multi-choice setting must use OptionButton")
	t.assert_eq(choice.option_button.get_item_text(0), "極限軽量", "choice popup must use Japanese labels")
	choice.free()
