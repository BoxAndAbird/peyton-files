extends Node3D
## FallingRock.gd - telegraphed falling rock (Burrower phase 2/3, Ancient
## collapse phase). Shows a ground warning disc, drops a rock from 10m, and
## damages the player within `radius` on impact. Fair by design: the warning
## appears ~0.8s before the hit lands.

var _dmg := 22.0
var _radius := 2.2
var _rock: MeshInstance3D
var _disc: MeshInstance3D
var _vel := 0.0
var _falling := false
var _ground_y := 0.0

func setup(ground_pos: Vector3, dmg: float, radius := 2.2) -> void:
	_dmg = dmg
	_radius = radius
	global_position = ground_pos
	_ground_y = ground_pos.y

	# Warning disc on the floor.
	_disc = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = _radius
	cyl.bottom_radius = _radius
	cyl.height = 0.05
	_disc.mesh = cyl
	var dm := StandardMaterial3D.new()
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color = Color(1.0, 0.6, 0.1, 0.3)
	dm.emission_enabled = true
	dm.emission = Color(1.0, 0.6, 0.1)
	_disc.material_override = dm
	_disc.position = Vector3(0, 0.06, 0)
	add_child(_disc)

	# The rock itself, waiting overhead.
	_rock = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.2, 1.2)
	_rock.mesh = box
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.35, 0.32, 0.3)
	rm.roughness = 1.0
	_rock.material_override = rm
	_rock.position = Vector3(0, 10.0, 0)
	_rock.rotation = Vector3(randf(), randf(), randf())
	add_child(_rock)

	# Short warning delay before the drop starts (pause-safe timer).
	var t := get_tree().create_timer(0.35, false)
	t.timeout.connect(func(): _falling = true)

func _physics_process(delta: float) -> void:
	if not _falling or _rock == null:
		return
	_vel += 30.0 * delta
	_rock.position.y -= _vel * delta
	if _rock.position.y <= 0.6:
		_impact()

func _impact() -> void:
	_falling = false
	AudioManager.play_at("hit", global_position, get_parent(), 0.6)
	var pl = GameManager.player
	if pl:
		var d: float = Vector2(pl.global_position.x - global_position.x,
			pl.global_position.z - global_position.z).length()
		if d <= _radius:
			pl.take_damage(_dmg, self)
		if pl.cam:
			pl.cam.add_trauma(clampf(0.6 - d * 0.04, 0.1, 0.6))
	# Leave brief rubble, then clean up.
	_rock.position.y = 0.6
	_disc.visible = false
	var tw := create_tween()
	tw.tween_property(_rock, "scale", Vector3(1.0, 0.15, 1.0), 0.5)
	tw.tween_interval(1.0)
	tw.tween_callback(queue_free)
