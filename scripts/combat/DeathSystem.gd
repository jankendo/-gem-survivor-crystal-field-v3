extends RefCounted
class_name DeathSystem
var scratch := QueryBuffer.new(600)
func tick(state: RunState, world: EnemyWorld, gems: PickupWorld, damage: DamageSystem, map: WorldGenerator) -> void:
 var cursor := 0
 while cursor<damage.death_count:
  var n:=cursor
  cursor+=1
  var id := damage.death_ids[n]
  if not world.alive(id): continue
  var i := world.slot(id)
  if world.hp[i] > 0: continue
  var is_boss := (world.flags[i] & 1) != 0
  var terrain := map.terrain_index(world.positions[i])
  state.progression.terrain_kills[terrain] += 1
  if world.flags[i]&2: state.progression.elite_kills += 1
  var source := damage.death_sources[n]
  if source.begins_with("weapon:"):
   var weapon := source.trim_prefix("weapon:")
   var values: Dictionary = state.progression.metrics.weapon_kills
   values[weapon] = int(values.get(weapon,0))+1
  gems.add(world.positions[i],world.xp[i],map)
  state.progression.kills += 1
  if state.phase!="RESULT" and state.player.hp>0 and float(state.player.stats.get("char_kill_heal",0))>0 and state.rng.chance(float(state.player.stats.char_kill_heal)): state.player.hp=minf(state.player.max_hp,state.player.hp+1)
  state.progression.currency += 1 if not is_boss else 100
  if is_boss:
   if world.types[i]==-5 and state.player.hp<state.player.max_hp*.2: state.progression.metrics.reaper=true
   state.progression.bosses += 1
   state.progression.terrain_bosses[terrain] += 1
   if world.types[i]<0: state.progression.boss_ids.append("boss_"+str(mini(-world.types[i]*5,30)))
   if world.types[i] == -3 and not state.endless and state.phase!="RESULT" and state.player.hp>0: state.phase = "CLEAR"
  if damage.spatial!=null:
   if damage.death_burst_radius[n]>0:
    damage.spatial.query_circle(SpatialWorld.ENEMY,world.positions[i],damage.death_burst_radius[n],scratch)
    for q in range(scratch.count): damage.apply(world,scratch.ids[q],damage.death_burst_damage[n],source)
   if damage.death_slow_radius[n]>0:
    damage.spatial.query_circle(SpatialWorld.ENEMY,world.positions[i],damage.death_slow_radius[n],scratch)
    for q in range(scratch.count):
     if world.alive(scratch.ids[q]): world.slow[world.slot(scratch.ids[q])]=90
  world.remove(id)

 damage.death_count = 0
