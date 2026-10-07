extends RefCounted

func common_failures(metrics: Dictionary) -> Array:
	var failures: Array = []
	if float(metrics.get("elapsed", 0.0)) < 600.0:
		failures.append("category autoplay did not reach ten simulated minutes")
	if bool(metrics.get("game_over", false)):
		failures.append("category autoplay ended in game over before ten minutes")
	if int(metrics.get("kills", 0)) <= 0:
		failures.append("category autoplay did not defeat enemies")
	if int(metrics.get("damage", 0)) <= 0:
		failures.append("category autoplay did not record weapon damage")
	if int(metrics.get("enemy_count", 0)) > int(metrics.get("enemy_hard_budget", 700)):
		failures.append(
			"category autoplay exceeded the protected-spawn hard safety budget: enemies=%d soft_cap=%d hard_budget=%d"
			% [int(metrics.get("enemy_count", 0)), int(metrics.get("enemy_soft_cap", 0)), int(metrics.get("enemy_hard_budget", 700))]
		)
	if int(metrics.get("projectile_count", 0)) > 180:
		failures.append("category autoplay exceeded the projectile cap")
	var boss_minutes: Array = metrics.get("boss_minutes", [])
	if not boss_minutes.has(5) or not boss_minutes.has(10):
		failures.append("category autoplay did not process the 5 and 10 minute bosses")
	return failures

func finish(tree: SceneTree, category: String, metrics: Dictionary, extra_failures: Array = []) -> void:
	var failures = common_failures(metrics)
	failures.append_array(extra_failures)
	print("Balance AutoPlay [%s]: %s" % [category, str(metrics)])
	if failures.is_empty():
		print("Balance AutoPlay OK [%s]" % category)
		tree.quit(0)
		return
	for failure in failures:
		push_error("%s: %s" % [category, failure])
	tree.quit(1)
