extends RefCounted
## One shared Godot theme: dark by default, native typography, consistent geometry.
const LEXEND := preload("res://assets/fonts/Lexend.ttf")
const SYMBOLS := preload("res://assets/fonts/ControlSymbols.ttf")
const PALETTES := {
 "dark":{"background":"0b1016","surface":"14202b","control":"223746","hover":"304b5b","pressed":"1d504b","text":"f5f1e8","muted":"b6c5ce","border":"6b8596","focus":"9de1c3","brand":"f4a8c5","accent":"9de1c3","warning":"ffd18a","error":"ffb4ab","success":"9de1c3","empty":"101a23"},
 "light":{"background":"edece5","surface":"fff9ec","control":"e2e6dc","hover":"cdded3","pressed":"b7d8c6","text":"152633","muted":"405866","border":"536e7a","focus":"12664e","brand":"8d244f","accent":"12664e","warning":"754a0b","error":"9a2424","success":"12664e","empty":"d4dfde"}
}
static var resolved := "dark"
static var preference := "dark"
static var font_choice := "system"
static var system_dark := true
static var _theme: Theme
static var _panels: Dictionary = {}
static var _buttons: Dictionary = {}
static var _system_font: Font
static var _lexend_font: Font

static func color(role: String) -> Color:
 return Color(PALETTES[resolved].get(role,PALETTES[resolved]["text"]))

static func configure(mode: String,font_mode: String,dark_system := true) -> void:
 preference=mode if mode in ["dark","light","system"] else "dark"
 font_choice=font_mode if font_mode in ["system","lexend"] else "system"
 system_dark=dark_system
 resolved=("dark" if system_dark else "light") if preference=="system" else preference
 if _theme==null: _theme=Theme.new()
 _theme.default_font=_font()
 _theme.default_font_size=12
 for type in ["Label","Button","CheckButton","OptionButton","LineEdit","PopupMenu","TabBar"]:
  _theme.set_color("font_color",type,color("text"))
  for key in ["font_hover_color","font_focus_color","font_pressed_color","font_selected_color"]:
   _theme.set_color(key,type,color("text"))
  _theme.set_color("font_disabled_color",type,color("muted"))
 _theme.set_color("font_unselected_color","TabBar",color("muted"))
 _theme.set_color("font_placeholder_color","LineEdit",color("muted"))
 for role in ["brand","accent","muted","warning","error","success"]:
  var variant: String = str(role).capitalize()+"Label"
  _theme.set_type_variation(variant,"Label")
  _theme.set_color("font_color",variant,color(role))
 for key in _panels: _paint_panel(_panels[key],key)
 for key in _buttons: _paint_button(_buttons[key],key)
 for type in ["TabContainer","PopupMenu","AcceptDialog"]:
  _theme.set_stylebox("panel",type,panel())
 for type in ["Button","OptionButton","LineEdit"]:
  for state in ["normal","hover","pressed","focus","disabled"]:
   _theme.set_stylebox(state,type,_button_style(state))
 for state in ["tab_selected","tab_unselected","tab_hovered","tab_focus"]:
  _theme.set_stylebox(state,"TabBar",_button_style({"tab_selected":"pressed","tab_unselected":"normal","tab_hovered":"hover","tab_focus":"focus"}[state]))
 _theme.emit_changed()

static func _font() -> Font:
 if font_choice=="lexend":
  if _lexend_font==null:
   _lexend_font=LEXEND.duplicate()
   _lexend_font.fallbacks=[SYMBOLS]
  return _lexend_font
 if _system_font==null:
  if OS.has_feature("web"):
   # Browsers do not expose local font files to the Godot filesystem.
   # Use Godot's readable bundled UI fallback without a font-permission prompt.
   _system_font=ThemeDB.fallback_font.duplicate()
   _system_font.fallbacks=[SYMBOLS]
  else:
   var native := SystemFont.new()
   native.font_names=PackedStringArray(["system-ui","sans-serif","Segoe UI","Roboto","Arial"])
   native.fallbacks=[SYMBOLS]
   _system_font=native
 return _system_font

static func font_status() -> Dictionary:
 return {"choice":font_choice,"family":_font().get_font_name(),"native_system":font_choice=="system" and not OS.has_feature("web"),"web_fallback":font_choice=="system" and OS.has_feature("web")}

static func theme() -> Theme:
 if _theme==null: configure(preference,font_choice,system_dark)
 return _theme

static func panel(accent := Color("6b8596")) -> StyleBoxFlat:
 var key := accent.to_html(false)
 if not _panels.has(key):
  _panels[key]=StyleBoxFlat.new()
  _paint_panel(_panels[key],key)
 return _panels[key]

static func caption() -> StyleBoxFlat:
 if not _panels.has("compact"):
  _panels["compact"]=StyleBoxFlat.new()
  _paint_panel(_panels["compact"],"compact")
 return _panels["compact"]

static func _paint_panel(style: StyleBoxFlat,key: String) -> void:
 style.bg_color=color("surface")
 style.border_color=color("accent") if key in ["9de1c3","aaf2d3"] else (color("brand") if key=="f4a8c5" else color("border"))
 style.set_border_width_all(1)
 style.set_content_margin_all(2 if key=="compact" else 10)
 style.anti_aliasing=false

static func _button_style(state: String) -> StyleBoxFlat:
 if not _buttons.has(state):
  _buttons[state]=StyleBoxFlat.new()
  _paint_button(_buttons[state],state)
 return _buttons[state]

static func _paint_button(style: StyleBoxFlat,state: String) -> void:
 style.bg_color=color({"normal":"control","hover":"hover","pressed":"pressed","disabled":"empty"}.get(state,"control"))
 style.border_color=color("focus" if state=="focus" else "border")
 if state=="focus": style.bg_color=Color.TRANSPARENT
 style.set_border_width_all(2 if state=="focus" else 1)
 style.set_content_margin_all(5)
 style.anti_aliasing=false

static func style_button(button: Button) -> void:
 button.theme=theme()
 for state in ["normal","hover","pressed","focus","disabled"]:
  button.add_theme_stylebox_override(state,_button_style(state))

static func box(_path: String,_margin: int,content := -1) -> StyleBox:
 # UI surfaces share the palette; scene artwork remains unchanged.
 return panel()

static func prepare_confirmation(dialog: ConfirmationDialog) -> void:
 dialog.theme=theme()
 style_button(dialog.get_ok_button())
 style_button(dialog.get_cancel_button())
 dialog.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 dialog.get_label().custom_minimum_size.x=340
 dialog.window_input.connect(func(event: InputEvent):
  if event is InputEventJoypadButton and event.is_action_pressed("ui_cancel"):
   dialog.hide()
   dialog.canceled.emit()
   dialog.set_input_as_handled())
 dialog.about_to_popup.connect(func():
  var width: float=dialog.get_tree().root.get_visible_rect().size.x
  dialog.get_label().custom_minimum_size.x=minf(340,width-64)
  dialog.size.x=mini(dialog.size.x,int(width-24))
  dialog.get_cancel_button().call_deferred("grab_focus"))
