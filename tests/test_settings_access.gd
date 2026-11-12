extends SceneTree
const Harness := preload("res://tests/harness.gd")
const SettingsPanel :=  preload("res://scripts/game/settings_panel.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Controls := preload("res://scripts/game/controls.gd")
var h := Harness.new("settings_access")
var reset := false
func _initialize() -> void:
 call_deferred("run")
func key(code: int) -> void:
 var e := InputEventKey.new()
 e.keycode=code
 e.physical_keycode=code
 e.pressed=true
 Input.parse_input_event(e)
 Input.flush_buffered_events()
 var release := e.duplicate()
 release.pressed=false
 Input.parse_input_event(release)
 Input.flush_buffered_events()
func run() -> void:
 var panel := SettingsPanel.new()
 root.add_child(panel)
 await process_frame
 panel.store=Store.new("user://settings-access.json")
 panel.store.clear()
 panel.settings=panel.store.defaults()["settings"].duplicate(true)
 panel.data_reset.connect(func(): reset=true)
 panel.open()
 panel.options["auto_fire"].button_pressed=true
 panel.options["vibration"].button_pressed=true
 await create_timer(0.4).timeout
 h.check("coalesced save persists final toggles",panel.store.load_data()["settings"]["auto_fire"] and panel.store.load_data()["settings"]["vibration"])
 panel.tabs.current_tab=panel.tabs.get_tab_idx_from_control(panel.tabs.get_node("Kontroller"))
 panel.binding_buttons["drive_fire"].pressed.emit()
 key(KEY_LEFT)
 h.check("conflict stays in capture with explanation",panel.capture_action=="drive_fire" and panel.status.text.contains("zaten"))
 key(KEY_J)
 panel.flush()
 h.check("valid remap persists through actual capture UI",panel.capture_action=="" and panel.store.load_data()["settings"]["bindings"].get("drive_fire")==KEY_J)
 h.check("on-screen binding reflects remap",panel.binding_buttons["drive_fire"].text.ends_with("J"))
 panel.binding_buttons["drive_mine"].pressed.emit()
 key(KEY_ESCAPE)
 h.check("Escape cancels capture without closing settings",panel.capture_action=="" and panel.visible)
 panel._show_reset()
 await process_frame
 h.check("reset requires confirmation with cancel focused",panel.reset_dialog.visible and panel.reset_dialog.get_cancel_button().has_focus())
 key(KEY_ESCAPE)
 await process_frame
 h.check("cancel reset preserves data",not reset and panel.store.exists())
 panel._show_reset()
 await process_frame
 panel.reset_dialog.get_ok_button().pressed.emit()
 await process_frame
 h.check("confirmed reset emits success and deletes all saves",reset and not panel.store.exists() and not FileAccess.file_exists(panel.store.path+".bak"))
 h.eq("reset restores default controls",Controls.bindings,{})
 panel.queue_free()
 quit(h.finish())
