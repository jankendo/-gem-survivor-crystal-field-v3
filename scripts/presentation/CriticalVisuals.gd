extends Node2D
class_name CriticalVisuals
# Last world layer: warnings and player cannot be occluded by cosmetic effects.
var renderer: WorldRenderer
var low_hp:=false
func _draw() -> void:
 if renderer==null: return
 var snapshot:=renderer.snapshot
 for n in range(snapshot.warnings.size()):
  var p:=snapshot.warnings[n]
  if snapshot.warning_boss[n]:
   draw_circle(p,snapshot.warning_radius,Color(1,.12,.1,.10))
   draw_arc(p,snapshot.warning_radius,0,TAU,48,Color(.03,.02,.03),7)
   draw_arc(p,snapshot.warning_radius,0,TAU,48,Color(1,.35,.15),3)
  else:
   draw_line(snapshot.warning_origins[n],p,Color(.03,.02,.03),7)
   draw_line(snapshot.warning_origins[n],p,Color(1,.6,.2),3)
 if renderer.meteor_warning:
  draw_arc(renderer.meteor_position,70,0,TAU,48,Color(.03,.02,.03),7)
  draw_arc(renderer.meteor_position,70,0,TAU,48,Color(1,.45,.1),3)
 var center:=renderer.player_position
 draw_arc(center,27,0,TAU,32,Color(.02,.03,.05),7)
 draw_arc(center,27,0,TAU,32,Color(1,1,.85),3)
 draw_texture_rect(renderer.player_texture,Rect2(center-Vector2(22,22),Vector2(44,44)),false)
 if low_hp:
  draw_line(center+Vector2(-8,-35),center+Vector2(0,-44),Color(1,.4,.25),4)
  draw_line(center+Vector2(0,-44),center+Vector2(8,-35),Color(1,.4,.25),4)
