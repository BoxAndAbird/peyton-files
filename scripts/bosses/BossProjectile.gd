extends Node3D
## BossProjectile.gd - enemy projectile (water bolt, shard, shadow bolt).
## Mirrors the player's Projectile but raycasts against world+player and calls
## player.take_damage on hit. Dodgeable by design: speeds stay ~10-16 m/s.
## Visual: emissive sphere, color set by the firing boss.

const MAX_RANGE := 34.0

var _dir := Vector3.FORWARD
var _speed := 12.0
var _dmg := 15.0
var _sanity_drain := 0.0   # curse bolts (Hollow Monk) also erode the mind
var _travelled := 0.0
var _dead := false

func setup(dir: Vector3, speed: float, dmg: float, color: Color, sanity_drain := 0.0) -> void:
	_dir = dir.normalized()
	_speed = speed
	_dmg = dmg
	_sanity_drain = sanity_drain
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.22
	s.height = 0.44
	mesh.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	add_child(mesh)
	# Small glow so bolts read in dark corridors (readability rule).
	var light := OmniLight3D.new()
	light.omni_range = 3.0
	light.light_energy = 0.6
	light.light_color = color
	light.shadow_enabled = false
	add_child(light)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step := _speed * delta
	var from := global_position
	var to := from + _dir * step
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b11)  # world + player
	var hit := space.intersect_ray(q)
	if hit:
		var col := hit["collider"] as Node
		if col and col.is_in_group("player") and col.has_method("take_damage"):
			col.call("take_damage", _dmg, self)
			var pl = GameManager.player
			if pl and pl.cam:
				pl.cam.add_trauma(0.3)
			if _sanity_drain > 0.0 and GameManager.current_stage:
				var sm = GameManager.current_stage.get_node_or_null("SanityManager")
				if sm:
					sm.set_sanity(sm.sanity - _sanity_drain)
		_expire()
		return
	global_position = to
	_travelled += step
	if _travelled >= MAX_RANGE:
		_expire()

func _expire() -> void:
	_dead = true
	queue_free()
