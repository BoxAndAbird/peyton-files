class_name UIManager
extends Control
## UIManager.gd
##
## Owns the screen stack and controller/keyboard focus (bible sections 15 & 21).
## Built in code by Main.gd and handed to GameManager. Every screen is a child
## Control kept in `_screens` by name; GameManager drives visibility through
## show_only / show_screen / hide_screen.
##
## Also renders the accessibility subtitle line (bible section 16) reacting to
## EventBus.subtitle_requested.

var _screens: Dictionary = {}      # name -> Control
var _subtitle: Label
var _sub_timer := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Font size accessibility (bible: Small/Normal/Large).
	var fs := int(SettingsManager.get_value("font_size"))
	var base := [15, 18, 22][clampi(fs, 0, 2)]
	theme = UIKit.make_theme(base)

	_build_screens()
	_build_subtitle()

	EventBus.subtitle_requested.connect(_on_subtitle)

func _build_screens() -> void:
	var defs := {
		"title":        "res://scripts/ui/TitleScreen.gd",
		"main_menu":    "res://scripts/ui/MainMenuScreen.gd",
		"class_select": "res://scripts/ui/ClassSelectScreen.gd",
		"settings":     "res://scripts/ui/SettingsScreen.gd",
		"hud":          "res://scripts/ui/HUDScreen.gd",
		"pause":        "res://scripts/ui/PauseScreen.gd",
		"inventory":    "res://scripts/ui/InventoryScreen.gd",
		"shop":         "res://scripts/ui/ShopScreen.gd",
		"upgrade":      "res://scripts/ui/UpgradeScreen.gd",
		"death":        "res://scripts/ui/DeathScreen.gd",
		"victory":      "res://scripts/ui/VictoryScreen.gd",
	}
	for name in defs.keys():
		var scr = load(defs[name])
		var node: Control = scr.new()
		node.name = name
		node.visible = false
		node.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(node)
		_screens[name] = node

func _build_subtitle() -> void:
	_subtitle = UIKit.label("", 18, UIKit.TEXT)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_subtitle.offset_top = -96
	_subtitle.offset_bottom = -56
	_subtitle.add_theme_color_override("font_outline_color", Color.BLACK)
	_subtitle.add_theme_constant_override("outline_size", 6)
	_subtitle.visible = false
	add_child(_subtitle)

# --- Screen control --------------------------------------------------
func show_only(name: String) -> void:
	for k in _screens.keys():
		_screens[k].visible = (k == name)
	_focus_first(name)

func show_screen(name: String) -> void:
	if _screens.has(name):
		_screens[name].visible = true
		_screens[name].move_to_front()
		_focus_first(name)

func hide_screen(name: String) -> void:
	if _screens.has(name):
		_screens[name].visible = false

func get_screen(name: String) -> Control:
	return _screens.get(name)

func get_hud() -> Control:
	return _screens.get("hud")

func _focus_first(name: String) -> void:
	# Give controller/keyboard a valid focus target on every screen change.
	var s: Control = _screens.get(name)
	if s and s.has_method("focus_default"):
		s.call_deferred("focus_default")

# --- Subtitles -------------------------------------------------------
func _on_subtitle(text: String, seconds: float) -> void:
	if not SettingsManager.subtitles_on():
		return
	_subtitle.text = text
	_subtitle.visible = true
	_sub_timer = seconds

func _process(delta: float) -> void:
	if _sub_timer > 0.0:
		_sub_timer -= delta
		if _sub_timer <= 0.0:
			_subtitle.visible = false
