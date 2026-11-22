extends RefCounted
const NAMES: Array[String]=["PASLI EŞİK","FIRTINA HATTI","CAM ORMANI","BUZLU ARŞİV","KIZIL SANTRAL","SESSİZ ÇEKİRDEK"]
const TINTS: Array[Color]=[Color.WHITE,Color("b0bfda"),Color("adcfc7"),Color("c7d8e5"),Color("d2aa9b"),Color("b7a9cd")]
static func index(stage: int,_distance: float) -> int: return [2,3,4,5,0,1][posmod(stage,6)]
static func draw(canvas: CanvasItem,kind: int,travel: float,moving: bool,weather: bool) -> void:
 if not weather:
  return
 if kind in [1,3]:
  for i in 24:
   var p:=Vector2(196+posmod(i*37,244),fposmod(i*61+travel*(1.3 if kind==1 else 0.22),360))
   if kind==1: canvas.draw_line(p,p+Vector2(-3,12),Color(0.6,0.75,0.9,0.32),1)
   else: canvas.draw_rect(Rect2(p,Vector2(2,2)),Color("bcd7df"))
 elif kind==2:
  # Cam Ormanı: deterministic glass-forest glints strictly along the forest shoulders (off-asphalt).
  for i in 18:
   var left_side: bool=(i%2)==0
   var base_x: float=(18.0+float(posmod(i*43,160))) if left_side else (460.0+float(posmod(i*47,162)))
   var sway: float=(sin(travel*0.018+float(i)*1.3)*5.0) if moving else 0.0
   var x: float=clampf(base_x+sway,8.0,184.0) if left_side else clampf(base_x+sway,456.0,632.0)
   var y: float=fposmod(float(i)*53.0+travel*0.38,360.0)
   var col: Color=Color(0.62,0.94,0.82,0.34) if i%3!=0 else Color(0.86,0.98,0.94,0.28)
   canvas.draw_rect(Rect2(Vector2(roundf(x),roundf(y)),Vector2(2,2)),col)
   if i%3==0:
    canvas.draw_line(Vector2(roundf(x)-2.0,roundf(y)+1.0),Vector2(roundf(x)+4.0,roundf(y)+1.0),Color(0.76,0.98,0.90,0.20),1.0)
