extends RefCounted
class_name DamageSystem
# Actual HP loss is attributed once; overkill is tracked separately.
var totals: Dictionary = {}
var boss_damage := 0.0
var normal_damage := 0.0
var overkill := 0.0
var death_ids := PackedInt64Array()
var death_count := 0
var event_count := 0
func _init() -> void: death_ids.resize(600)
func begin_tick() -> void: death_count = 0
func apply(world: EnemyWorld, id: int, amount: float, source: String) -> float:
 if not world.alive(id) or amount <= 0: return 0.0
 var i := world.slot(id)
 if world.hp[i] <= 0: return 0.0
 var actual := minf(world.hp[i], amount)
 world.hp[i] -= actual
 totals[source] = float(totals.get(source, 0.0)) + actual
 overkill += amount - actual
 event_count += 1
 if world.flags[i] & 1: boss_damage += actual
 else: normal_damage += actual
 if world.hp[i] <= 0:
  death_ids[death_count] = id
  death_count += 1
 return actual
func apply_player(state: RunState, amount: float, source: String) -> void:
 if state.player.invulnerability > 0: return
 state.player.hp = maxf(0, state.player.hp - amount)
 state.player.invulnerability = 36
 state.last_damage_source = source
 if state.player.hp <= 0: state.phase = "RESULT"
func total() -> float: return boss_damage + normal_damage
