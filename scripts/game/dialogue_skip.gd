extends MenuButton

signal skip_line
signal skip_remaining

func _ready() -> void:
	text = "Atla"
	flat = false
	focus_mode = Control.FOCUS_ALL
	var menu := get_popup()
	menu.add_item("Bu repliği atla", 0)
	menu.add_item("Tüm replikleri atla", 1)
	menu.add_theme_constant_override("v_separation", 34)
	menu.id_pressed.connect(_select_skip)
	menu.about_to_popup.connect(func(): menu.set_focused_item(0))

func _select_skip(id: int) -> void:
	if id == 0:
		skip_line.emit()
	else:
		skip_remaining.emit()

func popup_bounds() -> Array[int]:
	var popup := get_popup()
	return [popup.position.x, popup.position.y, popup.size.x, popup.size.y]
