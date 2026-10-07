extends RefCounted
class_name UILayoutInspector
# Native runtime geometry, including clipping ancestors; no layout-coordinate oracle.
func visible_rect(control: Control) -> Rect2:
 var rect := control.get_global_rect()
 var parent := control.get_parent()
 while parent!=null:
  if parent is Control and parent.clip_contents: rect=rect.intersection(parent.get_global_rect())
  parent=parent.get_parent()
 return rect.intersection(Rect2(Vector2.ZERO,control.get_viewport_rect().size))
func inside(rect: Rect2,bounds: Rect2) -> bool:
 return bounds.grow(1).encloses(rect)
func overlaps(controls: Array[Control]) -> Array[String]:
 var errors: Array[String]=[]
 for i in range(controls.size()):
  var a:=visible_rect(controls[i])
  if not a.has_area(): continue
  for j in range(i+1,controls.size()):
   var b:=visible_rect(controls[j])
   if not b.has_area(): continue
   var overlap:=a.intersection(b)
   if overlap.size.x>1 and overlap.size.y>1 and not controls[i].get_meta("intentional_overlay",false) and not controls[j].get_meta("intentional_overlay",false): errors.append(str(controls[i].name)+" / "+str(controls[j].name))
 return errors
func inspect(app,screen: String) -> Array[String]:
 var errors: Array[String]=[]
 var bounds:=Rect2(app.ui.global_position,app.ui.size)
 var controls: Array[Control]=[]
 for c in app.controller.view.controls[screen].values():
  if not (c is Button or c is LineEdit) or not c.is_visible_in_tree(): continue
  controls.append(c)
  if c.size.y<44: errors.append(str(c.name)+" target height <44")
  var rect:=visible_rect(c)
  if rect.has_area() and not inside(rect,bounds): errors.append(str(c.name)+" outside safe area")
  if c.get_parent().name=="Actions" and not inside(c.get_global_rect(),bounds): errors.append(str(c.name)+" primary clipped/offscreen")
  if screen!="HUD" and not (c is Button and c.disabled) and c.focus_mode==Control.FOCUS_NONE: errors.append(str(c.name)+" unreachable keyboard")
 errors.append_array(overlaps(controls))
 return errors
