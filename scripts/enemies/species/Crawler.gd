extends "res://scripts/enemies/EnemyBase.gd"
## Crawler (Appendix E.1) - small pale cave predator; ambush swarm.
## Identity: fast rush + LEAP BITE, and PACK AGGRESSION - when one crawler
## spots the player, every crawler within 8m joins the chase (spawns in
## groups; teaches crowd control). Weak to fire and knockback.
## Attack timing per E.1 row 1: windup 0.47 / recovery 0.48 / damage 12.

func _species_setup() -> void:
	add_to_group("crawlers")
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 2.1        # slightly long: the bite is a short leap
	damage = 12.0 * pow(1.10, RunManager.stage_index)

func _on_state_entered(s: int) -> void:
	if s == AIState.CHASE:
		# Pack aggression: chitter and wake the swarm.
		AudioManager.play_at("footstep", global_position, get_parent(), 1.6)
		for other in get_tree().get_nodes_in_group("crawlers"):
			var o3 := other as Node3D
			if o3 == null or o3 == self:
				continue
			if o3.global_position.distance_to(global_position) < 8.0 \
					and o3.has_method("join_pack_chase"):
				o3.call("join_pack_chase")

func join_pack_chase() -> void:
	if state == AIState.IDLE or state == AIState.PATROL or state == AIState.INVESTIGATE:
		_enter_state(AIState.CHASE)

## Leap bite: a short hop toward the player during the active frames.
func _perform_attack() -> void:
	var pl = GameManager.player
	if pl == null:
		return
	var to: Vector3 = pl.global_position - global_position
	to.y = 0.0
	if to.length() > 0.2:
		velocity = to.normalized() * 7.0   # the leap itself
		velocity.y = 3.0
	super._perform_attack()
