extends Control
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
func _process(delta: float) -> void:
 var real_delta: float=delta/maxf(Engine.time_scale,0.01)
 if decorative_motion: _t+=real_delta
 talking=maxf(0,talking-real_delta)
 hurt=maxf(0,hurt-real_delta)
 confused=maxf(0,confused-real_delta)
 queue_redraw()
func px(x: int,y: int,w: int,h: int,c: Color) -> void:
 draw_rect(Rect2(x,y,w,h),c)
func _draw() -> void:
 var ink:=Color("101a23")
 var shell:=Color("566879")
 var edge:=Color("b6c5ce")
 var glow: Color={"calm":Color("9de1c3"),"scared":Color("ffd18a"),"excited":Color("f4a8c5"),"sulky":Color("bbacdf")}.get(mood,Color("9de1c3"))
 if hurt>0: glow=Color("ffb4ab")
 # Cut corners and a split navigation crown distinguish the silhouette.
 px(18,0,4,5,edge);px(26,0,4,5,edge)
 px(12,5,24,3,ink);px(8,8,32,28,ink);px(4,13,40,18,ink)
 px(12,7,24,3,shell);px(9,10,30,24,shell);px(6,14,36,16,shell)
 px(13,10,22,2,edge);px(11,14,26,16,ink)
 # Compass fins, and two expressive optics around a memory seed.
 px(0,20,7,4,glow);px(41,20,7,4,glow)
 var blink: bool=decorative_motion and fmod(_t,4.4)>4.25
 var eye_height: int=1 if blink else (5 if mood=="scared" else 3)
 px(14,18,5,eye_height,glow);px(29,18,5,eye_height,glow)
 px(22,15,4,12,glow);px(20,19,8,4,glow);px(23,19,2,4,ink)
 if confused>0: px(31,12,3,3,Color("ffd18a"))
 var voice: int=2 if talking>0 and decorative_motion and int(_t*8)%2==0 else 0
 px(17,28,14,2,glow);px(20,30,8,voice,glow)
 px(12,35,24,3,shell);px(18,38,12,3,ink);px(21,41,6,3,glow)
