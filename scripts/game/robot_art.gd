extends RefCounted
## Original pixel geometry on a shared grid; the core and hitbox share one pivot.
const ACCENTS: Array[Color]=[Color("ffce70"),Color("79d4ff"),Color("f4a8c5")]
static func draw(canvas: CanvasItem,pivot: Vector2,kind: int,time: float=0,flash: bool=false,scale_factor: float=1) -> void:
 var ink:=Color("101622");var metal:=Color("506879");var light:=Color("afc8cf");var accent:=Color.WHITE if flash else ACCENTS[kind]
 var origin:=pivot.round()
 var pieces: Array=[[-28,-24,56,48,ink],[-24,-22,48,42,metal],[-18,-18,36,30,light],[-15,-15,30,23,ink],[-10,-10,8,4,accent],[3,-10,8,4,accent],[-4,-3,8,9,accent],[-18,15,36,6,accent],[-5,-31,10,8,ink],[-2,-34,4,6,accent]]
 if kind==0: pieces.append_array([[-44,-16,18,40,ink],[26,-16,18,40,ink],[-40,-12,10,30,metal],[30,-12,10,30,metal],[-36,0,8,12,accent],[28,0,8,12,accent],[-24,23,16,7,ink],[8,23,16,7,ink]])
 elif kind==1: pieces.append_array([[-46,-6,20,22,ink],[26,-6,20,22,ink],[-42,-3,14,8,accent],[28,-3,14,8,accent],[-40,15,8,7,accent],[32,15,8,7,accent]])
 else: pieces.append_array([[-44,-24,18,48,ink],[26,-24,18,48,ink],[-40,-20,10,30,metal],[30,-20,10,30,metal],[-38,-15,6,9,accent],[32,-15,6,9,accent],[-22,22,14,10,ink],[8,22,14,10,ink],[-32,-30,8,8,accent],[24,-30,8,8,accent]])
 for r in pieces: canvas.draw_rect(Rect2(origin+Vector2(r[0],r[1])*scale_factor,Vector2(r[2],r[3])*scale_factor),r[4])
 # Engine exhaust animates inside its fixed assembly, never moves the core.
 var jet:=4+int(time*8)%3*2
 for side in [-1,1]: canvas.draw_rect(Rect2(origin+Vector2(side*20-3,28)*scale_factor,Vector2(6,jet)*scale_factor),accent)
