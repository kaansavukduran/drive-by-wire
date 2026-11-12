extends SceneTree
## Rasterize the newly authored SVG; never edits historical MOMO icon assets.
func _initialize() -> void:
 var svg:=FileAccess.get_file_as_string("res://assets/brand/ilin-icon.svg")
 for spec in [["ilin-icon.png",256],["ilin-icon-192.png",192],["ilin-adaptive-fg.png",432]]:
  var image:=Image.new()
  if image.load_svg_from_string(svg,float(spec[1])/256.0)!=OK or image.save_png("res://assets/brand/"+str(spec[0]))!=OK:
   quit(1)
   return
 var background:=Image.create(432,432,false,Image.FORMAT_RGBA8)
 background.fill(Color("101a23"))
 quit(0 if background.save_png("res://assets/brand/ilin-adaptive-bg.png")==OK else 1)
