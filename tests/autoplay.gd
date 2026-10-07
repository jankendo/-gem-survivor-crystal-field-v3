extends SceneTree
func _initialize() -> void: call_deferred("autoplay")
func autoplay() -> void:
 var db := GameDatabase.new()
 var builds := {"balanced":["magic_bolt","thunder_chain","bomb_seed","laser_lance","might","cooldown","area","regen","armor","elite_hunter"],"close_range":["ice_orbit","blade_fan","poison_mist","sonic_wave","might","cooldown","area","regen","armor","magnet"]}
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--build="):
   var chosen:=arg.get_slice("=",1)
   for id in builds.keys():
    if id!=chosen: builds.erase(id)
 var reports: Array = []
 for build in builds:
  var run := RunController.new(db,60606,"mio" if build=="close_range" else "noah",builds[build])
  var driver:=AutoplayDriver.new()
  var boss_times: Dictionary={}
  var start := Time.get_ticks_usec()
  while run.state.tick < 60000 and run.state.phase != "CLEAR" and run.state.phase != "RESULT":
   if run.state.phase=="CONTRACT":
    run.resolve_contract(false)
   if run.state.phase=="LEVEL_UP":
    run.select(driver.choice(run))
    continue
   var direction:=driver.direction(run,build)
   if run.state.tick%120==0: run.interact()
   run.pipeline.tick(run,direction)
   for n in range(run.enemies.count):
    var i:=run.enemies.dense[n]
    if run.enemies.types[i]<0:
     var id:=run.enemies.entity_id(i)
     if not boss_times.has(id): boss_times[id]={"stage":-run.enemies.types[i],"spawn_tick":run.state.field_tick,"HP":run.enemies.max_hp[i],"player_hp_at_spawn":run.state.player.hp}
   for id in boss_times:
    if not run.enemies.alive(id) and not boss_times[id].has("TTK_seconds"): boss_times[id].TTK_seconds=(run.state.field_tick-int(boss_times[id].spawn_tick))/60.0
  reports.append({"passives":run.state.progression.passives,"overclocks":run.state.progression.named_overclocks,"boss_timings":boss_times.values(),"build":build,"seed":60606,"phase":run.state.phase,"seconds":run.state.field_tick/60.0,"HP":run.state.player.hp,"last_damage_source":run.state.last_damage_source,"level":run.state.progression.level,"kills":run.state.progression.kills,"bosses":run.state.progression.bosses,"weapons":run.state.progression.weapons,"evolutions":run.state.progression.evolutions,"damage":run.damage.totals,"signature":run.signature(),"wall_seconds":(Time.get_ticks_usec()-start)/1e6})
  print("autoplay finished ",build)
 var gate_ok: bool = not reports.is_empty() and reports.size()==builds.size()
 for report in reports: gate_ok=gate_ok and report.phase=="CLEAR"
 var report := {"ok":gate_ok,"runs":reports,"note":"Deterministic scripted autoplayer with normal HP and progression. Clearing is measured, not assumed; this does not certify human fun."}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/autoplay.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if gate_ok else 1)
