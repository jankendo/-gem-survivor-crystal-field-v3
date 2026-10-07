extends RefCounted
func tags() -> Array: return ["UI","unit","gameplay","iOS","release"]
func run(t: TestContext,tree: SceneTree) -> void:
 var db:=GameDatabase.new()
 var save:=SaveMigration.new().normalize(SaveMigration.new().defaults())
 var model:=CollectionModel.new(db)
 model.query="魔弾"; model.update(save)
 t.check(model.filtered.size()>0,"Japanese partial name search")
 model.query="遠距離";model.update(save)
 t.check(model.filtered.any(func(i): return model.entries[i].id=="magic_bolt"),"Japanese actual weapon category search")
 t.check(db.table("weapons").values().all(func(d): return UIStrings.CATEGORIES.has(d.category)),"all real weapon categories have Japanese labels")
 t.equal(UIStrings.new(db).condition({"type":"initial"}),"初期解放","initial content never described as requiring a purchase")
 model.query="魔弾"
 model.category=2; model.update(save)
 t.equal(model.filtered.size(),0,"filter combines with search")
 model.query=""; model.category=1; model.status=1; model.update(save)
 t.check(model.filtered.any(func(i): return model.entries[i].id=="magic_bolt"),"initial weapon correctly shown unlocked")
 model.query="存在しない名前の検索"; model.update(save)
 t.equal(model.filtered.size(),0,"zero search results")
 model.query=""; model.category=6; model.status=0; model.sorting=3
 save.profile.metrics={"survive_seconds":300}
 model.update(save)
 t.check(model.filtered.size()==db.table("quests").size(),"all quests discoverable")
 t.check(model.entries[model.filtered[0]].ratio>=model.entries[model.filtered.back()].ratio,"quest progress sorting")
 var state:=RunController.new(db,777)
 state.state.progression.weapons={"magic_bolt":8,"bomb_seed":1}
 state.state.progression.passives={"might":3}
 var detail:=BuildDetails.new(db)
 var before:=state.signature()
 var text:=detail.equipment("weapons","magic_bolt",state.state)
 t.check(text.contains("現在Lv8") and text.contains("星砕") and text.contains("連携"),"equipment exact level/evolution/combo names")
 t.check(text.contains("相方未所持") or text.contains("成立中"),"relationship ownership state")
 t.equal(state.signature(),before,"detail model never mutates state or RNG")
 state.state.field_tick=17999; state.state.tick=17999
 state.state.progression.passives.might=3
 state.pipeline.tick(state,Vector2.ZERO)
 t.check(state.state.progression.evolutions.has("magic_bolt"),"time-gated evolution does not require a new selection")
 state.state.phase="RUNNING"; state.state.progression.choices.clear(); state.state.progression.gems=300
 state.state.progression.level=25; state.state.progression.kills=5000
 state.state.field_tick=35999; state.state.tick=35999
 state.pipeline.tick(state,Vector2.ZERO)
 t.check(state.state.player.evolved,"character evolution occurs without a level-up panel")
 var app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_alpha2.save"
 tree.root.size=Vector2i(844,390)
 tree.root.add_child(app)
 app.set_process(false); app.set_physics_process(false)
 app.safe_override=Rect2(44,0,756,369); app.resize_ui()
 app.controller.show_collection()
 for i in range(6): await tree.process_frame
 var ui: UIController=app.controller
 ui.view.node("CollectionScreen","Search").text="魔弾"
 for i in range(5): await tree.process_frame
 t.check(ui.collection.model.filtered.size()>0,"UI search updates reusable rows")
 t.check(UILayoutInspector.new().visible_rect(ui.view.node("CollectionScreen","Row0")).size.y>=44,"phone list has fully usable first result")
 var nodes: int=ui.panels.CollectionScreen.get_child_count()
 ui.collection.saved_scroll=0; ui.collection.open_detail(0)
 t.equal(ui.current,"DetailPanel","collection detail is isolated modal")
 ui.back()
 for i in range(8): await tree.process_frame
 t.equal(ui.view.node("CollectionScreen","Search").text,"魔弾","detail Back retains search")
 t.equal(ui.view.node("CollectionScreen","Scroll").scroll_vertical,ui.collection.saved_scroll,"detail Back restores scroll")
 ui.collection.clear()
 t.equal(ui.collection.model.query,"","explicit clear")
 t.equal(ui.panels.CollectionScreen.get_child_count(),nodes,"search retains node tree")
 app.keyboard_points_override=220; app.sync_keyboard_area()
 for i in range(6): await tree.process_frame
 t.check(UILayoutInspector.new().inspect(app,"CollectionScreen").is_empty(),"search keyboard and notch primary actions reachable")
 t.check(ui.view.node("CollectionScreen","Search").size.y>=44,"search touch input target")
 app.keyboard_points_override=0; app.sync_keyboard_area()
 for i in range(6): await tree.process_frame
 t.check(ui.view.node("CollectionScreen","Filters").visible,"keyboard dismissal restores filters")
 app.start_run("noah","attack",60606)
 app.run.state.progression.weapons={"magic_bolt":2,"bomb_seed":1}
 app.run.state.progression.passives={"might":2}
 app.run.state.progression.choices=[["weapons","magic_bolt"]]
 app.run.state.phase="LEVEL_UP"
 ui.sync_phase()
 var card: String=ui.view.node("LevelUpPanel","Choice0").get_node("CardMargin/CardText").text
 t.equal(card.count("進化:"),1,"growth card has one accurate evolution explanation")
 t.check(card.contains("攻撃") and card.contains("→") and card.contains("成立中"),"growth shows numeric difference and actual combo ownership")
 t.check(app.renderer.critical.z_index>app.renderer.effects.z_index,"critical visuals above decoration")
 var visual_boss: int=app.run.enemies.spawn(-3,Vector2(150,0),{"hp":1000,"radius":50},1,true)
 var render_before: int=app.run.signature()
 app.renderer.present(app.run,Vector2(1280,720))
 t.equal(app.run.signature(),render_before,"renderer presentation does not mutate run")
 t.equal(app.renderer.snapshot.boss_count,1,"boss locator reads authoritative snapshot flags")
 app.run.enemies.remove(visual_boss)
 app.renderer.present(app.run,Vector2(1280,720))
 t.equal(app.renderer.snapshot.boss_count,0,"removed boss cannot leave a stale locator")
 app.queue_free()
 for i in range(5): await tree.process_frame
 tree.root.size=Vector2i(1280,720);tree.root.content_scale_size=Vector2i(1280,720)
