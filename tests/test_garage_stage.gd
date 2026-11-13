extends SceneTree
const H:=preload("res://tests/harness.gd")
const Store:=preload("res://scripts/core/save_store.gd")
var h:=H.new("garage_stage")
func _initialize() -> void: call_deferred("run")
func frames(n:=3) -> void:
 for i in n: await process_frame
func controls(screen: Node) -> Array:
 var out: Array=[screen.speech,screen.info,screen.quick_button]
 if screen.speech_next.visible: out.append(screen.speech_next)
 if screen.brief_label.visible: out.append(screen.brief_label)
 for child in screen.buttons.get_children():
  if child is Button and child.visible and not child.is_queued_for_deletion(): out.append(child)
 return out
func check_stage(screen: Node,label: String) -> void:
 var fits:=true
 var area: Rect2=screen.cast.get_global_rect()
 for c in controls(screen):
  if not root.get_visible_rect().grow(1).encloses(c.get_global_rect()): fits=false
  for slot in screen.cast.slots:
   if slot.get_global_rect().intersects(c.get_global_rect()): fits=false
 h.check("UI and character floor areas remain separate "+label,fits)
 var actors_fit:=true
 for i in screen.cast.actors.size():
  var actor: Sprite2D=screen.cast.actors[i]
  var rect: Rect2=actor.get_global_transform()*actor.get_rect()
  if not screen.cast.slots[i].get_global_rect().encloses(rect): actors_fit=false
  if not area.encloses(rect): actors_fit=false
 h.check("full character cells fit own slots "+label,actors_fit)
func run() -> void:
 Store.new().clear()
 for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(360,780),Vector2i(640,480)]:
  root.content_scale_size=dimensions;root.size=dimensions
  var screen: Node=load("res://scenes/garage.tscn").instantiate()
  root.add_child(screen)
  await frames()
  screen.set_process(false)
  screen._layout()
  await frames()
  for motion in [true,false]:
   screen.save["settings"]["motion"]=motion
   var start: Dictionary=screen.cast.snapshot()
   for i in 240: screen._process(1.0/60.0)
   h.eq("time never moves actors with motion %s %s" % [motion,dimensions],screen.cast.snapshot(),start)
  check_stage(screen,"dialogue %s" % dimensions)
  # All six dialogues, including long remembered prompts, stay readable page by page.
  var pages_fit:=true
  for dialogue in screen.garage.data["dialogues"]:
   screen._say("Geldiğine sevindim. Bugün rotayı birlikte seçelim. Yollar değişiyor; ortak hatıralarımız çoğalıyor.\n"+str(dialogue.get("prompt","")))
   for page in screen.speech_pages.size():
    screen.speech_page=page;screen._show_speech_page()
    var font: Font=screen.speech.get_theme_font("font")
    var text_size: Vector2=font.get_multiline_string_size(screen.speech.text,HORIZONTAL_ALIGNMENT_LEFT,screen.speech.size.x-20,screen.speech.get_theme_font_size("font_size"))
    if text_size.y>screen.speech.size.y-20: pages_fit=false
  h.check("all garage prompt pages fit without clipping %s" % dimensions,pages_fit)
  var original: Dictionary=screen.cast.snapshot()
  screen._show_upgrades();await frames();screen._layout();await frames()
  h.eq("upgrade phase never moves character marks %s" % dimensions,screen.cast.snapshot(),original)
  check_stage(screen,"upgrade %s" % dimensions)
  var text_fits:=true
  for c in controls(screen):
   if c is Button:
    var font: Font=c.get_theme_font("font")
    if font.get_multiline_string_size(c.text,HORIZONTAL_ALIGNMENT_LEFT,c.size.x-10,c.get_theme_font_size("font_size")).y>c.size.y-10: text_fits=false
  h.check("upgrade button text stays inside its button %s" % dimensions,text_fits)
  screen._pick_upgrade(str(screen.offers[0]["id"]));await frames();screen._layout();await frames()
  h.eq("ready phase never moves character marks %s" % dimensions,screen.cast.snapshot(),original)
  check_stage(screen,"ready %s" % dimensions)
  # Focus-page advance cannot move actors or silently change the upgrade stage.
  screen._say("Birlikte yola çıkmadan önce bu konuşmanın bütün cümlelerini okuyabilmeliyiz. ".repeat(5))
  original=screen.cast.snapshot()
  screen.speech_next.pressed.emit()
  h.eq("speech page changes only text %s" % dimensions,screen.cast.snapshot(),original)
  h.eq("speech page preserves current stage %s" % dimensions,screen.stage,"ready")
  original=screen.cast.snapshot()
  root.content_scale_size=Vector2i(360,780) if dimensions.x>dimensions.y else Vector2i(640,360)
  root.size=root.content_scale_size
  await frames();screen._layout();await frames()
  root.content_scale_size=dimensions;root.size=dimensions
  await frames();screen._layout();await frames()
  h.eq("rotation roundtrip restores exact floor marks %s" % dimensions,screen.cast.snapshot(),original)
  screen.queue_free();await frames()
 for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(360,780),Vector2i(640,480)]:
  root.content_scale_size=dimensions;root.size=dimensions
  var title: Node=load("res://scenes/title.tscn").instantiate()
  root.add_child(title);await frames();title.set_process(false);title._layout();await frames()
  var before: Dictionary=title.cast.snapshot()
  for i in 240: title._process(1.0/60.0)
  h.eq("title actors do not drift with time %s" % dimensions,title.cast.snapshot(),before)
  var clear:=true
  if title.cast.visible:
   for c in title.base_rects:
    if not c.visible or c==title.cast or c==title.help_panel: continue
    for actor in title.cast.actors:
     var rect: Rect2=actor.get_global_transform()*actor.get_rect()
     if rect.intersects(c.get_global_rect()): clear=false
  h.check("title character cells avoid menu controls %s" % dimensions,clear)
  title.queue_free();await frames()
 Store.new().clear()
 quit(h.finish())
