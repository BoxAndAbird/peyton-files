extends Node
## SanityManager.gd - sanity drain/recovery + the full psychological event
## library (bible section 5 + APPENDIX B). One instance per stage, created by
## GameManager._load_current_stage.
##
## DRAIN: rises with depth; recovers near the entrance or while the lantern
## is focused. Value persists across stages via RunManager.carry_sanity.
##
## EVENT SCHEDULER (Appendix B): every 18-28s, one event rolls from the
## categories the current sanity level has unlocked. Cooldowns + an intensity
## rule ("the game must not become random noise") keep it sparse. Lantern
## focus is universal counterplay: no event can START while focusing.
##   atmosphere      <=90  whispers, lantern flicker
##   memory_scene    <=90  narrative memory fragments (Appendix G flavor)
##   fake_ui         <=75  the HUD lies (HUDScreen handles the visual)
##   navigation      <=60  a false exit gate that dissolves when approached
##   combat_halluc   <=45  translucent hallucination enemies (1 hit, no damage)
##   audio           <=30  distorted stings, footsteps behind you
##   npc_distortion  <=15  the helpers' faces stop being faces
##   item_deception  <=5   loot that was never there
## Plus the hard threshold event: collapse at <=10 (real crawler pack unless
## Memory Anchor is held).
##
## Debug: console `sanity <0-100>` sets the value; `sanityevent <category>`
## forces any category immediately.

const MAX_SANITY := 100.0
const EVENT_COOLDOWN_MIN := 18.0
const EVENT_COOLDOWN_MAX := 28.0

# category -> sanity ceiling that unlocks it (rolled only at/below).
const CATEGORIES := {
	"atmosphere": 90.0, "memory_scene": 90.0, "fake_ui": 75.0,
	"navigation": 60.0, "combat_halluc": 45.0, "audio": 30.0,
	"npc_distortion": 15.0, "item_deception": 5.0,
}

const MEMORY_LINES := [
	"You remember rope burning through your palms. Whose rope?",
	"A birthday. Cake with grit in the frosting. Everyone singing too slowly.",
	"The first time you saw the cave mouth, it was smaller. It has been eating.",
	"Someone said 'don't look for me.' You are almost sure it was your voice.",
	"Rain. You remember rain. The ceiling drips in the same rhythm.",
]

var sanity := 100.0
var _event_cooldown := 12.0     # first event no sooner than ~12s in
var _collapse_fired := false
var _fakes: Array = []          # live fake props: [Node3D, kind]

func _ready() -> void:
	sanity = clampf(RunManager.carry_sanity, 0.0, MAX_SANITY)
	_emit()

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	_update_drain(delta)
	_update_fakes()
	_event_cooldown -= delta
	if _event_cooldown <= 0.0:
		_schedule_next()
		# Lantern focus is universal counterplay: nothing starts mid-focus.
		if not Input.is_action_pressed("lantern"):
			_roll_event()
	# Hard collapse threshold (kept from the slice; Memory Anchor negates).
	if sanity <= 10.0 and not _collapse_fired:
		_collapse_fired = true
		_fire_collapse()

func _update_drain(delta: float) -> void:
	var drain := 0.12 + RunManager.stage_index * 0.07
	if RunManager.active_tags().has("sanity_loss_down"):
		drain *= 0.85   # Deep Breathing
	if RunManager.active_tags().has("sanity_drain"):
		drain += 0.25   # Cursed Bargain
	if _is_recovering():
		sanity = minf(sanity + 2.5 * delta, MAX_SANITY)
	else:
		sanity = maxf(sanity - drain * delta, 0.0)
	RunManager.carry_sanity = sanity
	_emit()

func _is_recovering() -> bool:
	var player = GameManager.player
	if player == null:
		return false
	if GameManager.current_stage and GameManager.current_stage.has_method("get_spawn_point"):
		if player.global_position.distance_to(GameManager.current_stage.get_spawn_point()) < 6.0:
			return true
	return Input.is_action_pressed("lantern")

func set_sanity(value: float) -> void:
	sanity = clampf(value, 0.0, MAX_SANITY)
	if sanity > 15.0:
		_collapse_fired = false   # collapse can re-arm after real recovery
	RunManager.carry_sanity = sanity
	_emit()

func _emit() -> void:
	EventBus.sanity_changed.emit(sanity, MAX_SANITY)

func _schedule_next() -> void:
	_event_cooldown = randf_range(EVENT_COOLDOWN_MIN, EVENT_COOLDOWN_MAX)

# =====================================================================
#  EVENT ROLLING (Appendix B)
# =====================================================================
func _roll_event() -> void:
	var eligible: Array = []
	for cat in CATEGORIES.keys():
		if sanity <= float(CATEGORIES[cat]):
			eligible.append(cat)
	if eligible.is_empty():
		return
	debug_fire(eligible[randi() % eligible.size()])

## Also the console hook: force any category by name.
func debug_fire(category: String) -> void:
	EventBus.sanity_event_started.emit(category)
	match category:
		"atmosphere":       _ev_atmosphere()
		"memory_scene":     _ev_memory()
		"fake_ui":          pass   # HUDScreen reacts to the signal directly
		"navigation":       _ev_fake_prop("exit")
		"combat_halluc":    _ev_hallucination()
		"audio":            _ev_audio()
		"npc_distortion":   _ev_npc()
		"item_deception":   _ev_fake_prop("item")
	EventBus.sanity_event_ended.emit(category)

func _ev_atmosphere() -> void:
	AudioManager.play("hurt", "Ambient", 0.4)
	EventBus.subtitle_requested.emit("...it knows your name...", 3.0)
	# Brief lantern flicker: dip, never darkness (bible section 19).
	var pl = GameManager.player
	if pl and pl._omni_light:
		var tw := create_tween()
		tw.tween_property(pl._omni_light, "light_energy", 0.7, 0.15)
		tw.tween_property(pl._omni_light, "light_energy", 1.6, 0.4)

func _ev_memory() -> void:
	EventBus.subtitle_requested.emit(MEMORY_LINES[randi() % MEMORY_LINES.size()], 4.0)
	AudioManager.play("pickup", "Ambient", 0.5)

func _ev_audio() -> void:
	# Distorted sting + footsteps that are not yours, behind you.
	AudioManager.play("ui_denied", "Ambient", 0.45)
	for i in range(3):
		var t := get_tree().create_timer(0.4 * (i + 1), false)
		t.timeout.connect(func():
			var pl = GameManager.player
			if pl and GameManager.current_stage:
				var behind: Vector3 = pl.global_position - pl.facing_dir() * 3.0
				AudioManager.play_at("footstep", behind, GameManager.current_stage, 0.8))

func _ev_npc() -> void:
	if get_tree().get_nodes_in_group("helpers").is_empty():
		EventBus.subtitle_requested.emit("You hear a shop bell. There is no shop.", 3.0)
	else:
		EventBus.subtitle_requested.emit("For a moment, the helper's face is a smooth pale plate.", 3.0)
	AudioManager.play("hurt", "Ambient", 0.3)

## Translucent, harmless, one-hit hallucination enemies near the player.
func _ev_hallucination() -> void:
	var stage = GameManager.current_stage
	var pl = GameManager.player
	if stage == null or pl == null:
		return
	var pool: Array = stage.stage_data.get("enemy_pool", ["crawler"])
	for i in range(2):
		var eid := String(pool[randi() % pool.size()])
		var e = EnemyFactory.create(eid)
		stage.add_child(e)
		var ang := randf() * TAU
		e.global_position = pl.global_position + Vector3(cos(ang), 0.4, sin(ang)) * randf_range(5.0, 8.0)
		e.setup(eid, RunManager.stage_index)
		e.make_hallucination()
	EventBus.subtitle_requested.emit("Movement in the corner of your eye.", 2.0)

## A false exit gate or loot crate that dissolves as you reach for it.
func _ev_fake_prop(kind: String) -> void:
	var stage = GameManager.current_stage
	var pl = GameManager.player
	if stage == null or pl == null:
		return
	var prop := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	if kind == "exit":
		var bm := BoxMesh.new()
		bm.size = Vector3(1.6, 2.6, 0.5)
		prop.mesh = bm
		mat.albedo_color = Color(0.95, 0.5, 0.15)
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.55, 0.4, 0.4)
		prop.mesh = bm
		mat.albedo_color = Color(0.95, 0.75, 0.35)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 1.0
	prop.material_override = mat
	stage.add_child(prop)
	# Ahead of the player, in their eyeline — close enough to tempt.
	var dir: Vector3 = pl.facing_dir()
	prop.global_position = pl.global_position + dir * randf_range(9.0, 13.0) + Vector3(0, 1.0, 0)
	_fakes.append([prop, kind])

func _update_fakes() -> void:
	var pl = GameManager.player
	if pl == null:
		return
	for entry in _fakes.duplicate():
		var prop = entry[0]
		if not is_instance_valid(prop):
			_fakes.erase(entry)
			continue
		if prop.global_position.distance_to(pl.global_position) < 3.0:
			_fakes.erase(entry)
			var msg := "The gate was never there." if entry[1] == "exit" else "Your hand closes on nothing."
			EventBus.subtitle_requested.emit(msg, 2.5)
			AudioManager.play("ui_denied", "Ambient", 0.6)
			set_sanity(sanity - 3.0)   # deceptions sting
			var tw := create_tween()
			tw.tween_property(prop, "scale", Vector3(0.02, 0.02, 0.02), 0.5)
			tw.tween_callback(prop.queue_free)

# =====================================================================
#  COLLAPSE (hard threshold, kept from the slice)
# =====================================================================
func _fire_collapse() -> void:
	EventBus.sanity_event_started.emit("collapse")
	if RunManager.active_tags().has("anti_collapse"):
		set_sanity(35.0)   # Memory Anchor
		EventBus.subtitle_requested.emit("You hold on to the memory.", 3.0)
		EventBus.sanity_event_ended.emit("collapse")
		return
	EventBus.subtitle_requested.emit("THE CAVE OPENS ITS EYES", 3.0)
	if GameManager.current_stage and GameManager.current_stage.has_method("debug_spawn_enemy"):
		for i in range(3):
			GameManager.current_stage.debug_spawn_enemy("crawler")
	EventBus.sanity_event_ended.emit("collapse")
