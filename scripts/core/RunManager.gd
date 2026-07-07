extends Node
## RunManager.gd  (Autoload singleton: "RunManager")
##
## Owns everything about the CURRENT run (bible section 21): seed + deterministic
## RNG, chosen class, current stage, the exactly-ten upgrade picks, essence and a
## serialisable snapshot for the continue feature.
##
## Deterministic seeds are a hard requirement (bible section 7): a per-stage RNG
## is derived from (seed, stage_index) so a bug can be reproduced exactly.
##
## Emits run/stage signals through EventBus; does not touch scenes directly
## (GameManager performs the actual scene swaps).

const UPGRADES_PER_STAGE := 2
const TOTAL_UPGRADES := 10  # bible: exactly ten choices resolved per run

var run_active := false
var seed_value := 0
var rng := RandomNumberGenerator.new()

var class_id := "swordsman"
var stage_index := 0
var upgrades: Array[String] = []      # chosen upgrade ids, capped at TOTAL_UPGRADES
var equipped: Dictionary = {}         # slot -> item_id (5 slots)
var essence := 0

# Persistent-across-stages resource state (health/sanity carry over).
var carry_health := -1.0              # -1 => full at next spawn
var carry_sanity := 100.0
var run_time := 0.0                   # seconds elapsed, for victory stats

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if run_active:
		run_time += delta

# --- Lifecycle -------------------------------------------------------
func start_new(new_class_id: String, new_seed := 0) -> void:
	class_id = new_class_id
	seed_value = new_seed if new_seed != 0 else randi()
	rng.seed = seed_value
	stage_index = 0
	upgrades.clear()
	equipped = {"weapon": "", "armor": "", "relic": "", "accessory": "", "consumable": ""}
	essence = 0
	carry_health = -1.0
	carry_sanity = 100.0
	run_time = 0.0
	run_active = true
	SaveManager.record_run_started()
	EventBus.run_started.emit(class_id, seed_value)

func end_run(victory: bool) -> void:
	run_active = false
	var summary := {
		"class_id": class_id, "stage_index": stage_index,
		"upgrades": upgrades.duplicate(), "seed": seed_value,
		"time": run_time, "victory": victory,
	}
	if victory:
		SaveManager.record_victory(run_time)
	else:
		SaveManager.record_death()
	SaveManager.clear_run()  # continue is invalidated on death/victory
	EventBus.run_ended.emit(victory, summary)

# --- Stage flow ------------------------------------------------------
## Deterministic RNG for the current stage so generation is reproducible.
func stage_rng() -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(seed_value) + "_stage_" + str(stage_index))
	return r

func advance_stage() -> bool:
	# Returns true if there is another stage, false if the run is complete.
	stage_index += 1
	if stage_index >= Database.stage_count():
		return false
	return true

func is_final_stage() -> bool:
	return stage_index >= Database.stage_count() - 1

func current_stage_data() -> Dictionary:
	return Database.get_stage(stage_index)

# --- Upgrades --------------------------------------------------------
func upgrades_remaining() -> int:
	return TOTAL_UPGRADES - upgrades.size()

func can_offer_upgrade() -> bool:
	return upgrades.size() < TOTAL_UPGRADES

func add_upgrade(upgrade_id: String) -> void:
	if upgrades.size() < TOTAL_UPGRADES:
		upgrades.append(upgrade_id)
		var s: Dictionary = SaveManager.statistics["upgrades_taken"]
		s[upgrade_id] = int(s.get(upgrade_id, 0)) + 1
		EventBus.upgrade_chosen.emit(upgrade_id)

## Aggregate stat modifiers contributed by all chosen upgrades + equipped items.
func aggregate_modifiers() -> Dictionary:
	var mods := {}
	for uid in upgrades:
		for up in Database.UPGRADES:
			if up["id"] == uid:
				for stat in up.get("mods", {}).keys():
					mods[stat] = float(mods.get(stat, 0.0)) + up["mods"][stat]
	for slot in equipped.keys():
		var iid: String = equipped[slot]
		if iid == "":
			continue
		for it in Database.items:
			if it["id"] == iid:
				mods[it["stat"]] = float(mods.get(it["stat"], 0.0)) + it["stat_value"]
	return mods

## Collect gameplay tags from upgrades (e.g. "apply_burn", "reveal_exit").
func active_tags() -> Array:
	var tags: Array = []
	for uid in upgrades:
		for up in Database.UPGRADES:
			if up["id"] == uid:
				for t in up.get("tags", []):
					tags.append(t)
	return tags

func add_essence(amount: int) -> void:
	essence += amount
	EventBus.essence_gained.emit(amount)

# --- Continue snapshot ----------------------------------------------
func to_snapshot() -> Dictionary:
	return {
		"seed": seed_value, "class_id": class_id, "stage_index": stage_index,
		"upgrades": upgrades.duplicate(), "equipped": equipped.duplicate(),
		"essence": essence, "carry_health": carry_health,
		"carry_sanity": carry_sanity, "run_time": run_time,
	}

func from_snapshot(s: Dictionary) -> void:
	seed_value = int(s.get("seed", 0))
	rng.seed = seed_value
	class_id = String(s.get("class_id", "swordsman"))
	stage_index = int(s.get("stage_index", 0))
	upgrades.assign(s.get("upgrades", []))
	equipped = s.get("equipped", {})
	essence = int(s.get("essence", 0))
	carry_health = float(s.get("carry_health", -1.0))
	carry_sanity = float(s.get("carry_sanity", 100.0))
	run_time = float(s.get("run_time", 0.0))
	run_active = true

func save_continue() -> void:
	if run_active:
		SaveManager.save_run(to_snapshot())
