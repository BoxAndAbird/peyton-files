extends "res://scripts/enemies/EnemyBase.gd"
## Faceless Echo (Appendix E.10) - a copy of the player's silhouette; the
## adaptive duel enemy and strongest psychological threat.
## Identity: it wears YOUR class - body tinted your class color, fights with
## your weapon's cadence (fast combos for daggers/sword, heavy singles for
## hammer, and it KEEPS DISTANCE and 'shoots' if you're an Archer). It
## SIDESTEPS like a player dodging, and at half health it enrages with your
## own haste. Muffled player voice. Counterplay: exploit your class's own
## weakness - it shares it.
## Attack timing per E.10 row 1: windup 0.47 / recovery 0.48 / damage 39.

var _sidestep_cd := 0.0
var _enraged_half := false
var _mirror_kind := "melee_light"

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	damage = 39.0 * pow(1.10, RunManager.stage_index)
	# Mirror the player's class.
	var cls := Database.get_class_data(RunManager.class_id)
	_mirror_kind = String(cls["weapon_kind"])
	if _mat:
		# Player-color body, but wrong - desaturated and too dark.
		var c: Color = cls["color"]
		_mat.albedo_color = Color(c.r * 0.5, c.g * 0.5, c.b * 0.5)
	match _mirror_kind:
		"melee_heavy":
			attack_windup = 0.83   # E.10 row 4 timing for heavy swings
			attack_range = 2.6
			damage *= 1.25
		"ranged":
			attack_range = 1.8     # melee fallback; prefers shooting
		_:
			attack_range = 2.2

## Archer echoes keep distance like their original.
func _chase_target(player: Node3D) -> Vector3:
	if _mirror_kind == "ranged":
		var d := global_position.distance_to(player.global_position)
		if d < 6.0:
			return global_position + (global_position - player.global_position)
		if d > 14.0:
			return player.global_position
		return global_position
	return player.global_position

func _species_process(delta: float) -> void:
	if dormant or state != AIState.CHASE:
		return
	var pl = GameManager.player
	if pl == null:
		return
	_sidestep_cd -= delta
	var d: float = global_position.distance_to(pl.global_position)
	# Player-like sidestep when you square up on it.
	if _sidestep_cd <= 0.0 and d < 5.0:
		_sidestep_cd = 2.5
		var side: Vector3 = (pl.global_position - global_position).cross(Vector3.UP).normalized()
		if randf() < 0.5:
			side = -side
		velocity += side * 7.0
		AudioManager.play_at("dodge", global_position, get_parent(), 0.8)
	# Archer echo: shoots back from range.
	if _mirror_kind == "ranged" and _attack_timer <= 0.0 and d >= 5.0 and d <= 16.0 and _has_los(pl):
		_attack_timer = 1.6
		var BossProjectile := load("res://scripts/bosses/BossProjectile.gd")
		var p = BossProjectile.new()
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(0, 1.4, 0)
		p.setup((pl.global_position + Vector3.UP - p.global_position).normalized(),
			14.0, damage * 0.55, Color(0.4, 0.4, 0.45))
		AudioManager.play_at("dodge", global_position, get_parent(), 1.9)

## Light-weapon echoes swing in quick two-hit combos, like you do.
func _perform_attack() -> void:
	super._perform_attack()
	if _mirror_kind == "melee_light" and not is_hallucination:
		var t := get_tree().create_timer(0.3, false)
		t.timeout.connect(func():
			if state != AIState.DEAD and GameManager.player:
				var d: float = global_position.distance_to(GameManager.player.global_position)
				if d <= attack_range + 0.5:
					GameManager.player.take_damage(damage * 0.6, self))

## At half health it borrows your haste (enrage, muffled voice).
func take_damage(amount: float, source: Node = null) -> void:
	super.take_damage(amount, source)
	if not _enraged_half and hp > 0.0 and hp <= max_hp * 0.5:
		_enraged_half = true
		move_speed *= 1.3
		attack_recovery *= 0.7
		_flash(Color(0.9, 0.9, 1.0))
		AudioManager.play_at("hurt", global_position, get_parent(), 0.7)  # muffled voice
		EventBus.subtitle_requested.emit("It moves the way you move.", 2.0)
