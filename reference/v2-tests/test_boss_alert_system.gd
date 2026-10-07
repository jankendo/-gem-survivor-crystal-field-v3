extends RefCounted

const BossAlertSystemScript = preload("res://scripts/systems/BossAlertSystem.gd")

func run(t) -> void:
	var alert = BossAlertSystemScript.new()
	alert.ingest({"type": "boss_warning", "message": "ボス接近", "duration": 5.0, "pos": Vector2(100, 200)})
	t.assert_eq(alert.warning_timer, 5.0, "boss warning should last five seconds")
	t.assert_eq(alert.planned_position, Vector2(100, 200), "boss warning should retain minimap position")
	alert.tick(2.0)
	t.assert_eq(alert.warning_timer, 3.0, "boss warning timer should tick in real time")
	alert.ingest({"type": "boss_spawn"})
	t.assert_eq(alert.warning_timer, 0.0, "boss spawn should clear warning banner")

