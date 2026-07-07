extends "res://scripts/enemies/EnemyBase.gd"
## Watcher (Appendix E.7) - tall shadow statue; line-of-sight horror.
## Identity: MOVES ONLY WHEN UNSEEN - and then terrifyingly fast. Watched,
## it is a statue (darker, utterly still, silent). Its GRAB hits hard but
## the doc forbids unfair one-shots - it is scare pressure, and keeping it
## in view is the whole counterplay. After taking three hits it VANISHES
## and reappears elsewhere with a stone scrape.
## Attack timing per E.7 row 1: windup 0.47 / recovery 0.48 / damage 30.

const UNSEEN_SPEED_MULT := 1.7

var _hits_taken := 0
var _frozen := false

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 2.2
	damage = 30.0 * pow(1.10, RunManager.stage_index)
	# Cap: never more than ~60% of the player's health in one grab (no
	# unfair one-shots, per the doc).
	damage = minf(damage, 55.0)

func _chase_speed(player) -> float:
	var seen := _player_sees_me(player)
	if seen != _frozen:
		_frozen = seen
		if seen:
			# Stone scrape as it locks into statue form (audio identity).
			AudioManager.play_at("footstep", global_position, get_parent(), 0.4)
			if _mat:
				_mat.albedo_color = Color(0.08, 0.08, 0.1)
		else:
			if _mat:
				_mat.albedo_color = data["color"]
	return 0.0 if seen else move_speed * UNSEEN_SPEED_MULT

## Three hits and it refuses to be pinned down: vanish, reappear elsewhere.
func take_damage(amount: float, source: Node = null) -> void:
	super.take_damage(amount, source)
	if state == AIState.DEAD:
		return
	_hits_taken += 1
	if _hits_taken >= 3:
		_hits_taken = 0
		_vanish()

func _vanish() -> void:
	AudioManager.play_at("footstep", global_position, get_parent(), 0.3)
	var ang := randf() * TAU
	var offset := Vector3(cos(ang), 0.0, sin(ang)) * randf_range(6.0, 10.0)
	global_position += offset
	global_position.y = 0.5
	_flash(Color(0.0, 0.0, 0.0))
	EventBus.subtitle_requested.emit("Stone scrapes against stone.", 1.5)
