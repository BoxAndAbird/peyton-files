extends "res://scripts/enemies/EnemyBase.gd"
## Crystal Spider (Appendix E.3) - mineral arachnid; ranged zone control.
## Identity: keeps its distance and SPITS SHARDS (glass-click telegraph),
## laying slowing WEB patches to control space. Its crystals glow - the doc
## notes it can even help visibility. Weak to blunt close melee (it is
## fragile up close and slow to reposition).
## Attack timing per E.3 row 1: windup 0.47 / recovery 0.48 / damage 18.

var _spit_cd := 0.0
var _web_cd := 4.0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 1.6            # weak fallback bite only
	damage = 18.0 * pow(1.10, RunManager.stage_index)
	# Glowing abdomen: a small light so the spider aids visibility.
	var glow := OmniLight3D.new()
	glow.omni_range = 4.0
	glow.light_energy = 0.6
	glow.light_color = Color(0.6, 0.8, 0.95)
	glow.shadow_enabled = false
	glow.position = Vector3(0, 1.2, 0.3)
	add_child(glow)

## Prefers 6-12m; backs off if the player closes in.
func _chase_target(player: Node3D) -> Vector3:
	var d := global_position.distance_to(player.global_position)
	if d < 5.0:
		return global_position + (global_position - player.global_position)
	if d > 12.0:
		return player.global_position
	return global_position   # hold ground and shoot

func _species_process(delta: float) -> void:
	if state != AIState.CHASE or dormant:
		return
	var pl = GameManager.player
	if pl == null:
		return
	var d: float = global_position.distance_to(pl.global_position)
	_spit_cd -= delta
	_web_cd -= delta
	if _spit_cd <= 0.0 and d >= 4.0 and d <= 18.0 and _has_los(pl):
		_spit_cd = 2.4
		_flash(Color(0.7, 0.9, 1.0))   # glass-click telegraph
		AudioManager.play_at("crit", global_position, get_parent(), 1.6)
		var BossProjectile := load("res://scripts/bosses/BossProjectile.gd")
		var p = BossProjectile.new()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(0, 1.3, 0)
		p.setup((pl.global_position + Vector3.UP - p.global_position).normalized(),
			11.0, damage * 0.7, Color(0.65, 0.85, 1.0))
	if _web_cd <= 0.0 and d <= 10.0:
		_web_cd = 7.0
		_lay_web(pl.global_position)

## Slowing web patch under the player's feet (telegraphed by its glow).
func _lay_web(at: Vector3) -> void:
	var web := Area3D.new()
	web.collision_layer = 0
	web.collision_mask = 0b10
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.8
	shape.height = 1.0
	col.shape = shape
	web.add_child(col)
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.8
	cyl.bottom_radius = 1.8
	cyl.height = 0.05
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.85, 0.95, 1.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.85, 1.0)
	mesh.material_override = mat
	web.add_child(mesh)
	get_parent().add_child(web)
	web.global_position = Vector3(at.x, 0.3, at.z)
	web.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player") and body.has_method("apply_slow"):
			body.call("apply_slow", 0.55, 2.0))
	# Webs decay after 8s.
	var t := get_tree().create_timer(8.0, false)
	t.timeout.connect(func():
		if is_instance_valid(web):
			web.queue_free())
