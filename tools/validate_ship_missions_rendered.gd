extends Node
## Real rendered Controls/input, normal landing->prologue->walkthrough entry.
## Run through Godot MCP. No normal user save is read or written.
var level
var checks := 0
var failures: Array=[]
var report := {}
var _finished := false

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message);push_error(message)

func frames(count := 4) -> void:
	for i in range(count): await get_tree().process_frame

func key(code: Key) -> void:
	var event := InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);await frames(2)
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);await frames(2)

func _ready() -> void:
	get_tree().create_timer(300).timeout.connect(func():
		if not _finished: push_error("Rendered mission validation timeout");get_tree().quit(2))
	run.call_deferred()

func capture(capture_name: String) -> void:
	await frames(4);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/mission_validation/screenshots/"+capture_name+".png")

func station(id: String) -> bool:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames(2)
	var entry: Dictionary=level._ship_points[id]
	if not is_instance_valid(entry.marker): check(false,"No access marker: "+id);return false
	level.player.global_position=entry.marker.global_position
	level.player.camera.reset_smoothing();level.player.camera.force_update_scroll()
	level.ship_refresh_prompt()
	check(level._ship_active_id==id,"Rendered station target: "+id)
	var event := InputEventAction.new();event.action=&"interact";event.pressed=true;Input.parse_input_event(event)
	await frames()
	event=InputEventAction.new();event.action=&"interact";event.pressed=false;Input.parse_input_event(event)
	var opened: bool=is_instance_valid(level._ship_panel) and level._ship_panel.prop_id==id
	check(opened,"E opens rendered station: "+id)
	return opened

func operate(prop: String, action_id: String, value: Variant=null) -> void:
	if not is_instance_valid(level._ship_panel) or level._ship_panel.prop_id!=prop:
		if not await station(prop): return
	await frames(2)
	var panel=level._ship_panel
	if not panel._controls.has(action_id): check(false,"Missing rendered action: "+prop+"/"+action_id);return
	var button: Button=panel._controls[action_id].button
	# Readouts/actions refresh at 5 Hz. Wait for that refresh after a live
	# verification threshold; frame-count waits can be shorter at high FPS.
	if button.disabled: await get_tree().create_timer(0.25).timeout
	check(not button.disabled,"Rendered action enabled: "+prop+"/"+action_id)
	if button.disabled: return
	var choice := panel.find_child(action_id.replace(":","_")+"Choice",true,false) as OptionButton
	if choice!=null:
		var data: Array=level._ship_state.actions(prop)
		for action in data:
			if action.id==action_id:
				for index in range(action.options.size()):
					if action.options[index][0]==value: choice.select(index)
	var number := panel.find_child(action_id+"Value",true,false) as SpinBox
	if number!=null: number.value=float(value)
	button.pressed.emit();await frames(3)

func verify(prop: String, room: String) -> void:
	await operate(prop,"restore")
	var waited := 0.0
	while float(level._ship_state.verification.get(room,0.0))<6.0 and waited<24.0:
		await get_tree().create_timer(0.25).timeout;waited+=0.25
	check(float(level._ship_state.verification.get(room,0.0))>=6.0,"Live verification period: "+room)
	await operate(prop,"verify")

func capture_room(prop: String, capture_name: String) -> void:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	level.player.global_position=level._ship_points[prop].marker.global_position
	level.player.camera.reset_smoothing();level.player.camera.force_update_scroll()
	await capture(capture_name)

func sorting_probe() -> void:
	var entry: Dictionary=level._ship_points["bridge.planning"]
	var bounds: Rect2=level._ship_footprint(entry.host)
	check(level.y_sort_enabled and entry.host.get_parent().y_sort_enabled and entry.host.z_index==level.player.z_index,"Player and bridge furniture retain shared Y-sort plane")
	for side in [-1,1]:
		var point := Vector2.INF
		for x_offset in [0,8,-8,16,-16,24,-24,32,-32]:
			var candidate := Vector2(bounds.get_center().x+x_offset,bounds.position.y-12 if side<0 else bounds.end.y+12)
			if level._ship_body_clear(candidate): point=candidate;break
		check(point!=Vector2.INF,"Sorting probe has clear player floor on each side")
		if point==Vector2.INF: continue
		level.player.global_position=point;level.player.face_toward(entry.host.global_position)
		level.player.camera.reset_smoothing();level.player.camera.force_update_scroll()
		await capture("sorting_bridge_behind" if side<0 else "sorting_bridge_front")

func hud_regression(size_label: String) -> void:
	var hud: WalkHud=level._walk_hud
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	await key(KEY_9);check(hud._selected_hotbar_index==8,"Keyboard quick-slot selection "+size_label)
	var wheel := InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=true
	Input.parse_input_event(wheel);await frames()
	check(hud._selected_hotbar_index==0,"Mouse-wheel quick-slot selection "+size_label)
	await key(KEY_I)
	check(hud._active_overlay==&"inventory" and not level.player.is_physics_processing(),"Inventory opens and pauses walking "+size_label)
	var snapshot: Dictionary=hud.inventory_snapshot()
	var source: int=hud._storage_items.find(&"engineering_multitool")
	check(source>=0,"Carried tool remains in the original inventory")
	if source>=0:
		hud._inventory_hotbar_cells[0].drop_requested.emit(&"hotbar",0,{"source_kind":&"storage","source_index":source})
		check(hud._hotbar_items[0]==&"engineering_multitool","Inventory drag/drop signal moves item to quickbar")
		var before := JSON.stringify(hud.inventory_snapshot())
		hud._equipment_cells[0].drop_requested.emit(&"equipment",0,{"source_kind":&"hotbar","source_index":0})
		check(before==JSON.stringify(hud.inventory_snapshot()),"Equipment compatibility rejects tool in head slot")
		hud._equipment_cells[3].drop_requested.emit(&"equipment",3,{"source_kind":&"hotbar","source_index":0})
		check(hud._equipment_items[&"tool"]==&"engineering_multitool","Compatible tool equipment drop still works")
	await capture("inventory_"+size_label)
	hud.inventory_restore(snapshot)
	await key(KEY_ESCAPE);check(hud._active_overlay==&"" and level.player.is_physics_processing(),"Inventory close restores walking")
	await key(KEY_M)
	check(hud._active_overlay==&"map" and not hud.MAP_CONTENT_VISIBLE,"Approved map opens with content disabled")
	var pins_inactive := not hud._map_player_marker.visible and hud._map_player_marker.mouse_filter==Control.MOUSE_FILTER_IGNORE
	for marker_data in hud._map_task_markers.values():
		pins_inactive=pins_inactive and not marker_data.marker.visible and marker_data.marker.mouse_filter==Control.MOUSE_FILTER_IGNORE
	check(pins_inactive,"Blank map retains hidden, non-interactive marker data")
	await capture("blank_map_"+size_label);await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	check(hud._active_overlay==&"settings","Esc opens existing Settings")
	var volume: float=hud._volume_slider.value
	hud._volume_slider.value=0
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")),"Settings volume can mute")
	hud._volume_slider.value=62
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and hud._volume_label.text=="62%","Settings volume still adjusts and labels output")
	await capture("settings_"+size_label)
	hud._volume_slider.value=volume;await key(KEY_ESCAPE)
	check(level.player.is_physics_processing(),"Settings close restores walking")
	await key(KEY_F3);await capture("dev_scenarios_"+size_label)
	check(hud._dev_panel.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y,"Development scenario controls fit viewport "+size_label)
	check(hud._dev_panel.get_index()==hud._root.get_child_count()-1,"Scenario controls draw above the quickbar/prompt")
	await key(KEY_M);check(not hud._dev_panel.visible and hud._active_overlay==&"map","Opening a normal modal dismisses the development panel")
	await key(KEY_ESCAPE)

func play_legacy(prop: String, task: String) -> void:
	await operate(prop,"legacy:"+task)
	var console=level._ship_service_console
	check(is_instance_valid(console),"Original service controls rendered: "+task)
	if not is_instance_valid(console): return
	await capture("legacy_"+task)
	match task:
		"auxiliary_power":
			for i in range(3): console._power_sliders[i].value=[67,43,77][i]
			console._power_sync_button.pressed.emit()
		"air_filter":
			console._filter_release_button.pressed.emit()
			console._on_filter_rotate_pressed();console._on_filter_rotate_pressed();console._on_filter_seat_pressed()
			console._filter_pressure_slider.value=67;console._filter_pressure_button.pressed.emit()
		"nutrient_flow":
			for i in range(3):
				while console._nutrient_rotations[i]!=[1,3,2][i]: console._nutrient_rotate_buttons[i].pressed.emit()
			console._nutrient_restore_button.pressed.emit()
	check(console._task_complete,"Original controls finish in rendered runtime: "+task)
	console._close_button.pressed.emit();await get_tree().create_timer(0.3).timeout

func sequence(context: String) -> void:
	if context=="return":
		if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
		level._walk_hud._toggle_dev_menu();await frames()
		var buttons: Array=level._walk_hud._dev_panel.find_children("*","Button",true,false)
		var found := false
		for button in buttons:
			if button.text=="TEST RETURN": button.pressed.emit();found=true;break
		check(found and level._ship_state.phase=="return","Existing F3 menu enters explicit development-only return scenario")
	level.ship_mission_save_path="res://.godot/mission_validation/rendered_"+context+".json"
	await operate("bridge.planning","assign")
	await capture(context+"_planning")
	await operate("quarters.desk","roster")
	await operate("quarters.desk","crew_log")
	await operate("quarters.desk","crew_compare","unconfirmed" if context=="return" else "records_match")
	await operate("quarters.desk","record");await capture(context+"_quarters")
	await operate("cargo.bundle","manifest");await operate("cargo.bundle","seal")
	await operate("cargo.scale","tare")
	await operate("cargo.mover","move_load","scale")
	await operate("cargo.scale","weigh")
	await capture(context+"_cargo_measurement")
	await operate("cargo.scale","cargo_decide","quarantine" if context=="return" else "accept")
	await operate("power.breaker","observe")
	await operate("power.breaker","diagnose","load" if context=="return" else "cell")
	await operate("power.breaker","isolate")
	await operate("power.converter","allocation","reserve")
	if context=="outbound": await play_legacy("power.cell","auxiliary_power")
	await verify("power.breaker","power");await capture(context+"_power")
	await operate("life.filter","observe")
	await operate("life.filter","diagnose","scrubber" if context=="return" else "airflow")
	await operate("life.filter","isolate")
	if context=="outbound":
		await operate("quarters.drawer.1","take:filter_cartridge")
		await play_legacy("life.filter","air_filter")
	else:
		await operate("quarters.drawer.1","take:scrubber_media")
		await operate("life.scrubber","scrubber_service")
	await verify("life.filter","life");await capture(context+"_life_support")
	await operate("hydro.console","observe")
	await operate("hydro.console","diagnose","balance" if context=="return" else "restriction")
	await operate("hydro.pump","isolate")
	if context=="outbound": await play_legacy("hydro.console","nutrient_flow")
	else:
		await operate("quarters.drawer.2","take:nutrient_buffer")
		await operate("hydro.console","dose",1.0)
	await verify("hydro.console","hydro");await capture(context+"_hydroponics")
	await operate("engine.pump.1","observe")
	await operate("engine.pump.1","diagnose","valve" if context=="return" else "pump")
	await operate("engine.turbine.1","reduce_load")
	var service := "engine.valve.2" if context=="return" else "engine.pump.1"
	await operate(service,"isolate")
	if context=="outbound":
		await operate("cargo.trolley","transfer_kit")
		await operate("engine.locker.1","take:coolant_charge")
	await operate(service,"engine_service")
	await verify(service,"engine")
	await operate("engine.turbine.1","resume_output");await capture(context+"_engines")
	await operate("bridge.helm","route")
	await operate("bridge.helm","correction",-9.0 if context=="return" else -6.0)
	await operate("bridge.helm","nav_verify");await capture(context+"_navigation")
	await operate("bridge.comms.upper","prepare_report")
	await capture(context+"_communications_report")
	await operate("bridge.comms.upper","channel","robust" if context=="return" else "standard")
	await operate("bridge.comms.upper","transmit")
	await get_tree().create_timer(3.3).timeout
	check(level._ship_state.completed.size()==8,"All objectives completed through rendered controls: "+context)
	await operate("bridge.planning","file_report")
	await capture(context+"_complete")
	check(level.ship_save_game().begins_with("Ship-side mission"),"Rendered scenario save isolated from user files")
	print("RENDERED CONTEXT COMPLETE: ",context)
	report[context]={"completed":level._ship_state.completed.duplicate(),"filed":level._ship_state.flags.get("report_filed",false)}

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/mission_validation/screenshots")
	Engine.set_meta("ship_maintenance_entry",true)
	var landing: Node=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	get_tree().root.add_child(landing);get_tree().current_scene=landing
	await frames();await capture("normal_landing")
	while landing._start_button.disabled: await get_tree().process_frame
	landing._start_button.pressed.emit()
	while get_tree().current_scene==landing or get_tree().current_scene==null: await get_tree().process_frame
	var intro: Node=get_tree().current_scene
	check(intro.has_method("_enter_game"),"Normal start reaches existing prologue")
	await capture("normal_prologue")
	while intro._transitioning: await get_tree().process_frame
	intro._skip_button.pressed.emit()
	while get_tree().current_scene==intro or get_tree().current_scene==null: await get_tree().process_frame
	level=get_tree().current_scene
	check(level.has_node("Player") and level.has_node("CargoBayProps"),"Normal prologue entry reaches walkthrough")
	while not level._ship_points_ready: await get_tree().process_frame
	level.ship_mission_save_path="res://.godot/mission_validation/rendered_outbound.json"
	await capture("normal_arrival")
	level._on_arrival_briefing_dismissed()
	for child in level.get_children():
		if child is CanvasLayer and child!=level._walk_hud: child.hide()
	check(not level.has_node("LabRoom"),"Overlapping/missing-asset lab remains inactive")
	await sequence("outbound")
	await sequence("return")
	for room in ["bridge","quarters","cargo","engine","power","life","hydro"]:
		var prop: String={"bridge":"bridge.planning","quarters":"quarters.table","cargo":"cargo.scale","engine":"engine.pump.1","power":"power.cell","life":"life.filter","hydro":"hydro.console"}[room]
		await capture_room(prop,"furnished_"+room)
	await sorting_probe()
	await hud_regression("1280x720")
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	get_window().size=Vector2i(1024,576)
	get_window().content_scale_size=Vector2i(1024,576)
	await frames(6)
	await station("bridge.planning");await capture("small_planning_1024x576")
	check(level._ship_panel._root.get_rect().size.x<=1024.1,"Procedure layout fits smaller viewport")
	level._ship_panel.close_panel();await frames()
	await station("engine.pump.1");await capture("small_engine_1024x576")
	level._ship_panel.close_panel();await frames()
	await capture("small_gameplay_hud")
	await hud_regression("1024x576")
	# Exercise the existing scene transitions, not a replacement incident flow.
	var transit_phase: String=level._ship_state.phase
	var transit_inventory := JSON.stringify(level._walk_hud.inventory_snapshot())
	var transit_save_path: String=level.ship_mission_save_path
	await get_tree().create_timer(0.3).timeout
	level._exit_ship_to_planet()
	while get_tree().current_scene==level or get_tree().current_scene==null: await get_tree().process_frame
	var planet: Node=get_tree().current_scene
	check(planet.has_method("_board_ship"),"Original ship exit still reaches the existing planet scene")
	await capture("existing_planet_transit")
	planet.player.global_position=planet.AIRLOCK_ENTRY_POS
	planet._refresh_prompt()
	var interact := InputEventAction.new();interact.action=&"interact";interact.pressed=true;Input.parse_input_event(interact)
	while get_tree().current_scene==planet or get_tree().current_scene==null: await get_tree().process_frame
	interact=InputEventAction.new();interact.action=&"interact";interact.pressed=false;Input.parse_input_event(interact)
	level=get_tree().current_scene
	while not level._ship_points_ready: await get_tree().process_frame
	check(level._ship_state.phase==transit_phase and level._ship_state.completed.size()==8,"Planet return preserves mission phase and completed duties")
	check(JSON.stringify(level._walk_hud.inventory_snapshot())==transit_inventory,"Planet return preserves inventory/equipment")
	check(level.ship_mission_save_path==transit_save_path,"Planet return preserves isolated scenario save namespace")
	check(not level._arrival_briefing_open and level.player.is_physics_processing(),"Existing planet return restores walking without replaying arrival")
	await capture("existing_ship_return")
	report.checks=checks;report.failures=failures
	var file := FileAccess.open("res://.godot/mission_validation/rendered_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close();_finished=true
	print("RENDERED SHIP MISSIONS: ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
