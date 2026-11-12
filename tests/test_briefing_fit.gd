extends SceneTree
const H:=preload("res://tests/harness.gd")
const Book:=preload("res://scripts/core/story_book.gd")
const Session:=preload("res://scripts/game/session.gd")
var h:=H.new("briefing_fit")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 Session.story_mode=true
 for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(360,780),Vector2i(640,480)]:
  root.content_scale_size=dimensions
  root.size=dimensions
  for key in Book.data()["nodes"]:
   var path: Array=[] if key=="root" else Array(key.split("/"))
   Session.campaign_state=Book.sanitize({"stage":path.size(),"choices":path})
   var screen: Node=load("res://scenes/journey.tscn").instantiate()
   root.add_child(screen)
   await process_frame
   await process_frame
   screen._layout()
   for page in 4:
    screen._show_page(page,true)
    await process_frame
    var valid:=true
    var controls: Array=[screen.back,screen.heading]
    controls.append_array(screen.tabs)
    controls.append_array(screen.pages[page].get_children())
    for control in controls:
     if not control is Control: continue
     var rect: Rect2=control.get_global_rect()
     if not root.get_visible_rect().grow(1).encloses(rect): valid=false
     if control.get_parent()==screen.pages[page] and not screen.content.get_global_rect().grow(1).encloses(rect): valid=false
     if control is Button or control is Label:
      if control is Button and rect.size.y<44: valid=false
      var font: Font=control.get_theme_font("font")
      var text_size: Vector2=font.get_multiline_string_size(control.text,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-12,control.get_theme_font_size("font_size"))
      if text_size.y>rect.size.y-(8 if control is Button else 0): valid=false
    h.check("all content fits without scroll %s %s page%d" % [dimensions,key,page],valid)
   screen.queue_free()
   await process_frame
 Session.story_mode=false
 Session.campaign_state={}
 quit(h.finish())
