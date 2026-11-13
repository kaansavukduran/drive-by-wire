extends Control
const Art=preload("res://scripts/game/visual_art.gd")
## Omega-3 · original game/TASLAK character: a travelling memory compass, not a CRT.
## Pixel geometry stays on a 48×44 grid; no random external artwork.
var mood := "calm"
var talking := 0.0
var hurt := 0.0
var confused := 0.0
var _t := 0.0
var decorative_motion := true
func _ready() -> void:
 custom_minimum_size=Vector2(48,44)
 size=custom_minimum_size
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 material=Art.material()
func _process(delta: float) -> void:
 var real_delta: float=delta/maxf(Engine.time_scale,0.01)
 if decorative_motion: _t+=real_delta
 talking=maxf(0,talking-real_delta)
 hurt=maxf(0,hurt-real_delta)
 confused=maxf(0,confused-real_delta)
 queue_redraw()
func px(x: int,y: int,w: int,h: int,c: Color) -> void:
 draw_rect(Rect2(x,y,w,h),c)
func frame_index() -> int:
 var frame:=0
 if mood in ["scared","sulky"] or confused>0:frame=3
 elif mood=="excited":frame=4
 if decorative_motion:
  if talking>0 and int(_t*8)%2==0:frame=2
  elif fmod(_t,4.4)>4.25:frame=1
 if hurt>0:frame=5
 return frame
func _draw() -> void:
 Art.draw(self,"omega",frame_index(),Rect2(Vector2.ZERO,size))
