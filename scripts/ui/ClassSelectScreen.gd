extends Control
## ClassSelectScreen.gd - four class cards (bible section 4).
## Emits: GameManager.start_run(selected). Shows stats, weapon, passive.

var _selected := "swordsman"
var _cards: Dictionary = {}     # class_id -> PanelContainer
var _start_btn: Button

func _ready() -> void:
	add_child(UIKit.background())
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.offset_left = 40; root.offset_right = -40
	root.offset_top = 30; root.offset_bottom = -30
	add_child(root)

	root.add_child(UIKit.label("SELECT YOUR SURVIVOR", 32, UIKit.ACCENT))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	for cid in Database.CLASS_ORDER:
		var card := _make_card(cid)
		row.add_child(card)
		_cards[cid] = card

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	root.add_child(bar)
	var back := UIKit.button("Back", 160)
	back.pressed.connect(func(): GameManager.go_to_main_menu())
	bar.add_child(back)
	var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_start_btn = UIKit.button("Begin Descent", 220)
	_start_btn.pressed.connect(_on_start)
	bar.add_child(_start_btn)

	_select(_selected)

func _make_card(cid: String) -> PanelContainer:
	var data: Dictionary = Database.CLASSES[cid]
	var card := UIKit.panel()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var name := UIKit.label(data["display_name"], 24, data["color"])
	vb.add_child(name)
	vb.add_child(UIKit.label(data["role"], 14, UIKit.MUTED))
	# Weapon glyph (placeholder colored box).
	var wep := UIKit.label("Weapon: " + Database.get_weapon(data["weapon"])["name"], 14, UIKit.TEXT)
	vb.add_child(wep)
	var desc := UIKit.subtitle(data["description"])
	desc.custom_minimum_size = Vector2(0, 90)
	vb.add_child(desc)

	# Key stats.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	for stat in ["health", "strength", "speed", "defense", "crit", "range"]:
		grid.add_child(UIKit.label(Database.STAT_DEFS[stat]["name"], 13, UIKit.MUTED))
		grid.add_child(UIKit.label(str(data["base_stats"][stat]), 13, UIKit.TEXT))
	vb.add_child(grid)
	vb.add_child(UIKit.label("Passive:", 13, UIKit.ACCENT))
	vb.add_child(UIKit.subtitle(_passive_text(data["passive_id"])))

	var pick := UIKit.button("Choose", 0)
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pick.pressed.connect(func(): _select(cid))
	vb.add_child(pick)
	return card

func _passive_text(pid: String) -> String:
	match pid:
		"archer_haste_crit": return "Crits grant 2.5s haste; charged shots pierce."
		"tank_guarded": return "Standing still 0.75s: -25% incoming damage until you move."
		"sword_counter": return "Perfect dodge/parry empowers next strike, restores stamina."
		"bandit_backstab": return "Attacks from behind/stealth: bonus crit + essence."
	return ""

func _select(cid: String) -> void:
	_selected = cid
	AudioManager.play_ui("hover")
	for id in _cards.keys():
		var sb := UIKit._sb(UIKit.PANEL, (UIKit.ACCENT if id == cid else UIKit.BORDER), (3 if id == cid else 2), 6)
		_cards[id].add_theme_stylebox_override("panel", sb)

func _on_start() -> void:
	AudioManager.play_ui("confirm")
	GameManager.start_run(_selected)

func focus_default() -> void:
	_start_btn.grab_focus()
