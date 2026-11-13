extends RefCounted
## Measured source-cell contacts, independent from the fixed world origins.
const PATH := "res://data/story_cast_art.json"
const IDS := ["aion","emre","eren"]
const TEXTURES := {"emre":preload("res://assets/sprites/emre_aftermath_detail.png"),"aion":preload("res://assets/sprites/aion_story.png"),"eren":preload("res://assets/sprites/eren_story.png")}
const BACKGROUND := preload("res://assets/ui/road_aftermath.png")
static var _data: Dictionary={}
static var _material: ShaderMaterial
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func spec(who: String) -> Dictionary:return data()["actors"][who]
static func positions() -> Array[Vector2]:
 var result: Array[Vector2]=[]
 for who in IDS:
  var p: Array=spec(who)["world"];result.append(Vector2(p[0],p[1]))
 return result
static func region(who: String,index: int) -> Rect2:
 var s:=spec(who);var cell:=Vector2(s["cell"][0],s["cell"][1]);var columns: int=s["columns"]
 return Rect2(Vector2(index%columns,index/columns)*cell,cell)
static func anchor(who: String,index: int) -> Vector2:
 var p: Array=spec(who)["anchors"][index];return Vector2(p[0],p[1])
static func material() -> ShaderMaterial:
 if _material==null:
  var shader:=Shader.new()
  shader.code="shader_type canvas_item; render_mode unshaded; void fragment(){vec4 c=texture(TEXTURE,UV); if(c.a<0.94){discard;} COLOR=vec4(c.rgb,1.0);}"
  _material=ShaderMaterial.new();_material.shader=shader
 return _material
static func configure(sprite: Sprite2D,who: String,index: int) -> void:
 sprite.texture=TEXTURES[who];sprite.region_enabled=true;sprite.region_filter_clip_enabled=true
 sprite.centered=false;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;sprite.material=material()
 sprite.region_rect=region(who,index);sprite.offset=-anchor(who,index)
 sprite.scale=Vector2.ONE*float(spec(who)["scale"])
static func clip_frame(who: String,clip: String,time: float) -> int:
 var c: Dictionary=spec(who)["clips"][clip];var duration:=0.0
 for value in c["seconds"]:duration+=float(value)
 var phase:=fposmod(time,duration) if c["loop"] else minf(time,duration-0.0001)
 for i in c["frames"].size():
  phase-=float(c["seconds"][i])
  if phase<0:return int(c["frames"][i])
 return int(c["frames"][-1])
static func frame(who: String,time: float,step_time: float,step: String,motion: bool) -> int:
 if who=="emre":return clip_frame(who,"hurt",time) if motion else 0
 if who=="aion":
  if motion and step in ["promise","rescue"] and step_time<2.5:return clip_frame(who,"interact",step_time)
  return clip_frame(who,"idle",time) if motion else 0
 if step=="aftermath":return clip_frame(who,"idle",time) if motion else 0
 if step=="eren" and motion:return clip_frame(who,"assist",step_time)
 return 3
