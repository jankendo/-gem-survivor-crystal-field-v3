extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(7101)
	state.configure_render_profile("ios_low", false)
	for index in range(state.max_projectiles() + 25):
		state.projectiles.append({"id": index})
	var before_hash: int = state.projectiles.hash()
	state.trim_runtime_arrays()
	t.assert_eq(state.projectiles.size(), state.max_projectiles() + 25, "visual profile must not remove simulation projectiles")
	t.assert_eq(state.projectiles.hash(), before_hash, "projectile ordering and contents must remain unchanged")
