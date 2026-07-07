extends Node
## SettingsManager.gd  (Autoload singleton: "SettingsManager")
##
## Loads/saves user://settings.cfg and applies audio/video/accessibility/input
## options (bible section 16). Persists independently of the run save.
##
## Signals (via EventBus):
##   settings_applied(settings)  - after any apply; camera/UI read fov, sens...
##   brightness_changed(value)   - WorldEnvironment/postprocess reacts.
##
## Exported/queried values are read directly by other systems (e.g. the camera
## reads mouse_sensitivity and invert_y). Loads AFTER AudioManager so it can
## push volumes into the buses on startup.

const PATH := "user://settings.cfg"

const DEFAULTS := {
	# audio (0..100)
	"master_volume": 90.0, "music_volume": 70.0, "sfx_volume": 85.0, "ambient_volume": 80.0,
	# video
	"brightness": 1.0, "gamma": 1.0, "fov": 74.0,
	"resolution_index": -1,           # -1 = leave as-is / use window default
	"fullscreen_mode": 0,             # 0 windowed, 1 fullscreen, 2 borderless
	# controls
	"mouse_sensitivity": 1.0, "invert_y": false, "vibration": true,
	# accessibility
	"subtitles": true, "font_size": 1, "camera_shake": 100.0,
	"damage_numbers": true, "colorblind": 0,
}

const RESOLUTIONS := [
	Vector2i(1280, 720), Vector2i(1600, 900),
	Vector2i(1920, 1080), Vector2i(2560, 1440),
]

var _data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputActions.ensure_defaults()
	load_settings()
	# Defer the first apply so every autoload exists and a Camera can appear.
	call_deferred("apply_all")

# --- Access ----------------------------------------------------------
func get_value(key: String):
	return _data.get(key, DEFAULTS.get(key))

func set_value(key: String, value) -> void:
	_data[key] = value

# Typed convenience getters used by gameplay systems.
func mouse_sensitivity() -> float: return float(get_value("mouse_sensitivity"))
func invert_y() -> bool:           return bool(get_value("invert_y"))
func fov() -> float:               return float(get_value("fov"))
func brightness() -> float:        return float(get_value("brightness"))
func gamma() -> float:             return float(get_value("gamma"))
func camera_shake_scale() -> float:return float(get_value("camera_shake")) / 100.0
func subtitles_on() -> bool:       return bool(get_value("subtitles"))
func damage_numbers_on() -> bool:  return bool(get_value("damage_numbers"))
func vibration_on() -> bool:       return bool(get_value("vibration"))

# --- Persistence -----------------------------------------------------
func load_settings() -> void:
	_data = DEFAULTS.duplicate(true)
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in DEFAULTS.keys():
			if cfg.has_section_key("settings", key):
				_data[key] = cfg.get_value("settings", key)
		# Restore key rebinds.
		if cfg.has_section("input"):
			for action in cfg.get_section_keys("input"):
				var kc: int = int(cfg.get_value("input", action))
				var e := InputEventKey.new()
				e.physical_keycode = kc
				InputActions.rebind(action, e)

func save() -> void:
	var cfg := ConfigFile.new()
	for key in _data.keys():
		cfg.set_value("settings", key, _data[key])
	# Persist first key of each rebindable action as physical keycode.
	for action in InputActions.REBINDABLE:
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				cfg.set_value("input", action, e.physical_keycode)
				break
	cfg.save(PATH)

func reset_to_defaults() -> void:
	_data = DEFAULTS.duplicate(true)
	# Wipe and reinstate default binds.
	for action in InputActions.DEFAULTS.keys():
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
	InputActions.ensure_defaults()
	apply_all()
	save()

# --- Apply -----------------------------------------------------------
func apply_all() -> void:
	apply_audio()
	apply_video()
	EventBus.settings_applied.emit(_data.duplicate())
	EventBus.brightness_changed.emit(brightness())

func apply_audio() -> void:
	AudioManager.set_bus_volume01("Master", float(get_value("master_volume")))
	AudioManager.set_bus_volume01("Music", float(get_value("music_volume")))
	AudioManager.set_bus_volume01("SFX", float(get_value("sfx_volume")))
	AudioManager.set_bus_volume01("Ambient", float(get_value("ambient_volume")))
	# Master bus (index 0) also honours master_volume directly.
	var m := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(m, linear_to_db(clampf(float(get_value("master_volume")) / 100.0, 0.0001, 1.0)))

func apply_video() -> void:
	# Fullscreen mode.
	match int(get_value("fullscreen_mode")):
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Borderless flag for mode 2.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, int(get_value("fullscreen_mode")) == 2)
	# Resolution (only when windowed and a valid index chosen).
	var ridx := int(get_value("resolution_index"))
	if ridx >= 0 and ridx < RESOLUTIONS.size() and int(get_value("fullscreen_mode")) != 1:
		DisplayServer.window_set_size(RESOLUTIONS[ridx])
