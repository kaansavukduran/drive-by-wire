extends Node
## Appearance preferences use the existing local save and native Godot theme.
const Store := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
signal changed
var dark_system := true
var browser_callback: JavaScriptObject
var media: JavaScriptObject
func _ready() -> void:
 if OS.has_feature("web"):
  media=JavaScriptBridge.get_interface("window").matchMedia("(prefers-color-scheme: dark)")
  dark_system=bool(media.matches)
  browser_callback=JavaScriptBridge.create_callback(_browser_change)
  media.addEventListener("change",browser_callback)
 elif DisplayServer.is_dark_mode_supported():
  dark_system=DisplayServer.is_dark_mode()
  DisplayServer.set_system_theme_change_callback(_native_change)
 apply(Store.new().load_data()["settings"])
func _browser_change(args: Array) -> void:
 dark_system=bool(args[0].matches)
 apply({"theme":UiSkin.preference,"font":UiSkin.font_choice})
func _native_change() -> void:
 dark_system=DisplayServer.is_dark_mode()
 apply({"theme":UiSkin.preference,"font":UiSkin.font_choice})
func apply(settings: Dictionary) -> void:
 UiSkin.configure(str(settings.get("theme","dark")),str(settings.get("font","system")),dark_system)
 get_tree().root.theme=UiSkin.theme()
 RenderingServer.set_default_clear_color(UiSkin.color("background"))
 if OS.has_feature("web"):
  JavaScriptBridge.eval("document.documentElement.dataset.theme='%s';document.documentElement.style.colorScheme='%s';" % [UiSkin.resolved,UiSkin.resolved])
 changed.emit()
 get_tree().call_group("appearance_views","queue_redraw")
func cache(settings: Dictionary) -> void:
 if OS.has_feature("web"):
  JavaScriptBridge.eval("try{localStorage.setItem('dbw.appearance',JSON.stringify(%s))}catch(e){}" % JSON.stringify({"theme":settings.get("theme","dark"),"font":settings.get("font","system")}))
func _exit_tree() -> void:
 if media!=null and browser_callback!=null: media.removeEventListener("change",browser_callback)
