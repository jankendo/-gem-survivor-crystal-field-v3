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
