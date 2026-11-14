extends SceneTree
const H=preload("res://tests/harness.gd")
const Boss=preload("res://scripts/core/boss_encounter.gd")
const Biomes=preload("res://scripts/game/road_biomes.gd")
const Session=preload("res://scripts/game/session.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Store=preload("res://scripts/core/save_store.gd")
var h=H.new("boss_encounters")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for stage in 3:
  var b=Boss.new();b.start(stage)
  h.check("boss enters from outside road without a projectile",b.step(.1,Vector2(320,290)).is_empty() and b.position.y<0)
  for tick in 300:
   b.step(1.0/60,Vector2(320,290))
   if b.warning_left>0:break
  h.check("each robot warns before its first shot",b.warning_left>0 and b.casts==0 and not b.targets.is_empty())
  var locked=b.targets.duplicate();b.step(.2,Vector2(235,200))
  h.eq("warning target stays locked when player moves",b.targets,locked)
  var shots: Array=[]
  for tick in 90:shots.append_array(b.step(1.0/60,Vector2(235,200)))
  h.check("warning produces real moving damaging shots",shots.size()>0 and shots[0]["vel"].length()>0 and shots[0]["dmg"]>0)
  h.check("front robot core stays below HUD and toast areas",b.rect().position.y>=118)
  b.hit(b.max_hp/2);b.step(.01,Vector2(320,290))
  h.eq("half health starts a second phase",b.phase,2)
  h.check("damage leaves pivot and collision aligned",b.rect().get_center()==b.position)
  for tick in 1200:b.step(1.0/60,Vector2(320,290))
  h.check("all robots cast several attacks",b.casts>=3)
  h.check("killing the boss yields victory exactly once",b.hit(10000) and not b.hit(10000) and b.defeated and not b.active)
  h.check("defeated robot cannot keep firing",b.step(5,Vector2.ZERO).is_empty())
  h.eq("first biome before threshold",Biomes.index(stage,179),stage*2)
  h.eq("next biome at threshold",Biomes.index(stage,180),stage*2+1)
 root.size=Vector2i(640,360);root.content_scale_size=Vector2i(640,360);await process_frame;await process_frame
 Session.story_mode=true;Session.campaign_state=Book.choose(Book.defaults(),"depart")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_physics_process(false);game.set_process(false);game.store=Store.new("user://boss-fixture.json")
 game.touch_enabled=true;game._layout();game._notice("ROBOT SALDIRISI\nMühür-01");game._process(.01)
 var sample=Boss.new();sample.start(0);sample.position=Vector2(320,150)
 var rendered=Rect2(game.to_global(sample.rect().position),sample.rect().size*game.scale)
 h.check("touch landscape feedback clears front robot and steering hint",not rendered.intersects(game.toast.get_global_rect()) and not rendered.intersects(game.story_caption.get_global_rect()) and not game.touch_hint.visible)
 game.distance=279.9;game._simulate(.02)
 h.check("real story reaches an actual boss",game.boss.active and game.boss.started)
 game.distance=399.89;game._simulate(.02)
 h.check("driving past encounter cannot skip boss",not game.over and game.distance<400)
 var hp_before: float=game.boss.hp
 game.bullets=[{"pos":game.boss.position+Vector2(0,2),"vel":Vector2.UP}];game._update_bullets(.01)
 h.check("front projectile collides with robot and deals configured damage",game.boss.hp<hp_before and game.bullets.is_empty())
 game.car_y=318;game.boss.position=Vector2(game.car_x,430);hp_before=game.boss.hp
 game._execute({"intent":"drop_mine"})
 h.check("real mine leaves rear muzzle with its arming delay",game.mines.size()==1 and game.mines[0]["pos"].y>game.car_y and game.mines[0]["arm"]>0)
 for tick in 90:game._update_mines(1.0/60)
 h.check("rear mine arms in flight and hits robot even at rear movement bound",game.boss.hp<hp_before and game.mines.is_empty())
 game.boss.position=Vector2(game.car_x,game.car_y+56);hp_before=game.boss.hp
 game._direct_action("drive_comfort")
 h.check("nearby support pulse damages robot without moving it",game.boss.hp<hp_before and game.boss.position==Vector2(game.car_x,game.car_y+56))
 var clock: float=game.boss.clock;game._set_paused(true);game._simulate(1)
 h.eq("pause freezes boss windup and movement",game.boss.clock,clock)
 game._set_paused(false);game._hurt_boss(10000)
 game.distance=399.89;game._simulate(.02)
 h.check("only victory opens the normal chapter completion",game.boss.defeated and game.over and game.end_result["outcome"]=="survived")
 game.store.clear();game.queue_free();await process_frame
 Session.story_mode=false;Session.campaign_state={}
 quit(h.finish())
