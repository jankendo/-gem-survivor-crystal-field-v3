extends RefCounted
class_name DeathSystem
func tick(state: RunState, world: EnemyWorld, gems: PickupWorld, damage: DamageSystem, map: WorldGenerator) -> void:
 for n in range(damage.death_count):
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
  state.progression.currency += 1 if not is_boss else 100
  if is_boss:
   state.progression.bosses += 1
   state.progression.terrain_bosses[terrain] += 1
   if world.types[i]<0: state.progression.boss_ids.append("boss_"+str(mini(-world.types[i]*5,30)))
   if world.types[i] == -3 and not state.endless: state.phase = "CLEAR"
  world.remove(id)

 damage.death_count = 0
