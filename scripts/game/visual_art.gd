extends RefCounted
## Authored visual registrations. These never supply gameplay coordinates or RNG.
const PATH := "res://data/visual_art.json"
const PATHS := {
 "cliff":"res://assets/art/cliff.png",
 "kurt_scene":"res://assets/art/kurt_scene.png",
 "cliff_cars":"res://assets/art/cliff_cars.png",
 "omega":"res://assets/art/omega.png",
 "cast_a":"res://assets/art/cast_a.png",
 "cast_b":"res://assets/art/cast_b.png",
 "robots":"res://assets/art/robots.png",
 "players":"res://assets/art/players.png",
 "enemies":"res://assets/art/enemies.png",
 "terrain":"res://assets/art/terrain.png",
 "garage":"res://assets/art/garage.png",
 "fx":"res://assets/art/fx.png",
 "gadgets":"res://assets/art/gadgets.png",
 "weapons":"res://assets/art/weapons.png"}
static var _textures: Dictionary={}
static func texture(name: String) -> Texture2D:
 if not _textures.has(name):_textures[name]=load(PATHS[name])
 return _textures[name]
static var _data: Dictionary={}
static var _material: ShaderMaterial
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func region(sheet: String,index: int) -> Rect2:
 var s: Dictionary=data()["sheets"][sheet];var columns: int=s["columns"]
 var cell:=Vector2(float(s["size"][0])/columns,float(s["size"][1])/int(s["rows"]))
 return Rect2(Vector2(index%columns,index/columns)*cell,cell)
static func material() -> ShaderMaterial:
 if _material==null:
  var shader:=Shader.new()
  shader.code="shader_type canvas_item; render_mode unshaded; varying vec4 tint; void vertex(){tint=COLOR;} void fragment(){vec4 c=texture(TEXTURE,UV); if(c.a<0.94){discard;} COLOR=vec4(c.rgb*tint.rgb,tint.a);}"
  _material=ShaderMaterial.new();_material.shader=shader
 return _material
static func draw(canvas: CanvasItem,sheet: String,index: int,box: Rect2,tint: Color=Color.WHITE,flip_v: bool=false) -> void:
 var target:=box
 if flip_v:target.size.y=-target.size.y
 canvas.draw_texture_rect_region(texture(sheet),target,region(sheet,index),tint)
static func at(canvas: CanvasItem,sheet: String,index: int,pivot: Vector2,size: Vector2,tint: Color=Color.WHITE,flip_v: bool=false) -> void:
 draw(canvas,sheet,index,Rect2(pivot-size/2,size),tint,flip_v)
static func cast_spec(who: String) -> Dictionary:return data()["cast"][who]
static func portrait(canvas: CanvasItem,who: String,box: Rect2) -> void:
 var s:=cast_spec(who);var source: Array=s["portrait"]
 var rect:=Rect2(source[0],source[1],source[2],source[3]);rect.position+=region(s["sheet"],int(s["index"])).position
 var ratio:=minf(box.size.x/rect.size.x,box.size.y/rect.size.y)
 var size:=rect.size*ratio
 canvas.draw_texture_rect_region(texture(s["sheet"]),Rect2(box.get_center()-size/2,size),rect)
static func standing(sprite: Sprite2D,who: String) -> void:
 var s:=cast_spec(who);var frame:=region(s["sheet"],int(s["index"]))
 sprite.texture=texture(s["sheet"]);sprite.region_enabled=true;sprite.region_filter_clip_enabled=true
 sprite.region_rect=frame;sprite.centered=false;sprite.offset=-Vector2(s["foot"][0],s["foot"][1])
 sprite.scale=Vector2.ONE*minf(72.0/frame.size.x,64.0/frame.size.y)
 sprite.material=material();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
static func vehicle(sprite: Sprite2D,index: int,zoom: float=1) -> void:
 var rect:=region("players",index)
 sprite.texture=texture("players");sprite.region_enabled=true;sprite.region_filter_clip_enabled=true
 sprite.region_rect=rect;sprite.centered=false;sprite.offset=-rect.size/2
 sprite.scale=Vector2(48,74)/rect.size*zoom;sprite.material=material()
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
static func vehicle_at(canvas: CanvasItem,index: int,pivot: Vector2,tint: Color=Color.WHITE) -> void:
 at(canvas,"players",index,pivot,Vector2(48,74),tint)
static func explosion(canvas: CanvasItem,pivot: Vector2,time: float,size: float=80) -> void:
 at(canvas,"fx",clampi(int(time*10),0,5),pivot,Vector2.ONE*size)
static func road(canvas: CanvasItem,kind: int,scroll: float,height: float=360) -> void:
 var source:=region("terrain",clampi(kind,0,5))
 # Register asphalt edges and both lane dividers to the existing world road.
 var from_x: Array=data()["road_source_x"]
 var to_x: Array=[0,192,288,352,448,640]
 var y:=fposmod(scroll,640.0)-640
 while y<height:
  for i in 5:
   var src:=Rect2(source.position+Vector2(from_x[i],2),Vector2(from_x[i+1]-from_x[i],source.size.y-4))
   canvas.draw_texture_rect_region(texture("terrain"),Rect2(to_x[i],y,to_x[i+1]-to_x[i],640),src)
  y+=640
