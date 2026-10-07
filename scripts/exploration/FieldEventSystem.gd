extends RefCounted
class_name FieldEventSystem
var definition: Dictionary = {}
var deadline := 0
var start_crystals := 0
var start_elites := 0
var start_chests := 0
var danger_ticks := 0
var impact_tick := 0
var impact_position := Vector2.ZERO
var gem_multiplier := 1.0
var scratch := QueryBuffer.new(600)
func start(run: RunController,room: int,id: String = "") -> bool:
 if not run.field.event.is_empty() or room<0: return false
 var definitions: Array = run.db.table("field_events").events
 var rng = run.state.rng.stream_rng("field_event",str(run.state.field_tick)+":"+str(room))
 definition={}
 if id.is_empty(): definition=definitions[rng.next_int(definitions.size())]
 else:
  for d in definitions:
   if d.id==id: definition=d
 if definition.is_empty(): return false
 run.field.event=str(definition.id)
 run.field.event_room=room
 deadline=run.state.field_tick+roundi(float(definition.duration)*60)
 run.field.event_deadline=deadline
 start_crystals=run.field.crystals
 start_elites=run.state.progression.elite_kills
 start_chests=int(run.state.progression.metrics.get("total_chests",0))
 danger_ticks=0
 impact_tick=0
 gem_multiplier=1.65 if definition.id=="gem_storm" else 1.0
 run.encounter.event_refill_mult=1.3 if definition.id=="gem_storm" else 1.0
 if definition.id in ["crystal_surge","cursed_treasure"]:
  run.field.active[room]=1
  run.field.hp[room]=60
  run.field.kinds[room]="sealed_chest_pillar" if definition.id=="cursed_treasure" else "explosive_vein"
 if definition.id=="elite_hunt":
  var d: Dictionary=run.db.enemy_defs[0].duplicate()
  d.elite=true
  d.hp=float(d.hp)*2
  run.enemies.spawn(0,run.map.spawn_position(run.state.player.position,300,450,run.state.rng),d)
 return true
func tick(run: RunController) -> void:
 if run.field.event.is_empty(): return
 if run.state.phase=="RESULT":
  finish(run,false)
  return
 var kind: String=run.field.event
 if kind=="danger_bloom" and run.state.player.position.distance_to(run.map.rooms[run.field.event_room].get_center())<220:
  danger_ticks+=1
 if kind=="meteor_rain": meteor(run)
 var success := false
 match str(definition.success_type):
  "survive": success=run.state.field_tick>=deadline and run.state.player.hp>0
  "crystal_break": success=run.field.crystals-start_crystals>=int(definition.get("success_count",1))
  "elite_reward": success=run.state.progression.elite_kills>start_elites
  "danger_time": success=danger_ticks>=int(definition.get("success_count",10))*60
  "chest_open": success=int(run.state.progression.metrics.get("total_chests",0))>start_chests
 if success: finish(run,true)
 elif run.state.field_tick>=deadline: finish(run,false)
func finish(run: RunController,success: bool) -> void:
 if success:
  var p := run.state.progression
  p.currency+=roundi(100*(1+float(run.state.player.stats.get("event_reward",0))))
  run.gems.add(run.map.rooms[run.field.event_room].get_center(),80,run.map)
  run.field.events_completed+=1
  if definition.id in ["gem_storm","meteor_rain"]: p.skips+=1
  if definition.id=="elite_hunt": p.banishes_bonus+=1
  if definition.id=="danger_bloom": p.chain+=1; p.max_chain=maxi(p.max_chain,p.chain)
  if definition.id=="cursed_treasure": p.metrics.cursed_relics=int(p.metrics.get("cursed_relics",0))+1
 run.field.event=""
 gem_multiplier=1.0
 impact_tick=0
 run.encounter.event_refill_mult=1.0
func meteor(run: RunController) -> void:
 if impact_tick==0 and run.state.field_tick%180==0:
  impact_position=run.map.safe_position(run.state.player.position+Vector2.RIGHT.rotated(run.state.rng.range_float(0,TAU))*80)
  impact_tick=run.state.field_tick+60
 if impact_tick>0 and run.state.field_tick>=impact_tick:
  if run.state.player.position.distance_to(impact_position)<70: run.damage.apply_player(run.state,15,"field:meteor")
  run.spatial.query_circle(SpatialWorld.ENEMY,impact_position,70,scratch)
  for n in range(scratch.count): run.damage.apply(run.enemies,scratch.ids[n],25,"field:meteor")
  impact_tick=0
