extends Node
## Focused runtime/state tests. All writes stay in .godot/mission_validation.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
var level
var state
var hud: WalkHud
var checks := 0
var failures: Array=[]
var result := {}

func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures.append(description);push_error(description)

func frames(count := 3) -> void:
	for i in range(count): await get_tree().process_frame

func _ready() -> void:
	print("STATE VALIDATION: ready")
	run.call_deferred()

func action(prop: String, id: String, value: Variant=null, expected := true) -> Dictionary:
	var response: Dictionary=state.act(prop,id,value)
	check(response.ok==expected,"Action %s/%s: %s" % [prop,id,response.message])
	return response

func legacy(task: String, prop: String, test_cancel := false) -> void:
	var entry: Dictionary=level._ship_points[prop]
	if not is_instance_valid(entry.marker):
		check(false,"Cannot play legacy task without access marker: "+prop);return
	level.player.global_position=entry.marker.global_position
	check(level.ship_open_procedure(prop),"Procedure opens at "+prop)
	await frames()
	level._ship_action("legacy:"+task,null,prop)
	await frames()
	var console=level._ship_service_console
	check(is_instance_valid(console),"Existing service console created: "+task)
	if not is_instance_valid(console): return
	if task=="auxiliary_power":
		for i in range(3): console._power_sliders[i].value=[67,43,77][i]
		console._on_power_sync_pressed()
	elif task=="air_filter":
		console._on_filter_release_pressed();console._on_filter_rotate_pressed()
		if test_cancel:
			var before: int=hud.inventory_count(&"filter_cartridge")
			console._close_console();await get_tree().create_timer(0.25).timeout
			check(hud.inventory_count(&"filter_cartridge")==before,"Cancel filter does not consume spare")
			level.ship_open_procedure(prop);await frames();level._ship_action("legacy:"+task,null,prop);await frames()
			console=level._ship_service_console
			check(console._filter_stage==1 and console._filter_rotation==1,"Filter stage/orientation resumes")
		console._on_filter_rotate_pressed();console._on_filter_seat_pressed()
		console._filter_pressure_slider.value=67;console._on_filter_pressure_locked()
	elif task=="nutrient_flow":
		for i in range(3):
			while console._nutrient_rotations[i]!=[1,3,2][i]: console._on_nutrient_rotate_pressed(i)
		console._on_nutrient_flow_restore_pressed()
	check(console._task_complete,"Original service game finishes: "+task)
	console._close_console();await get_tree().create_timer(0.25).timeout
	check(state.flags.get("legacy."+task,false),"Service game publishes connected system state: "+task)

func run_context(context: String) -> void:
	print("STATE VALIDATION: begin ",context)
	if context=="return": level.ship_start_development_scenario(context)
	state=level._ship_state
	level.ship_mission_save_path="res://.godot/mission_validation/"+context+".json"
	check(not state.completed.has("crew"),"Scenario starts without fabricated completion")
	action("quarters.desk","roster",null,false)
	action("bridge.planning","assign")
	action("quarters.desk","roster")
	action("quarters.table","crew_log")
	action("quarters.desk","crew_compare","records_match" if context=="return" else "unconfirmed",false)
	action("quarters.desk","crew_compare","unconfirmed" if context=="return" else "records_match")
	action("cargo.bundle","manifest")
	action("cargo.bundle","seal")
	action("cargo.scale","tare")
	action("cargo.mover","move_load","scale")
	action("cargo.scale","weigh")
	action("cargo.scale","cargo_decide","accept" if context=="return" else "quarantine",false)
	action("cargo.scale","cargo_decide","quarantine" if context=="return" else "accept")
	action("power.breaker","observe")
	action("power.breaker","diagnose","load" if context=="return" else "cell")
	action("power.breaker","isolate")
	action("power.converter","allocation","overload",false)
	check(state.systems.power.essential==70,"Poor allocation never removes essential supply")
	action("power.converter","allocation","reserve")
	if context=="outbound": await legacy("auxiliary_power","power.cell")
	action("power.breaker","restore");state.tick(7.0);action("power.breaker","verify")
	check(state.completed.has("power"),"Complete multistage power duty")
	action("life.filter","observe")
	action("life.filter","diagnose","oxygen",false)
	action("life.filter","diagnose","scrubber" if context=="return" else "airflow")
	action("life.filter","isolate")
	if context=="outbound":
		action("quarters.drawer.1","take:filter_cartridge")
		await legacy("air_filter","life.filter",true)
	else:
		action("cargo.cylinders","cylinder","oxygen_reserve")
		var co2_before: float=state.systems.life.co2
		action("life.oxygen","oxygen_reserve")
		check(state.systems.life.reserve==100.0 and state.systems.life.co2==co2_before,"O2 reserve identity is meaningful but cannot mask poor CO2 removal")
		action("quarters.drawer.1","take:scrubber_media")
		action("life.scrubber","scrubber_service")
	action("life.duct","restore");state.tick(7.0);action("life.filter","verify")
	action("hydro.console","observe")
	action("hydro.console","diagnose","balance" if context=="return" else "restriction")
	action("hydro.pump","isolate")
	if context=="outbound": await legacy("nutrient_flow","hydro.console")
	else:
		action("quarters.drawer.2","take:nutrient_buffer")
		var stock_before: int=hud.inventory_count(&"nutrient_buffer")
		action("hydro.console","dose",2.0,false)
		check(hud.inventory_count(&"nutrient_buffer")==stock_before,"Rejected dose does not consume buffer")
		action("hydro.console","dose",1.0)
	action("hydro.pump","restore");state.tick(7.0);action("hydro.console","verify")
	# Connected equipment responds to the published bus, independently of duty
	# completion flags. This fixture models a temporary service outage only.
	state.systems.power.isolated=true;state.tick(0.1)
	check(state.bus_powered("essential") and not state.bus_powered("science") and state.systems.hydro.flow==0.0,"Science isolation stops irrigation while essential power remains live")
	state.systems.power.isolated=false;state.tick(0.1)
	check(state.systems.hydro.flow>=90,"Restored bus recovers irrigation through actual equipment state")
	action("engine.pump.1","observe")
	action("engine.pump.1","diagnose","valve" if context=="return" else "pump")
	action("engine.turbine.1","reduce_load")
	var service_prop := "engine.valve.2" if context=="return" else "engine.pump.1"
	action(service_prop,"isolate")
	if context=="outbound":
		action("cargo.trolley","transfer_kit")
		action("engine.locker.1","take:coolant_charge")
	action(service_prop,"engine_service")
	action(service_prop,"restore");state.tick(10.0);action(service_prop,"verify")
	action("engine.turbine.1","resume_output")
	check(state.engine_flow(0)>=0.9 and state.engine_flow(1)>=0.9,"Both cooling loops recover through actual pump/valve state")
	action("bridge.helm","route")
	action("bridge.helm","correction",5.0)
	action("bridge.helm","nav_verify",null,false)
	action("bridge.helm","correction",-9.0 if context=="return" else -6.0)
	action("bridge.helm","nav_verify")
	action("bridge.comms.upper","prepare_report")
	check(state.systems.communications.report_id=="A1-DUTY-"+context.to_upper() and state.systems.communications.report_text.contains("%.1f kg" % state.systems.cargo.measured_mass) and state.systems.communications.report_text.contains("Verified heading"),"Prepared report retains actual phase-specific cargo/flight/system measurements")
	var prepared_text: String=state.systems.communications.report_text
	action("bridge.comms.upper","channel","local")
	action("bridge.comms.upper","transmit",null,false)
	action("bridge.comms.upper","channel","robust" if context=="return" else "standard")
	action("bridge.comms.upper","transmit");state.tick(4.0)
	check(state.systems.communications.report_text==prepared_text,"Acknowledgement retains the transmitted report snapshot")
	check(state.completed.size()==8,"All eight procedures across seven rooms complete: "+context)
	var inventory_before := JSON.stringify(hud.inventory_snapshot())
	var completions: int=state.completed.size()
	action("bridge.comms.upper","transmit",null,false)
	check(inventory_before==JSON.stringify(hud.inventory_snapshot()) and completions==state.completed.size(),"Duplicate submission creates no reward or consumption")
	action("bridge.planning","file_report")
	for room in ["bridge","quarters","cargo","engine","power","life","hydro"]:
		var prop: String={"bridge":"bridge.planning","quarters":"quarters.desk","cargo":"cargo.bundle","engine":"engine.pump.1","power":"power.breaker","life":"life.filter","hydro":"hydro.console"}[room]
		action(prop,"record")
		check(state.evidence.has(context+"."+room),"Phase-specific narrative evidence: "+room)
	check(level.ship_save_game().begins_with("Ship-side mission"),"Mission save succeeds in isolated test path")
	var snapshot: Dictionary=level.ship_snapshot()
	state.systems.engine.load=0.2
	check(level.ship_load_game().begins_with("Ship-side progress"),"Mission load succeeds")
	check(state.completed.size()==8 and state.systems.engine.load==1.0 and state.flags.report_filed,"Equipment/objective/report state survives load")
	check(JSON.stringify(snapshot.inventory)==JSON.stringify(hud.inventory_snapshot()),"Inventory order and equipment survive load")
	var invalid: Dictionary=snapshot.duplicate(true);invalid.inventory.storage=[]
	check(not level.ship_restore(invalid),"Invalid load rejected atomically")
	check(state.completed.size()==8,"Invalid load does not reset progress")
	var malformed_cases: Array=[]
	invalid=snapshot.duplicate(true);invalid.mission.stocks.erase("cargo.locker");malformed_cases.append(invalid)
	invalid=snapshot.duplicate(true);invalid.mission.stocks["cargo.locker"]["unknown_item"]=1;malformed_cases.append(invalid)
	invalid=snapshot.duplicate(true);invalid.mission.journal=[{"text":"truncated"}];malformed_cases.append(invalid)
	invalid=snapshot.duplicate(true);invalid.mission.legacy_progress={"air_filter":{"task":"air_filter","filter_stage":"broken"}};malformed_cases.append(invalid)
	invalid=snapshot.duplicate(true);invalid.inventory.selected=0.5;malformed_cases.append(invalid)
	for malformed in malformed_cases:
		check(not level.ship_restore(malformed),"Malformed stock/log/procedure/selection save rejected atomically")
	result[context]={"completed":state.completed.duplicate(),"evidence":state.evidence.keys(),"journal_entries":state.journal.size()}
	print("STATE VALIDATION: complete ",context)

func reopen_level(save_path: String) -> void:
	# Match the existing scene transition's fade/settle interval before disposal.
	await get_tree().create_timer(0.3).timeout
	print("STATE VALIDATION: release old walkthrough")
	# Do not retain typed HUD/controller handles after their scene is freed.
	hud=null;state=null
	level.queue_free();level=null;await frames(3)
	print("STATE VALIDATION: create replacement walkthrough")
	var replacement=LEVEL.instantiate()
	print("STATE VALIDATION: replacement instantiated")
	level=replacement;level.ship_mission_save_path=save_path
	print("STATE VALIDATION: add replacement to tree")
	add_child(level)
	print("STATE VALIDATION: wait for replacement access points")
	while not level._ship_points_ready: await get_tree().process_frame
	print("STATE VALIDATION: replacement ready")
	hud=level._walk_hud;state=level._ship_state
	level._on_arrival_briefing_dismissed();level.player.set_physics_process(false)
	for child in level.get_children():
		if child is CanvasLayer and child!=hud: child.hide()

func test_restart_persistence() -> void:
	print("STATE VALIDATION: fresh-scene persistence")
	var previous: Dictionary=level.ship_snapshot()
	level.ship_mission_save_path="res://.godot/mission_validation/restart.json"
	check(level.ship_save_game().begins_with("Ship-side mission"),"Restart fixture saved in isolated path")
	await reopen_level(level.ship_mission_save_path)
	check(state.phase=="outbound" and state.completed.is_empty(),"Fresh walkthrough starts without retained test state")
	check(level.ship_load_game().begins_with("Ship-side progress"),"Fresh walkthrough loads saved return scenario")
	print("STATE VALIDATION: full reload returned")
	check(state.phase=="return" and state.completed.size()==8 and state.flags.report_filed,"Phase, objectives and final report survive fresh scene")
	check(JSON.stringify(previous.inventory)==JSON.stringify(hud.inventory_snapshot()),"Fresh scene restores the same inventory/equipment order")
	check(previous.mission.stocks==state.stocks and previous.mission.evidence==state.evidence,"Storage ledgers and phase evidence survive fresh scene")
	level.ship_start_development_scenario("outbound")
	level.ship_mission_save_path="res://.godot/mission_validation/partial_restart.json"
	state.flags.assigned=true;state.completed={"crew":true,"cargo":true,"power":true}
	action("life.filter","observe");action("life.filter","diagnose","airflow");action("life.filter","isolate")
	action("quarters.drawer.1","take:filter_cartridge")
	level.player.global_position=level._ship_points["life.filter"].marker.global_position
	level.ship_open_procedure("life.filter");await frames()
	level._ship_action("legacy:air_filter",null,"life.filter");await frames()
	var console=level._ship_service_console
	console._on_filter_release_pressed();console._on_filter_rotate_pressed()
	check(level.ship_save_game().begins_with("Ship-side mission"),"Open partial service controls included in save")
	console._close_console();await get_tree().create_timer(0.3).timeout
	await reopen_level(level.ship_mission_save_path)
	check(level.ship_load_game().begins_with("Ship-side progress"),"Fresh scene loads partial filter procedure")
	print("STATE VALIDATION: partial reload returned")
	check(hud.inventory_count(&"filter_cartridge")==1 and not state.completed.has("life"),"Pending filter remains carried and duty incomplete after restart")
	level.player.global_position=level._ship_points["life.filter"].marker.global_position
	level.ship_open_procedure("life.filter");await frames()
	level._ship_action("legacy:air_filter",null,"life.filter");await frames()
	console=level._ship_service_console
	check(console._filter_stage==1 and console._filter_rotation==1,"Partial housing stage/orientation restored after restart")
	console._on_filter_rotate_pressed();console._on_filter_seat_pressed();console._filter_pressure_slider.value=67;console._on_filter_pressure_locked()
	check(hud.inventory_count(&"filter_cartridge")==0 and state.systems.life.serviced,"Successful resumed service consumes exactly one pending filter")
	check(not state.legacy_complete("air_filter","life.filter") and hud.inventory_count(&"filter_cartridge")==0,"Duplicate legacy completion cannot consume again")
	console._close_console();await get_tree().create_timer(0.3).timeout
	var carried_before_transit := JSON.stringify(hud.inventory_snapshot())
	var transit_path: String=level.ship_mission_save_path
	level.ship_store_transit()
	Engine.set_meta("returning_from_planet",true)
	await reopen_level("user://ship_side_missions_v1.json")
	check(state.phase=="outbound" and state.systems.life.serviced and state.flags.get("legacy.air_filter",false),"Existing planet transit carries ship equipment/procedure state")
	check(carried_before_transit==JSON.stringify(hud.inventory_snapshot()),"Existing planet transit retains the same inventory")
	check(level.ship_mission_save_path==transit_path,"Planet transit preserves isolated development/test save namespace")
	result.restart_persistence=true

func run() -> void:
	print("STATE VALIDATION: instantiate walkthrough")
	DirAccess.make_dir_recursive_absolute("res://.godot/mission_validation")
	level=LEVEL.instantiate();level.ship_mission_save_path="res://.godot/mission_validation/runtime.json"
	add_child(level);await frames(12)
	while not level._ship_points_ready: await get_tree().process_frame
	hud=level._walk_hud;state=level._ship_state
	var immutable_inventory: Dictionary=hud.inventory_snapshot()
	var immutable_text := JSON.stringify(immutable_inventory)
	hud.inventory_put(&"filter_cartridge")
	check(JSON.stringify(immutable_inventory)==immutable_text,"Inventory snapshot owns arrays independently of later mutations")
	hud.inventory_restore(immutable_inventory)
	level._on_arrival_briefing_dismissed()
	for child in level.get_children():
		if child is CanvasLayer and child!=hud: child.hide()
	level.player.set_physics_process(false)
	result.access={}
	for id in level._ship_points:
		var entry: Dictionary=level._ship_points[id]
		result.access[id]=entry.issue
		check(is_instance_valid(entry.marker),"Safe access marker exists: "+id)
	check(not level.has_node("LabRoom"),"Inactive lab is not a runtime dependency")
	await run_context("outbound")
	await run_context("return")
	await test_restart_persistence()
	result.checks=checks;result.failures=failures
	var file := FileAccess.open("res://.godot/mission_validation/state_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"));file.close()
	print("SHIP MISSIONS: ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
