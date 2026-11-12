extends RefCounted
## AIONIA game-specific UI: square pixel borders, ink, cream, mint and rose.

const FONT := preload("res://assets/fonts/Lexend.ttf")
const SYMBOLS := preload("res://assets/fonts/ControlSymbols.ttf")

static func theme() -> Theme:
	var result := Theme.new()
	var font: FontFile = FONT.duplicate()
	font.fallbacks = [SYMBOLS]
	result.default_font = font
	result.default_font_size = 12
	return result

static func panel(accent := Color("415774")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111d2b")
	style.border_color = accent
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_content_margin_all(10)
	style.shadow_color = Color(0.02, 0.03, 0.06, 0.65)
	style.shadow_size = 0
	style.anti_aliasing = false
	style.shadow_offset = Vector2(0, 2)
	return style


static func box(path: String, margin: int, content: int = -1) -> StyleBox:
	var full := "res://" + path
	if not ResourceLoader.exists(full):
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.08, 0.09, 0.13, 0.92)
		flat.set_content_margin_all(6)
		return flat
	var sb := StyleBoxTexture.new()
	sb.texture = load(full)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.set_content_margin_all(margin + 2 if content < 0 else content)
	return sb


static func style_button(b: Button) -> void:
	var normal := panel(Color("526c88"))
	normal.bg_color = Color("23354c")
	normal.set_content_margin_all(5)
	var hover := normal.duplicate()
	hover.bg_color = Color("35455f")
	hover.border_color = Color("f4a8c5")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("245657")
	pressed.border_color = Color("9de1c3")
	var focus := normal.duplicate()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("aaf2d3")
	focus.set_border_width_all(2)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("1a2638")
	disabled.border_color = Color("41516b")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", Color("fff2df"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("94a3bb"))


static func prepare_confirmation(dialog: ConfirmationDialog) -> void:
	dialog.theme = theme()
	dialog.theme.set_stylebox("panel","AcceptDialog",panel(Color("f4a8c5")))
	style_button(dialog.get_ok_button())
	style_button(dialog.get_cancel_button())
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size.x = 340
	# Godot's native dialog handles Escape; explicitly support controller Back too.
	dialog.window_input.connect(func(event: InputEvent):
		if event is InputEventJoypadButton and event.is_action_pressed("ui_cancel"):
			dialog.hide()
			dialog.canceled.emit()
			dialog.set_input_as_handled())
	dialog.about_to_popup.connect(func():
		var width: float=dialog.get_tree().root.get_visible_rect().size.x
		dialog.get_label().custom_minimum_size.x=minf(340,width-64)
		dialog.size.x=mini(dialog.size.x,int(width-24))
		dialog.get_cancel_button().call_deferred("grab_focus"))
