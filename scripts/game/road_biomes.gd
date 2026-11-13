extends RefCounted
const NAMES: Array[String]=["PASLI EŞİK","FIRTINA HATTI","CAM ORMANI","BUZLU ARŞİV","KIZIL SANTRAL","SESSİZ ÇEKİRDEK"]
const TINTS: Array[Color]=[Color.WHITE,Color("b0bfda"),Color("adcfc7"),Color("c7d8e5"),Color("d2aa9b"),Color("b7a9cd")]
static func index(stage: int,distance: float) -> int: return clampi(stage,0,2)*2+(1 if distance>=180 else 0)
static func draw(canvas: CanvasItem,kind: int,travel: float,moving: bool,weather: bool) -> void:
 if kind==0: return
 var colors: Array[Color]=[Color("262a3b"),Color("223446"),Color("183f3b"),Color("657e91"),Color("442b32"),Color("28233e")]
 for x in [0,448]: canvas.draw_rect(Rect2(x,0,192,360),colors[kind])
 var offset:=fmod(travel,96.0) if moving else 0.0
 for row in 6:
  var y:=row*96.0-96+offset
  for x in [150.0,484.0]:
   if kind==2:
    canvas.draw_rect(Rect2(x-4,y+12,8,50),Color("47645b"));canvas.draw_rect(Rect2(x-22,y,44,35),Color("277063"));canvas.draw_rect(Rect2(x-14,y-12,28,29),Color("56a89c"));canvas.draw_rect(Rect2(x-5,y-7,10,10),Color("b5e4bb"))
   elif kind==3:
    canvas.draw_rect(Rect2(x-12,y,24,40),Color("99bdd0"));canvas.draw_rect(Rect2(x-6,y-8,12,55),Color("cbe9e9"));canvas.draw_rect(Rect2(x-18,y+34,40,7),Color("7c9fb5"))
   elif kind==4:
    canvas.draw_rect(Rect2(x-16,y,32,48),Color("222534"));canvas.draw_rect(Rect2(x-10,y+6,20,34),Color("8d4c42"));canvas.draw_rect(Rect2(x-6,y+13,12,5),Color("ffba72"));canvas.draw_rect(Rect2(x-2,y+48,4,48),Color("bd7657"))
   elif kind==5:
    canvas.draw_rect(Rect2(x-18,y,36,58),Color("111d2c"));canvas.draw_rect(Rect2(x-13,y+5,26,42),Color("4c456e"))
    for i in 4: canvas.draw_rect(Rect2(x-8,y+10+i*9,16,3),Color("9e91cc"))
   else:
    canvas.draw_rect(Rect2(x-4,y,8,60),Color("627385"));canvas.draw_rect(Rect2(x-14,y-4,28,8),Color("aeb7ba"))
 if weather and kind in [1,3]:
  for i in 24:
   var p:=Vector2(196+posmod(i*37,244),fposmod(i*61+travel*(1.3 if kind==1 else 0.22),360))
   if kind==1: canvas.draw_line(p,p+Vector2(-3,12),Color(0.6,0.75,0.9,0.32),1)
   else: canvas.draw_rect(Rect2(p,Vector2(2,2)),Color("bcd7df"))
