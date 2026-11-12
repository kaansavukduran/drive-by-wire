extends SceneTree
const Harness := preload("res://tests/harness.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
var h := Harness.new("title_ui")
var title: Node2D
var step := 0

func _initialize() -> void:
	title = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)

func _process(_delta: float) -> bool:
	step += 1
	if step < 2:
		return false
	h.eq("first keyboard focus is the play button", root.gui_get_focus_owner(), title.start_button)
	title._show_help()
	h.check("help is visible and underlying play is disabled", title.help_panel.visible and title.start_button.disabled)
	h.check("help content fits its clipped reading area",title.help_body.size.x<=title.help_scroll.size.x and title.help_scroll.clip_contents)
	h.check("long help remains vertically scrollable",title.help_scroll.get_v_scroll_bar().max_value>title.help_scroll.get_v_scroll_bar().page)
	title._hide_help()
	h.check("closing help restores play and keyboard focus", not title.help_panel.visible and not title.start_button.disabled and root.gui_get_focus_owner() == title.start_button)
	title._show_settings()
	var panel: Control = title.settings
	panel.store = SaveStore.new("user://test_title_ui.json")
	panel.store.clear()
	h.check("settings opens with its own keyboard focus", panel.visible and panel.back.has_focus() and title.start_button.disabled)
	panel.options["motion"].button_pressed = false
	panel.flush()
	h.check("reduced motion applies to the actual title", not title.motion)
	var face_time: float = title.face._t
	title.face.hurt = 0.35
	title.face._process(0.5)
	h.near("reduced motion freezes decorative frames", title.face._t, face_time, 0.001)
	h.near("reduced motion still expires damage feedback", title.face.hurt, 0.0, 0.001)
	var saved: Dictionary = panel.store.load_data()
	h.eq("reduced motion persists through the settings UI", saved["settings"]["motion"], false)
	var slider := panel.volume_slider as HSlider
	slider.value = 35
	panel.flush()
	h.near("volume persists through the real slider", float(panel.store.load_data()["settings"]["volume"]), 0.35, 0.001)
	# Explicitly unwritable destination: the UI keeps working and explains failure.
	panel.store = SaveStore.new("res://project.godot/not-a-directory/save.json")
	slider.value = 40
	panel.flush()
	h.check("save failure has an actionable visible status", panel.status.text.contains("Kayıt yazılamadı"))
	panel.close()
	h.check("closing settings restores the title", not panel.visible and not title.start_button.disabled)
	SaveStore.new("user://test_title_ui.json").clear()
	quit(h.finish())
	return true
