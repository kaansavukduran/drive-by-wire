extends SceneTree
const H:=preload("res://tests/harness.gd")
var h:=H.new("rear_defense")
var game: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 await process_frame
 game.set_process(false)
 game.spawn_timer=99999
 game.pickup_timer=99999
 game.car_x=320;game.car_y=230
 game.enemies.clear();game.enemy_bullets.clear();game.mines.clear()
 game.mines_left=0 # Old empty-ammo state cannot block the new infinite dispenser.
 game._execute({"intent":"drop_mine"})
 h.eq("empty legacy ammo cannot block rear mine",game.mine_drops,1)
 h.eq("mine uses actual rear socket",game.mines[0]["pos"],Vector2(320,260))
 game._execute({"intent":"drop_mine"})
 h.eq("same-frame spam respects cooldown",game.mine_drops,1)
 var cooldown: float=game.mine_cooldown
 game._set_paused(true)
 game._simulate(1)
 h.eq("pause freezes mine cooldown",game.mine_cooldown,cooldown)
 game._set_paused(false)
 var key:=InputEventKey.new();key.keycode=KEY_X;key.physical_keycode=KEY_X;key.pressed=true
 Input.parse_input_event(key);Input.flush_buffered_events()
 for i in 180: game._simulate(1.0/60.0)
 key=key.duplicate();key.pressed=false
 Input.parse_input_event(key);Input.flush_buffered_events()
 h.check("held mine repeats after cooldown without ammo",game.mine_drops>=5)
 h.check("active mines stay bounded",game.mines.size()<10)
 game.mines.clear();game.enemy_bullets.clear();game.mine_cooldown=0
 game._execute({"intent":"drop_mine"})
 var center: Vector2=game.mines[0]["pos"]
 game.mines[0]["arm"]=0
 game._spawn_enemy_for_test("rammer",1,center.y+15)
 var pursuer: Dictionary=game.enemies[-1]
 var hp_before: float=game.hp
 game.enemy_bullets.append({"pos":center+Vector2(0,8),"vel":Vector2(0,-200),"dmg":10,"near":false,"passed":false})
 game._update_mines(0)
 h.eq("rear projectile is intercepted by armed mine",game.enemy_bullets.size(),0)
 h.check("mine blast really damages rear attacker",pursuer["hp"]<pursuer["max_hp"])
 h.eq("rear defense does not damage player",game.hp,hp_before)
 game.mines.clear();game.enemy_bullets.clear();game.mine_cooldown=0
 game._execute({"intent":"drop_mine"})
 center=game.mines[0]["pos"];game.mines[0]["arm"]=0
 game.enemy_bullets.append({"pos":center+Vector2(0,10),"vel":Vector2(0,-200),"dmg":10,"near":false,"passed":false})
 game._update_mines(0)
 h.eq("projectile alone can trigger mine away from shooter",game.enemy_bullets.size(),0)
 h.eq("detonated mine removed immediately",game.mines.size(),0)
 game.queue_free()
 quit(h.finish())
