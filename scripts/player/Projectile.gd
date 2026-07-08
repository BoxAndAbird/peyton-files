extends Node3D
## Projectile.gd - arrow/bolt for ranged classes.
## Moves in a straight line, raycasting each frame so fast arrows never
## tunnel through enemies or walls. Calls back into PlayerCombat on hit.
## Charged shots (Archer passive: "charged shots pierce at high range stat")
## carry pierce_left > 0: they punch through enemies, excluding each body
## already hit, and only stop on walls or range.
##
## Visual: small emissive box (PS2 placeholder). No external assets.

var _dir := Vector3.FORWARD
var _speed := 26.0
var _travelled := 0.0
var _max_range := 20.0
var _owner_combat = null   # PlayerCombat (untyped for duck-typed callback)
var _dead := false
var _pierce_left := 0
var _dmg_mult := 1.0
var _exclude: Array[RID] = []   # bodies already pierced

func _ready() -> void:
	# Placeholder mesh: thin glowing bolt.
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.06, 0.5)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.8, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.75, 0.4)
	mat.emission_energy_multiplier = 1.4
	mesh.material_override = mat
	add_child(mesh)

func launch(dir: Vector3, max_range: float, owner_combat: Node, pierce := 0, dmg_mult := 1.0) -> void:
	_dir = dir.normalized()
	_max_range = max_range
	_owner_combat = owner_combat
	_pierce_left = pierce
	_dmg_mult = dmg_mult
	look_at_from_position(global_position, global_position + _dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step := _speed * delta
	var from := global_position
	var to := from + _dir * step
	# Raycast against world (layer 1) + enemies (layer 3).
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to, 0b101)
	q.collide_with_areas = false
	q.exclude = _exclude
	var hit := space.intersect_ray(q)
	if hit:
		var col: Object = hit["collider"]
		# Walk up to the enemy root (enemies group).
		var n := col as Node
		while n and not n.is_in_group("enemies"):
			n = n.get_parent()
		if n and _owner_combat and _owner_combat.has_method("projectile_hit"):
			_owner_combat.projectile_hit(n, _dmg_mult)
			if _pierce_left > 0:
				# Charged pierce: pass through, never re-hit this body.
				_pierce_left -= 1
				_exclude.append(hit["rid"])
				global_position = Vector3(hit["position"]) + _dir * 0.15
				return
		_expire()
		return
	global_position = to
	_travelled += step
	if _travelled >= _max_range:
		_expire()

func _expire() -> void:
	_dead = true
	queue_free()
