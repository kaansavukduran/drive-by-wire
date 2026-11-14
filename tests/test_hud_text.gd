extends SceneTree
const H:=preload("res://tests/harness.gd")
const Book:=preload("res://scripts/core/story_book.gd")
const Store:=preload("res://scripts/core/save_store.gd")
const UiSkin:=preload("res://scripts/game/ui_skin.gd")
const Controls:=preload("res://scripts/game/controls.gd")
var h:=H.new("hud_text")
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 await process_frame;await process_frame
func actual_fits(label: Label) -> bool:
 if label.text.is_empty(): return true
 var count:=label.get_line_count()
 var height:=maxi(0,count-1)*label.get_theme_constant("line_spacing")
 for i in count: height+=label.get_line_height(i)
 if label.has_theme_stylebox("normal"): height+=label.get_theme_stylebox("normal").get_minimum_size().y
 return height<=label.size.y+0.5
func normalized(text: String) -> String:
 return " ".join(text.replace("\n"," ").split(" ",false))
func run() -> void:
 var lines: Array[String]=["omer: İki kapı aynı enerjiyi istiyor. Birini şimdi açarsak diğeri için beklemek gerekecek.","Baykuş Ömer: "+"Uzun bir cümlenin her kelimesi okunmalı. ".repeat(12)]
 for node in Book.data()["nodes"].values():
  for line in node.get("beats",[]):
   if not line in lines: lines.append(line)
 for font in ["system","lexend"]:
  UiSkin.configure("dark",font)
  for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(360,780),Vector2i(640,480)]:
   root.content_scale_size=dimensions;root.size=dimensions
   var game: Node=load("res://scenes/main.tscn").instantiate();root.add_child(game)
   game.set_physics_process(false);game.set_process(false)
   game.store=Store.new("user://hud-text-fixture.json")
   await frames()
   for touch in [false,true]:
    game.touch_enabled=touch
    for device in ["keyboard","pad"]:
     Controls.last_device=device;game._layout();await frames()
     game.momo.trust=100;game.momo.set_mood("excited");game.shield_left=3.2;game._update_hud()
     var fits:=true
     var all_words:=true
     for line in lines:
      game._say(line,true)
      var reconstructed: String=" ".join(game.radio_pages)
      var expected: String=game.radio_text
      if normalized(reconstructed)!=normalized(expected): all_words=false
      for page in game.radio_pages.size():
       game.radio_page=page;game._show_radio_page()
       if not actual_fits(game.bubble) or not actual_fits(game.radio_page_caption): fits=false
     h.check("all radio pages fully fit %s %s touch%s %s" % [font,dimensions,touch,device],fits)
     h.check("pagination preserves every word %s %s touch%s %s" % [font,dimensions,touch,device],all_words)
     var clear:=true
     var labels: Array=[game.bubble,game.radio_page_caption,game.status_label,game.hint,game.momo_title]
     for i in labels.size():
      if not labels[i].visible: continue
      if not actual_fits(labels[i]): clear=false
      for j in range(i+1,labels.size()):
       if labels[j].visible and labels[i].get_global_rect().intersects(labels[j].get_global_rect()): clear=false
      if labels[i].get_global_rect().intersects(game.pause_button.get_global_rect()): clear=false
     h.check("radio/status/hints/pause areas stay separate %s %s touch%s %s" % [font,dimensions,touch,device],clear)
     for contract in 3:
      game.arcade.contract=contract;game._update_hud()
      h.check("HUD mission and stats fully fit %s %s %s" % [font,dimensions,contract],actual_fits(game.hud) and actual_fits(game.mission) and actual_fits(game.story_caption) and actual_fits(game.score_label) and actual_fits(game.energy_caption) and actual_fits(game.distance_caption))
     game._notice("OMEGA-3 · ALAN DARBESİ\nYakın mermiler temizlendi · +enerji")
     h.check("feedback text fits and clears objective %s %s" % [font,dimensions],actual_fits(game.toast) and not game.toast.get_global_rect().intersects(game.story_caption.get_global_rect()))
   game._say(lines[1],true)
   h.check("long radio really has several pages",game.radio_pages.size()>1)
   var full: String=game.radio_text
   game._advance_radio(game.bubble_left+0.1)
   h.eq("automatic playback advances exactly one page",game.radio_page,1)
   h.eq("automatic playback preserves full message",game.radio_text,full)
   h.check("full radio message stays in journal",game.journey.log_lines.any(func(x): return str(x).contains(full)))
   h.check("speaker header matches portrait",game.momo_title.text.begins_with("Baykuş Ömer") and game.radio_portrait.speaker=="omer")
   game._set_paused(true)
   var timer: float=game.bubble_left;game._process(1)
   h.eq("pause freezes reading time",game.bubble_left,timer)
   game._set_paused(false)
   for page in game.radio_pages.size(): game._advance_radio(game.bubble_left+0.1)
   game._layout();await frames()
   h.check("expired radio stays cleared after layout and font reflow",game.bubble.text.is_empty() and game.radio_page_caption.text.is_empty() and game.radio_text.is_empty())
   game._end_run("survived");await frames()
   h.check("result summary fits without covering result buttons %s %s" % [font,dimensions],actual_fits(game.end_panel) and not game.end_panel.get_global_rect().intersects(game.result_buttons[0].get_global_rect()))
   game.store.clear();game.queue_free();await frames()
 UiSkin.configure("dark","system")
 quit(h.finish())
