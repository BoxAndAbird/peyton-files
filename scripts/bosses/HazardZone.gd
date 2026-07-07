extends Area3D
## HazardZone.gd - lingering damage volume (Drowned Priest floods, acid pools,
## void patches). Ticks damage twice per second while the player stands inside,
## then fades out after `life` seconds. Visual: translucent emissive slab so
## the danger area is always readable.

var _dps := 10.0
var _life := 8.0
var _tick := 0.0
var _mesh: MeshInstance3D

func setup(size: Vector3, dps: float, life: float, color: Color) -> void:
	_dps = dps
	_life = life
	collision_layer = 0
	collision_mask = 0b10          # detect the player (layer 2)
	monitoring = true

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	add_child(col)

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, maxf(size.y * 0.5, 0.3), size.z)
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.7
	_mesh.material_override = mat
	add_child(_mesh)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(1.0, 0.02, 1.0), 0.4)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return
	_tick += delta
	if _tick >= 0.5:
		_tick = 0.0
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.call("take_damage", _dps * 0.5, self)
