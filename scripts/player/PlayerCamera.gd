class_name PlayerCamera
extends Node3D
## PlayerCamera.gd - third-person over-shoulder rig (bible section 6).
## Structure (built in code by PlayerController):
##   Yaw (this node, child of player) -> Pitch (Node3D) -> SpringArm3D -> Camera3D
##
## Reads SettingsManager each frame-of-change: mouse_sensitivity, invert_y, fov,
## camera_shake. Applies trauma-based shake; systems call add_trauma(0..1).
##
## Integration: PlayerController reads `basis` of the yaw node for
## camera-relative movement.

var pitch_node: Node3D
var arm: SpringArm3D
var camera: Camera3D

var _pitch := -0.18
var _trauma := 0.0
const PITCH_MIN := -1.25
const PITCH_MAX := 0.7

func _ready() -> void:
	pitch_node = Node3D.new()
	pitch_node.name = "Pitch"
	add_child(pitch_node)
	pitch_node.rotation.x = _pitch

	arm = SpringArm3D.new()
	arm.name = "Arm"
	arm.spring_length = 4.2
	arm.position = Vector3(0.55, 0.35, 0)   # over-shoulder offset
	arm.collision_mask = 1                   # collide with world only
	pitch_node.add_child(arm)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.fov = SettingsManager.fov()
	camera.near = 0.05
	arm.add_child(camera)
	camera.make_current()

	EventBus.settings_applied.connect(_on_settings)

func _on_settings(_s: Dictionary) -> void:
	if camera:
		camera.fov = SettingsManager.fov()

## Mouse-look; called from PlayerController._unhandled_input.
func apply_look(relative: Vector2) -> void:
	var sens := 0.0022 * SettingsManager.mouse_sensitivity()
	rotation.y -= relative.x * sens
	var y := relative.y * sens * (-1.0 if SettingsManager.invert_y() else 1.0)
	_pitch = clampf(_pitch - y, PITCH_MIN, PITCH_MAX)
	pitch_node.rotation.x = _pitch

## Controller right-stick look; called from PlayerController._physics_process.
func apply_stick(axis: Vector2, delta: float) -> void:
	if axis.length_squared() < 0.04:
		return
	var sens := 2.4 * SettingsManager.mouse_sensitivity()
	rotation.y -= axis.x * sens * delta
	var y := axis.y * sens * delta * (-1.0 if SettingsManager.invert_y() else 1.0)
	_pitch = clampf(_pitch - y, PITCH_MIN, PITCH_MAX)
	pitch_node.rotation.x = _pitch

## Trauma shake: hits/explosions call add_trauma; decays quadratically.
func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(_trauma - delta * 1.4, 0.0)
		var shake := _trauma * _trauma * SettingsManager.camera_shake_scale()
		camera.h_offset = randf_range(-0.25, 0.25) * shake
		camera.v_offset = randf_range(-0.2, 0.2) * shake
		camera.rotation.z = randf_range(-0.03, 0.03) * shake
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.rotation.z = 0.0

## Forward direction on the ground plane, for camera-relative movement.
func flat_forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()

func flat_right() -> Vector3:
	var r := global_transform.basis.x
	r.y = 0.0
	return r.normalized()
