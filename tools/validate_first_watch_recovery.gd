extends "res://tools/validate_first_watch.gd"
## Explicit fixtures for recovery/failure contracts, separate from chapter input proof.
const CUE_FIXTURE := "res://tools/first_watch_cue_fixture.tscn"
const HIDE_IDS := ["cargo.locker","engine.locker.1","engine.locker.2","cargo.bundle"]

func serialized_equal(a: Variant,b: Variant) -> bool:
	# JSON changes numeric variants and StringName values. Compare the same wire
	# representation on both sides rather than asserting runtime type identity.
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))

func camera_state(camera: Camera2D) -> Dictionary:
	return {"zoom":camera.zoom,"offset":camera.offset,"position":camera.position,"smoothing":camera.position_smoothing_enabled,"limits":[camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom]}

func boot_fixture(checkpoint := "") -> void:
	Engine.set_meta("ship_story_validation_path",ROOT+"recovery.json")
	level=LEVEL.instantiate(); level.ship_story_autosave=false
	get_tree().root.add_child(level); get_tree().current_scene=level
	while not level._ship_points_ready: await frames(1)
	await key(KEY_ENTER); await get_tree().create_timer(0.35).timeout
	if not checkpoint.is_empty(): check(level.ship_restore(SAVE.read(ROOT+checkpoint+".json")),"Fixture restores earned input-run checkpoint: "+checkpoint)
	await frames(3)

func wait_hide(phase: String, deadline := 8.0) -> bool:
	var waited := 0.0
	while level._ship_hide_phase!=phase and waited<deadline:
		await get_tree().create_timer(0.02).timeout; waited+=0.02
	await frames(2)
	return check(level._ship_hide_phase==phase,"Transition reaches "+phase)

func obstacle(point: Vector2, size: Vector2, layer := 1) -> StaticBody2D:
	var body := StaticBody2D.new();body.collision_layer=layer;body.collision_mask=0
	var shape := CollisionShape2D.new();var rectangle := RectangleShape2D.new();rectangle.size=size
	shape.shape=rectangle;body.add_child(shape);level.add_child(body);body.global_position=point
	return body

func character_obstacle(point: Vector2) -> CharacterBody2D:
	var actor := CharacterBody2D.new();actor.collision_layer=4;actor.collision_mask=1
	var shape := CollisionShape2D.new();var circle := CircleShape2D.new();circle.radius=7
	shape.shape=circle;actor.add_child(shape);level.add_child(actor);actor.global_position=point
	return actor

func settle() -> void:
	await get_tree().physics_frame;await get_tree().physics_frame;await frames(2)

func place_at_access(id: String, farther := false) -> Vector2:
	var entry: Dictionary=level._ship_points[id]
	var point: Vector2=entry.marker.global_position
	var alternative: Vector2=point+(Vector2.LEFT*18 if entry.definition.kind=="storage_hide" else Vector2.DOWN*12)
	if farther and level._ship_hide_point_clear(alternative): point=alternative
	level.player.global_position=point
	level.player.camera.reset_smoothing();level.player.camera.force_update_scroll()
	return point

func assert_outside(id: String) -> void:
	check(level._ship_hide_phase=="outside" and not level.player.is_concealed and level.player.sprite.visible and not level.player.get_node("CollisionShape2D").disabled,"Outside visibility/collision restored: "+id)
	check(level.player.is_physics_processing() and not level.ship_control_locked() and level._ship_hide_point_clear(level.player.global_position),"Outside controls and body clearance restored: "+id)
	check(not level._ship_points[id].host.has_meta("hide_occupant"),"Reservation released: "+id)

func hiding_instance(id: String) -> void:
	var entry: Dictionary=level._ship_points[id];var host: Node2D=entry.host
	var locker: bool=entry.definition.kind=="storage_hide"
	var saved_transform: Transform2D=host.transform;var saved_scale: float=host.artwork_scale
	var saved_appearance: int=host.appearance;var saved_direction: int=host.direction
	var inventory: String=JSON.stringify(level._walk_hud.inventory_snapshot())
	var from := place_at_access(id,true);await settle()
	var inside: Vector2=host.get_node("HidePoint").global_position
	var route: PackedVector2Array=level._ship_hide_entry_route(id,from)
	check(not route.is_empty(),"Connected full-size entry route: "+id)
	if route.is_empty(): return
	if locker:
		check(host.direction==3 and host.appearance==0,"Actual WEST closed artwork: "+id)
		check(level._ship_hide_entry_route(id,host.global_position+Vector2(30,0)).is_empty(),"EAST side cannot enter WEST door: "+id)
		host.appearance=2
		check(not level.ship_enter_hiding(id),"Damaged/open combination is unavailable: "+id)
		host.appearance=saved_appearance
	else:
		check(not level._ship_hide_segment_clear(from,inside),"Direct gap crosses own crates and is rejected: "+id)
		check(route.size()>3 and level._ship_hide_route_clear(route),"Walk-around route respects all own crate bodies: "+id)
	var wall := obstacle(host.global_position+Vector2(-12,0) if locker else Vector2(from.x,(from.y+inside.y)*0.5),Vector2(1,42) if locker else Vector2(360,1))
	await settle()
	check(not level.ship_enter_hiding(id),"Thin external entry wall prevents concealment: "+id)
	check(not host.has_meta("hide_occupant"),"Refused wall entry reserves nothing: "+id)
	wall.queue_free();await settle()
	host.set_meta("hide_occupant",-1)
	check(not level.ship_enter_hiding(id),"Occupied reservation is refused: "+id)
	host.remove_meta("hide_occupant")
	var actor := character_obstacle(inside);await settle()
	check(not level.ship_enter_hiding(id),"Character occupancy at target is refused: "+id)
	actor.queue_free();await settle()
	Engine.time_scale=0.15
	level.ship_refresh_prompt();await interact();await frames(4)
	check(is_instance_valid(level._ship_panel),"Actual E opens hiding host: "+id)
	await operate("hide")
	check(level._ship_hide_phase=="entering","Actual Hide button starts explicit entering phase: "+id)
	check(host.get_meta("hide_occupant",0)==level.player.get_instance_id(),"Occupancy reserved before crossing: "+id)
	check(not level.ship_enter_hiding(id),"Repeated entry cannot reserve twice: "+id)
	if locker:
		check(host.appearance==1,"Supplied WEST open sprite during entry: "+id)
		await capture(id.replace(".","_")+"_door_open",true)
	Engine.time_scale=1.0
	await wait_hide("concealed")
	check(level.player.is_concealed and not level.player.sprite.visible and level.player.get_node("CollisionShape2D").disabled,"Concealed API, visibility and overlap policy: "+id)
	if locker: check(host.appearance==0,"Door closes after entry: "+id)
	else:
		# Temporary reveal is a cover probe, not a replacement concealment pose.
		level.player.sprite.visible=true;await capture("cargo_bundle_cover_probe",true);level.player.sprite.visible=false
	await capture(id.replace(".","_")+"_concealed",true)
	var hidden_position: Vector2=level.player.global_position
	movement(Vector2.RIGHT);await settle();movement(Vector2.ZERO)
	check(level.player.global_position==hidden_position and not level.ship_open_procedure("bridge.planning"),"Concealment blocks ordinary movement and remote equipment: "+id)
	await key(KEY_I)
	check(level._hud_modal_open and not level.player.is_physics_processing(),"Inventory opens without releasing hiding lock: "+id)
	await interact()
	check(level.player.is_concealed,"Modal E cannot start an exit: "+id)
	await key(KEY_ESCAPE)
	check(not level._hud_modal_open and not level.player.is_physics_processing(),"Closing inventory preserves concealment lock: "+id)
	var hidden_save: Dictionary=level.ship_snapshot()
	wall=obstacle(host.global_position+Vector2(-12,0) if locker else Vector2(from.x,(from.y+inside.y)*0.5),Vector2(1,42) if locker else Vector2(360,1));await settle()
	check(not level.ship_exit_hiding() and level.player.global_position==hidden_position,"Thin external exit wall cannot be crossed to a clear endpoint: "+id)
	wall.queue_free();await settle()
	# Block only the preferred endpoint. Another connected access-side exit fits.
	var partial := obstacle(from,Vector2(2,2));await settle()
	check(level.ship_exit_hiding(),"Partially obstructed preferred exit has connected fallback: "+id)
	await wait_hide("outside");assert_outside(id)
	partial.queue_free();await settle()
	check(level.ship_restore(hidden_save),"Hidden snapshot resumes safely outside: "+id)
	await settle();assert_outside(id)
	place_at_access(id,true);await settle();check(level.ship_enter_hiding(id),"Repeat entry after load: "+id);await wait_hide("concealed")
	check(level.ship_exit_hiding(),"Begin exit for dynamic obstruction: "+id)
	wall=obstacle(host.global_position+Vector2(-12,0) if locker else Vector2(from.x,(from.y+inside.y)*0.5),Vector2(1,42) if locker else Vector2(360,1))
	await get_tree().create_timer(1.5).timeout
	check(level._ship_hide_phase in ["outside","concealed"],"Interrupted exit stops on clear outside floor or inside cover: "+id)
	if level._ship_hide_phase=="outside": assert_outside(id)
	wall.queue_free();await settle()
	if level._ship_hide_phase=="outside":
		place_at_access(id,true);await settle();check(level.ship_enter_hiding(id),"Reenter after interrupted outside exit: "+id);await wait_hide("concealed")
	var full := obstacle(host.global_position,Vector2(300,300));await settle()
	check(not level.ship_exit_hiding() and level.player.is_concealed,"Fully blocked exit remains concealed: "+id)
	level.ship_refresh_prompt()
	check("BLOCKED" in level._walk_hud._context_label.text and "RETRY" in level._walk_hud._context_label.text,"Blocked exit gives visible retry feedback: "+id)
	await capture(id.replace(".","_")+"_blocked_exit",true)
	var blocked_snapshot: Dictionary=level.ship_snapshot()
	var before_inventory: String=JSON.stringify(level._walk_hud.inventory_snapshot())
	check(not level.ship_restore(blocked_snapshot),"Fully obstructed hidden load is rejected before mutation: "+id)
	check(level.player.is_concealed and JSON.stringify(level._walk_hud.inventory_snapshot())==before_inventory,"Rejected load preserves current state: "+id)
	await key(KEY_F6)
	check("SAVED" in level._ship_hide_feedback,"Actual F6 saves the hidden checkpoint without unlocking: "+id)
	await key(KEY_F9)
	check(level.player.is_concealed and "REFUSED" in level._ship_hide_feedback,"Actual F9 refuses obstructed load with visible recovery feedback: "+id)
	full.queue_free();await settle();check(level.ship_exit_hiding(),"Cleared obstruction permits retry: "+id);await wait_hide("outside");assert_outside(id)
	place_at_access(id,true);await settle();check(level.ship_enter_hiding(id),"Cancellation entry: "+id)
	await get_tree().create_timer(0.08).timeout
	await key(KEY_Q)
	check(level._ship_hide_phase in ["exiting","outside"],"Actual Q cancels entering along traversed route: "+id)
	await wait_hide("outside");assert_outside(id)
	# New obstruction appears after reservation but before the next route segment.
	place_at_access(id,true);await settle();check(level.ship_enter_hiding(id),"Dynamic obstruction entry: "+id)
	wall=obstacle(host.global_position+Vector2(-12,0) if locker else Vector2(from.x,(from.y+inside.y)*0.5),Vector2(1,42) if locker else Vector2(360,1))
	await get_tree().create_timer(1.5).timeout
	check(level._ship_hide_phase in ["outside","concealed"],"Interrupted transition reaches safe stopped state: "+id)
	wall.queue_free();await settle()
	if level._ship_hide_phase=="concealed": check(level.ship_exit_hiding(),"Interrupted interior can retry: "+id);await wait_hide("outside")
	assert_outside(id)
	if locker:
		host.appearance=1;place_at_access(id,true);await settle()
		check(level.ship_enter_hiding(id) and level.ship_cancel_hiding(),"Already-open cabinet supports cancellation: "+id)
		await wait_hide("outside");check(host.appearance==1,"Cancellation restores prior open appearance: "+id)
		host.appearance=saved_appearance
	check(host.transform==saved_transform and host.artwork_scale==saved_scale and host.direction==saved_direction and host.appearance==saved_appearance,"Transforms, artwork scale/direction and prior appearance retained: "+id)
	check(JSON.stringify(level._walk_hud.inventory_snapshot())==inventory,"All hide paths preserve inventory: "+id)
	observations[id]={"checks_finished":true,"route":str(route),"position":str(host.global_position)};flush()

func hiding() -> void:
	await boot_fixture()
	check(level._walk_hud._mission_panel.size.y<=300,"One-objective tracker fits a compact panel after startup layout")
	for id in HIDE_IDS: await hiding_instance(id)

func restart(checkpoint: String, expected: int) -> void:
	var data: Dictionary=SAVE.read(ROOT+checkpoint+".json")
	if not check(not data.is_empty(),"Earned chapter checkpoint exists for restart"): return
	var path := ROOT+"restart_"+checkpoint+".json"
	check(SAVE.atomic_write(path,data)==OK,"Copy isolated checkpoint for process restart")
	Engine.set_meta("ship_story_validation_path",path)
	var landing: Node=load("res://scenes/ui/landing_screen.tscn").instantiate()
	get_tree().root.add_child(landing);get_tree().current_scene=landing;await frames(5)
	if not check(is_instance_valid(landing._continue_button),"Fresh landing detects valid Continue"): return
	await click(landing._continue_button);await wait_ship()
	check(level._ship_story.completed_count()==expected,"Continue restores exact chapter stage")
	check(level._ship_story.receipts==data.story.receipts,"Continue preserves all conversation/report receipts")
	check(serialized_equal(level._walk_hud.inventory_snapshot(),data.inventory),"Continue preserves inventory/equipment")
	check(not level._arrival_briefing_open and not level.ship_control_locked() and level.player.is_physics_processing(),"Continue resumes safely without replaying intro or arrival")
	check(level.player.global_position.distance_to(Vector2(data.position[0],data.position[1]))<0.1,"Continue restores validated saved player position")
	await capture("continue_"+checkpoint,true)

func contracts() -> void:
	await boot_fixture()
	check(level.ship_request_story_cue("cue.thura.earth_years","res://scenes/ui/earth_years_montage.tscn"),"Existing montage supports embedded owner adapter")
	var embedded: Node=level._ship_cue_asset
	while embedded._transitioning: await frames(1)
	await click(embedded._skip_button)
	var skip_wait := 0.0
	while not level._ship_cue_active.is_empty() and skip_wait<3.0:
		await get_tree().create_timer(0.02).timeout;skip_wait+=0.02
	await frames(3)
	check(level._ship_story.cues["cue.thura.earth_years"].status=="skipped" and get_tree().current_scene==level and not level.ship_control_locked(),"Actual montage skip signal restores owner without scene replacement")
	place_at_access("power.breaker");await settle();check(level.ship_open_procedure("power.breaker"),"Observation before watch acceptance is accessible")
	await frames(4);await operate("observe")
	check(level._ship_state.flags.get("power.observed",false) and not level._ship_story.has("watch.accepted") and level._ship_state.completed.is_empty(),"Useful early observation neither accepts work nor repairs equipment")
	await key(KEY_ESCAPE)
	check(level.ship_restore(SAVE.read(ROOT+"mid_roster.json")),"Restore earned roster checkpoint")
	await frames(4)
	# A legitimate clear spot outside hydroponics. Only this failure fixture
	# relocates actors; the chapter proof leaves her normal patrol untouched.
	var npc_point: Vector2=level._ship_points["bridge.planning"].marker.global_position+Vector2(70,0)
	check(level._ship_hide_point_clear(npc_point) and level._ship_hide_point_clear(npc_point+Vector2(20,0)),"Outside-hydro conversation fixture fits unchanged floor")
	level.amara.global_position=npc_point;level.player.global_position=npc_point+Vector2(20,0);await settle()
	level.ship_refresh_prompt();check(level._active_amara_interaction,"Actual Amara prompt works outside hydroponics")
	await interact();check(level._crew_dialogue_open and level.amara.is_physics_processing(),"Outside conversation locks normal NPC physics behavior")
	var npc_before: Vector2=level.amara.global_position
	var old_generation: int=level._crew_dialogue._generation
	await get_tree().create_timer(0.3).timeout
	check(level.amara.global_position==npc_before,"Outside speaker remains stationary")
	# The redesigned conversation screen covers the walk HUD, so its inventory
	# shortcut stays inactive until the conversation ends.
	await key(KEY_I)
	check(not level._hud_modal_open and level._crew_dialogue_open,"Walk HUD shortcuts stay inactive during the conversation screen")
	await key(KEY_ESCAPE)
	check(not level._crew_dialogue_open and level.amara._interaction_locks.is_empty() and level.player.is_physics_processing(),"Cancellation restores aggregate input and previous NPC behavior")
	check(level._ship_hud._walking_visible,"Cancelling restores the walk HUD")
	level.ship_refresh_prompt();await interact()
	check(level._crew_dialogue._generation!=old_generation and level._crew_dialogue.phase=="typing","Reoffered conversation starts fresh")
	check(level._crew_dialogue_open and not level._ship_story.has("amara.introduced"),"A response from the cancelled conversation cannot accept its replacement")
	await dialogue("inspect")
	check(level._ship_story.has("amara.introduced"),"Cancelled introduction can be reoffered and accepted")
	var complete: Dictionary=SAVE.read(ROOT+"completed.json")
	if not check(not complete.is_empty(),"Earned completed chapter available for contract fixtures"): return
	check(level.ship_restore(complete),"Restore earned chapter for regression observations")
	var history: Dictionary=level._ship_state.completed.duplicate(true)
	level._ship_state.systems.hydro.isolated=true;level._ship_state.tick(0.5)
	level.ship_story_amara_dialogue()
	check("Delivery still needs attention" in str(level._crew_dialogue._lines),"Amara reports current regressed delivery honestly")
	check(level._ship_state.completed==history and level._ship_story.completed_count()==5,"Regressed readings preserve earned repair/chapter history")
	await dialogue("optional")
	for pair in [["hydro.pump","optional:amara_nutrient_pump"],["hydro.seedlings","optional:amara_seedling_sensor"]]:
		place_at_access(pair[0]);await settle()
		check(level.ship_open_procedure(pair[0]),"Open optional observation fixture at its real host")
		await frames(4)
		await operate(pair[1]);await key(KEY_ESCAPE)
	check(level._completed_crew_tasks.size()==2 and level._ship_story.completed_count()==5,"Optional checks never increase required mission count")
	level._ship_state.systems.hydro.isolated=false;level._ship_state.tick(2.0)
	level.ship_story_amara_dialogue()
	check("Delivery is holding steady" in str(level._crew_dialogue._lines),"Amara's healthy response follows actual restored readings")
	await dialogue("later")
	var receipts: Dictionary=level._ship_story.receipts.duplicate(true)
	level._story_handoff();await dialogue()
	check(level._ship_story.receipts==receipts,"Repeated handoff grants no duplicate progression")
	check(level.ship_restore(SAVE.read(ROOT+"mid_power.json")),"Restore earned pre-irrigation checkpoint for optional checks")
	level.ship_story_amara_dialogue();await dialogue("optional")
	for pair in [["hydro.pump","optional:amara_nutrient_pump"],["hydro.seedlings","optional:amara_seedling_sensor"]]:
		place_at_access(pair[0]);await settle();check(level.ship_open_procedure(pair[0]),"Optional station opens before irrigation repair")
		await frames(4);await operate(pair[1]);await key(KEY_ESCAPE)
	check(level._completed_crew_tasks.size()==2 and level._ship_story.completed_count()==3 and not level._ship_state.completed.has("hydro"),"Both optional checks cannot impersonate the still-unrepaired irrigation duty")
	check(level._ship_state.transactions.is_empty() and level._ship_state.systems.hydro.ec==2,"Optional checks consume no correction chemical")
	# Version-1 migration preserves actual technical/inventory state, with no
	# first-watch or watched-cinematic receipt invented by the adapter.
	var legacy: Dictionary=complete.duplicate(true);legacy.version=1;legacy.erase("story")
	legacy.mission.version=1;legacy.mission.erase("context");legacy.mission.erase("work_orders")
	check(level.ship_restore(legacy),"Valid version-1 save migrates")
	check(not level.ship_story_active() and level._ship_state.work_order_context=="maintenance","Legacy stays maintenance rather than inventing a chapter")
	check(serialized_equal(level._walk_hud.inventory_snapshot(),complete.inventory) and level._ship_state.completed==complete.mission.completed,"Migration preserves inventory, equipment and completed procedures")
	check(not level.ship_snapshot().has("story"),"Legacy migration fabricates no story/cue section")
	check(level.ship_restore(complete),"Return to earned story context")
	# Both interaction and walk-through boundary must remain guarded, even after
	# chapter completion. Keep the actual automatic airlock behavior enabled.
	var exit: Node2D=level.exterior_airlock
	level.player.global_position=exit.global_position+Vector2(0,28);await get_tree().create_timer(0.4).timeout
	level.ship_refresh_prompt();check(level._active_airlock_exit,"Actual airlock E prompt reachable")
	await interact();check(not level._transitioning_to_planet and level.ship_story_active(),"Ordinary E departure is guarded after handoff")
	level.player.global_position=level.floor_layer.to_global(Vector2(478.5,270))
	movement(Vector2.UP);await frames(3);movement(Vector2.ZERO)
	check(get_tree().current_scene==level and not level._transitioning_to_planet,"Walk-through boundary departure is guarded after handoff")
	level.player.global_position=level._ship_points["bridge.planning"].marker.global_position
	# Pending handoff is a safe reoffer, not a serialized animation frame.
	var pending: Dictionary=complete.duplicate(true)
	pending.story.receipts.erase("watch.acknowledged");pending.story.cues["cue.asteria.watch_handoff"].status="pending"
	check(level.ship_restore(pending),"Load pending handoff at safe checkpoint")
	await frames(4)
	check(not level.ship_control_locked() and not level._ship_story.has("watch.acknowledged"),"Pending cue grants no completion or stuck input")
	var pending_receipts: Dictionary=level._ship_story.receipts.duplicate(true)
	var camera: Camera2D=level.player.camera;var zoom: Vector2=camera.zoom;var offset: Vector2=camera.offset
	var original_camera := camera_state(camera)
	check(not level.ship_request_story_cue("cue.asteria.watch_handoff","res://.godot/missing_cinematic.tscn"),"Missing cue resource refuses safely")
	check(level._ship_story.receipts==pending_receipts and not level.ship_control_locked(),"Missing cue preserves earned facts and releases locks")
	Engine.set_meta("first_watch_fixture_actor","maya")
	check(not level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Missing physical actor refuses without inventing Maya")
	Engine.set_meta("first_watch_fixture_actor","thura")
	for outcome in ["cancelled","failed","node_exit"]:
		Engine.set_meta("first_watch_fixture_outcome",outcome)
		check(level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Request contract fixture: "+outcome)
		await frames(8)
		check(not level.ship_control_locked() and level.player.is_physics_processing() and level.amara._interaction_locks.is_empty(),"Terminal outcome restores input/NPC locks: "+outcome)
		check(camera.is_current() and camera.zoom==zoom and camera.offset==offset,"Terminal outcome restores gameplay camera: "+outcome)
		check(camera_state(camera)==original_camera,"Terminal outcome restores bounds, position and smoothing: "+outcome)
		check(level._ship_story.receipts==pending_receipts,"Failure/cancel grants no chapter completion: "+outcome)
	Engine.set_meta("first_watch_fixture_outcome","pending")
	check(level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Pending fixture takes one cue lock")
	var context: Dictionary=level._ship_cue_active.duplicate()
	check(not level.ship_finish_story_cue(context.cue_id,"stale-token","completed"),"Stale callback is ignored")
	await key(KEY_I);check(level._hud_modal_open,"Inventory may hold an independent lock during cue")
	check(level.ship_finish_story_cue(context.cue_id,context.request_token,"cancelled"),"Authoritative cancellation accepted once")
	check(not level.player.is_physics_processing(),"Cue release does not release inventory lock")
	await key(KEY_ESCAPE)
	check(level.player.is_physics_processing(),"Closing final modal restores walking")
	check(not level.ship_finish_story_cue(context.cue_id,context.request_token,"completed"),"Duplicate callback cannot advance cancelled request")
	Engine.set_meta("first_watch_fixture_outcome","pending")
	check(level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Lost-callback fixture starts")
	# Accelerate only this isolated fixture's clock; exercise the actual 90-second
	# owner deadline, with both actors already held by the real cue lock.
	Engine.time_scale=120.0
	await get_tree().create_timer(91.0).timeout
	Engine.time_scale=1.0
	check(not level.ship_control_locked() and not level._ship_story.has("watch.acknowledged") and camera.is_current(),"Lost callback deadline fails safely without completion")
	Engine.set_meta("first_watch_fixture_outcome","completed");Engine.set_meta("first_watch_fixture_landing","unknown")
	check(level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Invalid landing fixture starts")
	await frames(8);check(not level._ship_story.has("watch.acknowledged") and not level.ship_control_locked(),"Invalid landing refuses completion and restores control")
	Engine.set_meta("first_watch_fixture_landing","ship")
	for outcome in ["completed","skipped"]:
		check(level.ship_restore(pending),"Restore earned pending summary for semantic "+outcome)
		await frames(4);Engine.set_meta("first_watch_fixture_outcome",outcome)
		check(level.ship_request_story_cue("cue.asteria.watch_handoff",CUE_FIXTURE),"Contract outcome fixture starts: "+outcome)
		await frames(8)
		check(level._ship_story.has("watch.acknowledged") and level._ship_story.completed_count()==5,"Complete/skip converge on same semantic handoff: "+outcome)
		check(camera.is_current() and camera.zoom==zoom and camera.offset==offset and not level.ship_control_locked(),"Semantic outcome restores camera/input: "+outcome)
		check(camera_state(camera)==original_camera,"Semantic outcome restores full gameplay camera state: "+outcome)
	# Actual pending arrival reoffers the existing overlay after safe restoration.
	var arrival: Dictionary=SAVE.read(ROOT+"mid_roster.json").duplicate(true)
	arrival.story.cues["cue.asteria.arrival"].status="pending"
	check(level.ship_restore(arrival),"Pending arrival snapshot restores")
	await frames(6)
	check(level._arrival_briefing_open and level.ship_control_locked(),"Pending arrival reoffers real briefing and correct aggregate lock")
	var old_arrival_callback: Callable=level.get_node("ArrivalBriefing").dismissed.get_connections()[0].callable
	await key(KEY_ENTER)
	check(level.ship_restore(arrival),"Arrival can reload while its previous fade is pending")
	await frames(6);old_arrival_callback.call()
	check(level._arrival_briefing_open and level.ship_control_locked(),"Old briefing dismissal cannot finish or unlock a new cue attempt")
	await key(KEY_ENTER);await get_tree().create_timer(0.35).timeout
	check(not level._arrival_briefing_open and not level.ship_control_locked(),"Reoffered arrival dismisses without replaying prologue")
	# Explicit maintenance route alone can request the mock surface. Missing
	# destination must restore controls and remove transient handoff metadata.
	level.ship_start_development_scenario("outbound")
	level.ship_mission_save_path=ROOT+"development.json"
	level.mock_planet_scene_path="res://.godot/nonexistent_surface.tscn"
	level._exit_ship_to_planet();await frames(4)
	check(not level._transitioning_to_planet and level.player.is_physics_processing() and not Engine.has_meta("ship_mission_transit"),"Failed development scene load recovers controls and transit metadata")

func intro_checkpoint() -> void:
	Engine.set_meta("ship_story_validation_path",ROOT+"intro_pending_start.json")
	var landing: Node=load("res://scenes/ui/landing_screen.tscn").instantiate()
	get_tree().root.add_child(landing);get_tree().current_scene=landing;await frames(5)
	var previous: int=landing.get_instance_id();await click(landing._start_button)
	var intro: Node=await current_scene_changed(previous)
	while intro._transitioning: await frames(1)
	for i in range(2):
		if intro._is_subtitle_typing: await key(KEY_SPACE)
		await key(KEY_SPACE)
		while intro._transitioning: await frames(1)
	var payload: Dictionary=SAVE.read(intro._campaign_path)
	check(not payload.is_empty() and payload.story.cues["cue.thura.earth_years"].status=="pending","New start persists a real pending intro before boarding")
	check(payload.get("spawn_pending",false) and payload.story.receipts.is_empty() and payload.mission.completed.is_empty(),"Intro checkpoint has no fabricated actor landing or mission completion")
	check(SAVE.atomic_write(ROOT+"pending_intro.json",payload)==OK,"Copy actual interrupted-intro checkpoint for cold restart")
	check(intro._frame_index==2,"Actual prologue input reached the third supplied frame")
	await capture("pending_intro",true)
	# finish() exits this process while the actual montage is still pending.

func restart_intro() -> void:
	var payload: Dictionary=SAVE.read(ROOT+"pending_intro.json")
	if not check(not payload.is_empty(),"Cold restart has an earned pending-intro file"): return
	Engine.set_meta("ship_story_validation_path",ROOT+"pending_intro.json")
	var landing: Node=load("res://scenes/ui/landing_screen.tscn").instantiate()
	get_tree().root.add_child(landing);get_tree().current_scene=landing;await frames(5)
	check(is_instance_valid(landing._continue_button),"Fresh menu offers Continue for pending intro")
	var previous: int=landing.get_instance_id();await click(landing._continue_button)
	var intro: Node=await current_scene_changed(previous)
	check(intro.has_method("_enter_game") and intro._frame_index==0,"Pending intro resumes at the safe opening frame")
	var old_token: String=payload.story.cues["cue.thura.earth_years"].token
	check(intro._cue_context.request_token!=old_token,"Cold intro resume identifies a new cue attempt")
	check(not intro._bootstrap_story.finish_cue("cue.thura.earth_years",old_token,"completed"),"Pre-restart cue callback cannot complete the resumed attempt")
	while intro._transitioning: await frames(1)
	await capture("continue_intro",true);await click(intro._skip_button);await wait_ship()
	check(level._arrival_briefing_open and level._ship_story.cues["cue.thura.earth_years"].status=="skipped","Resumed authored skip reaches actual arrival briefing")
	check(level.player.global_position==level.player_spawn and level._ship_hide_point_clear(level.player.global_position),"Initial actor landing uses the current saved scene spawn and clearance")
	check(serialized_equal(level._walk_hud.inventory_snapshot(),payload.inventory) and level._ship_story.receipts.is_empty(),"Cold intro resume retains inventory and creates no assignment receipt")
	await key(KEY_ENTER);await get_tree().create_timer(0.35).timeout
	check(level.player.is_physics_processing() and level._ship_story.objective().station=="bridge.planning","Resumed intro converges on the normal first objective")
	check(not SAVE.read(level.ship_mission_save_path).get("spawn_pending",false),"Live actor checkpoint replaces pending-spawn marker atomically")

func run() -> void:
	match validation_mode:
		"hiding": await hiding()
		"restart_roster": await restart("mid_roster",1)
		"restart_power": await restart("mid_power",3)
		"restart_complete": await restart("completed",5)
		"contracts": await contracts()
		"intro_checkpoint": await intro_checkpoint()
		"restart_intro": await restart_intro()
		_: check(false,"Unknown recovery fixture")
	finish()
