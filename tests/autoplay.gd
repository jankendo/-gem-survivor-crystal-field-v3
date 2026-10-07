extends SceneTree
func _initialize() -> void: call_deferred("autoplay")
func autoplay() -> void:
 var db := GameDatabase.new()
 var builds := {"balanced":["magic_bolt","thunder_chain","bomb_seed","laser_lance","might","cooldown","area","regen","armor","elite_hunter"],"close_range":["ice_orbit","blade_fan","poison_mist","sonic_wave","might","cooldown","area","regen","armor","magnet"]}
 var reports: Array = []
 for build in builds:
  var run := RunController.new(db,60606,"noah",builds[build])
  var scratch := QueryBuffer.new(600)
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
   for n in range(run.enemies.count):
    var i := run.enemies.dense[n]
    if run.enemies.flags[i]&1:
     var away: Vector2 = (run.state.player.position-run.enemies.positions[i]).normalized()
     if away==Vector2.ZERO: away=Vector2.RIGHT
     destination = run.map.safe_position(run.enemies.positions[i]+away*(160.0 if build=="close_range" else 230.0))
     break
   var waypoint := run.map.pursuit_target(run.state.player.position,destination)
   var direction := (waypoint-run.state.player.position).normalized()
   # Dodge locked boss telegraphs using the same observable simulation warnings.
   for n in range(run.enemies.count):
    var i := run.enemies.dense[n]
    if run.enemies.warning[i]>0 and run.enemies.attack_target[i].distance_to(run.state.player.position)<150:
     direction = (run.state.player.position-run.enemies.attack_target[i]).normalized()
     if direction==Vector2.ZERO: direction = Vector2.RIGHT
     var best_clearance := -1.0
     for candidate in range(8):
      var escape := Vector2.RIGHT.rotated(candidate*TAU/8)
      var point := run.state.player.position+escape*140
      if run.map.walkable(point,14):
       var clearance := point.distance_squared_to(run.enemies.attack_target[i])
       if clearance>best_clearance:
        best_clearance=clearance
        direction=escape
   if run.state.tick%120==0: run.interact()
   run.pipeline.tick(run,direction)
  reports.append({"build":build,"seed":60606,"phase":run.state.phase,"seconds":run.state.field_tick/60.0,"HP":run.state.player.hp,"last_damage_source":run.state.last_damage_source,"level":run.state.progression.level,"kills":run.state.progression.kills,"bosses":run.state.progression.bosses,"weapons":run.state.progression.weapons,"evolutions":run.state.progression.evolutions,"damage":run.damage.totals,"signature":run.signature(),"wall_seconds":(Time.get_ticks_usec()-start)/1e6})
  print("autoplay finished ",build)
 var report := {"ok":true,"runs":reports,"note":"Deterministic scripted autoplayer with normal HP and progression. Clearing is measured, not assumed; this does not certify human fun."}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/autoplay.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit()
