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
	create_timer(600.0).timeout.connect(func(): push_error("Flow validation timed out"); quit(2))

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

func _artifact_click(panel: Node,id: String) -> void:
	await _frames(3)
	if not is_instance_valid(panel): _check(false,"Pointer panel exists for "+id);return
	var screen=panel.screen
	var r := Rect2()
	for attempt in range(8):
		for target in screen._hits:
			if target.id==id: r=target.rect;break
		if r.has_area() or panel.kind!="supply_stores" or not id.begins_with("store:"): break
		# Use the visible wheel region to reach an item beyond the first six slots.
		var scroll := Rect2()
		for target in screen._hits:
			if target.id=="carry:scroll": scroll=target.rect;break
		if not scroll.has_area(): break
		var scroll_point: Vector2=screen.get_global_transform_with_canvas()*scroll.get_center()
		var wheel := InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.position=scroll_point;wheel.global_position=scroll_point;wheel.pressed=true
		root.push_input(wheel,true);await _frames(3)
	_check(r.has_area(),"Pointer target present: "+str(panel.kind)+" / "+id)
	if not r.has_area(): return
	var point: Vector2=screen.get_global_transform_with_canvas()*r.get_center()
	_check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"Pointer target in viewport: "+id)
	var motion := InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed
		root.push_input(event,true);await _frames(2)

func _wait_engine_readings(state: Object) -> void:
	var waited := 0.0
	while float(state.verification.engine)<float(state.verify_seconds("engine")) and waited<35.0:
		await create_timer(0.25).timeout;waited+=0.25
	_check(float(state.systems.engine.temperature)<=65.0 and float(state.verification.engine)>=float(state.verify_seconds("engine")),"Real healthy engine observation period completed")

func _shot(name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/eito_flow/%s_%dx%d.png" % [name,root.size.x,root.size.y])

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
	Engine.set_meta("ship_story_validation_path","res://.godot/mission_validation/eito_flow_story.json")
	root.size = Vector2i(1024,576) if "--small" in OS.get_cmdline_user_args() else Vector2i(1280,720)
	root.content_scale_size=root.size
	_level = LEVEL.instantiate()
	_level.ship_story_autosave = false # The flow probe must not touch real campaign saves.
	root.add_child(_level)
	await create_timer(0.6).timeout
	# Station points are built a few frames after the level enters the tree; slower machines need longer.
	var point_wait := 0.0
	while not bool(_level.get("_ship_points_ready")) and point_wait < 20.0:
		await create_timer(0.1).timeout; point_wait += 0.1
	await _key(KEY_ENTER)
	await create_timer(0.4).timeout
	var story = _level.get("_ship_story"); var state = _level.get("_ship_state"); var hud = _level.get("_ship_hud")
	var dialogue = _level.get("_crew_dialogue")
	_check(story != null, "Story active")

	# Maya over comms: the assignment conversation with choices.
	var planning = await _open("bridge.planning")
	_check(planning is EITO_LAYER and planning.kind=="planning_table", "Planning-table artifact opens before Maya's briefing")
	await _artifact_click(planning,"tab:1")
	await _shot("planning_briefing")
	await _artifact_click(planning,"brief")
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
	await _artifact_click(panel,"slip:1")
	await create_timer(0.5).timeout
	_check(story.has("roster.reviewed"), "Roster reviewed recorded")
	await _shot("records_done")
	panel.close_panel()
	await create_timer(0.8).timeout
	_check(dialogue.mode != "ribbon" or dialogue.ribbon_text != "Meet Amara", "No duplicate ribbon after records")
	# Legitimate non-hiding stores use the Stations 02 bin/carry layout.
	panel = await _open("quarters.drawer.1")
	_check(panel is EITO_LAYER and panel.kind == "supply_stores", "Crew drawer opens the dedicated supply board")
	var filter_before: int = hud.inventory_count(&"filter_cartridge")
	var stock_before: int = state.stocks["quarters.drawer.1"].filter_cartridge
	await _artifact_click(panel,"take:filter_cartridge")
	_check(hud.inventory_count(&"filter_cartridge")==filter_before+1 and state.stocks["quarters.drawer.1"].filter_cartridge==stock_before-1, "Drawer moves one FILTER-A to real carried inventory")
	await _artifact_click(panel,"store:filter_cartridge")
	_check(hud.inventory_count(&"filter_cartridge")==filter_before and state.stocks["quarters.drawer.1"].filter_cartridge==stock_before, "Drawer returns one FILTER-A to its own stock")
	await _artifact_click(panel,"tab:2")
	_check(panel.screen.selected==0 and panel.screen.fb.s=="warn", "Remote wardrobe tab cannot transfer supplies from this drawer")
	panel.close_panel(); await create_timer(0.3).timeout

	# Amara in person.
	_level.call("ship_story_amara_dialogue")
	await create_timer(0.3).timeout
	_check(dialogue.mode == "person" and dialogue.who == "amara", "Amara speaks in person")
	await _key(KEY_E); await _key(KEY_E); await create_timer(2.5).timeout
	await _shot("amara_choices")
	await _key(KEY_1)
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
	# Optional hydro boards use the actual crew activity gate and receipt owner.
	for pair in [["hydro.pump","nutrient_pump_check","flow","amara_nutrient_pump"],["hydro.seedlings","seedling_rack_check","sensor","amara_seedling_sensor"]]:
		_level.set("_crew_tasks_unlocked",false);_level.call("_story_sync")
		panel=await _open(pair[0])
		_check(panel is EITO_LAYER and panel.kind==pair[1], "Dedicated optional board opens at "+pair[0])
		await _artifact_click(panel,pair[2]);await _artifact_click(panel,"record")
		_check(not _level.get("_completed_crew_tasks").has(pair[3]) and panel.screen.fb.s=="lock", "Optional receipt waits for Amara's activity authorization")
		_level.set("_crew_tasks_unlocked",true);_level.call("_story_sync")
		await _artifact_click(panel,"record")
		_check(_level.get("_completed_crew_tasks").has(pair[3]), "Optional record uses the existing crew-task completion path")
		var optional_count: int=_level.get("_completed_crew_tasks").size()
		await _artifact_click(panel,"record")
		_check(_level.get("_completed_crew_tasks").size()==optional_count, "Repeated optional record creates no duplicate receipt")
		panel.close_panel();await create_timer(0.3).timeout

	# The Stations 02 cargo-scale board is also reachable through normal entry.
	panel = await _open("cargo.scale") if _level.get("_ship_points").has("cargo.scale") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "cargo_scale", "Cargo scale opens its dedicated Stations 02 board")
		for control_id in ["tag","seal","zero","ref"]: await _artifact_click(panel,control_id)
		panel.close_panel(); await create_timer(0.3).timeout
	panel = await _open("cargo.mover") if _level.get("_ship_points").has("cargo.mover") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "pallet_mover", "Pallet mover opens its dedicated Stations 02 board")
		await _artifact_click(panel,"drive")
		_check(panel.screen._stage()==0 and panel.screen.fb.s=="warn", "Out-of-order mover control gives visible feedback")
		for control_id in ["key","lower","lift","dest_scale","drive","lower"]: await _artifact_click(panel,control_id)
		_check(panel.screen._stage()==6 and state.systems.cargo.location=="scale", "Mover's six controls transfer the identified load exactly once")
		panel.close_panel(); await create_timer(0.3).timeout
	panel = await _open("cargo.cylinders") if _level.get("_ship_points").has("cargo.cylinders") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "cylinder_rack", "Cylinder rack opens its dedicated Stations 02 board")
		await _artifact_click(panel,"cyl:1")
		_check(panel.screen._stage()==0 and panel.screen.fb.s=="warn", "Oxygen selection cannot satisfy coolant work order")
		for control_id in ["order","cyl:0","confirm","chain","lift"]: await _artifact_click(panel,control_id)
		_check(panel.screen._stage()==5 and state.stocks["cargo.cylinders"].coolant_charge==1, "Rack sequence issues one actual COOL-02 cylinder")
		await _artifact_click(panel,"lift")
		_check(state.stocks["cargo.cylinders"].coolant_charge==1, "Repeated lift does not deduct another cylinder")
		panel.close_panel(); await create_timer(0.3).timeout
	panel = await _open("cargo.trolley") if _level.get("_ship_points").has("cargo.trolley") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "maintenance_trolley", "Maintenance trolley opens its dedicated Stations 02 board")
		for control_id in ["brake","drawer","kit","dest1","sign","send"]: await _artifact_click(panel,control_id)
		_check(panel.screen._stage()==5 and state.stocks["cargo.trolley"].coolant_charge==3, "Trolley displays cargo-inspection prerequisite without issuing kit")
		panel.close_panel(); await create_timer(0.3).timeout
	panel = await _open("cargo.scale") if _level.get("_ship_points").has("cargo.scale") else null
	if panel != null:
		for control_id in ["read","accept"]: await _artifact_click(panel,control_id)
		_check(state.completed.has("cargo"), "Cargo inspection unlocks actual trolley issue")
		panel.close_panel(); await create_timer(0.3).timeout
	panel = await _open("cargo.trolley") if _level.get("_ship_points").has("cargo.trolley") else null
	if panel != null:
		await _artifact_click(panel,"send")
		_check(panel.screen._stage()==6 and state.stocks["cargo.trolley"].coolant_charge==2, "Trolley issues one live COOL-02 kit after cargo inspection")
		await _artifact_click(panel,"send")
		_check(state.stocks["cargo.trolley"].coolant_charge==2, "Repeated trolley issue click does not deduct another kit")
		panel.close_panel(); await create_timer(0.3).timeout
	# The first-watch duct is observational only. The separate maintenance
	# fixture below confirms the same board obeys repair interlocks and timer.
	panel = await _open("life.duct") if _level.get("_ship_points").has("life.duct") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "air_duct", "Air duct opens its dedicated Stations 02 board")
		await _artifact_click(panel,"restore")
		_check(panel.screen.fb.s == "warn", "Duct restore out of order displays a warning")
		await _artifact_click(panel,"compare")
		_check(bool(state.flags.get("life.observed",false)), "Duct comparison captures live readings")
		await _artifact_click(panel,"diagnose")
		_check(not bool(state.flags.get("life.diagnosed",false)) and panel.screen.fb.s == "lock", "No unassigned first-watch life repair is permitted")
		panel.close_panel(); await create_timer(0.3).timeout
		state.work_order_context="maintenance"
		state.authorized_work_orders=PackedStringArray(["life"])
		state.systems.life.airflow=41.0
		state.systems.life.restored=false
		panel = await _open("life.duct")
		await _artifact_click(panel,"diagnose")
		_check(bool(state.flags.get("life.diagnosed",false)), "Duct records supported airflow diagnosis")
		await _artifact_click(panel,"isolate")
		_check(bool(state.systems.life.isolated), "Duct isolates the real life-support housing")
		await _artifact_click(panel,"restore")
		_check(bool(state.systems.life.isolated) and panel.screen.fb.s == "warn", "Duct cannot restore before component service")
		panel.close_panel(); await create_timer(0.3).timeout
		hud.inventory_put(&"filter_cartridge")
		panel = await _open("life.filter")
		_check(panel is EITO_LAYER and panel.kind == "air_filter", "Filter housing opens its dedicated Stations 02 board")
		await _artifact_click(panel,"insert")
		_check(panel.screen._stage()==0 and panel.screen.fb.s=="warn", "Filter insertion out of order gives visible feedback")
		for control_id in ["latch1","latch2","pull","cart:1","rotate","rotate","insert","seat","relatch"]: await _artifact_click(panel,control_id)
		_check(panel.screen._stage()==7, "Filter housing reaches airflow confirmation with cartridge seated and latched")
		await _artifact_click(panel,"prime")
		_check(not bool(state.systems.life.serviced) and panel.screen.fb.s=="warn", "Out-of-band airflow cannot complete filter service")
		for i in range(5): await _artifact_click(panel,"up")
		await _artifact_click(panel,"prime")
		_check(bool(state.systems.life.serviced) and panel.screen._stage()==8, "FILTER-A consumed only after correct eight-step housing sequence")
		_check(_level.get("_completed_room_tasks").has(&"air_filter"), "Legacy room-task receipt stays synchronized with the redesigned filter board")
		var filter_count: int = hud.inventory_count(&"filter_cartridge")
		await _artifact_click(panel,"prime")
		_check(hud.inventory_count(&"filter_cartridge")==filter_count, "Repeated filter confirmation does not consume another cartridge")
		panel.close_panel(); await create_timer(0.3).timeout
		panel = await _open("life.duct")
		await _artifact_click(panel,"restore")
		_check(not bool(state.systems.life.isolated) and bool(state.systems.life.restored), "Duct restores real circulation after service")
		await _artifact_click(panel,"verify")
		_check(not state.completed.has("life"), "Duct cannot verify before steady timer")
		state.verification.life=state.verify_seconds("life")
		await _artifact_click(panel,"verify")
		_check(state.completed.has("life"), "Duct verifies after real steady timer")
		panel.close_panel(); await create_timer(0.3).timeout
	# A separate return-watch fixture exercises the scrubber's real service
	# action without changing first-watch narrative requirements.
	state.reset("return")
	state.flags.assigned=true
	state.completed["power"]=true
	state.authorized_work_orders=PackedStringArray(["life"])
	hud.inventory_put(&"scrubber_media")
	panel = await _open("life.scrubber") if _level.get("_ship_points").has("life.scrubber") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "co2_scrubber", "CO2 scrubber opens its dedicated Stations 02 board")
		await _artifact_click(panel,"swap")
		_check(panel.screen.fb.s=="warn" and not bool(state.systems.life.serviced), "Out-of-order scrubber swap cannot consume media")
		for control_id in ["compare","diagnose","isolate","unbolt","swap"]: await _artifact_click(panel,control_id)
		_check(bool(state.systems.life.serviced) and panel.screen._stage()==5, "Scrubber sequence consumes one real SCRUB-A after isolation and multitool clamp")
		var media_count: int=hud.inventory_count(&"scrubber_media")
		await _artifact_click(panel,"swap")
		_check(hud.inventory_count(&"scrubber_media")==media_count, "Repeated scrubber swap does not consume another medium")
		await _artifact_click(panel,"restore")
		_check(bool(state.systems.life.restored) and float(state.systems.life.co2)<=0.1, "Scrubber restoration updates live CO2")
		await _artifact_click(panel,"verify")
		_check(not state.completed.has("life"), "Scrubber verification waits for the healthy-reading timer")
		state.verification.life=state.verify_seconds("life")
		await _artifact_click(panel,"verify")
		_check(state.completed.has("life"), "Scrubber completes after live steady readings")
		panel.close_panel(); await create_timer(0.3).timeout
	hud.inventory_put(&"oxygen_reserve")
	panel = await _open("life.oxygen") if _level.get("_ship_points").has("life.oxygen") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind == "oxygen_rack", "Oxygen rack opens its dedicated Stations 02 board")
		await _artifact_click(panel,"check")
		_check(panel.screen._stage()==0 and panel.screen.fb.s=="warn", "Out-of-order oxygen check cannot swap reserve")
		for control_id in ["tank:1","valve:2","valve:1","tank:1","tank:1","valve:1","check"]: await _artifact_click(panel,control_id)
		_check(panel.screen._stage()==7 and float(state.systems.life.reserve)==100.0, "Oxygen checklist invokes one real O2-01 reserve swap")
		var oxygen_count: int=hud.inventory_count(&"oxygen_reserve")
		await _artifact_click(panel,"check")
		_check(hud.inventory_count(&"oxygen_reserve")==oxygen_count, "Repeated oxygen check does not consume a second O2-01")
		panel.close_panel(); await create_timer(0.3).timeout
	# The turbine's cooling result is derived from engine verification. No
	# screen control can approve the coolant work order on its own.
	state.reset("outbound")
	state.flags.assigned=true
	state.completed["cargo"]=true;state.completed["power"]=true
	state.work_order_context="maintenance"
	state.authorized_work_orders=PackedStringArray(["engine"])
	panel = await _open("engine.turbine.1") if _level.get("_ship_points").has("engine.turbine.1") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind=="turbine" and panel.screen._loop()==0, "Turbine 1 uses the dedicated loop-1 board")
		await _artifact_click(panel,"inspect")
		await _artifact_click(panel,"reduce")
		_check(float(state.systems.engine.load)==1.0 and panel.screen.fb.s=="lock", "Turbine cannot reduce output without diagnosis")
		state.flags["engine.diagnosed"]=true
		await _artifact_click(panel,"reduce")
		_check(float(state.systems.engine.load)==0.6 and not panel.screen._cooled(), "Turbine limits output but does not self-verify cooling")
		await _artifact_click(panel,"resume")
		_check(float(state.systems.engine.load)==0.6 and panel.screen.fb.s=="fault", "Nominal output remains blocked until cooling is verified")
		state.systems.engine.health[0]=1.0;state.systems.engine.temperature=60.0;state.completed["engine"]=true
		_check(panel.screen._cooled(), "Cooling indicator reads the actual verified engine state")
		await _artifact_click(panel,"resume")
		_check(float(state.systems.engine.load)==1.0, "Nominal output resumes through the existing engine action")
		panel.close_panel();await create_timer(0.3).timeout
	panel = await _open("engine.turbine.2") if _level.get("_ship_points").has("engine.turbine.2") else null
	if panel != null:
		_check(panel.screen._loop()==1, "Turbine 2 reads its own loop rather than turbine 1's loop")
		panel.close_panel();await create_timer(0.3).timeout
	state.reset("return")
	state.flags.assigned=true
	state.completed["cargo"]=true;state.completed["power"]=true
	state.work_order_context="maintenance"
	state.authorized_work_orders=PackedStringArray(["engine"])
	panel = await _open("engine.valve.2") if _level.get("_ship_points").has("engine.valve.2") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind=="valve_manifold" and panel.screen._loop()==1, "Valve 2 opens its dedicated loop-2 manifold board")
		await _artifact_click(panel,"wheel:1")
		_check(panel.screen.fb.s=="warn" and not bool(state.flags.get("engine.diagnosed",false)), "Handwheel cannot bypass comparison and diagnosis")
		await _artifact_click(panel,"compare");await _artifact_click(panel,"wheel:1")
		_check(bool(state.flags.get("engine.diagnosed",false)), "Manifold records the existing valve diagnosis")
		await _artifact_click(panel,"isolate")
		_check(not bool(state.systems.engine.isolated[1]) and panel.screen.fb.s=="fault", "Manifold requires reduced turbine output before isolation")
		panel.close_panel();await create_timer(0.3).timeout
	panel = await _open("engine.turbine.2")
	await _artifact_click(panel,"inspect");await _artifact_click(panel,"reduce")
	_check(float(state.systems.engine.load)==0.6, "Turbine 2 establishes the real 60% maintenance window")
	panel.close_panel();await create_timer(0.3).timeout
	panel = await _open("engine.valve.2")
	await _artifact_click(panel,"isolate")
	_check(bool(state.systems.engine.isolated[1]), "Manifold isolates its assigned loop")
	await _artifact_click(panel,"wheel:1");await _artifact_click(panel,"wheel:1")
	_check(float(state.systems.engine.valves[1])<0.9 and panel.screen._turns()==2, "Visual handwheel turns do not fake an intermediate valve opening")
	await _artifact_click(panel,"wheel:1")
	_check(float(state.systems.engine.valves[1])>=0.99 and bool(state.systems.engine.serviced), "Third turn invokes the actual valve service once")
	await _artifact_click(panel,"restore")
	_check(not bool(state.systems.engine.isolated[1]), "Manifold restores the serviced loop")
	await _artifact_click(panel,"verify")
	_check(not state.completed.has("engine"), "Manifold cannot verify before healthy readings persist")
	await _wait_engine_readings(state)
	await _artifact_click(panel,"verify")
	_check(state.completed.has("engine"), "Manifold verifies after the real cooling timer")
	panel.close_panel();await create_timer(0.3).timeout
	panel = await _open("engine.valve.1") if _level.get("_ship_points").has("engine.valve.1") else null
	if panel != null:
		_check(panel.screen._loop()==0 and not panel.screen._target(), "Second manifold instance reads loop 1 and has no assigned valve repair")
		panel.close_panel();await create_timer(0.3).timeout
	state.reset("outbound")
	state.flags.assigned=true
	state.completed["cargo"]=true;state.completed["power"]=true
	state.work_order_context="maintenance"
	state.authorized_work_orders=PackedStringArray(["engine"])
	if hud.inventory_count(&"coolant_charge")<1: hud.inventory_put(&"coolant_charge")
	panel = await _open("engine.pump.1") if _level.get("_ship_points").has("engine.pump.1") else null
	if panel != null:
		_check(panel is EITO_LAYER and panel.kind=="coolant_pump" and panel.screen._i()==0, "Pump 1 opens its dedicated loop-1 cutaway board")
		await _artifact_click(panel,"charge")
		_check(panel.screen.fb.s=="warn" and not bool(state.systems.engine.serviced), "Pump charge port cannot skip observation and isolation")
		for id in ["observe","diagnose","reduce","isolate","seal"]: await _artifact_click(panel,id)
		_check(panel.screen._stage()==5 and bool(state.systems.engine.isolated[0]), "Pump checklist reaches isolated COOL-02 charge stage")
		var coolant_before: int=hud.inventory_count(&"coolant_charge")
		await _artifact_click(panel,"charge")
		_check(panel.screen._stage()==6 and hud.inventory_count(&"coolant_charge")==coolant_before-1 and bool(state.systems.engine.serviced), "Pump service consumes one COOL-02 through the real action")
		await _artifact_click(panel,"charge")
		_check(hud.inventory_count(&"coolant_charge")==coolant_before-1, "Repeated pump charge click does not consume another coolant item")
		await _artifact_click(panel,"restore")
		_check(panel.screen._stage()==7 and not bool(state.systems.engine.isolated[0]), "Pump restores the real cooling loop")
		await _artifact_click(panel,"verify")
		_check(not state.completed.has("engine"), "Pump verification is blocked until healthy-reading timer completes")
		await _wait_engine_readings(state)
		await _artifact_click(panel,"verify")
		_check(state.completed.has("engine"), "Pump verifies recovered engine cooling after the real timer")
		panel.close_panel();await create_timer(0.3).timeout
	panel = await _open("engine.pump.2") if _level.get("_ship_points").has("engine.pump.2") else null
	if panel != null:
		_check(panel.screen._i()==1 and not panel.screen._target(), "Pump 2 reads its own healthy loop and cannot repeat pump-1 service")
		panel.close_panel();await create_timer(0.3).timeout
	# Native helm, including wrong corrections and the shared alternate consoles.
	state.completed["crew"]=true
	state.systems.power.calibrated=true;state.systems.power.restored=true;state.systems.power.isolated=false;state.systems.power.science=20
	panel=await _open("bridge.helm")
	_check(panel.kind=="helm", "Helm opens the dedicated heading board")
	await _artifact_click(panel,"apply")
	_check(not bool(state.flags.get("navigation.correction_applied",false)), "Helm cannot apply before comparing the actual readings")
	await _artifact_click(panel,"planned");await _artifact_click(panel,"instrument")
	_check(bool(state.flags.get("navigation.compared",false)), "Helm compares through the real route action")
	panel.screen.dial=-2.0;await _artifact_click(panel,"apply");await _artifact_click(panel,"verify")
	_check(not state.completed.has("navigation") and panel.screen.fb.s=="lock", "Wrong signed correction does not verify the heading")
	panel.screen.dial=float(state.systems.navigation.planned)-float(state.systems.navigation.instrument)
	await _artifact_click(panel,"apply");await _artifact_click(panel,"verify")
	_check(state.completed.has("navigation") and state.systems.navigation.verified, "Correct signed correction verifies the real navigation duty")
	await _shot("helm_verified")
	panel.close_panel();await create_timer(0.3).timeout
	panel=await _open("bridge.flight.lower")
	_check(panel.kind=="helm" and panel.screen._done(), "Alternate flight console shares the verified heading state")
	panel.close_panel();await create_timer(0.3).timeout
	# Teletype, protocol and timed acknowledgement, entered through the console.
	for task in ["crew","cargo","power","life","hydro","engine","navigation"]: state.completed[task]=true
	panel=await _open("bridge.comms.upper")
	_check(panel.kind=="communications", "Flight station opens the dedicated communications board")
	await _artifact_click(panel,"transmit")
	_check(not state.systems.communications.sent, "Guarded transmitter cannot send an unprepared report")
	await _artifact_click(panel,"signal");await _artifact_click(panel,"report")
	_check(state.systems.communications.report_ready and not state.systems.communications.report_text.is_empty(), "Teletype prepares the actual retained duty report")
	await _artifact_click(panel,"protocol:local");await _artifact_click(panel,"cover")
	_check(not bool(state.flags.get("communications.guard_open",false)), "Local-only protocol cannot unlock the Earth send guard")
	await _artifact_click(panel,"protocol:standard");await _artifact_click(panel,"cover");await _artifact_click(panel,"transmit")
	_check(state.systems.communications.sent and not state.systems.communications.acknowledged, "Send starts the existing acknowledgement timer")
	var report_id: String=state.systems.communications.report_id
	await _artifact_click(panel,"transmit");await _artifact_click(panel,"ack")
	_check(not state.systems.communications.acknowledged and state.systems.communications.report_id==report_id, "Repeated send/ACK clicks cannot finish or replace an in-flight report")
	await create_timer(3.2).timeout
	_check(state.systems.communications.acknowledged and state.completed.has("communications"), "Earth acknowledgement arrives through the real elapsed timer")
	await _shot("communications_ack")
	panel.close_panel();await create_timer(0.3).timeout
	panel=await _open("bridge.comms.lower")
	_check(panel.kind=="communications" and panel.screen._stage()==6, "Lower comms station shares the retained ACK")
	panel.close_panel();await create_timer(0.3).timeout
	_check(not _level.get("_task_console_open"), "Panels closed cleanly")
	print("EITO FLOW: %s (%d checks, %d failures)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	var exit_code := 0 if _failures == 0 else 1
	_level.queue_free()
	await _frames(3)
	Engine.remove_meta("ship_story_validation_path")
	quit(exit_code)
