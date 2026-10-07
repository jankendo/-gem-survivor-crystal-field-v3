extends RefCounted
class_name StatusSystem
# Only owner of gameplay status countdowns. Durations are integer fixed ticks.
var last_tick := -1
func tick(world: EnemyWorld, player: PlayerState, tick_id: int) -> void:
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
