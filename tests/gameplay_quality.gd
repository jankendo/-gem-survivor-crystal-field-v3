extends SceneTree
const BUILDS: Dictionary={
 "ranged":{"character":"noah","equipment":["magic_bolt","thunder_chain","bomb_seed","laser_lance","might","cooldown","area","regen","armor","elite_hunter"]},
 "melee":{"character":"mio","equipment":["ice_orbit","blade_fan","poison_mist","sonic_wave","might","cooldown","area","regen","armor","magnet"]},
 "deploy":{"character":"gantz","equipment":["rune_gate","bomb_seed","guardian_wall","thorn_seed","might","cooldown","area","regen","armor","elite_hunter"]},
 "area":{"character":"atlas","equipment":["sonic_wave","ice_orbit","poison_mist","blade_fan","might","cooldown","area","regen","armor","magnet"]},
 "hybrid":{"character":"rai","equipment":["thunder_chain","laser_lance","ice_orbit","bomb_seed","might","cooldown","area","regen","armor","elite_hunter"]},
 "utility":{"character":"collector","equipment":["coin_orbit","black_hole","gravity_anchor","gem_turret","might","cooldown","area","regen","armor","magnet"]}}
func _initialize() -> void: call_deferred("play")
func play() -> void:
 var seeds: Array=[60606,20261007,314159]
 var chosen:=""
 var night:=false
 var seed_override:=-1
 for arg in OS.get_cmdline_user_args():
  if arg=="--nightly": night=true
  if arg.begins_with("--seed="): seed_override=int(arg.get_slice("=",1))
  if arg.begins_with("--build="): chosen=arg.get_slice("=",1)
 if night: seeds=[60606,20261007,314159,271828,9001]
 if seed_override>=0: seeds=[seed_override]
 var db:=GameDatabase.new()
 var reports: Array=[]
 for seed in seeds:
  for build in BUILDS:
   if not chosen.is_empty() and build!=chosen: continue
   var spec: Dictionary=BUILDS[build]
   var r:=RunController.new(db,seed,spec.character,spec.equipment)
   var driver:=AutoplayDriver.new()
   var diagnostics:=RunDiagnostics.new(r)
   var direction:=Vector2.ZERO
   var started:=Time.get_ticks_usec()
   while r.state.tick<66000 and r.state.phase not in ["CLEAR","RESULT"]:
    if r.state.phase=="LEVEL_UP":
     var choice:=driver.choice(r)
     var selected: Array=r.state.progression.choices[choice].duplicate()
     var stamp:=Time.get_ticks_usec()
     r.select(choice);diagnostics.selected(selected,Time.get_ticks_usec()-stamp)
     continue
    if r.state.phase=="CONTRACT": r.resolve_contract(false)
    if r.state.tick%6==0: direction=driver.direction(r,"close_range" if build in ["melee","area"] else "balanced")
    diagnostics.input(direction)
    if r.state.tick%120==0: r.interact()
    r.pipeline.tick(r,direction)
    diagnostics.observe()
   var report:=diagnostics.report(build)
   report.wall_seconds=(Time.get_ticks_usec()-started)/1e6
   report.outcome="TIME_LIMIT" if r.state.phase=="RUNNING" else r.state.phase
   reports.append(report)
   DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
   FileAccess.open("res://test-output/quality-"+str(seed)+"-"+str(build)+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
   print("QUALITY ",build," seed=",seed," phase=",r.state.phase," choices=",report.level_choices," seconds=",report.survival_seconds)
 var ok:=not reports.is_empty()
 for row in reports:
  ok=ok and row.phase in ["CLEAR","RESULT","RUNNING"] and is_finite(row.HP) and row.survival_seconds>0 and row.level_choices>0 and not row.bosses.is_empty()
 var result: Dictionary={"ok":ok,"runs":reports,"note":"Normal HP/spawn, six representative identities, recorded deaths are measurements rather than forced clears. TIME_LIMIT is an explicitly incomplete run, never a clear. Measurement validity gates finite HP, progression and a reached boss; existing ranged/melee full-clear CI remains separate. Not human fun or real-time device proof."}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 var suffix:=str(seed_override) if seed_override>=0 else "multi"
 FileAccess.open("res://test-output/gameplay-quality-"+suffix+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 quit(0 if ok else 1)
