extends RefCounted
class_name StatusSystem
# Only owner of gameplay status countdowns. Durations are integer fixed ticks.
var last_tick := -1
func tick(world: EnemyWorld, player: PlayerState, tick_id: int,damage: DamageSystem = null,period_ticks: int = 30,poison_damage: float = 2) -> void:
 assert(tick_id != last_tick, "StatusSystem called twice in one simulation tick")
 last_tick = tick_id
 player.invulnerability = maxi(0, player.invulnerability - 1)
 for n in range(world.count):
  var i := world.dense[n]
  world.contact[i] = maxi(0, world.contact[i] - 1)
  world.shock[i] = maxi(0, world.shock[i] - 1)
  world.poison[i] = maxi(0, world.poison[i] - 1)
  world.periodic[i] = maxi(0, world.periodic[i] - 1)
  world.slow[i] = maxi(0, world.slow[i] - 1)
  world.action[i] = maxi(0, world.action[i] - 1)
  world.warning[i] = maxi(0, world.warning[i] - 1)
  if damage!=null and world.hp[i]>0 and world.poison[i]>0 and world.periodic[i]==0:
   damage.apply(world,world.entity_id(i),poison_damage,"status:poison")
   world.periodic[i]=period_ticks
