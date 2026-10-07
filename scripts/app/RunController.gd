extends RefCounted
class_name RunController
var db: GameDatabase
var state := RunState.new()
var enemies := EnemyWorld.new()
var gems := PickupWorld.new()
var deployments := DeployWorld.new()
var projectiles := ProjectileWorld.new()
var spatial := SpatialWorld.new()
var map := WorldGenerator.new()
var field := FieldRewardSystem.new()
var pending_contract := ""
var contract := ContractSystem.new()
var pending_interact := false
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
 damage.spatial = spatial
 state.seed_value = seed_input
 state.rng.set_seed_value(seed_input)
 map.generate(state.rng.stream_seed("map"))
 field.generate(map,db)
 state.player.character = character
 var c: Dictionary = db.table("characters")[character]
 state.player.max_hp += float(c.get("modifiers",{}).get("hp_flat",0))
 state.player.max_hp*=float(c.get("modifiers",{}).get("hp_mult",1))
 state.player.hp = state.player.max_hp
 state.player.speed = float(db.config().player_speed) * float(c.get("modifiers",{}).get("move_mult",1))
 state.progression.weapons[c.initial_weapon] = 1
 unlocked = equipment.duplicate()
 if unlocked.is_empty():
  unlocked = [c.initial_weapon,"might","magnet","cooldown","move_speed","area","regen"]
 state.player.stats = PassiveSystem.new().resolve(state,db)
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
 state.player.stats = PassiveSystem.new().resolve(state,db)
 weapons.refresh(state,db)
 combos.refresh(state,db)
 if not pending_contract.is_empty(): state.phase = "CONTRACT"
func continue_endless() -> void:
 if state.phase == "CLEAR":
  state.endless = true
  state.phase = "RUNNING"
func signature() -> int:
 return [state.tick,state.field_tick,state.phase,state.player.position,state.player.hp,state.player.invulnerability,state.player.stats,state.progression.exp,state.progression.level,state.progression.kills,state.progression.currency,state.progression.weapons,state.progression.passives,state.progression.evolutions,state.progression.overclocks,state.progression.named_overclocks,state.progression.rooms,state.progression.metrics,state.progression.terrain_ticks,state.progression.terrain_kills,state.progression.terrain_crystals,state.progression.terrain_bosses,state.progression.elite_kills,state.progression.gem_turret_charge,state.progression.skips,state.progression.banishes_bonus,enemies.positions,enemies.hp,enemies.generation,enemies.dense,enemies.count,enemies.contact,enemies.shock,enemies.poison,enemies.periodic,enemies.slow,enemies.action,enemies.warning,enemies.flags,enemies.impulses,gems.magnetized,gems.magnet_count,gems.positions,gems.values,gems.active,projectiles.positions,projectiles.velocities,projectiles.damage,projectiles.life,projectiles.homing,projectiles.bounces,projectiles.statuses,projectiles.seen_count,deployments.positions,deployments.directions,deployments.lengths,deployments.amounts,deployments.remaining,deployments.clocks,deployments.count,projectiles.count,projectiles.remaining_hits,projectiles.seen_ids,weapons.cooldowns,combos.cooldowns,damage.totals,damage.overkill,field.positions,field.hp,field.active,field.event,field.events.deadline,field.events.danger_ticks,field.events.impact_tick,field.events.impact_position,state.rng.snapshot()].hash()

func interact() -> void: pending_interact = true
