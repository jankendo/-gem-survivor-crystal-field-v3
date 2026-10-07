extends RefCounted

const NotificationLogSystemScript = preload("res://scripts/systems/NotificationLogSystem.gd")

func run(t) -> void:
	var log = NotificationLogSystemScript.new()
	log.configure({"notification_log_enabled": true})
	for i in range(60):
		log.ingest({"type": "room_discovered", "name": "部屋%d" % i}, float(i))
	t.assert_eq(log.entries.size(), 5, "visible notifications should be capped at five")
	t.assert_eq(log.history.size(), 50, "notification history should be capped at fifty")
	t.assert_true(log.history_text().find("部屋59") >= 0, "history should retain newest notification")
	log.tick(8.0)
	t.assert_eq(log.entries.size(), 0, "visible notifications should expire")

