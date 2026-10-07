extends RefCounted
class_name StatResolver
# Fixed calculation order. Detailed breakdown is produced on demand, never per frame.
func resolve(id: String, state: RunState, db: GameDatabase, include_temporary: bool = true) -> Dictionary:
 var oc:=OverclockSystem.new().factors(id,state,db)
 var d: Dictionary = db.table("v3_weapons")[id]
 var cfg := db.config()
 var level := int(state.progression.weapons.get(id, 1))
 var p := state.progression.passives
 var passive_stats := PassiveSystem.new().resolve(state,db)
 var char_mod: Dictionary = db.table("characters")[state.player.character].get("modifiers", {})
 var category := str(d.category)
 var base := float(d.damage)
 var leveled := base * (1.0 + (level - 1) * float(cfg.weapon_level_damage))
 if state.player.evolved: leveled*=float(db.table("character_evolutions").get(state.player.character,{}).get("modifiers",{}).get("damage_mult",1))
 var character := leveled * float(char_mod.get("damage_mult", 1))
 var tags: Array=db.table("weapons")[id].get("tags",[])
 for tag in tags: character*=float(char_mod.get("tag_damage",{}).get(tag,1))
 var passive := character * (1 + float(passive_stats.get("damage",0))+float(passive_stats.get("meta_damage",0)))
 if str(d.archetype)=="projectile": passive *= 1+float(passive_stats.get("projectile_damage",0))
 if str(d.status)=="poison": passive *= 1+float(passive_stats.get("poison_damage",0))
 var categorized := passive * float(cfg.category_damage.get(category, 1))
 var evolved := categorized * (float(cfg.evolution_damage) if state.progression.evolutions.has(id) else 1.0)
 if state.progression.evolutions.has(id): evolved*=float(char_mod.get("evolved_damage_mult",1))
 var synergy := evolved * float(db.table("blessings").get(state.player.blessing, {}).get("modifiers", {}).get("damage_mult", 1))
 for contract in state.player.contracts: synergy *= float(db.table("rune_contracts")[contract].get("damage_mult", 1))
 var temporary := synergy * (float(cfg.get("resonance_damage_mult",1.1)) if include_temporary and state.progression.resonance > 0 else 1.0)
 var final := temporary * pow(float(cfg.overclock_damage)+float(char_mod.get("overclock_bonus",0)), maxi(0,int(state.progression.overclocks.get(id, 0))-state.progression.named_overclocks.get(id,[]).size())) * float(oc.damage)
 var cooldown := float(d.cooldown) * maxf(.4, 1 - (level - 1) * float(cfg.weapon_level_cooldown)) * maxf(.675, 1 - -float(passive_stats.get("cooldown",0)))
 cooldown*=float(oc.cooldown)
 cooldown*=float(char_mod.get("cooldown_mult",1))
 var area_mult:=1.0
 for tag in tags:
  cooldown*=float(char_mod.get("tag_cooldown",{}).get(tag,1))
  area_mult*=float(char_mod.get("tag_area",{}).get(tag,1))
 for contract in state.player.contracts: cooldown *= float(db.table("rune_contracts")[contract].get("cooldown_mult", 1))
 return {"damage": final, "cooldown_ticks": maxi(1, roundi(cooldown * 60)), "range":float(d.range), "radius":float(d.radius) * float(oc.area) * area_mult * (1 + float(passive_stats.get("area",0))), "bounce_bonus":int(char_mod.get("bounce_bonus",0)),"targets":int(d.targets) + int(oc.targets) + (int(char_mod.get("chain_bonus",0)) if str(d.archetype)=="chain" else 0) + int(passive_stats.get("projectiles",0)) + (int((level-1)/int(d.get("projectile_level_step",3))) if str(d.archetype)=="projectile" else 0), "breakdown":[base,leveled,character,passive,categorized,evolved,synergy,temporary,final]}
