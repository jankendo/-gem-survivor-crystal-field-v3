extends RefCounted

const DirtyScript = preload("res://scripts/systems/UiDirtyFlagSystem.gd")

func run(t) -> void:
	var dirty = DirtyScript.new()
	dirty.configure({"equipment": 0.20, "minimap": 0.25})
	t.assert_true(dirty.should_update("equipment", "a"), "first equipment update should run")
	t.assert_true(not dirty.should_update("equipment", "a"), "unchanged equipment must not update every frame")
	dirty.tick(0.21)
	t.assert_true(dirty.should_update("equipment", "a"), "equipment should refresh at its bounded interval")
	t.assert_true(dirty.should_update("minimap", "room1"), "first minimap update should run")
	t.assert_true(dirty.should_update("minimap", "room2"), "changed exploration state should refresh immediately")
