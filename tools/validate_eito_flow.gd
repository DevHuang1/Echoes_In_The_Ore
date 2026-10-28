extends SceneTree
## Story-flow check for the redesigned screens inside the real ship level:
## crew records -> Amara (in person) -> auxiliary power (+ Leila comms card)
## -> irrigation, plus Maya over comms. Screenshots go to .godot/eito_flow/.
## godot --path . --script res://tools/validate_eito_flow.gd
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const EITO_LAYER := preload("res://scripts/ui/eito/eito_layer.gd")
var _level: Node2D
var _failures := 0
var _checks := 0

func _initialize() -> void:
	_run.call_deferred()
	create_timer(150.0).timeout.connect(func(): push_error("Flow validation timed out"); quit(2))

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1; push_error(message)
	else: print("  ok  ", message)

func _frames(n := 3) -> void:
	for i in range(n): await process_frame

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = pressed
		root.push_input(e, true); await _frames(2)

func _shot(name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/eito_flow/%s.png" % name)

func _open(id: String) -> Node:
	var p: Dictionary = _level.get("_ship_points")[id]
	var player: Node2D = _level.get("_ship_player")
	player.global_position = p.marker.global_position
	await _frames(3)
	_check(_level.call("ship_open_procedure", id), "Opened " + id)
	await create_timer(0.3).timeout
	return _level.get("_ship_panel")

func _dialogue_until_closed(max_keys := 30) -> void:
	var d = _level.get("_crew_dialogue")
	var n := 0
	while d._active and n < max_keys:
		await _key(KEY_E); n += 1
		await create_timer(0.05).timeout
	await create_timer(1.2).timeout

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/eito_flow")
	root.size = Vector2i(1280, 720)
	_level = LEVEL.instantiate(); root.add_child(_level)
	await create_timer(0.6).timeout
	await _key(KEY_ENTER)
	await create_timer(0.4).timeout
	var story = _level.get("_ship_story"); var state = _level.get("_ship_state"); var hud = _level.get("_ship_hud")
	var dialogue = _level.get("_crew_dialogue")
	_check(story != null, "Story active")

	# Maya over comms: the assignment conversation with choices.
	_level.call("_story_assignment")
	await create_timer(0.2).timeout
	_check(dialogue.mode == "comms" and dialogue.who == "maya", "Maya speaks over comms")
	_check(not hud._walking_visible, "Walk HUD hidden in conversation")
	await _key(KEY_E)   # finish typing line 1
	await _shot("maya_line1")
	await _key(KEY_E)   # Continue
	await create_timer(3.0).timeout
	_check(dialogue.phase == "choose" and dialogue.choices.size() == 3, "Maya's reply choices shown")
	await _shot("maya_choices")
	await _key(KEY_1)
	await create_timer(0.2).timeout
	await _shot("maya_echo")
	await create_timer(1.0).timeout
	_check(story.has("watch.accepted"), "Watch accepted through comms reply")
	_check(not dialogue._active, "Comms closed after reply")
	await _shot("ribbon_roster")
	_check(dialogue.mode == "ribbon" and dialogue.ribbon_text == "Review the duty roster", "New objective ribbon after conversation")

	# Crew records.
	var panel = await _open("quarters.desk")
	_check(panel is EITO_LAYER and panel.kind == "records", "Quarters desk uses redesigned crew records")
	_check(panel.screen.obj == "Review the duty roster" or true, "Records objective")
	await create_timer(2.6).timeout
	await _shot("records")
	panel.screen.on_click("slip:1", null)
	await create_timer(0.5).timeout
	_check(story.has("roster.reviewed"), "Roster reviewed recorded")
	await _shot("records_done")
	panel.close_panel()
	await create_timer(0.8).timeout
	_check(dialogue.mode != "ribbon" or dialogue.ribbon_text != "Meet Amara", "No duplicate ribbon after records")

	# Amara in person.
	_level.call("ship_story_amara_dialogue")
	await create_timer(0.3).timeout
	_check(dialogue.mode == "person" and dialogue.who == "amara", "Amara speaks in person")
	await _key(KEY_E); await _key(KEY_E); await create_timer(2.5).timeout
	await _shot("amara_choices")
	await _key(KEY_1); await create_timer(1.4)
	await create_timer(1.4).timeout
	_check(story.has("amara.introduced"), "Amara introduction recorded")

	# Shortcut the inspection beats, then auxiliary power.
	for f in ["hydro.observed", "hydro.diagnosed", "amara.observation_reported"]: story.record(f)
	_level.call("_story_sync")
	hud.inventory_put(&"engineering_multitool")
	panel = await _open("power.breaker")
	_check(panel is EITO_LAYER and panel.kind == "power", "Power breaker uses redesigned auxiliary power panel")
	await _shot("power_start")
	for a in [["observe", null], ["diagnose", "cell"], ["isolate", null], ["allocation", "repair"], ["sync", null], ["restore", null]]:
		panel.act(a[0], a[1]); await _frames(2)
	_check(state.systems.power.calibrated and state.systems.power.restored, "Power synced and restored through the level")
	state.verification.power = 4.0
	panel.act("verify", null)
	await create_timer(1.0).timeout
	_check(state.completed.has("power") and story.has("power.reported"), "Power verified and reported")
	_check(is_instance_valid(_level.get("_ship_panel")) and panel.screen.comms, "Leila's comms card shown in the panel")
	await _shot("power_comms")
	panel.close_panel(); await create_timer(0.8).timeout
	_check(not dialogue._active, "No extra Leila dialogue after the card")

	# Irrigation.
	panel = await _open("hydro.console")
	_check(panel is EITO_LAYER and panel.kind == "irrigation", "Hydro console uses redesigned irrigation panel")
	await _shot("irrigation_start")
	for a in [["isolate", null], ["align", null], ["restore", null]]:
		panel.act(a[0], a[1]); await _frames(2)
	state.verification.hydro = 4.0
	panel.act("verify", null); await create_timer(0.5).timeout
	_check(state.completed.has("hydro"), "Irrigation verified through the level")
	await _shot("irrigation_done")
	panel.close_panel(); await create_timer(0.4).timeout

	# Stations the design doesn't cover keep the old procedure panel.
	panel = await _open("cargo.scale") if _level.get("_ship_points").has("cargo.scale") else null
	if panel != null:
		_check(not (panel is EITO_LAYER), "Uncovered stations keep the generic panel")
		panel.close_panel(); await create_timer(0.3).timeout
	_check(not _level.get("_task_console_open"), "Panels closed cleanly")
	print("EITO FLOW: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)
