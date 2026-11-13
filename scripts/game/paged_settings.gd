extends Control
## Settings rows stay in a bounded page; focus never scrolls controls offscreen.
const TextFit=preload("res://scripts/game/text_fit.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
var column: VBoxContainer
var previous: Button
var next: Button
var counter: Label
var groups: Array=[]
var page_index:=0
var _last_size:=Vector2.ZERO
var _last_count:=-1
func _init() -> void:
 column=VBoxContainer.new();column.add_theme_constant_override("separation",4);add_child(column)
func _ready() -> void:
 previous=_button("Önceki",-1);next=_button("Sonraki",1)
 counter=Label.new();counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;counter.clip_text=true;add_child(counter)
 resized.connect(reflow);call_deferred("reflow")
func _button(text: String,step: int) -> Button:
 var b:=Button.new();b.text=text;UiSkin.style_button(b);b.pressed.connect(func():turn(step));add_child(b);return b
func _process(_delta: float) -> void:
 if is_visible_in_tree() and (size!=_last_size or column.get_child_count()!=_last_count): reflow()
func reflow() -> void:
 if not is_instance_valid(previous): return
 _last_size=size;_last_count=column.get_child_count();column.position=Vector2.ZERO;column.size.x=size.x
 var nav:=44.0 if DisplayServer.is_touchscreen_available() else 28.0
 var height:=maxf(44,size.y-nav-6)
 groups.clear();var group: Array=[];var occupied:=0.0
 for child in column.get_children():
  if child.has_meta("skip_paging"): continue
  var row_height: float=child.get_combined_minimum_size().y
  if child is Label:
   child.clip_text=true;child.size.x=size.x
   var probe:=TextFit.probe_for(child);probe.size.x=size.x;row_height=TextFit.height(probe,child.text);probe.free()
   child.custom_minimum_size.y=row_height
  if child is BaseButton:
   row_height=maxf(row_height,nav);child.custom_minimum_size.y=row_height
  if occupied+row_height>height and not group.is_empty(): groups.append(group);group=[];occupied=0
  group.append(child);occupied+=row_height+4
 if not group.is_empty(): groups.append(group)
 if groups.is_empty():groups.append([])
 page_index=clampi(page_index,0,groups.size()-1)
 _show_page()
 var w: float=floorf((size.x-68)/2)
 previous.position=Vector2(0,size.y-nav);previous.size=Vector2(w,nav)
 next.position=Vector2(size.x-w,size.y-nav);next.size=Vector2(w,nav)
 counter.position=Vector2(w+2,size.y-nav);counter.size=Vector2(64,nav)
func _show_page() -> void:
 for child in column.get_children(): child.visible=not child.has_meta("skip_paging") and child in groups[page_index]
 previous.disabled=page_index==0;next.disabled=page_index==groups.size()-1
 counter.text="%d / %d" % [page_index+1,groups.size()]
 if previous.disabled and previous.has_focus(): next.grab_focus()
 elif next.disabled and next.has_focus(): previous.grab_focus()
func turn(step: int) -> void:
 page_index=clampi(page_index+step,0,maxi(0,groups.size()-1));_show_page()
func _input(event: InputEvent) -> void:
 if not is_visible_in_tree():return
 # Left/right remain available to sliders and option buttons. Page with the visible nav.
 if event.is_action_pressed("ui_page_up") or event.is_action_pressed("ui_page_down"):
  turn(-1 if event.is_action_pressed("ui_page_up") else 1);get_viewport().set_input_as_handled()
