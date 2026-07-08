extends Node
## Main.gd - root scene script. The ONLY hand-authored scene in the project
## (everything else is constructed in code for robustness). Builds:
##   World (Node3D)          - gameplay container handed to GameManager
##   WorldEnvironment        - global environment; brightness slider target
##   UILayer > UIManager     - screen stack
## then binds GameManager, which takes over flow (starting at TITLE).
##
## Listens: EventBus.brightness_changed to drive environment exposure so the
## settings brightness slider has a real-time effect (bible section 19).

var world: Node3D
var world_env: WorldEnvironment
var ui: UIManager

func _ready() -> void:
	# --- gameplay container -------------------------------------------
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	# --- global environment (readability floor: never pitch black) ----
	world_env = WorldEnvironment.new()
	world_env.name = "GlobalEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.37, 0.42)
	env.ambient_light_energy = 0.9   # enforced minimum readability
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.07, 0.09)
	env.fog_density = 0.015
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	world_env.environment = env
	add_child(world_env)

	# --- UI layer -------------------------------------------------------
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 10
	add_child(ui_layer)
	ui = UIManager.new()
	ui.name = "UIManager"
	ui_layer.add_child(ui)

	# --- bind the game spine --------------------------------------------
	EventBus.brightness_changed.connect(_on_brightness)
	GameManager.bind(world, ui)
	EventBus.say("Main booted. World + UI bound.")

	# Headless end-to-end verification: godot --headless --path . -- --smoke
	if OS.get_cmdline_user_args().has("--smoke"):
		var SmokeTest := load("res://scripts/core/SmokeTest.gd")
		var st: Node = SmokeTest.new()
		st.name = "SmokeTest"
		add_child(st)

func _on_brightness(value: float) -> void:
	# Brightness 0.5-1.5 and gamma map onto the environment adjustments.
	if world_env and world_env.environment:
		world_env.environment.adjustment_brightness = value
		world_env.environment.adjustment_contrast = 1.0
		world_env.environment.adjustment_saturation = 1.0
