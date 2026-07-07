extends "res://scripts/bosses/BossBase.gd"
## Burrower.gd - Stage 1 boss: massive blind worm (bible section 11).
## Teaches arena awareness. Cycle:
##   BURROWED  - unhittable; a dirt mound tracks toward the player
##   EMERGING  - erupts at the mound with an eruption ring
##   DECIDE    - close player => tail sweep; far player => telegraphed LUNGE
##   LUNGE     - dashes along a recorded line; DODGING IT leaves the worm
##               EXPOSED for 2.5s at 2x damage (the bible's counterplay:
##               "attack after missed lunge")
##   SINKING   - returns underground
## Phases (Database.BOSSES.burrower): 2 = wall-break crawler adds + rocks on
## emerge; 3 = panic speed + rock rain while burrowed.

enum W { BURROWED, EMERGING, DECIDE, TELEGRAPH, LUNGE, EXPOSED, SINKING }

var w: int = W.BURROWED
var wt := 0.0                 # state timer
var _under_pos := Vector3.ZERO
var _mound: MeshInstance3D
var _lunge_dir := Vector3.ZERO
var _lunge_hit := false
var _rock_accum := 0.0
var _scar_mat: StandardMaterial3D

func setup_boss(id: String) -> void:
	_base_color = Color(0.75, 0.7, 0.6)
	super.setup_boss(id)
	set_meta("hit_radius", 2.0)
	_under_pos = global_position
	_make_mound()
	_go_burrowed()

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.5
	cap.height = 5.0
	col.shape = cap
	col.position = Vector3(0, 2.5, 0)
	add_child(col)

func _build_body() -> void:
	# Segmented worm silhouette: stacked spheres, glowing weak scars.
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.roughness = 1.0
	for i in range(4):
		var seg := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 1.5 - i * 0.22
		s.height = s.radius * 2.0
		seg.mesh = s
		seg.position = Vector3(0, 0.9 + i * 1.15, 0)
		seg.material_override = _mat
		add_child(seg)
	# Weak scars: emissive patches that blaze while EXPOSED.
	_scar_mat = StandardMaterial3D.new()
	_scar_mat.albedo_color = Color(0.9, 0.5, 0.3)
	_scar_mat.emission_enabled = true
	_scar_mat.emission = Color(1.0, 0.45, 0.2)
	_scar_mat.emission_energy_multiplier = 0.3
	for i in range(3):
		var scar := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.5, 0.35, 0.25)
		scar.mesh = b
		scar.position = Vector3(0.9 - i * 0.2, 1.3 + i * 1.2, -1.0 + i * 0.3)
		scar.material_override = _scar_mat
		add_child(scar)

func _make_mound() -> void:
	_mound = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 1.2
	s.height = 0.8
	_mound.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.4, 0.33, 0.26)
	m.roughness = 1.0
	_mound.material_override = m
	_mound.visible = false
	# Mound is parented to the stage so it survives our own position jumps.
	call_deferred("_adopt_mound")

func _adopt_mound() -> void:
	if get_parent():
		get_parent().add_child(_mound)

# --- state helpers ------------------------------------------------------
func _go_burrowed() -> void:
	w = W.BURROWED
	wt = 4.0
	_under_pos = global_position
	global_position.y = -9.0          # far underground; unhittable
	if _mound:
		_mound.visible = true

func _damageable() -> bool:
	return w != W.BURROWED and w != W.SINKING

func _pattern(delta: float) -> void:
	wt -= delta
	match w:
		W.BURROWED:
			var speed: float = float(tuning.get("burrow_speed", 6.0)) * (1.4 if phase >= 3 else 1.0)
			var to := player_pos() - _under_pos
			to.y = 0.0
			if to.length() > 0.2:
				_under_pos += to.normalized() * speed * delta
			if _mound:
				_mound.global_position = Vector3(_under_pos.x, 0.15, _under_pos.z)
			# Phase 3 panic: rocks rain while it hunts underground.
			if phase >= 3:
				_rock_accum += delta
				if _rock_accum >= 1.4:
					_rock_accum = 0.0
					_fall_rock(player_pos() + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)),
						float(tuning.get("rock_dmg", 22.0)))
			if to.length() < 2.6 or wt <= 0.0:
				_emerge()
		W.EMERGING:
			if wt <= 0.0:
				w = W.DECIDE
				wt = 0.7 if phase < 3 else 0.4
		W.DECIDE:
			face_player(0.2)
			stop_moving()
			if wt <= 0.0:
				if dist_to_player() < 4.0:
					_tail_sweep()
				else:
					_begin_lunge()
		W.TELEGRAPH:
			face_player(0.3)
			if wt <= 0.0:
				w = W.LUNGE
				wt = 0.55
				_lunge_hit = false
				AudioManager.play_at("hurt", global_position, get_parent(), 0.4)
		W.LUNGE:
			velocity.x = _lunge_dir.x * 13.0
			velocity.z = _lunge_dir.z * 13.0
			if not _lunge_hit and dist_to_player() < 2.6:
				_lunge_hit = true
				hurt_player(float(tuning.get("lunge_dmg", 26.0)), 0.5)
			if wt <= 0.0:
				stop_moving()
				if _lunge_hit:
					_sink()
				else:
					# MISSED: the counterplay window opens.
					w = W.EXPOSED
					wt = float(tuning.get("exposed_time", 2.5))
					exposed = true
					_scar_mat.emission_energy_multiplier = 3.0
					EventBus.subtitle_requested.emit("Its scars glow — strike now!", 2.0)
		W.EXPOSED:
			stop_moving()
			if wt <= 0.0:
				exposed = false
				_scar_mat.emission_energy_multiplier = 0.3
				_sink()
		W.SINKING:
			if wt <= 0.0:
				_go_burrowed()

func _emerge() -> void:
	w = W.EMERGING
	wt = 0.5
	if _mound:
		_mound.visible = false
	global_position = Vector3(_under_pos.x, 0.4, _under_pos.z)
	# Eruption ring punishes standing on the mound.
	_ring_attack(global_position, 3.0, 0.45, float(tuning.get("sweep_dmg", 18.0)))
	var pl = GameManager.player
	if pl and pl.cam:
		pl.cam.add_trauma(0.35)
	# Phase 2: the cave wall breaks — crawler adds join.
	if phase >= 2 and randf() < 0.5:
		_summon("crawler", 1 if phase == 2 else 2)
	if phase >= 2:
		_fall_rock(player_pos() + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)),
			float(tuning.get("rock_dmg", 22.0)))

func _tail_sweep() -> void:
	_ring_attack(global_position, 4.2, 0.6, float(tuning.get("sweep_dmg", 18.0)))
	w = W.SINKING
	wt = 1.1

func _begin_lunge() -> void:
	w = W.TELEGRAPH
	wt = 0.7 if phase < 3 else 0.5
	var to := player_pos() - global_position
	to.y = 0.0
	_lunge_dir = to.normalized()
	_flash(Color(1.0, 0.5, 0.3))

func _sink() -> void:
	w = W.SINKING
	wt = 0.8
	stop_moving()

func _on_phase(new_phase: int) -> void:
	if new_phase == 2:
		EventBus.subtitle_requested.emit("The cave walls crack open.", 2.5)
	elif new_phase == 3:
		EventBus.subtitle_requested.emit("It panics. The ceiling is coming down.", 2.5)

func die() -> void:
	if _mound and is_instance_valid(_mound):
		_mound.queue_free()
	super.die()
