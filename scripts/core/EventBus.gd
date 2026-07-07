extends Node
## EventBus.gd  (Autoload singleton: "EventBus")
##
## Central signal hub. Systems emit and connect here instead of holding hard
## references to each other. This keeps the project modular: the HUD can react
## to player damage without knowing what a Player is, the MusicDirector can
## react to combat state without touching enemies, etc.
##
## CONVENTION: emitters call `EventBus.emit_signal("name", ...)` or the typed
## helper methods below. Listeners connect in their own _ready().
##
## Nothing in this file depends on any other autoload, so it is safe to load
## first.

# --- Game / flow -----------------------------------------------------------
signal game_state_changed(new_state: int, old_state: int) ## GameManager.State enum
signal request_scene(scene_id: String)                    ## UI asks GameManager to change screens
signal run_started(class_id: String, seed: int)
signal run_ended(victory: bool, summary: Dictionary)
signal stage_loaded(stage_index: int, stage_id: String)
signal stage_cleared(stage_index: int)
signal pause_toggled(is_paused: bool)

# --- Player ----------------------------------------------------------------
signal player_spawned(player: Node)                       ## PlayerController passes `self`
signal player_stats_changed(stats: Dictionary)            ## recalculated stat snapshot
signal player_health_changed(current: float, maximum: float)
signal player_stamina_changed(current: float, maximum: float)
signal player_died()
signal player_interacted(target: Node)
signal player_moved_loud(world_pos: Vector3, loudness: float) ## for sound-tracking enemies

# --- Combat ----------------------------------------------------------------
signal damage_dealt(source: Node, target: Node, amount: float, is_crit: bool)
signal enemy_spawned(enemy: Node)
signal enemy_died(enemy: Node, world_pos: Vector3)
signal combat_state_changed(in_combat: bool)              ## drives combat music
signal essence_gained(amount: int)

# --- Sanity ----------------------------------------------------------------
signal sanity_changed(current: float, maximum: float)
signal sanity_event_started(event_id: String)
signal sanity_event_ended(event_id: String)

# --- Progression -----------------------------------------------------------
signal upgrade_offered(options: Array)                    ## Array[UpgradeData-like Dictionary]
signal upgrade_chosen(upgrade_id: String)
signal item_picked_up(item_id: String)
signal inventory_changed(slots: Dictionary)
signal boss_started(boss_id: String)
signal boss_phase_changed(boss_id: String, phase: int)
signal boss_defeated(boss_id: String)

# --- Settings / audio ------------------------------------------------------
signal settings_applied(settings: Dictionary)
signal brightness_changed(value: float)
signal subtitle_requested(text: String, seconds: float)   ## for accessibility captions

# --- Debug -----------------------------------------------------------------
signal debug_message(text: String)


func _ready() -> void:
	# Ensure the bus survives everything and is never paused out.
	process_mode = Node.PROCESS_MODE_ALWAYS


## Convenience typed emitters (optional; avoids stringly-typed emit calls).
func say(text: String) -> void:
	debug_message.emit(text)
	print("[BTH] ", text)
