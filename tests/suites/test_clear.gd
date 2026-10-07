extends RefCounted
func tags() -> Array: return ["gameplay","deterministic"]
func run(t: TestContext, _tree: SceneTree) -> void:
 var db := GameDatabase.new()
 var run := RunController.new(db,900)
 run.state.field_tick = 53999
 run.state.boss_stage = 2
 run.state.player.hp = 99999
 run.pipeline.tick(run,Vector2.ZERO)
 var boss_id := -1
 for n in range(run.enemies.count):
  var i := run.enemies.dense[n]
  if run.enemies.types[i] == -3: boss_id = run.enemies.entity_id(i)
 t.check(boss_id >= 0,"15min main final boss schedule")
 run.damage.begin_tick()
 run.damage.apply(run.enemies,boss_id,1e9,"weapon:magic_bolt")
 DeathSystem.new().tick(run.state,run.enemies,run.gems,run.damage,run.map)
 t.equal(run.state.phase,"CLEAR","main final boss causes clear")
 run.continue_endless()
 run.state.field_tick = 108000
 run.encounter.boss_schedule(run.state,db,run.map,run.enemies)
 t.check(run.state.boss_stage >= 6,"30min endless boss")
 t.check(run.damage.total() > 0 and run.damage.boss_damage > 0,"result totals")
