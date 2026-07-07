extends StaticBody3D
## Interactable.gd - generic world interaction target (doors, gates, helpers).
## Joins the "interactables" group; PlayerController finds the nearest one in
## range, shows "[E] <prompt>", and calls interact(player) on the action.
##
## Configure with setup(); behavior is injected via the `on_interact` Callable
## so gates/shops/shrines share this one script.
##
## Visual: emissive placeholder box (in-engine art per the output contract).

var prompt := "Interact"
var on_interact: Callable = Callable()
var one_shot := true
var _used := false
var _mesh: MeshInstance3D

func setup(p_prompt: String, color: Color, size: Vector3) -> void:
	prompt = p_prompt
	collision_layer = 0b100000   # layer 6: interactable
	collision_mask = 0
	add_to_group("interactables")

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	add_child(col)

	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	_mesh.mesh = bm
	_mesh.position = Vector3(0, size.y * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	_mesh.material_override = mat
	add_child(_mesh)

func prompt_text() -> String:
	return prompt

func interact(player: Node) -> void:
	if _used and one_shot:
		return
	_used = one_shot
	AudioManager.play("pickup")
	if on_interact.is_valid():
		on_interact.call(player)
	if _used:
		remove_from_group("interactables")
		var mat := _mesh.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.2
