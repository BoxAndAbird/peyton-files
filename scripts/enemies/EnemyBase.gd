extends CharacterBody3D
## EnemyBase.gd - shared enemy body + AI state machine (bible sections 10, 27).
## Data-driven from Database.ENEMIES so ALL TEN SPECIES run on this one class;
## species that need bespoke behavior later subclass it and override hooks
## (_on_state_entered, _species_process, _build_body).
##
## SENSES (from enemy data "senses"):
##   "sight"     - detect player within radius (+ line of sight check)
##   "sight_los" - like sight but ONLY moves when player is NOT looking (Watcher)
##   "sound"     - blind; reacts to EventBus.player_moved_loud (Blind Stalker)
##   "proximity" - disguised until the player comes close (Mimic)
##
## States per bible: IDLE, PATROL, INVESTIGATE, CHASE, ATTACK, STAGGERED, DEAD.
## (Search/Retreat/Enraged slots exist in the enum for later species.)
##
## Emits: EventBus.enemy_died, damage via player.take_damage, combat music via
## combat_state_changed (group-counted). Scaling: +15% hp / +10% dmg per stage.

enum AIState { IDLE, PATROL, INVESTIGATE, SEARCH, CHASE, ATTACK, RETREAT, STAGGERED, ENRAGED, DEAD }

const GRAVITY := 18.0
const POISE_MAX := 40.0

var species_id := "crawler"
var data: Dictionary = {}
var hp := 50.0
var max_hp := 50.0
var damage := 10.0
var move_speed := 3.0
var detect_radius := 12.0
var senses := "sight"

# Attack timing (Appendix E: per-species windup/active/recovery tables).
# Species subclasses override these in _species_setup().
var attack_range := 1.9
var attack_windup := 0.45
var attack_recovery := 1.1
var retreat_time := 1.5          # RETREAT state duration (fleeing species)

# Hallucination enemies (Appendix B combat-hallucination events): translucent,
# one-hit, deal no damage, self-fade. Created via make_hallucination().
var is_hallucination := false

# Dormancy: StageBuilder's activation manager freezes far enemies so the
# active-enemy cap (Appendix J) holds. Dormant = no physics, no hearing.
var dormant := false

# Movement debuff (Flooded Caverns water; webs). 1.0 = unaffected.
var _slow_mult := 1.0
var _slow_timer := 0.0

var state: int = AIState.IDLE
var staggered := false
var _state_timer := 0.0
var _attack_timer := 0.0
var _poise := 0.0
var _burn_time := 0.0
var _burn_tick_dmg := 0.0
var _burn_accum := 0.0
var _investigate_pos := Vector3.ZERO
var _patrol_target := Vector3.ZERO
var _revealed := true            # false for proximity (mimic) until triggered
var _agent: NavigationAgent3D
var _body_mesh: MeshInstance3D
var _mat: StandardMaterial3D

func setup(p_species: String, stage_index: int) -> void:
	species_id = p_species
	data = Database.get_enemy(species_id)
	# Baseline + per-stage scaling (bible section 27).
	var stage_mult_hp := pow(1.15, stage_index)
	var stage_mult_dmg := pow(1.10, stage_index)
	max_hp = float(data["hp"]) * stage_mult_hp
	hp = max_hp
	damage = float(data["damage"]) * stage_mult_dmg
	move_speed = float(data["speed"]) * 2.2   # table value is a scalar; 2.2 m/s base
	detect_radius = float(data["detect"])
	senses = String(data["senses"])
	_revealed = senses != "proximity"

	collision_layer = 0b100      # layer 3: enemy
	collision_mask = 0b1         # collide with world
	add_to_group("enemies")

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 1.2
	_agent.radius = 0.5
	add_child(_agent)

	_build_body()
	if senses == "sound":
		EventBus.player_moved_loud.connect(_on_heard_sound)

	SaveManager.record_encyclopedia(species_id)
	_species_setup()
	_enter_state(AIState.IDLE)

## Species hook: subclasses set attack timing, groups, extra senses here.
func _species_setup() -> void:
	pass

## Turn this enemy into a sanity hallucination: translucent, fragile,
## harmless, self-fading (faster with the Clear Mind upgrade).
func make_hallucination() -> void:
	is_hallucination = true
	hp = 1.0
	if _mat:
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(_mat.albedo_color, 0.45)
	var life := 5.0 if RunManager.active_tags().has("halluc_fade") else 9.0
	var t := get_tree().create_timer(life, false)
	t.timeout.connect(func():
		if state != AIState.DEAD:
			fade_out())

## Silent removal (hallucinations, cleanup): no loot, no kill credit.
func fade_out() -> void:
	state = AIState.DEAD
	collision_layer = 0
	remove_from_group("enemies")
	if is_in_group("chasing_enemies"):
		remove_from_group("chasing_enemies")
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.6)
	tw.tween_callback(queue_free)

## StageBuilder activation manager (Appendix J active-enemy cap).
func set_dormant(value: bool) -> void:
	if dormant == value or state == AIState.DEAD:
		return
	dormant = value
	set_physics_process(not dormant)
	if dormant:
		velocity = Vector3.ZERO

## Placeholder body: silhouette-first low-poly (bible section 18). Override
## per species for bespoke shapes.
func _build_body() -> void:
	_body_mesh = MeshInstance3D.new()
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = data["color"]
	_mat.roughness = 1.0
	if senses == "proximity" and not _revealed:
		# Mimic: looks like a loot chest until revealed.
		var box := BoxMesh.new()
		box.size = Vector3(1.0, 0.8, 0.8)
		_body_mesh.mesh = box
		_body_mesh.position = Vector3(0, 0.4, 0)
		_mat.emission_enabled = true
		_mat.emission = Color(0.9, 0.8, 0.3)
		_mat.emission_energy_multiplier = 0.5
	else:
		var cap := CapsuleMesh.new()
		cap.radius = 0.38
		cap.height = 1.4 + float(data["threat"]) * 0.12   # bigger = scarier
		_body_mesh.mesh = cap
		_body_mesh.position = Vector3(0, 0.85, 0)
		# Eye glow for sighted species only (readability without brightness).
		if senses != "sound":
			var eye := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.06
			s.height = 0.12
			eye.mesh = s
			eye.position = Vector3(0.12, 1.45, -0.3)
			var em := StandardMaterial3D.new()
			em.emission_enabled = true
			em.emission = Color(0.9, 0.2, 0.15)
			em.emission_energy_multiplier = 2.0
			eye.material_override = em
			add_child(eye)
	_body_mesh.material_override = _mat
	add_child(_body_mesh)

# =====================================================================
#  STATE MACHINE
# =====================================================================
func _enter_state(new_state: int) -> void:
	state = new_state
	_state_timer = 0.0
	match state:
		AIState.CHASE:
			add_to_group("chasing_enemies")
			EventBus.combat_state_changed.emit(true)
		AIState.STAGGERED:
			staggered = true
			_flash(Color.WHITE)
		AIState.DEAD:
			pass
	if state != AIState.CHASE and is_in_group("chasing_enemies"):
		remove_from_group("chasing_enemies")
		if get_tree() and get_tree().get_nodes_in_group("chasing_enemies").is_empty():
			EventBus.combat_state_changed.emit(false)
	_on_state_entered(state)

## Species hook.
func _on_state_entered(_s: int) -> void:
	pass

func _physics_process(delta: float) -> void:
	if state == AIState.DEAD:
		return
	_state_timer += delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_mult = 1.0
	_process_burn(delta)

	var player := GameManager.player as Node3D
	var dist := INF
	if player:
		dist = global_position.distance_to(player.global_position)

	match state:
		AIState.IDLE:
			if _state_timer > 2.0:
				_patrol_target = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
				_enter_state(AIState.PATROL)
			_try_detect(player, dist)
		AIState.PATROL:
			_move_toward(_patrol_target, move_speed * 0.5, delta)
			if _state_timer > 4.0 or global_position.distance_to(_patrol_target) < 1.0:
				_enter_state(AIState.IDLE)
			_try_detect(player, dist)
		AIState.INVESTIGATE:
			_move_toward(_investigate_pos, move_speed * 0.75, delta)
			if global_position.distance_to(_investigate_pos) < 1.4 or _state_timer > 6.0:
				_enter_state(AIState.IDLE)
			_try_detect(player, dist)
		AIState.CHASE:
			if player == null:
				_enter_state(AIState.IDLE)
			elif dist <= attack_range and _attack_timer <= 0.0:
				_enter_state(AIState.ATTACK)
				_begin_attack(player)
			else:
				var speed := _chase_speed(player)
				_move_toward(_chase_target(player), speed, delta)
				if dist > detect_radius * 1.8 and senses != "sound":
					_enter_state(AIState.IDLE)
		AIState.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
		AIState.RETREAT:
			# Flee directly away from the player, then re-engage.
			if player:
				var away := global_position + (global_position - player.global_position)
				_move_toward(away, move_speed * 1.1, delta)
			if _state_timer >= retreat_time:
				_enter_state(AIState.CHASE)
		AIState.STAGGERED:
			velocity.x = 0.0
			velocity.z = 0.0
			if _state_timer > 1.0:
				staggered = false
				_mat.albedo_color = data["color"]
				_enter_state(AIState.CHASE)

	# Gravity always.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.1)
	move_and_slide()
	_species_process(delta)

## Species hook.
func _species_process(_delta: float) -> void:
	pass

## Species hook: where to move while chasing (Blind Stalker hunts the LAST
## HEARD position, not the player's true position).
func _chase_target(player: Node3D) -> Vector3:
	return player.global_position

## Species hook: chase speed modifier (Watcher freezes while watched).
func _chase_speed(player) -> float:
	if senses == "sight_los" and _player_sees_me(player):
		return 0.0
	return move_speed

# --- senses -----------------------------------------------------------
func _try_detect(player: Node3D, dist: float) -> void:
	if player == null:
		return
	match senses:
		"sight", "sight_los":
			if dist <= detect_radius and _has_los(player):
				_enter_state(AIState.CHASE)
		"proximity":
			if dist <= 2.6 and not _revealed:
				_reveal()
			elif _revealed and dist <= detect_radius:
				_enter_state(AIState.CHASE)
		"sound":
			pass   # only _on_heard_sound drives this species

func _on_heard_sound(pos: Vector3, loudness: float) -> void:
	if state == AIState.DEAD or dormant:
		return
	var d := global_position.distance_to(pos)
	if d <= detect_radius * loudness:
		if d < 3.0:
			_enter_state(AIState.CHASE)
		elif state != AIState.CHASE:
			_investigate_pos = pos
			_enter_state(AIState.INVESTIGATE)

func _has_los(player: Node3D) -> bool:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 1.3,
		player.global_position + Vector3.UP * 1.0, 0b1)
	return space.intersect_ray(q).is_empty()

## `player` untyped: aim_dir() is a PlayerController duck-typed member.
func _player_sees_me(player) -> bool:
	if player == null or not player.has_method("aim_dir"):
		return false
	var to_me: Vector3 = (global_position - player.global_position).normalized()
	var aim: Vector3 = player.aim_dir()
	return aim.dot(to_me) > 0.25 and _has_los(player)

func _reveal() -> void:
	_revealed = true
	AudioManager.play_at("hurt", global_position, get_parent(), 0.6)
	# Swap chest disguise for the creature body.
	if _body_mesh:
		_body_mesh.queue_free()
	var was := senses
	senses = "sight"
	_build_body()
	senses = was
	_enter_state(AIState.CHASE)

## Movement debuff (water, webs); mirrors PlayerController.apply_slow.
func apply_slow(mult: float, duration: float) -> void:
	_slow_mult = minf(_slow_mult, clampf(mult, 0.2, 1.0))
	_slow_timer = maxf(_slow_timer, duration)

# --- movement -----------------------------------------------------------
func _move_toward(target: Vector3, speed: float, _delta: float) -> void:
	speed *= _slow_mult
	if speed <= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var next := target
	if _agent and _agent.is_inside_tree():
		_agent.target_position = target
		if not _agent.is_navigation_finished():
			next = _agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.05:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		# Face travel direction (backstab checks read basis -z).
		var yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, yaw, 0.2)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

# --- attacking ------------------------------------------------------------
func _begin_attack(_player: Node3D) -> void:
	_flash(Color(1.0, 0.5, 0.3))   # telegraph (bible: clear windups)
	AudioManager.play_at("dodge", global_position, get_parent(), 0.7)
	# create_timer(..., false): respect pause so windups never land mid-pause.
	var windup := get_tree().create_timer(attack_windup, false)
	windup.timeout.connect(func():
		if state == AIState.DEAD or GameManager.player == null:
			return
		if _mat:
			_mat.albedo_color = data["color"]
		_perform_attack()
		_attack_timer = attack_recovery
		if state != AIState.DEAD and state != AIState.STAGGERED and state != AIState.RETREAT:
			_enter_state(AIState.CHASE))

## Species hook: the attack's active frames. Default = frontal melee bite.
## Hallucinations whiff by design (Appendix B: pressure without damage).
func _perform_attack() -> void:
	var pl = GameManager.player
	if pl == null:
		return
	var d: float = global_position.distance_to(pl.global_position)
	if d <= attack_range + 0.5:
		if is_hallucination:
			AudioManager.play_at("dodge", global_position, get_parent(), 1.3)
			return
		pl.take_damage(damage, self)

# --- damage intake ----------------------------------------------------------
func take_damage(amount: float, _source: Node = null) -> void:
	if state == AIState.DEAD:
		return
	if not _revealed:
		_reveal()
	hp -= amount
	_poise += amount
	_flash(Color(1, 0.2, 0.2))
	if hp <= 0.0:
		die()
	elif _poise >= POISE_MAX:
		_poise = 0.0
		_enter_state(AIState.STAGGERED)
	elif state == AIState.IDLE or state == AIState.PATROL:
		_enter_state(AIState.CHASE)   # retaliate

## Instant stagger (Swordsman parry, Tank guard bash).
func force_stagger() -> void:
	if state != AIState.DEAD:
		_poise = 0.0
		_enter_state(AIState.STAGGERED)

func apply_burn(tick_damage: float, duration: float) -> void:
	_burn_tick_dmg = tick_damage
	_burn_time = maxf(_burn_time, duration)

func _process_burn(delta: float) -> void:
	if _burn_time <= 0.0:
		return
	_burn_time -= delta
	_burn_accum += delta
	if _burn_accum >= 0.5:      # burn ticks every 0.5s (bible section 5)
		_burn_accum = 0.0
		hp -= _burn_tick_dmg
		_flash(Color(1.0, 0.6, 0.1))
		if hp <= 0.0:
			die()

func _flash(color: Color) -> void:
	if _mat:
		_mat.albedo_color = color
		var t := get_tree().create_timer(0.12, false)
		t.timeout.connect(func():
			if _mat and state != AIState.DEAD:
				_mat.albedo_color = data["color"])

func die() -> void:
	if state == AIState.DEAD:
		return
	if is_hallucination:
		# Hallucinations dissolve: no loot, no kill credit, no gauntlet count.
		EventBus.subtitle_requested.emit("It was never there.", 1.5)
		fade_out()
		return
	_enter_state(AIState.DEAD)
	SaveManager.stat_add_kill(species_id)
	# Ending matrix (Appendix G2): Mercy requires killing no player echoes.
	if species_id == "faceless":
		RunManager.echoes_killed += 1
	EventBus.enemy_died.emit(self, global_position)
	AudioManager.play_at("hurt", global_position, get_parent(), 0.5)
	# Essence drop (bible combat loop: loot essence).
	var Pickup := load("res://scripts/items/Pickup.gd")
	var p = Pickup.new()   # untyped: setup() is a script member
	p.setup("essence", float(data["threat"]) * 2.0)
	get_parent().add_child(p)
	p.global_position = global_position + Vector3.UP * 0.3
	# Equipment drop chance: base 8%, nudged by player Luck (bible: luck
	# improves loot, never guarantees it).
	var luck := 0.0
	var pl = GameManager.player
	if pl and pl.stats:
		luck = pl.stats.stat("luck")
	if randf() < 0.08 + luck * 0.006:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var ip = Pickup.new()
		ip.setup_item(Database.roll_item_id(rng, luck))
		get_parent().add_child(ip)
		ip.global_position = global_position + Vector3(0.8, 0.3, 0.4)
	# Collapse then clean up.
	collision_layer = 0
	remove_from_group("enemies")
	if is_in_group("chasing_enemies"):
		remove_from_group("chasing_enemies")
		if get_tree().get_nodes_in_group("chasing_enemies").is_empty():
			EventBus.combat_state_changed.emit(false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.0, 0.05, 1.0), 0.4)
	tw.tween_callback(queue_free)
