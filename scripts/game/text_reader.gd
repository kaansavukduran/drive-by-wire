extends Control
## A bounded reader: every word is reachable with touch, keyboard or gamepad.
const TextFit=preload("res://scripts/game/text_fit.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const QA=preload("res://scripts/game/qa_snapshot.gd")
var full_text: String=""
var pages: Array[String]=[]
var page_index:=0
var reading_offset:=0
var _theme_fit_queued:=false
var content: Label
var previous: Button
var next: Button
var counter: Label
var font_size:=13
func _ready() -> void:
 content=Label.new();content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.clip_text=true
 content.add_theme_font_size_override("font_size",font_size);add_child(content)
 previous=_button("Önceki · ←",-1);next=_button("Sonraki · →",1)
 counter=Label.new();counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;counter.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;counter.clip_text=true
 counter.add_theme_font_size_override("font_size",11);add_child(counter)
 resized.connect(reflow);theme_changed.connect(_queue_theme_fit);reflow()
func _button(text: String,step: int) -> Button:
 var b:=Button.new();b.text=text;UiSkin.style_button(b);b.pressed.connect(func(): turn(step));add_child(b);return b
func set_text(value: String,reset: bool=true) -> void:
 full_text=value
 if reset: page_index=0;reading_offset=0
 if is_node_ready(): reflow()
func reflow() -> void:
 if not is_node_ready(): return
 content.position=Vector2.ZERO;content.size=Vector2(size.x,maxf(16,size.y-52))
 var width:=floorf((size.x-76)/2)
 previous.position=Vector2(0,size.y-44);previous.size=Vector2(width,44)
 next.position=Vector2(size.x-width,size.y-44);next.size=Vector2(width,44)
 counter.position=Vector2(width+4,size.y-44);counter.size=Vector2(68,44)
 pages=TextFit.pages(full_text,content);page_index=TextFit.page_at(pages,reading_offset);_show_page(false)
func turn(step: int) -> void:
 page_index=clampi(page_index+step,0,maxi(0,pages.size()-1));_show_page()
func _show_page(remember: bool=true) -> void:
 if pages.is_empty(): return
 if remember:reading_offset=TextFit.offset_at(pages,page_index)
 content.text=pages[page_index];counter.text="%d / %d" % [page_index+1,pages.size()]
 previous.disabled=page_index==0;next.disabled=page_index==pages.size()-1
 # Do not strand focus on a button that just became disabled.
 if previous.has_focus() and previous.disabled: next.grab_focus()
 elif next.has_focus() and next.disabled: previous.grab_focus()
func _input(event: InputEvent) -> void:
 if not is_visible_in_tree(): return
 if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
  turn(-1 if event.is_action_pressed("ui_left") else 1);get_viewport().set_input_as_handled()
func snapshot() -> Dictionary:
 return {"page":page_index,"anchor":reading_offset,"pages":pages.size(),"text":content.text,"content":QA.rect(content),"previous":QA.rect(previous),"next":QA.rect(next),"counter":QA.rect(counter),"fits":TextFit.fits(content)}

func _queue_theme_fit() -> void:
 if not _theme_fit_queued:
  _theme_fit_queued=true;call_deferred("_fit_theme")
func _fit_theme() -> void:
 _theme_fit_queued=false;reflow()
