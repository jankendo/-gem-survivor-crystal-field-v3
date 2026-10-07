extends RefCounted
class_name WeaponRuntime
# Active definitions cached on loadout changes. Dispatch by archetype, not weapon ID.
var ids: Array[String] = []
var definitions: Array = []
var stats: Array = []
var cooldowns := PackedInt32Array()
var signature := 0
var modifiers := WeaponModifiers.new()
var resolver := StatResolver.new()
var scratch := QueryBuffer.new(600)
var processed := 0
var resonance_multiplier := 1.1
var coverage_ticks := 0
func refresh(state: RunState, db: GameDatabase) -> void:
 state.player.stats = PassiveSystem.new().resolve(state,db)
 var contracts := ContractSystem.new().multipliers(state,db)
 for key in contracts: state.player.stats["contract_"+str(key)] = contracts[key]
 ids.clear()
 definitions.clear()
 stats.clear()
 resonance_multiplier = float(db.config().get("resonance_damage_mult",1.1))
 for id in state.progression.weapons:
  ids.append(id)
  definitions.append(db.table("v3_weapons")[id])
  stats.append(resolver.resolve(id, state, db, false))
 cooldowns.resize(ids.size())
 cooldowns.fill(0)
 signature = [state.progression.weapons,state.progression.passives,state.progression.evolutions,state.progression.overclocks,state.player.contracts].hash()
func tick(state: RunState, enemies: EnemyWorld, spatial: SpatialWorld, projectiles: ProjectileWorld, damage_system: DamageSystem,context = null) -> void:
 for n in range(ids.size()):
  processed += 1
  cooldowns[n] = maxi(0, cooldowns[n] - 1)
  if cooldowns[n] > 0: continue
  var d: Dictionary = definitions[n]
  var s: Dictionary = stats[n]
  var target := spatial.query_nearest(SpatialWorld.ENEMY, state.player.position, s.range, scratch)
  if target < 0 or not enemies.alive(target):
   if not d.get("modifiers",{}).is_empty():
    modifiers.utility(context,d,state.player.position,float(s.radius),float(s.damage),"weapon:"+ids[n])
    cooldowns[n]=int(s.cooldown_ticks)
   continue
  cooldowns[n] = int(s.cooldown_ticks)
  coverage_ticks += 1
  var origin := state.player.position
  var hit_damage := float(s.damage)
  hit_damage *= 1+float(state.player.stats.get("context_damage",0))
  if state.progression.resonance>0: hit_damage *= resonance_multiplier
  var hit_radius := float(s.radius)*(1+float(state.player.stats.get("context_area",0)))
  if str(d.status)=="poison": hit_radius *= 1+float(state.player.stats.get("poison_area",0))
  var center := enemies.positions[enemies.slot(target)]
  modifiers.utility(context,d,origin,hit_radius,hit_damage,"weapon:"+ids[n])
  match str(d.archetype):
   "projectile", "summon":
    var direction := (center - origin).normalized()
    for shot in range(int(s.targets)):
     projectiles.add(origin, direction.rotated((shot - (int(s.targets)-1)*.5) * .13) * float(d.speed), hit_damage, "weapon:" + ids[n],int(d.get("pierce",0))+int(state.player.stats.get("pierce",0)),int(d.get("modifiers",{}).get("bounce",0))+int(s.get("bounce_bonus",0)),bool(d.get("modifiers",{}).get("homing",false)),["","slow","shock","poison"].find(str(d.status)))
   "beam": spatial.query_segment(SpatialWorld.ENEMY, origin, origin + (center-origin).normalized() * float(s.range), 30, scratch)
   "deploy":
    if context!=null:
     context.deployments.add(center,hit_radius,hit_damage,"weapon:"+ids[n],int(s.targets),d)
     continue
    spatial.query_circle(SpatialWorld.ENEMY,center,hit_radius,scratch)
   "explosion": spatial.query_circle(SpatialWorld.ENEMY, center, hit_radius, scratch)
   "chain": spatial.query_circle(SpatialWorld.ENEMY, center, minf(s.range, 280), scratch)
   _: spatial.query_circle(SpatialWorld.ENEMY, origin, hit_radius, scratch)
  if str(d.archetype) == "projectile" or str(d.archetype) == "summon": continue
  var hits := 0
  for query_index in range(scratch.count):
   var id := scratch.ids[query_index]
   if not enemies.alive(id): continue
   if str(d.archetype)=="melee" and (enemies.positions[enemies.slot(id)]-origin).normalized().dot((center-origin).normalized())<.1: continue
   damage_system.apply(enemies, id, hit_damage, "weapon:" + ids[n])
   modifiers.on_hit(enemies,id,origin,d)
   var i := enemies.slot(id)
   match str(d.status):
    "slow": enemies.slow[i] = 90
    "shock": enemies.shock[i] = 90
    "poison": enemies.poison[i] = 180+int(state.player.stats.get("poison_duration",0))
   hits += 1
   if hits >= int(s.targets): break
