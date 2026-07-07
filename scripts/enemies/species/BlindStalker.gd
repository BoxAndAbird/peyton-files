extends "res://scripts/enemies/EnemyBase.gd"
## Blind Stalker (Appendix E.2) - tall eyeless humanoid; sound-tracking hunter.
## Identity: it NEVER knows where you are - only where you last made noise.
## While chasing it moves to the last heard position; stand still and it
## loses you, sweeping the area with slow reaching motions. Wet breathing
## grows louder as it closes. Counterplay: crouch-walk pace, thrown noise
## (sprint elsewhere), burn.
## Attack timing per E.2 row 1: windup 0.59 / recovery 0.56 / damage 15.

var _last_heard := Vector3.ZERO
var _heard_recently := 0.0
var _breath_cd := 0.0

func _species_setup() -> void:
	attack_windup = 0.59
	attack_recovery = 0.56
	attack_range = 2.3          # long reaching lunge at the last sound
	damage = 15.0 * pow(1.10, RunManager.stage_index)
	_last_heard = global_position

func _on_heard_sound(pos: Vector3, loudness: float) -> void:
	if state == AIState.DEAD or dormant:
		return
	var d := global_position.distance_to(pos)
	if d <= detect_radius * loudness:
		_last_heard = pos
		_heard_recently = 4.0
		if state != AIState.CHASE:
			_investigate_pos = pos
			_enter_state(AIState.INVESTIGATE if d > 4.0 else AIState.CHASE)

## Hunts the SOUND, not the player (the core of its identity).
func _chase_target(_player: Node3D) -> Vector3:
	return _last_heard

func _species_process(delta: float) -> void:
	_heard_recently -= delta
	if state == AIState.CHASE:
		# Reached the last sound and heard nothing new: it loses the trail.
		if _heard_recently <= 0.0 and global_position.distance_to(_last_heard) < 1.5:
			_investigate_pos = _last_heard
			_enter_state(AIState.INVESTIGATE)
		# Wet breathing intensifies near the player (audio identity).
		_breath_cd -= delta
		var pl = GameManager.player
		if pl and _breath_cd <= 0.0 and global_position.distance_to(pl.global_position) < 7.0:
			_breath_cd = 1.4
			AudioManager.play_at("hurt", global_position, get_parent(), 0.35)
