extends RefCounted
class_name WeaponModifiers
var scratch := QueryBuffer.new(1024)
func utility(context,definition: Dictionary,origin: Vector2,radius: float,amount: float,source: String) -> void:
 if context==null: return
 var modifiers: Dictionary=definition.get("modifiers",{})
 if modifiers.has("gem_pull"):
  context.spatial.query_circle(SpatialWorld.GEM,origin,float(modifiers.gem_pull),scratch)
  for n in range(scratch.count): context.gems.magnetize(scratch.ids[n])
 if modifiers.has("mining"):
  context.spatial.query_circle(SpatialWorld.INTERACTABLE,origin,radius,scratch)
  for n in range(scratch.count):
   var id: int=scratch.ids[n]-100
   if id>=0 and id<context.field.active.size() and context.field.active[id] and context.field.kinds[id] not in ["healing_spring","sealed_chest_pillar"]:
    context.field.mine(context,id,amount*float(modifiers.mining),source)
 if modifiers.has("ward"):
  context.state.player.invulnerability=maxi(context.state.player.invulnerability,int(modifiers.ward))
func on_hit(enemies: EnemyWorld,id: int,origin: Vector2,definition: Dictionary,context = null,actual: float = 0,evolved: bool = false) -> void:
 if not enemies.alive(id): return
 var modifiers: Dictionary=definition.get("modifiers",{})
 var i:=enemies.slot(id)
 if context!=null and actual>0:
  if evolved and modifiers.has("lifesteal_evolved"): context.state.player.hp=minf(context.state.player.max_hp,context.state.player.hp+actual*float(modifiers.lifesteal_evolved))
  if enemies.hp[i]<=0: context.state.progression.currency+=int(modifiers.get("currency_kill_bonus",0))
 if modifiers.has("knockback"): enemies.impulses[i]+=(enemies.positions[i]-origin).normalized()*float(modifiers.knockback)*(float(context.state.player.stats.get("char_knockback",1)) if context!=null else 1)
 if modifiers.has("pull"): enemies.impulses[i]+=(origin-enemies.positions[i]).normalized()*float(modifiers.pull)
