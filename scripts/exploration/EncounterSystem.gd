extends RefCounted
class_name EncounterSystem
var budget := 0.0
var threat := 0.0
var spawned := 0
var eligible := PackedInt32Array()
var weights := PackedFloat32Array()
var total_weight := 0.0
var next_unlock := 0.0
func target_alive(state: RunState, db: GameDatabase, risk: bool = false) -> int:
 var targets: Array = db.config().target_alive
 return int(targets[mini(targets.size()-1, state.field_tick / 18000)]) + (20 if risk else 0)
func tick(state: RunState, db: GameDatabase, map: WorldGenerator, enemies: EnemyWorld) -> void:
 var cfg := db.config()
 if state.player.contracts.has("ruin_pact") and state.field_tick%36000==0:
  var reaper := db.enemy_index("reaper")
  if reaper>=0: enemies.spawn(reaper,map.spawn_position(state.player.position,400,600,state.rng),db.enemy_defs[reaper],1.5)
 var room := map.room_at(state.player.position)
 var risk := room >= 0 and map.kinds[room] == "risk"
 var multiplier := 1.0+float(state.player.stats.get("spawn",0))
 for c in state.player.contracts: multiplier *= float(db.table("rune_contracts")[c].get("spawn_mult",1))
 budget = minf(24, budget + float(cfg.refill_per_second) * multiplier / 60.0)
 threat = minf(float(cfg.threat_budget), threat + float(cfg.refill_per_second) / 60.0)
 var target := target_alive(state, db, risk)
 while budget >= 1 and enemies.count < target and enemies.count < int(cfg.enemy_cap):
  var seconds := state.field_tick / 60.0
  if eligible.is_empty() or seconds >= next_unlock: refresh_eligible(db,seconds)
  var roll := state.rng.range_float(0,total_weight)
  var chosen := 0
  for n in range(weights.size()):
   if roll <= weights[n]:
    chosen = n
    break
  var type_id := eligible[chosen]
  var d: Dictionary = db.enemy_defs[type_id]
  var cost := 5.0 if d.get("elite",false) else 1.0
  if threat < cost: break
  var pos := map.spawn_position(state.player.position,450,700,state.rng)
  enemies.spawn(type_id, pos, d, 1 + seconds / 60.0 * float(cfg.enemy_hp_per_minute))
  spawned += 1
  budget -= 1
  threat -= cost
func boss_schedule(state: RunState, db: GameDatabase, map: WorldGenerator, enemies: EnemyWorld) -> void:
 var stage := state.field_tick / 18000
 if stage <= state.boss_stage or enemies.free_count == 0: return
 var definitions := db.table("bosses")
 var key := "boss_" + str(mini(stage * 5, 30))
 if not definitions.has(key): return
 var d: Dictionary = definitions[key].duplicate(true)
 var reference: Array = db.config().boss_reference_dps
 d.hp = float(reference[mini(stage-1,2)]) * float(db.config().boss_ttk_seconds) * (1 + maxf(0,stage-3)*.3)
 var pos := map.spawn_position(state.player.position,380,500,state.rng)
 var id := enemies.spawn(-stage, pos, d, 1, true)
 if id >= 0: state.boss_stage = stage

func refresh_eligible(db: GameDatabase, seconds: float) -> void:
 eligible.clear()
 weights.clear()
 total_weight = 0
 next_unlock = INF
 for i in range(db.enemy_defs.size()):
  var d: Dictionary = db.enemy_defs[i]
  if d.get("boss",false) or float(d.get("weight",0)) <= 0: continue
  var unlock := float(d.get("unlock_seconds",0))
  if unlock > seconds:
   next_unlock = minf(next_unlock,unlock)
   continue
  eligible.append(i)
  total_weight += float(d.weight)
  weights.append(total_weight)
