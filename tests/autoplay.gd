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
  var scratch := QueryBuffer.new(600)
  var boss_times: Dictionary={}
  var start := Time.get_ticks_usec()
  while run.state.tick < 60000 and run.state.phase != "CLEAR" and run.state.phase != "RESULT":
   if run.state.phase=="CONTRACT":
    run.pending_contract = ""
    run.state.phase = "RUNNING"
   if run.state.phase=="LEVEL_UP":
    var best := 0
    var score := -1.0
    for k in range(run.state.progression.choices.size()):
     var choice: Array = run.state.progression.choices[k]
     var value := 50.0
     if choice[0]=="weapons": value = 100.0+float(run.state.progression.weapons.get(choice[1],0))*8.0
     if choice[1] in ["regen","armor"]: value = 120.0
     if value>score:
      score=value
      best=k
    run.select(best)
    continue
   var target := run.spatial.query_nearest(SpatialWorld.GEM,run.state.player.position,900,scratch)
   var destination := run.map.rooms[(run.state.tick/1800)%run.map.rooms.size()].get_center()
   if target>=0 and run.gems.active[target]: destination = run.gems.positions[target]
   var boss_slot := -1
   for n in range(run.enemies.count):
    var i := run.enemies.dense[n]
    if run.enemies.flags[i]&1:
     boss_slot=i
     var away: Vector2 = (run.state.player.position-run.enemies.positions[i]).normalized()
     if away==Vector2.ZERO: away=Vector2.RIGHT
     var desired := 230.0
     if build=="close_range":
      desired=100
      for stat in run.weapons.stats: desired=maxf(desired,minf(140,float(stat.radius)*.85))
     destination = run.map.safe_position(run.enemies.positions[i]+away*desired)
     # Projection near a narrow wall must not choose a point inside boss contact.
     if destination.distance_to(run.enemies.positions[i])<run.enemies.radius[i]+24:
      for angle in range(8):
       var point := run.enemies.positions[i]+away.rotated(angle*TAU/8)*desired
       if run.map.walkable(point,14):
        destination=point
        break
     break
   var waypoint := run.map.pursuit_target(run.state.player.position,destination)
   var direction := (waypoint-run.state.player.position).normalized()
   # Choose one critical warning; a later dash warning must not overwrite a boss dodge.
   var warning_slot := -1
   for n in range(run.enemies.count):
    var i := run.enemies.dense[n]
    if run.enemies.warning[i]>0 and run.enemies.attack_target[i].distance_to(run.state.player.position)<240:
     if warning_slot<0: warning_slot=i
     if run.enemies.flags[i]&1:
      warning_slot=i
      break
   if warning_slot>=0:
    direction=(run.state.player.position-run.enemies.attack_target[warning_slot]).normalized()
    if direction==Vector2.ZERO: direction=Vector2.RIGHT
    var best_clearance := -1.0
    for candidate in range(8):
     var escape := Vector2.RIGHT.rotated(candidate*TAU/8)
     var point := run.state.player.position+escape*140
     if run.map.walkable(point,14) and run.map.walkable(run.state.player.position+escape*35,14) and run.map.walkable(run.state.player.position+escape*70,14) and run.map.walkable(run.state.player.position+escape*105,14):
      var clearance := point.distance_squared_to(run.enemies.attack_target[warning_slot])
      if boss_slot>=0:
       var nearest:=Geometry2D.get_closest_point_to_segment(run.enemies.positions[boss_slot],run.state.player.position,point)
       if nearest.distance_to(run.enemies.positions[boss_slot])<run.enemies.radius[boss_slot]+24 and escape.dot((run.enemies.positions[boss_slot]-run.state.player.position).normalized())>0: continue
      if clearance>best_clearance:
       best_clearance=clearance
       direction=escape
   if boss_slot>=0:
    var boss_position: Vector2=run.enemies.positions[boss_slot]
    var next_position: Vector2=run.map.move(run.state.player.position,direction*run.state.player.speed/60)
    if next_position.distance_to(boss_position)<run.enemies.radius[boss_slot]+24:
     var clearance := -1.0
     for candidate in range(8):
      var escape:=Vector2.RIGHT.rotated(candidate*TAU/8)
      var point: Vector2=run.map.move(run.state.player.position,escape*run.state.player.speed/60)
      var distance:=point.distance_squared_to(boss_position)
      if distance>clearance:
       clearance=distance
       direction=escape
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
