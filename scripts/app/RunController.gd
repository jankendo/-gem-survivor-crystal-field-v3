extends RefCounted
class_name RunController
var db: GameDatabase
var state := RunState.new()
var enemies := EnemyWorld.new()
var gems := PickupWorld.new()
var projectiles := ProjectileWorld.new()
var spatial := SpatialWorld.new()
var map := WorldGenerator.new()
var encounter := EncounterSystem.new()
var weapons := WeaponRuntime.new()
var damage := DamageSystem.new()
var combos := ComboSystem.new()
var warp := WarpSystem.new()
var pipeline := SimulationPipeline.new()
var unlocked: Array = []
var accumulator := 0.0
var speed := 1
func _init(database: GameDatabase, seed_input: int = 60606, character: String = "noah", equipment: Array = []) -> void:
 db = database
 state.seed_value = seed_input
 state.rng.set_seed_value(seed_input)
 map.generate(state.rng.stream_seed("map"))
 state.player.character = character
 var c: Dictionary = db.table("characters")[character]
 state.player.max_hp += float(c.get("modifiers",{}).get("hp_flat",0))
 state.player.hp = state.player.max_hp
 state.player.speed = float(db.config().player_speed) * float(c.get("modifiers",{}).get("move_mult",1))
 state.progression.weapons[c.initial_weapon] = 1
 unlocked = equipment.duplicate()
 if unlocked.is_empty():
  unlocked = [c.initial_weapon,"might","magnet","cooldown","move_speed","area","regen"]
 weapons.refresh(state,db)
 combos.refresh(state,db)
func advance(render_delta: float, input_at_tick: Callable) -> void:
 if state.phase != "RUNNING": return
 accumulator += render_delta * speed
 while accumulator + .000000001 >= 1.0 / 60.0:
  if state.phase != "RUNNING":
   accumulator = 0
   break
  accumulator -= 1.0 / 60.0
  pipeline.tick(self,input_at_tick.call(state.tick))
func select(index: int) -> void:
 pipeline.level.select(index,state,db)
 weapons.refresh(state,db)
 combos.refresh(state,db)
func continue_endless() -> void:
 if state.phase == "CLEAR":
  state.endless = true
  state.phase = "RUNNING"
func signature() -> int:
 return [state.tick,state.field_tick,state.player.position,state.player.hp,state.progression.exp,state.progression.level,state.progression.kills,state.progression.currency,enemies.positions,enemies.hp,enemies.generation,enemies.dense,enemies.count,gems.positions,gems.values,gems.active,projectiles.positions,projectiles.count,damage.totals,state.rng.snapshot()].hash()
