extends Node
## SaveManager.gd  (Autoload singleton: "SaveManager")
##
## Three files (bible section 23), all JSON under user://:
##   profile_save.json - unlocks, encyclopedia, best times, total deaths.
##                       NEVER deleted by run death.
##   run_save.json     - continue snapshot (stage, seed, class, stats, items).
##                       Cleared on death/victory.
##   statistics.json   - analytics for balancing.
##
## Loads after Settings so it can react to applied config if needed. Emits
## nothing directly; callers pull data. GameManager/RunManager own the schema.

const PROFILE_PATH := "user://profile_save.json"
const RUN_PATH := "user://run_save.json"
const STATS_PATH := "user://statistics.json"

var profile: Dictionary = {}
var statistics: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	profile = _read_json(PROFILE_PATH, _default_profile())
	statistics = _read_json(STATS_PATH, _default_stats())

# --- Defaults --------------------------------------------------------
func _default_profile() -> Dictionary:
	return {
		"unlocks": [],           # class ids / feature flags unlocked
		"encyclopedia": [],      # enemy ids encountered
		"best_time": 0.0,        # fastest victory (seconds)
		"total_deaths": 0,
		"total_victories": 0,
		"runs_started": 0,
	}

func _default_stats() -> Dictionary:
	return {
		"kills": {},             # enemy_id -> count
		"deaths_by_enemy": {},   # enemy_id -> count
		"damage_dealt": 0.0,
		"items_collected": 0,
		"upgrades_taken": {},    # upgrade_id -> count
	}

# --- Low-level JSON --------------------------------------------------
func _read_json(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return fallback
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		# Merge onto fallback so new keys added later still exist.
		var merged := fallback.duplicate(true)
		for k in parsed.keys():
			merged[k] = parsed[k]
		return merged
	return fallback

func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: cannot write " + path)
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# --- Profile ---------------------------------------------------------
func save_profile() -> void:
	_write_json(PROFILE_PATH, profile)

func unlock(flag: String) -> void:
	if not profile["unlocks"].has(flag):
		profile["unlocks"].append(flag)
		save_profile()

func has_unlock(flag: String) -> bool:
	return profile["unlocks"].has(flag)

func record_encyclopedia(enemy_id: String) -> void:
	if not profile["encyclopedia"].has(enemy_id):
		profile["encyclopedia"].append(enemy_id)
		save_profile()

func record_death() -> void:
	profile["total_deaths"] = int(profile["total_deaths"]) + 1
	save_profile()

func record_victory(time_seconds: float) -> void:
	profile["total_victories"] = int(profile["total_victories"]) + 1
	if profile["best_time"] <= 0.0 or time_seconds < float(profile["best_time"]):
		profile["best_time"] = time_seconds
	save_profile()

func record_run_started() -> void:
	profile["runs_started"] = int(profile["runs_started"]) + 1
	save_profile()

# --- Run snapshot (continue) ----------------------------------------
func has_continue() -> bool:
	return FileAccess.file_exists(RUN_PATH)

func save_run(snapshot: Dictionary) -> void:
	_write_json(RUN_PATH, snapshot)

func load_run() -> Dictionary:
	return _read_json(RUN_PATH, {})

func clear_run() -> void:
	var d := DirAccess.open("user://")
	if d and d.file_exists("run_save.json"):
		d.remove("run_save.json")

# --- Statistics ------------------------------------------------------
func save_stats() -> void:
	_write_json(STATS_PATH, statistics)

func stat_add_kill(enemy_id: String) -> void:
	var k: Dictionary = statistics["kills"]
	k[enemy_id] = int(k.get(enemy_id, 0)) + 1

func stat_add_damage(amount: float) -> void:
	statistics["damage_dealt"] = float(statistics["damage_dealt"]) + amount
