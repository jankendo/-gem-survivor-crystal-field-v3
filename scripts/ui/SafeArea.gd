extends RefCounted
class_name SafeArea
func logical_rect(viewport: Vector2, window: Vector2, physical_safe: Rect2i) -> Rect2:
 var full := Rect2(Vector2.ZERO,viewport)
 if window.x <= 0 or window.y <= 0 or physical_safe.size.x <= 0 or physical_safe.size.y <= 0: return inset(full)
 var scale := minf(window.x/viewport.x,window.y/viewport.y)
 var offset := (window-viewport*scale)*.5
 var area := Rect2((Vector2(physical_safe.position)-offset)/scale,Vector2(physical_safe.size)/scale).intersection(full)
 if not area.has_area(): return inset(full)
 return inset(area)
func inset(area: Rect2) -> Rect2:
 return area.grow(-minf(12,minf(area.size.x,area.size.y)*.05))
func apply(control: Control, override_rect: Rect2 = Rect2()) -> void:
 var viewport := control.get_viewport_rect().size
 var rect := inset(Rect2(Vector2.ZERO,viewport))
 if OS.has_feature("ios"): rect = logical_rect(viewport,Vector2(control.get_tree().root.size),DisplayServer.get_display_safe_area())
 if override_rect.has_area(): rect = inset(override_rect.intersection(Rect2(Vector2.ZERO,viewport)))
 control.position = rect.position
 control.size = rect.size
