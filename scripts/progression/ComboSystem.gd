extends RefCounted
class_name ComboSystem
var active: Array = []
var cooldowns := PackedInt32Array()
var scratch := QueryBuffer.new(600)
var amounts := PackedFloat64Array()
func refresh(state: RunState, db: GameDatabase) -> void:
 active.clear()
 for d in db.table("weapon_combo_attacks").get("combos", []):
  if state.progression.weapons.has(d.weapon_a) and state.progression.weapons.has(d.weapon_b): active.append(d)
 cooldowns.resize(active.size())
 cooldowns.fill(0)
 amounts.resize(active.size())
 for n in range(active.size()):
  var d: Dictionary = active[n]
  var a := StatResolver.new().resolve(d.weapon_a,state,db,false)
  var b := StatResolver.new().resolve(d.weapon_b,state,db,false)
  amounts[n] = float(a.damage)*float(d.damage_scale_a)+float(b.damage)*float(d.damage_scale_b)
func tick(state: RunState, db: GameDatabase, enemies: EnemyWorld, spatial: SpatialWorld, damage: DamageSystem) -> void:
 for n in range(active.size()):
  cooldowns[n] = maxi(0, cooldowns[n] - 1)
  if cooldowns[n] > 0: continue
  var d: Dictionary = active[n]
  spatial.query_circle(SpatialWorld.ENEMY, state.player.position, 500, scratch)
  if scratch.is_empty(): continue
  cooldowns[n] = int(float(d.cooldown_seconds) * 60)
  var amount := amounts[n]*(float(db.config().get("resonance_damage_mult",1.1)) if state.progression.resonance>0 else 1.0)
  var pattern := str(d.pattern)
  var target := spatial.query_nearest(SpatialWorld.ENEMY,state.player.position,650,scratch)
  if target<0: continue
  var center := enemies.positions[enemies.slot(target)]
  if "prism" in pattern:
   spatial.query_segment(SpatialWorld.ENEMY,state.player.position,state.player.position+(center-state.player.position).normalized()*650,45,scratch)
  elif "meteor" in pattern or "detonator" in pattern:
   spatial.query_circle(SpatialWorld.ENEMY,center,180,scratch)
  elif "cleave" in pattern:
   spatial.query_circle(SpatialWorld.ENEMY,state.player.position,260,scratch)
  else: spatial.query_circle(SpatialWorld.ENEMY,state.player.position,420,scratch)
  for k in range(mini(int(d.max_targets), scratch.size())):
   var id := scratch.ids[k]
   damage.apply(enemies,id,amount,"combo:"+str(d.id))
   if enemies.alive(id) and "frost" in pattern: enemies.slow[enemies.slot(id)] = 90
