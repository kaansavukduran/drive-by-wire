extends RefCounted
## Rear barn doors: one rigid chassis, two vertical hinges, no roof swap.
const Art=preload("res://scripts/game/visual_art.gd")
const LEFT=Vector2(-15,48)
const RIGHT=Vector2(8,48)
const HEIGHT=6.0
const LEAF=11.5
const ANGLE=105.0
const RELEASE=Vector2(-3.5,52)
const OPEN_SECONDS=.4
const CLOSE_SECONDS=.28
const HOLD_SECONDS=.12

static func step(amount: float,state: String,elapsed: float,delta: float) -> float:
 var opening:=state=="windup" or (state=="attack" and elapsed<HOLD_SECONDS)
 var target:=1.0 if opening else 0.0
 var value:=move_toward(amount,target,delta/(OPEN_SECONDS if opening else CLOSE_SECONDS))
 return target if is_equal_approx(value,target) else value

static func leaves(amount: float) -> Array:
 var angle:=deg_to_rad(ANGLE*clampf(amount,0,1))
 var out: Array=[]
 for side in [-1,1]:
  var hinge: Vector2=LEFT if side<0 else RIGHT
  var free:=hinge+Vector2(-side*LEAF*cos(angle),LEAF*sin(angle))
  out.append({"hinge":hinge,"free":free,"corners":PackedVector2Array([hinge-Vector2(0,HEIGHT),free-Vector2(0,HEIGHT),free,hinge])})
 return out

static func draw(canvas: CanvasItem,pivot: Vector2,amount: float,cargo: String,loaded: bool,tint: Color) -> void:
 # The same source pixels always supply cab, roof, wheels and lights.
 Art.at(canvas,"enemies",2,pivot,Vector2(56,108),tint,true)
 var mouth:=Rect2(pivot+LEFT-Vector2(0,HEIGHT),Vector2(RIGHT.x-LEFT.x,HEIGHT))
 canvas.draw_rect(mouth,Color("141a20"))
 if loaded and amount>0:
  Art.at(canvas,"gadgets",{"crate":4,"barrel":5,"spikes":6}.get(cargo,4),pivot+Vector2(RELEASE.x,45),Vector2(15,6),tint)
 var texture:=Art.texture("enemies")
 var geometry:=leaves(amount)
 for i in 2:
  var leaf: Dictionary=geometry[i]
  var corners: PackedVector2Array=leaf["corners"]
  for j in corners.size():corners[j]+=pivot
  # Metal skin comes from this truck's existing rear cover, not a new style.
  var skin:=Rect2(1024+(115 if i==0 else 230),54,100,50)
  var uv:=PackedVector2Array([skin.position,skin.position+Vector2(skin.size.x,0),skin.end,skin.position+Vector2(0,skin.size.y)])
  for j in uv.size():uv[j]/=texture.get_size()
  canvas.draw_polygon(corners,PackedColorArray([tint,tint,tint,tint]),uv,texture)
  var outline:=corners.duplicate();outline.append(corners[0])
  canvas.draw_polyline(outline,Color("32333b"),1)
  canvas.draw_line(corners[0],corners[1],Color("b4a484"),1)
  canvas.draw_line(corners[1],corners[2],Color("d3ac61"),1)
 # Both pins remain attached to the rear pillars throughout opening/closing.
 for hinge in [LEFT,RIGHT]:
  for height in [1.0,5.0]:canvas.draw_rect(Rect2(pivot+hinge-Vector2(.7,height),Vector2(1.4,1.6)),Color("c1a879"))
