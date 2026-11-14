extends SceneTree
const H=preload("res://tests/harness.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Session=preload("res://scripts/game/session.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
var h=H.new("paged_ui")
func _initialize() -> void:call_deferred("run")
func frames() -> void:await process_frame;await process_frame
func fits(label: Label) -> bool:
 var count:=label.get_line_count();var height: float=maxi(0,count-1)*label.get_theme_constant("line_spacing")
 for i in count:height+=label.get_line_height(i)
 return height<=label.size.y+.5
func inside(a: Rect2,b: Rect2) -> bool:return b.grow(.5).encloses(a)
func run() -> void:
 Session.story_mode=true
 for font in ["system","lexend"]:
  UiSkin.configure("dark",font)
  for dimensions in [Vector2i(640,360),Vector2i(640,480),Vector2i(360,640),Vector2i(320,568)]:
   root.content_scale_size=dimensions;root.size=dimensions
   for gallery in [false,true]:
    var state:=Book.defaults();state["stage"]=2;state["phase"]="continued";Session.campaign_state=state
    var screen=load("res://scenes/endings.tscn" if gallery else "res://scenes/ending.tscn").instantiate();root.add_child(screen);await frames()
    var reader: Control=screen.reader
    var all_text:=true
    for page in reader.pages.size():
     reader.page_index=page;reader._show_page()
     if not fits(reader.content):all_text=false
    h.check("all chapter/continued prose fits %s %s" % [font,dimensions],all_text)
    h.eq("every word stays reachable without a wheel"," ".join(" ".join(reader.pages).replace("\n"," ").split(" ",false))," ".join(reader.full_text.replace("\n"," ").split(" ",false)))
    var clear:=not reader.get_global_rect().intersects(screen.status.get_global_rect()) and not reader.get_global_rect().intersects(screen.primary.get_global_rect())
    for control in [screen.heading,screen.primary,screen.gallery_button,screen.back,screen.status,reader]:
     if not inside(control.get_global_rect(),screen.panel.get_global_rect()):clear=false
     if control is Label and not fits(control):clear=false
    h.check("chapter/continued prose clears footer and all actions",clear)
    h.eq("no scroll container",screen.find_children("*","ScrollContainer",true,false).size(),0)
    h.eq("no invented ending slots",screen.ending_buttons.size(),0)
    screen.queue_free();await frames()
   var settings=load("res://scripts/game/settings_panel.gd").new();root.add_child(settings);settings.open();await frames()
   var complete:=true;var all_reachable:=true
   for tab in settings.tabs.get_tab_count():
    settings.tabs.current_tab=tab;await frames()
    var page: Control=settings.tabs.get_current_tab_control();page.reflow();await frames()
    var reached: Array=[]
    for index in page.groups.size():
     page.page_index=index;page._show_page();await frames()
     for control in page.column.get_children():
      if not control.visible:continue
      reached.append(control)
      if not inside(control.get_global_rect(),page.get_global_rect()) or control.get_global_rect().intersects(page.previous.get_global_rect()):complete=false
      if control is Label and not fits(control):complete=false
    for control in page.column.get_children():
     if not control.has_meta("skip_paging") and not control in reached:all_reachable=false
   h.check("every settings row fits without touching its page navigation",complete)
   h.check("all settings options remain reachable without a wheel",all_reachable)
   h.eq("settings uses bounded pages for every category",settings.tabs.get_children().filter(func(c):return c is ScrollContainer).size(),0)
   settings.queue_free();await frames()
 UiSkin.configure("dark","system");Session.campaign_state={};Session.story_mode=false
 quit(h.finish())
