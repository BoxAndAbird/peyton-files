extends Control
## PauseScreen.gd - Resume / Settings / Quit to Menu (bible section 15).
## Shown as an overlay while get_tree().paused == true; this Control keeps
## processing because UIManager (its parent) is PROCESS_MODE_ALWAYS.

var _resume_btn: Button

func _ready() -> void:
	add_child(UIKit.background(Color(0.02, 0.03, 0.04, 0.78)))
	var col := UIKit.center_column(10)
	add_child(col)
	col.add_child(UIKit.label("PAUSED", 34, UIKit.ACCENT))
	col.add_child(_sp(16))

	_resume_btn = UIKit.button("Resume")
	_resume_btn.pressed.connect(func():
		visible = false
		GameManager.resume())
	col.add_child(_resume_btn)

	var inv := UIKit.button("Pack & Equipment")
	inv.pressed.connect(func():
		visible = false
		GameManager.open_inventory())
	col.add_child(inv)

	var settings := UIKit.button("Settings")
	settings.pressed.connect(func(): GameManager.open_settings())
	col.add_child(settings)

	var quit := UIKit.button("Quit to Menu")
	quit.pressed.connect(func():
		visible = false
		RunManager.save_continue()   # keep the continue snapshot on quit-out
		GameManager.return_to_menu())
	col.add_child(quit)

	col.add_child(_sp(10))
	col.add_child(UIKit.subtitle("The run is saved. The cave will remember where you were."))

func _sp(h: float) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c

func focus_default() -> void:
	_resume_btn.grab_focus()
