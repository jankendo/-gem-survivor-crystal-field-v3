extends RefCounted
func tags() -> Array: return ["unit","UI","gameplay","release"]
func contrast(a: Color,b: Color) -> float:
 var high:=a.srgb_to_linear(); var low:=b.srgb_to_linear()
 var x:=.2126*high.r+.7152*high.g+.0722*high.b
 var y:=.2126*low.r+.7152*low.g+.0722*low.b
 return (maxf(x,y)+.05)/(minf(x,y)+.05)
func run(t: TestContext,tree: SceneTree) -> void:
 var malformed:=SaveMigration.new().defaults()
 malformed.profile.metrics="invalid"
 t.check(not SaveMigration.new().valid(malformed),"malformed nested save metrics rejected before shop")
 malformed=SaveMigration.new().defaults(); malformed.progression.bosses=[]
 t.check(not SaveMigration.new().valid(malformed),"malformed nested unlock counters rejected")
 var db:=GameDatabase.new()
 var valid:=db.tables.duplicate(true)
 db.tables.clear()
 t.check(not DataValidator.new().validate(db).is_empty(),"empty database rejected before gameplay")
 db.tables=valid.duplicate(true); db.tables.evolutions["broken"]={}
 t.check(not DataValidator.new().validate(db).is_empty(),"missing evolution fields detected without crash")
 db.tables=valid.duplicate(true); db.tables.weapons.magic_bolt="bad-shape"
 t.check(not DataValidator.new().validate(db).is_empty(),"malformed entity definition fails gracefully")
 db.tables=valid.duplicate(true); db.tables.evolutions["broken"]={"weapon":"absent","passive":"might"}
 t.check(not DataValidator.new().validate(db).is_empty(),"invalid data reference caught")
 db.tables=valid.duplicate(true); db.tables.characters.noah.generated_sprite="res://missing-required.svg"
 t.check(not DataValidator.new().validate(db).is_empty(),"critical missing asset detected")
 db.tables=valid.duplicate(true)
 db.tables.field_gimmicks.healing_spring.generated_icon="res://missing-optional.svg"
 t.check(DataValidator.new().validate(db).is_empty(),"optional icon failure permits visible procedural/text fallback")
 t.check(not DataValidator.new().validate(db,true).is_empty(),"strict release validator detects optional missing reference")
 db.tables=valid
 var progression_save:=SaveMigration.new().defaults()
 progression_save.profile.metrics={"total_kills":17}
 t.check(ConditionSystem.new().progress_label(progression_save,{"type":"total_kills","value":500}).contains("17"),"quest progress uses actual saved metric")
 var run:=RunController.new(db,60606)
 run.state.player.hp=0; run.state.phase="RESULT"
 run.state.player.stats.char_kill_heal=1.0
 var definition: Dictionary=db.table("bosses").values()[2]
 var id:=run.enemies.spawn(-3,Vector2(100,0),definition)
 run.enemies.flags[run.enemies.slot(id)]|=1
 run.damage.apply(run.enemies,id,9999999,"weapon:magic_bolt")
 run.pipeline.death.tick(run.state,run.enemies,run.gems,run.damage,run.map)
 t.equal(run.state.phase,"RESULT","terminal death has priority over simultaneous final boss kill")
 t.equal(run.state.player.hp,0.0,"kill-heal cannot revive terminal death")
 t.equal(run.state.progression.bosses,1,"simultaneous boss kill still counted exactly once")
 t.equal(run.enemies.boss_id,-1,"removed boss lookup cannot remain stale")
 var next_boss:=run.enemies.spawn(-2,Vector2.ZERO,definition)
 t.equal(run.enemies.boss_id,next_boss,"boss lookup includes reused generation")
 var other_boss:=run.enemies.spawn(-1,Vector2.ZERO,definition)
 run.enemies.remove(next_boss)
 t.equal(run.enemies.boss_id,other_boss,"boss removal finds remaining boss")
 t.check(contrast(UITokens.TEXT,UITokens.BACKGROUND)>=7,"body panel text contrast >=7:1")
 t.check(contrast(UITokens.TEXT,Color("21566a"))>=4.5,"primary button contrast >=4.5:1")
 t.check(contrast(Color("bcc8d8"),Color("263140"))>=4.5,"disabled reason text contrast >=4.5:1")
 var theme:=UITokens.new().build()
 t.check(theme.get_stylebox("focus","Button").border_width_left>=3,"focus has non-color border cue")
 var app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_boundary.save"
 tree.root.add_child(app)
 app.set_process(false); app.set_physics_process(false)
 await tree.process_frame
 app.start_run("noah","attack",60606)
 app.run.state.phase="PAUSED"
 app.controller.show_equipment()
 app.db.tables.weapons.magic_bolt.erase("generated_icon")
 app.controller.progression.equipment()
 var slot: Button=app.controller.view.node("EquipmentPanel","Slot0")
 t.check(not slot.text.is_empty() and not slot.tooltip_text.is_empty(),"optional icon absence retains text placeholder and description")
 app.controller.progression.slot(0)
 t.check(app.controller.view.node("DetailPanel","Info").text.contains("魔弾"),"touch opens full equipment description")
 app.run.state.phase="RESULT"; app.run.state.player.hp=0; app.run.state.boss_stage=3; app.run.state.progression.bosses=3
 app.controller.menu.result()
 t.check(app.controller.view.node("ResultScreen","Title").text.contains("クリア済み・死亡"),"endless death displays clear credit and death separately")
 app.queue_free()
 for i in range(4): await tree.process_frame
