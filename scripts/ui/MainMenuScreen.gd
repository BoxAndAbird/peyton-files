extends Control
## MainMenuScreen.gd - New Run / Continue / Settings / Credits / Quit.
## Continue is disabled without a run save (bible QA: "Continue disabled
## without save"). Quit asks for confirmation.

var _new_btn: Button
var _continue_btn: Button
var _credits_panel: PanelContainer
var _confirm_panel: PanelContainer

func _ready() -> void:
	add_child(UIKit.background())
	var col := UIKit.center_column(10)
	add_child(col)
	col.add_child(UIKit.title("BELOW THE HOLLOW"))
	col.add_child(_sp(24))

	_new_btn = UIKit.button("New Run")
	_new_btn.pressed.connect(func(): GameManager.open_class_select())
	col.add_child(_new_btn)

	_continue_btn = UIKit.button("Continue")
	_continue_btn.pressed.connect(func(): GameManager.continue_run())
	col.add_child(_continue_btn)

	var settings_btn := UIKit.button("Settings")
	settings_btn.pressed.connect(func(): GameManager.open_settings())
	col.add_child(settings_btn)

	var credits_btn := UIKit.button("Credits")
	credits_btn.pressed.connect(func(): _credits_panel.visible = true)
	col.add_child(credits_btn)

	var quit_btn := UIKit.button("Quit")
	quit_btn.pressed.connect(func(): _confirm_panel.visible = true)
	col.add_child(quit_btn)

	_build_credits()
	_build_confirm()

func _build_credits() -> void:
	_credits_panel = UIKit.panel()
	_credits_panel.set_anchors_preset(Control.PRESET_CENTER)
	_credits_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_credits_panel.add_child(vb)
	vb.add_child(UIKit.label("CREDITS", 26, UIKit.ACCENT))
	vb.add_child(UIKit.subtitle("Below the Hollow — vertical slice build.\nDesign: Developer Bible V3.\nEngine: Godot 4. Code-generated project scaffold."))
	var close := UIKit.button("Back", 160)
	close.pressed.connect(func(): _credits_panel.visible = false)
	vb.add_child(close)
	add_child(_credits_panel)

func _build_confirm() -> void:
	_confirm_panel = UIKit.panel()
	_confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	_confirm_panel.visible = false
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_confirm_panel.add_child(vb)
	vb.add_child(UIKit.label("Quit to desktop?", 22))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var yes := UIKit.button("Quit", 140)
	yes.pressed.connect(func(): get_tree().quit())
	var no := UIKit.button("Cancel", 140)
	no.pressed.connect(func(): _confirm_panel.visible = false)
	h.add_child(yes)
	h.add_child(no)
	vb.add_child(h)
	add_child(_confirm_panel)

func _sp(h: float) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c

func focus_default() -> void:
	# Refresh continue availability each time the menu appears.
	_continue_btn.disabled = not SaveManager.has_continue()
	_new_btn.grab_focus()
