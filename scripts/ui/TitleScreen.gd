extends Control
## TitleScreen.gd - logo, animated cave backdrop, "press any button".
## Signal: leads to GameManager.go_to_main_menu(). (bible section 15)

var _prompt: Label
var _t := 0.0
var _bg: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = UIKit.background(Color(0.03, 0.04, 0.055))
	add_child(_bg)

	var col := UIKit.center_column(18)
	add_child(col)
	col.add_child(UIKit.title("BELOW THE HOLLOW"))
	var tag := UIKit.subtitle("Descend. Adapt. Do not trust the map.")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)
	col.add_child(_spacer(40))
	_prompt = UIKit.label("- Press Any Button -", 20, UIKit.MUTED)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_prompt)

func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _process(delta: float) -> void:
	_t += delta
	# Gentle pulsing prompt + subtly breathing backdrop (readable, never black).
	_prompt.modulate.a = 0.4 + 0.5 * (0.5 + 0.5 * sin(_t * 2.2))
	var g := 0.035 + 0.01 * sin(_t * 0.6)
	_bg.color = Color(g * 0.8, g, g * 1.2)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var is_button := event is InputEventKey or event is InputEventMouseButton \
		or event is InputEventJoypadButton
	if is_button and event.is_pressed():
		AudioManager.play_ui("confirm")
		GameManager.go_to_main_menu()
		get_viewport().set_input_as_handled()

func focus_default() -> void:
	pass
