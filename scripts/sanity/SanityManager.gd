extends Node
## SanityManager.gd - sanity drain/recovery + event scheduler (bible sections
## 5, 21). One instance per stage, created by GameManager._load_current_stage.
##
## RULES (bible): sanity decreases with depth and enemy auras; recovers near
## light/rest. At low thresholds hallucination events fire. Sanity value
## persists across stages via RunManager.carry_sanity.
##
## Emits: EventBus.sanity_changed, sanity_event_started/ended.
## Debug: console `sanity <0-100>` sets the value directly through set_sanity.
##
## Vertical-slice events implemented here:
##   whisper  (<=70) - subtitle whisper + audio sting
##   shadows  (<=40) - brief screen darkening pulse (still readable)
##   collapse (<=10) - hallucination Crawler pack spawns (fake, low hp)
## The full SanityEventData-driven scheduler replaces this table later.

const MAX_SANITY := 100.0

var sanity := 100.0
var _event_cooldown := 0.0
var _fired: Dictionary = {}    # event id -> true (once per stage)

func _ready() -> void:
	sanity = clampf(RunManager.carry_sanity, 0.0, MAX_SANITY)
	_emit()

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	var drain := _base_drain_per_s()
	# Deep Breathing upgrade: sanity loss -15%.
	if RunManager.active_tags().has("sanity_loss_down"):
		drain *= 0.85
	# Cursed Bargain: permanent extra drain.
	if RunManager.active_tags().has("sanity_drain"):
		drain += 0.25
	# Recovery: standing in the lit entrance room / near the lantern focus.
	var recovering := _is_recovering()
	if recovering:
		sanity = minf(sanity + 2.5 * delta, MAX_SANITY)
	else:
		sanity = maxf(sanity - drain * delta, 0.0)
	RunManager.carry_sanity = sanity
	_emit()

	_event_cooldown = maxf(_event_cooldown - delta, 0.0)
	if _event_cooldown <= 0.0:
		_check_events()

func _base_drain_per_s() -> float:
	# Deeper stages erode the mind faster (0.12/s .. 0.4/s).
	return 0.12 + RunManager.stage_index * 0.07

func _is_recovering() -> bool:
	var player = GameManager.player
	if player == null:
		return false
	# Near the stage entrance = safety; lantern focus also steadies the mind.
	if GameManager.current_stage and GameManager.current_stage.has_method("get_spawn_point"):
		if player.global_position.distance_to(GameManager.current_stage.get_spawn_point()) < 6.0:
			return true
	return Input.is_action_pressed("lantern")

func set_sanity(value: float) -> void:
	sanity = clampf(value, 0.0, MAX_SANITY)
	RunManager.carry_sanity = sanity
	_emit()

func _emit() -> void:
	EventBus.sanity_changed.emit(sanity, MAX_SANITY)

# --- threshold events -------------------------------------------------
func _check_events() -> void:
	if sanity <= 10.0 and not _fired.has("collapse"):
		_fire("collapse")
	elif sanity <= 40.0 and not _fired.has("shadows"):
		_fire("shadows")
	elif sanity <= 70.0 and not _fired.has("whisper"):
		_fire("whisper")

func _fire(id: String) -> void:
	_fired[id] = true
	_event_cooldown = 20.0
	EventBus.sanity_event_started.emit(id)
	match id:
		"whisper":
			AudioManager.play("hurt", "Ambient", 0.4)
			EventBus.subtitle_requested.emit("...it knows your name...", 3.0)
		"shadows":
			EventBus.subtitle_requested.emit("The shadows lean toward you.", 3.0)
			AudioManager.play("ui_denied", "Ambient", 0.5)
		"collapse":
			# Memory Anchor: once per stage prevent sanity collapse.
			if RunManager.active_tags().has("anti_collapse"):
				set_sanity(35.0)
				EventBus.subtitle_requested.emit("You hold on to the memory.", 3.0)
				EventBus.sanity_event_ended.emit(id)
				return
			EventBus.subtitle_requested.emit("THE CAVE OPENS ITS EYES", 3.0)
			# Hallucination pack: real danger at zero sanity (risk/reward).
			if GameManager.current_stage and GameManager.current_stage.has_method("debug_spawn_enemy"):
				for i in range(3):
					GameManager.current_stage.debug_spawn_enemy("crawler")
	EventBus.sanity_event_ended.emit(id)
