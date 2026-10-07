extends RefCounted
func tags() -> Array: return ["unit","gameplay","deterministic"]
func run(t: TestContext,_tree: SceneTree) -> void:
 var db:=GameDatabase.new()
 var mio:=RunController.new(db,333,"mio")
 t.equal(mio.weapons.definitions[0].slow_ticks,113,"Mio slow duration preserves trait")
 var nero:=RunController.new(db,333,"nero")
 t.check(is_equal_approx(nero.state.player.stats.spawn,.15),"Nero spawn pressure")
 t.equal(ContractSystem.new().effect(nero.state,{"damage_mult":1.2},"damage_mult"),1.25,"Nero magnifies contract benefit")
 t.equal(ContractSystem.new().effect(nero.state,{"max_hp_mult":.8},"max_hp_mult"),.75,"contract strength includes cost")
 var lily:=RunController.new(db,333,"lily")
 t.equal(lily.state.player.stats.rare_reward,.06,"rare reward is additive probability")
 var forge:=RunController.new(db,333,"forge_master")
 t.equal(forge.state.player.stats.weapon_core,.2,"Forge weapon-core probability")
 var knight:=RunController.new(db,333,"corridor_knight")
 t.check(knight.state.player.stats.char_corridor_armor>.19,"corridor defense")
 var mapper:=RunController.new(db,333,"cave_mapper")
 t.equal(mapper.state.player.stats.char_compass_range,1.5,"map utility feeds presentation compass")
 var void_run:=RunController.new(db,333,"void_cartographer")
 void_run.state.progression.resonance=60
 void_run.pipeline.tick(void_run,Vector2.ZERO)
 t.check(void_run.state.player.stats.context_damage>.34,"new-room resonance enhances Void damage")
 void_run.state.progression.resonance=0
 void_run.pipeline.tick(void_run,Vector2.ZERO)
 t.check(void_run.state.player.stats.context_damage<0,"explored room tradeoff")
 var relic:=RunController.new(db,333,"relic_hunter")
 t.check(relic.state.player.stats.contract_resist>.19,"curse penalty resistance")
 var atlas:=RunController.new(db,333,"atlas")
 var enemy:=atlas.enemies.spawn(0,Vector2(20,0),{"hp":100,"radius":18})
 WeaponModifiers.new().on_hit(atlas.enemies,enemy,Vector2.ZERO,db.table("v3_weapons").sonic_wave,atlas)
 t.equal(atlas.enemies.impulses[atlas.enemies.slot(enemy)].x,275.0,"Atlas actual knockback")
 var collector:=RunController.new(db,333,"collector")
 t.equal(collector.weapons.ids,["coin_orbit"],"Collector has a functional gem-themed starting attack")
 for character in db.table("characters"):
  var signatures: Array=[]
  for mode in [[30,1],[60,1],[30,2],[60,2]]:
   var run:=RunController.new(db,334,character)
   run.speed=mode[1]
   run.state.player.hp=1e6
   run.state.player.max_hp=1e6
   var input:=func(tick: int) -> Vector2: return Vector2.RIGHT.rotated(tick*.002)
   while run.state.tick<180:
    run.advance(minf(1.0/mode[0],float(180-run.state.tick)/60/run.speed),input)
    if run.state.phase=="LEVEL_UP": run.select(0)
   signatures.append(run.signature())
  t.check(signatures[0]==signatures[1] and signatures[0]==signatures[2] and signatures[0]==signatures[3],"character render/speed parity "+str(character))
