extends RefCounted

const FilterScript = preload("res://scripts/systems/CollectionFilterSystem.gd")

func run(t) -> void:
	var system = FilterScript.new()
	var rows = [
		{"id": "a", "unlocked": true, "secret": false, "tags": ["melee", "crystal"], "evolvable": true, "evolved": false, "highest_level": 8, "acquired_count": 20},
		{"id": "b", "unlocked": false, "secret": true, "tags": ["ranged", "poison"], "evolvable": false, "evolved": false, "highest_level": 0, "acquired_count": 0}
	]
	t.assert_eq(system.filter_rows(rows, "unlocked").size(), 1, "unlocked filter must work")
	t.assert_eq(system.filter_rows(rows, "locked").size(), 1, "locked filter must work")
	t.assert_eq(system.filter_rows(rows, "secret").size(), 1, "secret filter must work")
	t.assert_eq(system.filter_rows(rows, "melee").size(), 1, "tag filter must work")
	t.assert_eq(system.filter_rows(rows, "evolvable").size(), 1, "evolvable filter must work")
	t.assert_true(system.FILTER_IDS.has("currency") and system.FILTER_IDS.has("not_evolved"), "required collection filters must exist")
