extends Control
## UpgradeScreen.gd - two mutually exclusive choice cards (bible sections 3+12).
## Exactly ONE choice is accepted per offer; RunManager caps the run at ten.
## Each stage intermission calls offer() twice back-to-back (2 picks/stage).
##
## Flow: GameManager.complete_stage() -> state UPGRADE -> offer()
##       pick -> RunManager.add_upgrade -> second offer() or continue to
##       GameManager._after_upgrade_continue().

var _cards_row: HBoxContainer
var _header: Label
var _remaining_lbl: Label
var _offers_this_intermission := 0
var _current_options: Array = []

func _ready() -> void:
	add_child(UIKit.background(Color(0.03, 0.03, 0.05, 0.9)))
	var col := UIKit.center_column(14)
	add_child(col)
	_header = UIKit.label("THE CAVE OFFERS", 30, UIKit.ACCENT)
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_header)
	_remaining_lbl = UIKit.subtitle("")
	_remaining_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_remaining_lbl)

	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 24)
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_cards_row)

## Called by GameManager when the intermission starts (and again after the
## first pick). Rolls two distinct options from the pool, luck-weighted.
func offer() -> void:
	_offers_this_intermission = 0
	_roll_and_show()

func _roll_and_show() -> void:
	# Clear previous cards.
	for c in _cards_row.get_children():
		c.queue_free()

	if not RunManager.can_offer_upgrade():
		_finish_intermission()
		return

	_remaining_lbl.text = "Choices remaining this run: %d" % RunManager.upgrades_remaining()

	# Roll two distinct upgrades not already owned.
	var pool: Array = []
	for up in Database.UPGRADES:
		if not RunManager.upgrades.has(up["id"]):
			pool.append(up)
	if pool.size() < 2:
		_finish_intermission()
		return
	var rng := RunManager.stage_rng()
	# Advance rng by pick count so the second offer differs deterministically
	# while remaining reproducible from the run seed.
	for i in range(RunManager.upgrades.size() * 3 + _offers_this_intermission * 7):
		rng.randi()
	var a: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var b: Dictionary = a
	while b["id"] == a["id"]:
		b = pool[rng.randi_range(0, pool.size() - 1)]
	_current_options = [a, b]
	EventBus.upgrade_offered.emit(_current_options)

	for opt in _current_options:
		_cards_row.add_child(_make_card(opt))
	call_deferred("focus_default")

func _make_card(up: Dictionary) -> PanelContainer:
	var card := UIKit.panel()
	card.custom_minimum_size = Vector2(320, 300)
	var rarity: String = up.get("rarity", "common")
	var rcolor: Color = Database.RARITY_COLORS.get(rarity, UIKit.TEXT)
	card.add_theme_stylebox_override("panel", UIKit._sb(UIKit.PANEL, rcolor, 2, 8))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	vb.add_child(UIKit.label(up["name"], 22, rcolor))
	vb.add_child(UIKit.label(rarity.capitalize() + "  ·  " + String(up["cat"]).capitalize(), 13, UIKit.MUTED))
	var desc := UIKit.subtitle(up["desc"])
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(desc)

	# Stat preview.
	var mods: Dictionary = up.get("mods", {})
	if not mods.is_empty():
		var preview := ""
		for stat in mods.keys():
			var v: float = mods[stat]
			preview += "%s %s%s   " % [Database.STAT_DEFS.get(stat, {"name": stat})["name"],
				"+" if v >= 0 else "", str(v)]
		vb.add_child(UIKit.label(preview, 14, UIKit.ACCENT))

	var take := UIKit.button("Take", 0)
	take.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	take.pressed.connect(_on_pick.bind(up["id"]))
	vb.add_child(take)
	return card

func _on_pick(upgrade_id: String) -> void:
	RunManager.add_upgrade(upgrade_id)
	# Let the player stats recalc immediately.
	if GameManager.player and GameManager.player.has_method("recalculate_stats"):
		GameManager.player.recalculate_stats()
	_offers_this_intermission += 1
	if _offers_this_intermission < RunManager.UPGRADES_PER_STAGE and RunManager.can_offer_upgrade():
		_roll_and_show()
	else:
		_finish_intermission()

func _finish_intermission() -> void:
	visible = false
	GameManager._after_upgrade_continue()

func focus_default() -> void:
	# Focus the first "Take" button for controller users.
	for card in _cards_row.get_children():
		for child in card.get_children():
			if child is VBoxContainer:
				for w in child.get_children():
					var b := w as Button
					if b:
						b.grab_focus()
						return
