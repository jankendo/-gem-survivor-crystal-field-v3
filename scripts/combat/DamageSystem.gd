extends RefCounted
class_name DamageSystem
# Actual HP loss is attributed once; overkill is tracked separately.
var spatial: SpatialWorld
var presentation := PresentationEvents.new()
var normal_multiplier := 1.0
var elite_multiplier := 1.0
var boss_multiplier := 1.0
var totals: Dictionary = {}
var boss_damage := 0.0
var normal_damage := 0.0
var field_damage := 0.0
var overkill := 0.0
var death_ids := PackedInt64Array()
var death_sources := PackedStringArray()
var death_count := 0
var event_count := 0
func _init() -> void:
 death_ids.resize(600)
 death_sources.resize(600)
func begin_tick() -> void:
 death_count = 0
 presentation.clear()
func apply(world: EnemyWorld, id: int, amount: float, source: String) -> float:
 if not world.alive(id) or amount <= 0: return 0.0
 var i := world.slot(id)
 if world.hp[i] <= 0: return 0.0
 if source.begins_with("weapon:") or source.begins_with("combo:"):
  amount *= elite_multiplier if world.flags[i]&3 else normal_multiplier
 if world.flags[i]&1: amount*=boss_multiplier
 if world.flags[i]&8: amount *= .6
 var actual := minf(world.hp[i], amount)
 world.hp[i] -= actual
 totals[source] = float(totals.get(source, 0.0)) + actual
 overkill += amount - actual
 event_count += 1
 presentation.emit(world.positions[i],0)
 if world.flags[i] & 1: boss_damage += actual
 else: normal_damage += actual
 if world.hp[i] <= 0:
  if spatial!=null: spatial.deactivate_enemy(id)
  death_ids[death_count] = id
  death_sources[death_count] = source
  death_count += 1
 return actual
func apply_player(state: RunState, amount: float, source: String) -> void:
 if state.player.invulnerability > 0: return
 amount*=float(state.player.stats.get("char_incoming",1))
 var reduction := float(state.player.stats.get("contract_incoming",1))*maxf(.58,1-float(state.player.stats.get("armor",0)))
 if source=="boss": reduction *= maxf(.6,1-float(state.player.stats.get("boss_armor",0)))
 reduction *= maxf(.7,1-float(state.player.stats.get("context_armor",0)))
 state.player.hp = maxf(0, state.player.hp - amount*reduction)
 state.player.invulnerability = 36
 state.last_damage_source = source
 if state.player.hp <= 0:
  if int(state.player.stats.get("revivals",0)) > 0 and not state.player.revival_used:
   state.player.revival_used = true
   state.player.hp = state.player.max_hp*.5
   state.player.invulnerability = 180
  else: state.phase = "RESULT"
func total() -> float: return boss_damage + normal_damage + field_damage

func apply_field(field: FieldRewardSystem, index: int, amount: float, source: String) -> float:
 if not field.active[index] or field.hp[index] <= 0: return 0
 var actual := minf(field.hp[index],amount)
 field.hp[index] -= actual
 field_damage += actual
 totals[source] = float(totals.get(source,0))+actual
 return actual
