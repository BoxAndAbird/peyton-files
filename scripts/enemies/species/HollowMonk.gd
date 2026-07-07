extends "res://scripts/enemies/EnemyBase.gd"
## Hollow Monk (Appendix E.9) - robed cave cult remnant; caster/teleporter.
## Identity: holds range and casts CURSE BOLTS (damage + sanity erosion,
## reversed chanting as the tell). If the player closes in it TELEPORTS away
## in a burst of dark. Periodically summons a shadow parasite through a
## sigil. Counterplay: close pressure and INTERRUPTS - any damage during the
## 0.9s cast cancels it and staggers him. Lore carrier; drops relics.
## Attack timing per E.9 row 1: windup 0.47 / recovery 0.48 / damage 36.

var _cast_cd := 2.0
var _casting := false
var _cast_left := 0.0
var _blink_cd := 0.0
var _summon_cd := 10.0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 1.8            # weak staff jab fallback
	damage = 36.0 * pow(1.10, RunManager.stage_index)

## Holds 8-12m; drifts rather than charges.
func _chase_target(player: Node3D) -> Vector3:
	var d := global_position.distance_to(player.global_position)
	if d > 12.0:
		return player.global_position
	if d < 7.0:
		return global_position + (global_position - player.global_position)
	return global_position

func _species_process(delta: float) -> void:
	if dormant or state == AIState.DEAD:
		return
	_cast_cd -= delta
	_blink_cd -= delta
	_summon_cd -= delta
	var pl = GameManager.player
	if pl == null:
		return
	var d: float = global_position.distance_to(pl.global_position)

	# Blink away from close pressure.
	if d < 4.0 and _blink_cd <= 0.0 and state == AIState.CHASE:
		_blink_cd = 5.0
		_blink(pl)

	# Curse bolt cast (interruptible channel).
	if _casting:
		velocity.x = 0.0
		velocity.z = 0.0
		_cast_left -= delta
		if _cast_left <= 0.0:
			_casting = false
			_fire_curse_bolt(pl)
		return
	if state == AIState.CHASE and _cast_cd <= 0.0 and d <= 18.0 and _has_los(pl):
		_cast_cd = 3.2
		_casting = true
		_cast_left = 0.9
		_flash(Color(0.6, 0.3, 0.8))
		AudioManager.play_at("hurt", global_position, get_parent(), 0.6)  # reversed chant
	# Sigil summon: a parasite crawls out of the floor.
	if state == AIState.CHASE and _summon_cd <= 0.0:
		_summon_cd = 14.0
		var e = EnemyFactory.create("shadow_parasite")
		get_parent().add_child(e)
		e.global_position = global_position + Vector3(randf_range(-2, 2), 0.4, randf_range(-2, 2))
		e.setup("shadow_parasite", RunManager.stage_index)
		EventBus.enemy_spawned.emit(e)
		EventBus.subtitle_requested.emit("A sigil flares on the stone.", 1.5)

func _fire_curse_bolt(pl) -> void:
	var BossProjectile := load("res://scripts/bosses/BossProjectile.gd")
	var p = BossProjectile.new()
	get_parent().add_child(p)
	p.global_position = global_position + Vector3(0, 1.6, 0)
	p.setup((pl.global_position + Vector3.UP - p.global_position).normalized(),
		12.0, damage * 0.6, Color(0.55, 0.25, 0.75), 4.0)   # + sanity erosion

func _blink(pl) -> void:
	AudioManager.play_at("dodge", global_position, get_parent(), 0.4)
	var away: Vector3 = (global_position - pl.global_position)
	away.y = 0.0
	if away.length() < 0.5:
		away = Vector3(1, 0, 0)
	global_position += away.normalized() * 8.0 \
		+ Vector3(randf_range(-2, 2), 0.0, randf_range(-2, 2))
	global_position.y = 0.5
	_flash(Color(0.2, 0.1, 0.3))

## Any damage during the cast interrupts it (the stated counterplay).
func take_damage(amount: float, source: Node = null) -> void:
	if _casting:
		_casting = false
		_cast_cd = 4.0
		_poise = POISE_MAX     # force the stagger: a real punish window
		EventBus.subtitle_requested.emit("The chant dies in his throat.", 1.5)
	super.take_damage(amount, source)

## Lore carrier: better relic chance on death (bible: "drops relics").
func die() -> void:
	if not is_hallucination and randf() < 0.35:
		var Pickup := load("res://scripts/items/Pickup.gd")
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var ip = Pickup.new()
		ip.setup_item(Database.roll_item_id(rng, 8.0))
		get_parent().add_child(ip)
		ip.global_position = global_position + Vector3(0.5, 0.4, -0.5)
	super.die()
