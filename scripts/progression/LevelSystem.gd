extends RefCounted
class_name LevelSystem
var loadout := LoadoutSystem.new()
func collect(value: int, state: RunState, db: GameDatabase, unlocked: Array) -> void:
 state.progression.exp += value
 state.progression.gem_turret_charge=mini(99,state.progression.gem_turret_charge+1)
 var p := state.progression
 if state.tick-p.last_pickup_tick > 300: p.gem_streak=0
 p.last_pickup_tick = state.tick
 p.gem_streak += 1
 p.max_gem_streak = maxi(p.max_gem_streak,p.gem_streak)
 state.progression.gems += 1
 offer(state, db, unlocked)
func offer(state: RunState, db: GameDatabase, unlocked: Array) -> void:
 if state.phase != "RUNNING": return
 var p := state.progression
 var required := int(db.config().exp_base) + p.level * int(db.config().exp_level)
 if p.exp < required or not p.choices.is_empty(): return
 p.exp -= required
 p.level += 1
 var options := loadout.candidates(state, db, unlocked)
 options = state.rng.stream_rng("reward",str(p.level)+":"+str(p.reward_roll)).shuffled(options)
 p.choices = options.slice(0, mini(3, options.size()))
 if p.choices.is_empty():
  p.choices=OverclockSystem.new().candidates(state,db).slice(0,3)
 if not p.choices.is_empty(): state.phase = "LEVEL_UP"
func select(index: int, state: RunState, db: GameDatabase) -> void:
 if index < 0 or index >= state.progression.choices.size(): return
 var choice: Array = state.progression.choices[index]
 if choice[0] == "overclock": OverclockSystem.new().apply(choice,state,db)
 else: loadout.apply(choice, state, db)
 state.progression.choices.clear()
 EvolutionSystem.new().refresh(state, db)
 state.phase = "RUNNING"

func reroll(state: RunState, db: GameDatabase, unlocked: Array) -> bool:
 var p := state.progression
 if state.phase!="LEVEL_UP" or p.rerolls_used >= 1+int(state.player.stats.get("rerolls",0)): return false
 var options := loadout.candidates(state,db,unlocked)
 if options.is_empty(): options=OverclockSystem.new().candidates(state,db)
 if options.is_empty(): return false
 p.rerolls_used += 1
 p.reward_roll += 1
 p.choices = state.rng.stream_rng("reward",str(p.level)+":"+str(p.reward_roll)).shuffled(options).slice(0,3)
 return true
func banish(state: RunState) -> bool:
 var p := state.progression
 if state.phase!="LEVEL_UP" or p.choices.is_empty() or p.banishes_used >= 1+state.progression.banishes_bonus+int(state.player.stats.get("banishes",0)): return false
 p.banishes_used += 1
 var choice: Array = p.choices.pop_back()
 p.banished.append(choice[1])
 if p.choices.is_empty(): state.phase="RUNNING"
 return true
