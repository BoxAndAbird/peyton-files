extends Control
## ShopScreen.gd - helper NPC service window (bible section 15: NPC portrait,
## item list, prices, service buttons, dialogue above the list).
## Opened by GameManager.open_shop(helper); pure view over HelperBase.offers.

var _helper = null            # HelperBase (untyped: duck-typed offers/purchase)
var _name_lbl: Label
var _line_lbl: Label
var _essence_lbl: Label
var _rows_col: VBoxContainer
var _leave_btn: Button

func _ready() -> void:
	add_child(UIKit.background(Color(0.02, 0.03, 0.04, 0.88)))
	var frame := UIKit.panel()
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.custom_minimum_size = Vector2(640, 0)
	add_child(frame)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	frame.add_child(root)

	_name_lbl = UIKit.label("", 26, UIKit.ACCENT)
	root.add_child(_name_lbl)
	_line_lbl = UIKit.subtitle("")
	root.add_child(_line_lbl)
	_essence_lbl = UIKit.label("", 15, UIKit.ACCENT)
	root.add_child(_essence_lbl)

	_rows_col = VBoxContainer.new()
	_rows_col.add_theme_constant_override("separation", 6)
	root.add_child(_rows_col)

	_leave_btn = UIKit.button("Leave", 160)
	_leave_btn.pressed.connect(func(): GameManager.close_shop())
	root.add_child(_leave_btn)

## Called by GameManager when a helper is interacted with.
func open_for(helper) -> void:
	_helper = helper
	refresh()

func refresh() -> void:
	if _helper == null:
		return
	_name_lbl.text = String(_helper.info["name"])
	# Portrait tint: name takes the helper's color.
	_name_lbl.add_theme_color_override("font_color", _helper.info["color"])
	_line_lbl.text = String(_helper.info["line"])
	_essence_lbl.text = "Your essence: %d" % RunManager.essence
	for c in _rows_col.get_children():
		c.queue_free()
	for i in range(_helper.offers.size()):
		_rows_col.add_child(_offer_row(i))

func _offer_row(index: int) -> PanelContainer:
	var offer: Dictionary = _helper.offers[index]
	var row := UIKit.panel()
	var v := VBoxContainer.new()
	row.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)

	var sold: bool = offer.get("sold", false)
	var name_lbl := UIKit.label(String(offer["label"]), 16,
		UIKit.MUTED if sold else UIKit.TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_lbl)

	var price: int = _helper.price_of(index)
	var currency := String(offer.get("currency", "essence"))
	var price_text := "free" if price == 0 else "%d %s" % [price, currency]
	h.add_child(UIKit.label(price_text, 14,
		UIKit.SANITY if currency == "sanity" else UIKit.ACCENT))

	var buy := UIKit.button("Sold" if sold else "Take", 100)
	buy.disabled = sold
	buy.pressed.connect(func():
		if _helper.purchase(index):
			refresh()
		else:
			AudioManager.play_ui("denied"))
	h.add_child(buy)

	v.add_child(UIKit.subtitle(String(offer.get("desc", ""))))
	return row

func focus_default() -> void:
	refresh()
	_leave_btn.grab_focus()
