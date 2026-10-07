extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const KnockbackScript = preload("res://scripts/systems/KnockbackResolver.gd")

func _initialize() -> void:
	var state = StateScript.new()
	state.start_new_run(881606, "auto-knockback-wall")
	var enemy = state.acquire_enemy(["slime", state.enemy_defs.get("slime", {}), state.player_position + Vector2(96, 0), 0, 1.0])
	state.enemies.append(enemy)
	var resolver = KnockbackScript.new()
	var events: Array = []
	for i in range(6000):
		var direction := Vector2.RIGHT.rotated(float(i) * 0.07)
		resolver.apply(state, enemy, direction, 42.0, events, "auto_knockback")
		if not state.is_walkable_position(enemy.position, enemy.radius):
			push_error("knockback autoplay pushed enemy outside walkable map")
			quit(1)
	print("AutoPlay Knockback OK: 10min equivalent wall pressure.")
	quit(0)
