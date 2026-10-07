extends RefCounted
class_name WeaponRuntime
# Active definitions cached on loadout changes. Dispatch by archetype, not weapon ID.
var ids: Array[String] = []
var definitions: Array = []
var stats: Array = []
var cooldowns := PackedInt32Array()
var signature := 0
var resolver := StatResolver.new()
var scratch := QueryBuffer.new(600)
var processed := 0
var coverage_ticks := 0
func refresh(state: RunState, db: GameDatabase) -> void:
 state.player.stats = PassiveSystem.new().resolve(state,db)
 var contracts := ContractSystem.new().multipliers(state,db)
 for key in contracts: state.player.stats["contract_"+str(key)] = contracts[key]
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
  var hit_damage := float(s.damage)
  hit_damage *= 1+float(state.player.stats.get("context_damage",0))
  var center := enemies.positions[enemies.slot(target)]
  match str(d.archetype):
   "projectile", "summon":
    var direction := (center - origin).normalized()
    for shot in range(int(s.targets)):
     projectiles.add(origin, direction.rotated((shot - (int(s.targets)-1)*.5) * .13) * float(d.speed), hit_damage, "weapon:" + ids[n],int(d.get("pierce",0))+int(state.player.stats.get("pierce",0)))
   "beam": spatial.query_segment(SpatialWorld.ENEMY, origin, origin + (center-origin).normalized() * float(s.range), 30, scratch)
   "explosion", "deploy": spatial.query_circle(SpatialWorld.ENEMY, center, s.radius, scratch)
   "chain": spatial.query_circle(SpatialWorld.ENEMY, center, minf(s.range, 280), scratch)
   _: spatial.query_circle(SpatialWorld.ENEMY, origin, s.radius, scratch)
  if str(d.archetype) == "projectile" or str(d.archetype) == "summon": continue
  var hits := 0
  for query_index in range(scratch.count):
   var id := scratch.ids[query_index]
   if not enemies.alive(id): continue
   damage_system.apply(enemies, id, hit_damage, "weapon:" + ids[n])
   var i := enemies.slot(id)
   match str(d.status):
    "slow": enemies.slow[i] = 90
    "shock": enemies.shock[i] = 90
    "poison": enemies.poison[i] = 180+int(state.player.stats.get("poison_duration",0))
   hits += 1
   if hits >= int(s.targets): break
