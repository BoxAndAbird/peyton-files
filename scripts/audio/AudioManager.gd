extends Node
## AudioManager.gd  (Autoload singleton: "AudioManager")
##
## Owns the audio bus layout (bible section 17) and plays sound. Because the
## project ships with NO external audio files yet, this manager SYNTHESIZES
## small placeholder blips in code (AudioStreamWAV). That means menus, hits and
## pickups already make sound, and swapping in real .wav/.ogg later is a
## one-line change per cue.
##
## BUSES: Master -> {Music, SFX, Ambient, UI}. SettingsManager drives their
## volumes. Loads before SettingsManager so settings can configure it.
##
## Integration: EventBus.subtitle_requested is emitted here for accessibility
## captions when a named cue plays (if subtitles are on).

const BUSES := ["Music", "SFX", "Ambient", "UI"]

# Pre-baked procedural streams keyed by cue name.
var _cues: Dictionary = {}
# Reusable 2D players pool so overlapping SFX don't cut each other.
var _ui_players: Array[AudioStreamPlayer] = []
var _ui_index := 0
var _ambient_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_bake_cues()
	# Pool of 6 UI/SFX players.
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_ui_players.append(p)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

# --- Bus setup -------------------------------------------------------
func _setup_buses() -> void:
	# Master is index 0 and always present. Add the rest routed to Master.
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

## Set a bus volume from a 0..1 linear slider value (0..100 also accepted).
func set_bus_volume01(bus_name: String, value: float) -> void:
	if value > 1.0:
		value = value / 100.0
	value = clampf(value, 0.0, 1.0)
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if value <= 0.001:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

# --- Procedural cue baking ------------------------------------------
func _bake_cues() -> void:
	# name -> AudioStreamWAV. freq/type/dur tuned to read as retro UI/foley.
	_cues["ui_hover"]   = _make_tone(660.0, 0.05, "square", 0.25)
	_cues["ui_confirm"] = _make_tone(880.0, 0.09, "square", 0.35)
	_cues["ui_cancel"]  = _make_tone(330.0, 0.09, "square", 0.30)
	_cues["ui_denied"]  = _make_tone(150.0, 0.14, "saw", 0.30)
	_cues["hit"]        = _make_noise(0.06, 0.45)
	_cues["crit"]       = _make_tone(1200.0, 0.10, "square", 0.4)
	_cues["pickup"]     = _make_tone(990.0, 0.12, "sine", 0.3)
	_cues["footstep"]   = _make_noise(0.04, 0.2)
	_cues["dodge"]      = _make_noise(0.08, 0.25)
	_cues["hurt"]       = _make_tone(220.0, 0.12, "saw", 0.4)

## Synthesize a short mono 16-bit tone. wave in {"sine","square","saw"}.
func _make_tone(freq: float, dur: float, wave: String, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / rate
		var phase := fposmod(t * freq, 1.0)
		var s := 0.0
		match wave:
			"square": s = 1.0 if phase < 0.5 else -1.0
			"saw":    s = phase * 2.0 - 1.0
			_:        s = sin(phase * TAU)
		# Simple attack/decay envelope so it doesn't click.
		var env := clampf(minf(float(i) / 64.0, float(count - i) / (rate * dur * 0.6)), 0.0, 1.0)
		var v := int(clampf(s * gain * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wrap_wav(data, rate)

## Synthesize a short noise burst (impacts / footsteps).
func _make_noise(dur: float, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var env := clampf(float(count - i) / count, 0.0, 1.0)
		var v := int(clampf((randf() * 2.0 - 1.0) * gain * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wrap_wav(data, rate)

func _wrap_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

# --- Playback API ----------------------------------------------------
## Play a 2D (non-positional) cue by name. Safe if the cue is unknown.
func play(cue: String, bus := "SFX", pitch := 1.0, subtitle := "") -> void:
	var stream: AudioStream = _cues.get(cue)
	if stream == null:
		return
	var p := _ui_players[_ui_index]
	_ui_index = (_ui_index + 1) % _ui_players.size()
	p.stream = stream
	p.bus = bus
	p.pitch_scale = pitch
	p.play()
	if subtitle != "":
		EventBus.subtitle_requested.emit(subtitle, 1.5)

func play_ui(kind: String) -> void:
	play("ui_" + kind, "UI")

## Positional 3D cue. `parent` should be inside the current scene tree.
func play_at(cue: String, world_pos: Vector3, parent: Node, pitch := 1.0) -> void:
	var stream: AudioStream = _cues.get(cue)
	if stream == null or parent == null or not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.bus = "SFX"
	p.pitch_scale = pitch
	p.unit_size = 6.0
	p.max_distance = 30.0
	parent.add_child(p)
	p.global_position = world_pos
	p.play()
	p.finished.connect(p.queue_free)

# --- Ambient / music hooks (expanded in the audio step) --------------
func set_ambient(stream: AudioStream) -> void:
	_ambient_player.stream = stream
	if stream:
		_ambient_player.play()
	else:
		_ambient_player.stop()

func set_music(stream: AudioStream) -> void:
	_music_player.stream = stream
	if stream:
		_music_player.play()
	else:
		_music_player.stop()
