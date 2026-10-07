extends RefCounted
class_name WeaponRuntime
# Active definitions cached on loadout changes. Dispatch by archetype, not weapon ID.
var ids: Array[String] = []
var definitions: Array = []
var stats: Array = []
var cooldowns := PackedInt32Array()
var signature := 0
var resolver := StatResolver.new()
var scratch: Array = []
var processed := 0
var coverage_ticks := 0
func refresh(state: RunState, db: GameDatabase) -> void:
 ids.clear()
 definitions.clear()
 stats.clear()
 for id in state.progression.weapons:
  ids.append(id)
  definitions.append(db.table("v3_weapons")[id])
  stats.append(resolver.resolve(id, state, db))
 cooldowns.resize(ids.size())
 cooldowns.fill(0)
 signature = [state.progression.weapons,state.progression.passives,state.progression.evolutions,state.progression.overclocks,state.player.contracts].hash()
func tick(state: RunState, enemies: EnemyWorld, spatial: SpatialWorld, projectiles: ProjectileWorld, damage_system: DamageSystem) -> void:
 for n in range(ids.size()):
  processed += 1
  cooldowns[n] = maxi(0, cooldowns[n] - 1)
  if cooldowns[n] > 0: continue
  var d: Dictionary = definitions[n]
  var s: Dictionary = stats[n]
  var target := spatial.query_nearest(SpatialWorld.ENEMY, state.player.position, s.range, scratch)
  if target < 0 or not enemies.alive(target): continue
  cooldowns[n] = int(s.cooldown_ticks)
  coverage_ticks += 1
  var origin := state.player.position
  var center := enemies.positions[enemies.slot(target)]
  match str(d.archetype):
   "projectile", "summon":
    var direction := (center - origin).normalized()
    for shot in range(int(s.targets)):
     projectiles.add(origin, direction.rotated((shot - (int(s.targets)-1)*.5) * .13) * float(d.speed), s.damage, "weapon:" + ids[n])
   "beam": spatial.query_segment(SpatialWorld.ENEMY, origin, origin + (center-origin).normalized() * float(s.range), 30, scratch)
   "explosion", "deploy": spatial.query_circle(SpatialWorld.ENEMY, center, s.radius, scratch)
   "chain": spatial.query_circle(SpatialWorld.ENEMY, center, minf(s.range, 280), scratch)
   _: spatial.query_circle(SpatialWorld.ENEMY, origin, s.radius, scratch)
  if str(d.archetype) == "projectile" or str(d.archetype) == "summon": continue
  var hits := 0
  for id in scratch:
   if not enemies.alive(id): continue
   damage_system.apply(enemies, id, s.damage, "weapon:" + ids[n])
   var i := enemies.slot(id)
   match str(d.status):
    "slow": enemies.slow[i] = 90
    "shock": enemies.shock[i] = 90
    "poison": enemies.poison[i] = 180
   hits += 1
   if hits >= int(s.targets): break
