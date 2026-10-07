extends RefCounted
class_name AutoplayDriver
# Shared reproducible QA input policy; never changes HP, spawn or RNG.
var scratch:=QueryBuffer.new(600)
func direction(run: RunController,build: String="balanced") -> Vector2:
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
  if run.enemies.warning[i]<=0: continue
  var endangered:=false
  if run.enemies.flags[i]&1:
   endangered=run.enemies.attack_target[i].distance_to(run.state.player.position)<float(run.db.config().boss_attack_radius)+30
  else:
   var nearest:=Geometry2D.get_closest_point_to_segment(run.state.player.position,run.enemies.positions[i],run.enemies.attack_target[i])
   endangered=nearest.distance_to(run.state.player.position)<run.enemies.radius[i]+40
  if endangered:
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
 return direction
func choice(run: RunController) -> int:
 var best:=0
 var score:=-1.0
 for k in range(run.state.progression.choices.size()):
  var candidate: Array=run.state.progression.choices[k]
  var value:=50.0
  if candidate[0]=="weapons": value=100.0+float(run.state.progression.weapons.get(candidate[1],0))*8.0
  if candidate[1] in ["regen","armor"]: value=120.0
  if value>score: score=value; best=k
 return best
