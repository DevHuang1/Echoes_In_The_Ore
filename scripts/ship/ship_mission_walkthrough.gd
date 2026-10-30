@tool
extends Node2D
## Base implementation for the existing walkthrough owner. This is not an
## autoload/second interaction manager: the existing scene root owns these methods.
const SHIP_CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
const SHIP_STATE := preload("res://scripts/ship/ship_mission_state.gd")
const SHIP_PANEL := preload("res://scripts/ui/ship_procedure_panel.gd")
const EITO_LAYER := preload("res://scripts/ui/eito/eito_layer.gd")
const SHIP_STORY := preload("res://scripts/ship/first_watch_story.gd")
const STORY_SAVE := preload("res://scripts/ship/ship_story_save.gd")
const LOCKER_HIDE_SOUND := preload("res://audio/sfx/pressure_door_open.mp3")
@export var ship_story_enabled := true
@export var ship_story_autosave := true
@export var ship_mission_save_path := "user://ship_side_missions_v1.json"
@export_range(16.0,48.0,1.0) var ship_interaction_reach := 30.0
var _ship_state
var _ship_hud: WalkHud
var _ship_player: ShipPlayer
var _ship_floor: Sprite2D
var _ship_points := {}
var _ship_active_id := ""
var _ship_near_hide_id := ""
var _ship_panel
var _ship_ready := false
var _ship_service_console
var _ship_service_prop := ""
var _ship_service_task := ""
var _ship_hide_id := ""
var _ship_hide_exit := Vector2.ZERO
var _ship_hide_phase := "outside"
var _ship_hide_feedback := ""
var _ship_hide_route := PackedVector2Array()
var _ship_hide_traversed := PackedVector2Array()
var _ship_hide_route_index := 0
var _ship_hide_prior_appearance := 0
var _ship_hide_speed := 95.0
var _ship_status := ""
var _ship_status_time := 0.0
var _ship_auto_timer := 0.0
var _ship_syncing := false
var _ship_initial_inventory := {}
var _ship_points_ready := false
var _ship_story
var _ship_pending_continue_path := ""
var _ship_cue_active := {}
var _ship_cue_asset: Node
var _ship_cue_ui: CanvasLayer
var _ship_story_hud_key := ""
var _ship_pending_cue_reoffer := ""
var _ship_access_connected := {}
const SHIP_NAV_ORIGIN := Vector2(16,20)
const SHIP_NAV_STEP := 4.0

func _exit_tree() -> void:
	if Engine.is_editor_hint(): return
	_story_release_locks()
	_ship_release_hide_reservation()
	# A model/save snapshot may outlive its scene during a planet transition.
	# Disconnect the old owner and release scene-node handles explicitly.
	_ship_ready=false
	if _ship_state!=null:
		if _ship_state.changed.is_connected(_ship_state_changed): _ship_state.changed.disconnect(_ship_state_changed)
		_ship_state.inventory=null
	_ship_points.clear()
	_ship_access_connected.clear()

func ship_begin(hud: WalkHud, actor: ShipPlayer) -> void:
	if Engine.is_editor_hint(): return
	if Engine.has_meta("ship_maintenance_entry"):
		ship_story_enabled = false; Engine.remove_meta("ship_maintenance_entry")
	_ship_hud=hud;_ship_player=actor;_ship_floor=get_node("FloorLayer")
	_ship_state=SHIP_STATE.new();_ship_state.configure(hud)
	if ship_story_enabled:
		_ship_story = SHIP_STORY.new()
		_ship_state.configure_first_watch()
		if Engine.has_meta("ship_story_bootstrap"):
			_ship_story.restore(Engine.get_meta("ship_story_bootstrap")); Engine.remove_meta("ship_story_bootstrap")
		if ship_mission_save_path == STORY_SAVE.LEGACY: ship_mission_save_path = STORY_SAVE.new_campaign_path()
	if Engine.has_meta("ship_story_continue_path"):
		_ship_pending_continue_path = str(Engine.get_meta("ship_story_continue_path")); Engine.remove_meta("ship_story_continue_path")
	_ship_initial_inventory=hud.inventory_snapshot()
	_ship_state.changed.connect(_ship_state_changed)
	hud.inventory_changed.connect(_ship_inventory_changed)
	hud.mission_scenario_requested.connect(ship_start_development_scenario)
	get("_crew_dialogue").conversation_finished.connect(_story_conversation_finished)
	_ship_ready=true
	if ship_story_active() and _ship_pending_continue_path.is_empty() and not Engine.has_meta("ship_mission_transit"):
		_story_begin_cue("cue.asteria.arrival", "arrival_briefing")
	_ship_build_points.call_deferred()
	if Engine.has_meta("ship_mission_transit"):
		ship_restore(Engine.get_meta("ship_mission_transit"),false)
		Engine.remove_meta("ship_mission_transit")
		if Engine.has_meta("ship_mission_transit_save_path"):
			var transit_path := str(Engine.get_meta("ship_mission_transit_save_path"))
			if _ship_save_path_allowed(transit_path): ship_mission_save_path=transit_path
			Engine.remove_meta("ship_mission_transit_save_path")
	_ship_sync_hud()

func ship_is_initialized() -> bool:
	return _ship_ready and _ship_state!=null

func ship_control_locked() -> bool:
	return _ship_hide_phase != "outside" or not _ship_cue_active.is_empty() or not _ship_pending_continue_path.is_empty() or not _ship_pending_cue_reoffer.is_empty()

func ship_process(delta: float) -> void:
	if not ship_is_initialized(): return
	_ship_state.tick(delta)
	_ship_process_hiding(delta)
	_ship_status_time=maxf(0.0,_ship_status_time-delta)
	_ship_auto_timer+=delta
	if _ship_auto_timer>=0.5:
		_ship_auto_timer=0.0
		_ship_publish_systems()
		if ship_story_active(): _story_sync()
		if not _ship_pending_cue_reoffer.is_empty(): _story_reoffer_pending_cue.call_deferred()

func _ship_body_clear(point: Vector2, exclusions: Array[RID]=[], ignore_doors_for_access_planning := false) -> bool:
	if not _ship_player._is_body_over_floor(point,ignore_doors_for_access_planning): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape=_ship_player.get_node("CollisionShape2D").shape
	query.transform=Transform2D(0,point);query.collision_mask=1
	var excluded: Array[RID]=[_ship_player.get_rid()]
	excluded.append_array(exclusions);query.exclude=excluded
	return get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _ship_in_area(point: Vector2, room: String) -> bool:
	return SHIP_CATALOG.AREAS.has(room) and SHIP_CATALOG.AREAS[room].has_point(_ship_floor.to_local(point))

func _ship_footprint(host: Node2D) -> Rect2:
	var result := Rect2(host.global_position,Vector2.ZERO)
	var found := false
	for shape in host.find_children("*","CollisionShape2D",true,false):
		if shape.disabled or shape.shape==null: continue
		var bounds: Rect2=shape.global_transform*shape.shape.get_rect()
		result=bounds if not found else result.merge(bounds);found=true
	return result

func _ship_build_points() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _ship_build_access_connectivity()
	for definition in SHIP_CATALOG.PROPS:
		var host := get_node_or_null(NodePath(definition[0])) as Node2D
		if host==null: continue
		var marker := Marker2D.new();marker.name="ShipInteractionPoint"
		host.add_child(marker)
		var bounds := _ship_footprint(host)
		var preferred: Vector2=definition[4]
		if host.has_node("AccessPoint") and definition[3] in ["storage_hide","cargo_hide"]:
			preferred=(host.get_node("AccessPoint").global_position-bounds.get_center()).normalized()
		var candidates: Array[Vector2]=[]
		for direction in [preferred,Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT,Vector2.UP]:
			var radius: Vector2=bounds.size*0.5+Vector2(12,12)
			var base: Vector2=bounds.get_center()+direction*radius
			var across := Vector2(-direction.y,direction.x)
			for offset in [0.0,12.0,-12.0,24.0,-24.0,36.0,-36.0]:
				for extra in [0.0,8.0,16.0,24.0,32.0]: candidates.append(base+across*offset+direction*extra)
		var chosen := Vector2.INF
		for point in candidates:
			if _ship_in_area(point,definition[2]) and _ship_body_clear(point,[],true) and _ship_connected_access(point): chosen=point;break
		if chosen==Vector2.INF:
			marker.queue_free()
			_ship_points[definition[1]]={"host":host,"marker":null,"definition":SHIP_CATALOG.definition(definition[1]),"issue":"No safe approach point; requires review without moving furniture."}
			continue
		marker.global_position=chosen
		_ship_points[definition[1]]={"host":host,"marker":marker,"definition":SHIP_CATALOG.definition(definition[1]),"issue":""}
	_ship_points_ready=true
	if not _ship_pending_continue_path.is_empty():
		var pending := _ship_pending_continue_path; _ship_pending_continue_path = ""
		ship_mission_save_path = pending
		var payload := STORY_SAVE.read(pending)
		if payload.is_empty() or not ship_restore(payload):
			ship_mission_save_path = STORY_SAVE.new_campaign_path()
			_ship_status = "That save could not be restored safely. It has not been changed. A new watch is available."; _ship_status_time = 15.0
		set("_arrival_briefing_open", false); _ship_hud.set_walking_visible(true); call("_update_player_walk_state")
	_ship_sync_hud()

func _ship_build_access_connectivity() -> void:
	# Planning only: doors can be opened normally, but walls, furniture and the
	# unchanged player-sized floor mask still constrain every candidate. Yield to
	# the briefing/render loop instead of freezing startup for the grid scan.
	var width := 411;var height := 211
	var valid := PackedByteArray();valid.resize(width*height)
	for y in range(height):
		for x in range(width):
			if _ship_body_clear(_ship_floor.to_global(SHIP_NAV_ORIGIN+Vector2(x,y)*SHIP_NAV_STEP),[],true): valid[y*width+x]=1
		if y%16==0: await get_tree().process_frame
	var start := Vector2i((_ship_floor.to_local(_ship_player.global_position)-SHIP_NAV_ORIGIN)/SHIP_NAV_STEP)
	if start.x<0 or start.y<0 or start.x>=width or start.y>=height or valid[start.y*width+start.x]==0:
		start=Vector2i(221,120)
	var queue: Array[Vector2i]=[start];_ship_access_connected={start:true};var head := 0
	while head<queue.size():
		var cell := queue[head];head+=1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=cell+delta
			if next.x<0 or next.y<0 or next.x>=width or next.y>=height or _ship_access_connected.has(next): continue
			if valid[next.y*width+next.x]==1: _ship_access_connected[next]=true;queue.append(next)

func _ship_connected_access(world_point: Vector2) -> bool:
	var target := Vector2i((_ship_floor.to_local(world_point)-SHIP_NAV_ORIGIN)/SHIP_NAV_STEP)
	for y in range(target.y-2,target.y+3):
		for x in range(target.x-2,target.x+3):
			var cell := Vector2i(x,y)
			if not _ship_access_connected.has(cell): continue
			var cell_position := _ship_floor.to_global(SHIP_NAV_ORIGIN+Vector2(cell)*SHIP_NAV_STEP)
			if cell_position.distance_to(world_point)>7: continue
			var ray := PhysicsRayQueryParameters2D.create(cell_position,world_point,1,[_ship_player.get_rid()])
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): return true
	return false

func ship_can_reach(point: Vector2, room := "", reach := -1.0) -> bool:
	if not ship_is_initialized(): return false
	var from := _ship_player.global_position
	if from.distance_to(point)>(ship_interaction_reach if reach<0 else reach): return false
	if not room.is_empty() and (not _ship_in_area(from,room) or not _ship_in_area(point,room)): return false
	# The wall artwork is visual-only. Sample the authoritative floor mask and
	# pressure-door barriers along the entire segment, then test solid furniture.
	var distance := from.distance_to(point)
	for i in range(maxi(2,ceili(distance/2.0))+1):
		var sample := from.lerp(point,float(i)/float(maxi(2,ceili(distance/2.0))))
		if not _ship_player._is_body_over_floor(sample): return false
	var ray := PhysicsRayQueryParameters2D.create(from,point,1,[_ship_player.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func ship_refresh_prompt() -> void:
	_ship_active_id=""
	_ship_near_hide_id=""
	for key in ["_active_room_task_id","_active_crew_task_id"]: set(key,&"")
	set("_active_amara_interaction",false);set("_active_airlock_exit",false)
	if get("_arrival_briefing_open") or get("_hud_modal_open") or get("_task_console_open") or get("_crew_dialogue_open"): return
	if ship_control_locked():
		var locked_prompt := "ENTERING COVER / [Q] CANCEL" if _ship_hide_phase=="entering" else "LEAVING COVER / PLEASE WAIT" if _ship_hide_phase=="exiting" else (_ship_hide_feedback if not _ship_hide_feedback.is_empty() else "[H] EXIT COVER") if _ship_hide_phase=="concealed" else "COMMUNICATION IN PROGRESS"
		_ship_hud.set_interaction_prompt(locked_prompt,true);return
	var candidates: Array=[]
	var nearest_hide_distance := INF
	for id in _ship_points:
		var entry: Dictionary=_ship_points[id]
		if not is_instance_valid(entry.marker): continue
		if ship_can_reach(entry.marker.global_position,entry.definition.room):
			if entry.definition.kind in ["storage_hide","cargo_hide"]:
				var hide_distance: float=_ship_player.global_position.distance_to(entry.marker.global_position)
				if hide_distance<nearest_hide_distance:
					nearest_hide_distance=hide_distance;_ship_near_hide_id=id
				continue
			candidates.append({"id":id,"distance":_ship_player.global_position.distance_to(entry.marker.global_position),"prompt":str(entry.host.name).to_snake_case().capitalize()+"   /   [E] ACCESS","kind":"prop"})
	var npc := get_node_or_null("AmaraOkoye") as Node2D
	if npc != null and _ship_player.global_position.distance_to(npc.global_position) <= 90.0:
		var talk_priority := -100.0 if ship_story_active() else _ship_player.global_position.distance_to(npc.global_position)
		candidates.append({"id":"amara","distance":talk_priority,"prompt":"AMARA OKOYE   /   [E] TALK","kind":"amara"})
	if bool(get("_crew_tasks_unlocked")) and not ship_story_active():
		for task in get("AMARA_CREW_TASKS"):
			if get("_completed_crew_tasks").has(task.id): continue
			var host := get_node_or_null(task.station_path) as Node2D
			if host==null: continue
			var point: Vector2=call("_crew_task_interaction_position",task,host)
			if ship_can_reach(point,"hydro",36.0): candidates.append({"id":str(task.id),"distance":_ship_player.global_position.distance_to(point)-5.0,"prompt":task.prompt,"kind":"crew"})
	var airlock := get_node_or_null("ExteriorAirlockGate") as Node2D
	if airlock!=null and ship_can_reach(airlock.global_position+Vector2(0,28),"",36.0): candidates.append({"id":"airlock","distance":_ship_player.global_position.distance_to(airlock.global_position+Vector2(0,28)),"prompt":"SURVEY BRIEFING PENDING / [E] CHECK AUTHORIZATION" if ship_story_active() else "DEVELOPMENT AIRLOCK / [E] MOCK PLANET","kind":"airlock"})
	if candidates.is_empty():
		var prompt := "[H] HIDE" if not _ship_near_hide_id.is_empty() else _ship_status if _ship_status_time>0 else ""
		_ship_hud.set_interaction_prompt(prompt,not prompt.is_empty());return
	candidates.sort_custom(func(a: Dictionary,b: Dictionary): return a.distance<b.distance if not is_equal_approx(a.distance,b.distance) else a.id<b.id)
	var target: Dictionary=candidates[0]
	if target.kind=="prop": _ship_active_id=target.id
	elif target.kind=="amara": set("_active_amara_interaction",true)
	elif target.kind=="crew": set("_active_crew_task_id",StringName(target.id))
	elif target.kind=="airlock": set("_active_airlock_exit",true)
	_ship_hud.set_interaction_prompt(target.prompt+("  /  [H] HIDE" if not _ship_near_hide_id.is_empty() else ""),true)

func ship_handle_interact(event: InputEvent) -> bool:
	if not ship_is_initialized() or not event.is_action_pressed(&"interact"): return false
	if ship_control_locked():
		get_viewport().set_input_as_handled();return true
	if _ship_active_id.is_empty(): return false
	var entry: Dictionary=_ship_points[_ship_active_id]
	if not ship_can_reach(entry.marker.global_position,entry.definition.room): return false
	ship_open_procedure(_ship_active_id);get_viewport().set_input_as_handled();return true

func ship_open_procedure(id: String) -> bool:
	if not _ship_points.has(id) or get("_task_console_open") or ship_control_locked(): return false
	var point: Dictionary=_ship_points[id]
	if not is_instance_valid(point.marker) or not ship_can_reach(point.marker.global_position,point.definition.room): return false
	if point.definition.kind in ["storage_hide","cargo_hide"]: return false
	if ship_story_active() and id.begins_with("power.") and _ship_state.completed.has("power") and not _ship_story.has("power.reported") and _ship_story.has("amara.observation_reported"):
		_story_power_ack(); return true
	_ship_player.face_toward(point.host.global_position)
	# Ported artifact boards use their fixed 1280x720 screens;
	# everything the design doesn't cover keeps the generic procedure panel.
	var eito_kind: String = EITO_LAYER.kind_for(_ship_state, id)
	if eito_kind.is_empty():
		_ship_panel=SHIP_PANEL.new();_ship_panel.setup(_ship_state,id,str(_ship_points[id].host.name).to_snake_case().capitalize())
	else:
		_ship_panel=EITO_LAYER.new();_ship_panel.setup(_ship_state,id,str(_ship_points[id].host.name).to_snake_case().capitalize(),eito_kind)
		# Leila's comms card only belongs to the chapter once engineering has
		# authorised the power work; an early repair is credited when it gets there.
		_ship_panel.story_mode=ship_story_active() and (eito_kind != "power" or _ship_story.has("amara.observation_reported"))
		_ship_panel.save_path=ship_mission_save_path
		if ship_story_active(): _ship_panel.story_objective=str(_ship_story.objective().get("title",""))
	_ship_panel.action_requested.connect(_ship_action.bind(id))
	if _ship_panel is EITO_LAYER: _ship_panel.legacy_receipt_recorded.connect(_ship_eito_legacy_recorded)
	_ship_panel.closed.connect(_ship_panel_closed)
	_ship_panel.save_requested.connect(func(): _ship_panel.feedback(ship_save_game()))
	_ship_panel.load_requested.connect(func(): _ship_panel.feedback(ship_load_game()))
	set("_task_console_open",true);_ship_hud.set_walking_visible(false);call("_update_player_walk_state")
	add_child(_ship_panel)
	return true

func _ship_action(action_id: String, value: Variant, prop_id: String) -> void:
	if not is_instance_valid(_ship_panel) or _ship_panel.prop_id!=prop_id or ship_control_locked(): return
	var entry: Dictionary=_ship_points.get(prop_id,{})
	if entry.is_empty() or not is_instance_valid(entry.marker) or not ship_can_reach(entry.marker.global_position,entry.definition.room):
		_ship_panel.feedback("Move back to this station's clear access point before operating it.",false);return
	var result: Dictionary=_ship_state.act(prop_id,action_id,value)
	if result.get("event") == "story":
		_ship_panel.close_panel()
		if action_id == "story:briefing": _story_assignment()
		else: _story_handoff()
		return
	if result.get("event") == "optional":
		call("_complete_crew_task", StringName(result.task)); _story_sync()
		_ship_panel.feedback("Optional observation recorded. This does not repair irrigation or add a required mission.")
		_story_checkpoint(); return
	if result.get("event","")=="legacy":
		_ship_service_prop=prop_id;_ship_service_task=result.task
		_ship_panel.close_panel()
		call("_open_room_task_console",StringName(result.task));return
	if result.get("event","")=="hide":
		_ship_panel.close_panel();ship_enter_hiding(prop_id);return
	if is_instance_valid(_ship_panel): _ship_panel.feedback(result.message,result.ok)
	_ship_status=result.message;_ship_status_time=4.0
	if result.ok and ship_story_active(): _story_equipment_action(prop_id, action_id)

func _ship_panel_closed() -> void:
	_ship_panel=null;set("_task_console_open",false)
	_eito_flash_pending()
	_ship_hud.set_walking_visible(not bool(get("_arrival_briefing_open")))
	call("_update_player_walk_state")

func ship_attach_service_console(console: Node, task: StringName) -> void:
	_ship_service_console=console;_ship_service_task=str(task)
	console.set_resume_progress(_ship_state.legacy_progress.get(str(task),{}))

func ship_legacy_completed(task_id: StringName) -> void:
	if _ship_state.legacy_complete(str(task_id),_ship_service_prop):
		var existing: Dictionary=get("_completed_room_tasks");existing[task_id]=true
		_ship_status="Controls completed. Restore and verify the connected system at its station.";_ship_status_time=6.0

func _ship_eito_legacy_recorded(task_id: String) -> void:
	var existing: Dictionary=get("_completed_room_tasks")
	existing[StringName(task_id)]=true
	_ship_status="Controls completed. Restore and verify the connected system at its station."
	_ship_status_time=6.0

func ship_service_closed() -> void:
	if is_instance_valid(_ship_service_console): _ship_state.legacy_progress[_ship_service_task]=_ship_service_console.progress_snapshot()
	_ship_service_console=null

func _ship_state_changed() -> void:
	if _ship_syncing: return
	_ship_sync_hud();_ship_publish_systems()

func _ship_inventory_changed() -> void:
	if _ship_ready and _ship_state!=null and is_instance_valid(_ship_panel): _ship_panel._schedule_rebuild()

func _ship_sync_hud() -> void:
	if not ship_is_initialized() or not is_instance_valid(_ship_hud): return
	if ship_story_active():
		_story_sync(); return
	var entries: Array=[]
	for objective in SHIP_CATALOG.OBJECTIVES:
		var station_id: String=SHIP_CATALOG.OBJECTIVE_STATIONS[objective[0]]
		var entry: Dictionary=_ship_points.get(station_id,{})
		var host := get_node_or_null(SHIP_CATALOG.definition(station_id).path) as Node2D
		var point: Vector2=entry.marker.global_position if is_instance_valid(entry.get("marker")) else host.global_position if host!=null else Vector2.ZERO
		entries.append({"id":StringName(objective[0]),"title":objective[3],"action_hint":objective[1],"purpose":objective[4],"description":objective[1],"marker_label":objective[2],"position":point,"marker_position":point+Vector2(0,-16)})
	var completion: Dictionary=_ship_state.completed.duplicate()
	if bool(get("_crew_tasks_unlocked")):
		for task in get("AMARA_CREW_TASKS"):
			var host := get_node_or_null(task.station_path) as Node2D
			var point: Vector2=call("_crew_task_interaction_position",task,host) if host!=null else _ship_player.global_position
			entries.append({"id":task.id,"title":task.title,"action_hint":task.get("action_hint", task.get("prompt", "Inspect this station.")),"purpose":task.get("purpose", "Optional crew requests provide context about ship systems and the people maintaining them."),"description":"Optional / "+str(task.title),"marker_label":"OPTIONAL","position":point})
			if get("_completed_crew_tasks").has(task.id): completion[str(task.id)]=true
	_ship_hud.set_ship_objectives(entries,completion)

func _ship_publish_systems() -> void:
	if not _ship_ready: return
	set_meta("ship_system_state",_ship_state.systems.duplicate(true))
	for id in _ship_points:
		var entry: Dictionary=_ship_points[id]
		var room: String=entry.definition.room
		if _ship_state.systems.has(room): entry.host.set_meta("ship_system_state",_ship_state.systems[room].duplicate(true))
	var lighting := get_node_or_null("ShipRoomLighting")
	if lighting!=null:
		lighting.set_room_flicker(&"r04_power_maint",_ship_state.phase=="return" and not _ship_state.completed.has("power"))

func _ship_hide_bodies(host: Node2D) -> Array[RID]:
	var bodies: Array[RID] = []
	for body in host.find_children("*", "StaticBody2D", true, false): bodies.append(body.get_rid())
	return bodies

func _ship_hide_point_clear(point: Vector2, exclusions: Array[RID] = []) -> bool:
	if not _ship_player._is_body_over_floor(point): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _ship_player.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0,point); query.collision_mask = 7
	var excluded: Array[RID] = [_ship_player.get_rid()]
	excluded.append_array(exclusions); query.exclude = excluded
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _ship_in_locker_portal(host: Node2D, point: Vector2) -> bool:
	var local: Vector2 = host.to_local(point)-host.footprint_offset
	var half: Vector2 = host.get_current_footprint_size()*0.5
	return local.x >= -half.x-10.0 and local.x <= 3.0 and absf(local.y) <= float(host.hide_door_tolerance)

func _ship_hide_segment_clear(from: Vector2, to: Vector2, host: Node2D = null) -> bool:
	var samples := maxi(1,ceili(from.distance_to(to)))
	for i in range(samples+1):
		var point := from.lerp(to,float(i)/samples)
		var excluded: Array[RID] = []
		if host != null and _ship_in_locker_portal(host,point): excluded = _ship_hide_bodies(host)
		if not _ship_hide_point_clear(point,excluded): return false
	return true

func _ship_hide_route_clear(route: PackedVector2Array, host: Node2D = null) -> bool:
	if route.is_empty(): return false
	if not _ship_hide_segment_clear(route[0],route[0],host): return false
	for i in range(1,route.size()):
		if not _ship_hide_segment_clear(route[i-1],route[i],host): return false
	return true

func _ship_find_walk_route(from: Vector2, to: Vector2, room: String, radius := 104.0) -> PackedVector2Array:
	if not _ship_hide_point_clear(from) or not _ship_hide_point_clear(to): return PackedVector2Array()
	if not _ship_in_area(from,room) or not _ship_in_area(to,room): return PackedVector2Array()
	if _ship_hide_segment_clear(from,to): return PackedVector2Array([from,to])
	var step := 4.0; var cells := ceili(radius/step)
	var origin := from-Vector2.ONE*float(cells)*step
	var start := Vector2i(cells,cells)
	var queue: Array[Vector2i] = [start]; var seen := {start:start}; var head := 0
	var found := Vector2i(-1,-1)
	while head < queue.size():
		var cell := queue[head]; head += 1
		var point := origin+Vector2(cell)*step
		if point.distance_to(to)<=6.0 and _ship_hide_segment_clear(point,to): found=cell; break
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+direction
			if next.x<0 or next.y<0 or next.x>cells*2 or next.y>cells*2 or seen.has(next): continue
			var candidate := origin+Vector2(next)*step
			if _ship_in_area(candidate,room) and _ship_hide_segment_clear(point,candidate): seen[next]=cell; queue.append(next)
	if found.x<0: return PackedVector2Array()
	var backwards := PackedVector2Array([to,origin+Vector2(found)*step])
	while found!=start:
		found=seen[found]; backwards.append(origin+Vector2(found)*step)
	backwards.reverse()
	return backwards

func _ship_hide_entry_route(id: String, from: Vector2) -> PackedVector2Array:
	if not _ship_points.has(id): return PackedVector2Array()
	var entry: Dictionary = _ship_points[id]; var host: Node2D = entry.host
	var inside: Vector2 = host.get_node("HidePoint").global_position
	if entry.definition.kind == "cargo_hide":
		# Walk around the sealed stack. No own-body exclusions or reduced actor.
		return _ship_find_walk_route(from,inside,entry.definition.room)
	if entry.definition.kind != "storage_hide" or host.direction != 3 or host.appearance not in [0,1]: return PackedVector2Array()
	var local: Vector2 = host.to_local(from)-host.footprint_offset
	var half: Vector2 = host.get_current_footprint_size()*0.5
	if local.x > -half.x-8.0 or absf(local.y)>float(host.hide_door_tolerance): return PackedVector2Array()
	var portal: Vector2 = host.to_global(host.footprint_offset+Vector2(-half.x-9.0,0))
	var route := PackedVector2Array([from,portal,inside])
	return route if _ship_hide_route_clear(route,host) else PackedVector2Array()

func _ship_play_hide_sound(host: Node2D, kind: String) -> void:
	# The existing door mechanism fits the locker. The tied crates have no
	# suitable fabric/rope sound, so they remain silent.
	if kind != "storage_hide": return
	var sound := host.get_node_or_null("HideSFX") as AudioStreamPlayer2D
	if sound == null:
		sound = AudioStreamPlayer2D.new()
		sound.name = "HideSFX"
		sound.stream = LOCKER_HIDE_SOUND
		sound.volume_db = -18.0
		host.add_child(sound)
	sound.play()

func ship_enter_hiding(id: String) -> bool:
	if ship_control_locked() or not _ship_points.has(id): return false
	var entry: Dictionary = _ship_points[id]; var host: Node2D = entry.host
	if entry.definition.kind not in ["storage_hide","cargo_hide"] or not is_instance_valid(entry.marker): return false
	if not ship_can_reach(entry.marker.global_position,entry.definition.room): return false
	if host.has_meta("hide_occupant") and int(host.get_meta("hide_occupant")) != _ship_player.get_instance_id():
		_ship_status = "This hiding place is occupied."; _ship_status_time=5; return false
	var route := _ship_hide_entry_route(id,_ship_player.global_position)
	if route.is_empty():
		_ship_status = "No clear cover route. Use the WEST door of an intact locker; keep the approach and pocket clear." if entry.definition.kind=="storage_hide" else "The behind-stack route or cover pocket is obstructed. The sealed crates cannot be entered."
		_ship_status_time=7; return false
	host.set_meta("hide_occupant",_ship_player.get_instance_id())
	_ship_hide_prior_appearance=host.appearance; _ship_hide_speed=host.hide_transition_speed
	_ship_hide_exit=_ship_player.global_position; _ship_hide_id=id; _ship_hide_phase="entering"
	_ship_hide_feedback=""
	_ship_hide_route=route; _ship_hide_route_index=1
	_ship_hide_traversed=PackedVector2Array([_ship_player.global_position])
	if entry.definition.kind=="storage_hide": host.appearance=1
	_ship_play_hide_sound(host,entry.definition.kind)
	call("_update_player_walk_state")
	return true

func _ship_hide_exit_route(id: String, inside: Vector2, preferred: Vector2) -> PackedVector2Array:
	if not _ship_points.has(id): return PackedVector2Array()
	var entry: Dictionary = _ship_points[id]; var host: Node2D=entry.host
	if entry.definition.kind=="cargo_hide":
		var stack_candidates := PackedVector2Array([preferred])
		for distance in [12.0,24.0,36.0]:
			for side in [Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]: stack_candidates.append(preferred+side*distance)
		for candidate in stack_candidates:
			var around_stack := _ship_find_walk_route(inside,candidate,entry.definition.room)
			if not around_stack.is_empty(): return around_stack
		return PackedVector2Array()
	if host.direction!=3: return PackedVector2Array()
	var half: Vector2=host.get_current_footprint_size()*0.5
	var portal: Vector2=host.to_global(host.footprint_offset+Vector2(-half.x-9.0,0))
	if not _ship_hide_segment_clear(inside,portal,host): return PackedVector2Array()
	var candidates := PackedVector2Array([preferred,portal])
	for radius in [8.0,16.0,24.0,32.0]:
		for direction in [Vector2.LEFT,Vector2.UP,Vector2.DOWN]: candidates.append(portal+direction*radius)
	for candidate in candidates:
		if not _ship_hide_point_clear(candidate) or not _ship_in_area(candidate,entry.definition.room): continue
		var outside := _ship_find_walk_route(portal,candidate,entry.definition.room,40)
		if outside.is_empty(): continue
		var result := PackedVector2Array([inside]); result.append_array(outside)
		if _ship_hide_route_clear(result,host): return result
	return PackedVector2Array()

func _ship_safe_position(preferred: Vector2, _room := "") -> Vector2:
	# Compatibility helper now requires a connected exit from the current host.
	if _ship_hide_id.is_empty(): return preferred if _ship_hide_point_clear(preferred) else Vector2.INF
	var route := _ship_hide_exit_route(_ship_hide_id,_ship_player.global_position,preferred)
	return route[-1] if not route.is_empty() else Vector2.INF

func ship_exit_hiding() -> bool:
	if _ship_hide_phase=="outside": return true
	if _ship_hide_phase!="concealed": return false
	var route := _ship_hide_exit_route(_ship_hide_id,_ship_player.global_position,_ship_hide_exit)
	if route.is_empty():
		_ship_hide_feedback="EXIT BLOCKED / REMAIN IN COVER / [H] RETRY WHEN CLEAR"
		_ship_status="Exit obstructed. Stay concealed and press H to retry when the WEST approach clears."; _ship_status_time=6; return false
	_ship_hide_feedback=""
	_ship_hide_route=route; _ship_hide_route_index=1; _ship_hide_phase="exiting"
	var entry: Dictionary=_ship_points[_ship_hide_id]
	if entry.definition.kind=="storage_hide": entry.host.appearance=1
	_ship_play_hide_sound(entry.host,entry.definition.kind)
	_ship_player.set_concealment(false,"")
	return true

func ship_cancel_hiding() -> bool:
	if _ship_hide_phase!="entering": return false
	var route := _ship_hide_traversed.duplicate(); route.reverse()
	var entry: Dictionary=_ship_points[_ship_hide_id]
	if not _ship_hide_route_clear(route,entry.host if entry.definition.kind=="storage_hide" else null):
		_ship_interrupt_hide_transition(); return false
	_ship_hide_route=route; _ship_hide_route_index=1; _ship_hide_phase="exiting"
	return true

func _ship_interrupt_hide_transition() -> void:
	if _ship_hide_point_clear(_ship_player.global_position):
		_ship_release_hide_reservation()
		_ship_player.set_concealment(false,""); _ship_player.get_node("CollisionShape2D").set_deferred("disabled",false)
		_ship_hide_phase="outside"; _ship_hide_id=""
	else:
		_ship_hide_phase="concealed"; _ship_player.set_concealment(true,_ship_hide_id)
		_ship_player.get_node("CollisionShape2D").set_deferred("disabled",true)
		var entry: Dictionary=_ship_points.get(_ship_hide_id,{})
		if not entry.is_empty() and is_instance_valid(entry.host) and entry.definition.kind=="storage_hide": entry.host.appearance=0
	_ship_status="Cover transition interrupted by an obstruction. Controls remain safe; clear the approach and retry."; _ship_status_time=7
	_ship_hide_feedback="COVER ROUTE BLOCKED / [H] RETRY WHEN CLEAR" if _ship_hide_phase=="concealed" else ""
	call("_update_player_walk_state")

func _ship_process_hiding(delta: float) -> void:
	if _ship_hide_phase not in ["entering","exiting"] or bool(get("_hud_modal_open")): return
	if not _ship_points.has(_ship_hide_id): _ship_interrupt_hide_transition(); return
	var entry: Dictionary=_ship_points[_ship_hide_id]
	var host: Node2D=entry.host if entry.definition.kind=="storage_hide" else null
	if _ship_hide_route_index>=_ship_hide_route.size():
		_ship_player.sprite.stop()
		if _ship_hide_phase=="entering":
			_ship_hide_phase="concealed"; _ship_player.set_concealment(true,_ship_hide_id)
			_ship_player.get_node("CollisionShape2D").set_deferred("disabled",true)
			if host!=null: host.appearance=0
		else:
			_ship_release_hide_reservation(); _ship_hide_phase="outside"; _ship_hide_id=""
			_ship_player.set_concealment(false,""); _ship_player.get_node("CollisionShape2D").set_deferred("disabled",false)
		call("_update_player_walk_state"); return
	var target := _ship_hide_route[_ship_hide_route_index]
	var current := _ship_player.global_position
	var next := current.move_toward(target,_ship_hide_speed*delta)
	if not _ship_hide_segment_clear(current,next,host): _ship_interrupt_hide_transition(); return
	_ship_player.face_toward(target); _ship_player.sprite.play()
	_ship_player.global_position=next
	if _ship_hide_phase=="entering": _ship_hide_traversed.append(next)
	if next.is_equal_approx(target): _ship_hide_route_index+=1

func _ship_release_hide_reservation() -> void:
	if not _ship_hide_id.is_empty() and _ship_points.has(_ship_hide_id):
		var host: Node2D=_ship_points[_ship_hide_id].host
		if is_instance_valid(host):
			if host.get_meta("hide_occupant",0)==_ship_player.get_instance_id(): host.remove_meta("hide_occupant")
			if _ship_points[_ship_hide_id].definition.kind=="storage_hide": host.appearance=_ship_hide_prior_appearance

func _ship_valid_load_position(payload: Dictionary) -> Vector2:
	if payload.get("spawn_pending",false):
		# The prologue has no live actor. Resolve its first landing against the
		# current scene's saved spawn, never a fabricated pre-ship coordinate.
		return _ship_player.global_position if _ship_hide_point_clear(_ship_player.global_position) else Vector2.INF
	var desired := Vector2(float(payload.position[0]),float(payload.position[1]))
	var concealed: String=payload.get("concealed","")
	if concealed.is_empty(): return desired if _ship_hide_point_clear(desired) else Vector2.INF
	if not _ship_points.has(concealed): return Vector2.INF
	var preferred := Vector2(float(payload.hide_exit[0]),float(payload.hide_exit[1]))
	# Pending entry/cancel saves may already be on clear outside floor.
	if _ship_hide_point_clear(desired):
		var outside := _ship_find_walk_route(desired,preferred,_ship_points[concealed].definition.room)
		if not outside.is_empty(): return outside[-1]
	var route := _ship_hide_exit_route(concealed,desired,preferred)
	return route[-1] if not route.is_empty() else Vector2.INF

func ship_snapshot() -> Dictionary:
	if is_instance_valid(_ship_service_console): ship_service_capture()
	var payload := {"format":"echoes_ship_side", "version":2, "mission":_ship_state.snapshot(), "inventory":_ship_hud.inventory_snapshot(), "position":[_ship_player.global_position.x,_ship_player.global_position.y], "legacy_completed":get("_completed_room_tasks").duplicate(), "crew_completed":get("_completed_crew_tasks").duplicate(), "amara_intro":get("_amara_intro_seen"), "crew_unlocked":get("_crew_tasks_unlocked"), "concealed":_ship_hide_id, "hide_exit":[_ship_hide_exit.x,_ship_hide_exit.y]}
	if ship_story_active(): payload.story = _ship_story.snapshot()
	return payload

func ship_service_capture() -> void:
	if is_instance_valid(_ship_service_console): _ship_state.legacy_progress[_ship_service_task]=_ship_service_console.progress_snapshot()

func ship_restore(payload: Dictionary, restore_position := true) -> bool:
	if not STORY_SAVE.valid_payload(payload): return false
	var restored_story = null
	if payload.version == 2 and payload.has("story"):
		restored_story = SHIP_STORY.new()
		if not restored_story.restore(payload.story): return false
		if _ship_story!=null: restored_story.sequence=maxi(restored_story.sequence,_ship_story.sequence)
		if restored_story.has("watch.accepted") and not payload.mission.flags.get("assigned",false): return false
		for pair in [["roster.reviewed","crew"],["power.reported","power"],["amara.repair_reported","hydro"]]:
			if restored_story.has(pair[0]) and not payload.mission.completed.has(pair[1]): return false
	var safe_load_position: Vector2 = _ship_player.global_position
	if restore_position:
		safe_load_position = _ship_valid_load_position(payload)
		if safe_load_position == Vector2.INF: return false
	_ship_syncing = true
	if is_instance_valid(get("_crew_dialogue")): get("_crew_dialogue").cancel_dialogue()
	_story_release_locks(); _ship_release_hide_reservation()
	_ship_hud.inventory_restore(payload.inventory); _ship_state.restore(payload.mission)
	_ship_story = restored_story
	_ship_pending_cue_reoffer = ""
	if restored_story == null:
		_ship_state.work_order_context = "maintenance"; _ship_state.authorized_work_orders = PackedStringArray()
	else:
		_ship_state.work_order_context = "first_watch"
		_ship_state.authorized_work_orders = restored_story.work_orders()
		for cue_id in restored_story.cues:
			if restored_story.cues[cue_id].status == "pending":
				restored_story.cues[cue_id].status = "cancelled"
				_ship_pending_cue_reoffer = cue_id
		if not restored_story.cues.has("cue.asteria.arrival"):
			var intro_status: String=str(restored_story.cues.get("cue.thura.earth_years",{}).get("status",""))
			_ship_pending_cue_reoffer="cue.asteria.arrival" if intro_status in ["completed","skipped"] else "cue.thura.earth_years" if intro_status in ["pending","cancelled","failed"] else _ship_pending_cue_reoffer
	var legacy := {}; var crew := {}
	for key in payload.legacy_completed: legacy[StringName(key)] = bool(payload.legacy_completed[key])
	for key in payload.crew_completed: crew[StringName(key)] = bool(payload.crew_completed[key])
	set("_completed_room_tasks",legacy); set("_completed_crew_tasks",crew)
	set("_amara_intro_seen",bool(payload.get("amara_intro",false))); set("_crew_tasks_unlocked",bool(payload.get("crew_unlocked",false)))
	if restore_position: _ship_player.global_position = safe_load_position
	_ship_player.set_concealment(false,"")
	_ship_player.get_node("CollisionShape2D").set_deferred("disabled",false)
	_ship_hide_id = ""; _ship_hide_phase = "outside"
	_ship_hide_feedback=""
	_ship_story_hud_key = ""; _ship_syncing = false
	_ship_sync_hud(); _ship_publish_systems(); call("_update_player_walk_state")
	if is_instance_valid(_ship_panel): _ship_panel._schedule_rebuild()
	if not _ship_pending_cue_reoffer.is_empty(): _story_reoffer_pending_cue.call_deferred()
	return true

func _story_reoffer_pending_cue() -> void:
	if not ship_story_active() or not is_inside_tree(): return
	if bool(get("_hud_modal_open")) or bool(get("_task_console_open")) or bool(get("_crew_dialogue_open")) or not _ship_cue_active.is_empty() or _ship_hide_phase!="outside": return
	var cue_id := _ship_pending_cue_reoffer; _ship_pending_cue_reoffer = ""
	if cue_id == "cue.asteria.arrival":
		_story_begin_cue(cue_id,"arrival_briefing")
		call("_show_story_arrival_briefing")
	elif cue_id == "cue.thura.earth_years":
		ship_request_story_cue(cue_id,"res://scenes/ui/earth_years_montage.tscn")
	else:
		_ship_status="Communication interrupted safely. The earned watch records are intact; return to the bridge planning table to continue."; _ship_status_time=12.0
	call("_update_player_walk_state")

func _ship_save_path_allowed(path: String) -> bool:
	return STORY_SAVE.allowed(path)

func ship_save_game() -> String:
	if not _ship_save_path_allowed(ship_mission_save_path): return "Save refused: use the ship-side save namespace or isolated validation directory."
	var payload := ship_snapshot()
	if not STORY_SAVE.valid_payload(payload): return "Save validation failed. Existing campaign has not been changed."
	var result := STORY_SAVE.atomic_write(ship_mission_save_path,payload)
	if result != OK: return "Could not replace ship-side save; progress is still in memory."
	if ship_story_active(): STORY_SAVE.remember(ship_mission_save_path)
	return "Ship-side mission, inventory, equipment and story progress saved."

func ship_load_game() -> String:
	if is_instance_valid(_ship_service_console): return "Close the service controls before loading. Current procedure and supplies remain recorded."
	if not _ship_save_path_allowed(ship_mission_save_path) or not FileAccess.file_exists(ship_mission_save_path): return "No ship-side save exists for this scenario."
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ship_mission_save_path))
	if not parsed is Dictionary or not ship_restore(parsed): return "Save is invalid/incompatible. Current mission and inventory were not changed."
	return "Ship-side progress restored. Concealed saves resume at the validated exit with control restored."

func ship_start_development_scenario(context: String) -> void:
	if context not in ["outbound","return"] or not ship_is_initialized(): return
	if _ship_hide_phase != "outside":
		_ship_status = "Leave concealment before starting a development fixture."; _ship_status_time = 5.0; return
	_ship_syncing = true
	if is_instance_valid(get("_crew_dialogue")): get("_crew_dialogue").cancel_dialogue()
	_story_release_locks(); _ship_story = null; _ship_story_hud_key = ""
	_ship_hud.inventory_restore(_ship_initial_inventory)
	_ship_state.reset(context)
	set("_completed_room_tasks",{});set("_completed_crew_tasks",{});set("_crew_tasks_unlocked",false)
	set("_amara_intro_seen",false)
	ship_mission_save_path="user://ship_side_missions_dev_"+context+".json"
	_ship_syncing=false;_ship_sync_hud();_ship_publish_systems()
	_ship_status="DEVELOPMENT SCENARIO / "+context.to_upper()+". Separate save; canonical transition and endings are unchanged.";_ship_status_time=7.0

func ship_store_transit() -> void:
	if ship_is_initialized():
		Engine.set_meta("ship_mission_transit",ship_snapshot())
		Engine.set_meta("ship_mission_transit_save_path",ship_mission_save_path)

func ship_amara_observation() -> String:
	if not ship_is_initialized(): return ""
	if _ship_state.phase=="return":
		return "My recorded reservoir and plant observations differ from the earlier watch. Compare the EC, pump and power logs before blaming the material. I have not established a cause."
	return "The duty log has the current reservoir and flow readings. Verify the repair at the console after servicing; an inspection alone is not the same as restored delivery."

func ship_story_active() -> bool:
	return _ship_story != null

func ship_story_continuing() -> bool:
	return not _ship_pending_continue_path.is_empty() or Engine.has_meta("ship_story_continue_path")

func _story_checkpoint() -> void:
	if ship_story_active() and ship_story_autosave and ship_is_initialized() and not _ship_syncing:
		var message := ship_save_game()
		if not message.begins_with("Ship-side"): _ship_status = message; _ship_status_time = 8.0

func _story_sync() -> void:
	if not ship_story_active() or _ship_syncing: return
	_ship_state.authorized_work_orders = _ship_story.work_orders()
	_ship_state.optional_checks = get("_completed_crew_tasks").duplicate()
	_ship_state.optional_checks.enabled = bool(get("_crew_tasks_unlocked"))
	_ship_state.story_progress = {"completed": _ship_story.completed_count(), "acknowledged": _ship_story.has("watch.acknowledged"), "summary": _ship_story.summary, "can_submit": _ship_story.has("amara.repair_reported") and _story_repairs_healthy() and not _ship_story.has("watch.acknowledged"), "receipts":_ship_story.receipts.duplicate(), "objective":_ship_story.objective()}
	var objective: Dictionary = _ship_story.objective()
	if _ship_state.completed.has("hydro") and _ship_story.has("power.reported") and not _ship_story.has("amara.repair_reported"):
		objective.title = "Report restored delivery"; objective.station = "amara"; objective.marker_label = "AMARA"
		objective.action_hint = "Return to Amara and share the verified irrigation readings."
		objective.description = "Return to Amara with the verified irrigation readings. Repair history is retained if conditions change."
		objective.purpose = "The crew needs confirmation that the plants are receiving nutrients again before the watch report is closed."
	elif _ship_state.completed.has("power") and not _ship_story.has("power.reported") and _ship_story.has("amara.observation_reported"):
		objective.title = "Hear engineering's reply"; objective.station = "power.breaker"
		objective.action_hint = "Use the power workstation to receive Leila's status reply."
		objective.description = objective.action_hint
		objective.purpose = "Confirm that engineering sees the restored power feed before continuing with the irrigation repair."
	var point := _ship_player.global_position
	if objective.station == "amara":
		var npc := get_node_or_null("AmaraOkoye") as Node2D
		if npc != null:
			point = npc.global_position
			if not _ship_in_area(point, "hydro"):
				objective.action_hint += " Amara is on patrol; follow her nearby crew marker."
				objective.description = objective.action_hint
	elif _ship_points.has(objective.station) and is_instance_valid(_ship_points[objective.station].marker):
		point = _ship_points[objective.station].marker.global_position
	objective.position = point; objective.marker_position = point+Vector2(0,-20)
	_eito_track_objective(str(objective.title))
	var key := str([objective.title, objective.description, objective.purpose, Vector2i(point/8), _ship_story.completed_count(), get("_completed_crew_tasks"), get("_crew_tasks_unlocked")])
	if key == _ship_story_hud_key: return
	_ship_story_hud_key = key
	_ship_hud.set_story_objective(objective, _ship_story.completed_count(), bool(get("_crew_tasks_unlocked")), get("_completed_crew_tasks").size())

## NEW OBJECTIVE ribbon from the redesign. Panels that announce the next
## objective themselves (crew records, power) don't get a second ribbon; other
## changes wait until no panel or conversation is covering the screen.
var _eito_objective := ""
var _eito_ribbon := ""
func _eito_track_objective(title: String) -> void:
	if title == _eito_objective:
		_eito_flash_pending(); return
	var first := _eito_objective.is_empty()
	_eito_objective = title
	if first: return
	if is_instance_valid(_ship_panel) and str(_ship_panel.get("kind")) in ["records", "power"]: _eito_ribbon = ""
	else: _eito_ribbon = title
	_eito_flash_pending()

func _eito_flash_pending() -> void:
	if _eito_ribbon.is_empty() or bool(get("_task_console_open")) or bool(get("_crew_dialogue_open")): return
	var dialogue = get("_crew_dialogue")
	if is_instance_valid(dialogue) and dialogue.has_method("flash_objective"): dialogue.flash_objective(_eito_ribbon)
	_eito_ribbon = ""

func _story_repairs_healthy() -> bool:
	return _ship_state.completed.has("power") and _ship_state.completed.has("hydro") and _ship_state.bus_powered("science") and not _ship_state.systems.hydro.isolated and _ship_state.systems.hydro.flow>=90 and _ship_state.systems.hydro.ec>=1.8 and _ship_state.systems.hydro.ec<=2.4

func _story_speak(id: String, speaker: String, lines: Array[String], choices: Array = []) -> bool:
	if bool(get("_crew_dialogue_open")) or _ship_hide_phase != "outside" or bool(get("_hud_modal_open")): return false
	if is_instance_valid(_ship_panel): _ship_panel.close_panel()
	if bool(get("_task_console_open")): return false
	set("_crew_dialogue_open", true)
	var npc := get_node_or_null("AmaraOkoye")
	if id.begins_with("amara.") and npc != null: npc.set_in_dialogue(true)
	_ship_player.sprite.stop()
	_ship_hud.set_interaction_prompt("", false); _ship_hud.set_walking_visible(false); call("_update_player_walk_state")
	get("_crew_dialogue").start_dialogue(lines, false, {"id": id, "speaker": speaker, "choices": choices, "objective": str(_ship_story.objective().get("title",""))})
	return true

func _story_assignment() -> void:
	if not ship_story_active(): return
	if _ship_story.has("watch.acknowledged"):
		_story_speak("command.wait", "MAYA CHEN / CDR / TERMINAL TEXT", ["Your watch is handed over, Thura. Thank you. Await the Erebos survey briefing; surface deployment is not cleared yet."])
	elif _ship_story.has("watch.accepted"):
		_story_speak("command.reminder", "MAYA CHEN / CDR / TERMINAL TEXT", ["The roster terminal is in crew quarters, below the bridge corridor. Amara is tending the grow beds below that. Your watch covers service power and irrigation; the other routine systems are running normally."])
	else:
		_story_speak("command.assignment", "MAYA CHEN / CDR / TERMINAL TEXT", ["Welcome to the watch, Thura. We're preparing for the Erebos survey. Amara has poor delivery at the grow beds, and engineering has flagged the auxiliary service feed.", "Please review the watch roster at the quarters desk, then meet Amara. Compare the readings before you work on either system. The other routine checks are optional."], [{"id":"accept","label":"I'll take the watch"},{"id":"reason","label":"Why those two jobs?"},{"id":"later","label":"Not yet"}])

func ship_story_amara_dialogue() -> bool:
	if not ship_story_active(): return false
	var speaker := "AMARA OKOYE / MED / HYDROPONICS"
	if not _ship_story.has("roster.reviewed"):
		_story_speak("amara.early", speaker, ["Hello, Thura. Maya left your watch assignment at the bridge planning table. Check the quarters roster, then come find me; I'd appreciate another pair of eyes on these beds."])
	elif not _ship_story.has("amara.introduced"):
		_story_speak("amara.introduction", speaker, ["I'm Amara Okoye. I'm the medic, but I spend part of the watch keeping these grow beds alive.", "Delivery is low. The console by the west wall has the reservoir chemistry, pump capacity and flow readings. Have a look, then tell me what you find."], [{"id":"inspect","label":"I'll check the readings"},{"id":"pump_question","label":"Is the pump failing?"},{"id":"later","label":"A moment first"}])
	elif not _ship_story.has("hydro.diagnosed"):
		_story_speak("amara.inspect_reminder", speaker, ["Compare the readings at the hydroponics console. A healthy pump doesn't tell us whether nutrients are reaching the beds. Record the diagnosis, then bring it back to me."])
	elif not _ship_story.has("amara.observation_reported"):
		_story_speak("amara.observation_report", speaker, ["That fits what I'm seeing: normal chemistry, a healthy pump, but poor delivery. The service feed is down, and the manifold will still need attention once it's back.", "Leila has authorized the auxiliary power work. Restore and verify that feed first; then we can work on delivery without guessing."], [{"id":"report","label":"I'll restore the feed"},{"id":"reason","label":"Why power first?"},{"id":"later","label":"Not yet"}])
	elif _ship_state.completed.has("hydro") and not _ship_story.has("amara.repair_reported"):
		if _story_repairs_healthy():
			_story_speak("amara.repair_report", speaker, ["Delivery is back in range, and the reservoir is still where it should be. That's a verified repair, Thura. Thank you for checking the whole path.", "Take those readings to Maya at the bridge planning table. She needs the result, not another round of routine maintenance."], [{"id":"report","label":"I'll hand over the watch"},{"id":"later","label":"I'll report in a moment"}])
		else:
			_story_speak("amara.regressed", speaker, ["Your repair is in the log, but delivery isn't healthy right now. Check the service feed and isolation controls. Restore the actual readings before we call it ready."])
	else:
		var condition := "Delivery is holding steady." if _story_repairs_healthy() else "Delivery still needs attention; the current console readings are the guide."
		_story_speak("amara.optional", speaker, [condition+" I also have two optional observation checks: inspect the pump and check the seedling sensor. They won't replace the manifold repair."], [{"id":"optional","label":"Add the optional checks"},{"id":"later","label":"Maybe later"}])
	return true

func _story_power_ack() -> void:
	if not _ship_state.bus_powered("science"):
		_story_speak("engineering.regressed", "LEILA HADDAD / ENG / TERMINAL TEXT", ["The power repair is recorded, but the service feed isn't live at the moment. Restore the safe allocation before continuing."])
	else:
		_story_speak("engineering.power_ack", "LEILA HADDAD / ENG / TERMINAL TEXT", ["I've got your verified power readings, Thura. Essential supply stayed online and the service feed is live again. Good work.", "Amara's console should now show some delivery, but the manifold restriction remains. Isolate it there, align the labelled valves, restore and verify before you report back."], [{"id":"ack","label":"Understood"}])

func _story_handoff() -> void:
	if not _ship_story.has("amara.repair_reported") or not _story_repairs_healthy():
		_ship_status = "Restore the assigned systems and report the verified delivery to Amara before handing over."; _ship_status_time = 7.0; return
	if _ship_story.has("watch.acknowledged"): _story_assignment(); return
	_ship_story.summary = "ASTERIA-1 / DAY 184 / FIRST WATCH\nRoster: authorized watch records compared; this is not an in-person crew introduction.\n\nPOWER / BEFORE\n"+str(_ship_story.evidence.get("power.before",""))+"\nPOWER / VERIFIED\n"+_ship_state.readings("power")+"\n\nIRRIGATION / BEFORE\n"+str(_ship_story.evidence.get("hydro.before",""))+"\nIRRIGATION / VERIFIED\n"+_ship_state.readings("hydro")+"\n\nAmara's repair report received. Required equipment work: power and irrigation only.\nOther routine equipment was not falsely marked serviced."
	_ship_story.record("summary.submitted")
	_story_checkpoint()
	var context := _story_begin_cue("cue.asteria.watch_handoff", "production_terminal_text")
	if context.is_empty(): return
	if not _story_speak("command.handoff", "MAYA CHEN / CDR / TERMINAL TEXT", ["I've reviewed the watch summary: service power restored, irrigation verified, and Amara's report received. Thank you, Thura.", "Your watch is handed over. Await the Erebos survey briefing; this acknowledgement does not clear surface deployment."], [{"id":"ack","label":"Watch handed over"},{"id":"later","label":"Review it again first"}]):
		ship_finish_story_cue("cue.asteria.watch_handoff",context.request_token,"failed")

func _story_conversation_finished(id: String, result: String) -> void:
	set("_crew_dialogue_open", false)
	_ship_hud.set_walking_visible(not bool(get("_arrival_briefing_open")) and not bool(get("_task_console_open")))
	var npc := get_node_or_null("AmaraOkoye")
	if npc != null: npc.set_in_dialogue(false)
	if not ship_story_active(): call("_update_player_walk_state"); return
	match id:
		"command.assignment":
			if result == "accept":
				_ship_story.record("watch.accepted"); _ship_state.flags.assigned = true
			elif result == "reason":
				_story_speak("command.assignment_reason", "MAYA CHEN / CDR / TERMINAL TEXT", ["The grow beds depend on that service feed. Restore the supply, then check the delivery path. You don't need to service every machine to do this watch."], [{"id":"back","label":"Back to the assignment"}])
		"command.assignment_reason":
			if result == "back": _story_assignment()
		"amara.introduction":
			if result == "inspect": _ship_story.record("amara.introduced"); set("_amara_intro_seen", true)
			elif result == "pump_question":
				_story_speak("amara.pump_question", "AMARA OKOYE / MED / HYDROPONICS", ["Let's check rather than guess. Compare pump capacity with reservoir chemistry and actual delivery; they're different measurements."], [{"id":"inspect","label":"I'll compare them"},{"id":"later","label":"A moment first"}])
		"amara.pump_question":
			if result == "inspect": _ship_story.record("amara.introduced"); set("_amara_intro_seen", true)
		"amara.observation_report":
			if result == "report": _ship_story.record("amara.observation_reported")
			elif result == "reason": _story_speak("amara.power_reason", "AMARA OKOYE / MED / HYDROPONICS", ["Without the feed, there's no useful delivery to verify. Once power is back we can see what the manifold is doing."], [{"id":"back","label":"Back to the report"}])
		"amara.power_reason":
			if result == "back": ship_story_amara_dialogue()
		"engineering.power_ack":
			if result == "ack" and _ship_state.bus_powered("science"): _ship_story.record("power.reported")
		"amara.repair_report":
			if result == "report" and _story_repairs_healthy(): _ship_story.record("amara.repair_reported")
		"amara.optional":
			if result == "optional": set("_crew_tasks_unlocked", true)
		"command.handoff":
			if result == "ack" and _story_repairs_healthy():
				ship_finish_story_cue(str(_ship_cue_active.get("cue_id","")), str(_ship_cue_active.get("request_token","")), "completed")
			else: ship_finish_story_cue(str(_ship_cue_active.get("cue_id","")), str(_ship_cue_active.get("request_token","")), "cancelled")
	_story_sync(); _story_checkpoint(); call("_update_player_walk_state")

func _story_equipment_action(prop_id: String, action_id: String) -> void:
	if prop_id in ["quarters.desk", "quarters.table"] and action_id == "crew_compare" and _ship_state.completed.has("crew"):
		_ship_story.record("roster.reviewed")
	if SHIP_CATALOG.definition(prop_id).get("room") == "hydro" and _ship_story.has("amara.introduced"):
		if action_id == "observe" and not _ship_story.has("hydro.observed"):
			_ship_story.evidence["hydro.before"] = _ship_state.readings("hydro")+"\nScience/service supply: "+("live" if _ship_state.bus_powered("science") else "unavailable")
			_ship_story.record("hydro.observed")
		if action_id == "diagnose" and _ship_story.has("hydro.observed"): _ship_story.record("hydro.diagnosed")
	if prop_id.begins_with("power.") and action_id == "observe" and not _ship_story.evidence.has("power.before"):
		_ship_story.evidence["power.before"] = _ship_state.readings("power")
	if action_id == "verify" and _ship_state.completed.has("power") and prop_id.begins_with("power.") and not _ship_story.has("power.reported") and _ship_story.has("amara.observation_reported"):
		_ship_story.evidence["power.after"] = _ship_state.readings("power")
		if is_instance_valid(_ship_panel) and _ship_panel.get("kind") == "power" and _ship_state.bus_powered("science"):
			# The redesigned panel carries Leila's acknowledgement on its own comms card.
			_ship_story.record("power.reported"); _ship_panel.show_comms()
		else:
			if is_instance_valid(_ship_panel): _ship_panel.close_panel()
			_story_power_ack()
	if action_id == "verify" and prop_id.begins_with("hydro.") and _ship_state.completed.has("hydro"):
		_ship_story.evidence["hydro.after"] = _ship_state.readings("hydro")
	_story_sync(); _story_checkpoint()

func _story_begin_cue(cue_id: String, delivery: String) -> Dictionary:
	if not ship_story_active() or not _ship_cue_active.is_empty(): return {}
	if cue_id == "cue.asteria.watch_handoff" and (not _ship_story.has("summary.submitted") or not _story_repairs_healthy()): return {}
	var context: Dictionary = _ship_story.request_cue(cue_id, delivery)
	if context.is_empty(): return {}
	_ship_cue_active = context.duplicate(true)
	_ship_cue_active.camera = _ship_player.camera
	_ship_cue_active.zoom = _ship_player.camera.zoom
	_ship_cue_active.smoothing = _ship_player.camera.position_smoothing_enabled
	_ship_cue_active.camera_state = {"position":_ship_player.camera.position,"offset":_ship_player.camera.offset,"limit_left":_ship_player.camera.limit_left,"limit_right":_ship_player.camera.limit_right,"limit_top":_ship_player.camera.limit_top,"limit_bottom":_ship_player.camera.limit_bottom}
	var npc := get_node_or_null("AmaraOkoye")
	if npc != null: npc.set_interaction_lock(&"story_cue", true)
	_story_checkpoint(); call("_update_player_walk_state")
	return context

func ship_finish_story_cue(cue_id: String, token: String, outcome: String, landing_id := "ship") -> bool:
	if not ship_story_active() or _ship_cue_active.get("cue_id") != cue_id or _ship_cue_active.get("request_token") != token: return false
	if landing_id != "ship" and outcome in ["completed", "skipped"]: outcome = "failed"
	if cue_id == "cue.asteria.watch_handoff" and outcome in ["completed", "skipped"] and (not _ship_story.has("summary.submitted") or not _story_repairs_healthy()): outcome = "failed"
	if not _ship_story.finish_cue(cue_id, token, outcome): return false
	if outcome in ["cancelled","failed"]:
		_ship_status="Communication interrupted. Watch progress is retained; use the station again when ready."; _ship_status_time=8.0
	if cue_id == "cue.asteria.watch_handoff" and outcome in ["completed", "skipped"]: _ship_story.record("watch.acknowledged")
	_story_release_locks()
	_story_sync(); _story_checkpoint(); call("_update_player_walk_state")
	if cue_id=="cue.thura.earth_years" and outcome in ["completed","skipped"] and not _ship_story.cues.has("cue.asteria.arrival"):
		_story_begin_cue("cue.asteria.arrival","arrival_briefing");call("_show_story_arrival_briefing")
	return true

func _story_release_locks() -> void:
	var camera: Camera2D = _ship_cue_active.get("camera")
	if is_instance_valid(camera) and camera.is_inside_tree():
		camera.zoom = _ship_cue_active.get("zoom", camera.zoom)
		camera.position_smoothing_enabled = _ship_cue_active.get("smoothing", camera.position_smoothing_enabled)
		for property in _ship_cue_active.get("camera_state",{}): camera.set(property,_ship_cue_active.camera_state[property])
		camera.make_current(); camera.reset_smoothing()
	_ship_cue_active = {}
	var dialogue := get_node_or_null("CrewDialogue")
	if is_instance_valid(get("_crew_dialogue")): dialogue = get("_crew_dialogue")
	if dialogue != null and dialogue.conversation_id == "command.handoff": dialogue.cancel_dialogue()
	if is_instance_valid(_ship_cue_asset): _ship_cue_asset.queue_free()
	_ship_cue_asset = null
	if is_instance_valid(_ship_cue_ui): _ship_cue_ui.queue_free()
	_ship_cue_ui = null
	var npc := get_node_or_null("AmaraOkoye")
	if npc != null: npc.set_interaction_lock(&"story_cue", false)

func ship_request_story_cue(cue_id: String, asset_path: String) -> bool:
	if _ship_hide_phase != "outside" or bool(get("_crew_dialogue_open")) or bool(get("_hud_modal_open")) or bool(get("_task_console_open")): return false
	var context := _story_begin_cue(cue_id, "teammate_asset")
	if context.is_empty(): return false
	if not ResourceLoader.exists(asset_path):
		ship_finish_story_cue(cue_id, context.request_token, "failed"); return false
	var resource = load(asset_path)
	if not resource is PackedScene:
		ship_finish_story_cue(cue_id, context.request_token, "failed"); return false
	var asset: Node = resource.instantiate()
	if not asset.has_method("play_cue") or not asset.has_signal("cue_finished"):
		asset.free(); ship_finish_story_cue(cue_id, context.request_token, "failed"); return false
	var actors := {"thura":_ship_player}
	var npc := get_node_or_null("AmaraOkoye")
	if npc != null: actors.amara=npc
	if asset.has_method("required_actor_ids"):
		var required: Variant=asset.call("required_actor_ids")
		if not required is Array and not required is PackedStringArray:
			asset.free(); ship_finish_story_cue(cue_id,context.request_token,"failed"); return false
		for actor_id in required:
			if not actors.has(actor_id) or not is_instance_valid(actors[actor_id]):
				asset.free(); ship_finish_story_cue(cue_id,context.request_token,"failed"); return false
	context.actors=actors; context.gameplay_camera=_ship_player.camera
	_ship_cue_asset = asset
	asset.connect("cue_finished", func(token: String, reported_id: String, outcome: String, landing: String): ship_finish_story_cue(reported_id,token,outcome,landing))
	asset.tree_exited.connect(func():
		if _ship_cue_active.get("request_token") == context.request_token: ship_finish_story_cue(cue_id, context.request_token, "failed"))
	if asset is Control:
		_ship_cue_ui=CanvasLayer.new();_ship_cue_ui.layer=30
		add_child(_ship_cue_ui);_ship_cue_ui.add_child(asset)
	else: add_child(asset)
	asset.call("play_cue", context)
	get_tree().create_timer(90.0).timeout.connect(func():
		if _ship_cue_active.get("request_token") == context.request_token: ship_finish_story_cue(cue_id, context.request_token, "failed"))
	return true

func _unhandled_key_input(event: InputEvent) -> void:
	if not ship_is_initialized() or not event is InputEventKey or not event.pressed or event.echo: return
	if event.is_action_pressed(&"hide"):
		if _ship_hide_phase=="concealed":
			ship_exit_hiding();get_viewport().set_input_as_handled()
		elif _ship_hide_phase=="outside" and not _ship_near_hide_id.is_empty() and not bool(get("_arrival_briefing_open")) and not bool(get("_hud_modal_open")) and not bool(get("_task_console_open")) and not bool(get("_crew_dialogue_open")) and not ship_control_locked():
			ship_enter_hiding(_ship_near_hide_id);get_viewport().set_input_as_handled()
	elif event.keycode == KEY_Q and _ship_hide_phase == "entering":
		ship_cancel_hiding(); get_viewport().set_input_as_handled()
	elif event.keycode==KEY_F6:
		_ship_status=ship_save_game();_ship_status_time=5.0;get_viewport().set_input_as_handled()
		if _ship_hide_phase=="concealed": _ship_hide_feedback="COVER SAVED / [H] EXIT" if _ship_status.begins_with("Ship-side") else "SAVE FAILED / KEEP COVER / [H] EXIT"
	elif event.keycode==KEY_F9:
		_ship_status=ship_load_game();_ship_status_time=5.0;get_viewport().set_input_as_handled()
		if _ship_hide_phase=="concealed": _ship_hide_feedback="LOAD REFUSED / STILL IN COVER / [H] RETRY EXIT"
