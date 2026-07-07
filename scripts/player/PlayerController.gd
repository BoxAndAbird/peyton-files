extends CharacterBody3D
## PlayerController.gd - the player (bible sections 4-6, 21).
## Fully code-built CharacterBody3D:
##   CollisionShape (capsule) + placeholder low-poly body tinted by class
##   PlayerCamera rig (yaw/pitch/springarm/camera)
##   Lantern: OmniLight3D 8-12m always on + SpotLight3D 16m focus (Q)
##   StatsComponent + PlayerCombat children
##
## Movement: camera-relative WASD/left stick, sprint (stamina drain), dodge
## roll with i-frames starting 0.08s after input (bible section 6), gravity.
##
## Emits (EventBus): player_health_changed, player_stamina_changed,
## player_moved_loud (sound stealth), player_died, player_interacted.
## Reads: SettingsManager (sensitivity/invert), RunManager (carry health).
##
## Debug: `god` console command flips `godmode`.

const BASE_MOVE_SPEED := 4.6
const SPRINT_MULT := 1.5
const GRAVITY := 18.0
const DODGE_SPEED := 9.5
const DODGE_TIME := 0.42
const DODGE_IFRAME_START := 0.08
const DODGE_IFRAME_END := 0.34
const DODGE_COST := 25.0
const SPRINT_COST_PER_S := 12.0
const STAMINA_REGEN := 22.0

var stats: StatsComponent
var combat: PlayerCombat
var cam: PlayerCamera

var health := 100.0
var stamina := 100.0
var godmode := false

var _dodge_timer := -1.0        # >= 0 while dodging
var _dodge_dir := Vector3.ZERO
var _slow_mult := 1.0           # movement debuff (spider webs, water)
var _slow_timer := 0.0
var _still_time := 0.0          # tank passive accumulator
var _guarded := false
var _footstep_accum := 0.0
var _interact_target = null     # Interactable (untyped: duck-typed prompt_text/interact)
var _body_mesh: MeshInstance3D
var _focus_light: SpotLight3D
var _omni_light: OmniLight3D

func _ready() -> void:
	collision_layer = 0b10       # layer 2: player
	collision_mask = 0b1         # collides with world
	add_to_group("player")

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)

## Called by GameManager right after spawn.
func setup(class_id: String) -> void:
	stats = StatsComponent.new()
	stats.name = "Stats"
	add_child(stats)
	stats.setup(class_id)

	combat = PlayerCombat.new()
	combat.name = "Combat"
	add_child(combat)
	combat.setup(self, stats)

	cam = PlayerCamera.new()
	cam.name = "CameraRig"
	cam.position = Vector3(0, 1.55, 0)
	add_child(cam)

	_build_body(class_id)
	_build_lantern()

	# Carry-over health between stages; -1 means fresh/full.
	health = stats.max_health() if RunManager.carry_health < 0.0 else minf(RunManager.carry_health, stats.max_health())
	stamina = stats.max_stamina()
	_emit_bars()

func recalculate_stats() -> void:
	if stats:
		stats.recalculate()
		health = minf(health, stats.max_health())
		_emit_bars()

# =====================================================================
#  PLACEHOLDER BODY + LANTERN (all in-engine, no external art)
# =====================================================================
func _build_body(class_id: String) -> void:
	var color: Color = Database.get_class_data(class_id)["color"]
	_body_mesh = MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.36
	cap.height = 1.6
	_body_mesh.mesh = cap
	_body_mesh.position = Vector3(0, 0.95, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	_body_mesh.material_override = mat
	add_child(_body_mesh)
	# Simple "head" so facing reads at PS2 fidelity.
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.34)
	head.mesh = box
	head.position = Vector3(0, 1.85, -0.05)
	head.material_override = mat
	add_child(head)

func _build_lantern() -> void:
	# Always-on readable glow (bible: 8-12m normal).
	_omni_light = OmniLight3D.new()
	_omni_light.omni_range = 10.0
	_omni_light.light_energy = 1.6
	_omni_light.light_color = Color(1.0, 0.85, 0.6)
	_omni_light.position = Vector3(0.3, 1.4, 0.1)
	_omni_light.shadow_enabled = true   # the ONE shadowed player light
	add_child(_omni_light)
	# Focus cone (bible: 16m focused), toggled with the lantern action.
	_focus_light = SpotLight3D.new()
	_focus_light.spot_range = 16.0
	_focus_light.spot_angle = 24.0
	_focus_light.light_energy = 0.0
	_focus_light.light_color = Color(1.0, 0.9, 0.7)
	_focus_light.position = Vector3(0, 1.5, 0)
	add_child(_focus_light)

# =====================================================================
#  INPUT
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if cam == null or combat == null:
		return   # setup() not called yet
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam.apply_look((event as InputEventMouseMotion).relative)
	elif event.is_action_pressed("attack"):
		combat.try_attack()
	elif event.is_action_pressed("dodge"):
		_try_dodge()
	elif event.is_action_pressed("interact") and _interact_target:
		EventBus.player_interacted.emit(_interact_target)
		if _interact_target.has_method("interact"):
			_interact_target.interact(self)

# =====================================================================
#  PHYSICS
# =====================================================================
func _physics_process(delta: float) -> void:
	if cam == null:
		return
	# Controller camera stick.
	cam.apply_stick(Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)), delta)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := cam.flat_forward() * -input.y + cam.flat_right() * input.x
	if wish.length_squared() > 1.0:
		wish = wish.normalized()

	var speed := stats.move_speed(BASE_MOVE_SPEED)
	# Movement debuffs (spider webs, flooded water) decay over time.
	if _slow_timer > 0.0:
		_slow_timer -= delta
		speed *= _slow_mult
		if _slow_timer <= 0.0:
			_slow_mult = 1.0
	var sprinting := Input.is_action_pressed("sprint") and stamina > 1.0 and wish.length_squared() > 0.01
	if sprinting:
		var cost := SPRINT_COST_PER_S * delta
		if RunManager.active_tags().has("sprint_cost"):
			cost *= 0.75   # Runner Lungs
		stamina = maxf(stamina - cost, 0.0)
		speed *= SPRINT_MULT
	else:
		stamina = minf(stamina + STAMINA_REGEN * delta, stats.max_stamina())

	# --- dodge state ----------------------------------------------------
	if _dodge_timer >= 0.0:
		_dodge_timer += delta
		velocity.x = _dodge_dir.x * DODGE_SPEED
		velocity.z = _dodge_dir.z * DODGE_SPEED
		if _dodge_timer >= DODGE_TIME * _dodge_recovery_mult():
			_dodge_timer = -1.0
	else:
		velocity.x = wish.x * speed
		velocity.z = wish.z * speed

	# Gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.1)

	move_and_slide()

	# --- tank passive: Guarded after standing still 0.75s ---------------
	if stats.class_id == "tank":
		if wish.length_squared() < 0.001 and _dodge_timer < 0.0:
			_still_time += delta
			if _still_time >= 0.75 and not _guarded:
				_guarded = true
				EventBus.subtitle_requested.emit("Guarded", 0.8)
		else:
			_still_time = 0.0
			_guarded = false

	# --- lantern focus ---------------------------------------------------
	var focusing := Input.is_action_pressed("lantern")
	_focus_light.light_energy = lerpf(_focus_light.light_energy, 3.2 if focusing else 0.0, 12.0 * delta)
	_omni_light.omni_range = lerpf(_omni_light.omni_range, 8.0 if focusing else 10.0, 6.0 * delta)
	# Aim the cone where the camera looks.
	_focus_light.global_transform.basis = cam.pitch_node.global_transform.basis

	# --- footsteps + loudness (sound-tracking enemies listen) ----------
	var planar := Vector2(velocity.x, velocity.z).length()
	if planar > 0.5 and is_on_floor():
		_footstep_accum += planar * delta
		var stride := 2.2 if sprinting else 2.8
		if _footstep_accum >= stride:
			_footstep_accum = 0.0
			AudioManager.play("footstep", "SFX", randf_range(0.9, 1.1))
			var loud := 1.0 if sprinting else 0.55
			if RunManager.active_tags().has("no_footprints"):
				loud *= 0.5
			EventBus.player_moved_loud.emit(global_position, loud)

	# --- face movement/camera direction --------------------------------
	if wish.length_squared() > 0.01 and _dodge_timer < 0.0:
		var target_yaw := atan2(-wish.x, -wish.z)
		_body_mesh.rotation.y = lerp_angle(_body_mesh.rotation.y, target_yaw, 10.0 * delta)

	# --- interaction probe ----------------------------------------------
	_update_interact_target()
	_emit_bars()

func _dodge_recovery_mult() -> float:
	return 0.8 if RunManager.active_tags().has("dodge_recovery") else 1.0  # Quickstep

func _try_dodge() -> void:
	if _dodge_timer >= 0.0 or stamina < DODGE_COST:
		if stamina < DODGE_COST:
			AudioManager.play_ui("denied")
		return
	stamina -= DODGE_COST
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := cam.flat_forward() * -input.y + cam.flat_right() * input.x
	if dir.length_squared() < 0.01:
		dir = -cam.flat_forward()   # neutral dodge = backstep
	_dodge_dir = dir.normalized()
	_dodge_timer = 0.0
	AudioManager.play("dodge")
	if RunManager.active_tags().has("dodge_haste"):
		combat._haste_timer = 1.2   # Fleet Knife

func is_dodging_iframes() -> bool:
	return _dodge_timer >= DODGE_IFRAME_START and _dodge_timer <= DODGE_IFRAME_END

# =====================================================================
#  HEALTH / DAMAGE  (enemies call take_damage)
# =====================================================================
func take_damage(amount: float, source: Node = null) -> void:
	if godmode or health <= 0.0 or stats == null:
		return
	if is_dodging_iframes():
		# Perfect dodge: swordsman passive.
		if stats.class_id == "swordsman":
			combat.empower_next_strike()
			stamina = minf(stamina + 20.0, stats.max_stamina())
			EventBus.subtitle_requested.emit("Perfect dodge", 0.8)
		return
	var final := stats.damage_taken(amount)
	if _guarded:
		final *= 0.75   # tank passive
	health -= final
	cam.add_trauma(0.5)
	AudioManager.play("hurt")
	_emit_bars()
	if health <= 0.0:
		health = 0.0
		EventBus.player_died.emit()

func heal(amount: float) -> void:
	health = minf(health + amount, stats.max_health())
	_emit_bars()

## Movement debuff (spider webs, water). mult 0..1, duration seconds.
func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = minf(_slow_mult, clampf(mult, 0.2, 1.0))
	_slow_timer = maxf(_slow_timer, duration)

func get_health() -> float:
	return health

func _emit_bars() -> void:
	EventBus.player_health_changed.emit(health, stats.max_health())
	EventBus.player_stamina_changed.emit(stamina, stats.max_stamina())

# =====================================================================
#  INTERACTION
# =====================================================================
func _update_interact_target() -> void:
	var best = null   # untyped: prompt_text() is duck-typed
	var best_d := 2.6
	for node in get_tree().get_nodes_in_group("interactables"):
		var n3 := node as Node3D
		if n3 == null:
			continue
		var d: float = (n3.global_position - global_position).length()
		if d < best_d:
			best_d = d
			best = n3
	if best != _interact_target:
		_interact_target = best
		var hud = GameManager.ui.get_hud() if GameManager.ui else null
		if hud:
			var label := ""
			if best:
				label = "[E] " + (best.prompt_text() if best.has_method("prompt_text") else "Interact")
			hud.set_prompt(label)

# =====================================================================
#  AIM HELPERS (used by PlayerCombat)
# =====================================================================
func facing_dir() -> Vector3:
	# The direction the body is visually facing (melee arc).
	var yaw: float = _body_mesh.rotation.y + rotation.y
	return Vector3(-sin(yaw), 0.0, -cos(yaw))

func aim_dir() -> Vector3:
	# Camera forward, including pitch (ranged aim).
	return -cam.pitch_node.global_transform.basis.z.normalized()
