extends RefCounted
class_name LevelSystem
var loadout := LoadoutSystem.new()
func collect(value: int, state: RunState, db: GameDatabase, unlocked: Array) -> void:
 state.progression.exp += value
 state.progression.gems += 1
 offer(state, db, unlocked)
func offer(state: RunState, db: GameDatabase, unlocked: Array) -> void:
 var p := state.progression
 var required := int(db.config().exp_base) + p.level * int(db.config().exp_level)
 if p.exp < required or not p.choices.is_empty(): return
 p.exp -= required
 p.level += 1
 var options := loadout.candidates(state, db, unlocked)
 options = state.rng.stream_rng("reward", p.level).shuffled(options)
 p.choices = options.slice(0, mini(3, options.size()))
 if p.choices.is_empty():
  for id in p.evolutions:
   if int(p.overclocks.get(id, 0)) < 2: p.choices.append(["overclock", id])
 if not p.choices.is_empty(): state.phase = "LEVEL_UP"
func select(index: int, state: RunState, db: GameDatabase) -> void:
 if index < 0 or index >= state.progression.choices.size(): return
 var choice: Array = state.progression.choices[index]
 if choice[0] == "overclock": state.progression.overclocks[choice[1]] = int(state.progression.overclocks.get(choice[1], 0)) + 1
 else: loadout.apply(choice, state, db)
 state.progression.choices.clear()
 EvolutionSystem.new().refresh(state, db)
 state.phase = "RUNNING"
