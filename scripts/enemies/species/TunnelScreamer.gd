extends "res://scripts/enemies/EnemyBase.gd"
## Tunnel Screamer (Appendix E.5) - mouth-covered crawler; disorientation
## support. Identity: a long RISING INHALE (the doc demands a clear telegraph
## for fairness - it visibly swells and brightens for a full second), then a
## SCREAM CONE that damages, briefly whites out the screen, and SUMMONS
## CRAWLERS. Counterplay: interrupt the windup (damage staggers it out) or
## simply leave the cone.
## Attack timing per E.5 row 1: windup 0.47 / recovery 0.48 / damage 24.

const SCREAM_RANGE := 8.0
const SCREAM_DOT := 0.5        # ~60 degree cone

var _scream_cd := 4.0
var _screaming := false
var _inhale_left := 0.0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 1.8          # weak melee fallback
	damage = 24.0 * pow(1.10, RunManager.stage_index)

func _species_process(delta: float) -> void:
	_scream_cd -= delta
	if _screaming:
		velocity.x = 0.0
		velocity.z = 0.0
		_inhale_left -= delta
		# Visible swell during the inhale (fair telegraph).
		var t := 1.0 - maxf(_inhale_left, 0.0)
		scale = Vector3.ONE * (1.0 + 0.25 * t)
		if _inhale_left <= 0.0:
			_screaming = false
			scale = Vector3.ONE
			_do_scream()
		return
	if state == AIState.CHASE and _scream_cd <= 0.0 and not dormant:
		var pl = GameManager.player
		if pl and global_position.distance_to(pl.global_position) <= SCREAM_RANGE + 1.0:
			_begin_scream()

func _begin_scream() -> void:
	_screaming = true
	_inhale_left = 1.0
	_scream_cd = 8.0
	_flash(Color(1.0, 0.3, 0.5))
	# Rising inhale (audio identity).
	AudioManager.play_at("hurt", global_position, get_parent(), 1.8)
	EventBus.subtitle_requested.emit("A rising inhale...", 1.0)

func _do_scream() -> void:
	AudioManager.play_at("hurt", global_position, get_parent(), 2.2)
	var pl = GameManager.player
	if pl == null or is_hallucination:
		return
	var to: Vector3 = pl.global_position - global_position
	var dist := to.length()
	to.y = 0.0
	var fwd := -global_transform.basis.z
	if dist <= SCREAM_RANGE and fwd.dot(to.normalized()) > SCREAM_DOT:
		pl.take_damage(damage, self)
		# Blind pulse: brief white-out (never total darkness - the inverse).
		var hud = GameManager.ui.get_hud() if GameManager.ui else null
		if hud and hud.has_method("flash_blind"):
			hud.flash_blind(1.1)
		if pl.cam:
			pl.cam.add_trauma(0.5)
	# Summon crawlers regardless (support role).
	for i in range(2):
		var e = EnemyFactory.create("crawler")
		get_parent().add_child(e)
		e.global_position = global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))
		e.setup("crawler", RunManager.stage_index)
		EventBus.enemy_spawned.emit(e)

## Damage during the inhale interrupts the scream (its core counterplay).
func take_damage(amount: float, source: Node = null) -> void:
	if _screaming:
		_screaming = false
		scale = Vector3.ONE
		_scream_cd = 5.0
		_poise = POISE_MAX   # force the stagger
	super.take_damage(amount, source)
