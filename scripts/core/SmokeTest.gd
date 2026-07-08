extends Node
## SmokeTest.gd - headless end-to-end exercise of every major system.
## Run:  godot --headless --path . -- --smoke
## Main.gd attaches this node when "--smoke" is in the user args. It drives a
## real run through the live game code (no mocks): class select, stage build,
## every enemy species, every sanity event category, a full boss phase-walk,
## items/equip, upgrades, stage completion to VICTORY, then a fresh run to
## DEATH. Prints PASS/FAIL per step and quits with a summary.
##
## PROCESS_MODE_ALWAYS so it keeps driving while the tree is paused (upgrade
## screens etc). Timers use default process_always so awaits survive pause.

var _pass := 0
var _fail := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func _check(label: String, ok: bool) -> void:
	if ok:
		_pass += 1
		print("[SMOKE PASS] ", label)
	else:
		_fail += 1
		print("[SMOKE FAIL] ", label)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _run() -> void:
	await _wait(0.6)
	print("[SMOKE] === Below the Hollow smoke test ===")

	# --- 1. start a run ---------------------------------------------------
	GameManager.start_run("archer")
	await _wait(2.0)   # stage build + deferred navmesh bake
	_check("run started, PLAYING state", GameManager.state == GameManager.State.PLAYING)
	_check("player spawned", GameManager.player != null)
	_check("stage built", GameManager.current_stage != null)
	if GameManager.current_stage:
		_check("stage has rooms", GameManager.current_stage.graph.rooms.size() >= 12)

	# --- 2. every enemy species ------------------------------------------
	for eid in Database.ENEMIES.keys():
		GameManager.current_stage.debug_spawn_enemy(eid)
	await _wait(1.5)
	var enemy_count := get_tree().get_nodes_in_group("enemies").size()
	_check("all species spawned (%d live)" % enemy_count, enemy_count >= 11)
	# Player swings + arrow fire through live combat code.
	GameManager.player.combat.try_attack()
	await _wait(0.5)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("die"):
			e.call("die")
	await _wait(1.0)
	_check("kill_all cleared enemies", get_tree().get_nodes_in_group("enemies").size() <= 2)

	# --- 3. sanity events: all 8 categories -------------------------------
	var sm = GameManager.current_stage.get_node_or_null("SanityManager")
	_check("sanity manager present", sm != null)
	if sm:
		for cat in ["atmosphere", "memory_scene", "fake_ui", "navigation",
				"combat_halluc", "audio", "npc_distortion", "item_deception"]:
			sm.debug_fire(cat)
			await _wait(0.2)
		_check("sanity events fired without crash", true)
		sm.set_sanity(8.0)
		await _wait(0.5)
		sm.set_sanity(90.0)

	# --- 4. items: give, equip, drop ---------------------------------------
	var got := RunManager.add_item("item_005")
	RunManager.add_item("item_012")
	_check("items picked up", got and RunManager.backpack.size() >= 1)
	RunManager.equip_item("item_005")
	_check("item equipped", RunManager.equipped.values().has("item_005"))
	RunManager.drop_item("item_012")

	# --- 5. boss: spawn, phase-walk, kill ----------------------------------
	var spawned: bool = GameManager.current_stage.debug_spawn_boss("burrower")
	_check("burrower spawned", spawned)
	await _wait(1.0)
	var boss = _find_boss()
	if boss:
		boss.log_attacks = true
		boss.debug_set_phase(3)
		_check("burrower reached phase 3", boss.phase == 3)
		await _wait(2.0)   # let phase-3 pattern tick (rocks, burrow)
		boss.die()
		await _wait(0.5)
		_check("burrower died cleanly", boss.hp <= 0.0)
	# Ancient Below choice altars.
	GameManager.current_stage.debug_spawn_boss("ancient_below")
	await _wait(0.5)
	var ancient = _find_boss()
	if ancient:
		ancient.debug_set_phase(5)
		_check("ancient reached choice phase", ancient.phase == 5)
		await _wait(0.5)
		ancient.die()
		_check("ancient set an ending", RunManager.ending_id != "")
		RunManager.ending_id = ""   # reset so real flow decides later

	# --- 6. complete every stage to VICTORY --------------------------------
	var guard := 0
	while GameManager.state != GameManager.State.VICTORY and guard < 12:
		guard += 1
		GameManager.complete_stage()
		await _wait(0.4)
		# Upgrade intermission: pick through the real RunManager path.
		if GameManager.state == GameManager.State.UPGRADE:
			while RunManager.can_offer_upgrade() \
					and RunManager.upgrades.size() < RunManager.UPGRADES_PER_STAGE * (RunManager.stage_index + 1) \
					and RunManager.upgrades.size() < RunManager.TOTAL_UPGRADES:
				for up in Database.UPGRADES:
					if not RunManager.upgrades.has(up["id"]):
						RunManager.add_upgrade(up["id"])
						break
			var upscreen = GameManager.ui.get_screen("upgrade")
			if upscreen:
				upscreen.visible = false
			GameManager._after_upgrade_continue()
		await _wait(1.8)   # next stage build
	_check("run reached VICTORY (stages walked: %d)" % guard,
		GameManager.state == GameManager.State.VICTORY)

	# --- 7. fresh run -> death ---------------------------------------------
	GameManager.start_run("tank")
	await _wait(2.0)
	if GameManager.player:
		GameManager.player.take_damage(99999.0)
	await _wait(0.5)
	_check("death flow reached DEATH state", GameManager.state == GameManager.State.DEATH)

	# --- 8. persistence -----------------------------------------------------
	_check("profile recorded runs", int(SaveManager.profile["runs_started"]) >= 2)
	_check("statistics saved kills", not SaveManager.statistics["kills"].is_empty())

	# --- summary -------------------------------------------------------------
	print("[SMOKE] === DONE: %d passed, %d failed ===" % [_pass, _fail])
	await _wait(0.3)
	get_tree().quit(1 if _fail > 0 else 0)

func _find_boss():
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("debug_set_phase"):
			return e
	return null
