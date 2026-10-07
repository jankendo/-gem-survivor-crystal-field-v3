extends RefCounted
class_name SafeArea
func logical_rect(viewport: Vector2, window: Vector2, physical_safe: Rect2i) -> Rect2:
 if window.x <= 0 or window.y <= 0: return Rect2(Vector2.ONE*16,viewport-Vector2.ONE*32)
 var scale := minf(window.x / viewport.x,window.y / viewport.y)
 var offset := (window - viewport * scale) * .5
 var pos := (Vector2(physical_safe.position) - offset) / scale
 var end := (Vector2(physical_safe.end) - offset) / scale
 return Rect2(pos.max(Vector2.ZERO),end.min(viewport)-pos.max(Vector2.ZERO)).grow(-16)
func apply(control: Control) -> void:
 var size := control.get_viewport_rect().size
 var window := Vector2(DisplayServer.window_get_size())
 var physical := DisplayServer.get_display_safe_area()
 var rect := Rect2(Vector2.ONE*16,size-Vector2.ONE*32)
 if OS.has_feature("ios") and physical.size.x > 0: rect = logical_rect(size,window,physical)
 control.position = rect.position
 control.size = rect.size
