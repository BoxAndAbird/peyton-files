extends Control
## SettingsScreen.gd - full settings matrix (bible section 16).
## Tabs: Audio / Video / Controls / Accessibility. Values bind live to
## SettingsManager and apply immediately (real-time brightness/volume preview).
## Persists on Back via SettingsManager.save().

var _awaiting_action := ""    # action id currently being rebound
var _rebind_buttons: Dictionary = {}

func _ready() -> void:
	# Dim the screen behind (settings is an overlay).
	var dim := UIKit.background(Color(0.02, 0.03, 0.04, 0.92))
	add_child(dim)

	var frame := UIKit.panel()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 60; frame.offset_right = -60
	frame.offset_top = 40; frame.offset_bottom = -40
	add_child(frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	frame.add_child(root)
	root.add_child(UIKit.label("SETTINGS", 28, UIKit.ACCENT))

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	tabs.add_child(_audio_tab())
	tabs.add_child(_video_tab())
	tabs.add_child(_controls_tab())
	tabs.add_child(_access_tab())

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)
	var reset := UIKit.button("Reset Defaults", 200)
	reset.pressed.connect(func(): SettingsManager.reset_to_defaults(); _rebuild())
	bar.add_child(reset)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	var back := UIKit.button("Back", 160)
	back.pressed.connect(_on_back)
	bar.add_child(back)

# --- Tab builders ----------------------------------------------------
func _audio_tab() -> Control:
	var v := _tab_body("Audio")
	v.add_child(_slider_row("Master Volume", "master_volume", 0, 100, 1))
	v.add_child(_slider_row("Music Volume", "music_volume", 0, 100, 1))
	v.add_child(_slider_row("SFX Volume", "sfx_volume", 0, 100, 1))
	v.add_child(_slider_row("Ambient Volume", "ambient_volume", 0, 100, 1))
	return v

func _video_tab() -> Control:
	var v := _tab_body("Video")
	v.add_child(_slider_row("Brightness", "brightness", 0.5, 1.5, 0.01))
	v.add_child(_slider_row("Gamma", "gamma", 0.8, 1.3, 0.01))
	v.add_child(_slider_row("Field of View", "fov", 60, 95, 1))
	v.add_child(UIKit.row("Display Mode", _option(
		["Windowed", "Fullscreen", "Borderless"], "fullscreen_mode")))
	var res_names: Array[String] = []
	for r in SettingsManager.RESOLUTIONS:
		res_names.append("%dx%d" % [r.x, r.y])
	v.add_child(UIKit.row("Resolution", _option(res_names, "resolution_index")))
	return v

func _controls_tab() -> Control:
	var v := _tab_body("Controls")
	v.add_child(_slider_row("Mouse Sensitivity", "mouse_sensitivity", 0.1, 3.0, 0.05))
	v.add_child(UIKit.row("Invert Y", _toggle("invert_y")))
	v.add_child(UIKit.row("Controller Vibration", _toggle("vibration")))
	v.add_child(UIKit.label("Key Bindings (click, then press a key):", 15, UIKit.MUTED))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	for action in InputActions.REBINDABLE:
		var b := UIKit.button(_rebind_label(action), 150)
		b.pressed.connect(_begin_rebind.bind(action))
		_rebind_buttons[action] = b
		grid.add_child(b)
	v.add_child(grid)
	return v

func _access_tab() -> Control:
	var v := _tab_body("Accessibility")
	v.add_child(UIKit.row("Subtitles", _toggle("subtitles")))
	v.add_child(UIKit.row("Font Size", _option(["Small", "Normal", "Large"], "font_size")))
	v.add_child(_slider_row("Camera Shake", "camera_shake", 0, 100, 1))
	v.add_child(UIKit.row("Damage Numbers", _toggle("damage_numbers")))
	v.add_child(UIKit.row("Colorblind Mode", _option(["Off", "Protan", "Deutan", "Tritan"], "colorblind")))
	return v

func _tab_body(title: String) -> VBoxContainer:
	# The tab is the VBox itself; its node name becomes the tab title.
	var v := VBoxContainer.new()
	v.name = title
	v.add_theme_constant_override("separation", 10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v

# --- Row helpers -----------------------------------------------------
func _slider_row(label: String, key: String, lo: float, hi: float, step: float) -> Control:
	var s := UIKit.hslider(lo, hi, step, float(SettingsManager.get_value(key)))
	var value_lbl := UIKit.label(_fmt(float(SettingsManager.get_value(key)), step), 14, UIKit.TEXT)
	value_lbl.custom_minimum_size = Vector2(60, 0)
	s.value_changed.connect(func(val):
		SettingsManager.set_value(key, val)
		value_lbl.text = _fmt(val, step)
		SettingsManager.apply_all())
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var name := UIKit.label(label, 15, UIKit.TEXT); name.custom_minimum_size = Vector2(200, 0)
	h.add_child(name); h.add_child(s); h.add_child(value_lbl)
	return h

func _fmt(v: float, step: float) -> String:
	return str(int(round(v))) if step >= 1.0 else "%.2f" % v

func _option(items: Array, key: String) -> OptionButton:
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_ALL
	for i in items.size():
		o.add_item(str(items[i]), i)
	var cur := int(SettingsManager.get_value(key))
	o.selected = clampi(cur, 0, items.size() - 1)
	o.item_selected.connect(func(idx):
		SettingsManager.set_value(key, idx)
		SettingsManager.apply_all())
	return o

func _toggle(key: String) -> CheckButton:
	var c := CheckButton.new()
	c.focus_mode = Control.FOCUS_ALL
	c.button_pressed = bool(SettingsManager.get_value(key))
	c.toggled.connect(func(on):
		SettingsManager.set_value(key, on)
		SettingsManager.apply_all())
	return c

# --- Rebinding -------------------------------------------------------
func _rebind_label(action: String) -> String:
	return action.replace("_", " ").capitalize() + ": " + InputActions.label_for(action)

func _begin_rebind(action: String) -> void:
	_awaiting_action = action
	_rebind_buttons[action].text = action.capitalize() + ": <press key>"

func _input(event: InputEvent) -> void:
	if _awaiting_action == "":
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var e := InputEventKey.new()
		e.physical_keycode = key.physical_keycode
		InputActions.rebind(_awaiting_action, e)
		_rebind_buttons[_awaiting_action].text = _rebind_label(_awaiting_action)
		_awaiting_action = ""
		AudioManager.play_ui("confirm")
		accept_event()

# --- Lifecycle -------------------------------------------------------
func _on_back() -> void:
	SettingsManager.save()
	AudioManager.play_ui("cancel")
	GameManager.close_settings()

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	call_deferred("_ready")

func focus_default() -> void:
	pass
