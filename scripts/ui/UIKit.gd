class_name UIKit
extends RefCounted
## UIKit.gd  (static UI factory + theme, NOT an autoload)
##
## Builds the shared PS2-horror look (bible sections 15 & 18): grainy dark
## panels, muted palette, high-contrast readable text. Every screen uses these
## factories so styling and controller/keyboard focus + UI sounds are wired in
## one place. Legibility is never sacrificed (design pillar: readable terror).

# --- Palette ---------------------------------------------------------
const BG      := Color(0.055, 0.065, 0.085)
const PANEL   := Color(0.09, 0.11, 0.14, 0.96)
const BORDER  := Color(0.18, 0.23, 0.30)
const TEXT    := Color(0.85, 0.88, 0.92)
const MUTED   := Color(0.55, 0.60, 0.67)
const ACCENT  := Color(0.91, 0.70, 0.29)   # lantern amber
const DANGER  := Color(0.80, 0.33, 0.31)
const SANITY  := Color(0.55, 0.45, 0.80)
const HEALTH  := Color(0.78, 0.28, 0.28)
const STAMINA := Color(0.30, 0.62, 0.45)

# --- Theme -----------------------------------------------------------
static func make_theme(base_font_size := 18) -> Theme:
	var t := Theme.new()
	t.default_font_size = base_font_size

	var panel := _sb(PANEL, BORDER, 2, 6)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)

	# Buttons: flat with accent hover/focus so focus is always visible.
	t.set_stylebox("normal", "Button", _sb(Color(0.12,0.14,0.18), BORDER, 1, 4))
	t.set_stylebox("hover", "Button", _sb(Color(0.17,0.20,0.26), ACCENT, 1, 4))
	t.set_stylebox("pressed", "Button", _sb(Color(0.20,0.16,0.10), ACCENT, 1, 4))
	t.set_stylebox("focus", "Button", _sb(Color(0.17,0.20,0.26,0.0), ACCENT, 2, 4))
	t.set_stylebox("disabled", "Button", _sb(Color(0.10,0.11,0.13), Color(0.15,0.17,0.2), 1, 4))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_constant("outline_size", "Button", 0)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "RichTextLabel", TEXT)
	return t

static func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

# --- Factories -------------------------------------------------------
static func button(text: String, min_w := 260.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 44)
	b.focus_mode = Control.FOCUS_ALL
	# UI sounds (safe: AudioManager is an autoload).
	b.mouse_entered.connect(func(): AudioManager.play_ui("hover"))
	b.focus_entered.connect(func(): AudioManager.play_ui("hover"))
	b.pressed.connect(func(): AudioManager.play_ui("confirm"))
	return b

static func label(text: String, size := 18, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func title(text: String) -> Label:
	var l := label(text, 46, ACCENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func subtitle(text: String) -> Label:
	var l := label(text, 16, MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func panel() -> PanelContainer:
	return PanelContainer.new()

## A vignette + solid background covering the whole screen (readable, not black).
static func background(tint := BG) -> ColorRect:
	var r := ColorRect.new()
	r.color = tint
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Centered vertical column used by most menus.
static func center_column(sep := 12) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", sep)
	return vb

static func hslider(min_v: float, max_v: float, step: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(220, 24)
	s.focus_mode = Control.FOCUS_ALL
	return s

## Label + control row (used by settings). Returns the HBox.
static func row(label_text: String, control: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := label(label_text, 16, TEXT)
	l.custom_minimum_size = Vector2(220, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(control)
	return h

## A simple stat/resource bar (ProgressBar with a tinted fill).
static func bar(color: Color, width := 220.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(width, 18)
	p.min_value = 0.0
	p.max_value = 100.0
	p.value = 100.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(3)
	bg.set_border_width_all(1)
	bg.border_color = BORDER
	p.add_theme_stylebox_override("fill", fill)
	p.add_theme_stylebox_override("background", bg)
	return p
