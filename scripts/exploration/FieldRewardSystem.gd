extends RefCounted
class_name FieldRewardSystem
var positions := PackedVector2Array()
var hp := PackedFloat32Array()
var active := PackedInt32Array()
var kinds := PackedStringArray()
var event := ""
var event_room := -1
var event_deadline := 0
var event_start_kills := 0
var scratch := QueryBuffer.new(600)
var crystals := 0
var events_completed := 0
func generate(map: WorldGenerator) -> void:
 var count := map.rooms.size()
 positions.resize(count)
 hp.resize(count)
 active.resize(count)
 kinds.resize(count)
 for i in range(count):
  positions[i] = map.safe_position(map.rooms[i].get_center()+Vector2(100,100))
  hp[i] = 60
  active[i] = 1
  kinds[i] = "healing_spring" if map.kinds[i]=="safe" else "explosive_vein" if map.kinds[i]=="mining" else "sealed_chest_pillar" if map.kinds[i]=="event" else "lightning_crystal" if map.kinds[i]=="risk" else "reflect_crystal"
func index_spatial(spatial: SpatialWorld) -> void:
 for i in range(positions.size()):
  if active[i]: spatial.insert(SpatialWorld.INTERACTABLE,100+i,positions[i])
  if active[i] and kinds[i]=="lightning_crystal": spatial.insert(SpatialWorld.HAZARD,i,positions[i])
func interact(run: RunController) -> bool:
 run.spatial.query_circle(SpatialWorld.INTERACTABLE,run.state.player.position,140,scratch)
 for query_index in range(scratch.count):
  var id := scratch.ids[query_index]
  if id < 100: continue
  var i: int = id-100
  if not active[i]: continue
  if kinds[i]=="healing_spring":
   run.state.player.hp = minf(run.state.player.max_hp,run.state.player.hp+30*(1+float(run.state.player.stats.get("field_reward",0))))
   active[i] = 0
   return true
  if kinds[i]=="sealed_chest_pillar":
   active[i] = 0
   run.state.progression.currency += 30
   run.state.progression.exp += roundi(40*(1+float(run.state.player.stats.get("chest_reward",0))))
   var options := LoadoutSystem.new().candidates(run.state,run.db,run.unlocked)
   if not options.is_empty():
    LoadoutSystem.new().apply(options[run.state.rng.next_int(options.size())],run.state,run.db)
    EvolutionSystem.new().refresh(run.state,run.db)
    run.weapons.refresh(run.state,run.db)
    run.combos.refresh(run.state,run.db)
   return true
  var cfg := run.db.config()
  var amount := float(cfg.mining_hit_damage) * (1+float(run.state.player.stats.get("mining",0)))
  run.damage.apply_field(self,i,amount,"field:mining")
  if hp[i] <= 0:
   active[i] = 0
   crystals += 1
   var reward := float(cfg.mining_reward)
   reward *= (1+float(run.state.player.stats.get("mining_reward",0)))*float(run.state.player.stats.get("contract_crystal",1))
   run.gems.add(positions[i],roundi(reward),run.map)
   run.state.progression.currency += roundi(10*(1+float(run.state.player.stats.get("field_reward",0))))
   if kinds[i]=="lightning_crystal":
    var available: Array = run.db.table("rune_contracts").keys()
    var rng = run.state.rng.stream_rng("contract",crystals)
    run.pending_contract = available[rng.next_int(available.size())]
    run.spatial.query_circle(SpatialWorld.ENEMY,positions[i],250,scratch)
    for hit_index in range(scratch.count): run.damage.apply(run.enemies,scratch.ids[hit_index],30,"field:lightning")
   # Damage death queue is drained on next fixed tick before it is cleared.
  return true
 var room := run.map.room_at(run.state.player.position)
 if room >= 0 and run.map.kinds[room]=="event" and event.is_empty():
  event = "elite_hunt" if run.state.field_tick > 18000 else "gem_storm"
  event_room = room
  event_deadline = run.state.field_tick + 2700
  event_start_kills = run.state.progression.kills
  return true
 return false
func tick(run: RunController) -> void:
 if event.is_empty(): return
 if run.state.field_tick >= event_deadline:
  if event=="gem_storm" or run.state.progression.kills-event_start_kills >= 10:
   run.state.progression.currency += roundi(100*(1+float(run.state.player.stats.get("event_reward",0))))
   run.gems.add(run.map.rooms[event_room].get_center(),80,run.map)
   events_completed += 1
  event = ""
