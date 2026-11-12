extends SceneTree
const Harness := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Book := preload("res://scripts/core/story_book.gd")
var h:=Harness.new("free_drive")
var game: Node2D
func _initialize() -> void: call_deferred("run")
func key(code: int,down: bool) -> void:
	var e:=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func tick(n: int) -> void:
	for i in n: game._simulate(1.0/60.0)
func touch(id: int,pos: Vector2,pressed: bool) -> void:
	var e:=InputEventScreenTouch.new()
	e.index=id
	e.position=root.get_final_transform()*pos
	e.pressed=pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func drag(id: int,pos: Vector2) -> void:
	var e:=InputEventScreenDrag.new()
	e.index=id
	e.position=root.get_final_transform()*pos
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.store=Store.new("user://free-drive-test.json")
	game.spawn_timer=99999
	game.pickup_timer=99999
	game.car_y=200
	for spec in [[KEY_W,Vector2(0,-1)],[KEY_S,Vector2(0,1)],[KEY_A,Vector2(-1,0)],[KEY_D,Vector2(1,0)]]:
		game.car_x=320;game.car_y=200;game.drive_velocity=Vector2.ZERO
		key(spec[0],true);tick(15);key(spec[0],false)
		var moved:=Vector2(game.car_x-320,game.car_y-200)
		h.check("WASD travels in requested direction %s" % spec[1],moved.dot(spec[1])>25)
		tick(15)
		var stopped:=Vector2(game.car_x,game.car_y)
		tick(30)
		h.eq("released controls stop without drift",Vector2(game.car_x,game.car_y),stopped)
	game.car_x=320;game.car_y=200;game.drive_velocity=Vector2.ZERO
	key(KEY_W,true);key(KEY_D,true);tick(15)
	var diagonal:=Vector2(game.car_x-320,game.car_y-200)
	h.check("diagonal is analog movement, not lane snapping",diagonal.x>15 and diagonal.y< -15 and absf(diagonal.x-absf(diagonal.y))<0.01)
	h.check("diagonal speed is normalized",diagonal.length()<40)
	key(KEY_W,false);key(KEY_D,false)
	for code in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		key(code,true);tick(180);key(code,false);tick(10)
		var r: Rect2=game._player_rect()
		h.check("road bounds contain full hitbox %s" % code,r.position.x>=224 and r.end.x<=416 and r.position.y>=60 and r.end.y<=344)
	game.car_x=320;game.car_y=220;game.drive_velocity=Vector2.ZERO
	game.touch_enabled=true;game._layout();game._sync_touch()
	var center: Vector2=game.joystick.get_global_rect().get_center()
	var fire: Vector2=game.touch_by_action["drive_fire"].get_global_rect().get_center()
	touch(0,center,true);touch(1,fire,true);drag(0,center+Vector2(-35,-25));tick(15)
	h.check("independent fingers drive and fire",game.car_x<315 and game.car_y<215 and game._held("drive_fire"))
	touch(1,fire,false)
	h.check("releasing action finger keeps joystick ownership",game.joystick.pointer==0 and game.joystick.value.length()>0)
	touch(0,center,false);tick(15)
	h.check("joystick release clears vector",game.joystick.value==Vector2.ZERO and game.drive_velocity==Vector2.ZERO)
	touch(0,center,true);drag(0,center+Vector2(45,0))
	game._set_paused(true);game._set_paused(false);drag(0,center+Vector2(45,0))
	h.eq("stale pre-pause finger cannot restart steering",game.joystick.value,Vector2.ZERO)
	for dimensions in [Vector2i(640,360),Vector2i(360,780),Vector2i(768,1024),Vector2i(1024,768)]:
		var before:=Vector2(game.car_x,game.car_y)
		root.content_scale_size=dimensions
		root.size=dimensions
		await process_frame
		game._layout();game._set_paused(false)
		h.eq("layout never moves physics origin",Vector2(game.car_x,game.car_y),before)
		var rects: Array=[game.joystick.get_global_rect(),game.pause_button.get_global_rect()]
		for action in game.touch_controls: rects.append(action.get_global_rect())
		var clear:=true
		var viewport:=root.get_visible_rect()
		for i in rects.size():
			if not viewport.encloses(rects[i]): clear=false
			for j in range(i+1,rects.size()):
				if rects[i].intersects(rects[j]): clear=false
		h.check("joystick, pause and all action hitboxes fit without overlap %s" % dimensions,clear)
		for cooldown in [0.0,0.6]:
			game.mine_cooldown=cooldown;game._update_hud()
			await process_frame
			var button_clear:=true
			for action in game.touch_controls:
				if not action.get_global_rect().grow(0.5).encloses(action.visual.get_global_rect()): button_clear=false
			h.check("visible action buttons match hitboxes at cooldown %s view %s" % [cooldown,dimensions],button_clear)

	game.car_x=320;game.car_y=200;game.car.position=Vector2(320,200)
	var pivot: Vector2=game.car.offset
	for pose in ["drive","boost","fire","hit","brake","shift_left","shift_right","damaged"]:
		game.anim=pose;game.anim_t=0;game._animate(0.05)
		h.eq("sprite pivot fixed during %s" % pose,game.car.offset,pivot)
		h.eq("sprite and hitbox share center during %s" % pose,game.car.position,game._player_rect().get_center())
	# Detect art-frame drift independently of code constants: green chassis bounds.
	var image:=Image.load_from_file("res://assets/sprites/aion_roadster.png")
	for index in 8:
		var low:=Vector2(99999,99999);var high:=Vector2.ZERO
		for y in range(0,96):
			for x in range(0,64):
				var c:=image.get_pixel((index%4)*64+x,(index/4)*96+y)
				if c.a>0.92 and c.g>c.r+0.098 and c.g>c.b+0.012 and c.r>0.156 and c.r<0.666 and c.g>0.313 and c.g<0.862:
					low=low.min(Vector2(x,y));high=high.max(Vector2(x,y))
		var error: float=(((low+high)/2+pivot)*game.car.scale).length()
		h.check("chassis stays aligned in art cell %d" % index,error<1.1)
	game.enemies.clear();game.bullets.clear();game.fire_cooldown=0;game.mine_cooldown=0
	game._spawn_enemy_for_test("rammer",1,game.car_y+100)
	game._fire({})
	h.check("rear enemy never reverses front gun",game.bullets[-1]["vel"].y<0 and game.bullets[-1]["pos"].y<game.car_y)
	game._execute({"intent":"drop_mine"})
	h.eq("mine leaves rear socket at current free X/Y",game.mines[-1]["pos"],Vector2(game.car_x,game.car_y+30))
	game.motion_enabled=false;game._shake(5)
	h.eq("reduced motion disables shake",game._camera_offset(),Vector2.ZERO)
	var old:=Book.sanitize({"stage":1,"choices":["signal"],"unlocked":["e01"],"active":false})
	h.eq("old checkpoints keep route and unlocked endings",[old["stage"],old["choices"],old["unlocked"]],[1,["signal"],["e01"]])
	var replied:=Book.answer(Book.defaults(),"listen")
	h.eq("conversation response changes relationship",replied["bonds"].get("kuzu"),1)
	h.eq("response has a real combat perk",Book.radio_reply(replied).get("perk"),"shield")
	h.eq("repeated answer cannot farm relationship",Book.answer(replied,"listen"),replied)
	h.eq("other answer cannot farm same conversation",Book.answer(replied,"together"),replied)
	game.store.clear()
	game.queue_free()
	quit(h.finish())
