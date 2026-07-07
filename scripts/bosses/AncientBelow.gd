extends "res://scripts/bosses/BossBase.gd"
## AncientBelow.gd - final boss: the cave's intelligence (bible sections 11, 28).
## Five phases at 100/80/60/40/20% HP:
##   1 CAVE HEART    - pulsing heart, radial shard bursts + aimed bolts
##   2 FALSE UI      - the HUD lies (sanity_event "fake_ui"), shadow bolts
##   3 PLAYER ECHOES - summons faceless copies (the strongest regular enemy)
##   4 COLLAPSE      - the arena rains rocks while all attacks continue
##   5 CHOICE ENDING - the heart opens: two altars appear. "Strike the Heart"
##                     (ending: shatter) or "Become the Hollow" (ending:
##                     hollow). Killing it outright also grants "shatter".
## The ending id lands in RunManager.ending_id -> VictoryScreen text.

var _burst_cd := 2.0
var _bolt_cd := 1.2
var _lie_cd := 6.0
var _echo_done := false
var _rock_cd := 1.2
var _choice_active := false
var _heart: MeshInstance3D
var _pulse_t := 0.0

func setup_boss(id: String) -> void:
	_base_color = Color(0.5, 0.42, 0.5)
	super.setup_boss(id)
	set_meta("hit_radius", 2.2)

func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.2
	col.shape = sph
	col.position = Vector3(0, 2.2, 0)
	add_child(col)

func _build_body() -> void:
	# The Cave Heart: a huge pulsing sphere wrapped in floating rock shards.
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.roughness = 0.8
	_mat.emission_enabled = true
	_mat.emission = Color(0.7, 0.3, 0.4)
	_mat.emission_energy_multiplier = 0.6
	_heart = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 2.0
	s.height = 4.0
	_heart.mesh = s
	_heart.position = Vector3(0, 2.2, 0)
	_heart.material_override = _mat
	add_child(_heart)
	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = Color(0.25, 0.24, 0.28)
	shard_mat.roughness = 1.0
	for i in range(6):
		var shard := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.7, 1.3, 0.7)
		shard.mesh = pm
		var ang := TAU * i / 6.0
		shard.position = Vector3(cos(ang) * 3.0, 2.2 + sin(ang * 2.0), sin(ang) * 3.0)
		shard.rotation = Vector3(randf(), randf(), randf())
		shard.material_override = shard_mat
		add_child(shard)
	# Arena presence light (readable final arena, bible section 19).
	var glow := OmniLight3D.new()
	glow.omni_range = 14.0
	glow.light_energy = 1.2
	glow.light_color = Color(0.9, 0.6, 0.7)
	glow.position = Vector3(0, 4.0, 0)
	glow.shadow_enabled = false
	add_child(glow)

func _pattern(delta: float) -> void:
	# Heartbeat pulse (visual identity + telegraph rhythm).
	_pulse_t += delta
	var pulse := 1.0 + 0.06 * sin(_pulse_t * (2.0 + phase * 0.7))
	_heart.scale = Vector3(pulse, pulse, pulse)

	if _choice_active:
		return   # phase 5: the fight pauses for the choice

	_burst_cd -= delta
	_bolt_cd -= delta

	# --- radial shard burst (all phases; density scales) -----------------
	if _burst_cd <= 0.0:
		_burst_cd = maxf(4.2 - phase * 0.5, 2.0)
		var count := 6 + phase * 2
		var from := global_position + Vector3(0, 2.2, 0)
		var dmg: float = float(tuning.get("shard_dmg", 15.0))
		for i in range(count):
			var ang := TAU * i / count + randf_range(-0.1, 0.1)
			var dir := Vector3(cos(ang), 0.0, sin(ang))
			_shoot_at(from, from + dir * 10.0 + Vector3(0, -1.0, 0), 9.0, dmg, Color(0.8, 0.5, 0.6))

	# --- aimed shadow bolt ------------------------------------------------
	if _bolt_cd <= 0.0:
		_bolt_cd = maxf(2.6 - phase * 0.25, 1.2)
		_shoot_at(global_position + Vector3(0, 3.0, 0), player_pos() + Vector3(0, 1.0, 0),
			13.0, float(tuning.get("bolt_dmg", 20.0)), Color(0.25, 0.2, 0.35))

	# --- phase 2+: the interface lies -------------------------------------
	if phase >= 2:
		_lie_cd -= delta
		if _lie_cd <= 0.0:
			_lie_cd = randf_range(8.0, 13.0)
			EventBus.sanity_event_started.emit("fake_ui")
			EventBus.subtitle_requested.emit("You are already dead. (are you?)", 2.0)

	# --- phase 3: player echoes (once, then reinforced on damage) ---------
	if phase >= 3 and not _echo_done:
		_echo_done = true
		EventBus.subtitle_requested.emit("It wears your shape.", 2.5)
		_summon("faceless", 2)

	# --- phase 4+: the collapse --------------------------------------------
	if phase >= 4:
		_rock_cd -= delta
		if _rock_cd <= 0.0:
			_rock_cd = 1.3
			_fall_rock(player_pos() + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)),
				float(tuning.get("rock_dmg", 26.0)))

func _on_phase(new_phase: int) -> void:
	match new_phase:
		2: EventBus.subtitle_requested.emit("IT REACHES INTO YOUR EYES", 2.5)
		3: pass  # echo summon handled in _pattern
		4: EventBus.subtitle_requested.emit("The Hollow Mind is collapsing.", 2.5)
		5: _open_choice()

# =====================================================================
#  PHASE 5: THE CHOICE (Appendix G2 Ending Matrix)
#  Escape - always offered (leave the cave)
#  Hollow - always offered (accept the cave)
#  Mercy  - only if the Medic/Child were aided 3+ times AND no echoes killed
#  Truth  - only if all five memory relics were collected
#  Killing the heart outright: Escape with sanity > 40, otherwise Hollow.
# =====================================================================
func _open_choice() -> void:
	_choice_active = true
	stop_moving()
	_mat.emission_energy_multiplier = 2.5
	EventBus.subtitle_requested.emit("The heart opens. It offers you a place inside.", 4.0)

	var altars: Array = [
		["Leave the Cave", "escape", Color(0.95, 0.75, 0.35)],
		["Become the Hollow", "hollow", Color(0.5, 0.4, 0.8)],
	]
	if RunManager.helpers_aided >= 3 and RunManager.echoes_killed == 0:
		altars.append(["Free the Trapped Memory", "mercy", Color(0.4, 0.9, 0.6)])
		EventBus.subtitle_requested.emit("A third light kindles: the ones you helped remember you.", 4.0)
	if RunManager.memory_relics >= 5:
		altars.append(["Speak the Cave's Name", "truth", Color(0.9, 0.9, 1.0)])
		EventBus.subtitle_requested.emit("The five memories align. You could know what this place IS.", 4.0)

	var Interactable := load("res://scripts/items/Interactable.gd")
	for i in range(altars.size()):
		var entry: Array = altars[i]
		var altar = Interactable.new()
		altar.setup(String(entry[0]), entry[2], Vector3(0.8, 1.6, 0.8))
		var ang := TAU * i / altars.size()
		altar.position = Vector3(cos(ang) * 4.0, 0, 3.0 + sin(ang) * 2.0)
		var ending: String = entry[1]
		altar.on_interact = func(_pl):
			RunManager.ending_id = ending
			_resolve_choice()
		add_child(altar)

func _resolve_choice() -> void:
	_choice_active = false
	die()

func die() -> void:
	# Killed by force (or choice already made): resolve per the matrix.
	if RunManager.ending_id == "":
		RunManager.ending_id = "escape" if RunManager.carry_sanity > 40.0 else "hollow"
	super.die()
