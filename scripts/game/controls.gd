extends RefCounted
## Godot InputMap stays the source of truth for every gameplay input.

const KEYS := {
 "drive_left": [KEY_LEFT, KEY_A], "drive_right": [KEY_RIGHT, KEY_D],
 "drive_up": [KEY_UP, KEY_W], "drive_down": [KEY_DOWN, KEY_S],
 "drive_fire": [KEY_SPACE, KEY_F], "drive_mine": [KEY_X],
 "drive_dodge": [KEY_R], "drive_comfort": [KEY_SHIFT, KEY_C],
 "drive_boost": [KEY_E], "drive_brake": [KEY_Q],
 "drive_chat": [KEY_T], "drive_pause": [KEY_ESCAPE, KEY_P],
}
const PAD := {
 "drive_left": [JOY_BUTTON_DPAD_LEFT], "drive_right": [JOY_BUTTON_DPAD_RIGHT],
 "drive_up": [JOY_BUTTON_DPAD_UP], "drive_down": [JOY_BUTTON_DPAD_DOWN],
 "drive_fire": [JOY_BUTTON_A], "drive_mine": [JOY_BUTTON_X],
 "drive_dodge": [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER], "drive_comfort": [JOY_BUTTON_Y],
 "drive_boost": [JOY_BUTTON_RIGHT_SHOULDER], "drive_brake": [],
 "drive_pause": [JOY_BUTTON_START],
}
const LABELS := {"drive_left":"Sola sür", "drive_right":"Sağa sür", "drive_up":"İleri sür", "drive_down":"Geri sür", "drive_boost":"Turbo", "drive_brake":"Fren", "drive_fire":"Ateş", "drive_mine":"Mayın", "drive_dodge":"Sıyrılma", "drive_comfort":"Alan darbesi"}
const PAD_NAMES := {JOY_BUTTON_A:"A", JOY_BUTTON_B:"B", JOY_BUTTON_X:"X", JOY_BUTTON_Y:"Y", JOY_BUTTON_LEFT_SHOULDER:"LB", JOY_BUTTON_RIGHT_SHOULDER:"RB", JOY_BUTTON_DPAD_LEFT:"D-pad sol", JOY_BUTTON_DPAD_RIGHT:"D-pad sağ", JOY_BUTTON_DPAD_UP:"D-pad yukarı", JOY_BUTTON_DPAD_DOWN:"D-pad aşağı"}
static var last_device := "keyboard"
static var bindings: Dictionary = {}
static var pad_bindings: Dictionary = {}
static var revision := 0
static var deadzone := 0.35

static func install(keys: Dictionary = {}, buttons: Dictionary = {}, zone := 0.35) -> void:
 bindings = keys.duplicate()
 pad_bindings = buttons.duplicate()
 deadzone = clampf(zone, 0.2, 0.6)
 revision += 1
 for action in KEYS:
  if not InputMap.has_action(action): InputMap.add_action(action, deadzone)
  InputMap.action_erase_events(action)
  InputMap.action_set_deadzone(action, deadzone)
  var codes: Array = [int(bindings[action])] if bindings.has(action) else KEYS[action]
  for code in codes:
   var key := InputEventKey.new()
   key.physical_keycode = code
   InputMap.action_add_event(action, key)
  var pads: Array = [int(pad_bindings[action])] if pad_bindings.has(action) else PAD.get(action, [])
  for code in pads:
   var button := InputEventJoypadButton.new()
   button.button_index = code
   InputMap.action_add_event(action, button)
 _axis("drive_left", JOY_AXIS_LEFT_X, -1)
 _axis("drive_right", JOY_AXIS_LEFT_X, 1)
 _axis("drive_up", JOY_AXIS_LEFT_Y, -1)
 _axis("drive_down", JOY_AXIS_LEFT_Y, 1)
 _axis("drive_fire", JOY_AXIS_TRIGGER_RIGHT, 1)
 _axis("drive_brake", JOY_AXIS_TRIGGER_LEFT, 1)
 # Menu mappings must be explicit: built-in defaults vary by platform.
 const MENU := {"ui_accept":JOY_BUTTON_A,"ui_cancel":JOY_BUTTON_B,"ui_left":JOY_BUTTON_DPAD_LEFT,"ui_right":JOY_BUTTON_DPAD_RIGHT,"ui_up":JOY_BUTTON_DPAD_UP,"ui_down":JOY_BUTTON_DPAD_DOWN}
 for action in MENU:
  var menu_button := InputEventJoypadButton.new()
  menu_button.button_index = MENU[action]
  if not InputMap.action_has_event(action,menu_button): InputMap.action_add_event(action,menu_button)
 for spec in [["ui_left",JOY_AXIS_LEFT_X,-1.0],["ui_right",JOY_AXIS_LEFT_X,1.0],["ui_up",JOY_AXIS_LEFT_Y,-1.0],["ui_down",JOY_AXIS_LEFT_Y,1.0]]:
  var menu_axis := InputEventJoypadMotion.new()
  menu_axis.axis = spec[1]
  menu_axis.axis_value = spec[2]
  if not InputMap.action_has_event(spec[0],menu_axis): InputMap.action_add_event(spec[0],menu_axis)
 for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
  InputMap.action_set_deadzone(action, deadzone)

static func _axis(action: String, axis: int, value: float) -> void:
 var event := InputEventJoypadMotion.new()
 event.axis = axis
 event.axis_value = value
 InputMap.action_add_event(action, event)

static func observe(event: InputEvent) -> void:
 if event is InputEventJoypadButton and event.pressed:
  last_device = "pad"
 elif event is InputEventJoypadMotion and absf(event.axis_value) > deadzone:
  last_device = "pad"
 elif event is InputEventScreenTouch and event.pressed:
  last_device = "touch"
 elif event is InputEventKey and event.pressed:
  last_device = "keyboard"
 elif event is InputEventMouseButton and event.pressed and not event.device == -1:
  last_device = "keyboard"

static func binding_error(action: String, code: int, is_pad: bool, overrides: Dictionary) -> String:
 if not LABELS.has(action): return "Bu eylem değiştirilemez."
 if is_pad:
  if code < 0 or code > JOY_BUTTON_DPAD_RIGHT or code in [JOY_BUTTON_B, JOY_BUTTON_BACK, JOY_BUTTON_START, JOY_BUTTON_GUIDE]:
   return "B / Back / Start geri ve mola için ayrılmıştır."
 elif code <= 0 or code >= (1 << 25) or code in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_T, KEY_P, KEY_CTRL, KEY_ALT, KEY_META]:
  return "Bu tuş menü, sohbet veya sistem için ayrılmıştır."
 var defaults: Dictionary = PAD if is_pad else KEYS
 for other in LABELS:
  if other == action: continue
  var used: Array = [int(overrides[other])] if overrides.has(other) else defaults.get(other, [])
  if code in used: return "Bu giriş zaten %s için kullanılıyor." % LABELS[other]
 return ""

static func binding_name(action: String, is_pad := false) -> String:
 if is_pad:
  var defaults: Array=PAD.get(action, [])
  var code := int(pad_bindings.get(action, defaults[0] if not defaults.is_empty() else -1))
  if code==-1: return "LT"
  return str(PAD_NAMES.get(code, "Tuş %d" % code))
 var code := int(bindings.get(action, KEYS[action][0]))
 return str({KEY_LEFT:"←",KEY_RIGHT:"→",KEY_UP:"↑",KEY_DOWN:"↓"}.get(code,OS.get_keycode_string(code)))

static func run_hint() -> String:
 if last_device == "pad":
  return "Sol çubuk / D-pad · Sür\nRT/A Ateş · X Mayın\nY Darbe · B/LB Sıyrıl\nRB Turbo · LT Fren\nStart Mola"
 return "%s/%s · %s/%s Sürüş\n%s Turbo · %s Fren\nFare sol / %s Ateş\nFare sağ / %s Mayın\n%s Darbe · %s Sıyrıl" % [binding_name("drive_left"),binding_name("drive_right"),binding_name("drive_up"),binding_name("drive_down"),binding_name("drive_boost"),binding_name("drive_brake"),binding_name("drive_fire"),binding_name("drive_mine"),binding_name("drive_comfort"),binding_name("drive_dodge")]
