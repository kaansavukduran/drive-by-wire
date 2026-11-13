extends RefCounted
const NAMES: Array[String]=["PASLI EŞİK","FIRTINA HATTI","CAM ORMANI","BUZLU ARŞİV","KIZIL SANTRAL","SESSİZ ÇEKİRDEK"]
const TINTS: Array[Color]=[Color.WHITE,Color("b0bfda"),Color("adcfc7"),Color("c7d8e5"),Color("d2aa9b"),Color("b7a9cd")]
static func index(stage: int,distance: float) -> int: return clampi(stage,0,2)*2+(1 if distance>=180 else 0)
static func draw(canvas: CanvasItem,kind: int,travel: float,moving: bool,weather: bool) -> void:
 if weather and kind in [1,3]:
  for i in 24:
   var p:=Vector2(196+posmod(i*37,244),fposmod(i*61+travel*(1.3 if kind==1 else 0.22),360))
   if kind==1: canvas.draw_line(p,p+Vector2(-3,12),Color(0.6,0.75,0.9,0.32),1)
   else: canvas.draw_rect(Rect2(p,Vector2(2,2)),Color("bcd7df"))
