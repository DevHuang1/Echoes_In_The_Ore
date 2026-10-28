extends Node
## Normal-renderer input and recovery validation. All saves are isolated.
const ROOT := "res://.godot/mission_validation/first_watch/"
const EVIDENCE := "res://.godot/first_watch_validation/"
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const SAVE := preload("res://scripts/ship/ship_story_save.gd")
@export var validation_mode := "chapter"
var level
var checks := 0
var failures: Array[String] = []
var observations := {}
var walking_distance := 0.0
var _grid := AStarGrid2D.new()
var _finished := false

func check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition: failures.append(message); push_error(message)
	return condition

func frames(count := 3) -> void:
	for i in range(count): await get_tree().process_frame

func flush() -> void:
	var payload := {"mode":validation_mode,"checks":checks,"failures":failures,"observations":observations,"walking_distance":walking_distance,"complete":_finished}
	var file := FileAccess.open(EVIDENCE+validation_mode+"_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(payload,"\t")); file.close()

func finish() -> void:
	_finished = true; flush()
	print("FIRST WATCH ",validation_mode,": ",checks," checks / ",failures.size()," failures / actual walking ",walking_distance)
	get_tree().quit(0 if failures.is_empty() else 1)

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="): validation_mode=argument.trim_prefix("--mode=")
	DirAccess.make_dir_recursive_absolute(ROOT)
	DirAccess.make_dir_recursive_absolute(EVIDENCE+"screenshots")
	flush()
	get_tree().create_timer(900.0).timeout.connect(func():
		if not _finished: check(false,"Validation deadline exceeded"); finish())
	run.call_deferred()

func key(code: Key, control := false) -> void:
	var event := InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=true; event.ctrl_pressed=control
	Input.parse_input_event(event); await frames(1)
	event=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=false; Input.parse_input_event(event)
	await frames(1)

func interact() -> void:
	var event := InputEventAction.new(); event.action=&"interact"; event.pressed=true; Input.parse_input_event(event); await frames(2)
	event=InputEventAction.new(); event.action=&"interact"; event.pressed=false; Input.parse_input_event(event); await frames(2)

func click(control: Control) -> bool:
	if not check(is_instance_valid(control) and control.is_visible_in_tree(),"Input target is visible: "+str(control.name if is_instance_valid(control) else "missing")): return false
	if control is BaseButton and not check(not control.disabled,"Input target is enabled: "+control.name): return false
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new(); motion.position=point; motion.global_position=point; Input.parse_input_event(motion)
	var event := InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=true
	Input.parse_input_event(event); await frames(1)
	event=InputEventMouseButton.new(); event.position=point; event.global_position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=false
	Input.parse_input_event(event); await frames(3)
	return true

func capture(capture_name: String, both_sizes := false) -> void:
	var sizes := [Vector2i(1280,720),Vector2i(1024,576)] if both_sizes else [get_window().size]
	for size in sizes:
		get_window().size=size; get_window().content_scale_size=size
		await frames(5); await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(EVIDENCE+"screenshots/"+capture_name+"_%dx%d.png" % [size.x,size.y])
	get_window().size=Vector2i(1280,720); get_window().content_scale_size=Vector2i(1280,720)
	await frames(4); flush()

func wait_ship() -> void:
	while get_tree().current_scene==null or not get_tree().current_scene.has_node("Player"): await frames(1)
	level=get_tree().current_scene
	while not level._ship_points_ready: await frames(1)
	await frames(4)

func current_scene_changed(previous_id: int) -> Node:
	while get_tree().current_scene==null or get_tree().current_scene.get_instance_id()==previous_id: await frames(1)
	await frames(4)
	return get_tree().current_scene

func start_normal(full_intro := false) -> void:
	var preferred := ROOT+"campaign.json" if not full_intro else ROOT+"intro_full.json"
	var previous_campaign := FileAccess.get_file_as_string(preferred) if FileAccess.file_exists(preferred) else ""
	Engine.set_meta("ship_story_validation_path",preferred)
	var landing: Node=load("res://scenes/ui/landing_screen.tscn").instantiate()
	get_tree().root.add_child(landing); get_tree().current_scene=landing
	await frames(5)
	var previous: int=landing.get_instance_id()
	await click(landing._start_button)
	var intro: Node=await current_scene_changed(previous)
	check(intro.has_method("_enter_game"),"Actual Start reaches existing montage")
	while intro._transitioning: await frames(1)
	if full_intro:
		for index in range(14):
			while intro._transitioning: await frames(1)
			if intro._is_subtitle_typing: await key(KEY_SPACE)
			await key(KEY_SPACE)
		while intro._transitioning: await frames(1)
		check(intro._finished,"All fourteen existing frames reach boarding")
		if intro._is_subtitle_typing: await key(KEY_SPACE)
		await key(KEY_SPACE)
	else: await click(intro._skip_button)
	await wait_ship()
	if not previous_campaign.is_empty():
		check(level.ship_mission_save_path!=preferred and FileAccess.get_file_as_string(preferred)==previous_campaign,"A new Start preserves the existing campaign byte-for-byte")
	check(level.ship_story_active(),"Normal entry creates first-watch context")
	check(level._ship_story.cues["cue.thura.earth_years"].status==("completed" if full_intro else "skipped"),"Montage receipt records actual complete/skip outcome")
	await capture("arrival",true)
	await key(KEY_ENTER); await get_tree().create_timer(0.4).timeout
	check(not level._arrival_briefing_open and not level.ship_control_locked(),"Arrival dismissal releases only its cue lock")
	check(level._ship_story.objective().station=="bridge.planning","Full/skip entry gives bridge assignment as primary objective")
	check(level._ship_state.completed.is_empty(),"No technical completion flags fabricated on story entry")
	build_grid()

func build_grid() -> void:
	_grid.region=Rect2i(0,0,411,211); _grid.cell_size=Vector2.ONE
	_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER; _grid.update()
	_grid.fill_solid_region(_grid.region,true)
	for cell in level._ship_access_connected: _grid.set_point_solid(cell,false)

func nearest_cell(world: Vector2) -> Vector2i:
	var origin := Vector2(16,20)
	var approximate := Vector2i((level._ship_floor.to_local(world)-origin)/4.0)
	var chosen := Vector2i(-1,-1); var distance := INF
	for y in range(approximate.y-3,approximate.y+4):
		for x in range(approximate.x-3,approximate.x+4):
			var cell := Vector2i(x,y)
			if not _grid.region.has_point(cell) or _grid.is_point_solid(cell): continue
			var point: Vector2=level._ship_floor.to_global(origin+Vector2(cell)*4)
			var delta: float=point.distance_to(world)
			if delta<distance: chosen=cell; distance=delta
	return chosen

func movement(direction: Vector2, strength := 1.0) -> void:
	for item in [["move_left",direction.x<0],["move_right",direction.x>0],["move_up",direction.y<0],["move_down",direction.y>0]]:
		var event := InputEventAction.new(); event.action=StringName(item[0]); event.pressed=item[1]; event.strength=strength if item[1] else 0
		Input.parse_input_event(event)
	Input.flush_buffered_events()

func move_to(point: Vector2) -> bool:
	var start := nearest_cell(level.player.global_position); var target := nearest_cell(point)
	if not check(start.x>=0 and target.x>=0,"Route endpoints have authoritative clear floor"): return false
	var path: PackedVector2Array=_grid.get_point_path(start,target)
	if not check(not path.is_empty(),"Connected walking path exists"): return false
	# Compress collinear cells, retaining every corner. Doors stay under normal AI.
	var waypoints := PackedVector2Array()
	for i in range(path.size()):
		if i>0 and i<path.size()-1 and (path[i]-path[i-1]).is_equal_approx(path[i+1]-path[i]): continue
		waypoints.append(level._ship_floor.to_global(Vector2(16,20)+path[i]*4))
	for waypoint in waypoints:
		var stalled := 0; var ticks := 0
		while level.player.global_position.distance_to(waypoint)>0.2 and ticks<900:
			var before: Vector2=level.player.global_position
			var delta: Vector2=waypoint-before
			var direction := Vector2(signf(delta.x),0) if absf(delta.x)>0.15 else Vector2(0,signf(delta.y))
			var axis_distance := absf(delta.x) if direction.x!=0 else absf(delta.y)
			# Account for get_vector's deadzone, then wait past the actual physics
			# update. Reading at physics_frame alone observes the previous position
			# and overshoots tight corridor corners by a full walking step.
			var fraction := minf(1.0,axis_distance/(level.player.move_speed*level.player.get_physics_process_delta_time()))
			var deadzone := (InputMap.action_get_deadzone("move_left")+InputMap.action_get_deadzone("move_right")+InputMap.action_get_deadzone("move_up")+InputMap.action_get_deadzone("move_down"))/4.0
			movement(direction,deadzone+(1.0-deadzone)*fraction)
			await get_tree().physics_frame
			await get_tree().process_frame
			var moved: float=before.distance_to(level.player.global_position); walking_distance+=moved
			stalled=stalled+1 if moved<0.01 else 0; ticks+=1
			if stalled>180: break
		movement(Vector2.ZERO)
		if not check(level.player.global_position.distance_to(waypoint)<1.5,"Actual movement input reaches route corner"):
			observations.route_failure={"from":str(start),"target":str(point),"waypoint":str(waypoint),"actual":str(level.player.global_position),"ticks":ticks,"stalled":stalled,"physics":level.player.is_physics_processing(),"arrival":level._arrival_briefing_open,"hud_modal":level._hud_modal_open,"dialogue":level._crew_dialogue_open,"locked":level.ship_control_locked(),"input":str(Input.get_vector("move_left","move_right","move_up","move_down"))}
			print("ROUTE FAILURE ",observations.route_failure)
			await capture("route_failure",true); finish(); return false
	await frames(2)
	return true

func station(id: String) -> bool:
	observations.last_station=id; print("WALK TO ",id); flush()
	if is_instance_valid(level._ship_panel): await key(KEY_ESCAPE)
	var entry: Dictionary=level._ship_points[id]
	var destination: Vector2=entry.marker.global_position
	for attempt in range(8):
		if not await move_to(destination): return false
		level.ship_refresh_prompt()
		if level._ship_active_id==id:
			await interact()
			return check(level._crew_dialogue_open or (is_instance_valid(level._ship_panel) and level._ship_panel.prop_id==id),"Actual E opens target "+id)
		# A nearby NPC has priority. Let her real patrol continue and try another
		# clear approach; never freeze/teleport her for the chapter proof.
		await get_tree().create_timer(0.5).timeout
		destination=entry.marker.global_position+Vector2(0,8 if attempt%2==0 else -8)
	return check(false,"Target selectable without intercept: "+id)

func talk_amara() -> bool:
	if is_instance_valid(level._ship_panel): await key(KEY_ESCAPE)
	for attempt in range(30):
		var npc: Node2D=level.amara
		var candidate := Vector2.INF
		for offset in [Vector2(20,0),Vector2(0,20),Vector2(-20,0),Vector2(0,-20),Vector2(28,0)]:
			var point: Vector2=npc.global_position+offset
			if level._ship_body_clear(point): candidate=point; break
		if candidate==Vector2.INF: await frames(10); continue
		if not await move_to(candidate): return false
		level.ship_refresh_prompt()
		if level._active_amara_interaction:
			await interact()
			return check(level._crew_dialogue_open,"Actual reachable E opens Amara conversation")
	return check(false,"Catch moving Amara through normal movement")

func dialogue(result := "", capture_name := "") -> void:
	# Redesigned dialogue: E reveals/advances (and steps the comms "Continue" row),
	# number keys pick a reply; the picked reply echoes briefly before it lands.
	var dialog: CrewDialogue=level._crew_dialogue
	for i in range(32):
		if not dialog._active: break
		if dialog.phase in ["typing","wait"] or (dialog.phase=="choose" and dialog._continue_choice and dialog._index<dialog._lines.size()-1):
			await interact(); await get_tree().create_timer(0.05).timeout
		elif dialog.phase=="echo": await get_tree().create_timer(0.1).timeout
		else:
			if not capture_name.is_empty(): await capture(capture_name,true)
			var selected := -1
			for index in range(dialog.choices.size()):
				if dialog.choices[index].id==result: selected=index; break
			if selected>=0: await key(KEY_1+selected)
			elif result=="cancelled": await key(KEY_ESCAPE)
			else: await interact()
			break
	var waited := 0.0
	while dialog._active and dialog.phase=="echo" and waited<3.0:
		await get_tree().create_timer(0.1).timeout; waited+=0.1
	await frames(3)

func operate(action_id: String) -> bool:
	var panel=level._ship_panel
	if not check(is_instance_valid(panel),"Procedure exists for "+action_id): return false
	if not str(panel.get("kind") if panel.get("kind")!=null else "").is_empty():
		# Redesigned station screens (power, irrigation, crew records) send the
		# same actions through their layer; values are the readings-supported ones.
		var values := {"diagnose":{"power":"cell","irrigation":"restriction"}.get(panel.kind),"allocation":"repair","crew_compare":"one_missing"}
		panel.act(action_id,values.get(action_id))
		await get_tree().create_timer(0.2).timeout
		return true
	var page: String=panel._action_page(action_id)
	var tab: Button=panel._tabs.get_node(page+"Tab")
	await click(tab)
	await get_tree().create_timer(0.25).timeout
	if not check(panel._controls.has(action_id),"Actual procedure offers "+action_id): return false
	return await click(panel._controls[action_id].button)

func checkpoint_copy(name: String) -> void:
	check(SAVE.atomic_write(ROOT+name+".json",level.ship_snapshot())==OK,"Isolated checkpoint copied: "+name)

func power_controls() -> void:
	if not str(level._ship_panel.get("kind") if level._ship_panel.get("kind")!=null else "").is_empty():
		await operate("sync")
		check(level._ship_state.systems.power.calibrated,"Bank B synchronizes through the redesigned power panel")
		return
	await operate("legacy:auxiliary_power")
	var console=level._ship_service_console
	check(is_instance_valid(console),"Original bank controls opened")
	for i in range(3):
		await click(console._power_sliders[i]); await key(KEY_HOME)
		for tick in range([67,43,77][i]): await key(KEY_RIGHT)
	await click(console._power_sync_button)
	check(console._task_complete,"Actual keyboard sliders synchronize original banks")
	await click(console._close_button); await get_tree().create_timer(0.3).timeout

func verify(room: String) -> void:
	await operate("restore")
	var waited := 0.0
	var needed: float=level._ship_state.verify_seconds(room)
	while float(level._ship_state.verification.get(room,0.0))<needed and waited<25:
		await get_tree().create_timer(0.25).timeout; waited+=0.25
	check(float(level._ship_state.verification.get(room,0))>=needed,"Actual healthy observation period: "+room)
	await operate("verify")

func chapter() -> void:
	await start_normal(false)
	check(level.amara.is_physics_processing(),"NPC physics stays enabled in the chapter fixture")
	check(level._ship_state.systems.life.airflow==67 and level._ship_state.engine_flow(0)==1 and level._ship_state.systems.engine.temperature<=65,"Unselected critical systems start genuinely healthy")
	check(level._ship_state.systems.navigation.instrument==level._ship_state.systems.navigation.planned and not level._ship_state.systems.navigation.verified,"Unassigned navigation starts in range without fabricated service signoff")
	await station("bridge.planning"); await dialogue("later")
	check(not level._ship_story.has("watch.accepted"),"Declining preserves unaccepted assignment")
	await station("bridge.planning"); await dialogue("accept","maya_assignment")
	check(level._ship_story.has("watch.accepted"),"Maya's actual response accepts scoped watch")
	await station("quarters.desk"); await operate("roster"); await operate("crew_log"); await operate("crew_compare")
	check(level._ship_story.completed_count()==1,"Roster comparison completes only mission 010")
	checkpoint_copy("mid_roster"); await key(KEY_ESCAPE)
	await talk_amara()
	var before: Vector2=level.amara.global_position
	await get_tree().create_timer(9.2).timeout
	check(level.amara.is_physics_processing() and level.amara.global_position.distance_to(before)<0.01,"Real conversation lock holds Amara stationary for nine seconds with normal physics")
	await dialogue("inspect","amara_introduction")
	await station("hydro.console"); await operate("observe"); await operate("diagnose")
	check(not level._ship_state.completed.has("hydro") and level._ship_state.systems.hydro.ec==2,"Observation/diagnosis is not a repair or chemical consumption")
	await key(KEY_ESCAPE); await talk_amara(); await dialogue("report","amara_delivery_report")
	check(level._ship_story.completed_count()==2,"Explicit observation report completes 020")
	await station("power.breaker"); await operate("observe"); await operate("diagnose"); await operate("isolate")
	await key(KEY_ESCAPE); await station("power.converter"); await operate("allocation")
	await key(KEY_ESCAPE); await station("power.cell"); await power_controls()
	await station("power.breaker"); await verify("power")
	# Leila's acknowledgement now arrives on the power panel's comms card.
	await get_tree().create_timer(1.0).timeout
	check(is_instance_valid(level._ship_panel) and level._ship_panel.screen.comms and not level._crew_dialogue_open,"Engineering acknowledgement shown on the power panel")
	await capture("leila_power_ack",true)
	check(level._ship_story.completed_count()==3 and level._ship_state.bus_powered("science"),"Verified power plus engineering acknowledgement completes 030 without cargo")
	check(level._ship_state.systems.hydro.flow==30,"Restored feed has observable delivery while manifold remains restricted")
	checkpoint_copy("mid_power")
	await station("hydro.console"); await operate("observe"); await operate("diagnose"); await operate("isolate")
	await operate("align")
	check(level._ship_state.systems.hydro.aligned,"Manifold valves set through the redesigned irrigation panel")
	await verify("hydro")
	check(level._ship_story.completed_count()==3,"Technical irrigation verification still needs Amara report-back")
	await key(KEY_ESCAPE); await talk_amara(); await dialogue("report","amara_repair_report")
	check(level._ship_story.completed_count()==4,"Explicit healthy repair report completes 040")
	await station("bridge.planning"); await operate("story:summary"); await dialogue("ack","maya_handoff")
	check(level._ship_story.completed_count()==5,"Production text acknowledgement completes all five missions")
	check(level._ship_state.completed.size()==3 and level._ship_state.completed.has("crew") and level._ship_state.completed.has("power") and level._ship_state.completed.has("hydro"),"Only roster, power and irrigation technical results exist; no eight-duty fabrication")
	check(not level._ship_state.flags.get("report_filed",false) and level._ship_state.transactions.is_empty(),"Scoped handoff does not fake full report or consume chemistry/supplies")
	checkpoint_copy("completed")
	await capture("chapter_complete",true)
	check(walking_distance>2000,"End-to-end chapter used substantial actual walking input")
	observations.chapter_snapshot=level.ship_snapshot()

func run() -> void:
	match validation_mode:
		"chapter": await chapter()
		"intro_full": await start_normal(true)
		_: check(false,"Unknown validation mode")
	finish()
