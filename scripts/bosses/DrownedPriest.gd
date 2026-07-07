extends "res://scripts/bosses/BossBase.gd"
## DrownedPriest.gd - Stage 2 boss: corpse-priest of the underground water
## (bible section 11).
##   Phase 1: keeps mid-range, water bolt volleys + staff slam up close.
##   Phase 2: floods arena lanes (HazardZones) and summons drowned hands.
##   Phase 3: CHANT every ~12s - a 5s channel. Deal enough damage during the
##            channel (tuning.chant_interrupt) to stagger him (the bible's
##            counterplay: "interrupt chant with ranged hits or heavy
##            stagger"); otherwise a water nova floods the whole arena.

var _bolt_cd := 0.0
var _slam_cd := 0.0
var _chant_cd := 8.0
var _chanting := false
var _chant_left := 0.0
var _chant_damage := 0.0
var _flood_cd := 0.0
var _staff: MeshInstance3D

func setup_boss(id: String) -> void:
	_base_color = Color(0.35, 0.5, 0.55)
	super.setup_boss(id)
	set_meta("hit_radius", 1.0)

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.7
	cap.height = 2.6
	col.shape = cap
	col.position = Vector3(0, 1.4, 0)
	add_child(col)

func _build_body() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.roughness = 1.0
	# Tall robed silhouette: capsule body + wide "robe" cone + staff.
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.65
	cap.height = 2.5
	body.mesh = cap
	body.position = Vector3(0, 1.4, 0)
	body.material_override = _mat
	add_child(body)
	var robe := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.5
	cone.bottom_radius = 1.1
	cone.height = 1.4
	robe.mesh = cone
	robe.position = Vector3(0, 0.7, 0)
	robe.material_override = _mat
	add_child(robe)
	_staff = MeshInstance3D.new()
	var rod := BoxMesh.new()
	rod.size = Vector3(0.12, 2.6, 0.12)
	_staff.mesh = rod
	_staff.position = Vector3(0.8, 1.5, 0)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.3, 0.65, 0.8)
	sm.emission_enabled = true
	sm.emission = Color(0.3, 0.65, 0.9)
	sm.emission_energy_multiplier = 0.8
	_staff.material_override = sm
	add_child(_staff)
	# Drowned halo light: readable boss silhouette in the arena.
	var halo := OmniLight3D.new()
	halo.omni_range = 6.0
	halo.light_energy = 0.8
	halo.light_color = Color(0.4, 0.7, 0.9)
	halo.position = Vector3(0, 2.8, 0)
	add_child(halo)

func _pattern(delta: float) -> void:
	_bolt_cd -= delta
	_slam_cd -= delta
	_flood_cd -= delta
	face_player(0.18)

	# --- chanting channel (phase 3) ------------------------------------
	if _chanting:
		stop_moving()
		_chant_left -= delta
		_staff.rotation.z = sin(Time.get_ticks_msec() * 0.01) * 0.4
		if _chant_left <= 0.0:
			_chanting = false
			_nova()
		return
	if phase >= 3:
		_chant_cd -= delta
		if _chant_cd <= 0.0:
			_begin_chant()
			return

	# --- positioning: hold 5-11m ----------------------------------------
	var d := dist_to_player()
	if d < 4.5:
		move_toward_point(global_position + (global_position - player_pos()), 2.6)
	elif d > 11.0:
		move_toward_point(player_pos(), 2.2)
	else:
		stop_moving()

	# --- water bolts ------------------------------------------------------
	if _bolt_cd <= 0.0 and d <= 22.0:
		_bolt_cd = 2.4 if phase == 1 else 1.8
		var from := global_position + Vector3(0, 2.2, 0)
		var dmg: float = float(tuning.get("bolt_dmg", 16.0))
		_shoot_at(from, player_pos() + Vector3(0, 1.0, 0), 12.0, dmg)
		if phase >= 2:
			# Spread volley: two extra bolts at slight angles.
			var to := (player_pos() - global_position).normalized()
			for ang in [-0.35, 0.35]:
				var dir := to.rotated(Vector3.UP, ang)
				_shoot_at(from, global_position + dir * 12.0 + Vector3(0, 1.0, 0), 11.0, dmg * 0.8)

	# --- staff slam up close ---------------------------------------------
	if _slam_cd <= 0.0 and d < 3.0:
		_slam_cd = 3.2
		_ring_attack(global_position, 3.2, 0.55, float(tuning.get("slam_dmg", 24.0)))

	# --- phase 2+: periodic lane floods ------------------------------------
	if phase >= 2 and _flood_cd <= 0.0:
		_flood_cd = 9.0
		_flood_lanes()

func _flood_lanes() -> void:
	EventBus.subtitle_requested.emit("The water rises.", 2.0)
	var dps: float = float(tuning.get("flood_dps", 10.0))
	# Three long strips crossing the arena around the priest.
	for i in range(3):
		var ang := randf_range(0.0, PI)
		var offset := Vector3(cos(ang), 0, sin(ang)) * randf_range(2.0, 5.0)
		var size := Vector3(3.0, 0.5, 14.0) if i % 2 == 0 else Vector3(14.0, 0.5, 3.0)
		_hazard(global_position + offset, size, dps, 8.0)
	_summon("drowned", 2)

func _begin_chant() -> void:
	_chanting = true
	_chant_left = 5.0
	_chant_damage = 0.0
	_chant_cd = 12.0
	_flash(Color(0.4, 0.8, 1.0))
	EventBus.subtitle_requested.emit("He chants — interrupt him!", 3.0)
	AudioManager.play("ui_denied", "SFX", 0.5)

func _nova() -> void:
	EventBus.subtitle_requested.emit("The chant completes. The water answers.", 2.5)
	_ring_attack(global_position, 9.5, 0.7, float(tuning.get("nova_dmg", 45.0)))
	_hazard(global_position, Vector3(12.0, 0.5, 12.0), float(tuning.get("flood_dps", 10.0)), 5.0)

func _on_damaged(amount: float) -> void:
	if _chanting:
		_chant_damage += amount
		if _chant_damage >= float(tuning.get("chant_interrupt", 60.0)):
			_chanting = false
			stagger(2.0)   # the interrupt reward: a long punish window

func _on_phase(new_phase: int) -> void:
	if new_phase == 2:
		_flood_cd = 0.5   # flood almost immediately on phase entry
		EventBus.subtitle_requested.emit("Drowned hands reach from the water.", 2.5)
	elif new_phase == 3:
		_chant_cd = 4.0
		EventBus.subtitle_requested.emit("He remembers the words now.", 2.5)