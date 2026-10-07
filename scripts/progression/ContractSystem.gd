extends RefCounted
class_name ContractSystem
func accept(run: RunController) -> bool:
 var id := run.pending_contract
 if id.is_empty() or not run.db.table("rune_contracts").has(id): return false
 var d: Dictionary = run.db.table("rune_contracts")[id]
 run.state.player.contracts.append(id)
 var resist := clampf(float(run.state.player.stats.get("contract_resist",0)),0,.6)
 var health := effect(run.state,d,"max_hp_mult")
 health = lerpf(health,1,resist) if health < 1 else health
 run.state.player.max_hp *= health
 run.state.player.hp = minf(run.state.player.hp,run.state.player.max_hp)
 if d.has("crystal_hp_mult"):
  for i in range(run.field.hp.size()):
   if run.field.active[i]: run.field.hp[i] *= effect(run.state,d,"crystal_hp_mult")
 run.pending_contract = ""
 run.weapons.refresh(run.state,run.db)
 run.combos.refresh(run.state,run.db)
 run.state.phase = "RUNNING"
 return true
func multipliers(state: RunState, db: GameDatabase) -> Dictionary:
 var values := {"incoming":1.0,"elite":1.0,"normal":1.0,"gem":1.0,"currency":1.0,"crystal":1.0,"rare":0.0}
 var resist := clampf(float(state.player.stats.get("contract_resist",0)),0,.6)
 for id in state.player.contracts:
  var d: Dictionary = db.table("rune_contracts")[id]
  var incoming := effect(state,d,"damage_taken_mult")
  values.incoming *= lerpf(incoming,1,resist) if incoming > 1 else incoming
  values.elite *= effect(state,d,"elite_damage_mult")
  var normal := effect(state,d,"normal_damage_mult")
  values.normal *= lerpf(normal,1,resist) if normal<1 else normal
  values.gem *= effect(state,d,"gem_mult")
  values.currency *= effect(state,d,"score_mult")
  values.crystal *= effect(state,d,"crystal_reward_mult")
  values.rare += float(d.get("rare_reward_bonus",0))*float(state.player.stats.get("char_contract_effect",1))
 values.currency *= 1+float(state.player.stats.get("contract_reward",0))
 return values
func effect(state: RunState,definition: Dictionary,key: String) -> float:
 return maxf(.05,1+(float(definition.get(key,1))-1)*float(state.player.stats.get("char_contract_effect",1)))
