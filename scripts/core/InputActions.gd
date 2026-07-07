class_name InputActions
extends RefCounted
## InputActions.gd  (static helper, NOT an autoload)
##
## Registers the gameplay input map at runtime (see the note in project.godot
## for why we do this instead of hand-authoring InputEventKey blocks).
## SettingsManager calls ensure_defaults() at startup, then overlays any saved
## rebinds. Menus additionally use Godot's built-in ui_* actions.
##
## Each entry: action -> { keys:[physical keycodes], mouse:[button idx],
##                         pads:[joy button], axes:[[axis, dir]] }

const DEFAULTS := {
	"move_forward": {"keys": [KEY_W, KEY_UP], "axes": [[JOY_AXIS_LEFT_Y, -1]]},
	"move_back":    {"keys": [KEY_S, KEY_DOWN], "axes": [[JOY_AXIS_LEFT_Y, 1]]},
	"move_left":    {"keys": [KEY_A, KEY_LEFT], "axes": [[JOY_AXIS_LEFT_X, -1]]},
	"move_right":   {"keys": [KEY_D, KEY_RIGHT], "axes": [[JOY_AXIS_LEFT_X, 1]]},
	"attack":       {"keys": [], "mouse": [MOUSE_BUTTON_LEFT], "pads": [JOY_BUTTON_RIGHT_SHOULDER]},
	"aim":          {"keys": [], "mouse": [MOUSE_BUTTON_RIGHT], "axes": [[JOY_AXIS_TRIGGER_LEFT, 1]]},
	"sprint":       {"keys": [KEY_SHIFT], "pads": [JOY_BUTTON_LEFT_STICK]},
	"dodge":        {"keys": [KEY_SPACE], "pads": [JOY_BUTTON_B]},
	"interact":     {"keys": [KEY_E], "pads": [JOY_BUTTON_A]},
	"lantern":      {"keys": [KEY_Q], "pads": [JOY_BUTTON_LEFT_SHOULDER]},
	"inventory":    {"keys": [KEY_TAB], "pads": [JOY_BUTTON_BACK]},
	"pause":        {"keys": [KEY_ESCAPE], "pads": [JOY_BUTTON_START]},
	"debug_console":{"keys": [KEY_QUOTELEFT, KEY_F1], "pads": []},
	"lock_on":      {"keys": [KEY_F], "pads": [JOY_BUTTON_RIGHT_STICK]},
}

## The subset of actions the rebind UI is allowed to change (bible section 16).
const REBINDABLE := [
	"move_forward", "move_back", "move_left", "move_right",
	"attack", "aim", "sprint", "dodge", "interact", "lantern",
	"inventory", "lock_on",
]

## Create every action with its default events if it does not already exist.
static func ensure_defaults() -> void:
	for action in DEFAULTS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# Only populate if empty so a live rebind is not overwritten.
		if InputMap.action_get_events(action).is_empty():
			_apply_defaults_for(action)

static func _apply_defaults_for(action: String) -> void:
	var d: Dictionary = DEFAULTS[action]
	for kc in d.get("keys", []):
		var e := InputEventKey.new()
		e.physical_keycode = kc
		InputMap.action_add_event(action, e)
	for mb in d.get("mouse", []):
		var e := InputEventMouseButton.new()
		e.button_index = mb
		InputMap.action_add_event(action, e)
	for pb in d.get("pads", []):
		var e := InputEventJoypadButton.new()
		e.button_index = pb
		InputMap.action_add_event(action, e)
	for ax in d.get("axes", []):
		var e := InputEventJoypadMotion.new()
		e.axis = ax[0]
		e.axis_value = ax[1]
		InputMap.action_add_event(action, e)

## Replace all events on an action with a single key/mouse/pad event.
static func rebind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)

## Human-readable label for the first event bound to an action (for the UI).
static func label_for(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			return OS.get_keycode_string(e.physical_keycode)
		if e is InputEventMouseButton:
			return "Mouse %d" % e.button_index
		if e is InputEventJoypadButton:
			return "Pad %d" % e.button_index
	return "-"
