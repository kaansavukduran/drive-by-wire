extends Control
const Art=preload("res://scripts/game/visual_art.gd")
const RobotArt=preload("res://scripts/game/robot_art.gd")
## Fixed, equal atlas cells; never size/position portraits from their alpha bounds.
const IDS := ["aion","kurt","kuzu","omer","emre","eren"]
const NAMES := {"aion":"Aion","kurt":"Kurt","kuzu":"Kuzu","omer":"Baykuş Ömer","emre":"Tavşan Emre","eren":"Tavşan Eren","omega":"Omega-3","muhur":"Mühür-01","yanki":"Yankı-02","tasnif":"Tasnif-13"}
var _cutout: ShaderMaterial
var speaker := "aion":
 set(value):
  speaker=value
  if is_instance_valid(_cutout): material=_cutout
  queue_redraw()

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 custom_minimum_size=Vector2(64,64)
 resized.connect(queue_redraw)
 var shader := Shader.new()
 shader.code="shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); COLOR=vec4(c.rgb,step(0.94,c.a));}"
 var cutout := ShaderMaterial.new()
 cutout.shader=shader
 _cutout=cutout
 material=cutout

func _draw() -> void:
 if speaker in ["muhur","yanki","tasnif"]:
  RobotArt.draw(self,size/2,["muhur","yanki","tasnif"].find(speaker),0,false,minf(size.x/100,size.y/76));return
 var side:=minf(size.x,size.y);var box:=Rect2((size-Vector2.ONE*side)/2,Vector2.ONE*side)
 if speaker=="omega":Art.draw(self,"omega",0,box)
 elif speaker in IDS:Art.portrait(self,speaker,box)
