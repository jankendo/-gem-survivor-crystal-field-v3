extends RefCounted
class_name DeployWorld
const CAPACITY := 128
var pulls := PackedFloat32Array()
var knockbacks := PackedFloat32Array()
var directions := PackedVector2Array()
var lengths := PackedFloat32Array()
var positions := PackedVector2Array()
var radii := PackedFloat32Array()
var amounts := PackedFloat64Array()
var remaining := PackedInt32Array()
var clocks := PackedInt32Array()
var periods := PackedInt32Array()
var mines := PackedByteArray()
var slow_ticks := PackedInt32Array()
var statuses := PackedInt32Array()
var sources := PackedStringArray()
var targets := PackedInt32Array()
var dense := PackedInt32Array()
var free_slots := PackedInt32Array()
var count := 0
var free_count := CAPACITY
var scratch := QueryBuffer.new(600)
func _init() -> void:
 pulls.resize(CAPACITY)
 knockbacks.resize(CAPACITY)
 directions.resize(CAPACITY)
 lengths.resize(CAPACITY)
 positions.resize(CAPACITY)
 radii.resize(CAPACITY)
 amounts.resize(CAPACITY)
 remaining.resize(CAPACITY)
 clocks.resize(CAPACITY)
 periods.resize(CAPACITY)
 mines.resize(CAPACITY)
 slow_ticks.resize(CAPACITY)
 statuses.resize(CAPACITY)
 sources.resize(CAPACITY)
 targets.resize(CAPACITY)
 dense.resize(CAPACITY)
 free_slots.resize(CAPACITY)
 for i in range(CAPACITY): free_slots[i]=CAPACITY-1-i
func add(pos: Vector2,radius: float,damage: float,source: String,target_count: int,definition: Dictionary,direction: Vector2 = Vector2.RIGHT) -> bool:
 if free_count==0: return false
 free_count-=1
 var i:=free_slots[free_count]
 var modifiers: Dictionary=definition.get("modifiers",{})
 pulls[i]=float(modifiers.get("pull",0))
 knockbacks[i]=float(modifiers.get("knockback",0))*float(definition.get("knockback_scale",1))
 directions[i]=direction.normalized()
 lengths[i]=float(modifiers.get("beam_length",0))
 positions[i]=pos
 radii[i]=radius
 amounts[i]=damage
 sources[i]=source
 targets[i]=target_count
 mines[i]=int(modifiers.get("trap",false))
 remaining[i]=int(modifiers.get("duration_ticks",180))
 periods[i]=int(modifiers.get("pulse_ticks",60))
 clocks[i]=30 if mines[i] else 1
 slow_ticks[i]=int(definition.get("slow_ticks",90))
 statuses[i]=["","slow","shock","poison"].find(str(definition.status))
 if not mines[i]: amounts[i]/=maxi(1,remaining[i]/periods[i])
 dense[count]=i
 count+=1
 return true
func remove_at(n: int) -> void:
 var i:=dense[n]
 count-=1
 dense[n]=dense[count]
 free_slots[free_count]=i
 free_count+=1
func tick(enemies: EnemyWorld,spatial: SpatialWorld,damage: DamageSystem) -> void:
 for n in range(count-1,-1,-1):
  var i:=dense[n]
  remaining[i]-=1
  clocks[i]=maxi(0,clocks[i]-1)
  var explode := false
  if clocks[i]==0:
   if lengths[i]>0: spatial.query_segment(SpatialWorld.ENEMY,positions[i],positions[i]+directions[i]*lengths[i],30,scratch)
   else: spatial.query_circle(SpatialWorld.ENEMY,positions[i],radii[i],scratch)
   var hits:=0
   for k in range(scratch.count):
    var id:=scratch.ids[k]
    if not enemies.alive(id) or enemies.hp[enemies.slot(id)]<=0: continue
    damage.apply(enemies,id,amounts[i],sources[i])
    var slot:=enemies.slot(id)
    if pulls[i]>0: enemies.impulses[slot]+=(positions[i]-enemies.positions[slot]).normalized()*pulls[i]
    if knockbacks[i]>0: enemies.impulses[slot]+=(enemies.positions[slot]-positions[i]).normalized()*knockbacks[i]
    if statuses[i]==1: enemies.slow[slot]=slow_ticks[i]
    elif statuses[i]==2: enemies.shock[slot]=90
    elif statuses[i]==3: enemies.poison[slot]=180
    hits+=1
    if hits>=targets[i]: break
   explode=mines[i]!=0 and hits>0
   clocks[i]=periods[i] if not mines[i] else 0
  if explode or remaining[i]<=0: remove_at(n)
