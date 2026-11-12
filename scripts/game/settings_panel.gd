extends PanelContainer
## Shared title/run settings. Applies immediately; failures are visible.

const SaveStore := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
signal changed(settings: Dictionary)
signal closed
var store: RefCounted
var settings: Dictionary = {}
var status: Label
var back: Button

func _init() -> void:
	position = Vector2(145, 42)
	size = Vector2(350, 276)
	theme = UiSkin.theme()
	add_theme_stylebox_override("panel", UiSkin.panel(Color("9de1c3")))

func _ready() -> void:
	store = SaveStore.new()
	settings = store.load_data()["settings"].duplicate()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	add_child(column)
	var title := Label.new()
	title.text = "AYARLAR · Sana göre bir yol"
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)
	for spec in [["sound", "Ses efektleri"], ["effects", "Kamera sarsıntısı"], ["motion", "Dekoratif arka plan hareketi"]]:
		var key: String = spec[0]
		var toggle := CheckButton.new()
		var title_text: String = spec[1]
		toggle.text = title_text + (" · Açık" if bool(settings[key]) else " · Kapalı")
		toggle.button_pressed = bool(settings[key])
		toggle.toggled.connect(func(value: bool):
			toggle.text = title_text + (" · Açık" if value else " · Kapalı")
			settings[key] = value
			_persist())
		column.add_child(toggle)
	var row := HBoxContainer.new()
	column.add_child(row)
	var label := Label.new()
	label.text = "Ses düzeyi"
	label.custom_minimum_size.x = 92
	row.add_child(label)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	volume.value = float(settings["volume"]) * 100
	volume.custom_minimum_size = Vector2(148, 22)
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(volume)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 38
	value_label.text = "%d%%" % int(volume.value)
	row.add_child(value_label)
	volume.value_changed.connect(func(value: float):
		settings["volume"] = value / 100.0
		value_label.text = "%d%%" % int(value)
		_persist())
	status = Label.new()
	status.text = "Tercihlerin bu cihazda saklanır."
	status.add_theme_font_size_override("font_size", 10)
	column.add_child(status)
	back = Button.new()
	back.text = "Geri · Esc"
	back.custom_minimum_size.y = 28
	UiSkin.style_button(back)
	back.pressed.connect(func(): closed.emit())
	column.add_child(back)
	hide()

func open() -> void:
	show()
	back.grab_focus()

func _persist() -> void:
	# Re-read the full record so settings never overwrite a newer run result.
	var save: Dictionary = store.load_data()
	save["settings"] = settings.duplicate()
	var ok: bool = store.save_data(save)
	status.text = "Kaydedildi." if ok else "Kayıt yazılamadı. Bu oturumda uygulanıyor."
	status.modulate = Color("9de1c3") if ok else Color("ffb3a8")
	changed.emit(settings.duplicate())
