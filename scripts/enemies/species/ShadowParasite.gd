extends "res://scripts/enemies/EnemyBase.gd"
## Shadow Parasite (Appendix E.8) - small black leech spirit; attrition and
## status pressure. Identity: it does not bite - it ATTACHES, draining health
## AND sanity over five seconds ("whisper under skin"). DODGE-ROLLING SCRAPES
## IT OFF (the doc's counterplay), burn kills it outright, and helpers can
## cleanse. Forces resource management rather than reflexes.
## Attack timing per E.8 row 1: windup 0.47 / recovery 0.48 (drain replaces
## flat damage).

const DRAIN_DURATION := 5.0
const DRAIN_HP_PER_TICK := 2.0
const DRAIN_SANITY_PER_TICK := 1.2

var _attached := false
var _drain_left := 0.0
var _tick := 0.0

func _species_setup() -> void:
	attack_windup = 0.47
	attack_recovery = 0.48
	attack_range = 1.6
	retreat_time = 2.5

## The "attack" is the attach: it melts into the player's shadow.
func _perform_attack() -> void:
	if _attached:
		return
	var pl = GameManager.player
	if pl == null or is_hallucination:
		super._perform_attack()
		return
	if global_position.distance_to(pl.global_position) <= attack_range + 0.5:
		_attach()

func _attach() -> void:
	_attached = true
	_drain_left = DRAIN_DURATION
	_tick = 0.0
	visible = false
	collision_layer = 0            # unhittable while under the skin
	EventBus.subtitle_requested.emit("Something whispers under your skin. DODGE to scrape it off!", 3.0)
	AudioManager.play("hurt", "SFX", 0.5)

func _species_process(delta: float) -> void:
	if not _attached:
		return
	velocity = Vector3.ZERO
	var pl = GameManager.player
	if pl == null:
		_detach(false)
		return
	# Ride the player.
	global_position = pl.global_position
	# Dodge-roll scrapes it off (core counterplay).
	if pl.has_method("is_dodging_iframes") and pl.is_dodging_iframes():
		_detach(true)
		return
	_drain_left -= delta
	_tick += delta
	if _tick >= 1.0:
		_tick = 0.0
		pl.take_damage(DRAIN_HP_PER_TICK, self)
		var sm = GameManager.current_stage.get_node_or_null("SanityManager") if GameManager.current_stage else null
		if sm:
			# Cave Salt items weaken parasites (bible item note).
			var drain := DRAIN_SANITY_PER_TICK
			if String(RunManager.equipped.get("accessory", "")).begins_with("item"):
				var item := Database.get_item(String(RunManager.equipped["accessory"]))
				if String(item.get("stat", "")) == "sanity":
					drain *= 0.5
			sm.set_sanity(sm.sanity - drain)
	if _drain_left <= 0.0:
		_detach(false)

func _detach(scraped: bool) -> void:
	_attached = false
	visible = true
	collision_layer = 0b100
	var pl = GameManager.player
	if pl:
		var ang := randf() * TAU
		global_position = pl.global_position + Vector3(cos(ang), 0.3, sin(ang)) * 2.0
	if scraped:
		EventBus.subtitle_requested.emit("You scrape it off.", 1.5)
		_poise = POISE_MAX
		take_damage(10.0)          # scraping hurts it and staggers it
	else:
		_enter_state(AIState.RETREAT)

## Burn kills it outright (its stated weakness), even mid-drain.
func apply_burn(_tick_damage: float, _duration: float) -> void:
	if _attached:
		_detach(true)
	die()
