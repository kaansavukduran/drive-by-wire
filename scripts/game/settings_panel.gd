extends PanelContainer
## Shared settings; native Godot controls, bounded input maps, coalesced saves.
const SaveStore := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Controls := preload("res://scripts/game/controls.gd")
signal changed(settings: Dictionary)
signal closed
signal data_reset
var store: RefCounted
var settings: Dictionary = {}
var status: Label
var back: Button
var options: Dictionary = {}
var volume_slider: HSlider
var tabs: TabContainer
var input_mode: OptionButton
var binding_buttons: Dictionary = {}
var reset_button: Button
var reset_dialog: ConfirmationDialog
var save_timer: Timer
var capture_action := ""
var _dirty := false

func _init() -> void:
 position = Vector2(100, 28)
 size = Vector2(440, 304)
 theme = UiSkin.theme()
 add_theme_stylebox_override("panel", UiSkin.panel(Color("9de1c3")))

func _ready() -> void:
 store = SaveStore.new()
 settings = store.load_data()["settings"].duplicate(true)
 save_timer = Timer.new()
 save_timer.one_shot = true
 save_timer.wait_time = 0.25
 save_timer.timeout.connect(flush)
 add_child(save_timer)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 6)
 add_child(column)
 var title := Label.new()
 title.text = "AYARLAR · Sana göre bir yol"
 title.add_theme_font_size_override("font_size", 16)
 column.add_child(title)
 tabs = TabContainer.new()
 tabs.custom_minimum_size.y = 172
 tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.add_child(tabs)
 var play := _page("Oyun")
 for spec in [["sound","Ses efektleri"],["effects","Kamera sarsıntısı"],["motion","Dekoratif hareket"],["auto_fire","Otomatik ateş"],["vibration","Kumanda titreşimi"],["low_power","Düşük güç · sonraki açılış"]]:
  var key: String = spec[0]
  var caption: String = spec[1]
  var toggle := CheckButton.new()
  toggle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  toggle.text = caption + (" · Açık" if bool(settings[key]) else " · Kapalı")
  toggle.button_pressed = bool(settings[key])
  toggle.toggled.connect(func(value: bool):
   settings[key] = value
   toggle.text = caption + (" · Açık" if value else " · Kapalı")
   _persist())
  toggle.visible = key != "low_power" or OS.has_feature("web")
  options[key] = toggle
  play.add_child(toggle)
 var row := HBoxContainer.new()
 play.add_child(row)
 var volume_label := Label.new()
 volume_label.text = "Ses düzeyi"
 row.add_child(volume_label)
 volume_slider = HSlider.new()
 volume_slider.min_value = 0
 volume_slider.max_value = 100
 volume_slider.step = 5
 volume_slider.value = float(settings["volume"]) * 100
 volume_slider.custom_minimum_size = Vector2(160, 26)
 volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 volume_slider.tooltip_text = "Ses düzeyi; sol ve sağ oklarla değiştirilebilir."
 row.add_child(volume_slider)
 var amount := Label.new()
 amount.custom_minimum_size.x = 40
 amount.text = "%d%%" % int(volume_slider.value)
 row.add_child(amount)
 volume_slider.value_changed.connect(func(value: float):
  settings["volume"] = value / 100
  amount.text = "%d%%" % int(value)
  _persist())
 _note(play, "Otomatik ateş basılı tutmayı azaltır. Düşük güç modu daha sade çizimle akıcılığı artırır; yeniden açınca uygulanır.")
 _make_controls(_page("Kontroller"))
 var privacy := _page("Veri")
 _note(privacy, "Rekor, MOMO hafızası ve tercihler yalnızca bu cihazda saklanır. Hesap, reklam, analiz servisi veya sunucuya gönderim yoktur.\n\nSıfırlama ilerlemeyi, tercihleri ve kurtarma kopyasını siler.")
 reset_button = _button(privacy,"Bu cihazdaki verileri sıfırla",func(): _show_reset())
 reset_dialog = ConfirmationDialog.new()
 UiSkin.prepare_confirmation(reset_dialog)
 reset_dialog.title = "Yerel verileri sıfırla?"
 reset_dialog.dialog_text = "Rekor, MOMO hafızası ve tercihler bu cihazdan silinecek. Bu işlem geri alınamaz."
 reset_dialog.ok_button_text = "Verileri sil"
 reset_dialog.cancel_button_text = "Vazgeç"
 reset_dialog.confirmed.connect(_reset_data)
 add_child(reset_dialog)
 status = Label.new()
 status.text = "Tercihlerin bu cihazda saklanır."
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 status.custom_minimum_size=Vector2(220,26)
 status.add_theme_font_size_override("font_size", 10)
 column.add_child(status)
 back = _button(column,"Geri · Esc / B",close)
 get_viewport().size_changed.connect(_fit_viewport)
 _fit_viewport()
 hide()

func _page(title: String) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.name = title
 scroll.follow_focus = true
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 tabs.add_child(scroll)
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",4)
 scroll.add_child(column)
 return column

func _note(parent: Node, text: String) -> void:
 var label := Label.new()
 label.text = text
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",11)
 parent.add_child(label)

func _button(parent: Node, text: String, callback: Callable) -> Button:
 var button := Button.new()
 button.text = text
 button.custom_minimum_size.y = 28
 UiSkin.style_button(button)
 button.pressed.connect(callback)
 parent.add_child(button)
 return button

func _make_controls(parent: Node) -> void:
 input_mode = OptionButton.new()
 input_mode.add_item("Klavye tuşlarını değiştir")
 input_mode.add_item("Kumanda düğmelerini değiştir")
 input_mode.item_selected.connect(func(_index: int): _refresh_bindings())
 parent.add_child(input_mode)
 for action in Controls.LABELS:
  var name: String = action
  var button := _button(parent,"",func():
   capture_action = name
   status.text = "%s için yeni girişe bas. Esc / B vazgeçer." % Controls.LABELS[name])
  binding_buttons[name] = button
 var deadzone_label := Label.new()
 deadzone_label.text = "Çubuk ölü bölgesi · %d%%" % int(settings["deadzone"] * 100)
 parent.add_child(deadzone_label)
 var zone := HSlider.new()
 zone.min_value = 20
 zone.max_value = 60
 zone.step = 5
 zone.value = float(settings["deadzone"]) * 100
 zone.custom_minimum_size.y = 26
 zone.value_changed.connect(func(value: float):
  settings["deadzone"] = value / 100
  deadzone_label.text = "Çubuk ölü bölgesi · %d%%" % int(value)
  _persist())
 parent.add_child(zone)
 _button(parent,"Varsayılan tuşlara dön",func():
  settings["bindings"] = {}
  settings["pad_bindings"] = {}
  _persist()
  _refresh_bindings())
 _note(parent,"Sol çubuk şerit; yukarı/aşağı turbo/fren. RT ateş, LT fren. Menülerde yönler seçer, A onaylar, B geri döner. Ayarlar: LB / RB sekme. Start mola verir.")
 Controls.install(settings["bindings"],settings["pad_bindings"],settings["deadzone"])
 _refresh_bindings()

func _refresh_bindings() -> void:
 if not is_instance_valid(input_mode): return
 for action in binding_buttons:
  binding_buttons[action].text = "%s · %s" % [Controls.LABELS[action],Controls.binding_name(action,input_mode.selected==1)]

func _input(event: InputEvent) -> void:
 if not visible: return
 Controls.observe(event)
 if reset_dialog.visible: return
 if capture_action != "":
  if event.is_action_pressed("ui_cancel"):
   capture_action = ""
   status.text = "Tuş değişikliği iptal edildi."
   get_viewport().set_input_as_handled()
   return
  var is_pad := input_mode.selected == 1
  var code := -1
  if is_pad and event is InputEventJoypadButton and event.pressed: code=event.button_index
  elif not is_pad and event is InputEventKey and event.pressed and not event.echo: code=event.physical_keycode if event.physical_keycode else event.keycode
  if code < 0: return
  var field := "pad_bindings" if is_pad else "bindings"
  var error := Controls.binding_error(capture_action,code,is_pad,settings[field])
  if error != "": status.text=error
  else:
   settings[field][capture_action] = code
   capture_action = ""
   _persist()
   _refresh_bindings()
  get_viewport().set_input_as_handled()
 elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
  tabs.current_tab = posmod(tabs.current_tab + (1 if event.button_index == JOY_BUTTON_RIGHT_SHOULDER else -1),tabs.get_tab_count())
  back.grab_focus()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("ui_cancel"):
  close()
  get_viewport().set_input_as_handled()

func open() -> void:
 show()
 call_deferred("_fit_viewport")
 back.grab_focus()

func close() -> void:
 capture_action = ""
 flush()
 closed.emit()

func _persist() -> void:
 _dirty = true
 Controls.install(settings["bindings"],settings["pad_bindings"],settings["deadzone"])
 if OS.has_feature("web"):
  JavaScriptBridge.eval("try{localStorage.setItem('dbw.low_power','%s')}catch(e){}" % ("1" if settings["low_power"] else "0"))
 status.text = "Uygulandı · kaydediliyor…"
 save_timer.start()
 changed.emit(settings.duplicate(true))

func flush() -> void:
 if not _dirty: return
 save_timer.stop()
 var save: Dictionary = store.load_data()
 save["settings"] = settings.duplicate(true)
 var ok: bool = store.save_data(save)
 _dirty = not ok
 status.text = "Kaydedildi. Düşük güç değişikliği sonraki açılışta uygulanır." if ok else "Kayıt yazılamadı. Bu oturumda uygulanıyor; Geri ile yeniden denenir."
 status.modulate = Color("9de1c3") if ok else Color("ffb3a8")

func _show_reset() -> void:
 reset_dialog.popup_centered(Vector2i(380,160))
 reset_dialog.get_cancel_button().grab_focus()

func _reset_data() -> void:
 save_timer.stop()
 _dirty = false
 if not store.clear():
  status.text = "Veriler silinemedi. Bu cihazın depolama izinlerini kontrol et."
  return
 if OS.has_feature("web"):
  JavaScriptBridge.eval("try{localStorage.removeItem('dbw.low_power')}catch(e){}")
 settings=store.defaults()["settings"]
 Controls.install()
 data_reset.emit()


func _fit_viewport() -> void:
 var view: Vector2=get_viewport().get_visible_rect().size
 var portrait := view.y>view.x
 position=Vector2(8,24) if portrait else (view-Vector2(440,304))/2
 size=view-Vector2(16,48) if portrait else Vector2(440,304)
 for toggle in options.values(): toggle.custom_minimum_size.y=44 if portrait else 28
 for button in binding_buttons.values(): button.custom_minimum_size.y=44 if portrait else 28
 back.custom_minimum_size.y=44 if portrait else 28


func _process(_delta: float) -> void:
 if not visible: return
 var view: Vector2=get_viewport().get_visible_rect().size
 var target := view-Vector2(16,48) if view.y>view.x else Vector2(440,304)
 if not size.is_equal_approx(target): _fit_viewport()
