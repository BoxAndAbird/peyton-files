extends CharacterBody3D
## BossBase.gd - boss framework (bible sections 11, 21, 28).
## Responsibilities: HP + phase thresholds from Database.BOSSES, health-bar
## signals, damage intake compatible with PlayerCombat (group "enemies",
## take_damage / apply_burn / staggered), and a library of SHARED ATTACK
## PRIMITIVES the three boss subclasses compose:
##   _shoot_at()      telegraphed projectile (BossProjectile)
##   _ring_attack()   telegraphed ground AoE ring
##   _fall_rock()     warning disc + falling rock (FallingRock)
##   _hazard()        lingering damage zone (HazardZone)
##   _summon()        spawn regular enemies as adds
##
## LIFECYCLE: StageBuilder spawns the subclass dormant in the exit-room arena.
## activate() starts the fight (HP bar + music sting). die() fires
## EventBus.boss_defeated and the on_defeated callable (StageBuilder unlocks
## the gate). Damaging a dormant boss auto-activates it (no free sniping).
##
## Subclass hooks: _build_body(), _build_collision(), _pattern(delta),
## _on_phase(new_phase), _on_damaged(amount).
##
## EventBus out: boss_started, boss_phase_changed, boss_health_changed,
## boss_defeated. Debug: console `boss <id>` spawns any boss via
## BossBase.create().

const GRAVITY := 18.0

var boss_id := ""
var data: Dictionary = {}
var tuning: Dictionary = {}
var hp := 1000.0
var max_hp := 1000.0
var phase := 1                       # 1-based, advances at phase_thresholds
var phase_thresholds: Array = []     # e.g. [1.0, 0.67, 0.34]
var fighting := false
var staggered := false
var exposed := false                 # counterplay window: 2x damage taken
var on_defeated: Callable = Callable()

var _stagger_timer := 0.0
var _burn_time := 0.0
var _burn_tick := 0.0
var _burn_accum := 0.0
var _mat: StandardMaterial3D
var _base_color := Color(0.5, 0.4, 0.4)

## Factory used by StageBuilder and the debug console.
## Const map (not Database) so this static func never touches an autoload —
## autoload access from static contexts is Godot-version-sensitive.
const BOSS_SCRIPTS := {
	"burrower": "res://scripts/bosses/Burrower.gd",
	"drowned_priest": "res://scripts/bosses/DrownedPriest.gd",
	"ancient_below": "res://scripts/bosses/AncientBelow.gd",
}

static func create(id: String):
	var path: String = BOSS_SCRIPTS.get(id, "")
	if path == "" or not ResourceLoader.exists(path):
		push_warning("BossBase.create: unknown boss " + id)
		return null
	return load(path).new()

func setup_boss(id: String) -> void:
	boss_id = id
	data = Database.BOSSES.get(id, {})
	tuning = data.get("tuning", {})
	max_hp = float(data.get("hp", 1000.0))
	hp = max_hp
	phase_thresholds = data.get("phases", [1.0])
	collision_layer = 0b100          # layer 3: enemy (player arrows raycast this)
	collision_mask = 0b1             # collide with world
	add_to_group("enemies")
	set_meta("hit_radius", 1.6)      # widens the player's melee reach vs big bodies
	_build_collision()
	_build_body()
	SaveManager.record_encyclopedia(boss_id)

## Default big capsule; subclasses override for bespoke silhouettes.
func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.3
	cap.height = 3.4
	col.shape = cap
	col.position = Vector3(0, 1.8, 0)
	add_child(col)

func _build_body() -> void:
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 1.25
	cap.height = 3.2
	mesh.mesh = cap
	mesh.position = Vector3(0, 1.8, 0)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.roughness = 1.0
	mesh.material_override = _mat
	add_child(mesh)

# =====================================================================
#  LIFECYCLE
# =====================================================================
func activate() -> void:
	if fighting or hp <= 0.0:
		return
	fighting = true
	EventBus.boss_started.emit(boss_id)
	EventBus.boss_health_changed.emit(hp, max_hp)
	EventBus.combat_state_changed.emit(true)
	EventBus.subtitle_requested.emit(String(data.get("name", "???")), 3.0)
	AudioManager.play("crit", "SFX", 0.5)
	var pl = GameManager.player
	if pl and pl.cam:
		pl.cam.add_trauma(0.5)

func _physics_process(delta: float) -> void:
	if hp <= 0.0:
		return
	_process_burn(delta)
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		if _stagger_timer <= 0.0:
			staggered = false
			_restore_color()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.1)
	if fighting and not staggered:
		_pattern(delta)
	move_and_slide()

## Subclass hook: the per-frame attack pattern brain.
func _pattern(_delta: float) -> void:
	pass

## Subclass hook: phase transition side effects.
func _on_phase(_new_phase: int) -> void:
	pass

## Subclass hook: reacts to incoming damage (e.g. chant interrupts).
func _on_damaged(_amount: float) -> void:
	pass

# =====================================================================
#  DAMAGE INTAKE (duck-typed contract shared with EnemyBase)
# =====================================================================
func take_damage(amount: float, _source: Node = null) -> void:
	if hp <= 0.0 or not _damageable():
		return
	if not fighting:
		activate()                    # no free sniping on a dormant boss
	if exposed:
		amount *= 2.0                 # counterplay windows reward aggression
	hp -= amount
	_flash(Color(1, 0.25, 0.2))
	_on_damaged(amount)
	EventBus.boss_health_changed.emit(maxf(hp, 0.0), max_hp)
	# Phase advance: thresholds[phase] is the NEXT boundary (1-based phase).
	while phase < phase_thresholds.size() and hp / max_hp <= float(phase_thresholds[phase]):
		phase += 1
		EventBus.boss_phase_changed.emit(boss_id, phase)
		EventBus.subtitle_requested.emit("%s shifts. (Phase %d)" % [data.get("name", "It"), phase], 2.0)
		AudioManager.play("crit", "SFX", 0.4)
		_on_phase(phase)
	if hp <= 0.0:
		die()

## Subclass hook: return false while unhittable (e.g. Burrower underground).
func _damageable() -> bool:
	return true

func stagger(seconds: float) -> void:
	staggered = true
	_stagger_timer = seconds
	_flash(Color.WHITE)
	EventBus.subtitle_requested.emit("Interrupted!", 1.2)

func apply_burn(tick_damage: float, duration: float) -> void:
	_burn_tick = tick_damage
	_burn_time = maxf(_burn_time, duration)

func _process_burn(delta: float) -> void:
	if _burn_time <= 0.0:
		return
	_burn_time -= delta
	_burn_accum += delta
	if _burn_accum >= 0.5:
		_burn_accum = 0.0
		take_damage(_burn_tick)

func die() -> void:
	if hp > 0.0:
		hp = 0.0
	fighting = false
	EventBus.boss_defeated.emit(boss_id)
	EventBus.combat_state_changed.emit(false)
	EventBus.subtitle_requested.emit("%s is destroyed." % data.get("name", "It"), 3.0)
	SaveManager.stat_add_kill(boss_id)
	# Essence shower.
	var Pickup := load("res://scripts/items/Pickup.gd")
	for i in range(5):
		var p = Pickup.new()
		p.setup("essence", 8.0)
		get_parent().add_child(p)
		p.global_position = global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))
	# Guaranteed equipment drop; commons are rerolled once (boss-tier loot).
	var luck := 0.0
	var pl = GameManager.player
	if pl and pl.stats:
		luck = pl.stats.stat("luck")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var iid := Database.roll_item_id(rng, luck)
	if String(Database.get_item(iid).get("rarity", "")) == "common":
		iid = Database.roll_item_id(rng, luck)
	var ip = Pickup.new()
	ip.setup_item(iid)
	get_parent().add_child(ip)
	ip.global_position = global_position + Vector3(0, 0.5, -1.5)
	if on_defeated.is_valid():
		on_defeated.call()
	collision_layer = 0
	remove_from_group("enemies")
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.0, 0.05, 1.0), 1.2)
	tw.tween_callback(queue_free)

# =====================================================================
#  SHARED HELPERS
# =====================================================================
func player():
	return GameManager.player

func player_pos() -> Vector3:
	var pl = GameManager.player
	return pl.global_position if pl else global_position

func dist_to_player() -> float:
	return global_position.distance_to(player_pos())

func face_player(turn := 0.15) -> void:
	var to := player_pos() - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), turn)

func move_toward_point(target: Vector3, speed: float) -> void:
	var dir := target - global_position
	dir.y = 0.0
	if dir.length() > 0.3:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

func stop_moving() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func _flash(color: Color) -> void:
	if _mat == null:
		return
	_mat.albedo_color = color
	var t := get_tree().create_timer(0.12, false)
	t.timeout.connect(_restore_color)

func _restore_color() -> void:
	if _mat and hp > 0.0:
		_mat.albedo_color = _base_color

func hurt_player(amount: float, trauma := 0.35) -> void:
	var pl = GameManager.player
	if pl == null:
		return
	pl.take_damage(amount, self)
	if pl.cam:
		pl.cam.add_trauma(trauma)

# --- attack primitives ------------------------------------------------
## Telegraphed projectile aimed at `target` (usually player_pos()).
func _shoot_at(from: Vector3, target: Vector3, speed: float, dmg: float, color := Color(0.4, 0.7, 1.0)) -> void:
	var BossProjectile := load("res://scripts/bosses/BossProjectile.gd")
	var p = BossProjectile.new()
	get_parent().add_child(p)
	p.global_position = from
	p.setup((target - from).normalized(), speed, dmg, color)

## Telegraphed ground ring: red disc for `delay`, then damages the player if
## still inside `radius` of `center`.
func _ring_attack(center: Vector3, radius: float, delay: float, dmg: float) -> void:
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.06
	disc.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.25, 0.15, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.2)
	mat.emission_energy_multiplier = 1.2
	disc.material_override = mat
	get_parent().add_child(disc)
	disc.global_position = Vector3(center.x, 0.08, center.z)
	AudioManager.play_at("dodge", center, get_parent(), 0.5)
	var t := get_tree().create_timer(delay, false)
	t.timeout.connect(func():
		var pl = GameManager.player
		if pl and Vector2(pl.global_position.x - center.x, pl.global_position.z - center.z).length() <= radius:
			hurt_player(dmg, 0.45)
		if is_instance_valid(disc):
			disc.queue_free())

## Falling rock with a ground warning marker.
func _fall_rock(ground_pos: Vector3, dmg: float) -> void:
	var FallingRock := load("res://scripts/bosses/FallingRock.gd")
	var r = FallingRock.new()
	get_parent().add_child(r)
	r.setup(ground_pos, dmg)

## Lingering damage zone (flood water, acid, void).
func _hazard(center: Vector3, size: Vector3, dps: float, life: float, color := Color(0.25, 0.5, 0.7, 0.5)) -> void:
	var HazardZone := load("res://scripts/bosses/HazardZone.gd")
	var h = HazardZone.new()
	get_parent().add_child(h)
	h.global_position = Vector3(center.x, 0.2, center.z)
	h.setup(size, dps, life, color)

## Spawn regular enemies as adds around the boss.
func _summon(species: String, count: int) -> void:
	var EnemyBase := load("res://scripts/enemies/EnemyBase.gd")
	for i in range(count):
		var e = EnemyBase.new()
		get_parent().add_child(e)
		e.global_position = global_position + Vector3(randf_range(-3, 3), 0.5, randf_range(-3, 3))
		e.setup(species, RunManager.stage_index)
		EventBus.enemy_spawned.emit(e)
