extends Area3D
## Pickup.gd - walk-over collectible (essence, heals; items come later).
## Kinds:
##   "essence" - adds `value` cave essence (run currency)
##   "heal"    - restores `value` health
## Emits EventBus.item_picked_up for future inventory kinds.
## Visual: small spinning emissive gem, in-engine placeholder.

var kind := "essence"
var value := 5.0
var _taken := false

func setup(p_kind: String, p_value: float) -> void:
	kind = p_kind
	value = p_value
	collision_layer = 0
	collision_mask = 0b10        # detects the player (layer 2)
	monitoring = true

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	col.shape = shape
	add_child(col)

	var mesh := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.3, 0.45, 0.3)
	mesh.mesh = pm
	mesh.position = Vector3(0, 0.35, 0)
	var mat := StandardMaterial3D.new()
	var color := Color(0.95, 0.85, 0.35) if kind == "essence" else Color(0.85, 0.3, 0.3)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.6
	mesh.material_override = mat
	add_child(mesh)

	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	rotate_y(delta * 2.0)

func _on_body(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	AudioManager.play("pickup")
	match kind:
		"essence":
			RunManager.add_essence(int(value))
			SaveManager.statistics["items_collected"] = int(SaveManager.statistics["items_collected"]) + 1
		"heal":
			if body.has_method("heal"):
				body.call("heal", value)   # call(): body is typed Node3D
	EventBus.item_picked_up.emit(kind)
	queue_free()
