extends RefCounted
class_name FieldRewardSystem
var positions := PackedVector2Array()
var hp := PackedFloat32Array()
var active := PackedInt32Array()
var kinds := PackedStringArray()
var events := FieldEventSystem.new()
var event := ""
var event_room := -1
var event_deadline := 0
var event_start_kills := 0
var scratch := QueryBuffer.new(600)
var crystals := 0
var events_completed := 0
var rifts := PackedInt32Array()
var rift_period := 180
var rift_start := 21600
func generate(map: WorldGenerator,db: GameDatabase = null) -> void:
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
  if map.kinds[i]=="risk" and i%2==1:
   kinds[i]="spawn_rift"
   rifts.append(i)
  if db!=null: hp[i]=float(db.table("field_gimmicks")[kinds[i]].hp)
 if db!=null:
  rift_period=int(db.config().get("rift_spawn_ticks",180))
  rift_start=int(float(db.table("field_gimmicks").spawn_rift.unlock_seconds)*60)
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
   var before := run.state.player.hp
   run.state.player.hp = minf(run.state.player.max_hp,run.state.player.hp+30*float(run.state.player.stats.get("char_healing",1))*(1+float(run.state.player.stats.get("field_reward",0))))
   run.state.progression.metrics.oasis_healing=float(run.state.progression.metrics.get("oasis_healing",0))+run.state.player.hp-before
   record_gimmick(run,i)
   active[i] = 0
   return true
  if kinds[i]=="sealed_chest_pillar":
   run.damage.apply_field(self,i,float(run.db.config().mining_hit_damage)*(1+float(run.state.player.stats.get("mining",0))),"field:mining")
   if hp[i]>0: return true
   run.state.progression.metrics.total_chests=int(run.state.progression.metrics.get("total_chests",0))+1
   record_gimmick(run,i)
   active[i] = 0
   run.state.progression.currency += 30
   run.state.progression.exp += roundi(40*(1+float(run.state.player.stats.get("chest_reward",0))))
   var options := LoadoutSystem.new().candidates(run.state,run.db,run.unlocked)
   if not options.is_empty():
    var choice: Array=options[run.state.rng.next_int(options.size())]
    LoadoutSystem.new().apply(choice,run.state,run.db)
    var rare_chance := float(run.state.player.stats.get("rare_reward",0))+float(run.state.player.stats.get("contract_rare",0))
    if choice[0]=="weapons": rare_chance+=float(run.state.player.stats.get("weapon_core",0))
    if rare_chance>0 and run.state.rng.chance(clampf(rare_chance,0,1)): LoadoutSystem.new().apply(choice,run.state,run.db)
    var drops: Dictionary=run.state.progression.metrics.field_drop_count
    var core: String="weapon_core" if choice[0]=="weapons" else "passive_core"
    drops[core]=int(drops.get(core,0))+1
    EvolutionSystem.new().refresh(run.state,run.db)
    run.weapons.refresh(run.state,run.db)
    run.combos.refresh(run.state,run.db)
   return true
  mine(run,i,float(run.db.config().mining_hit_damage)*(1+float(run.state.player.stats.get("mining",0))),"field:mining")
  return true
 var room := run.map.room_at(run.state.player.position)
 if room >= 0 and run.map.kinds[room]=="event" and event.is_empty() and run.state.field_tick>=14400:
  return events.start(run,room)
 return false
func tick(run: RunController) -> void:
 events.tick(run)
 if run.state.field_tick>=rift_start and run.state.field_tick%rift_period==0:
  for i in rifts:
   if active[i] and run.enemies.count<int(run.db.config().enemy_cap): run.enemies.spawn(0,positions[i],run.db.enemy_defs[0],1.5)
func record_gimmick(run: RunController,i: int) -> void:
 var counters: Dictionary=run.state.progression.metrics.gimmick_count
 var id: String=kinds[i]
 counters[id]=int(counters.get(id,0))+1
 if id=="lightning_crystal": counters.conductive_crystal=int(counters.get("conductive_crystal",0))+1

func mine(run: RunController,i: int,amount: float,source: String) -> void:
 if not active[i]: return
 var cfg := run.db.config()
 run.damage.apply_field(self,i,amount,source)
 if hp[i] <= 0:
  active[i] = 0
  crystals += 1
  run.state.progression.terrain_crystals[run.map.terrain_index(positions[i])] += 1
  record_gimmick(run,i)
  if run.map.kinds[i]=="shortcut": run.state.progression.metrics.shortcut_walls=int(run.state.progression.metrics.get("shortcut_walls",0))+1
  var reward := float(cfg.mining_reward)
  reward *= (1+float(run.state.player.stats.get("mining_reward",0)))*float(run.state.player.stats.get("contract_crystal",1))
  run.gems.add(positions[i],roundi(reward),run.map)
  run.state.progression.currency += roundi(10*(1+float(run.state.player.stats.get("field_reward",0)))*(float(run.state.player.stats.get("char_danger_reward",1)) if run.map.kinds[i]=="risk" else 1))
  if kinds[i]=="lightning_crystal":
   var available: Array = run.db.table("rune_contracts").keys()
   var rng = run.state.rng.stream_rng("contract",crystals)
   run.pending_contract = available[rng.next_int(available.size())]
   run.spatial.query_circle(SpatialWorld.ENEMY,positions[i],250*float(run.state.player.stats.get("char_gimmick_area",1)),scratch)
   for hit_index in range(scratch.count): run.damage.apply(run.enemies,scratch.ids[hit_index],30*float(run.state.player.stats.get("char_gimmick_damage",1)),"field:lightning")
  if kinds[i]=="explosive_vein":
   run.spatial.query_circle(SpatialWorld.ENEMY,positions[i],200*float(run.state.player.stats.get("char_gimmick_area",1)),scratch)
   for n in range(scratch.count): run.damage.apply(run.enemies,scratch.ids[n],30*float(run.state.player.stats.get("char_gimmick_damage",1)),"field:explosion")
  if kinds[i]=="reflect_crystal":
   for shot in range(4): run.projectiles.add(positions[i],Vector2.RIGHT.rotated(shot*TAU/4)*500,20,"field:reflect",1,2)
  if run.state.player.stats.get("char_crystal_poison",false):
   run.spatial.query_circle(SpatialWorld.ENEMY,positions[i],200,scratch)
   for n in range(scratch.count):
    if run.enemies.alive(scratch.ids[n]): run.enemies.poison[run.enemies.slot(scratch.ids[n])]=180
  # Damage death queue is drained on next fixed tick before it is cleared.
