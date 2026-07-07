extends "res://scripts/enemies/EnemyBase.gd"
## Mimic Cache (Appendix E.4) - loot-shaped parasite; trap enemy.
## Identity: pretends to be a chest (base class handles the disguise via
## "proximity" senses), delivers a brutal SNAP BITE, then after two bites
## FLEES and tries to re-disguise if it escapes far enough. Wood creak,
## then teeth. Counterplay: careful scanning, fire reveal.
## Attack timing per E.4 row 1: windup 0.47 / recovery 0.48 / damage 21.

var _bites := 0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 2.0
	retreat_time = 3.0
	damage = 21.0 * pow(1.10, RunManager.stage_index)

func _perform_attack() -> void:
	super._perform_attack()
	_bites += 1
	if _bites >= 2:
		_bites = 0
		AudioManager.play_at("hurt", global_position, get_parent(), 1.5)
		_enter_state(AIState.RETREAT)

func _species_process(_delta: float) -> void:
	# If it fled far enough, it goes quiet and re-disguises (re-ambush).
	if state == AIState.RETREAT and _revealed:
		var pl = GameManager.player
		if pl and global_position.distance_to(pl.global_position) > detect_radius * 1.2:
			_redisguise()

func _redisguise() -> void:
	_revealed = false
	if _body_mesh:
		_body_mesh.queue_free()
	_build_body()   # senses is "proximity" and _revealed false -> chest shape
	_enter_state(AIState.IDLE)
	EventBus.subtitle_requested.emit("The wood creaks somewhere out of sight.", 2.0)
