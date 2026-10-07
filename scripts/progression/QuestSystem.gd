extends RefCounted
class_name QuestSystem
func settle(run: RunController, save: Dictionary) -> void:
 ProgressMetrics.new().settle(run,save)
 var conditions := ConditionSystem.new()
 for id in run.db.table("quests"):
  if save.progression.quests.has(id): continue
  var quest: Dictionary = run.db.table("quests")[id]
  if not conditions.met(save,quest.condition): continue
  save.progression.quests[id]=true
  var reward: Dictionary = quest.get("reward",{})
  save.profile.currency+=int(reward.get("currency",0))
  if not save.progression.has("available"): save.progression.available={}
  for key in ["unlock_character","discover_weapon"]:
   if reward.has(key): save.progression.available[reward[key]]=true
  if reward.has("secret_flag"): save.progression.secret_flags[reward.secret_flag]=true
