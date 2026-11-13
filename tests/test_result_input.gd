extends SceneTree
const H:=preload("res://tests/harness.gd")
const Store:=preload("res://scripts/core/save_store.gd")
const Controls:=preload("res://scripts/game/controls.gd")
const Session:=preload("res://scripts/game/session.gd")
const Book:=preload("res://scripts/core/story_book.gd")
var h:=H.new("result_input")
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 3: await process_frame
func axis(which: int,value: float) -> void:
 var e:=InputEventJoypadMotion.new();e.axis=which;e.axis_value=value
 Input.parse_input_event(e);Input.flush_buffered_events();await frames()
func pad(code: int) -> void:
 var e:=InputEventJoypadButton.new();e.button_index=code;e.pressed=true
 Input.parse_input_event(e);Input.flush_buffered_events();await frames()
 e=e.duplicate();e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events();await frames()
func mouse(pos: Vector2,code: int,pressed: bool) -> void:
 var e:=InputEventMouseButton.new();e.position=root.get_final_transform()*pos;e.button_index=code;e.pressed=pressed
 Input.parse_input_event(e);Input.flush_buffered_events()
func key(code: int,down: bool) -> void:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=down
 Input.parse_input_event(e);Input.flush_buffered_events()
func fixture() -> Node:
 Session.story_mode=true;Session.campaign_state=Book.choose(Book.defaults(),"signal")
 change_scene_to_file("res://scenes/main.tscn");await frames()
 var game:=current_scene
 game.set_physics_process(false);game.set_process(false)
 game.store=Store.new("user://result-input.json");game.spawn_timer=99999;game.pickup_timer=99999
 return game
func run() -> void:
 var game:=await fixture()
 var origin: Vector2=game.road_touch_rect.get_center()
 game._update_hud();await frames()
 h.check("PC shortcut panel and pause button never overlap",not game.hint.get_global_rect().intersects(game.pause_button.get_global_rect()))
 mouse(origin,MOUSE_BUTTON_LEFT,true)
 h.check("left mouse immediately fires",game.mouse_fire and game.bullets.size()>0)
 mouse(origin,MOUSE_BUTTON_RIGHT,true)
 h.check("both mouse buttons operate independent weapons",game.mouse_mine and game.mouse_fire and game.mine_drops==1)
 var before_y: float=game.car_y
 key(KEY_W,true)
 for i in 15: game._simulate(1.0/60.0)
 h.check("WASD steering works while holding both mouse weapons",game.car_y<before_y and game.mouse_fire and game.mouse_mine)
 key(KEY_W,false)
 for i in 105: game._simulate(1.0/60.0)
 h.check("held right mouse repeats unlimited rear mines",game.mine_drops>=3)
 mouse(Vector2.ZERO,MOUSE_BUTTON_RIGHT,false)
 h.check("right release over HUD clears only mine",not game.mouse_mine and game.mouse_fire)
 mouse(Vector2.ZERO,MOUSE_BUTTON_LEFT,false)
 h.check("left release over HUD clears fire",not game.mouse_fire)
 game.dodge_cooldown=0;game.comfort_cooldown=0
 game.enemy_bullets=[{"pos":Vector2(game.car_x+20,game.car_y),"vel":Vector2.ZERO,"dmg":8},{"pos":Vector2(game.car_x+150,game.car_y),"vel":Vector2.ZERO,"dmg":8}]
 key(KEY_SHIFT,true);key(KEY_SHIFT,false)
 h.check("Shift activates actual area pulse",game.comfort_count==1 and game.comfort_cooldown>0)
 h.eq("Shift clears only nearby hostile projectiles",game.enemy_bullets.size(),1)
 h.eq("Shift no longer triggers dodge",game.dodge_cooldown,0.0)
 key(KEY_R,true);key(KEY_R,false)
 h.check("R retains direct dodge",game.dodge_cooldown>0)
 mouse(origin,MOUSE_BUTTON_LEFT,true);mouse(origin,MOUSE_BUTTON_RIGHT,true)
 game._set_paused(true)
 h.check("pause clears both mouse holds",not game.mouse_fire and not game.mouse_mine)
 game._set_paused(false)
 game._end_run("survived");await frames()
 h.eq("result starts focused on next chapter",root.gui_get_focus_owner(),game.result_buttons[0])
 await axis(JOY_AXIS_LEFT_X,0.8)
 h.eq("analog right selects garage",root.gui_get_focus_owner(),game.result_buttons[1])
 await axis(JOY_AXIS_LEFT_X,0);await axis(JOY_AXIS_LEFT_X,-0.8)
 h.eq("analog left returns to next chapter",root.gui_get_focus_owner(),game.result_buttons[0])
 await axis(JOY_AXIS_LEFT_X,0)
 await pad(JOY_BUTTON_DPAD_RIGHT)
 h.eq("D-pad right selects garage",root.gui_get_focus_owner(),game.result_buttons[1])
 await pad(JOY_BUTTON_DPAD_LEFT)
 h.eq("D-pad left returns to next chapter",root.gui_get_focus_owner(),game.result_buttons[0])
 await axis(JOY_AXIS_LEFT_Y,0.8)
 h.eq("vertical analog also navigates result",root.gui_get_focus_owner(),game.result_buttons[1])
 await axis(JOY_AXIS_LEFT_Y,0)
 root.content_scale_size=Vector2i(360,780);root.size=Vector2i(360,780);await frames();game._layout();await frames()
 h.eq("portrait layout keeps selected result",root.gui_get_focus_owner(),game.result_buttons[1])
 await axis(JOY_AXIS_LEFT_X,-0.8)
 h.eq("portrait result supports analog left",root.gui_get_focus_owner(),game.result_buttons[0])
 await axis(JOY_AXIS_LEFT_X,0)
 game.result_buttons[0].release_focus()
 await axis(JOY_AXIS_LEFT_X,0.8)
 h.eq("analog recovers focus after pointer focus loss",root.gui_get_focus_owner(),game.result_buttons[1])
 await axis(JOY_AXIS_LEFT_X,0)
 await pad(JOY_BUTTON_A)
 h.check("A activates selected garage without mouse",current_scene.get("stage")=="dialogue" or current_scene.get("stage")=="upgrade")
 root.content_scale_size=Vector2i(640,360);root.size=Vector2i(640,360)
 game=await fixture();game._end_run("survived");await frames();await pad(JOY_BUTTON_A)
 h.check("A activates next chapter without mouse",current_scene.get("choices")!=null and current_scene.campaign["stage"]==1)
 game=await fixture();game._end_run("destroyed");await frames();await pad(JOY_BUTTON_A)
 h.check("A activates retry without advancing chapter",current_scene.get("choices")!=null and current_scene.campaign["stage"]==0)
 Controls.install({"drive_mine":KEY_V})
 var custom:=InputEventKey.new();custom.physical_keycode=KEY_V
 h.check("custom keyboard mine binding remains usable",InputMap.event_is_action(custom,"drive_mine"))
 h.eq("custom keyboard binding survives save sanitization",Store.new().sanitize({"settings":{"bindings":{"drive_mine":KEY_V}}})["settings"]["bindings"].get("drive_mine"),KEY_V)
 Store.new("user://result-input.json").clear();Store.new().clear();Session.story_mode=false;Session.campaign_state={}
 quit(h.finish())
