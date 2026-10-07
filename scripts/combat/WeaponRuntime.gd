extends RefCounted
class_name WeaponRuntime
# Active definitions cached on loadout changes. Dispatch by archetype, not weapon ID.
var ids: Array[String] = []
var definitions: Array = []
var stats: Array = []
var cooldowns := PackedInt32Array()
var death_effects: Dictionary = {}
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
 death_effects.clear()
 ids.clear()
 definitions.clear()
 stats.clear()
 resonance_multiplier = float(db.config().get("resonance_damage_mult",1.1))
 for id in state.progression.weapons:
  ids.append(id)
  definitions.append(OverclockSystem.new().runtime(id,state,db))
  definitions.back()["slow_ticks"]=roundi(90*float(state.player.stats.get("char_slow",1)))
  death_effects["weapon:"+id]=definitions.back().modifiers
  stats.append(resolver.resolve(id, state, db, false))
 cooldowns.resize(ids.size())
 cooldowns.fill(0)
 signature = [state.progression.named_overclocks,state.progression.weapons,state.progression.passives,state.progression.evolutions,state.progression.overclocks,state.player.contracts].hash()
func tick(state: RunState, enemies: EnemyWorld, spatial: SpatialWorld, projectiles: ProjectileWorld, damage_system: DamageSystem,context = null) -> void:
 damage_system.source_effects=death_effects
 for n in range(ids.size()):
  processed += 1
  cooldowns[n] = maxi(0, cooldowns[n] - 1)
  if cooldowns[n] > 0: continue
  var d: Dictionary = definitions[n]
  var s: Dictionary = stats[n]
  if d.get("modifiers",{}).get("gem_charge",false) and state.progression.gem_turret_charge<=0 and not state.progression.evolutions.has(ids[n]): continue
  var target := spatial.query_nearest(SpatialWorld.ENEMY, state.player.position, s.range, scratch)
  if target < 0 or not enemies.alive(target):
   if not d.get("modifiers",{}).is_empty():
    modifiers.utility(context,d,state.player.position,float(s.radius),float(s.damage),"weapon:"+ids[n])
    cooldowns[n]=int(s.cooldown_ticks)
   continue
  if d.get("modifiers",{}).get("gem_charge",false): state.progression.gem_turret_charge=maxi(0,state.progression.gem_turret_charge-1)
  cooldowns[n] = int(s.cooldown_ticks)
  coverage_ticks += 1
  var origin := state.player.position
  var hit_damage := float(s.damage)
  hit_damage *= 1+float(state.player.stats.get("context_damage",0))
  if state.progression.resonance>0: hit_damage *= resonance_multiplier
  var tweaks: Dictionary=d.get("modifiers",{})
  hit_damage*=1+float(tweaks.get("contract_damage",0))*state.player.contracts.size()
  if context!=null and context.map.room_at(origin)<0: hit_damage*=float(tweaks.get("corridor_damage",1))
  var hit_radius := float(s.radius)*(1+float(state.player.stats.get("context_area",0)))
  if str(d.status)=="poison": hit_radius *= 1+float(state.player.stats.get("poison_area",0))
  var center := enemies.positions[enemies.slot(target)]
  modifiers.utility(context,d,origin,hit_radius,hit_damage,"weapon:"+ids[n])
  if context!=null and float(d.modifiers.get("self_chance",0))>0 and state.rng.chance(float(d.modifiers.self_chance)): damage_system.apply_player(state,float(d.modifiers.self_damage),"self:overclock")
  if context!=null and (d.modifiers.get("afterglow",false) or d.modifiers.get("bloom",false)): context.deployments.add(center,hit_radius,hit_damage,"weapon:"+ids[n],int(s.targets),d)
  match str(d.archetype):
   "projectile", "summon":
    var direction := (center - origin).normalized()
    for shot in range(int(s.targets)):
     projectiles.add(origin, direction.rotated((shot - (int(s.targets)-1)*.5) * .13) * float(d.speed), hit_damage, "weapon:" + ids[n],int(d.get("pierce",0))+int(state.player.stats.get("pierce",0)),int(d.get("modifiers",{}).get("bounce",0))+int(s.get("bounce_bonus",0)),bool(d.get("modifiers",{}).get("homing",false)),["","slow","shock","poison"].find(str(d.status)),bool(d.modifiers.get("split_bounce",false)))
   "beam": spatial.query_segment(SpatialWorld.ENEMY, origin, origin + (center-origin).normalized() * float(s.range), 30, scratch)
   "deploy":
    if context!=null:
     var direction := (center-origin).normalized()
     var placement: Vector2=origin if float(d.modifiers.get("beam_length",0))>0 else origin+direction*float(d.modifiers.forward_deploy) if d.modifiers.has("forward_deploy") else center
     context.deployments.add(placement,hit_radius,hit_damage,"weapon:"+ids[n],int(s.targets),d,direction)
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
   var per_target: float =hit_damage*(float(d.modifiers.get("frozen_damage",1)) if enemies.slow[enemies.slot(id)]>0 else 1)
   var actual:=damage_system.apply(enemies, id, per_target, "weapon:" + ids[n])
   modifiers.on_hit(enemies,id,origin,d,context,actual,state.progression.evolutions.has(ids[n]))
   var i := enemies.slot(id)
   match str(d.status):
    "slow": enemies.slow[i] = int(d.slow_ticks)
    "shock": enemies.shock[i] = 90
    "poison": enemies.poison[i] = 180+int(state.player.stats.get("poison_duration",0))
   hits += 1
   if hits >= int(s.targets): break
