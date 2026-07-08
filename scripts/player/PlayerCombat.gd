class_name PlayerCombat
extends Node
## PlayerCombat.gd - attack framework (bible sections 3, 5, 21).
## Owned by PlayerController. Handles:
##   - melee swings with an ACTIVE-FRAMES-ONLY hit window (QA: "hitboxes only
##     active during attack frames")
##   - ranged shots (Archer longbow) via pooled Projectile nodes
##   - crit rolls, burn application (Ash Oil tag), backstab bonus (Bandit)
## Emits through EventBus.damage_dealt so HUD numbers / stats / music react.
##
## Integration points:
##   player: PlayerController (parent, set in setup())
##   stats:  StatsComponent for damage/rate/crit queries

# NOTE: `player` is deliberately untyped (Variant). It is a PlayerController,
# but typing it CharacterBody3D would make duck-typed calls (facing_dir,
# aim_dir) compile errors under GDScript 2 strict member checking.
var player
var stats: StatsComponent

var _cooldown := 0.0
var _swing_active := false
var _swing_hit_targets: Array = []   # nodes already hit this swing
var _haste_timer := 0.0              # archer passive: crits grant haste
var _empowered := false              # swordsman passive: perfect-dodge bonus

func setup(p_player: CharacterBody3D, p_stats: StatsComponent) -> void:
	player = p_player
	stats = p_stats

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _haste_timer > 0.0:
		_haste_timer -= delta

func haste_active() -> bool:
	return _haste_timer > 0.0

## Swordsman passive hook: PlayerController calls this on a perfect dodge.
func empower_next_strike() -> void:
	_empowered = true

## Main entry: try to attack. Returns true if an attack started.
func try_attack() -> bool:
	if _cooldown > 0.0:
		return false
	# Tank guarding + attack = GUARD BASH (bible section 5: "Tank uses
	# stamina for guard bash").
	if stats.class_id == "tank" and player.get("guarding"):
		return _guard_bash()
	var rate := stats.attack_rate()
	if haste_active():
		rate *= 1.35
	_cooldown = 1.0 / maxf(rate, 0.05)
	var kind: String = Database.get_class_data(stats.class_id)["weapon_kind"]
	if kind == "ranged":
		_fire_projectile()
	else:
		_melee_swing()
	return true

## Tank guard bash: stamina-fueled shove that staggers and knocks back
## everything in the frontal arc. High poise pressure, modest damage.
func _guard_bash() -> bool:
	if player.stamina < 30.0:
		AudioManager.play_ui("denied")
		return false
	player.stamina -= 30.0
	_cooldown = 1.0
	AudioManager.play("hit", "SFX", 0.6)
	var origin: Vector3 = player.global_position + Vector3.UP * 1.0
	var forward: Vector3 = player.facing_dir()
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		var e3 := enemy as Node3D
		if e3 == null:
			continue
		var to: Vector3 = e3.global_position - origin
		to.y = 0.0
		if to.length() <= 3.0 and forward.dot(to.normalized()) > 0.3:
			_apply_hit(e3, 0.7)
			if e3.has_method("force_stagger"):
				e3.call("force_stagger")
			# Knockback (bible class table: Tank strengths include knockback).
			if e3 is CharacterBody3D:
				(e3 as CharacterBody3D).velocity += to.normalized() * 9.0 + Vector3.UP * 2.5
	if player.cam:
		player.cam.add_trauma(0.25)
	return true

## Archer charged shot (class passive: "charged shots pierce at high range
## stat"). charge 0..1 from holding aim; pierces 3 bodies when Range >= 6.
func fire_charged(charge: float) -> void:
	if player == null or not player.is_inside_tree():
		return
	_cooldown = 1.0 / maxf(stats.attack_rate(), 0.05)
	AudioManager.play("crit", "SFX", 0.8)
	var Projectile := load("res://scripts/player/Projectile.gd")
	var p = Projectile.new()
	player.get_parent().add_child(p)
	var aim: Vector3 = player.aim_dir()
	p.global_position = player.global_position + Vector3.UP * 1.3 + aim * 0.6
	p._speed = 34.0
	var pierce := 3 if stats.stat("range") >= 6.0 else 0
	p.launch(aim, Database.projectile_range(24.0, stats.stat("range")), self,
		pierce, 1.0 + charge)

# =====================================================================
#  MELEE
# =====================================================================
func _melee_swing() -> void:
	_swing_hit_targets.clear()
	_swing_active = true
	AudioManager.play("dodge", "SFX", randf_range(1.4, 1.7))
	var wep := Database.get_weapon(Database.get_class_data(stats.class_id)["weapon"])
	var reach: float = wep["reach"]
	# Active frames: 0.12s window starting 0.08s after input (windup).
	# create_timer(..., false): respect pause, or hits could land mid-pause.
	var windup := get_tree().create_timer(0.08, false)
	windup.timeout.connect(func():
		_do_melee_hits(reach)
		var recover := get_tree().create_timer(0.12, false)
		recover.timeout.connect(func(): _swing_active = false))

func _do_melee_hits(reach: float) -> void:
	if player == null or not player.is_inside_tree():
		return
	var origin: Vector3 = player.global_position + Vector3.UP * 1.0
	var forward: Vector3 = player.facing_dir()
	for enemy in player.get_tree().get_nodes_in_group("enemies"):
		var e3 := enemy as Node3D
		if e3 == null or _swing_hit_targets.has(e3):
			continue
		var to: Vector3 = e3.global_position - origin
		to.y = 0.0
		# Big bodies (bosses) widen effective reach via the hit_radius meta.
		var pad := 0.6
		if e3.has_meta("hit_radius"):
			pad += float(e3.get_meta("hit_radius"))
		# In reach and within a ~100 degree frontal arc.
		if to.length() <= reach + pad and forward.dot(to.normalized()) > 0.34:
			_swing_hit_targets.append(e3)
			_apply_hit(e3, 1.0)

# =====================================================================
#  RANGED
# =====================================================================
func _fire_projectile() -> void:
	if player == null or not player.is_inside_tree():
		return
	AudioManager.play("dodge", "SFX", 2.0)
	var Projectile := load("res://scripts/player/Projectile.gd")
	var p = Projectile.new()   # untyped: dynamic launch() call below
	player.get_parent().add_child(p)
	var aim: Vector3 = player.aim_dir()
	p.global_position = player.global_position + Vector3.UP * 1.3 + aim * 0.6
	p.launch(aim, Database.projectile_range(18.0, stats.stat("range")), self)

## Projectile callback when it overlaps an enemy.
func projectile_hit(enemy: Node, mult := 1.0) -> void:
	_apply_hit(enemy, mult)

# =====================================================================
#  DAMAGE RESOLUTION
# =====================================================================
## `enemy` untyped: take_damage/apply_burn/staggered are duck-typed members.
func _apply_hit(enemy, mult: float) -> void:
	if not enemy.has_method("take_damage"):
		return
	var dmg := stats.weapon_damage() * mult

	# Swordsman empowered strike.
	if _empowered:
		dmg *= 1.5
		_empowered = false

	# Bandit passive: "attacks from behind OR FROM STEALTH gain bonus crit
	# and essence drops." Stealth = holding RMB sneak.
	if stats.class_id == "bandit" and enemy is Node3D:
		var enemy_fwd: Vector3 = -(enemy as Node3D).global_transform.basis.z
		var to_player: Vector3 = (player.global_position - (enemy as Node3D).global_position).normalized()
		var behind: bool = enemy_fwd.dot(to_player) < -0.3
		if behind or player.get("sneaking"):
			dmg *= 1.4
			RunManager.add_essence(1)

	# Crit roll.
	var is_crit := randf() * 100.0 < stats.crit_chance()
	if is_crit:
		dmg *= 1.75
		AudioManager.play("crit")
		if stats.class_id == "archer":
			_haste_timer = 2.5   # archer passive
	else:
		AudioManager.play("hit")

	# Executioner: +25% vs staggered.
	if RunManager.active_tags().has("stagger_bonus") and "staggered" in enemy and enemy.staggered:
		dmg *= 1.25

	enemy.take_damage(dmg, player)
	SaveManager.stat_add_damage(dmg)
	EventBus.damage_dealt.emit(player, enemy, dmg, is_crit)

	# Ash Oil: attacks apply burn ticks.
	if RunManager.active_tags().has("apply_burn") and enemy.has_method("apply_burn"):
		enemy.apply_burn(Database.burn_tick(stats.stat("burn")), 3.0)
