extends RefCounted
func tags() -> Array: return ["gameplay","unit"]
func run(t: TestContext, _tree: SceneTree) -> void:
 var db := GameDatabase.new()
 var run := RunController.new(db,234)
 var hp := run.state.player.max_hp
 run.pending_contract = "blood_pact"
 run.state.phase = "CONTRACT"
 t.check(run.contract.accept(run),"contract accepted")
 t.equal(run.state.player.max_hp,hp*.8,"contract health tradeoff")
 t.check(run.state.player.contracts.has("blood_pact"),"contract recorded")
 t.equal(run.state.phase,"RUNNING","contract resumes run")
 run.state.progression.choices = [["weapons","magic_bolt"],["weapons","thunder_chain"]]
 run.state.phase = "LEVEL_UP"
 t.check(run.pipeline.level.banish(run.state),"banish candidate")
 t.check(run.state.progression.banished.has("thunder_chain"),"banish persists in run")
 run.state.phase = "RUNNING"
 t.check(not run.pipeline.level.reroll(run.state,db,run.unlocked),"reroll unavailable outside level up")
 var save := SaveMigration.new().defaults()
 save.profile.total_kills = 5000
 QuestSystem.new().settle(run,save)
 t.check(save.progression.quests.has("kill_5000"),"original quest condition and reward")
 t.check(not save.progression.unlocked.has("mirror_shard"),"quest never bypasses shop purchase")
 var currency: int = save.profile.currency
 QuestSystem.new().settle(run,save)
 t.equal(save.profile.currency,currency,"quest reward once")
 var effects := PresentationEvents.new()
 for n in range(1000): effects.emit(Vector2(n,0),0)
 t.equal(effects.count,PresentationEvents.CAPACITY,"bounded presentation buffer")
 t.check(effects.dropped>0,"cosmetic saturation tracked")
 var signature := run.signature()
 effects.clear()
 t.equal(run.signature(),signature,"cosmetic events cannot mutate simulation")

 for phase in ["RESULT","CLEAR"]:
  run.state.phase = phase
  run.state.progression.exp = 100000
  run.state.progression.choices.clear()
  run.pipeline.level.collect(50,run.state,db,run.unlocked)
  t.equal(run.state.phase,phase,"pickup cannot override terminal "+phase)
  t.check(run.state.progression.choices.is_empty(),"no terminal upgrade modal "+phase)
 var capped:=RunController.new(db,456)
 capped.state.progression.weapons={"magic_bolt":8}
 capped.state.progression.passives={"might":5}
 capped.unlocked=["magic_bolt","might"]
 capped.state.progression.evolutions={"magic_bolt":"starbreaker_bolt"}
 capped.state.phase="LEVEL_UP"
 capped.state.progression.choices=OverclockSystem.new().candidates(capped.state,db).slice(0,3)
 t.check(capped.pipeline.level.reroll(capped.state,db,capped.unlocked),"reroll retains overclock fallback")
 t.check(not capped.state.progression.choices.is_empty(),"reroll does not create empty modal")
 capped.state.progression.choices=[["overclock","magic_bolt","comet_orbit"]]
 t.check(capped.pipeline.level.banish(capped.state),"banish last choice")
 t.equal(capped.state.phase,"RUNNING","empty banish resumes simulation")
 t.check(OverclockSystem.new().candidates(capped.state,db).is_empty(),"banished weapon cannot reappear as overclock")
