class_name StatsComponent
extends Node
## StatsComponent.gd - stores and recalculates player stats (bible section 21).
## Final stats = class base + upgrade modifiers + item modifiers (from
## RunManager.aggregate_modifiers()). Pure data; owner (PlayerController)
## queries it every time it needs a value, so recalculation is instant.
##
## Signals:
##   stats_recalculated(snapshot)  - also mirrored to EventBus.player_stats_changed.

signal stats_recalculated(snapshot: Dictionary)

var class_id := "swordsman"
var base: Dictionary = {}      # class base stats
var final: Dictionary = {}     # base + modifiers

func setup(p_class_id: String) -> void:
	class_id = p_class_id
	base = Database.get_class_data(class_id)["base_stats"].duplicate()
	recalculate()

## Re-apply upgrades + equipment. Call after any pick/equip change.
func recalculate() -> void:
	final = base.duplicate()
	var mods := RunManager.aggregate_modifiers()
	for stat in mods.keys():
		if stat == "sanity":
			continue  # sanity modifiers are handled by SanityManager
		final[stat] = float(final.get(stat, 0.0)) + float(mods[stat])
	# Conditional upgrade: Stoneblood (defense when strength >= 6).
	if RunManager.active_tags().has("str_defense") and float(final.get("strength", 0)) >= 6.0:
		final["defense"] = float(final.get("defense", 0.0)) + 3.0
	stats_recalculated.emit(final.duplicate())
	EventBus.player_stats_changed.emit(final.duplicate())

# --- typed getters (never KeyError) ----------------------------------
func stat(name: String) -> float:
	return float(final.get(name, 0.0))

func max_health() -> float:
	return Database.max_health(stat("health"), 0.0)

func max_stamina() -> float:
	return Database.max_stamina(stat("stamina"))

func move_speed(base_speed: float) -> float:
	return Database.move_speed(base_speed, stat("speed"))

func weapon_damage() -> float:
	var wep := Database.get_weapon(Database.get_class_data(class_id)["weapon"])
	return Database.weapon_damage(wep["base_damage"], stat("strength"))

func attack_rate() -> float:
	var wep := Database.get_weapon(Database.get_class_data(class_id)["weapon"])
	return float(wep["rate"]) * Database.attack_rate_mult(stat("speed"))

func crit_chance() -> float:
	var c := stat("crit")
	# Embrace Madness: low sanity gives crit (checked against HUD sanity value
	# via RunManager.carry_sanity which SanityManager keeps fresh).
	if RunManager.active_tags().has("low_sanity_crit") and RunManager.carry_sanity < 40.0:
		c += 15.0
	return c

func damage_taken(incoming: float) -> float:
	return Database.damage_after_defense(incoming, stat("defense"))
