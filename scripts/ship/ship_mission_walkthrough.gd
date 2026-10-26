@tool
extends Node2D
## Base implementation for the existing walkthrough owner. This is not an
## autoload/second interaction manager: the existing scene root owns these methods.
const SHIP_CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
const SHIP_STATE := preload("res://scripts/ship/ship_mission_state.gd")
const SHIP_PANEL := preload("res://scripts/ui/ship_procedure_panel.gd")
@export var ship_mission_save_path := "user://ship_side_missions_v1.json"
@export_range(16.0,48.0,1.0) var ship_interaction_reach := 30.0
var _ship_state
var _ship_hud: WalkHud
var _ship_player: ShipPlayer
var _ship_floor: Sprite2D
var _ship_points := {}
var _ship_active_id := ""
var _ship_panel
var _ship_ready := false
var _ship_service_console
var _ship_service_prop := ""
var _ship_service_task := ""
var _ship_hide_id := ""
var _ship_hide_exit := Vector2.ZERO
var _ship_status := ""
var _ship_status_time := 0.0
var _ship_auto_timer := 0.0
var _ship_syncing := false
var _ship_initial_inventory := {}
var _ship_points_ready := false
var _ship_access_connected := {}
const SHIP_NAV_ORIGIN := Vector2(16,20)
const SHIP_NAV_STEP := 4.0

func _exit_tree() -> void:
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
	_ship_hud=hud;_ship_player=actor;_ship_floor=get_node("FloorLayer")
	_ship_state=SHIP_STATE.new();_ship_state.configure(hud)
	_ship_initial_inventory=hud.inventory_snapshot()
	_ship_state.changed.connect(_ship_state_changed)
	hud.inventory_changed.connect(_ship_inventory_changed)
	hud.mission_scenario_requested.connect(ship_start_development_scenario)
	_ship_ready=true
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
	return not _ship_hide_id.is_empty()

func ship_process(delta: float) -> void:
	if not ship_is_initialized(): return
	_ship_state.tick(delta)
	_ship_status_time=maxf(0.0,_ship_status_time-delta)
	_ship_auto_timer+=delta
	if _ship_auto_timer>=0.5:
		_ship_auto_timer=0.0
		_ship_publish_systems()

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
	for key in ["_active_room_task_id","_active_crew_task_id"]: set(key,&"")
	set("_active_amara_interaction",false);set("_active_airlock_exit",false)
	if get("_arrival_briefing_open") or get("_hud_modal_open") or get("_task_console_open") or get("_crew_dialogue_open"): return
	if ship_control_locked():
		_ship_hud.set_interaction_prompt("CONCEALED  /  [E] EXIT SAFELY",true);return
	var candidates: Array=[]
	for id in _ship_points:
		var entry: Dictionary=_ship_points[id]
		if not is_instance_valid(entry.marker): continue
		if ship_can_reach(entry.marker.global_position,entry.definition.room):
			candidates.append({"id":id,"distance":_ship_player.global_position.distance_to(entry.marker.global_position),"prompt":str(entry.host.name).to_snake_case().capitalize()+"   /   [E] ACCESS","kind":"prop"})
	var npc := get_node_or_null("AmaraOkoye") as Node2D
	if npc!=null and ship_can_reach(npc.global_position,"hydro",36.0): candidates.append({"id":"amara","distance":_ship_player.global_position.distance_to(npc.global_position)-4.0,"prompt":"AMARA OKOYE   /   [E] TALK","kind":"amara"})
	if bool(get("_crew_tasks_unlocked")):
		for task in get("AMARA_CREW_TASKS"):
			if get("_completed_crew_tasks").has(task.id): continue
			var host := get_node_or_null(task.station_path) as Node2D
			if host==null: continue
			var point: Vector2=call("_crew_task_interaction_position",task,host)
			if ship_can_reach(point,"hydro",36.0): candidates.append({"id":str(task.id),"distance":_ship_player.global_position.distance_to(point)-5.0,"prompt":task.prompt,"kind":"crew"})
	var airlock := get_node_or_null("ExteriorAirlockGate") as Node2D
	if airlock!=null and ship_can_reach(airlock.global_position+Vector2(0,28),"",36.0): candidates.append({"id":"airlock","distance":_ship_player.global_position.distance_to(airlock.global_position+Vector2(0,28)),"prompt":"EXTERIOR AIRLOCK   /   [E] EXIT TO PLANET","kind":"airlock"})
	if candidates.is_empty():
		_ship_hud.set_interaction_prompt(_ship_status if _ship_status_time>0 else "",_ship_status_time>0);return
	candidates.sort_custom(func(a: Dictionary,b: Dictionary): return a.distance<b.distance if not is_equal_approx(a.distance,b.distance) else a.id<b.id)
	var target: Dictionary=candidates[0]
	if target.kind=="prop": _ship_active_id=target.id
	elif target.kind=="amara": set("_active_amara_interaction",true)
	elif target.kind=="crew": set("_active_crew_task_id",StringName(target.id))
	elif target.kind=="airlock": set("_active_airlock_exit",true)
	_ship_hud.set_interaction_prompt(target.prompt,true)

func ship_handle_interact(event: InputEvent) -> bool:
	if not ship_is_initialized() or not event.is_action_pressed(&"interact"): return false
	if ship_control_locked():
		ship_exit_hiding();get_viewport().set_input_as_handled();return true
	if _ship_active_id.is_empty(): return false
	var entry: Dictionary=_ship_points[_ship_active_id]
	if not ship_can_reach(entry.marker.global_position,entry.definition.room): return false
	ship_open_procedure(_ship_active_id);get_viewport().set_input_as_handled();return true

func ship_open_procedure(id: String) -> bool:
	if not _ship_points.has(id) or get("_task_console_open") or ship_control_locked(): return false
	var point: Dictionary=_ship_points[id]
	if not is_instance_valid(point.marker) or not ship_can_reach(point.marker.global_position,point.definition.room): return false
	_ship_player.face_toward(point.host.global_position)
	_ship_panel=SHIP_PANEL.new();_ship_panel.setup(_ship_state,id,str(_ship_points[id].host.name).to_snake_case().capitalize())
	_ship_panel.action_requested.connect(_ship_action.bind(id))
	_ship_panel.closed.connect(_ship_panel_closed)
	_ship_panel.save_requested.connect(func(): _ship_panel.feedback(ship_save_game()))
	_ship_panel.load_requested.connect(func(): _ship_panel.feedback(ship_load_game()))
	set("_task_console_open",true);_ship_hud.set_walking_visible(false);call("_update_player_walk_state")
	add_child(_ship_panel)
	return true

func _ship_action(action_id: String, value: Variant, prop_id: String) -> void:
	var entry: Dictionary=_ship_points.get(prop_id,{})
	if entry.is_empty() or not is_instance_valid(entry.marker) or not ship_can_reach(entry.marker.global_position,entry.definition.room):
		_ship_panel.feedback("Move back to this station's clear access point before operating it.",false);return
	var result: Dictionary=_ship_state.act(prop_id,action_id,value)
	if result.get("event","")=="legacy":
		_ship_service_prop=prop_id;_ship_service_task=result.task
		_ship_panel.close_panel()
		call("_open_room_task_console",StringName(result.task));return
	if result.get("event","")=="hide":
		_ship_panel.close_panel();ship_enter_hiding(prop_id);return
	if is_instance_valid(_ship_panel): _ship_panel.feedback(result.message,result.ok)
	_ship_status=result.message;_ship_status_time=4.0

func _ship_panel_closed() -> void:
	_ship_panel=null;set("_task_console_open",false)
	_ship_hud.set_walking_visible(not bool(get("_arrival_briefing_open")))
	call("_update_player_walk_state")

func ship_attach_service_console(console: Node, task: StringName) -> void:
	_ship_service_console=console;_ship_service_task=str(task)
	console.set_resume_progress(_ship_state.legacy_progress.get(str(task),{}))

func ship_legacy_completed(task_id: StringName) -> void:
	if _ship_state.legacy_complete(str(task_id),_ship_service_prop):
		var existing: Dictionary=get("_completed_room_tasks");existing[task_id]=true
		_ship_status="Controls completed. Restore and verify the connected system at its station.";_ship_status_time=6.0

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
	var entries: Array=[]
	for objective in SHIP_CATALOG.OBJECTIVES:
		var station_id: String=SHIP_CATALOG.OBJECTIVE_STATIONS[objective[0]]
		var entry: Dictionary=_ship_points.get(station_id,{})
		var host := get_node_or_null(SHIP_CATALOG.definition(station_id).path) as Node2D
		var point: Vector2=entry.marker.global_position if is_instance_valid(entry.get("marker")) else host.global_position if host!=null else Vector2.ZERO
		entries.append({"id":StringName(objective[0]),"title":objective[3],"description":objective[1],"marker_label":objective[2],"position":point,"marker_position":point+Vector2(0,-16)})
	var completion: Dictionary=_ship_state.completed.duplicate()
	if bool(get("_crew_tasks_unlocked")):
		for task in get("AMARA_CREW_TASKS"):
			var host := get_node_or_null(task.station_path) as Node2D
			var point: Vector2=call("_crew_task_interaction_position",task,host) if host!=null else _ship_player.global_position
			entries.append({"id":task.id,"title":task.title,"description":"Optional / "+str(task.title),"marker_label":"OPTIONAL","position":point})
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

func ship_enter_hiding(id: String) -> bool:
	if ship_control_locked() or not _ship_points.has(id): return false
	var entry: Dictionary=_ship_points[id]
	if entry.definition.kind not in ["storage_hide","cargo_hide"] or not is_instance_valid(entry.marker): return false
	if not ship_can_reach(entry.marker.global_position,entry.definition.room): return false
	var hide_marker := entry.host.get_node_or_null("HidePoint") as Marker2D
	if hide_marker==null: return false
	var exclusions: Array[RID]=[]
	for body in entry.host.find_children("*","StaticBody2D",true,false): exclusions.append(body.get_rid())
	if not _ship_body_clear(hide_marker.global_position,exclusions) or not _ship_body_clear(entry.marker.global_position):
		_ship_status="The concealment/exit space is obstructed. Stay outside and use another hiding place.";_ship_status_time=5.0;return false
	_ship_hide_exit=entry.marker.global_position;_ship_hide_id=id
	_ship_player.get_node("CollisionShape2D").set_deferred("disabled",true)
	_ship_player.global_position=hide_marker.global_position
	_ship_player.set_concealment(true,id)
	call("_update_player_walk_state")
	return true

func _ship_safe_position(preferred: Vector2, room := "") -> Vector2:
	if _ship_body_clear(preferred): return preferred
	if room.is_empty(): room=SHIP_CATALOG.definition(_ship_hide_id).get("room","")
	for radius in range(8,97,8):
		for index in range(16):
			var point := preferred+Vector2.RIGHT.rotated(TAU*float(index)/16.0)*radius
			if _ship_body_clear(point) and _ship_in_area(point,room): return point
	return Vector2.INF

func ship_exit_hiding() -> bool:
	if not ship_control_locked(): return true
	var exit := _ship_safe_position(_ship_hide_exit)
	if exit==Vector2.INF:
		_ship_status="Exit temporarily obstructed. You remain concealed; press E to retry.";_ship_status_time=5.0;return false
	_ship_player.global_position=exit
	_ship_player.set_concealment(false,"")
	_ship_player.get_node("CollisionShape2D").set_deferred("disabled",false)
	_ship_hide_id=""
	call("_update_player_walk_state")
	_ship_status="Left concealment; movement and collision restored.";_ship_status_time=3.0
	return true

func ship_snapshot() -> Dictionary:
	if is_instance_valid(_ship_service_console): ship_service_capture()
	return {"format":"echoes_ship_side","version":1,"mission":_ship_state.snapshot(),"inventory":_ship_hud.inventory_snapshot(),"position":[_ship_player.global_position.x,_ship_player.global_position.y],"legacy_completed":get("_completed_room_tasks").duplicate(),"crew_completed":get("_completed_crew_tasks").duplicate(),"amara_intro":get("_amara_intro_seen"),"crew_unlocked":get("_crew_tasks_unlocked"),"concealed":_ship_hide_id,"hide_exit":[_ship_hide_exit.x,_ship_hide_exit.y]}

func ship_service_capture() -> void:
	if is_instance_valid(_ship_service_console): _ship_state.legacy_progress[_ship_service_task]=_ship_service_console.progress_snapshot()

func ship_restore(payload: Dictionary, restore_position := true) -> bool:
	if payload.get("format","")!="echoes_ship_side" or payload.get("version")!=1 or not payload.get("mission") is Dictionary or not payload.get("inventory") is Dictionary: return false
	if not _ship_hud.inventory_valid(payload.inventory): return false
	if not payload.get("position") is Array or payload.position.size()!=2: return false
	for coordinate in payload.position:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)): return false
	if not payload.get("hide_exit") is Array or payload.hide_exit.size()!=2: return false
	for coordinate in payload.hide_exit:
		if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)): return false
	for key in ["legacy_completed","crew_completed"]:
		if not payload.get(key) is Dictionary: return false
	var probe = SHIP_STATE.new()
	if not probe.restore(payload.mission): return false
	# Resolve an unoccupied position before mutating inventory/mission state.
	# A cabinet exit may have become obstructed since the save was written.
	var safe_load_position := _ship_player.global_position
	if restore_position:
		var desired := Vector2(float(payload.position[0]),float(payload.position[1]))
		var concealed_id := str(payload.get("concealed",""))
		if concealed_id.is_empty() and _ship_body_clear(desired): safe_load_position=desired
		else:
			var preferred := Vector2(float(payload.hide_exit[0]),float(payload.hide_exit[1]))
			safe_load_position=_ship_safe_position(preferred,SHIP_CATALOG.definition(concealed_id).get("room",""))
		if safe_load_position==Vector2.INF:
			var spawn := _ship_floor.to_global(Vector2(900,500))
			if _ship_body_clear(_ship_player.global_position): safe_load_position=_ship_player.global_position
			elif _ship_body_clear(spawn): safe_load_position=spawn
			else: return false
	_ship_syncing=true
	if ship_control_locked(): ship_exit_hiding()
	_ship_hud.inventory_restore(payload.inventory)
	_ship_state.restore(payload.mission)
	var legacy := {};var crew := {}
	for key in payload.legacy_completed: legacy[StringName(key)]=bool(payload.legacy_completed[key])
	for key in payload.crew_completed: crew[StringName(key)]=bool(payload.crew_completed[key])
	set("_completed_room_tasks",legacy);set("_completed_crew_tasks",crew)
	set("_amara_intro_seen",bool(payload.get("amara_intro",false)));set("_crew_tasks_unlocked",bool(payload.get("crew_unlocked",false)))
	if restore_position:
		_ship_player.global_position=safe_load_position
	# Resume outside concealment on load: never reload a player inside a solid
	# cabinet before its bodies/doors have entered the physics world.
	_ship_player.set_concealment(false,"");_ship_hide_id=""
	_ship_player.get_node("CollisionShape2D").set_deferred("disabled",false)
	_ship_syncing=false;_ship_sync_hud();_ship_publish_systems();call("_update_player_walk_state")
	return true

func _ship_save_path_allowed(path: String) -> bool:
	return not path.contains("..") and (path.begins_with("user://ship_side_missions") or path.begins_with("res://.godot/mission_validation/"))

func ship_save_game() -> String:
	if not _ship_save_path_allowed(ship_mission_save_path): return "Save refused: use the ship-side save namespace or isolated validation directory."
	var directory := ProjectSettings.globalize_path(ship_mission_save_path.get_base_dir())
	DirAccess.make_dir_recursive_absolute(directory)
	var temp := ship_mission_save_path+".tmp"
	var file := FileAccess.open(temp,FileAccess.WRITE)
	if file==null: return "Could not write ship-side save. Current progress is still in memory."
	file.store_string(JSON.stringify(ship_snapshot(),"\t"));file.close()
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(ship_mission_save_path))
	if result!=OK: return "Could not replace ship-side save; temporary copy retained."
	return "Ship-side mission, inventory, equipment and crew progress saved. Existing unrelated save files were not touched."

func ship_load_game() -> String:
	if is_instance_valid(_ship_service_console): return "Close the service controls before loading. Current procedure and supplies remain recorded."
	if not _ship_save_path_allowed(ship_mission_save_path) or not FileAccess.file_exists(ship_mission_save_path): return "No ship-side save exists for this scenario."
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ship_mission_save_path))
	if not parsed is Dictionary or not ship_restore(parsed): return "Save is invalid/incompatible. Current mission and inventory were not changed."
	return "Ship-side progress restored. Concealed saves resume at the validated exit with control restored."

func ship_start_development_scenario(context: String) -> void:
	if context not in ["outbound","return"] or not ship_is_initialized(): return
	if ship_control_locked(): ship_exit_hiding()
	_ship_syncing=true
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

func _unhandled_key_input(event: InputEvent) -> void:
	if not ship_is_initialized() or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_F6:
		_ship_status=ship_save_game();_ship_status_time=5.0;get_viewport().set_input_as_handled()
	elif event.keycode==KEY_F9:
		_ship_status=ship_load_game();_ship_status_time=5.0;get_viewport().set_input_as_handled()
