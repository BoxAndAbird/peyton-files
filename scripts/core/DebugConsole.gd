extends Node
## DebugConsole.gd  (Autoload singleton: "DebugConsole")
##
## Developer console (bible output-contract requirement #7). Toggle with the
## "debug_console" action (` or F1). Builds its own CanvasLayer UI in code so it
## needs no scene. Runs while the tree is paused (PROCESS_MODE_ALWAYS).
##
## Commands are resolved against GameManager/RunManager/SpawnDirector; commands
## for not-yet-built systems print a friendly notice instead of crashing.

var _layer: CanvasLayer
var _panel: PanelContainer
var _input: LineEdit
var _output: RichTextLabel
var _visible := false
var _fps_overlay: Label
var _show_fps := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	EventBus.debug_message.connect(_println)

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)

	# Persistent FPS/entity overlay (top-left).
	_fps_overlay = Label.new()
	_fps_overlay.position = Vector2(8, 8)
	_fps_overlay.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	_fps_overlay.visible = false
	_layer.add_child(_fps_overlay)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.custom_minimum_size = Vector2(0, 260)
	_panel.visible = false
	_layer.add_child(_panel)

	var vb := VBoxContainer.new()
	_panel.add_child(vb)
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.custom_minimum_size = Vector2(0, 210)
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_output)
	_input = LineEdit.new()
	_input.placeholder_text = "command (type 'help')"
	_input.text_submitted.connect(_on_submit)
	vb.add_child(_input)

	_println("[color=#8fdcff]Below the Hollow debug console.[/color] Type 'help'.")

func _process(_delta: float) -> void:
	if _show_fps and _fps_overlay.visible:
		var n := 0
		if GameManager.world:
			n = _count_nodes(GameManager.world)
		_fps_overlay.text = "FPS %d | nodes %d | state %d | stage %d" % [
			Engine.get_frames_per_second(), n, GameManager.state, RunManager.stage_index]

func _count_nodes(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count_nodes(ch)
	return c

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_console"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	_visible = not _visible
	_panel.visible = _visible
	if _visible:
		_input.grab_focus()
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if GameManager.state == GameManager.State.PLAYING:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _println(text: String) -> void:
	if _output:
		_output.append_text(text + "\n")

# =====================================================================
#  COMMANDS
# =====================================================================
func _on_submit(text: String) -> void:
	_input.clear()
	if text.strip_edges() == "":
		return
	_println("[color=#888]> " + text + "[/color]")
	var parts := text.strip_edges().split(" ", false)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)
	_run(cmd, args)

func _run(cmd: String, args: PackedStringArray) -> void:
	match cmd:
		"help":
			_println("Commands: help, fps, seed <n>, class <id>, startrun <class> [seed], "
				+ "stage <n>, regen, complete, spawn <enemy> [count], boss <id>, "
				+ "kill_all, heal [amt], god, sanity <0-100>, upgrade, give <item_id>, "
				+ "essence <n>, list <classes|enemies|stages|upgrades>, menu, quit")
		"fps":
			_show_fps = not _show_fps
			_fps_overlay.visible = _show_fps
		"seed":
			if args.size() > 0:
				RunManager.seed_value = int(args[0]); RunManager.rng.seed = int(args[0])
				_println("seed = %d" % RunManager.seed_value)
		"class":
			if args.size() > 0 and Database.CLASSES.has(args[0]):
				RunManager.class_id = args[0]; _println("class = " + args[0])
			else: _println("unknown class")
		"startrun":
			var cid := args[0] if args.size() > 0 else RunManager.class_id
			var sd := int(args[1]) if args.size() > 1 else 0
			if not Database.CLASSES.has(cid): _println("unknown class"); return
			RunManager.start_new(cid, sd); GameManager._load_current_stage()
			_println("run started: %s seed %d" % [cid, RunManager.seed_value])
		"stage":
			if args.size() > 0:
				RunManager.stage_index = clampi(int(args[0]), 0, Database.stage_count() - 1)
				GameManager._load_current_stage(); _println("stage -> %d" % RunManager.stage_index)
		"regen":
			GameManager._load_current_stage(); _println("stage regenerated")
		"complete":
			GameManager.complete_stage()
		"spawn":
			_cmd_spawn(args)
		"boss":
			_println("boss arenas arrive in the boss step; id noted: " + (args[0] if args.size() > 0 else "?"))
		"kill_all":
			var k := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.has_method("die"):
					e.call("die")   # call(): loop var is typed Node
					k += 1
			_println("killed %d" % k)
		"heal":
			var amt := float(args[0]) if args.size() > 0 else 9999.0
			if GameManager.player and GameManager.player.has_method("heal"):
				GameManager.player.heal(amt); _println("healed")
			else: _println("no player")
		"god":
			if GameManager.player and "godmode" in GameManager.player:
				GameManager.player.godmode = not GameManager.player.godmode
				_println("godmode = %s" % str(GameManager.player.godmode))
			else: _println("no player")
		"sanity":
			if args.size() > 0:
				var sm = GameManager.current_stage.get_node_or_null("SanityManager") if GameManager.current_stage else null
				if sm:
					sm.set_sanity(float(args[0]))
					_println("sanity -> " + args[0])
				else:
					_println("no active stage / sanity manager")
		"upgrade":
			GameManager.change_state(GameManager.State.UPGRADE)
			var up = GameManager.ui.get_screen("upgrade")
			if up and up.has_method("offer"): up.offer()
		"give":
			if args.size() > 0: EventBus.item_picked_up.emit(args[0]); _println("gave " + args[0])
		"essence":
			if args.size() > 0: RunManager.add_essence(int(args[0])); _println("essence = %d" % RunManager.essence)
		"list":
			_cmd_list(args)
		"menu":
			GameManager.return_to_menu()
		"quit":
			get_tree().quit()
		_:
			_println("[color=#e88]unknown command:[/color] " + cmd)

func _cmd_spawn(args: PackedStringArray) -> void:
	if args.size() == 0:
		_println("usage: spawn <enemy_id> [count]"); return
	var eid := args[0]
	if not Database.ENEMIES.has(eid):
		_println("unknown enemy: " + eid); return
	var count := int(args[1]) if args.size() > 1 else 1
	# SpawnDirector is added in the enemy step; guard so this never crashes.
	if GameManager.current_stage and GameManager.current_stage.has_method("debug_spawn_enemy"):
		for i in count:
			GameManager.current_stage.debug_spawn_enemy(eid)
		_println("spawned %d x %s" % [count, eid])
	else:
		_println("enemy system not built yet (comes in the enemy step)")

func _cmd_list(args: PackedStringArray) -> void:
	var what := args[0] if args.size() > 0 else "classes"
	match what:
		"classes": _println(", ".join(Database.CLASS_ORDER))
		"enemies": _println(", ".join(Database.ENEMIES.keys()))
		"stages":
			var s := ""
			for i in Database.STAGES.size(): s += "%d:%s  " % [i, Database.STAGES[i]["id"]]
			_println(s)
		"upgrades":
			var s := ""
			for u in Database.UPGRADES: s += u["id"] + " "
			_println(s)
		_: _println("list classes|enemies|stages|upgrades")
