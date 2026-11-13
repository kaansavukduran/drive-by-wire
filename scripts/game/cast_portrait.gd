extends Control
const RobotArt=preload("res://scripts/game/robot_art.gd")
## Fixed, equal atlas cells; never size/position portraits from their alpha bounds.
const SHEET := preload("res://assets/sprites/aionverse_portraits.png")
const OMEGA := preload("res://assets/brand/ilin-icon.png")
const IDS := ["aion","kurt","kuzu","omer","emre"]
const NAMES := {"aion":"Aion","kurt":"Kurt","kuzu":"Kuzu","omer":"Baykuş Ömer","emre":"Tavşan Emre","omega":"Omega-3","muhur":"Mühür-01","yanki":"Yankı-02","tasnif":"Tasnif-13"}
var _cutout: ShaderMaterial
var speaker := "aion":
	set(value):
		speaker=value
		if is_instance_valid(_cutout): material=null if value in ["muhur","yanki","tasnif"] else _cutout
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
	material=null if speaker in ["muhur","yanki","tasnif"] else cutout

func _draw() -> void:
	if speaker in ["muhur","yanki","tasnif"]:
		RobotArt.draw(self,size/2,["muhur","yanki","tasnif"].find(speaker),0,false,minf(size.x/100,size.y/76))
		return
	var side:=minf(size.x,size.y)
	var box:=Rect2((size-Vector2.ONE*side)/2,Vector2.ONE*side)
	if speaker=="omega":
		draw_texture_rect(OMEGA,box,false)
		return
	var index := IDS.find(speaker)
	if index<0: return
	draw_texture_rect_region(SHEET,box,Rect2((index%3)*64,(index/3)*64,64,64))
