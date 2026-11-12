extends SceneTree
## Build-time pixel-grid import for already authored game atlases. No new renderer.
## Originals stay untouched. Usage: godot --headless --script this.gd -- source dest columns rows cell_w cell_h
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=6:
		push_error("Expected source destination columns rows output_cell_width output_cell_height")
		quit(1)
		return
	var source:=Image.load_from_file(args[0])
	if source==null:
		quit(1)
		return
	var columns:=int(args[2])
	var rows:=int(args[3])
	var width:=int(args[4])
	var height:=int(args[5])
	if source.get_width()%columns!=0 or source.get_height()%rows!=0:
		push_error("Source cells must be equal integer rectangles")
		quit(1)
		return
	var output:=Image.create(columns*width,rows*height,false,Image.FORMAT_RGBA8)
	for y in rows:
		for x in columns:
			var cell:=source.get_region(Rect2i(x*source.get_width()/columns,y*source.get_height()/rows,source.get_width()/columns,source.get_height()/rows))
			cell.resize(width,height,Image.INTERPOLATE_NEAREST)
			output.blit_rect(cell,Rect2i(0,0,width,height),Vector2i(x*width,y*height))
	var result:=output.save_png(args[1])
	print("Pixel atlas import: ",args[1]," ",output.get_size())
	quit(0 if result==OK else 1)
