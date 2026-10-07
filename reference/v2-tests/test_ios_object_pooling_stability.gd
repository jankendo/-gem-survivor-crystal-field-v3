extends RefCounted

const PoolScript = preload("res://scripts/systems/PoolManager.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var pool = PoolScript.new()
	pool.register("effect", func(): return {"life": 0.0, "owner": ""}, func(value, args): value.merge({"life": args[0], "owner": args[1]}, true), 4)
	pool.prewarm("effect", 2)
	var first = pool.acquire("effect", [1.0, "a"])
	pool.release("effect", first)
	var second = pool.acquire("effect", [2.0, "b"])
	t.assert_true(first == second, "pooled effect should be reused")
	t.assert_eq(second.owner, "b", "reused objects must reset owner state")
	t.assert_eq(second.life, 2.0, "reused objects must reset lifetime")
	var report: Dictionary = pool.health_report().effect
	t.assert_true(int(report.reused) > 0, "reuse count should increase")
	t.assert_true(int(report.active) <= int(report.peak_active), "active count must remain bounded")
	var state = StateScript.new()
	state.start_new_run(99)
	var enemy = state.acquire_enemy(["slime", state.enemy_defs.slime, Vector2(10, 20), 0, 1.0])
	state.release_runtime("enemy", enemy)
	var reused_enemy = state.acquire_enemy(["bat", state.enemy_defs.bat, Vector2(30, 40), 0, 1.0])
	t.assert_true(enemy == reused_enemy and reused_enemy.type == "bat", "enemy pool should reuse and reset enemy state")
	var projectile = state.acquire_projectile(["bolt", Vector2.ZERO, Vector2.RIGHT, 3, 0, 1.0, 8.0, 0.0, false])
	state.release_runtime("projectile", projectile)
	var reused_projectile = state.acquire_projectile(["laser", Vector2.ONE, Vector2.DOWN, 9, 1, 2.0, 6.0, 12.0, true])
	t.assert_true(projectile == reused_projectile and reused_projectile.kind == "laser" and reused_projectile.hit_targets.is_empty(), "projectile pool should clear hit state")
	var gem = state.acquire_gem([Vector2(4, 5), 3])
	gem.attracting = true
	state.release_runtime("gem", gem)
	var reused_gem = state.acquire_gem([Vector2(8, 9), 7])
	t.assert_true(gem == reused_gem and not reused_gem.attracting and reused_gem.value == 7, "gem pool should clear attraction state")
