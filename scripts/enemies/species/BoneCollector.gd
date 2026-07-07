extends "res://scripts/enemies/EnemyBase.gd"
## Bone Collector (Appendix E.6) - corpse-armored brute; scaling tank.
## Identity: every death near it (within 12m) is bones for its armor - each
## stack reduces damage taken 15% (max 4) and visibly bulks it up. BURN
## STRIPS ARMOR (its explicit weakness). Up close it delivers a GROUND SLAM
## ring. Bone rattle on every stack. "Gets stronger near corpses if not
## stopped."
## Attack timing per E.6 row 1: windup 0.47 / recovery 0.48 / damage 27.

const MAX_STACKS := 4

var armor_stacks := 0
var _slam_cd := 0.0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 2.4
	damage = 27.0 * pow(1.10, RunManager.stage_index)
	EventBus.enemy_died.connect(_on_nearby_death)

func _on_nearby_death(enemy: Node, world_pos: Vector3) -> void:
	if state == AIState.DEAD or enemy == self or armor_stacks >= MAX_STACKS:
		return
	if global_position.distance_to(world_pos) <= 12.0:
		armor_stacks += 1
		scale = Vector3.ONE * (1.0 + armor_stacks * 0.06)
		_flash(Color(0.95, 0.92, 0.8))
		AudioManager.play_at("footstep", global_position, get_parent(), 0.5)
		EventBus.subtitle_requested.emit("Bones rattle onto its shoulders.", 1.5)

## Armor stacks soak damage; the stagger poise still builds from raw damage.
func take_damage(amount: float, source: Node = null) -> void:
	super.take_damage(amount * pow(0.85, armor_stacks), source)

## Burn strips armor instead of just ticking (its stated weakness).
func apply_burn(tick_damage: float, duration: float) -> void:
	if armor_stacks > 0:
		armor_stacks -= 1
		scale = Vector3.ONE * (1.0 + armor_stacks * 0.06)
		EventBus.subtitle_requested.emit("The fire sheds its bone plate!", 1.5)
	super.apply_burn(tick_damage, duration)

## Ground slam: telegraphed ring when the player hugs it.
func _perform_attack() -> void:
	var pl = GameManager.player
	if pl == null or is_hallucination:
		super._perform_attack()
		return
	if _slam_cd <= 0.0 and global_position.distance_to(pl.global_position) <= attack_range + 1.0:
		_slam_cd = 5.0
		AudioManager.play_at("hit", global_position, get_parent(), 0.4)
		var d: float = global_position.distance_to(pl.global_position)
		if d <= 3.4:
			pl.take_damage(damage * 1.2, self)
			if pl.cam:
				pl.cam.add_trauma(0.5)
	else:
		super._perform_attack()

func _species_process(delta: float) -> void:
	_slam_cd = maxf(_slam_cd - delta, 0.0)
