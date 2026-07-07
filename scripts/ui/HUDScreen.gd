extends Control
## HUDScreen.gd - in-game HUD (bible section 15).
## Health / sanity / stamina bars, essence counter, stage + objective line,
## interaction prompt, and floating damage numbers (toggleable in settings).
##
## Listens (EventBus): player_health_changed, player_stamina_changed,
## sanity_changed, essence_gained, stage_loaded, damage_dealt,
## player_spawned. Never references the Player class directly.

var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _sanity_bar: ProgressBar
var _essence_lbl: Label
var _objective_lbl: Label
var _stage_lbl: Label
var _prompt_lbl: Label
var _dmg_layer: Control     # floating damage numbers live here

# Boss bar (top center; bible: boss health bar signals via BossBase).
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar

# fake_ui sanity event: the HUD briefly lies about health (visual only).
var _lying := false
var _real_health := Vector2(100, 100)   # x=cur y=max

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- bottom-left resource cluster ---------------------------------
	var cluster := VBoxContainer.new()
	cluster.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cluster.offset_left = 24
	cluster.offset_top = -140
	cluster.offset_bottom = -24
	cluster.add_theme_constant_override("separation", 6)
	add_child(cluster)

	_health_bar = UIKit.bar(UIKit.HEALTH, 260)
	cluster.add_child(_label_over("HEALTH"))
	cluster.add_child(_health_bar)
	_stamina_bar = UIKit.bar(UIKit.STAMINA, 200)
	cluster.add_child(_stamina_bar)
	_sanity_bar = UIKit.bar(UIKit.SANITY, 230)
	cluster.add_child(_label_over("SANITY"))
	cluster.add_child(_sanity_bar)

	# --- top-left stage / objective ------------------------------------
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top.offset_left = 24
	top.offset_top = 18
	add_child(top)
	_stage_lbl = UIKit.label("", 20, UIKit.ACCENT)
	top.add_child(_stage_lbl)
	_objective_lbl = UIKit.label("", 15, UIKit.MUTED)
	top.add_child(_objective_lbl)

	# --- top-right essence ---------------------------------------------
	_essence_lbl = UIKit.label("Essence: 0", 18, UIKit.ACCENT)
	_essence_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_essence_lbl.offset_left = -220
	_essence_lbl.offset_top = 18
	add_child(_essence_lbl)

	# --- center interaction prompt -------------------------------------
	_prompt_lbl = UIKit.label("", 18, UIKit.TEXT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_lbl.offset_top = -170
	_prompt_lbl.offset_left = -200
	_prompt_lbl.offset_right = 200
	_prompt_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_lbl.add_theme_constant_override("outline_size", 6)
	add_child(_prompt_lbl)

	# --- damage number layer -------------------------------------------
	_dmg_layer = Control.new()
	_dmg_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dmg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dmg_layer)

	# --- boss bar (top center, hidden until a boss activates) -----------
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_top = 18
	_boss_box.offset_left = -260
	_boss_box.offset_right = 260
	_boss_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_boss_box.visible = false
	add_child(_boss_box)
	_boss_name = UIKit.label("", 22, UIKit.DANGER)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_boss_name.add_theme_constant_override("outline_size", 6)
	_boss_box.add_child(_boss_name)
	_boss_bar = UIKit.bar(UIKit.DANGER, 520)
	_boss_box.add_child(_boss_bar)

	# --- signals ---------------------------------------------------------
	EventBus.player_health_changed.connect(_on_health)
	EventBus.player_stamina_changed.connect(_on_stamina)
	EventBus.sanity_changed.connect(_on_sanity)
	EventBus.essence_gained.connect(_on_essence)
	EventBus.stage_loaded.connect(_on_stage)
	EventBus.damage_dealt.connect(_on_damage)
	EventBus.boss_started.connect(_on_boss_started)
	EventBus.boss_health_changed.connect(_on_boss_health)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.sanity_event_started.connect(_on_sanity_event)

func _label_over(text: String) -> Label:
	return UIKit.label(text, 11, UIKit.MUTED)

# --- signal handlers ---------------------------------------------------
func _on_health(cur: float, mx: float) -> void:
	_real_health = Vector2(cur, mx)
	if _lying:
		return   # fake_ui event owns the bar right now; real value restored after
	_health_bar.max_value = mx
	_health_bar.value = cur

func _on_stamina(cur: float, mx: float) -> void:
	_stamina_bar.max_value = mx
	_stamina_bar.value = cur

func _on_sanity(cur: float, mx: float) -> void:
	_sanity_bar.max_value = mx
	_sanity_bar.value = cur

func _on_essence(_amount: int) -> void:
	_essence_lbl.text = "Essence: %d" % RunManager.essence

func _on_stage(index: int, _id: String) -> void:
	var data := Database.get_stage(index)
	_stage_lbl.text = "%d. %s" % [index + 1, data["name"]]
	set_objective("Find the exit gate. Survive.")
	_essence_lbl.text = "Essence: %d" % RunManager.essence

## Public: stages/events update the objective line through this.
func set_objective(text: String) -> void:
	_objective_lbl.text = text

## Public: PlayerController shows/hides the interaction prompt.
func set_prompt(text: String) -> void:
	_prompt_lbl.text = text

# --- boss bar ------------------------------------------------------------
func _on_boss_started(boss_id: String) -> void:
	var data: Dictionary = Database.BOSSES.get(boss_id, {})
	_boss_name.text = String(data.get("name", "???"))
	_boss_bar.max_value = float(data.get("hp", 100.0))
	_boss_bar.value = _boss_bar.max_value
	_boss_box.visible = true
	set_objective("Survive: " + _boss_name.text)

func _on_boss_health(cur: float, mx: float) -> void:
	_boss_bar.max_value = mx
	_boss_bar.value = cur

func _on_boss_defeated(_boss_id: String) -> void:
	_boss_box.visible = false

# --- fake_ui sanity event: the health bar lies for ~1.2s (visual only) ----
func _on_sanity_event(event_id: String) -> void:
	if event_id != "fake_ui" or _lying:
		return
	_lying = true
	var fake := randf_range(0.05, 0.95) * _real_health.y
	var tw := create_tween()
	tw.tween_property(_health_bar, "value", fake, 0.15)
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		_lying = false
		_health_bar.max_value = _real_health.y
		_health_bar.value = _real_health.x)

func _on_damage(_source: Node, target: Node, amount: float, is_crit: bool) -> void:
	if not SettingsManager.damage_numbers_on():
		return
	if not (target is Node3D):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var world_pos: Vector3 = (target as Node3D).global_position + Vector3.UP * 1.6
	if cam.is_position_behind(world_pos):
		return
	var screen := cam.unproject_position(world_pos)
	var lbl := UIKit.label(str(int(round(amount))), 22 if is_crit else 16,
		UIKit.ACCENT if is_crit else UIKit.TEXT)
	lbl.position = screen + Vector2(randf_range(-14, 14), -8)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	_dmg_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 42.0, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tw.tween_callback(lbl.queue_free)

func focus_default() -> void:
	pass
