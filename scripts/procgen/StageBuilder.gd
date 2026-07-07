extends Node3D
## StageBuilder.gd - builds a playable 3D stage from a seed (bible section 7).
## Phases (in build()): graph -> carve cells -> geometry -> lights/props ->
## navigation bake -> exit gate -> loot -> enemies -> ready.
##
## GEOMETRY STRATEGY (performance budget, bible section 30):
## Rooms/corridors are carved into a 2m cell grid; carved cells become floor,
## and carved/uncarved boundaries become walls. Contiguous runs are merged into
## single boxes so a 14-room stage costs ~100-200 nodes, not thousands.
## Every room gets a biome-tinted OmniLight (no shadows) + emissive landmark
## prop + corridor path markers => the "three readability anchors" rule.
##
## Integration:
##   GameManager calls build(stage_data, rng) then get_spawn_point().
##   The exit gate Interactable calls GameManager.complete_stage().
##   DebugConsole calls debug_spawn_enemy(id).

const CELL := 2.0          # metres per grid cell
const MACRO := 9           # grid cells between room centers
const WALL_H := 3.6

var stage_data: Dictionary = {}
var graph: RoomGraph
var carved: Dictionary = {}          # Vector2i -> true
var room_rects: Dictionary = {}      # room id -> Rect2i (in cells)
var _rng: RandomNumberGenerator
var _nav_region: NavigationRegion3D
var _geometry_root: Node3D
var _floor_mat: StandardMaterial3D
var _wall_mat: StandardMaterial3D

# --- stage climax (boss arena or elite gauntlet in the exit room) -----
var arena_cleared := false           # gate opens only when true
var _fight_started := false
var _boss = null                     # BossBase subclass (untyped: duck calls)
var _gauntlet_ids: Array = []        # instance ids of gauntlet elites

# =====================================================================
#  BUILD PIPELINE
# =====================================================================
func build(p_stage_data: Dictionary, rng: RandomNumberGenerator) -> void:
	stage_data = p_stage_data
	_rng = rng
	var count := rng.randi_range(int(stage_data["room_min"]), int(stage_data["room_max"]))
	graph = RoomGraph.generate(rng, count)
	_carve_rooms()
	_carve_corridors()
	_make_materials()
	_build_geometry()
	_build_room_lights_and_props()
	_build_navigation()
	_place_exit_gate()
	_place_arena_trigger()
	_place_pickups()
	_place_helper()
	_spawn_enemies()
	EventBus.say("Stage '%s' built: %d rooms, %d cells." % [stage_data["id"], graph.rooms.size(), carved.size()])

# --- carving ----------------------------------------------------------
func _carve_rooms() -> void:
	for r in graph.rooms:
		var center: Vector2i = r["cell"] * MACRO
		var hw := _rng.randi_range(2, 3)   # half-width  -> rooms 10-14m wide
		var hh := _rng.randi_range(2, 3)
		if r["role"] == "entrance" or r["role"] == "exit":
			hw = 3; hh = 3                 # key rooms are always roomy
		if r["role"] == "exit" and String(stage_data.get("boss", "")) != "":
			hw = 4; hh = 4                 # boss arenas need dodge space (~18m)
		room_rects[r["id"]] = Rect2i(center - Vector2i(hw, hh), Vector2i(hw * 2 + 1, hh * 2 + 1))
		for x in range(center.x - hw, center.x + hw + 1):
			for y in range(center.y - hh, center.y + hh + 1):
				carved[Vector2i(x, y)] = true

func _carve_corridors() -> void:
	var done := {}
	for r in graph.rooms:
		for nid in r["links"]:
			var key := Vector2i(mini(r["id"], nid), maxi(r["id"], nid))
			if done.has(key):
				continue
			done[key] = true
			var a: Vector2i = r["cell"] * MACRO
			var b: Vector2i = graph.rooms[nid]["cell"] * MACRO
			# L-corridor: along x, then along y; 2 cells wide for readability.
			var p := a
			while p.x != b.x:
				p.x += signi(b.x - p.x)
				carved[p] = true
				carved[p + Vector2i(0, 1)] = true
			while p.y != b.y:
				p.y += signi(b.y - p.y)
				carved[p] = true
				carved[p + Vector2i(1, 0)] = true

# --- materials (PS2: flat colors, rough, no PBR shine) -----------------
func _make_materials() -> void:
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.albedo_color = Color(0.28, 0.26, 0.24) * Color(stage_data["light_tint"]).lightened(0.4)
	_floor_mat.roughness = 1.0
	_wall_mat = StandardMaterial3D.new()
	_wall_mat.albedo_color = Color(0.20, 0.19, 0.18) * Color(stage_data["light_tint"]).lightened(0.5)
	_wall_mat.roughness = 1.0

# --- geometry with run-length merging ----------------------------------
func _build_geometry() -> void:
	_geometry_root = Node3D.new()
	_geometry_root.name = "Geometry"
	add_child(_geometry_root)

	# FLOORS: merge carved cells into horizontal strips per row.
	var rows := {}
	for cell in carved.keys():
		if not rows.has(cell.y):
			rows[cell.y] = []
		rows[cell.y].append(cell.x)
	for y in rows.keys():
		var xs: Array = rows[y]
		xs.sort()
		var run_start: int = xs[0]
		var prev: int = xs[0]
		for i in range(1, xs.size() + 1):
			var x: int = xs[i] if i < xs.size() else prev + 2   # sentinel breaks run
			if x != prev + 1:
				_add_box(Vector3((run_start + prev) * 0.5 * CELL, -0.15, y * CELL),
					Vector3((prev - run_start + 1) * CELL, 0.3, CELL), _floor_mat)
				run_start = x
			prev = x

	# WALLS: boundary faces between carved and uncarved cells, merged in runs.
	_build_wall_runs(Vector2i(0, -1))  # north
	_build_wall_runs(Vector2i(0, 1))   # south
	_build_wall_runs(Vector2i(-1, 0))  # west
	_build_wall_runs(Vector2i(1, 0))   # east

func _build_wall_runs(dir: Vector2i) -> void:
	# Collect carved cells whose neighbor in `dir` is uncarved -> wall face.
	var faces := {}
	for cell in carved.keys():
		if not carved.has(cell + dir):
			# Key by the perpendicular coordinate so runs merge along the wall.
			var k: int = cell.y if dir.y != 0 else cell.x
			if not faces.has(k):
				faces[k] = []
			faces[k].append(cell.x if dir.y != 0 else cell.y)
	for k in faces.keys():
		var arr: Array = faces[k]
		arr.sort()
		var run_start: int = arr[0]
		var prev: int = arr[0]
		for i in range(1, arr.size() + 1):
			var v: int = arr[i] if i < arr.size() else prev + 2
			if v != prev + 1:
				var length := (prev - run_start + 1) * CELL
				var mid := (run_start + prev) * 0.5 * CELL
				var pos: Vector3
				var size: Vector3
				if dir.y != 0:
					pos = Vector3(mid, WALL_H * 0.5, k * CELL + dir.y * CELL * 0.5)
					size = Vector3(length, WALL_H, 0.4)
				else:
					pos = Vector3(k * CELL + dir.x * CELL * 0.5, WALL_H * 0.5, mid)
					size = Vector3(0.4, WALL_H, length)
				_add_box(pos, size, _wall_mat)
				run_start = v
			prev = v

## One visual box + matching static collision (layer 1: world).
func _add_box(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 0b1
	body.collision_mask = 0
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat
	body.add_child(mesh)
	_geometry_root.add_child(body)

# --- lights + readability anchors --------------------------------------
func _build_room_lights_and_props() -> void:
	var tint: Color = stage_data["light_tint"]
	for r in graph.rooms:
		var center := _room_center(r["id"])
		# 1) Primary light source (no shadows: performance budget).
		var light := OmniLight3D.new()
		light.position = center + Vector3(0, 2.6, 0)
		light.omni_range = 11.0
		light.light_energy = 1.1
		light.light_color = tint
		light.shadow_enabled = false
		add_child(light)
		# 2) Landmark prop: emissive crystal/brazier (also role-coded color).
		var prop := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.8, 1.4, 0.8)
		prop.mesh = pm
		var mat := StandardMaterial3D.new()
		var role_col := _role_color(r["role"], tint)
		mat.albedo_color = role_col
		mat.emission_enabled = true
		mat.emission = role_col
		mat.emission_energy_multiplier = 1.2
		prop.material_override = mat
		var off := Vector3(_rng.randf_range(-3, 3), 0.7, _rng.randf_range(-3, 3))
		prop.position = center + off
		add_child(prop)
	# 3) Path markers: small glow dots along corridors every ~6 cells.
	var i := 0
	for cell in carved.keys():
		i += 1
		if i % 11 != 0:
			continue
		var marker := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		marker.mesh = sm
		var mm := StandardMaterial3D.new()
		mm.emission_enabled = true
		mm.emission = Color(stage_data["light_tint"]).lightened(0.3)
		mm.emission_energy_multiplier = 2.0
		marker.material_override = mm
		marker.position = Vector3(cell.x * CELL + 0.7, 0.12, cell.y * CELL + 0.7)
		add_child(marker)

func _role_color(role: String, tint: Color) -> Color:
	match role:
		"exit": return Color(0.95, 0.55, 0.2)
		"loot": return Color(0.9, 0.8, 0.3)
		"helper": return Color(0.4, 0.9, 0.6)
		"event": return Color(0.7, 0.4, 0.8)
		"secret": return Color(0.3, 0.5, 0.9)
		_: return tint

# --- navigation ---------------------------------------------------------
func _build_navigation() -> void:
	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "NavRegion"
	add_child(_nav_region)
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = 0b1
	# The geometry lives under _geometry_root (a sibling), so parse by GROUP,
	# not by nav-region children. _geometry_root joins "nav_source" below.
	nav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav.geometry_source_group_name = "nav_source"
	nav.agent_radius = 0.5
	nav.agent_height = 1.8
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	_nav_region.navigation_mesh = nav
	_geometry_root.add_to_group("nav_source")
	# Runtime bake; deferred so all geometry is inside the tree first.
	_nav_region.call_deferred("bake_navigation_mesh")

# --- gameplay content ----------------------------------------------------
func _room_center(id: int) -> Vector3:
	var rect: Rect2i = room_rects[id]
	var c := rect.get_center()
	return Vector3(c.x * CELL, 0.0, c.y * CELL)

func get_spawn_point() -> Vector3:
	return _room_center(graph.get_entrance()["id"])

func _place_exit_gate() -> void:
	var Interactable := load("res://scripts/items/Interactable.gd")
	var gate = Interactable.new()   # untyped: setup/on_interact are script members
	gate.setup("Open the descent gate", Color(0.95, 0.5, 0.15), Vector3(1.6, 2.6, 0.5))
	# Gate sits at the arena's far edge so the climax owns the room center.
	var rect: Rect2i = room_rects[graph.get_exit()["id"]]
	var edge := (rect.size.y / 2 - 1) * CELL
	gate.position = _room_center(graph.get_exit()["id"]) + Vector3(0, 0, -edge)
	gate.one_shot = false           # stays interactable while sealed
	gate.on_interact = func(_player):
		if arena_cleared:
			EventBus.say("Exit gate opened.")
			GameManager.complete_stage()
		else:
			EventBus.subtitle_requested.emit("The gate is sealed. Something guards it.", 2.5)
			AudioManager.play_ui("denied")
			start_climax()
	add_child(gate)

# =====================================================================
#  STAGE CLIMAX: boss arena (stages with a boss id) or elite gauntlet
# =====================================================================
## Invisible trigger over the exit room: entering starts the fight.
func _place_arena_trigger() -> void:
	var trigger := Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 0b10    # player
	trigger.monitoring = true
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	var rect: Rect2i = room_rects[graph.get_exit()["id"]]
	shape.radius = maxf(rect.size.x, rect.size.y) * CELL * 0.35
	col.shape = shape
	trigger.add_child(col)
	trigger.position = _room_center(graph.get_exit()["id"]) + Vector3.UP
	trigger.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player"):
			start_climax())
	add_child(trigger)

func start_climax() -> void:
	if _fight_started or arena_cleared:
		return
	_fight_started = true
	var center := _room_center(graph.get_exit()["id"])
	_light_arena(center)
	var boss_id := String(stage_data.get("boss", ""))
	if boss_id != "":
		var BossBase := load("res://scripts/bosses/BossBase.gd")
		_boss = BossBase.create(boss_id)
		if _boss == null:
			arena_cleared = true    # never trap the player behind a bug
			return
		add_child(_boss)
		_boss.global_position = center + Vector3(0, 0.5, 2.0)
		_boss.setup_boss(boss_id)
		_boss.on_defeated = _on_climax_cleared
		_boss.activate()
	else:
		_start_gauntlet(center)

## Elite gauntlet (bible: stages 3/4 use elite gauntlets instead of bosses).
func _start_gauntlet(center: Vector3) -> void:
	EventBus.subtitle_requested.emit("Elites guard the descent.", 3.0)
	EventBus.combat_state_changed.emit(true)
	var EnemyBase := load("res://scripts/enemies/EnemyBase.gd")
	var pool: Array = stage_data["enemy_pool"]
	if not EventBus.enemy_died.is_connected(_on_gauntlet_death):
		EventBus.enemy_died.connect(_on_gauntlet_death)
	for i in range(4):
		var eid: String = pool[_rng.randi_range(0, pool.size() - 1)]
		var e = EnemyBase.new()
		add_child(e)
		e.global_position = center + Vector3(_rng.randf_range(-4, 4), 0.5, _rng.randf_range(-4, 4))
		# Elites: +1 stage of scaling and a bigger silhouette.
		e.setup(eid, RunManager.stage_index + 1)
		e.scale = Vector3(1.25, 1.25, 1.25)
		_gauntlet_ids.append(e.get_instance_id())
		EventBus.enemy_spawned.emit(e)

func _on_gauntlet_death(enemy: Node, _pos: Vector3) -> void:
	var id := enemy.get_instance_id()
	if _gauntlet_ids.has(id):
		_gauntlet_ids.erase(id)
		if _gauntlet_ids.is_empty():
			_on_climax_cleared()

func _on_climax_cleared() -> void:
	arena_cleared = true
	EventBus.subtitle_requested.emit("The gate grinds open.", 3.0)
	AudioManager.play("pickup", "SFX", 0.7)
	var hud = GameManager.ui.get_hud() if GameManager.ui else null
	if hud:
		hud.set_objective("The way down is open. Reach the gate.")

## Boss arenas must stay readable (bible section 19): rim lights on start.
func _light_arena(center: Vector3) -> void:
	for offset in [Vector3(-6, 3, -6), Vector3(6, 3, -6), Vector3(-6, 3, 6), Vector3(6, 3, 6)]:
		var l := OmniLight3D.new()
		l.omni_range = 9.0
		l.light_energy = 0.9
		l.light_color = Color(stage_data["light_tint"]).lightened(0.2)
		l.shadow_enabled = false
		l.position = center + offset
		add_child(l)

func _place_pickups() -> void:
	var Pickup := load("res://scripts/items/Pickup.gd")
	# Entrance: guaranteed heal (bible: guaranteed lantern refill / no enemies).
	var heal = Pickup.new()
	heal.setup("heal", 30.0)
	heal.position = get_spawn_point() + Vector3(2.0, 0.5, 1.0)
	add_child(heal)
	# Loot + secret rooms: essence clusters + one guaranteed equipment drop.
	for r in graph.rooms:
		if r["role"] == "loot" or r["role"] == "secret":
			for i in range(_rng.randi_range(2, 4)):
				var p = Pickup.new()
				p.setup("essence", float(_rng.randi_range(3, 8)))
				var rect: Rect2i = room_rects[r["id"]]
				p.position = _room_center(r["id"]) + Vector3(
					_rng.randf_range(-rect.size.x * 0.3, rect.size.x * 0.3) * CELL * 0.4, 0.5,
					_rng.randf_range(-rect.size.y * 0.3, rect.size.y * 0.3) * CELL * 0.4)
				add_child(p)
			# Deterministic (seeded) item so runs are reproducible.
			var ip = Pickup.new()
			ip.setup_item(Database.roll_item_id(_rng, 0.0))
			ip.position = _room_center(r["id"]) + Vector3(0, 0.4, 1.2)
			add_child(ip)

# --- enemies (threat budget per combat room; bible section 7) ------------
func _spawn_enemies() -> void:
	var pool: Array = stage_data["enemy_pool"]
	var threat_scale: float = stage_data["threat"]
	for r in graph.rooms:
		if r["role"] != "combat" and r["role"] != "event":
			continue
		var budget := threat_scale * _rng.randf_range(2.0, 4.0)
		var guard := 0
		while budget > 0.0 and guard < 8:
			guard += 1
			var eid: String = pool[_rng.randi_range(0, pool.size() - 1)]
			var cost: float = float(Database.get_enemy(eid)["threat"])
			if cost > budget and guard > 1:
				break
			budget -= cost
			_spawn_enemy_at(eid, _room_center(r["id"]) + Vector3(
				_rng.randf_range(-3.0, 3.0), 0.2, _rng.randf_range(-3.0, 3.0)))

func _spawn_enemy_at(eid: String, pos: Vector3) -> void:
	var EnemyBase := load("res://scripts/enemies/EnemyBase.gd")
	var e = EnemyBase.new()   # untyped: setup() is a script member
	add_child(e)
	e.global_position = pos + Vector3.UP * 0.5
	e.setup(eid, RunManager.stage_index)
	EventBus.enemy_spawned.emit(e)

## One seeded helper NPC in the "helper" room (bible section 14). Rooms may
## roll zero helper rooms — then the stage simply has no helper.
func _place_helper() -> void:
	for r in graph.rooms:
		if r["role"] != "helper":
			continue
		var HelperBase := load("res://scripts/helpers/HelperBase.gd")
		var ids := ["merchant", "medic", "cartographer", "child"]
		var h = HelperBase.new()   # untyped: setup() is a script member
		add_child(h)
		h.position = _room_center(r["id"]) + Vector3(1.5, 0, 0)
		h.setup(ids[_rng.randi_range(0, ids.size() - 1)], _rng)
		return   # never more than one per stage

## Announce the exit direction (Cartographer NPC + Cartographer Mark upgrade).
func reveal_exit_direction() -> void:
	var pl = GameManager.player
	if pl == null:
		return
	var exit_pos := _room_center(graph.get_exit()["id"])
	var to: Vector3 = exit_pos - pl.global_position
	var dirs := ["east", "north-east", "north", "north-west", "west", "south-west", "south", "south-east"]
	var ang := fposmod(atan2(-to.z, to.x), TAU)
	var compass: String = dirs[int(round(ang / (TAU / 8.0))) % 8]
	EventBus.subtitle_requested.emit("The descent gate lies to the %s, %d paces." % [compass, int(to.length())], 4.0)
	var hud = GameManager.ui.get_hud() if GameManager.ui else null
	if hud:
		hud.set_objective("Exit: %s, ~%dm" % [compass, int(to.length())])

## DebugConsole hook: spawn an enemy near the player.
func debug_spawn_enemy(eid: String) -> void:
	var pos := get_spawn_point()
	if GameManager.player:
		pos = GameManager.player.global_position + Vector3(2.5, 0.2, 2.5)
	_spawn_enemy_at(eid, pos)

## DebugConsole hook: spawn and activate any boss near the player.
func debug_spawn_boss(boss_id: String) -> bool:
	var BossBase := load("res://scripts/bosses/BossBase.gd")
	var b = BossBase.create(boss_id)
	if b == null:
		return false
	add_child(b)
	var pos := get_spawn_point() + Vector3(6, 0.5, 0)
	if GameManager.player:
		pos = GameManager.player.global_position + Vector3(7.0, 0.5, 0.0)
	b.global_position = pos
	b.setup_boss(boss_id)
	b.activate()
	return true
