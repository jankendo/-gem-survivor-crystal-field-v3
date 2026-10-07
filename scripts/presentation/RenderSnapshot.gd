extends RefCounted
class_name RenderSnapshot
var positions := PackedVector2Array()
var colors := PackedColorArray()
var sizes := PackedFloat32Array()
var warnings := PackedVector2Array()
var warning_origins:=PackedVector2Array()
var warning_boss:=PackedByteArray()
var warning_radius := 120.0
var types := PackedInt32Array()
var count := 0
var boss_indices:=PackedInt32Array()
var boss_count:=0
func _init() -> void:
 types.resize(600)
 positions.resize(600)
 colors.resize(600)
 sizes.resize(600)
 boss_indices.resize(600)
func capture(world: EnemyWorld) -> void:
 count = world.count
 boss_count=0
 warnings.clear()
 warning_origins.clear()
 warning_boss.clear()
 for n in range(count):
  var i := world.dense[n]
  types[n] = world.types[i]
  positions[n] = world.positions[i]
  sizes[n] = world.radius[i] * 2
  if world.flags[i]&1:
   boss_indices[boss_count]=n
   boss_count+=1
  colors[n] = Color(.95,.3,.45) if world.flags[i]&1 else Color(.95,.65,.25) if world.flags[i]&2 else Color(.3,.9,.75)
  if world.slow[i] > 0: colors[n] = Color(.4,.7,1)
  if world.warning[i] > 0:
   warnings.append(world.attack_target[i])
   warning_origins.append(world.positions[i])
   warning_boss.append(1 if world.flags[i]&1 else 0)
