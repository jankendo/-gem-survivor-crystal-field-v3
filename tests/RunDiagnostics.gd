extends RefCounted
class_name RunDiagnostics
# QA-only: no dependency from shipped scripts; local JSON, no network/identifiers.
var run: RunController
var timeline: Array=[]
var levels: Array=[]
var bosses: Array=[]
var input_segments: Array=[]
var last_direction:=Vector2(99,99)
var last_signature:=0
var last_evolution_count:=0
var last_warp:=false
var selection_us: Array=[]
var previous_choice_tick:=-1000
var consecutive_choices:=0
var damage_taken:=0.0
var hit_count:=0
var boss_hit_count:=0
var boss_active_ticks:=0
var dodge_ticks:=0
var opportunity_ticks:=0
var previous_hp:=0.0
var evolving_at:=0
func _init(controller: RunController) -> void:
 run=controller; previous_hp=run.state.player.hp
func input(direction: Vector2) -> void:
 if direction!=last_direction:
  input_segments.append([run.state.tick,direction.x,direction.y]);last_direction=direction
func selected(choice: Array,elapsed_us: int) -> void:
 var tick:=run.state.tick
 if tick-previous_choice_tick<=1: consecutive_choices+=1
 previous_choice_tick=tick
 levels.append({"tick":tick,"field_tick":run.state.field_tick,"level":run.state.progression.level,"choice":choice.duplicate()})
 selection_us.append(elapsed_us)
func observe() -> void:
 var s:=run.state
 if s.player.hp<previous_hp:
  damage_taken+=previous_hp-s.player.hp;hit_count+=1
  if s.last_damage_source.begins_with("boss:"): boss_hit_count+=1
 previous_hp=s.player.hp
 var id:=run.enemies.boss_id
 if run.enemies.alive(id):
  var slot:=run.enemies.slot(id)
  var row: Dictionary={}
  for b in bosses:
   if b.id==id: row=b;break
  if row.is_empty():
   row={"id":id,"spawn_tick":s.field_tick,"stage":-run.enemies.types[slot],"HP_at_spawn":s.player.hp,"max_hp":run.enemies.max_hp[slot],"dodging_ticks":0,"opportunity_ticks":0,"damage_start":run.damage.boss_damage,"phase":"telegraph/pursuit"}
   bosses.append(row);timeline.append({"boss_spawn":s.field_tick,"stage":row.stage})
  boss_active_ticks+=1
  var dodging: bool=run.enemies.warning[slot]>0
  dodge_ticks+=int(dodging);row.dodging_ticks+=int(dodging)
  var distance:=run.enemies.positions[slot].distance_to(s.player.position)
  var reachable:=false
  for n in range(run.weapons.stats.size()):
   var archetype: String=run.weapons.definitions[n].archetype
   var reach: float=run.weapons.stats[n].radius if archetype in ["aura","orbit","arc"] else run.weapons.stats[n].range
   if distance<=reach: reachable=true;break
  opportunity_ticks+=int(reachable);row.opportunity_ticks+=int(reachable)
 for row in bosses:
  if not run.enemies.alive(row.id) and not row.has("TTK_seconds"):
   row.TTK_seconds=(s.field_tick-int(row.spawn_tick))/60.0;row.HP_at_death=s.player.hp
   row.actual_damage=run.damage.boss_damage-float(row.damage_start)
   timeline.append({"boss_death":s.field_tick,"stage":row.stage})
 if s.progression.evolutions.size()>last_evolution_count:
  timeline.append({"evolution":s.field_tick,"evolutions":s.progression.evolutions.duplicate()})
  last_evolution_count=s.progression.evolutions.size()
 if run.warp.active!=last_warp:
  timeline.append({"warp":run.warp.active,"tick":s.tick,"field_tick":s.field_tick});last_warp=run.warp.active
func report(build: String) -> Dictionary:
 var s:=run.state
 var minutes:=maxf(1,s.field_tick/3600.0)
 var wall_sum:=0.0
 for value in selection_us: wall_sum+=value
 return {"seed":s.seed_value,"character":s.player.character,"build":build,"phase":s.phase,"clear":s.progression.bosses>=3,"survival_seconds":s.field_tick/60.0,"HP":s.player.hp,"final_level":s.progression.level,"weapons":s.progression.weapons,"passives":s.progression.passives,"evolutions":s.progression.evolutions,"bosses":bosses,"level_choices":levels.size(),"choices_per_minute":levels.size()/minutes,"consecutive_choices":consecutive_choices,"bot_selection_mean_ms":wall_sum/maxi(1,selection_us.size())/1000,"selection_wall_note":"Automated decision execution only; NOT human reading time or display duration.","damage_taken":run.damage.player_damage_total,"hit_count":run.damage.player_hit_count,"boss_hit_count":run.damage.player_boss_hits,"dodge_seconds":dodge_ticks/60.0,"attack_opportunity_seconds":opportunity_ticks/60.0,"opportunity_note":"Geometric range envelope, not guaranteed landed attacks; deploy activation and walls may reduce it.","last_damage_source":s.last_damage_source,"damage":run.damage.totals,"timeline":timeline,"levels":levels,"input_segments":input_segments,"signature":run.signature(),"input_policy":"Tick-indexed direction held for6 ticks; choices/interactions recorded. QA files never used by release runtime."}
