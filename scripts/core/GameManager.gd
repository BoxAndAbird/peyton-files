extends Node
## GameManager.gd  (Autoload singleton: "GameManager")
##
## The spine of the game (bible section 21): owns the global state machine,
## drives screen transitions and the gameplay world (stage build + player
## spawn), and controls pause.
##
## It is "bound" by Main.gd at boot, which hands it the two containers it needs:
##   world (Node3D)  - where stages/players/enemies live
##   ui (UIManager)  - the screen stack / HUD
## Everything else talks to GameManager through these + EventBus.

enum State { BOOT, TITLE, MAIN_MENU, CLASS_SELECT, SETTINGS, PLAYING, PAUSED,
	UPGRADE, DEATH, VICTORY, INVENTORY }

var state: int = State.BOOT
var world: Node3D                 # gameplay container (set by Main)
var ui                            # UIManager (set by Main)
var player = null                 # PlayerController (untyped: duck-typed calls)
var current_stage = null          # StageBuilder root (untyped: duck-typed calls)
var _return_state: int = State.MAIN_MENU  # where pause/settings returns to

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_died.connect(_on_player_died)

## Called once by Main.gd after it builds the containers.
func bind(world_node: Node3D, ui_node) -> void:
	world = world_node
	ui = ui_node
	change_state(State.TITLE)

# =====================================================================
#  STATE MACHINE
# =====================================================================
func change_state(new_state: int) -> void:
	var old := state
	state = new_state
	match new_state:
		State.TITLE:
			_teardown_world()
			get_tree().paused = false
			ui.show_only("title")
		State.MAIN_MENU:
			_teardown_world()
			get_tree().paused = false
			ui.show_only("main_menu")
		State.CLASS_SELECT:
			ui.show_only("class_select")
		State.SETTINGS:
			ui.show_screen("settings")     # overlay, keeps prior screen behind
		State.PLAYING:
			get_tree().paused = false
			ui.show_only("hud")
			_capture_mouse(true)
		State.PAUSED:
			get_tree().paused = true
			_capture_mouse(false)
			ui.show_screen("pause")
		State.UPGRADE:
			get_tree().paused = true
			_capture_mouse(false)
			ui.show_screen("upgrade")
		State.INVENTORY:
			get_tree().paused = true
			_capture_mouse(false)
			ui.show_screen("inventory")
		State.DEATH:
			get_tree().paused = true
			_capture_mouse(false)
			ui.show_only("death")
		State.VICTORY:
			get_tree().paused = true
			_capture_mouse(false)
			ui.show_only("victory")
	EventBus.game_state_changed.emit(new_state, old)

# =====================================================================
#  INPUT (pause)
# =====================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif state == State.PAUSED:
			resume()
			get_viewport().set_input_as_handled()
		elif state == State.INVENTORY:
			close_inventory()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if state == State.PLAYING:
			open_inventory()
			get_viewport().set_input_as_handled()
		elif state == State.INVENTORY:
			close_inventory()
			get_viewport().set_input_as_handled()

func open_inventory() -> void:
	change_state(State.INVENTORY)

func close_inventory() -> void:
	if state != State.INVENTORY:
		return
	ui.hide_screen("inventory")
	change_state(State.PLAYING)

func toggle_pause() -> void:
	if state == State.PLAYING:
		_return_state = State.PLAYING
		change_state(State.PAUSED)
		EventBus.pause_toggled.emit(true)

func resume() -> void:
	if state == State.PAUSED:
		change_state(State.PLAYING)
		EventBus.pause_toggled.emit(false)

# =====================================================================
#  RUN FLOW
# =====================================================================
func go_to_main_menu() -> void:
	change_state(State.MAIN_MENU)

func open_class_select() -> void:
	change_state(State.CLASS_SELECT)

func open_settings() -> void:
	_return_state = state
	change_state(State.SETTINGS)

func close_settings() -> void:
	ui.hide_screen("settings")
	state = _return_state
	# Re-assert mouse capture if we returned mid-game.
	if state == State.PLAYING:
		_capture_mouse(true)

func start_run(class_id: String) -> void:
	RunManager.start_new(class_id)
	_load_current_stage()

func continue_run() -> void:
	if not SaveManager.has_continue():
		return
	RunManager.from_snapshot(SaveManager.load_run())
	_load_current_stage()

func _load_current_stage() -> void:
	_teardown_world()
	var stage_data := RunManager.current_stage_data()
	# StageBuilder builds a lit, navigable room set for this stage.
	var StageBuilder := load("res://scripts/procgen/StageBuilder.gd")
	current_stage = StageBuilder.new()
	current_stage.name = "Stage_%d" % RunManager.stage_index
	world.add_child(current_stage)
	current_stage.build(stage_data, RunManager.stage_rng())
	# Spawn player at the stage entrance.
	_spawn_player(current_stage.get_spawn_point())
	# Per-stage sanity system (drain/recovery/events).
	var SanityMgr := load("res://scripts/sanity/SanityManager.gd")
	var sanity_node: Node = SanityMgr.new()
	sanity_node.name = "SanityManager"
	current_stage.add_child(sanity_node)
	change_state(State.PLAYING)
	RunManager.save_continue()
	EventBus.stage_loaded.emit(RunManager.stage_index, stage_data["id"])
	if SettingsManager.subtitles_on():
		EventBus.subtitle_requested.emit(stage_data["name"], 3.0)

func _spawn_player(spawn: Vector3) -> void:
	var PC := load("res://scripts/player/PlayerController.gd")
	player = PC.new()
	world.add_child(player)
	player.global_position = spawn + Vector3.UP * 1.0
	player.setup(RunManager.class_id)
	EventBus.player_spawned.emit(player)

## Called by the stage's exit trigger (or debug) when the stage is finished.
func complete_stage() -> void:
	EventBus.stage_cleared.emit(RunManager.stage_index)
	# Persist carry-over resources before leaving.
	if player and player.has_method("get_health"):
		RunManager.carry_health = player.get_health()
	if RunManager.can_offer_upgrade():
		change_state(State.UPGRADE)
		if ui.has_method("get_screen"):
			var up = ui.get_screen("upgrade")
			if up and up.has_method("offer"):
				up.offer()
	else:
		_after_upgrade_continue()

## Called by the upgrade screen once a pick is made.
func _after_upgrade_continue() -> void:
	if RunManager.advance_stage():
		_load_current_stage()
	else:
		win_run()

func win_run() -> void:
	RunManager.end_run(true)
	change_state(State.VICTORY)

func _on_player_died() -> void:
	if state != State.PLAYING:
		return
	RunManager.end_run(false)
	change_state(State.DEATH)

func return_to_menu() -> void:
	_teardown_world()
	go_to_main_menu()

# =====================================================================
#  WORLD LIFECYCLE
# =====================================================================
func _teardown_world() -> void:
	player = null
	current_stage = null
	if world:
		for c in world.get_children():
			c.queue_free()

func _capture_mouse(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
