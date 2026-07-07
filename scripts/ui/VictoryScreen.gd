extends Control
## VictoryScreen.gd - ending text, time, stats, back to menu (bible section 15).
## Saves the completion flag via SaveManager (done in RunManager.end_run).

var _summary_lbl: Label
var _menu_btn: Button
var _headline: Label
var _flavor: Label

func _ready() -> void:
	add_child(UIKit.background(Color(0.03, 0.05, 0.04, 0.95)))
	var col := UIKit.center_column(12)
	add_child(col)
	_headline = UIKit.label("YOU SAW THE SKY AGAIN", 34, UIKit.ACCENT)
	col.add_child(_headline)
	_flavor = UIKit.subtitle("Or something wearing the sky. It is hard to say, now.")
	col.add_child(_flavor)
	_summary_lbl = UIKit.subtitle("")
	_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_summary_lbl)
	col.add_child(_sp(20))

	_menu_btn = UIKit.button("Main Menu")
	_menu_btn.pressed.connect(func(): GameManager.return_to_menu())
	col.add_child(_menu_btn)
	var again := UIKit.button("New Descent")
	again.pressed.connect(func(): GameManager.open_class_select())
	col.add_child(again)

	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool, summary: Dictionary) -> void:
	if not victory:
		return
	# Ending text depends on the final-boss choice (bible: Choice Ending).
	match String(summary.get("ending", "")):
		"shatter":
			_headline.text = "THE HEART LIES SHATTERED"
			_headline.add_theme_color_override("font_color", UIKit.ACCENT)
			_flavor.text = "The cave is quiet. You climb toward a light that, this time, does not move away."
		"hollow":
			_headline.text = "THE HOLLOW WEARS YOUR NAME"
			_headline.add_theme_color_override("font_color", UIKit.SANITY)
			_flavor.text = "You are vast now. Somewhere far above, someone new picks up a lantern."
		_:
			_headline.text = "YOU SAW THE SKY AGAIN"
			_flavor.text = "Or something wearing the sky. It is hard to say, now."
	var cls := Database.get_class_data(String(summary.get("class_id", "swordsman")))
	var t := float(summary.get("time", 0.0))
	_summary_lbl.text = "%s escaped in %d:%02d\nUpgrades: %d   ·   Seed: %d\nVictories: %d   Best time: %d:%02d" % [
		cls["display_name"], int(t) / 60, int(t) % 60,
		summary.get("upgrades", []).size(), int(summary.get("seed", 0)),
		int(SaveManager.profile["total_victories"]),
		int(float(SaveManager.profile["best_time"])) / 60,
		int(float(SaveManager.profile["best_time"])) % 60]

func _sp(h: float) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c

func focus_default() -> void:
	_menu_btn.grab_focus()
