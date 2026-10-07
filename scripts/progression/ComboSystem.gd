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
  var a := StatResolver.new().resolve(d.weapon_a,state,db)
  var b := StatResolver.new().resolve(d.weapon_b,state,db)
  amounts[n] = float(a.damage)*float(d.damage_scale_a)+float(b.damage)*float(d.damage_scale_b)
func tick(state: RunState, db: GameDatabase, enemies: EnemyWorld, spatial: SpatialWorld, damage: DamageSystem) -> void:
 for n in range(active.size()):
  cooldowns[n] = maxi(0, cooldowns[n] - 1)
  if cooldowns[n] > 0: continue
  var d: Dictionary = active[n]
  spatial.query_circle(SpatialWorld.ENEMY, state.player.position, 500, scratch)
  if scratch.is_empty(): continue
  cooldowns[n] = int(float(d.cooldown_seconds) * 60)
  var amount := amounts[n]
  for k in range(mini(int(d.max_targets), scratch.size())): damage.apply(enemies, scratch.ids[k], amount, "combo:" + str(d.id))
