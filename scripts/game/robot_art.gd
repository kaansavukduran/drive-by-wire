extends RefCounted
const Art=preload("res://scripts/game/visual_art.gd")
const ACCENTS: Array[Color]=[Color("ffce70"),Color("79d4ff"),Color("f4a8c5")]
static func draw(canvas: CanvasItem,pivot: Vector2,kind: int,time: float=0,flash: bool=false,scale_factor: float=1,charging: bool=false) -> void:
 var frame:=kind+(3 if charging else 0)
 Art.at(canvas,"robots",frame,pivot,Vector2(100,76)*scale_factor,Color(1.3,1.3,1.3) if flash else Color.WHITE)
