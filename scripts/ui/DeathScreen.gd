extends Control
## DeathScreen.gd - cause of death, stage reached, build summary, retry/menu.
## Shows the run seed (bible: "shows skeleton seed for future run").
## Listens: EventBus.run_ended to capture the summary before display.

var _summary_lbl: Label
var _retry_btn: Button
var _headline: Label
var _last_summary: Dictionary = {}

func _ready() -> void:
	add_child(UIKit.background(Color(0.05, 0.02, 0.02, 0.95)))
	var col := UIKit.center_column(12)
	add_child(col)
	_headline = UIKit.label("THE CAVE KEEPS YOU", 36, UIKit.DANGER)
	col.add_child(_headline)
	_summary_lbl = UIKit.subtitle("")
	_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_summary_lbl)
	col.add_child(_sp(20))

	_retry_btn = UIKit.button("Descend Again")
	_retry_btn.pressed.connect(func(): GameManager.open_class_select())
	col.add_child(_retry_btn)
	var menu := UIKit.button("Main Menu")
	menu.pressed.connect(func(): GameManager.return_to_menu())
	col.add_child(menu)

	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(victory: bool, summary: Dictionary) -> void:
	if victory:
		return
	_last_summary = summary
	# Cycle ending (Appendix G2): dying on the final stage restarts the loop —
	# next run's entrance holds your skeleton.
	if int(summary.get("stage_index", 0)) >= Database.stage_count() - 1:
		_headline.text = "THE DESCENT BEGINS AGAIN"
		SaveManager.profile["cycle_pending"] = true
		SaveManager.unlock("ending_cycle")
		SaveManager.save_profile()
	else:
		_headline.text = "THE CAVE KEEPS YOU"
	var stage := Database.get_stage(int(summary.get("stage_index", 0)))
	var cls := Database.get_class_data(String(summary.get("class_id", "swordsman")))
	var mins := int(summary.get("time", 0.0)) / 60
	_summary_lbl.text = "%s died in %s\nUpgrades taken: %d   ·   Time: %d min\nSeed: %d  (deaths total: %d)" % [
		cls["display_name"], stage["name"],
		summary.get("upgrades", []).size(), mins,
		int(summary.get("seed", 0)), int(SaveManager.profile["total_deaths"])]

func _sp(h: float) -> Control:
	var c := Control.new(); c.custom_minimum_size = Vector2(0, h); return c

func focus_default() -> void:
	_retry_btn.grab_focus()
