extends Control
## InventoryScreen.gd - five equipment slots + backpack (bible section 15:
## "Five equipped slots, item details, stat comparison / equip, drop, inspect").
##
## Opened with Tab (action "inventory") via GameManager.State.INVENTORY; the
## tree pauses while open (accessibility default). All data lives in
## RunManager (equipped / backpack); this screen is a pure view that rebuilds
## on every change, so it can never drift from the real state.
##
## Layout:  [ EQUIPPED (5 slot rows) ]  [ BACKPACK (up to 10 rows) ]
## Each backpack row shows the item's stat and what it would replace.

var _equip_col: VBoxContainer
var _pack_col: VBoxContainer
var _pack_header: Label
var _close_btn: Button

func _ready() -> void:
	add_child(UIKit.background(Color(0.02, 0.03, 0.04, 0.88)))

	var frame := UIKit.panel()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 80; frame.offset_right = -80
	frame.offset_top = 50; frame.offset_bottom = -50
	add_child(frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	frame.add_child(root)
	root.add_child(UIKit.label("PACK & EQUIPMENT", 28, UIKit.ACCENT))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	# --- equipped column ------------------------------------------------
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UIKit.label("EQUIPPED", 18, UIKit.MUTED))
	_equip_col = VBoxContainer.new()
	_equip_col.add_theme_constant_override("separation", 6)
	left.add_child(_equip_col)

	# --- backpack column --------------------------------------------------
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	_pack_header = UIKit.label("BACKPACK", 18, UIKit.MUTED)
	right.add_child(_pack_header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_pack_col = VBoxContainer.new()
	_pack_col.add_theme_constant_override("separation", 6)
	_pack_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pack_col)

	_close_btn = UIKit.button("Close  [Tab]", 200)
	_close_btn.pressed.connect(func(): GameManager.close_inventory())
	root.add_child(_close_btn)

	EventBus.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed(_slots: Dictionary) -> void:
	if visible:
		refresh()

# --- view rebuild ------------------------------------------------------
func refresh() -> void:
	for c in _equip_col.get_children():
		c.queue_free()
	for c in _pack_col.get_children():
		c.queue_free()

	# Equipped slots (always all five, in fixed order).
	for slot in RunManager.SLOT_ORDER:
		_equip_col.add_child(_slot_row(slot))

	# Backpack rows.
	_pack_header.text = "BACKPACK  (%d / %d)" % [RunManager.backpack.size(), RunManager.BACKPACK_CAP]
	if RunManager.backpack.is_empty():
		_pack_col.add_child(UIKit.subtitle("Empty. The cave gives to those who look."))
	for iid in RunManager.backpack.duplicate():
		_pack_col.add_child(_pack_row(String(iid)))

func _slot_row(slot: String) -> PanelContainer:
	var row := UIKit.panel()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	row.add_child(h)

	var slot_lbl := UIKit.label(slot.capitalize(), 14, UIKit.MUTED)
	slot_lbl.custom_minimum_size = Vector2(110, 0)
	h.add_child(slot_lbl)

	var iid := String(RunManager.equipped.get(slot, ""))
	if iid == "":
		var empty := UIKit.label("—", 15, UIKit.MUTED)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(empty)
	else:
		var item := Database.get_item(iid)
		var name_lbl := UIKit.label(String(item.get("name", iid)), 15,
			Database.RARITY_COLORS.get(item.get("rarity", "common"), UIKit.TEXT))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(name_lbl)
		h.add_child(UIKit.label(_stat_text(item), 13, UIKit.ACCENT))
		var un := UIKit.button("Unequip", 110)
		un.disabled = RunManager.backpack.size() >= RunManager.BACKPACK_CAP
		un.pressed.connect(func():
			RunManager.unequip_slot(slot)
			refresh())
		h.add_child(un)
	return row

func _pack_row(iid: String) -> PanelContainer:
	var item := Database.get_item(iid)
	var row := UIKit.panel()
	var v := VBoxContainer.new()
	row.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)

	var name_lbl := UIKit.label(String(item.get("name", iid)), 15,
		Database.RARITY_COLORS.get(item.get("rarity", "common"), UIKit.TEXT))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_lbl)
	h.add_child(UIKit.label(_stat_text(item), 13, UIKit.ACCENT))

	var eq := UIKit.button("Equip", 90)
	eq.pressed.connect(func():
		RunManager.equip_item(iid)
		AudioManager.play("pickup")
		refresh())
	h.add_child(eq)
	var dr := UIKit.button("Drop", 80)
	dr.pressed.connect(func():
		RunManager.drop_item(iid)
		AudioManager.play_ui("cancel")
		refresh())
	h.add_child(dr)

	# Detail line: slot, flavor note, and what equipping would replace.
	var slot := String(item.get("slot", "?"))
	var detail := "%s · %s" % [slot.capitalize(), String(item.get("note", ""))]
	var cur := String(RunManager.equipped.get(slot, ""))
	if cur != "" and cur != iid:
		var cur_item := Database.get_item(cur)
		detail += "   (replaces %s: %s)" % [cur_item.get("name", cur), _stat_text(cur_item)]
	v.add_child(UIKit.subtitle(detail))
	return row

func _stat_text(item: Dictionary) -> String:
	if item.is_empty():
		return ""
	var stat := String(item.get("stat", ""))
	var stat_name: String = Database.STAT_DEFS.get(stat, {"name": stat}).get("name", stat)
	return "+%d %s" % [int(item.get("stat_value", 0)), stat_name]

func focus_default() -> void:
	refresh()
	_close_btn.grab_focus()
