extends RefCounted
class_name ConditionSystem
# Cold-path evaluator shared by quests and shop. Missing/unknown conditions fail closed.
func met(save: Dictionary, c: Dictionary) -> bool:
 if c.is_empty(): return false
 var type := str(c.get("type",""))
 var target := float(c.get("value",c.get("count",c.get("seconds",c.get("cost",c.get("amount",1))))))
 var metrics: Dictionary = save.profile.get("metrics",{})
 var progress: Dictionary = save.progression
 match type:
  "initial","currency_sink": return true
  "currency": return float(save.profile.currency)>=target
  "weapon_level": return int(progress.get("weapon_levels",{}).get(c.get("weapon",""),0))>=int(c.get("level",1))
  "weapon_kills": return int(metrics.get("weapon_kills",{}).get(c.get("weapon",""),0))>=target
  "boss_defeat": return bool(progress.get("bosses",{}).get(c.get("boss",""),false))
  "evolved_weapon": return bool(progress.get("evolved_weapons",{}).get(c.get("weapon",""),false))
  "character_unlocked": return progress.unlocked.has(c.get("character",""))
  "terrain_time","terrain_kills","terrain_crystals","terrain_boss_defeat": return float(metrics.get(type,{}).get(c.get("terrain",""),0))>=target
  "gimmick_count": return int(metrics.get("gimmick_count",{}).get(c.get("gimmick",""),0))>=target
  "field_drop_count": return int(metrics.get("field_drop_count",{}).get(c.get("drop",""),0))>=target
  "exploration_rank":
   var ranks := ["D","C","B","A","S","SS"]
   var required := ranks.find(str(c.get("rank",c.get("value","D"))))
   return required>=0 and ranks.find(str(metrics.get("exploration_rank","D")))>=required
  "secret_ghost","secret_reaper","secret_collector": return bool(progress.get("secret_flags",{}).get(type.trim_prefix("secret_"),false))
  "secret_void_mapper": return int(metrics.get("rooms_in_run",0))>=12 and met(save,{"type":"exploration_rank","rank":"S"})
  "secret_abyss_merchant": return int(metrics.get("total_currency_earned",0))>=25000 and int(metrics.get("total_contracts",0))>=20
  "specific_title": return bool(progress.get("titles",{}).get(c.get("title",""),false))
  "cursed_walls": return int(metrics.get("total_crystals",0))>=target
  "currency_paid": return int(metrics.get("total_currency_earned",0))>=target
  "danger_time": return float(metrics.get("terrain_time",{}).get("danger_den",0))>=target
 return metrics.has(type) and float(metrics[type])>=target

func progress_label(save: Dictionary,c: Dictionary) -> String:
 var kind:=str(c.get("type",""))
 var target:=float(c.get("value",c.get("count",c.get("seconds",c.get("cost",c.get("amount",1))))))
 var metrics: Dictionary=save.profile.get("metrics",{})
 var progress: Dictionary=save.progression
 var current: float=float(metrics.get(kind,0)) if metrics.get(kind,0) is float or metrics.get(kind,0) is int else 0
 match kind:
  "currency": current=float(save.profile.currency)
  "weapon_level": current=float(progress.get("weapon_levels",{}).get(c.get("weapon",""),0)); target=float(c.get("level",1))
  "weapon_kills": current=float(metrics.get("weapon_kills",{}).get(c.get("weapon",""),0))
  "terrain_time","terrain_kills","terrain_crystals","terrain_boss_defeat": current=float(metrics.get(kind,{}).get(c.get("terrain",""),0))
  "gimmick_count": current=float(metrics.get(kind,{}).get(c.get("gimmick",""),0))
  "field_drop_count": current=float(metrics.get(kind,{}).get(c.get("drop",""),0))
  "cursed_walls": current=float(metrics.get("total_crystals",0))
  "currency_paid": current=float(metrics.get("total_currency_earned",0))
  "danger_time": current=float(metrics.get("terrain_time",{}).get("danger_den",0))
  "exploration_rank": return "現在: ランク"+str(metrics.get("exploration_rank","D"))+" / 必要: "+str(c.get("rank",c.get("value","D")))
  "secret_abyss_merchant": return "現在: %d/25000貨・契約%d/20回" % [int(metrics.get("total_currency_earned",0)),int(metrics.get("total_contracts",0))]
  "secret_void_mapper": return "現在: %d/12部屋・ランク%s / 必要S" % [int(metrics.get("rooms_in_run",0)),str(metrics.get("exploration_rank","D"))]
  "initial","currency_sink","boss_defeat","evolved_weapon","character_unlocked","secret_ghost","secret_reaper","secret_collector","specific_title": return "✓ 条件達成" if met(save,c) else "○ まだ未達成"
 return "現在: %.0f / 必要: %.0f" % [current,target]
