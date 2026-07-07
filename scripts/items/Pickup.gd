extends Area3D
## Pickup.gd - walk-over collectible.
## Kinds:
##   "essence" - adds `value` cave essence (run currency)
##   "heal"    - restores `value` health
##   "item"    - equipment from the 120-item pool (setup_item); goes to the
##               backpack. If the pack is full the pickup STAYS in the world.
## Visual: small spinning emissive gem; items use a rarity-colored crate.

var kind := "essence"
var value := 5.0
var item_id := ""
var _taken := false
var _full_notice_cd := 0.0

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

## Equipment pickup from the 120-item pool (rarity-colored crate).
func setup_item(p_item_id: String) -> void:
	item_id = p_item_id
	kind = "item"
	collision_layer = 0
	collision_mask = 0b10
	monitoring = true

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.9
	col.shape = shape
	add_child(col)

	var item := Database.get_item(item_id)
	var color: Color = Database.RARITY_COLORS.get(item.get("rarity", "common"), Color.WHITE)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.4, 0.4)
	mesh.mesh = box
	mesh.position = Vector3(0, 0.3, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	mesh.material_override = mat
	add_child(mesh)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	rotate_y(delta * 2.0)
	_full_notice_cd = maxf(_full_notice_cd - delta, 0.0)

func _on_body(body: Node3D) -> void:
	if _taken or not body.is_in_group("player"):
		return
	if kind == "item":
		if RunManager.add_item(item_id):
			_taken = true
			AudioManager.play("pickup")
			queue_free()
		elif _full_notice_cd <= 0.0:
			_full_notice_cd = 2.0
			AudioManager.play_ui("denied")
			EventBus.subtitle_requested.emit("Pack is full.", 1.5)
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
