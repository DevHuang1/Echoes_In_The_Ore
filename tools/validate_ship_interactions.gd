extends Node
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
var level
var checks := 0
var failures: Array=[]
var report := {}
var _finished := false

func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok: failures.append(description);push_error(description)

func frames(count := 3) -> void:
	for i in range(count): await get_tree().process_frame

func _ready() -> void:
	get_tree().create_timer(180).timeout.connect(func():
		if not _finished: push_error("Interaction validation timeout");get_tree().quit(2))
	run.call_deferred()

func press_interact() -> void:
	var event := InputEventAction.new();event.action=&"interact";event.pressed=true
	Input.parse_input_event(event)
	await frames(2)
	event=InputEventAction.new();event.action=&"interact";event.pressed=false;Input.parse_input_event(event)

func press_hide() -> void:
	var event := InputEventKey.new();event.keycode=KEY_H;event.physical_keycode=KEY_H;event.pressed=true
	Input.parse_input_event(event);await frames(2)
	event=InputEventKey.new();event.keycode=KEY_H;event.physical_keycode=KEY_H;event.pressed=false
	Input.parse_input_event(event)

func test_approach_and_input() -> void:
	report.selection={}
	for id in level._ship_points:
		var entry: Dictionary=level._ship_points[id]
		if not is_instance_valid(entry.marker): check(false,"No marker: "+id);continue
		level.player.global_position=entry.marker.global_position
		level.ship_refresh_prompt()
		var selected: String=level._ship_active_id
		if entry.definition.kind in ["storage_hide","cargo_hide"]:
			check(level._ship_near_hide_id==id,"H selects reachable hiding place: "+id)
			check(selected!=id,"Hiding place is not an E station: "+id)
			check(not level.ship_open_procedure(id),"Hiding place has no task or storage panel: "+id)
			report.selection[id]=true
			continue
		check(selected==id,"A station is individually selectable from its marker: "+id+" (selected "+selected+")")
		if selected!=id: continue
		await press_interact()
		check(is_instance_valid(level._ship_panel) and level._task_console_open,"E opens one procedure: "+id)
		check(not level.player.is_physics_processing(),"Panel prevents walking: "+id)
		if is_instance_valid(level._ship_panel):
			check(level._ship_panel.prop_id==id,"Panel matches selected target: "+id)
			var escape := InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
			Input.parse_input_event(escape);await frames(2)
		check(not level._task_console_open and not is_instance_valid(level._ship_panel),"Escape cancels/resumes without stuck modal: "+id)
		check(level.player.is_physics_processing(),"Movement restored after cancellation: "+id)
		level.player.set_physics_process(false)
		var original: Transform2D=entry.host.transform
		var marker_before: Vector2=entry.marker.global_position
		entry.host.position+=Vector2(3,0)
		check(entry.marker.global_position.is_equal_approx(marker_before+Vector2(3,0)),"Moving prop carries interaction marker: "+id)
		entry.host.transform=original
		report.selection[id]=true

func test_routes() -> void:
	# Only the test instance's pressure doors are held open. No scene is saved.
	for door in get_tree().get_nodes_in_group("ship_door"):
		door.set_physics_process(false);door.set("_is_open",true);door.set("_target_open",true)
	var origin := Vector2(16,20)
	var width := 411;var height := 211;var step := 4.0
	var valid := PackedByteArray();valid.resize(width*height)
	for y in range(height):
		for x in range(width):
			if level._ship_body_clear(level._ship_floor.to_global(origin+Vector2(x,y)*step)): valid[y*width+x]=1
	var start := Vector2i(221,120) # floor position (900,500), current spawn aisle
	check(valid[start.y*width+start.x]==1,"Route search starts on walkable unoccupied floor")
	var queue: Array[Vector2i]=[start];var seen := {start:start};var head := 0
	while head<queue.size():
		var current := queue[head];head+=1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i=current+delta
			if next.x<0 or next.y<0 or next.x>=width or next.y>=height or seen.has(next): continue
			if valid[next.y*width+next.x]==1: seen[next]=current;queue.append(next)
	report.routes={}
	for id in level._ship_points:
		var entry: Dictionary=level._ship_points[id]
		if not is_instance_valid(entry.marker): continue
		var target: Vector2=level._ship_floor.to_local(entry.marker.global_position)
		var nearest := Vector2i((target-origin)/step)
		var found := Vector2i(-1,-1);var distance := INF
		for y in range(nearest.y-2,nearest.y+3):
			for x in range(nearest.x-2,nearest.x+3):
				var candidate := Vector2i(x,y)
				if seen.has(candidate):
					var candidate_distance := (origin+Vector2(candidate)*step).distance_to(target)
					if candidate_distance<distance: found=candidate;distance=candidate_distance
		check(found.x>=0 and distance<=9,"Continuous walking route to station: "+id)
		if found.x<0 or distance>9: report.routes[id]=false;continue
		var path: Array[Vector2i]=[found]
		while path[-1]!=start: path.append(seen[path[-1]])
		path.reverse()
		level.player.global_position=level._ship_floor.to_global(origin+Vector2(start)*step)
		for point in path:
			var desired: Vector2=level._ship_floor.to_global(origin+Vector2(point)*step)
			level.player._move_on_walkable_floor(desired-level.player.global_position)
		var final: Vector2=level._ship_floor.to_global(origin+Vector2(found)*step)
		check(level.player.global_position.distance_to(final)<0.75,"Real player traverses route: "+id)
		report.routes[id]=level.player.global_position.distance_to(final)<0.75
	report.connected_cells=seen.size()

func test_separation() -> void:
	var closed_tests := 0
	for door in get_tree().get_nodes_in_group("ship_door"):
		var offset: float=door.wall_depth*0.5+10.0
		var front: Vector2=door.to_global(Vector2(0,offset))
		var back: Vector2=door.to_global(Vector2(0,-offset))
		door.set("_is_open",true)
		level.player.global_position=front
		if level.ship_can_reach(back,"",100):
			door.set("_is_open",false)
			check(not level.ship_can_reach(back,"",100),"Closed pressure door prevents interaction: "+str(door.name));closed_tests+=1
		door.set("_is_open",true)
	check(closed_tests>0,"At least one open/closed doorway tested on actual valid floor")
	var power: Dictionary=level._ship_points["power.cell"]
	var life: Dictionary=level._ship_points["life.filter"]
	level.player.global_position=power.marker.global_position
	check(not level.ship_can_reach(life.marker.global_position,"life",1000),"Cannot operate across room boundaries even with large requested reach")
	check(not level.ship_open_procedure("life.filter"),"Cannot open remote station through a wall")

func test_prop_solidity() -> void:
	for id in level._ship_points:
		var entry: Dictionary=level._ship_points[id]
		var bounds: Rect2=level._ship_footprint(entry.host)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape=level.player.get_node("CollisionShape2D").shape
		query.transform=Transform2D(0,bounds.get_center());query.collision_mask=1
		query.exclude=[level.player.get_rid()]
		var hit_own_body := false
		for hit in level.get_world_2d().direct_space_state.intersect_shape(query):
			if hit.collider==entry.host or entry.host.is_ancestor_of(hit.collider): hit_own_body=true
		check(hit_own_body,"Prop retains a solid floor footprint: "+id)
		level.player.global_position=entry.marker.global_position
		for step in range(80):
			var movement: Vector2=level.player.global_position.direction_to(bounds.get_center())*1.0
			level.player._move_on_walkable_floor(movement)
		check(level.player.global_position.distance_to(bounds.get_center())>2.0,"Actual movement cannot enter prop footprint: "+id)

func test_objective_markers() -> void:
	var hud: WalkHud=level._walk_hud
	var active: Array=[]
	for entry in hud._task_entries:
		active.append(entry.id)
		if not CATALOG.OBJECTIVE_STATIONS.has(str(entry.id)): continue
		var target: Dictionary=level._ship_points[CATALOG.OBJECTIVE_STATIONS[str(entry.id)]]
		check(entry.position.is_equal_approx(target.marker.global_position),"Objective data points to actual station access: "+str(entry.id))
		check(hud._world_task_markers.has(entry.id),"Existing world-marker workflow covers objective: "+str(entry.id))
	for id in hud._world_task_markers:
		if id not in active: check(not hud._world_task_markers[id].visible,"Retired service marker cannot linger at HUD origin: "+str(id))

func test_hiding() -> void:
	report.hiding={}
	var occupied: Dictionary=level._ship_points["cargo.locker"]
	level.player.global_position=occupied.marker.global_position
	occupied.host.set_meta("hide_occupant",-1234)
	check(not level.ship_enter_hiding("cargo.locker"),"Another occupant prevents entering the same hiding prop")
	occupied.host.remove_meta("hide_occupant")
	for id in ["cargo.locker","cargo.bundle","engine.locker.1","engine.locker.2"]:
		var entry: Dictionary=level._ship_points[id]
		level.player.global_position=entry.marker.global_position
		level.ship_refresh_prompt()
		var carried := JSON.stringify(level._walk_hud.inventory_snapshot())
		var visual_states := {}
		for item in level.player.find_children("*","CanvasItem",true,false):
			if not item is Camera2D: visual_states[item]=item.visible
		await press_hide()
		await wait_hiding("concealed")
		check(level._ship_hide_id==id,"H enters selected hiding place: "+id)
		check(level.player.is_concealed and level.player.is_in_group("concealed_players"),"Concealment API/group exposed: "+id)
		check(not level.player.sprite.visible and level.player.get_node("CollisionShape2D").disabled,"Hidden sprite and cabinet-overlap collision handled: "+id)
		var all_hidden := true
		for item in visual_states:
			if is_instance_valid(item) and item.visible: all_hidden=false
		check(all_hidden,"Attached equipment, shadow and lights are all hidden: "+id)
		var held := InputEventKey.new();held.keycode=KEY_H;held.physical_keycode=KEY_H;held.pressed=true;held.echo=true
		Input.parse_input_event(held);await frames(2)
		check(level._ship_hide_phase=="concealed","Held H echo cannot immediately exit cover: "+id)
		var hidden_position: Vector2=level.player.global_position
		level.player._physics_process(0.1)
		check(level.player.global_position==hidden_position,"Hidden player cannot walk out through solid cabinet")
		var hidden_save: Dictionary=level.ship_snapshot()
		await press_interact();await frames(2)
		check(level._ship_hide_phase=="concealed","E cannot leave cover: "+id)
		await press_hide();await wait_hiding("outside")
		check(not level.player.is_concealed and level.player.sprite.visible and not level.player.get_node("CollisionShape2D").disabled,"H restores visibility and collision: "+id)
		check(level.player.is_physics_processing() and level._ship_body_clear(level.player.global_position),"Hiding exit restores control on clear floor: "+id)
		var visuals_restored := true
		for item in visual_states:
			if is_instance_valid(item) and item.visible!=visual_states[item]: visuals_restored=false
		check(visuals_restored,"Exit restores each attached visual's previous state: "+id)
		check(level.ship_restore(hidden_save),"Concealed snapshot can load safely")
		await frames()
		check(not level.player.is_concealed and level._ship_body_clear(level.player.global_position),"Concealed load resumes outside cabinet at safe exit")
		check(carried==JSON.stringify(level._walk_hud.inventory_snapshot()),"Concealment never loses inventory")
		level.player.set_physics_process(false)
		report.hiding[id]=true
	level.player.sprite.visible=false
	level.player.set_concealment(true,"validation.visual_state")
	level.player.set_concealment(false,"")
	check(not level.player.sprite.visible,"Concealment API preserves an intentionally hidden sprite on ordinary exit")
	level.player.sprite.visible=true
	# An obstructed exit must keep the actor concealed and allow a later retry.
	var entry: Dictionary=level._ship_points["cargo.locker"]
	level.player.global_position=entry.marker.global_position
	check(level.ship_enter_hiding("cargo.locker"),"Enter concealment for blocked-exit retry")
	await wait_hiding("concealed")
	var obstacle := StaticBody2D.new();obstacle.collision_layer=1
	var blocker := CollisionShape2D.new();var circle := CircleShape2D.new();circle.radius=140
	blocker.shape=circle;obstacle.add_child(blocker);level.add_child(obstacle)
	obstacle.global_position=level._ship_hide_exit;await frames(3)
	check(not level.ship_exit_hiding() and level.player.is_concealed,"Fully blocked exit keeps concealment and permits retry")
	var blocked_exit_save: Dictionary=level.ship_snapshot()
	check(not level.ship_restore(blocked_exit_save),"Concealed save refuses a fully blocked connected exit before mutation")
	await frames()
	check(level.player.is_concealed and not level.player.is_physics_processing(),"Rejected blocked load remains safely concealed for retry")
	obstacle.queue_free();await frames(3)
	check(level.ship_exit_hiding(),"Removing temporary exit obstruction permits connected safe retry")
	await wait_hiding("outside")
	check(not level.player.is_concealed and level.player.is_physics_processing(),"Retry restores player control")
	level.player.set_physics_process(false)

func wait_hiding(phase: String) -> void:
	var waited := 0.0
	while level._ship_hide_phase!=phase and waited<8.0:
		await get_tree().create_timer(0.02).timeout;waited+=0.02
	await frames(3)
	check(level._ship_hide_phase==phase,"Asynchronous hiding transition reaches "+phase)

func test_inventory_and_save() -> void:
	var hud: WalkHud=level._walk_hud
	var before: Dictionary=hud.inventory_snapshot()
	for i in range(36): hud.inventory_put(&"filter_cartridge")
	var stock_before: int=level._ship_state.stocks["quarters.drawer.2"].coolant_charge
	var response: Dictionary=level._ship_state.act("quarters.drawer.2","take:coolant_charge")
	check(not response.ok and level._ship_state.stocks["quarters.drawer.2"].coolant_charge==stock_before,"Full inventory transfer is atomic; spare stays in storage")
	hud.inventory_restore(before)
	var inventory_before_load := JSON.stringify(hud.inventory_snapshot())
	var snapshot: Dictionary=JSON.parse_string(JSON.stringify(level.ship_snapshot()))
	var malformed: Dictionary=snapshot.duplicate(true)
	malformed.mission.systems.engine.temperature="broken"
	check(not level.ship_restore(malformed),"Corrupt equipment value rejected before mutation")
	check(inventory_before_load==JSON.stringify(hud.inventory_snapshot()),"Rejected load preserves inventory")
	malformed=snapshot.duplicate(true);malformed.inventory.storage[0]={"not":"an item"}
	check(not level.ship_restore(malformed),"Malformed inventory item rejected")
	level.ship_mission_save_path="user://unrelated_existing_save.json"
	check(level.ship_save_game().begins_with("Save refused"),"Tests/code cannot overwrite unrelated user saves")
	level.ship_mission_save_path="res://.godot/mission_validation/physical.json"
	check(level.ship_save_game().begins_with("Ship-side mission"),"Isolated save written")
	check(level.ship_load_game().begins_with("Ship-side progress"),"Isolated save reloads")

func test_amara() -> void:
	level._begin_amara_dialogue();await frames()
	check(level._crew_dialogue_open and not level.player.is_physics_processing(),"Existing Amara dialogue still opens and stops movement")
	check(level._crew_dialogue._lines.any(func(line: String): return line.contains("reservoir") or line.contains("pump")),"Dialogue includes relevant system observation")
	level._crew_dialogue._finish_legacy(true);await frames()
	check(level._crew_tasks_unlocked and not level._crew_dialogue_open,"Existing Amara task acceptance still works")
	for task in level.AMARA_CREW_TASKS:
		var host: Node2D=level.get_node(task.station_path)
		var point: Vector2=level._crew_task_interaction_position(task,host)
		level.player.global_position=point
		level.ship_refresh_prompt()
		check(level._active_crew_task_id==task.id,"Amara job selects at reachable station: "+str(task.id))
		await press_interact()
		check(level._completed_crew_tasks.has(task.id),"E performs original Amara job: "+str(task.id))
	check(level._completed_crew_tasks.size()==2,"Existing Amara jobs still complete independently")
	level.player.set_physics_process(false)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/mission_validation")
	level=LEVEL.instantiate();level.ship_story_enabled=false;level.ship_mission_save_path="res://.godot/mission_validation/physical.json"
	add_child(level);await frames(12)
	while not level._ship_points_ready: await get_tree().process_frame
	level._on_arrival_briefing_dismissed()
	for child in level.get_children():
		if child is CanvasLayer and child!=level._walk_hud: child.hide()
	level.player.set_physics_process(false)
	level.amara.set_physics_process(false)
	test_objective_markers()
	await test_approach_and_input()
	test_routes()
	test_separation()
	test_prop_solidity()
	await test_hiding()
	test_inventory_and_save()
	await test_amara()
	report.checks=checks;report.failures=failures
	var file := FileAccess.open("res://.godot/mission_validation/interaction_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	_finished=true
	print("SHIP INTERACTIONS: ",checks," checks / ",failures.size()," failures")
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures.is_empty() else 1)
