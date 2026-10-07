extends RefCounted
class_name PassiveSystem
func resolve(state: RunState, db: GameDatabase) -> Dictionary:
 var result: Dictionary = {}
 for key in ["meta_damage","meta_magnet"]:
  if state.player.stats.has(key): result[key] = state.player.stats[key]
 for id in state.progression.passives:
  for stat in db.table("v3_passives").get(id, {}): result[stat] = float(result.get(stat,0)) + float(db.table("v3_passives")[id][stat]) * int(state.progression.passives[id])
 var c: Dictionary=db.table("characters")[state.player.character].get("modifiers",{})
 var mapping := {"magnet_mult":"magnet","crystal_damage_mult":"mining","crystal_reward_mult":"mining_reward","currency_mult":"currency","corridor_move_mult":"corridor_move","exploration_reward_mult":"field_reward","spawn_mult":"spawn","rare_reward_bonus":"rare_reward","weapon_core_bonus":"weapon_core"}
 for source in mapping:
  if c.has(source): result[mapping[source]]=float(result.get(mapping[source],0))+float(c[source])-(0 if source.ends_with("bonus") else 1)
 result.char_slow=float(c.get("slow_mult",1))
 result.char_knockback=float(c.get("knockback_mult",1))
 result.char_contract_effect=float(c.get("contract_effect_mult",1))
 result.contract_resist=float(result.get("contract_resist",0))+1-float(c.get("curse_penalty_mult",1))
 result.char_corridor_armor=1-float(c.get("corridor_defense_mult",1))
 result.char_open_move=float(c.get("open_move_mult",1))-1
 result.char_event_damage=float(c.get("event_damage_mult",1))
 result.char_unexplored_damage=float(c.get("unexplored_damage_mult",1))
 result.char_explored_damage=float(c.get("explored_damage_mult",1))
 result.char_danger_reward=float(c.get("danger_reward_mult",1))
 result.char_gimmick_damage=float(c.get("terrain_gimmick_mult",1))
 result.char_gimmick_area=float(c.get("terrain_gimmick_area_mult",1))
 result.char_compass_range=float(c.get("map_reveal_mult",1))
 result.char_gem_damage=float(db.config().get("gem_pickup_damage",3)) if c.get("gem_damage",false) else 0
 result.char_crystal_poison=bool(c.get("crystal_poison_burst",false))
 result.char_kill_heal=float(c.get("kill_heal_chance",0))
 result.char_incoming=float(c.get("damage_taken_mult",1))
 result.char_boss_damage=float(c.get("boss_damage_mult",1))
 result.char_gem_value=float(c.get("gem_value_mult",1))
 if state.player.evolved:
  var evolved: Dictionary=db.table("character_evolutions").get(state.player.character,{})
  result.magnet=float(result.get("magnet",0))+float(evolved.get("subtraits",{}).get("magnet_mult",1))-1
  result.char_gem_value*=float(evolved.get("modifiers",{}).get("gem_value_mult",1))
 result.char_healing=float(c.get("healing_mult",1))
 return result
