extends SceneTree

func _initialize() -> void:
	var state = preload("res://scripts/core/SurvivorState.gd").new()
	var spawner = preload("res://scripts/systems/EnemySpawner.gd").new()
	var alert = preload("res://scripts/systems/BossAlertSystem.gd").new()
	var log = preload("res://scripts/systems/NotificationLogSystem.gd").new()
	state.start_new_run(551199, "autoplay-boss-alert")
	var events: Array = []
	state.elapsed_seconds = 295.0
	spawner._process_boss_schedule(state, events)
	for event in events:
		alert.ingest(event)
		log.ingest(event, state.elapsed_seconds)
	if alert.warning_timer != 5.0 or log.history.is_empty():
		push_error("Boss alert autoplay failed warning/log phase")
		quit(1)
	events.clear()
	state.elapsed_seconds = 300.0
	spawner._process_boss_schedule(state, events)
	for event in events:
		alert.ingest(event)
		log.ingest(event, state.elapsed_seconds)
	if not state.boss_alive():
		push_error("Boss alert autoplay failed boss spawn phase")
		quit(1)
	state.elapsed_seconds = 600.0
	print("AutoPlay OK: boss warning, minimap target, HP source and notification history.")
	quit(0)

