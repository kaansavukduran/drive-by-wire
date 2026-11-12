extends RefCounted
## Shared action names; keyboard, controller and touch use the same run actions.

const KEYS := {
	"drive_left": [KEY_LEFT, KEY_A], "drive_right": [KEY_RIGHT, KEY_D],
	"drive_up": [KEY_UP, KEY_W], "drive_down": [KEY_DOWN, KEY_S],
	"drive_fire": [KEY_SPACE, KEY_F], "drive_mine": [KEY_X],
	"drive_dodge": [KEY_SHIFT], "drive_comfort": [KEY_C],
	"drive_chat": [KEY_T], "drive_pause": [KEY_ESCAPE, KEY_P],
}
const PAD := {
	"drive_left": JOY_BUTTON_DPAD_LEFT, "drive_right": JOY_BUTTON_DPAD_RIGHT,
	"drive_up": JOY_BUTTON_DPAD_UP, "drive_down": JOY_BUTTON_DPAD_DOWN,
	"drive_fire": JOY_BUTTON_A, "drive_mine": JOY_BUTTON_X,
	"drive_dodge": JOY_BUTTON_B, "drive_comfort": JOY_BUTTON_Y,
	"drive_pause": JOY_BUTTON_START,
}

static func install() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for code in KEYS[action]:
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
		if PAD.has(action):
			var button := InputEventJoypadButton.new()
			button.button_index = PAD[action]
			InputMap.action_add_event(action, button)
