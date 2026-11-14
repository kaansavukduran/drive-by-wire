extends SceneTree
const H=preload("res://tests/harness.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const Session=preload("res://scripts/game/session.gd")
const Fit=preload("res://scripts/game/text_fit.gd")
const Reader=preload("res://scripts/game/text_reader.gd")
const Controls=preload("res://scripts/game/controls.gd")
var h=H.new("ui_readability")
func _initialize() -> void:call_deferred("run")
func frames() -> void:await process_frame;await process_frame
func collisions(game: Node) -> Array[String]:
 var named={"health":game.hud,"score":game.score_label,"distance":game.distance_caption,"controls":game.hint,"notice":game.toast,"stage":game.story_caption,"speaker":game.momo_title,"speech":game.bubble,"page":game.radio_page_caption,"touch_hint":game.touch_hint}
 var active: Array=[];var issues: Array[String]=[]
 for key in named:
  if named[key].is_visible_in_tree() and not named[key].text.is_empty():active.append(key)
 for i in active.size():
  for j in range(i+1,active.size()):
   var a: Label=named[active[i]];var b: Label=named[active[j]]
   if a.get_global_rect().grow(a.get_theme_constant("outline_size")).intersects(b.get_global_rect().grow(b.get_theme_constant("outline_size"))):issues.append(active[i]+" / "+active[j])
 return issues
func run() -> void:
 Session.story_mode=false;Session.campaign_state={}
 for mode in ["dark","light"]:
  for font in ["system","lexend"]:
   UiSkin.configure(mode,font)
   for view in [Vector2i(640,360),Vector2i(800,360),Vector2i(360,640),Vector2i(320,568)]:
    root.size=view;root.content_scale_size=view;await frames()
    var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.set_physics_process(false);game.set_process(false)
    for touch in [false,true]:
     for device in ["keyboard","pad"]:
      game.touch_enabled=touch;Controls.last_device=device;game._layout()
      game._say("omer: İki kapı aynı enerjiyi istiyor. Birini şimdi açarsak diğeri için beklemek gerekecek.",true)
      game._notice("GÖREV TAMAM! +200 puan\n+onarım · mayın hazır");game._process(0);game._update_hud();await frames()
      var issues:=collisions(game)
      h.check("HUD text has its own area %s %s %s touch%s %s: %s"%[mode,font,view,touch,device,", ".join(issues)],issues.is_empty())
      var complete:=true
      for widget in game._radio_snapshot()["widgets"]:
       if not widget["fits"]:complete=false
      h.check("all visible HUD words fit",complete)
      h.check("bare world text remains readable in both themes",game.hud.get_theme_color("font_color").get_luminance()>.8 and game.toast.get_theme_color("font_color").get_luminance()>.6)
    game.queue_free();await frames()
 var reader:=Reader.new();reader.theme=UiSkin.theme();root.add_child(reader);reader.size=Vector2(190,210)
 var words: PackedStringArray=[]
 for i in 100:words.append("sözcük%03d"%i)
 reader.set_text(" ".join(words));await frames();reader.turn(2)
 var anchor: String=reader.content.text.split(" ",false)[0]
 reader.size=Vector2(410,190);await frames()
 h.check("resize keeps the word being read on the current page",anchor in reader.content.text)
 reader.reflow();reader.size=Vector2(190,210);await frames()
 h.check("repeated reflow does not erase the reading anchor",anchor in reader.content.text)
 var offset: int=reader.reading_offset
 UiSkin.configure("dark","system");await frames()
 h.check("font change keeps text fully fitted",Fit.fits(reader.content))
 h.eq("theme/font reflow preserves exact reading offset",reader.reading_offset,offset)
 h.check("font change keeps the word being read",anchor in reader.content.text)
 reader.queue_free();await frames()
 # Reflow consumers preserve a stable visible-character anchor, not page number.
 root.size=Vector2i(640,360);root.content_scale_size=root.size;await frames()
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.set_process(false);game.set_physics_process(false)
 game._say("omer: "+" ".join(words),true);game._advance_radio(game.bubble_left+.1);game._advance_radio(game.bubble_left+.1)
 var radio_anchor: String=game.bubble.text.split(" ",false)[0];var radio_offset: int=game.radio_offset
 root.size=Vector2i(360,640);root.content_scale_size=root.size;await frames();game._layout();game._layout()
 h.eq("radio reflow retains exact anchor across repeated layout",game.radio_offset,radio_offset)
 h.check("radio does not skip unread words on rotation",radio_anchor in game.bubble.text)
 game.queue_free();await frames()
 root.size=Vector2i(640,360);root.content_scale_size=root.size;await frames()
 var garage=load("res://scenes/garage.tscn").instantiate();root.add_child(garage);await frames();garage.set_process(false)
 garage._say(" ".join(words));garage.speech_page=2;garage._show_speech_page()
 var speech_anchor: String=garage.speech.text.split(" ",false)[0];var speech_offset: int=garage.speech_offset
 root.size=Vector2i(360,640);root.content_scale_size=root.size;await frames();garage._layout();garage._layout()
 h.eq("garage reflow retains exact reading offset",garage.speech_offset,speech_offset)
 h.check("garage keeps the current word after rotation",speech_anchor in garage.speech.text)
 garage.queue_free();await frames()
 Controls.install({}, {"drive_fire":JOY_BUTTON_Y,"drive_mine":JOY_BUTTON_RIGHT_SHOULDER});Controls.last_device="pad"
 var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_Y;event.pressed=true
 h.check("custom pad binding remains real InputMap input",InputMap.event_is_action(event,"drive_fire"))
 h.check("pad hints reflect actual fire and mine bindings",Controls.run_hint().contains("Y Ateş") and Controls.run_hint().contains("RB Mayın") and not Controls.run_hint().contains("X Mayın"))
 var page=load("res://scripts/game/paged_settings.gd").new();page.theme=UiSkin.theme();root.add_child(page);page.size=Vector2(300,100)
 var rows: Array[Button]=[]
 for i in 4:
  var row:=Button.new();row.text="Seçenek %d"%i;row.custom_minimum_size.y=40;page.column.add_child(row);rows.append(row)
 await frames();page.reflow();page.page_index=1;page._show_page();rows[1].grab_focus()
 h.check("settings edited row starts visible and focused",rows[1].is_visible_in_tree() and rows[1].has_focus())
 page.size=Vector2(300,150);await frames();page.reflow()
 h.check("reflow keeps the edited settings row visible",rows[1].is_visible_in_tree())
 h.check("reflow preserves focus on the edited setting",rows[1].has_focus())
 page.turn(1);await frames();page.reflow()
 h.check("explicit next page is not undone by the old row anchor",rows[2].is_visible_in_tree() and rows[3].is_visible_in_tree())
 page.queue_free();await frames()
 var label:=Label.new();label.theme=UiSkin.theme();label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.clip_text=true;label.add_theme_font_size_override("font_size",13);label.size=Vector2(190,40);root.add_child(label);await frames()
 var prose: String="İlk cümle tamam.\n\nİkinci cümle bütün kelimeleriyle burada.\nÜçüncü satır da korunur."
 var pages:=Fit.pages(prose,label)
 h.eq("paragraph pagination preserves words", " ".join(" ".join(pages).replace("\n"," ").split(" ",false))," ".join(prose.replace("\n"," ").split(" ",false)))
 label.queue_free();UiSkin.configure("dark","system");Controls.install();quit(h.finish())
