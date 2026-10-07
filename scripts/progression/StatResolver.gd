extends RefCounted
class_name StatResolver
# Fixed calculation order. Detailed breakdown is produced on demand, never per frame.
func resolve(id: String, state: RunState, db: GameDatabase, include_temporary: bool = true) -> Dictionary:
 var d: Dictionary = db.table("v3_weapons")[id]
 var cfg := db.config()
 var level := int(state.progression.weapons.get(id, 1))
 var p := state.progression.passives
 var passive_stats := PassiveSystem.new().resolve(state,db)
 var char_mod: Dictionary = db.table("characters")[state.player.character].get("modifiers", {})
 var category := str(d.category)
 var base := float(d.damage)
 var leveled := base * (1.0 + (level - 1) * float(cfg.weapon_level_damage))
 var character := leveled * float(char_mod.get("damage_mult", 1))
 var passive := character * (1 + float(passive_stats.get("damage",0))+float(passive_stats.get("meta_damage",0)))
 if str(d.archetype)=="projectile": passive *= 1+float(passive_stats.get("projectile_damage",0))
 if str(d.status)=="poison": passive *= 1+float(passive_stats.get("poison_damage",0))
 var categorized := passive * float(cfg.category_damage.get(category, 1))
 var evolved := categorized * (float(cfg.evolution_damage) if state.progression.evolutions.has(id) else 1.0)
 var synergy := evolved * float(db.table("blessings").get(state.player.blessing, {}).get("modifiers", {}).get("damage_mult", 1))
 for contract in state.player.contracts: synergy *= float(db.table("rune_contracts")[contract].get("damage_mult", 1))
 var temporary := synergy * (float(cfg.get("resonance_damage_mult",1.1)) if include_temporary and state.progression.resonance > 0 else 1.0)
 var final := temporary * pow(float(cfg.overclock_damage), int(state.progression.overclocks.get(id, 0)))
 var cooldown := float(d.cooldown) * maxf(.4, 1 - (level - 1) * float(cfg.weapon_level_cooldown)) * maxf(.675, 1 - -float(passive_stats.get("cooldown",0)))
 for contract in state.player.contracts: cooldown *= float(db.table("rune_contracts")[contract].get("cooldown_mult", 1))
 return {"damage": final, "cooldown_ticks": maxi(1, roundi(cooldown * 60)), "range":float(d.range), "radius":float(d.radius) * (1 + float(passive_stats.get("area",0))), "targets":int(d.targets) + int(passive_stats.get("projectiles",0)) + (int((level-1)/int(d.get("projectile_level_step",3))) if str(d.archetype)=="projectile" else 0), "breakdown":[base,leveled,character,passive,categorized,evolved,synergy,temporary,final]}
