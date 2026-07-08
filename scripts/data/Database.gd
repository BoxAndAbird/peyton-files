extends Node
## Database.gd  (Autoload singleton: "Database")
##
## Single source of truth for all tunable gameplay data, kept as plain
## dictionaries (per the design bible: "keep all gameplay data in Resources or
## dictionaries so it can be tuned easily"). Dictionaries are used instead of
## .tres Resources so the whole dataset is human-readable in one file and has
## zero binary/UID fragility.
##
## Also hosts the pure stat FORMULAS from bible section 5 so every system
## computes damage/speed/etc. the same way.
##
## No dependencies on other autoloads -> safe to load early.

# =====================================================================
#  CLASSES  (bible section 4)
# =====================================================================
# base_stats keys map to the stat ids defined in STAT_DEFS below.
const CLASSES := {
	"archer": {
		"display_name": "Archer",
		"weapon": "longbow",
		"weapon_kind": "ranged",
		"role": "Fragile ranged survivor",
		"description": "High range, speed and precision; low health and weak up close. Crits grant 2.5s haste; charged shots pierce.",
		"passive_id": "archer_haste_crit",
		"color": Color(0.55, 0.78, 0.45),
		"base_stats": {
			"strength": 3, "speed": 6, "range": 8, "burn": 2,
			"health": 80, "defense": 2, "stamina": 5, "crit": 12, "luck": 4,
		},
	},
	"tank": {
		"display_name": "Tank",
		"weapon": "warhammer",
		"weapon_kind": "melee_heavy",
		"role": "Slow durable bruiser",
		"description": "Health, defense, stagger and knockback; slow and short-ranged. Standing still 0.75s grants Guarded (-25% damage until moving).",
		"passive_id": "tank_guarded",
		"color": Color(0.78, 0.5, 0.3),
		"base_stats": {
			"strength": 8, "speed": 3, "range": 2, "burn": 1,
			"health": 160, "defense": 8, "stamina": 7, "crit": 5, "luck": 3,
		},
	},
	"swordsman": {
		"display_name": "Swordsman",
		"weapon": "ironsword",
		"weapon_kind": "melee_light",
		"role": "Balanced duelist",
		"description": "Combo speed, parry and reliable DPS; requires timing. Perfect dodge/parry empowers the next strike and restores stamina.",
		"passive_id": "sword_counter",
		"color": Color(0.6, 0.66, 0.78),
		"base_stats": {
			"strength": 6, "speed": 5, "range": 3, "burn": 2,
			"health": 120, "defense": 5, "stamina": 6, "crit": 8, "luck": 4,
		},
	},
	"bandit": {
		"display_name": "Bandit",
		"weapon": "twindaggers",
		"weapon_kind": "melee_light",
		"role": "Fast critical assassin",
		"description": "Speed, crit, backstab and item luck; low defense and short range. Attacks from behind/stealth gain bonus crit and essence.",
		"passive_id": "bandit_backstab",
		"color": Color(0.7, 0.55, 0.75),
		"base_stats": {
			"strength": 5, "speed": 7, "range": 3, "burn": 2,
			"health": 95, "defense": 3, "stamina": 6, "crit": 18, "luck": 8,
		},
	},
}

const CLASS_ORDER := ["archer", "tank", "swordsman", "bandit"]

# =====================================================================
#  STAT DEFINITIONS  (bible section 5)
# =====================================================================
const STAT_DEFS := {
	"strength":  {"name": "Strength",  "desc": "Base damage scalar."},
	"speed":     {"name": "Speed",     "desc": "Movement, attack rate, stamina recovery."},
	"range":     {"name": "Range",     "desc": "Projectile distance, lock-on, aim assist."},
	"burn":      {"name": "Burn",      "desc": "Damage over time and fire utility."},
	"health":    {"name": "Health",    "desc": "Survivability (flat max HP contribution)."},
	"defense":   {"name": "Defense",   "desc": "Damage reduction."},
	"stamina":   {"name": "Stamina",   "desc": "Dodges, sprint, charged attacks."},
	"crit":      {"name": "Crit %",    "desc": "Critical hit chance."},
	"luck":      {"name": "Luck",      "desc": "Loot and shop quality."},
}

# =====================================================================
#  WEAPONS  (light data; visuals are placeholder meshes)
# =====================================================================
const WEAPONS := {
	"longbow":     {"name": "Longbow",      "kind": "ranged",      "base_damage": 14.0, "rate": 1.1, "reach": 0.0},
	"warhammer":   {"name": "War Hammer",   "kind": "melee_heavy", "base_damage": 34.0, "rate": 0.55, "reach": 2.6},
	"ironsword":   {"name": "Iron Sword",   "kind": "melee_light", "base_damage": 20.0, "rate": 1.4, "reach": 2.2},
	"twindaggers": {"name": "Twin Daggers", "kind": "melee_light", "base_damage": 12.0, "rate": 2.2, "reach": 1.8},
}

# =====================================================================
#  STAGES  (bible sections 7 & 8)
# =====================================================================
const STAGES := [
	{
		"id": "forgotten_entrance", "name": "Forgotten Entrance",
		"room_min": 12, "room_max": 14, "target_minutes": 9, "threat": 1.0,
		"biome": "entrance", "ambient": Color(0.10, 0.09, 0.07),
		"light_tint": Color(1.0, 0.85, 0.6), "fog": Color(0.06, 0.05, 0.04),
		"enemy_pool": ["crawler", "blind_stalker", "mimic"],
		"boss": "burrower",
		"objective": "Find the descent gate. Its guardian stirs below.",
	},
	{
		"id": "flooded_caverns", "name": "Flooded Caverns",
		"room_min": 14, "room_max": 16, "target_minutes": 10, "threat": 1.4,
		"biome": "flooded", "ambient": Color(0.06, 0.09, 0.12),
		"light_tint": Color(0.6, 0.8, 1.0), "fog": Color(0.05, 0.08, 0.11),
		"enemy_pool": ["crawler", "drowned", "tunnel_screamer", "crystal_spider"],
		"boss": "drowned_priest",
		"objective": "Restore the two pump wheels, then face what the water hides.",
	},
	{
		"id": "crystal_abyss", "name": "Crystal Abyss",
		"room_min": 16, "room_max": 18, "target_minutes": 11, "threat": 1.8,
		"biome": "crystal", "ambient": Color(0.09, 0.08, 0.12),
		"light_tint": Color(0.7, 0.7, 1.0), "fog": Color(0.07, 0.06, 0.10),
		"enemy_pool": ["crystal_spider", "watcher", "bone_collector", "blind_stalker"],
		"boss": "",  # elite gauntlet (bible: stage 3/4 may use elite gauntlets)
		"objective": "Shatter the three resonance crystals to reveal the way down.",
	},
	{
		"id": "living_depths", "name": "Living Depths",
		"room_min": 18, "room_max": 20, "target_minutes": 12, "threat": 2.3,
		"biome": "living", "ambient": Color(0.12, 0.05, 0.05),
		"light_tint": Color(1.0, 0.45, 0.4), "fog": Color(0.10, 0.03, 0.03),
		"enemy_pool": ["shadow_parasite", "hollow_monk", "faceless", "bone_collector"],
		"boss": "",  # elite gauntlet
		"objective": "Burn open the living seal. Survive what wakes.",
	},
	{
		"id": "hollow_mind", "name": "Hollow Mind",
		"room_min": 18, "room_max": 22, "target_minutes": 13, "threat": 3.0,
		"biome": "void", "ambient": Color(0.11, 0.11, 0.13),
		"light_tint": Color(0.9, 0.9, 0.95), "fog": Color(0.09, 0.09, 0.11),
		"enemy_pool": ["faceless", "watcher", "hollow_monk", "shadow_parasite", "tunnel_screamer"],
		"boss": "ancient_below",
		"objective": "Reach the memory altar. End this.",
	},
]

# =====================================================================
#  ENEMY BASELINE TABLE  (bible section 27)
# =====================================================================
const ENEMIES := {
	"crawler":         {"name": "Crawler",         "hp": 68,  "speed": 1.18, "damage": 11, "detect": 11.5, "threat": 1, "senses": "sight", "color": Color(0.8,0.78,0.72)},
	"blind_stalker":   {"name": "Blind Stalker",   "hp": 86,  "speed": 1.36, "damage": 14, "detect": 13.0, "threat": 2, "senses": "sound", "color": Color(0.55,0.55,0.5)},
	"crystal_spider":  {"name": "Crystal Spider",  "hp": 104, "speed": 1.54, "damage": 17, "detect": 14.5, "threat": 2, "senses": "sight", "color": Color(0.6,0.75,0.85)},
	"mimic":           {"name": "Mimic Cache",     "hp": 122, "speed": 1.72, "damage": 20, "detect": 16.0, "threat": 2, "senses": "proximity", "color": Color(0.55,0.4,0.25)},
	"tunnel_screamer": {"name": "Tunnel Screamer", "hp": 140, "speed": 1.90, "damage": 23, "detect": 17.5, "threat": 3, "senses": "sight", "color": Color(0.5,0.3,0.35)},
	"bone_collector":  {"name": "Bone Collector",  "hp": 158, "speed": 2.08, "damage": 26, "detect": 19.0, "threat": 4, "senses": "sight", "color": Color(0.85,0.82,0.7)},
	"watcher":         {"name": "Watcher",         "hp": 176, "speed": 2.26, "damage": 29, "detect": 20.5, "threat": 4, "senses": "sight_los", "color": Color(0.15,0.15,0.18)},
	"drowned":         {"name": "Drowned One",     "hp": 110, "speed": 1.30, "damage": 18, "detect": 13.0, "threat": 2, "senses": "sight", "color": Color(0.3,0.45,0.5)},
	"shadow_parasite": {"name": "Shadow Parasite", "hp": 60,  "speed": 2.4,  "damage": 8,  "detect": 12.0, "threat": 2, "senses": "sight", "color": Color(0.12,0.10,0.16)},
	"hollow_monk":     {"name": "Hollow Monk",     "hp": 150, "speed": 1.6,  "damage": 24, "detect": 18.0, "threat": 4, "senses": "sight", "color": Color(0.4,0.35,0.45)},
	"faceless":        {"name": "Faceless Echo",   "hp": 200, "speed": 2.2,  "damage": 30, "detect": 22.0, "threat": 5, "senses": "sight", "color": Color(0.2,0.2,0.22)},
}

# =====================================================================
#  BOSSES  (bible sections 11 & 28)
# =====================================================================
const BOSSES := {
	"burrower": {
		"name": "The Burrower", "hp": 900, "stage": 0,
		"phases": [1.0, 0.67, 0.34],
		"desc": "Massive blind worm that teaches arena awareness.",
		"script": "res://scripts/bosses/Burrower.gd",
		"tuning": {"lunge_dmg": 26.0, "sweep_dmg": 18.0, "rock_dmg": 22.0,
			"burrow_speed": 6.0, "exposed_time": 2.5},
	},
	"drowned_priest": {
		"name": "The Drowned Priest", "hp": 1200, "stage": 1,
		"phases": [1.0, 0.67, 0.34],
		"desc": "Corpse-priest controlling underground water.",
		"script": "res://scripts/bosses/DrownedPriest.gd",
		"tuning": {"bolt_dmg": 16.0, "slam_dmg": 24.0, "nova_dmg": 45.0,
			"flood_dps": 10.0, "chant_interrupt": 60.0},
	},
	"ancient_below": {
		"name": "The Ancient Below", "hp": 2600, "stage": 4,
		"phases": [1.0, 0.8, 0.6, 0.4, 0.2],
		"desc": "Cave intelligence using the player's own memories.",
		"script": "res://scripts/bosses/AncientBelow.gd",
		"tuning": {"shard_dmg": 15.0, "bolt_dmg": 20.0, "rock_dmg": 26.0},
	},
}

# =====================================================================
#  UPGRADE POOL  (bible section 12) - two mutually-exclusive picks/stage.
# =====================================================================
const UPGRADES := [
	{"id":"heavy_hands","name":"Heavy Hands","cat":"strength","rarity":"common","mods":{"strength":2,"speed":-1},"desc":"+2 Strength, -1 Speed."},
	{"id":"breaker","name":"Breaker","cat":"strength","rarity":"uncommon","mods":{},"tags":["armor_crack"],"desc":"Heavy attacks crack armor."},
	{"id":"executioner","name":"Executioner","cat":"strength","rarity":"rare","mods":{},"tags":["stagger_bonus"],"desc":"+25% damage to staggered foes."},
	{"id":"stoneblood","name":"Stoneblood","cat":"strength","rarity":"uncommon","mods":{},"tags":["str_defense"],"desc":"Gain defense when Strength >= 6."},
	{"id":"quickstep","name":"Quickstep","cat":"speed","rarity":"common","mods":{},"tags":["dodge_recovery"],"desc":"Dodge recovery -20%."},
	{"id":"runner_lungs","name":"Runner Lungs","cat":"speed","rarity":"common","mods":{},"tags":["sprint_cost"],"desc":"Sprint cost -25%."},
	{"id":"fleet_knife","name":"Fleet Knife","cat":"speed","rarity":"uncommon","mods":{},"tags":["dodge_haste"],"desc":"Attacks speed up after dodging."},
	{"id":"no_footprints","name":"No Footprints","cat":"speed","rarity":"uncommon","mods":{},"tags":["no_footprints"],"desc":"Half as loud while moving (sound-hunters struggle)."},
	{"id":"long_sight","name":"Long Sight","cat":"range","rarity":"common","mods":{"range":2},"desc":"Lock-on +6m."},
	{"id":"piercing_aim","name":"Piercing Aim","cat":"range","rarity":"uncommon","mods":{},"tags":["pierce_3"],"desc":"Every third shot pierces."},
	{"id":"safe_distance","name":"Safe Distance","cat":"range","rarity":"rare","mods":{},"tags":["far_damage"],"desc":"+damage beyond 10m."},
	{"id":"ash_oil","name":"Ash Oil","cat":"burn","rarity":"common","mods":{"burn":1},"tags":["apply_burn"],"desc":"Attacks apply burn."},
	{"id":"wildfire","name":"Wildfire","cat":"burn","rarity":"rare","mods":{},"tags":["burn_spread"],"desc":"Burning enemies spread low burn."},
	{"id":"red_ember","name":"Red Ember","cat":"burn","rarity":"uncommon","mods":{},"tags":["low_sanity_damage"],"desc":"+damage while sanity below 40."},
	{"id":"deep_breathing","name":"Deep Breathing","cat":"sanity","rarity":"common","mods":{},"tags":["sanity_loss_down"],"desc":"Sanity loss -15%."},
	{"id":"embrace_madness","name":"Embrace Madness","cat":"sanity","rarity":"rare","mods":{},"tags":["low_sanity_crit"],"desc":"Low sanity gives crit."},
	{"id":"clear_mind","name":"Clear Mind","cat":"sanity","rarity":"uncommon","mods":{},"tags":["halluc_fade"],"desc":"Hallucination enemies fade faster."},
	{"id":"memory_anchor","name":"Memory Anchor","cat":"sanity","rarity":"rare","mods":{},"tags":["anti_collapse"],"desc":"Once per stage prevent sanity collapse."},
	{"id":"sixth_pocket","name":"Sixth Pocket","cat":"utility","rarity":"common","mods":{},"tags":["extra_slot"],"desc":"Temporary bonus consumable slot."},
	{"id":"cartographer_mark","name":"Cartographer Mark","cat":"utility","rarity":"uncommon","mods":{},"tags":["reveal_exit"],"desc":"Reveal exit direction."},
	{"id":"merchant_credit","name":"Merchant Credit","cat":"utility","rarity":"common","mods":{},"tags":["shop_discount"],"desc":"First shop item half price."},
	{"id":"medic_pact","name":"Medic Pact","cat":"utility","rarity":"rare","mods":{},"tags":["boss_heal"],"desc":"Heal after each boss."},
	{"id":"vitality","name":"Vitality","cat":"utility","rarity":"common","mods":{"health":25},"desc":"+25 max Health."},
	{"id":"iron_skin","name":"Iron Skin","cat":"utility","rarity":"uncommon","mods":{"defense":3},"desc":"+3 Defense."},
	{"id":"cursed_bargain","name":"Cursed Bargain","cat":"utility","rarity":"cursed","mods":{"strength":3,"crit":10},"tags":["sanity_drain"],"desc":"Immediate power + permanent sanity drain."},
]

# Base item archetypes for the 120-item pool (bible section 13).
const ITEM_BASES := [
	{"name":"Rusty Pick","slot":"weapon","stat":"strength","note":"Starter melee fallback."},
	{"name":"Miner Boots","slot":"armor","stat":"speed","note":"Footstep volume -5%."},
	{"name":"Cracked Lantern Lens","slot":"relic","stat":"range","note":"Lantern cone slightly wider."},
	{"name":"Ash Rag","slot":"accessory","stat":"burn","note":"Burn duration +0.5s."},
	{"name":"Bone Charm","slot":"accessory","stat":"luck","note":"Small loot chance increase."},
	{"name":"Old Helmet","slot":"armor","stat":"defense","note":"Reduces falling rock damage."},
	{"name":"Wet Matchbox","slot":"relic","stat":"burn","note":"Can fail in flooded rooms."},
	{"name":"Silver Compass","slot":"accessory","stat":"range","note":"Points vaguely to exit."},
	{"name":"Black Rope","slot":"relic","stat":"speed","note":"Can escape one pit/trap."},
	{"name":"Cave Salt","slot":"accessory","stat":"sanity","note":"Weakens parasites."},
]

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "cursed"]
const RARITY_COLORS := {
	"common": Color(0.8,0.8,0.8), "uncommon": Color(0.5,0.85,0.5),
	"rare": Color(0.45,0.65,0.95), "epic": Color(0.75,0.5,0.9),
	"legendary": Color(0.95,0.75,0.35), "cursed": Color(0.85,0.3,0.35),
}
const RARITY_MULT := {"common":1.0,"uncommon":1.4,"rare":2.0,"epic":2.8,"legendary":3.8,"cursed":2.4}
# Base drop weights per rarity. Luck multiplies the above-common tiers but is
# soft-capped (bible: "never let luck guarantee legendaries").
const RARITY_WEIGHTS := {
	"common": 40.0, "uncommon": 25.0, "rare": 16.0,
	"epic": 9.0, "legendary": 4.0, "cursed": 6.0,
}

# ---------------------------------------------------------------------
#  ITEM POOL  (generated: 10 archetypes x 12 = 120, following the doc).
# ---------------------------------------------------------------------
var items: Array = []
var _items_by_rarity: Dictionary = {}   # rarity -> Array of item dicts
var _items_by_id: Dictionary = {}       # id -> item dict

func _ready() -> void:
	_build_item_pool()

func _build_item_pool() -> void:
	items.clear()
	_items_by_rarity.clear()
	_items_by_id.clear()
	for r in RARITIES:
		_items_by_rarity[r] = []
	for i in range(120):
		var base: Dictionary = ITEM_BASES[i % ITEM_BASES.size()]
		var rarity: String = RARITIES[i % RARITIES.size()]
		var item := {
			"id": "item_%03d" % (i + 1),
			"name": "%s %d" % [base["name"], i + 1],
			"slot": base["slot"],
			"rarity": rarity,
			"stat": base["stat"],
			"stat_value": int(round(RARITY_MULT[rarity])),
			"note": base["note"],
		}
		items.append(item)
		_items_by_rarity[rarity].append(item)
		_items_by_id[item["id"]] = item

## Item lookup that never crashes (empty dict for unknown ids).
func get_item(id: String) -> Dictionary:
	return _items_by_id.get(id, {})

## Luck-weighted random item id. Higher luck shifts weight toward better
## rarities with diminishing returns; commons always keep some weight.
func roll_item_id(rng: RandomNumberGenerator, luck: float) -> String:
	var boost := 1.0 + clampf(luck, 0.0, 20.0) * 0.05
	var weights := {}
	var total := 0.0
	for r in RARITIES:
		var w: float = RARITY_WEIGHTS[r]
		if r != "common":
			w *= boost
		weights[r] = w
		total += w
	var roll := rng.randf() * total
	var rarity: String = "common"
	for r in RARITIES:
		roll -= weights[r]
		if roll <= 0.0:
			rarity = r
			break
	var pool: Array = _items_by_rarity[rarity]
	return pool[rng.randi_range(0, pool.size() - 1)]["id"]

# =====================================================================
#  STAT FORMULAS  (bible section 5) - pure functions, used everywhere.
# =====================================================================
static func move_speed(base: float, speed_stat: float) -> float:
	# Hard cap at +75% move speed.
	return base * min(1.75, 1.0 + speed_stat * 0.035)

static func attack_rate_mult(speed_stat: float) -> float:
	return 1.0 + speed_stat * 0.025

static func weapon_damage(weapon_base: float, strength: float, flat := 0.0) -> float:
	return weapon_base * (1.0 + strength * 0.06) + flat

static func projectile_range(base: float, range_stat: float) -> float:
	return base + range_stat * 0.85

static func lock_range(base: float, range_stat: float) -> float:
	return base + range_stat * 0.4

static func burn_tick(burn_stat: float) -> float:
	return 1.0 + burn_stat * 0.35  # applied every 0.5s

static func max_health(class_base: float, health_bonus: float) -> float:
	return class_base + health_bonus

static func damage_after_defense(incoming: float, defense: float) -> float:
	return incoming * (100.0 / (100.0 + defense * 8.0))

static func max_stamina(stamina_stat: float) -> float:
	return 100.0 + stamina_stat * 8.0

# --- Lookups with safe fallbacks ------------------------------------
# (named get_class_data because get_class() is a native Object method)
func get_class_data(id: String) -> Dictionary:
	return CLASSES.get(id, CLASSES["swordsman"])

func get_weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, WEAPONS["ironsword"])

func get_enemy(id: String) -> Dictionary:
	return ENEMIES.get(id, ENEMIES["crawler"])

func get_stage(index: int) -> Dictionary:
	return STAGES[clampi(index, 0, STAGES.size() - 1)]

func stage_count() -> int:
	return STAGES.size()
