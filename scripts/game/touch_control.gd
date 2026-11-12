extends Control
## A real multitouch gameplay button, with the same skin as the menus.
## Standard GUI Buttons only emulate a single mouse pointer on mobile.

const UiSkin := preload("res://scripts/game/ui_skin.gd")
var key: TouchScreenButton
var visual: Button

func setup(rect: Rect2, title: String, ui_theme: Theme, down: Callable, up: Callable) -> void:
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual = Button.new()
	visual.theme = ui_theme
	visual.text = title
	visual.size = rect.size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.focus_mode = Control.FOCUS_NONE
	UiSkin.style_button(visual)
	add_child(visual)
	key = TouchScreenButton.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	key.shape = shape
	key.position = rect.size / 2
	key.visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	key.pressed.connect(func():
		visual.set_pressed_no_signal(true)
		down.call())
	key.released.connect(func():
		visual.set_pressed_no_signal(false)
		up.call())
	add_child(key)
