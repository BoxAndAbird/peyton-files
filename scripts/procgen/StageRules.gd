extends Node
## StageRules.gd - per-biome SPECIAL RULES from the bible's stage pacing table
## (section 7) and stage details (section 8). One instance per stage, created
## by StageBuilder.build() after generation completes.
##
##   flooded  "Water slows player/enemies differently" - waist-deep pools:
##            player x0.65, enemies x0.5... but the Drowned THRIVE (immune).
##   crystal  "Mirrors create fake silhouettes" - dark enemy-shaped decoys
##            that shatter like glass when approached.
##   living   "Rooms can breathe/shift after combat" - room lights pulse with
##            a heartbeat; when combat ends the walls visibly exhale.
##            (Audiovisual only, matching the bible's "shifts as visual only"
##            precedent - real geometry moves would break the navmesh.)
##   void     "Map lies; false exits" - permanent counterfeit exit gates in
##            wrong rooms, direction reveals lie half the time, rocks float.
##
## Also runs the Forgotten Entrance tutorial beats (stage 1 "teaches
## movement, loot, sanity basics"). Everything is seeded from the stage RNG
## so layouts remain reproducible.

const WATER_ROOM_CHANCE := 0.45
const PLAYER_WATER_SLOW := 0.65
const ENEMY_WATER_SLOW := 0.5

var stage = null                     # StageBuilder (untyped: duck-typed access)
var _rng: RandomNumberGenerator

# living-depths breathing state
var _breath_lights: Array = []       # [[OmniLight3D, base_energy, phase], ...]
var _breath_t := 0.0
var _heartbeat_cd := 0.0

# void floating rocks: [[MeshInstance3D, base_y, phase], ...]
var _floaters: Array = []

func setup(p_stage, rng: RandomNumberGenerator) -> void:
	stage = p_stage
	_rng = rng
	match String(stage.stage_data["biome"]):
		"flooded":
			_setup_water()
		"crystal":
			_setup_mirrors()
		"living":
			_setup_breathing()
		"void":
			_setup_void()
	if RunManager.stage_index == 0:
		_run_tutorial()

# =====================================================================
#  FLOODED CAVERNS - water pools (slow player/enemies differently)
# =====================================================================
func _setup_water() -> void:
	for r in stage.graph.rooms:
		if r["role"] == "entrance" or r["role"] == "exit":
			continue
		if _rng.randf() > WATER_ROOM_CHANCE:
			continue
		var rect: Rect2i = stage.room_rects[r["id"]]
		var size := Vector3(rect.size.x * stage.CELL * 0.85, 1.0, rect.size.y * stage.CELL * 0.85)
		var pool := Area3D.new()
		pool.collision_layer = 0
		pool.collision_mask = 0b110      # player + enemies
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		pool.add_child(col)
		var mesh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x, 0.35, size.z)
		mesh.mesh = bm
		mesh.position = Vector3(0, -0.25, 0)
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.25, 0.45, 0.6, 0.55)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.4, 0.6)
		mat.emission_energy_multiplier = 0.35   # water glow = a light anchor
		mesh.material_override = mat
		pool.add_child(mesh)
		stage.add_child(pool)
		pool.global_position = stage._room_center(r["id"]) + Vector3(0, 0.45, 0)
		# Slow ticking is polled here (one timer for all pools is overkill;
		# Area3D overlap polling at 0.4s per pool is cheap at this count).
		var timer := Timer.new()
		timer.wait_time = 0.4
		timer.autostart = true
		pool.add_child(timer)
		timer.timeout.connect(_tick_water.bind(pool))

func _tick_water(pool: Area3D) -> void:
	if not is_instance_valid(pool):
		return
	for body in pool.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("apply_slow"):
			body.call("apply_slow", PLAYER_WATER_SLOW, 0.6)
		elif body.is_in_group("enemies") and body.has_method("apply_slow"):
			# The Drowned live here: water never slows them ("differently").
			if str(body.get("species_id")) == "drowned":
				continue
			body.call("apply_slow", ENEMY_WATER_SLOW, 0.6)

# =====================================================================
#  CRYSTAL ABYSS - mirror silhouettes (fake enemy shapes that shatter)
# =====================================================================
func _setup_mirrors() -> void:
	var count := _rng.randi_range(3, 5)
	var candidates: Array = []
	for r in stage.graph.rooms:
		if r["role"] != "entrance" and r["role"] != "exit":
			candidates.append(r["id"])
	for i in range(count):
		if candidates.is_empty():
			break
		var room_id: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
		_spawn_mirror(stage._room_center(room_id) + Vector3(
			_rng.randf_range(-3.0, 3.0), 0, _rng.randf_range(-3.0, 3.0)))

func _spawn_mirror(pos: Vector3) -> void:
	var sil := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.7
	sil.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.1, 0.1, 0.14, 0.7)   # reads as a lurking enemy
	sil.material_override = mat
	stage.add_child(sil)
	sil.global_position = pos + Vector3.UP * 0.9
	# Faint red glint where an eye would be - the lie needs to be convincing.
	var eye := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	eye.mesh = s
	var em := StandardMaterial3D.new()
	em.emission_enabled = true
	em.emission = Color(0.8, 0.2, 0.15)
	em.emission_energy_multiplier = 1.2
	eye.material_override = em
	eye.position = Vector3(0.1, 0.55, -0.3)
	sil.add_child(eye)
	# Poll proximity; shatter within 4m.
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	sil.add_child(timer)
	timer.timeout.connect(func():
		var pl = GameManager.player
		if pl == null or not is_instance_valid(sil):
			return
		if sil.global_position.distance_to(pl.global_position) < 4.0:
			timer.stop()
			AudioManager.play_at("crit", sil.global_position, stage, 2.2)  # glass
			EventBus.subtitle_requested.emit("Only your reflection, wrong by inches.", 2.0)
			var tw := sil.create_tween()
			tw.tween_property(sil, "scale", Vector3(1.3, 0.02, 1.3), 0.3)
			tw.tween_callback(sil.queue_free))

# =====================================================================
#  LIVING DEPTHS - breathing rooms + exhale after combat
# =====================================================================
func _setup_breathing() -> void:
	for child in stage.get_children():
		var light := child as OmniLight3D
		if light:
			_breath_lights.append([light, light.light_energy, _rng.randf() * TAU])
	EventBus.combat_state_changed.connect(_on_combat_changed)

func _on_combat_changed(in_combat: bool) -> void:
	if in_combat or _breath_lights.is_empty():
		return
	# Combat just ended: the room exhales (bible: rooms shift after combat).
	EventBus.subtitle_requested.emit("The walls exhale.", 2.0)
	AudioManager.play("hurt", "Ambient", 0.3)
	for entry in _breath_lights:
		var light = entry[0]
		if not is_instance_valid(light):
			continue
		var tw = light.create_tween()
		tw.tween_property(light, "light_energy", entry[1] * 1.7, 0.4)
		tw.tween_property(light, "light_energy", entry[1], 1.0)

func _process(delta: float) -> void:
	# Heartbeat pulse for the living biome.
	if not _breath_lights.is_empty():
		_breath_t += delta
		for entry in _breath_lights:
			var light = entry[0]
			if is_instance_valid(light):
				light.light_energy = entry[1] * (1.0 + 0.15 * sin(_breath_t * 1.6 + entry[2]))
		_heartbeat_cd -= delta
		if _heartbeat_cd <= 0.0:
			_heartbeat_cd = 2.2
			AudioManager.play("hit", "Ambient", 0.35)
	# Floating rocks bob in the void biome.
	if not _floaters.is_empty():
		_breath_t += delta
		for entry in _floaters:
			var rock = entry[0]
			if is_instance_valid(rock):
				rock.position.y = entry[1] + 0.3 * sin(_breath_t * 0.7 + entry[2])
				rock.rotate_y(delta * 0.15)

# =====================================================================
#  HOLLOW MIND - map lies, false exits, floating geometry
# =====================================================================
func _setup_void() -> void:
	stage.exit_direction_lies = true   # reveal_exit_direction may now lie
	# Counterfeit exit gates in wrong rooms (identical to the real one).
	var Interactable := load("res://scripts/items/Interactable.gd")
	var wrong_rooms: Array = []
	for r in stage.graph.rooms:
		if r["role"] != "entrance" and r["role"] != "exit" and r["depth"] >= 2:
			wrong_rooms.append(r["id"])
	for i in range(mini(2, wrong_rooms.size())):
		var room_id: int = wrong_rooms[_rng.randi_range(0, wrong_rooms.size() - 1)]
		wrong_rooms.erase(room_id)
		var fake = Interactable.new()
		fake.setup("Open the descent gate", Color(0.95, 0.5, 0.15), Vector3(1.6, 2.6, 0.5))
		fake.position = stage._room_center(room_id) + Vector3(0, 0, -3.0)
		fake.on_interact = func(_pl):
			EventBus.subtitle_requested.emit("The gate is a painting on stone. It was ALWAYS a painting.", 3.0)
			AudioManager.play_ui("denied")
			var sm = stage.get_node_or_null("SanityManager")
			if sm:
				sm.set_sanity(sm.sanity - 5.0)
			var tw = fake.create_tween()
			tw.tween_property(fake, "scale", Vector3(1.0, 0.02, 1.0), 0.6)
			tw.tween_callback(fake.queue_free)
		stage.add_child(fake)
	# Floating rocks: impossible geometry, drifting over the paths.
	for r in stage.graph.rooms:
		if _rng.randf() > 0.4:
			continue
		for i in range(_rng.randi_range(1, 2)):
			var rock := MeshInstance3D.new()
			var pm := PrismMesh.new()
			pm.size = Vector3(0.8, 1.0, 0.8) * _rng.randf_range(0.6, 1.4)
			rock.mesh = pm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.3, 0.36)
			mat.roughness = 1.0
			rock.material_override = mat
			stage.add_child(rock)
			var base_y := _rng.randf_range(2.2, 3.2)
			rock.position = stage._room_center(r["id"]) + Vector3(
				_rng.randf_range(-4.0, 4.0), base_y, _rng.randf_range(-4.0, 4.0))
			rock.rotation = Vector3(_rng.randf(), _rng.randf(), _rng.randf())
			_floaters.append([rock, base_y, _rng.randf() * TAU])

# =====================================================================
#  FORGOTTEN ENTRANCE - tutorial beats (stage 1 teaches the basics)
# =====================================================================
func _run_tutorial() -> void:
	_tutorial_line(2.0, "WASD moves. SHIFT sprints — but the cave hears running.")
	_tutorial_line(9.0, "SPACE dodges through attacks. Q focuses the lantern and steadies your mind.")
	_tutorial_line(17.0, "Gather glowing essence. TAB opens your pack. The gate below is guarded.")

func _tutorial_line(delay: float, text: String) -> void:
	var t := get_tree().create_timer(delay, false)
	t.timeout.connect(func():
		if GameManager.state == GameManager.State.PLAYING:
			EventBus.subtitle_requested.emit(text, 4.5))
