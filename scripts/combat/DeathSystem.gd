extends RefCounted
class_name DeathSystem
func tick(state: RunState, world: EnemyWorld, gems: PickupWorld, damage: DamageSystem, map: WorldGenerator) -> void:
 for n in range(damage.death_count):
  var id := damage.death_ids[n]
  if not world.alive(id): continue
  var i := world.slot(id)
  if world.hp[i] > 0: continue
  var is_boss := (world.flags[i] & 1) != 0
  gems.add(world.positions[i],world.xp[i],map)
  state.progression.kills += 1
  state.progression.currency += 1 if not is_boss else 100
  if is_boss:
   state.progression.bosses += 1
   state.progression.boss_ids.append("boss_"+str(mini(-world.types[i]*5,30)))
   if world.types[i] == -3 and not state.endless: state.phase = "CLEAR"
  world.remove(id)

 damage.death_count = 0
