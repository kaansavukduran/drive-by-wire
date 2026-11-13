extends SceneTree
const H=preload("res://tests/harness.gd")
const Art=preload("res://scripts/game/visual_art.gd")
const Face=preload("res://scripts/game/companion_face.gd")
const Cast=preload("res://scripts/game/cast_portrait.gd")
var h=H.new("visual_art")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for name in Art.PATHS:
  var texture: Texture2D=Art.texture(name)
  var spec: Dictionary=Art.data()["sheets"][name]
  h.eq("actual imported texture dimensions "+name,texture.get_size(),Vector2(spec["size"][0],spec["size"][1]))
  var cells: Dictionary={};var image: Image=texture.get_image()
  for i in int(spec["cells"]):
   var r:=Art.region(name,i)
   h.check("registered cell lies inside actual texture %s/%d" % [name,i],Rect2(Vector2.ZERO,texture.get_size()).encloses(r))
   var cell:=image.get_region(Rect2i(r));cells[cell.get_data().hex_encode().sha256_text()]=true
  h.eq("authored cells are distinct "+name,cells.size(),int(spec["cells"]))
 for who in Cast.IDS:
  var spec:=Art.cast_spec(who);var source:=Art.region(spec["sheet"],spec["index"])
  var image: Image=Art.texture(spec["sheet"]).get_image()
  var pixel:=Vector2i(source.position)+Vector2i(spec["foot"][0],spec["foot"][1])
  h.check("authored planted contact has visible material "+who,image.get_pixelv(pixel).a>=.94)
  var face: Array=spec["portrait"]
  h.check("portrait source crop remains in its own cell "+who,Rect2(Vector2.ZERO,source.size).encloses(Rect2(face[0],face[1],face[2],face[3])))
 var face:=Face.new();root.add_child(face);await process_frame;face.set_process(false)
 var rect:=face.get_rect();face.talking=1;face._t=0
 h.eq("verified speech has its own authored response",face.frame_index(),2)
 face.hurt=1;h.eq("damage response overrides speech",face.frame_index(),5)
 face.hurt=0;face.talking=0;face.mood="scared";h.eq("fear has its own authored signal",face.frame_index(),3)
 face.mood="excited";h.eq("excitement has its own authored signal",face.frame_index(),4)
 face.mood="calm";face._t=4.3;h.eq("actual blink frame selected",face.frame_index(),1)
 face.decorative_motion=false;h.eq("reduced motion holds calm without blink",face.frame_index(),0)
 for mood in ["calm","scared","excited","sulky"]:
  face.mood=mood;face.queue_redraw();h.eq("expression never changes UI bounds "+mood,face.get_rect(),rect)
 face.queue_free();await process_frame
 quit(h.finish())
