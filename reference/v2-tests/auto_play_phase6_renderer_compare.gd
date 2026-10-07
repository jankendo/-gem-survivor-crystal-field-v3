extends SceneTree

const Harness = preload("res://tests/Phase6BenchmarkHarness.gd")

func _initialize() -> void:
	var args := _args()
	var stem := String(args.get("stem", "res://test-output/phase6/renderer_compare"))
	var label := String(args.get("label", "Phase 6 renderer compare"))
	var summary: Dictionary = await Harness.new().run(self, 60.0, stem, label, 60606)
	if bool(summary.get("ok", false)):
		print("Phase 6 renderer benchmark OK: ", label)
		quit(0)
		return
	push_error(String(summary.get("error", "Phase 6 renderer benchmark failed")))
	quit(1)

func _args() -> Dictionary:
	var result := {}
	for arg in OS.get_cmdline_user_args():
		if not String(arg).begins_with("--"):
			continue
		var pair := String(arg).substr(2).split("=", false, 1)
		if pair.size() == 2:
			result[pair[0]] = pair[1]
	return result

