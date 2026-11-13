extends SceneTree
const Harness := preload("res://tests/harness.gd")
const Swipe := preload("res://scripts/game/swipe_steering.gd")
const Journey := preload("res://scripts/core/journey.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
var h := Harness.new("swipe_story")
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func frames(n := 3) -> void:
	for i in n: await process_frame
func touch(id: int,point: Vector2,pressed := true) -> void:
	var event := InputEventScreenTouch.new()
	event.index=id
	event.position=root.get_final_transform()*point
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func drag(id: int,point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=id
	event.position=root.get_final_transform()*point
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func key(code: int,pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode=code
	event.physical_keycode=code
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func mouse(point: Vector2,button: int,pressed := true) -> void:
	var event := InputEventMouseButton.new()
	event.position=root.get_final_transform()*point
	event.button_index=button
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func run() -> void:
	var swipe := Swipe.new()
	var area := Rect2(0,0,200,300)
	swipe.touch(0,Vector2(-10,100),true,area)
	h.eq("touch outside road cannot start steering",swipe.drag(0,Vector2(80,100)),0)
	swipe.touch(0,Vector2(80,100),true,area)
	h.eq("small jitter does not steer",swipe.drag(0,Vector2(95,100)),0)
	h.eq("horizontal swipe commits at threshold",swipe.drag(0,Vector2(120,100)),1)
	h.eq("long/reversed drag cannot skip multiple lanes",swipe.drag(0,Vector2(10,100)),0)
	swipe.touch(0,Vector2.ZERO,false,area)
	swipe.touch(1,Vector2(80,100),true,area)
	h.eq("another finger cannot steal swipe",swipe.drag(2,Vector2(140,100)),0)
	h.eq("vertical gesture is not steering",swipe.drag(1,Vector2(85,160)),0)
	h.eq("vertical gesture remains rejected after diagonal turn",swipe.drag(1,Vector2(150,160)),0)
	swipe.clear()
	h.eq("cancelled pointer cannot steer",swipe.drag(1,Vector2(150,100)),0)
	var steady := Journey.new("steady")
	var supplies := Journey.new("supplies")
	h.check("route choice changes actual support",steady.spec()["max_hp"]>supplies.spec()["max_hp"] and supplies.spec()["mines"]>steady.spec()["mines"])
	h.eq("first distance beat triggers",steady.advance(350).size(),1)
	h.eq("same beat cannot repeat",steady.advance(400).size(),0)
	h.eq("jump across milestones preserves all dialogue",steady.advance(1100).size(),2)
	h.check("journal retains the premise and delivered beats",steady.log_lines.size()==7)
	h.check("support goal depends on player action",not steady.goal_met(0,5) and steady.goal_met(1,0))
	h.check("supply goal needs two capsules",not supplies.goal_met(5,1) and supplies.goal_met(0,2))
	h.check("ending reflects goal success",steady.ending(true,0,0)!=steady.ending(true,1,0))
	h.check("failure has a continuing story",steady.ending(false,1,2)!=steady.ending(true,1,2))
	Session.next_route="steady"
	var safe_game: Node2D=load("res://scenes/main.tscn").instantiate()
	root.add_child(safe_game)
	await frames()
	h.near("steady route adds real maximum health",safe_game.max_hp,safe_game._cfg("player.max_hp",100)+15,0.01)
	safe_game.queue_free()
	await frames()
	Session.next_route="supplies"
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	game.set_physics_process(false)
	game.store=Store.new("user://swipe-story-test.json")
	game.store.clear()
	game.spawn_timer=99999
	game.pickup_timer=99999
	game.touch_enabled=true
	game._sync_touch()
	h.eq("chosen route gives extra mines in the real scene",game.mines_left,int(game._cfg("mine.count",3))+2)
	var road: Rect2=game.road_touch_rect
	var origin := road.get_center()
	var fire: Vector2=game.touch_by_action["drive_fire"].position+game.touch_by_action["drive_fire"].size/2
	var center: Vector2=game.joystick.get_global_rect().get_center()
	var initial: float=game.car_x
	touch(0,center)
	touch(1,fire)
	drag(0,center+Vector2(40,-25))
	for i in 15: game._simulate(1.0/60.0)
	h.check("joystick moves diagonally with independent held fire",game.car_x>initial and game.car_y<game.PLAYER_Y and game._held("drive_fire"))
	touch(0,center,false)
	h.check("releasing steering finger preserves held fire",game._held("drive_fire") and game.joystick.value==Vector2.ZERO)
	touch(1,fire,false)
	h.check("fire release clears held input",not game._held("drive_fire"))
	touch(0,center)
	game._set_paused(true)
	game._set_paused(false)
	drag(0,center-Vector2(70,0))
	h.eq("pre-pause finger cannot cause stale movement",game.joystick.value,Vector2.ZERO)
	key(KEY_A)
	for i in 20: game._simulate(1.0/60.0)
	key(KEY_A,false)
	h.check("A freely steers without text",game.car_x<initial)
	key(KEY_D)
	for i in 20: game._simulate(1.0/60.0)
	key(KEY_D,false)
	h.check("D freely steers without text",game.car_x>initial-30)
	key(KEY_E)
	for i in 60: game._simulate(1.0/60.0)
	key(KEY_E,false)
	h.check("E accelerates with real held input",game.speed>300)
	key(KEY_Q)
	for i in 120: game._simulate(1.0/60.0)
	key(KEY_Q,false)
	h.near("Q brakes",game.speed,140,0.1)
	game.fire_cooldown=0
	mouse(origin,MOUSE_BUTTON_LEFT)
	h.check("mouse left fires in road",game.mouse_fire and game.bullets.size()>0)
	mouse(Vector2.ZERO,MOUSE_BUTTON_LEFT,false)
	h.check("mouse release outside road clears fire",not game.mouse_fire)
	mouse(Vector2.ZERO,MOUSE_BUTTON_LEFT)
	h.check("HUD click cannot fire",not game.mouse_fire)
	mouse(origin,MOUSE_BUTTON_RIGHT)
	h.check("mouse right drops a rear mine",game.mouse_mine and game.mine_drops>0)
	mouse(origin,MOUSE_BUTTON_RIGHT,false)
	game._set_paused(true)
	game._open_journal()
	var elapsed: float=game.game_time
	game._simulate(1)
	h.check("journal pauses actual gameplay and shows delivered lines",game.game_time==elapsed and game.journal_text.text.contains("EVE GİDEN YOL"))
	game._close_journal()
	h.check("closing journal returns to pause",game.paused and game.pause_panel.visible)
	game._set_paused(false)
	game.arcade.collected=2
	game.distance=1200
	game._simulate(1.0/60.0)
	h.check("chapter finishes with the chosen route ending",game.over and game.end_panel.text.contains(str(game.journey.spec()["success"])))
	var saved: Dictionary=game.store.load_data()
	h.eq("story completion persists",saved["memory"]["chapter_clears"],1)
	game._end_run("survived")
	h.eq("chapter completion is written once",game.store.load_data()["memory"]["chapter_clears"],1)
	h.eq("route and optional goal persist",[saved["memory"]["last_route"],saved["memory"]["last_route_goal"]],["supplies",1])
	game.store.clear()
	Session.next_route="steady"
	quit(h.finish())
