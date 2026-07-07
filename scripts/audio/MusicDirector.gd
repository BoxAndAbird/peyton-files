extends Node
## MusicDirector.gd  (Autoload singleton: "MusicDirector")
##
## State-driven music/ambience (bible section 17) with ZERO external audio:
## three looping layers are synthesized at startup and crossfaded by game
## state. Swapping in real stems later = replacing the three streams.
##
##   BED     (Ambient bus) - low cave drone; pitch tinted per stage depth
##   TENSION (Music bus)   - dissonant high drone; rises as sanity falls
##   COMBAT  (Music bus)   - percussive pulse; on while enemies chase / boss
##
## Listens: stage_loaded, combat_state_changed, sanity_changed, boss_started,
## boss_defeated, game_state_changed, run_ended. Nothing else references this
## node — safe to load last in the autoload list.

const FADE_SPEED := 2.0        # db-lerp speed factor

var _bed: AudioStreamPlayer
var _tension: AudioStreamPlayer
var _combat: AudioStreamPlayer

# Target linear volumes (0..1) that _process eases toward.
var _bed_target := 0.5
var _tension_target := 0.0
var _combat_target := 0.0
var _boss_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bed = _make_player("Ambient", _synth_bed())
	_tension = _make_player("Music", _synth_tension())
	_combat = _make_player("Music", _synth_combat())

	EventBus.stage_loaded.connect(_on_stage)
	EventBus.combat_state_changed.connect(_on_combat)
	EventBus.sanity_changed.connect(_on_sanity)
	EventBus.boss_started.connect(_on_boss_started)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.game_state_changed.connect(_on_game_state)
	EventBus.run_ended.connect(_on_run_ended)

func _make_player(bus: String, stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = bus
	p.volume_db = -60.0
	add_child(p)
	p.play()
	return p

func _process(delta: float) -> void:
	_ease(_bed, _bed_target, delta)
	_ease(_tension, _tension_target, delta)
	_ease(_combat, _combat_target, delta)

func _ease(p: AudioStreamPlayer, target01: float, delta: float) -> void:
	var target_db := linear_to_db(clampf(target01, 0.0001, 1.0))
	p.volume_db = lerpf(p.volume_db, maxf(target_db, -60.0), FADE_SPEED * delta)

# --- reactions ---------------------------------------------------------
func _on_stage(stage_index: int, _id: String) -> void:
	# Deeper = slower, darker bed (pitch drops per stage).
	_bed.pitch_scale = 1.0 - stage_index * 0.08
	_bed_target = 0.55
	_combat_target = 0.0
	_boss_active = false

func _on_combat(in_combat: bool) -> void:
	if _boss_active:
		return   # boss owns the combat layer until defeated
	_combat_target = 0.7 if in_combat else 0.0

func _on_sanity(current: float, maximum: float) -> void:
	# Tension layer swells as the mind frays (bible: driven by danger meter).
	var frac := 1.0 - clampf(current / maxf(maximum, 1.0), 0.0, 1.0)
	_tension_target = frac * 0.6
	if _boss_active:
		_tension_target = maxf(_tension_target, 0.4)

func _on_boss_started(_boss_id: String) -> void:
	_boss_active = true
	_combat.pitch_scale = 0.85          # heavier pulse for bosses
	_combat_target = 0.9
	_tension_target = maxf(_tension_target, 0.4)

func _on_boss_defeated(_boss_id: String) -> void:
	_boss_active = false
	_combat.pitch_scale = 1.0
	_combat_target = 0.0

func _on_game_state(new_state: int, _old: int) -> void:
	# Menus/death/victory: duck gameplay layers, keep a faint bed.
	var playing: bool = new_state == GameManager.State.PLAYING \
		or new_state == GameManager.State.PAUSED \
		or new_state == GameManager.State.INVENTORY \
		or new_state == GameManager.State.SHOP \
		or new_state == GameManager.State.UPGRADE
	if not playing:
		_combat_target = 0.0
		_tension_target = 0.0
		_bed_target = 0.3
	else:
		_bed_target = 0.55

func _on_run_ended(_victory: bool, _summary: Dictionary) -> void:
	_boss_active = false
	_combat_target = 0.0

# =====================================================================
#  SYNTHESIS - looping AudioStreamWAV layers (placeholder "stems")
# =====================================================================
func _loop_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() / 2
	return w

## Deep cave drone: detuned low sines + very slow amplitude breathing.
func _synth_bed() -> AudioStreamWAV:
	var rate := 22050
	var dur := 6.0
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var breathe := 0.6 + 0.4 * sin(TAU * t / dur)      # loops seamlessly
		var s := sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 82.7 * t) * 0.3 \
			+ sin(TAU * 41.2 * t) * 0.2
		var v := int(clampf(s * 0.35 * breathe, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _loop_wav(data, rate)

## Dissonant tension drone: minor-second pair + slow tremble.
func _synth_tension() -> AudioStreamWAV:
	var rate := 22050
	var dur := 4.0
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var tremble := 0.7 + 0.3 * sin(TAU * 2.0 * t)
		var s := sin(TAU * 220.0 * t) * 0.4 + sin(TAU * 233.1 * t) * 0.4
		var v := int(clampf(s * 0.22 * tremble, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _loop_wav(data, rate)

## Combat pulse: filtered noise thumps on a driving grid.
func _synth_combat() -> AudioStreamWAV:
	var rate := 22050
	var dur := 2.0
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var beat_len := rate / 4           # 8 pulses per loop @ ~240bpm feel
	for i in range(count):
		var in_beat := i % beat_len
		var env := maxf(1.0 - float(in_beat) / (beat_len * 0.35), 0.0)
		var accent := 1.0 if (i / beat_len) % 4 == 0 else 0.55
		var s := (randf() * 2.0 - 1.0) * env * env * accent
		# Low sine body under each thump.
		s += sin(TAU * 60.0 * (float(in_beat) / rate)) * env * 0.6 * accent
		var v := int(clampf(s * 0.4, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _loop_wav(data, rate)
