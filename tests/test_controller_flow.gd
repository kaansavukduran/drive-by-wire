extends SceneTree
const Harness := preload("res://tests/harness.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Store := preload("res://scripts/core/save_store.gd")
var h := Harness.new("controller_flow")
func _initialize() -> void:
 call_deferred("run")
func frames(count := 3) -> void:
 for i in count: await process_frame
func button(code: int,pressed := true) -> void:
 var e := InputEventJoypadButton.new()
 e.button_index=code
 e.pressed=pressed
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func tap(code: int) -> void:
 button(code)
 await frames(1)
 button(code,false)
 await frames(2)
func axis(code: int,value: float) -> void:
 var e := InputEventJoypadMotion.new()
 e.axis=code
 e.axis_value=value
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func run() -> void:
 change_scene_to_file("res://scenes/title.tscn")
 await frames()
 var title := current_scene
 await tap(JOY_BUTTON_DPAD_DOWN)
 h.eq("D-pad selects garage on title",root.gui_get_focus_owner(),title.menu_buttons[1])
 await tap(JOY_BUTTON_A)
 await frames()
 h.check("A opens focused garage from title",current_scene.get("stage")!=null)
 await tap(JOY_BUTTON_B)
 await frames()
 title=current_scene
 await tap(JOY_BUTTON_A)
 await frames()
 h.check("story briefing offers three first decisions",current_scene.get("choices")!=null and current_scene.choices.size()==3)
 await tap(JOY_BUTTON_A)
 await frames()
 var game := current_scene
 if not h.check("A starts from focused title without a keyboard",game!=title and game.get("lane")!=null):
  quit(h.finish())
  return
 game.spawn_timer=9999.0
 game.pickup_timer=9999.0
 game.set_physics_process(false)
 axis(JOY_AXIS_LEFT_X,0.15)
 h.eq("stick drift cannot steer",game.lane,1)
 axis(JOY_AXIS_LEFT_X,-0.5)
 for i in 25: game._simulate(1.0/60.0)
 h.check("analog stick moves continuously",game.car_x<315)
 axis(JOY_AXIS_LEFT_X,-0.8)
 for i in 25: game._simulate(1.0/60.0)
 h.check("held stick reaches bounded road edge",game.car_x>=235 and game.car_x<265)
 axis(JOY_AXIS_LEFT_X,0.0)
 axis(JOY_AXIS_LEFT_X,0.6)
 for i in 25: game._simulate(1.0/60.0)
 h.check("opposite tilt moves back without rearming",game.car_x>265)
 axis(JOY_AXIS_LEFT_X,0)
 axis(JOY_AXIS_TRIGGER_RIGHT,1)
 h.check("RT fires",game.bullets.size()>0)
 axis(JOY_AXIS_TRIGGER_RIGHT,0)
 await tap(JOY_BUTTON_X)
 h.eq("X drops mine",game.mines_left,2)
 await tap(JOY_BUTTON_Y)
 h.check("Y offers MOMO support",game.comfort_cooldown>0)
 h.eq("hints switch to controller",Controls.last_device,"pad")
 await tap(JOY_BUTTON_START)
 h.check("Start pauses",game.paused and game.pause_panel.visible)
 # Idempotent focus-loss/disconnect must preserve an open settings panel.
 await tap(JOY_BUTTON_DPAD_DOWN)
 await tap(JOY_BUTTON_A)
 game._set_paused(true)
 h.check("settings retains focus while world is paused",game.settings_panel.visible and not game.pause_panel.visible)
 await tap(JOY_BUTTON_RIGHT_SHOULDER)
 h.eq("RB changes settings page",game.settings_panel.tabs.current_tab,1)
 await tap(JOY_BUTTON_B)
 h.check("B returns to pause menu",not game.settings_panel.visible and game.pause_panel.visible)
 await tap(JOY_BUTTON_DPAD_DOWN)
 await tap(JOY_BUTTON_DPAD_DOWN)
 await tap(JOY_BUTTON_A)
 h.check("leaving unfinished run asks with safe default",game.abandon_dialog.visible and game.abandon_dialog.get_cancel_button().has_focus())
 await tap(JOY_BUTTON_B)
 await frames()
 h.check("B cancels leaving without unpausing",not game.abandon_dialog.visible and game.paused and game.pause_panel.visible)
 await tap(JOY_BUTTON_B)
 h.check("B resumes pause menu",not game.paused)
 game.save["settings"]["auto_fire"]=true
 game.fire_cooldown=0
 game.bullets.clear()
 game._physics_process(1.0/60.0)
 h.check("auto fire works without held input",game.bullets.size()>0)
 Input.joy_connection_changed.emit(0,false)
 h.check("controller disconnect pauses safely",game.paused)
 Input.joy_connection_changed.emit(0,true)
 h.check("reconnect does not unexpectedly resume",game.paused)
 h.check("duplicate remap rejected",Controls.binding_error("drive_fire",KEY_LEFT,false,{})!="")
 h.check("pause key cannot be stolen",Controls.binding_error("drive_fire",KEY_ESCAPE,false,{})!="")
 Controls.install({"drive_fire":KEY_J,"drive_left":KEY_K},{"drive_fire":JOY_BUTTON_LEFT_STICK})
 Controls.last_device="keyboard"
 var key := InputEventKey.new()
 key.physical_keycode=KEY_J
 h.check("custom keyboard key enters native InputMap",InputMap.event_is_action(key,"drive_fire") and Controls.run_hint().contains("K") and not Controls.run_hint().contains("A/D"))
 var pad := InputEventJoypadButton.new()
 pad.button_index=JOY_BUTTON_LEFT_STICK
 h.check("custom pad button enters native InputMap",InputMap.event_is_action(pad,"drive_fire"))
 game.store=Store.new("user://controller-test.json")
 game.distance=1200
 game._simulate(1.0/60.0) # remains paused
 await tap(JOY_BUTTON_START)
 game._simulate(1.0/60.0)
 h.check("run reaches result with pad",game.over)
 await tap(JOY_BUTTON_B)
 await frames()
 var garage := current_scene
 h.check("B on result opens garage",garage.get("stage")!=null)
 if garage.get("stage")!=null:
  # Native directional focus and accept select a dialogue, then an upgrade.
  await tap(JOY_BUTTON_DPAD_DOWN)
  h.check("D-pad navigates into garage choices",root.gui_get_focus_owner().get_parent()==garage.buttons)
  await tap(JOY_BUTTON_A)
  await frames()
  h.eq("A selects dialogue",garage.stage,"upgrade")
  await tap(JOY_BUTTON_A)
  await frames()
  h.eq("A selects focused upgrade",garage.stage,"ready")
 await tap(JOY_BUTTON_B)
 await frames()
 h.check("B returns from garage to title",current_scene.get("start_button")!=null)
 Store.new("user://controller-test.json").clear()
 quit(h.finish())
