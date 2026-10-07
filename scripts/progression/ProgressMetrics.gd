extends RefCounted
class_name ProgressMetrics
const TERRAINS := ["crystal_corridor","oasis","mine_chamber","danger_den","relic_vault","shortcut"]
func settle(run: RunController,save: Dictionary) -> void:
 var p := run.state.progression
 if p.metrics_settled: return
 p.metrics_settled=true
 var m: Dictionary = save.profile.get("metrics",{})
 for type in ["terrain_time","terrain_kills","terrain_crystals","terrain_boss_defeat"]:
  var values: Dictionary = m.get(type,{})
  var source: PackedInt32Array = p.terrain_ticks if type=="terrain_time" else p.terrain_kills if type=="terrain_kills" else p.terrain_crystals if type=="terrain_crystals" else p.terrain_bosses
  for i in range(TERRAINS.size()): values[TERRAINS[i]]=float(values.get(TERRAINS[i],0))+float(source[i])/(60.0 if type=="terrain_time" else 1.0)
  m[type]=values
 for type in ["weapon_kills","gimmick_count","field_drop_count"]:
  var values: Dictionary = m.get(type,{})
  for id in p.metrics.get(type,{}): values[id]=int(values.get(id,0))+int(p.metrics[type][id])
  m[type]=values
 for type in ["total_chests","cursed_relics","shortcut_walls","oasis_healing","low_hp_time"]:
  m[type]=float(m.get(type,0))+float(p.metrics.get(type,0))
 m.survive_seconds=maxf(float(m.get("survive_seconds",0)),run.state.field_tick/60.0)
 m.survive_runs=int(m.get("survive_runs",0))+int(run.state.field_tick>=36000)
 m.total_gems_collected=int(m.get("total_gems_collected",0))+p.gems
 m.total_currency_earned=int(m.get("total_currency_earned",0))+run.state.settlement_reward
 m.total_kills=int(save.profile.get("total_kills",0))
 m.total_crystals=int(save.profile.get("total_crystals",0))
 m.rooms_discovered=int(save.profile.get("total_rooms",0))
 m.rooms_in_run=maxi(int(m.get("rooms_in_run",0)),p.rooms.size())
 m.max_combo=maxi(int(m.get("max_combo",0)),p.max_gem_streak)
 m.exploration_chain=maxi(int(m.get("exploration_chain",0)),p.max_chain)
 m.total_contracts=int(m.get("total_contracts",0))+run.state.player.contracts.size()
 m.field_event_successes=int(m.get("field_event_successes",0))+run.field.events_completed
 var rank := "SS" if p.rooms.size()>=20 else "S" if p.rooms.size()>=12 else "A" if p.rooms.size()>=10 else "B" if p.rooms.size()>=6 else "C" if p.rooms.size()>=3 else "D"
 if ["D","C","B","A","S","SS"].find(rank)>["D","C","B","A","S","SS"].find(str(m.get("exploration_rank","D"))): m.exploration_rank=rank
 var explosion := 0
 for id in p.weapons:
  if db_category(run,id)=="explosion": explosion+=1
 m.run_explosion_weapons=maxi(int(m.get("run_explosion_weapons",0)),explosion)
 save.profile.metrics=m
 for name in ["weapon_levels","evolved_weapons","bosses","secret_flags"]:
  if not save.progression.has(name): save.progression[name]={}
 for id in p.weapons: save.progression.weapon_levels[id]=maxi(int(save.progression.weapon_levels.get(id,0)),p.weapons[id])
 for id in p.evolutions: save.progression.evolved_weapons[id]=true
 for id in p.boss_ids: save.progression.bosses[id]=true
 if p.metrics.get("reaper",false): save.progression.secret_flags.reaper=true
 if float(m.get("terrain_time",{}).get("relic_vault",0))>=300 and float(m.get("low_hp_time",0))>=60: save.progression.secret_flags.ghost=true
func db_category(run: RunController,id: String) -> String: return str(run.db.table("weapons")[id].get("category",""))
