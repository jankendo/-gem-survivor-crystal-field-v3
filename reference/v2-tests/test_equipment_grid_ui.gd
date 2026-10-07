extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const GridScript = preload("res://scripts/ui/components/EquipmentGridView.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771613, "equipment-grid")
	var grid = GridScript.new()
	grid._ready()
	grid.build_from_state(state, "weapon", 4)
	t.assert_true(grid.grid != null and grid.grid.columns == 4, "equipment grid should use GridContainer columns")
	t.assert_true(grid.grid.get_child_count() > 0, "equipment grid should create icon cells")
	t.assert_true(grid.detail_sheet != null, "equipment grid should expose a detail sheet")
	t.assert_true(grid.stats_panel != null, "equipment grid should expose stats panel")
	grid.active_filter = "unlocked"
	grid._rebuild_cells()
	t.assert_true(grid.grid.get_child_count() >= state.unlocked_weapon_ids.size(), "unlocked filter should show unlocked weapons")
	grid.free()
