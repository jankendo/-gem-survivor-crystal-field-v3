extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(7102)
	state.configure_render_profile("ios_low", false)
	for index in range(state.max_gems() + 25):
		state.gems.append({"id": index})
	var before_hash: int = state.gems.hash()
	state.trim_runtime_arrays()
	t.assert_eq(state.gems.size(), state.max_gems() + 25, "visual profile must not remove simulation gems")
	t.assert_eq(state.gems.hash(), before_hash, "gem ordering and contents must remain unchanged")
