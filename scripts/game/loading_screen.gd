extends Control
## Native Godot loader uses measured ResourceLoader progress, without a timer.
var brand_art: Texture2D
const BRAND_PATH := "res://assets/brand/fragaria-strawberry.jpg"
const BRAND_FONT := preload("res://assets/fonts/VT323.ttf")
var progress: Array=[]
var amount := -1.0
var status: Label
var retry: Button
var started_at := 0
var failed := false
const TARGET := "res://scenes/title.tscn"
func _ready() -> void:
 if ResourceLoader.exists(BRAND_PATH): brand_art=load(BRAND_PATH)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var wordmark:=Label.new()
 wordmark.name="Wordmark"
 wordmark.text="FRAGARIA\nINTERACTIVE"
 wordmark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 wordmark.add_theme_font_override("font",BRAND_FONT)
 wordmark.add_theme_font_size_override("font_size",24)
 wordmark.add_theme_color_override("font_color",Color("f5f1e8"))
 add_child(wordmark)
 status=Label.new()
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status.add_theme_color_override("font_color",Color("f5f1e8"))
 add_child(status)
 retry=Button.new()
 retry.text="Yeniden dene"
 retry.pressed.connect(_request)
 retry.hide()
 add_child(retry)
 var version:=Label.new()
 version.name="Version"
 version.text="v"+str(ProjectSettings.get_setting("application/config/version"))
 version.add_theme_font_size_override("font_size",10)
 version.add_theme_color_override("font_color",Color("b6c5ce"))
 add_child(version)
 get_viewport().size_changed.connect(_layout)
 _layout()
 _request()
func _request() -> void:
 failed=false
 retry.hide()
 progress=[]
 amount=-1
 started_at=Time.get_ticks_msec()
 status.text="Oyun kaynakları hazırlanıyor…"
 var error:=ResourceLoader.load_threaded_request(TARGET)
 if error!=OK: _failure()
func _failure() -> void:
 failed=true
 status.text="Oyun kaynakları açılamadı. Yeniden dene; sorun sürerse kurulum dosyalarını doğrula."
 retry.show()
 retry.grab_focus()
func _process(_delta: float) -> void:
 if failed: return
 var state:=ResourceLoader.load_threaded_get_status(TARGET,progress)
 if state==ResourceLoader.THREAD_LOAD_LOADED:
  var scene: PackedScene=ResourceLoader.load_threaded_get(TARGET)
  if scene==null: _failure()
  else:
   set_process(false)
   get_tree().change_scene_to_packed(scene)
 elif state in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]: _failure()
 elif not progress.is_empty():
  amount=clampf(float(progress[0]),0,1)
  status.text="Kaynaklar hazırlanıyor · %%%d" % int(amount*100)
 if Time.get_ticks_msec()-started_at>30000: status.text="Hazırlık beklenenden uzun sürüyor; bekleyebilir veya yeniden açabilirsin."
 queue_redraw()
func _layout() -> void:
 var view: Vector2=get_viewport().get_visible_rect().size
 var centre: Vector2=Vector2(view.x/2,view.y/2-40)
 get_node("Wordmark").position=centre+Vector2(-120,36)
 get_node("Wordmark").size=Vector2(240,60)
 status.position=Vector2(16,view.y-64)
 status.size=Vector2(view.x-32,40)
 retry.position=Vector2(view.x/2-80,view.y-116)
 retry.size=Vector2(160,44)
 get_node("Version").position=Vector2(8,view.y-18)
 queue_redraw()
func _draw() -> void:
 var view: Vector2=get_viewport().get_visible_rect().size
 draw_rect(Rect2(Vector2.ZERO,view),Color.BLACK)
 var centre: Vector2=Vector2(view.x/2,view.y/2-40)
 if brand_art!=null: draw_texture_rect(brand_art,Rect2(centre+Vector2(-50,-108),Vector2(100,140)),false)
 var width: float=minf(280,view.x-48)
 for i in 10:
  var lit: bool=amount>=0 and i<int(amount*10)
  var c: Color=(Color("80cf8a") if i>=7 else Color("ed587f")) if lit else Color("333b43")
  draw_rect(Rect2((view.x-width)/2+i*(width+4)/10,view.y-84,(width-36)/10,12),c)
