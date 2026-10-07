extends RefCounted
class_name QuestSystem
func settle(run: RunController, save: Dictionary) -> void:
 var p := run.state.progression
 var totals: Dictionary = save.profile.get("metrics",{})
 var local := {"survive_seconds":run.state.field_tick/60.0,"max_combo":p.max_gem_streak,"exploration_chain":p.max_chain,"rooms_in_run":p.rooms.size()}
 for k in local: totals[k] = maxf(float(totals.get(k,0)),float(local[k]))
 totals["total_contracts"] = int(totals.get("total_contracts",0))+run.state.player.contracts.size()
 totals["field_event_successes"] = int(totals.get("field_event_successes",0))+run.field.events_completed
 totals["rooms_discovered"] = int(save.profile.get("total_rooms",0))
 totals["total_kills"] = int(save.profile.get("total_kills",0))
 totals["total_crystals"] = int(save.profile.get("total_crystals",0))
 if not save.progression.has("bosses"): save.progression.bosses = {}
 for id in p.boss_ids: save.progression.bosses[id] = true
 for id in p.evolutions: save.progression.collection[p.evolutions[id]] = true
 save.profile.metrics = totals
 for id in run.db.table("quests"):
  if save.progression.quests.has(id): continue
  var quest: Dictionary = run.db.table("quests")[id]
  var c: Dictionary = quest.condition
  var met := false
  var type := str(c.type)
  if type=="evolved_weapon": met = p.evolutions.has(c.weapon)
  elif type=="boss_defeat": met = save.progression.bosses.has(c.boss)
  elif type=="exploration_rank": met = p.rooms.size() >= 10
  elif totals.has(type): met = float(totals[type]) >= float(c.get("value",0))
  if not met: continue
  save.progression.quests[id] = true
  var reward: Dictionary = quest.get("reward",{})
  save.profile.currency += int(reward.get("currency",0))
  # Unlock/discovery rewards publish goods; they never bypass purchase entitlement.
  if not save.progression.has("available"): save.progression.available = {}
  for key in ["unlock_character","discover_weapon"]:
   if reward.has(key): save.progression.available[reward[key]] = true
