extends RefCounted
class_name UITokens
const GAP := 8
const MARGIN := 12
const TOUCH := 48
const TEXT := Color("eff7ff")
const BACKGROUND := Color("101b2b")
const ACCENT := Color("7de9ff")
func box(color: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
 var value := StyleBoxFlat.new()
 value.bg_color = color
 value.border_color = border
 value.set_border_width_all(width)
 value.set_corner_radius_all(6)
 value.content_margin_left = MARGIN
 value.content_margin_right = MARGIN
 value.content_margin_top = GAP
 value.content_margin_bottom = GAP
 return value
func build() -> Theme:
 var value := Theme.new()
 var font := SystemFont.new()
 font.font_names = PackedStringArray(["Noto Sans CJK JP","Yu Gothic","Hiragino Sans","Noto Sans JP"])
 value.default_font = font
 value.default_font_size = 18
 value.set_color("font_color","Label",TEXT)
 value.set_color("font_outline_color","Label",BACKGROUND)
 value.set_constant("outline_size","Label",3)
 value.set_color("font_color","Button",TEXT)
 value.set_color("font_disabled_color","Button",Color("bcc8d8"))
 value.set_color("font_focus_color","Button",TEXT)
 value.set_stylebox("panel","PanelContainer",box(BACKGROUND))
 value.set_stylebox("normal","Button",box(Color("24354d")))
 value.set_stylebox("hover","Button",box(Color("314861"),ACCENT,1))
 value.set_stylebox("pressed","Button",box(Color("42596f"),Color.WHITE,2))
 value.set_stylebox("focus","Button",box(Color.TRANSPARENT,ACCENT,3))
 value.set_stylebox("disabled","Button",box(Color("263140"),Color("7e8a9b"),1))
 value.set_type_variation("PrimaryButton","Button")
 value.set_stylebox("normal","PrimaryButton",box(Color("21566a"),ACCENT,1))
 value.set_type_variation("DangerButton","Button")
 value.set_stylebox("normal","DangerButton",box(Color("663841"),Color("ffb8b8"),1))
 for kind in ["VBoxContainer","HBoxContainer","GridContainer","HFlowContainer"]:
  value.set_constant("separation",kind,GAP)
  value.set_constant("h_separation",kind,GAP)
  value.set_constant("v_separation",kind,GAP)
 return value
