extends RefCounted
## Pixel-art 9-slice styles from assets/ui (falls back to flat colours if missing).


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
	b.add_theme_stylebox_override("normal", box("assets/ui/button_normal.png", 5))
	b.add_theme_stylebox_override("hover", box("assets/ui/button_hover.png", 5))
	b.add_theme_stylebox_override("focus", box("assets/ui/button_hover.png", 5))
	b.add_theme_stylebox_override("pressed", box("assets/ui/button_pressed.png", 5))
	b.add_theme_stylebox_override("disabled", box("assets/ui/button_disabled.png", 5))
