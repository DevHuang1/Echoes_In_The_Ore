extends SceneTree
## Renders redesigned screens in given states for visual comparison with the design.
## godot --path . --script res://tools/eito_preview.gd -- <kind> <preset> <out.png> [seconds]
const LAYER := preload("res://scripts/ui/eito/eito_layer.gd")
const STATE := preload("res://scripts/ship/ship_mission_state.gd")

class Inv extends RefCounted:
	var items := {"engineering_multitool":1}
	func inventory_count(i: StringName) -> int: return int(items.get(str(i), 0))
	func inventory_take(i: StringName, n := 1) -> bool:
		if inventory_count(i) < n: return false
		items[str(i)] -= n; return true
	func inventory_put(i: StringName, n := 1) -> bool:
		items[str(i)] = inventory_count(i) + n; return true

var inv := Inv.new()
var state
var layer
var frames := 0
var wait := 1.0
var elapsed := 0.0
var out := ""
var script_steps := []
var capture_in_progress := false
var board_kind := ""
var board_preset := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var kind: String = args[0] if args.size() > 0 else "power"
	var preset: String = args[1] if args.size() > 1 else "start"
	board_kind=kind;board_preset=preset
	out = args[2] if args.size() > 2 else "/tmp/eito.png"
	wait = float(args[3]) if args.size() > 3 else 1.0
	state = STATE.new(); state.configure(inv); state.configure_first_watch()
	state.flags.assigned = true
	state.authorized_work_orders = PackedStringArray(["crew", "hydro.inspect", "power", "hydro", "cargo"])
	if kind == "dialogue":
		_dialogue(preset); return
	var prop: String = {"power":"power.breaker", "irrigation":"hydro.console", "records":"quarters.desk", "cargo_scale":"cargo.scale", "pallet_mover":"cargo.mover", "cylinder_rack":"cargo.cylinders", "maintenance_trolley":"cargo.trolley", "air_duct":"life.duct", "air_filter":"life.filter", "co2_scrubber":"life.scrubber", "oxygen_rack":"life.oxygen", "supply_stores":"quarters.drawer.1", "turbine":"engine.turbine.1", "valve_manifold":"engine.valve.2", "coolant_pump":"engine.pump.1", "nutrient_pump_check":"hydro.pump", "seedling_rack_check":"hydro.seedlings", "helm":"bridge.helm", "communications":"bridge.comms.upper", "planning_table":"bridge.planning"}.get(kind, "power.breaker")
	_apply(kind, preset, prop)
	layer = LAYER.new()
	layer.setup(state, prop, "Preview", kind)
	layer.story_mode = true
	get_root().add_child(layer)

var dlg
func _dialogue(preset: String) -> void:
	var bg := ColorRect.new(); bg.color = Color("#0b1417"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cl := CanvasLayer.new(); cl.add_child(bg); get_root().add_child(cl)
	dlg = preload("res://scripts/ui/crew_dialogue.gd").new()
	get_root().add_child(dlg)
	var lines: Array[String] = []
	match preset:
		"maya":
			lines = ["Thura, it's Maya. The watch is yours from now. Start with the crew records."]
			dlg.start_dialogue(lines, false, {"id":"maya", "speaker":"MAYA CHEN / CDR / TERMINAL TEXT", "objective":"Accept Maya's watch", "choices":[{"id":"a","label":"Accept the watch"},{"id":"b","label":"Anything I should check first?"}]})
		"maya_more":
			lines = ["Thura, it's Maya.", "Second line."]
			dlg.start_dialogue(lines, false, {"id":"maya", "speaker":"MAYA CHEN / CDR / TERMINAL TEXT", "objective":"Accept Maya's watch"})
		"amara":
			lines = ["Thura. Glad you're on watch. The beds aren't getting enough water."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."},{"id":"b","label":"What have you checked so far?"}]})
		"amara_typing":
			lines = ["Thura. Glad you're on watch. The beds aren't getting enough water."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."}]})
		"amara_echo":
			lines = ["Thura. Glad you're on watch."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."}]})
			script_steps = [[1.0, "pick", 0]]
		"amara_long":
			lines = ["Delivery is low. The console by the west wall has the reservoir chemistry, pump capacity and flow readings. Have a look, then tell me what you find."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll check the readings"},{"id":"b","label":"Is the pump failing?"},{"id":"c","label":"A moment first"}]})
		"ribbon":
			dlg.flash_objective("Restore irrigation")

func A(prop: String, action: String, value = null) -> void:
	var r: Dictionary = state.act(prop, action, value)
	if not r.ok: push_warning("%s %s -> %s" % [prop, action, r.message])

func _apply(kind: String, preset: String, prop: String) -> void:
	if kind=="supply_stores":
		if preset=="take": script_steps=[[0.1,"click","take:filter_cartridge"]]
		elif preset=="returned": script_steps=[[0.08,"click","take:filter_cartridge"],[0.16,"click","store:filter_cartridge"]]
		elif preset=="blocked": script_steps=[[0.1,"click","tab:2"]]
		return
	if kind=="helm":
		state.reset("outbound");state.flags.assigned=true;state.completed={"crew":true,"engine":true};_power_on()
		if preset=="start": return
		if preset=="blocked": script_steps=[[0.1,"click","apply"]];return
		state.flags["navigation.plan_read"]=true
		if preset=="planned": return
		state.flags["navigation.compared"]=true
		if preset=="instrument": return
		state.flags["navigation.correction_applied"]=true;state.systems.navigation.correction=-6.0
		if preset=="wrong": state.systems.navigation.correction=-2.0;return
		if preset=="applied": return
		state.systems.navigation.verified=true;state.completed["navigation"]=true;return
	if kind=="communications":
		state.reset("outbound");state.flags.assigned=true;_power_on()
		state.completed={"crew":true,"cargo":true,"power":true,"life":true,"hydro":true,"engine":true,"navigation":true}
		state.systems.communications.signal=72.0
		if preset=="start": return
		if preset=="blocked": script_steps=[[0.1,"click","transmit"]];return
		state.flags["communications.signal_read"]=true
		if preset=="signal": return
		A(prop,"prepare_report")
		if preset=="report": return
		A(prop,"channel","standard");state.flags["communications.protocol_selected"]=true
		if preset=="protocol": return
		state.flags["communications.guard_open"]=true
		if preset=="guard": return
		A(prop,"transmit")
		if preset=="working": return
		state.systems.communications.acknowledged=true;state.completed["communications"]=true;state.verification.ack=3.0;return
	if kind=="planning_table":
		state.flags.assigned=false
		state.story_progress={"receipts":{},"objective":{"title":"Receive the watch","description":"Bridge: speak to Maya through the planning table beside the main helm."},"acknowledged":false,"can_submit":false,"summary":""}
		if preset=="briefing": script_steps=[[0.1,"click","tab:1"]]
		elif preset=="records": script_steps=[[0.1,"click","tab:2"]]
		elif preset=="blocked": script_steps=[[0.1,"click","tab:2"],[0.2,"click","review"]]
		elif preset=="completed":
			# Use only the checkpoint from a successful actual chapter playthrough.
			var report = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/first_watch_validation/chapter_report.json"))
			var snapshot = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/mission_validation/first_watch/completed.json"))
			var story := preload("res://scripts/ship/first_watch_story.gd").new()
			if not report is Dictionary or not report.get("complete",false) or not report.get("failures",["missing"]).is_empty() or not snapshot is Dictionary or not story.restore(snapshot.get("story",{})) or not state.restore(snapshot.get("mission",{})):
				push_error("Completed planning preview requires a validated real chapter checkpoint.");quit(2);return
			state.story_progress={"completed":story.completed_count(),"acknowledged":story.has("watch.acknowledged"),"receipts":story.receipts.duplicate(),"objective":story.objective(),"summary":story.summary,"can_submit":false}
			script_steps=[[0.1,"click","tab:2"]]
		return
	if kind == "cargo_scale":
		_apply_cargo(preset)
		return
	if kind == "pallet_mover":
		_apply_mover(preset)
		return
	if kind == "cylinder_rack":
		_apply_cylinder(preset)
		return
	if kind == "maintenance_trolley":
		_apply_trolley(preset)
		return
	if kind == "air_duct":
		_apply_duct(preset)
		return
	if kind == "air_filter":
		_apply_filter(preset)
		return
	if kind == "co2_scrubber":
		_apply_scrubber(preset)
		return
	if kind == "oxygen_rack":
		_apply_oxygen(preset)
		return
	if kind == "turbine":
		_apply_turbine(preset)
		return
	if kind == "valve_manifold":
		_apply_valve(preset)
		return
	if kind == "coolant_pump":
		_apply_pump(preset)
		return
	if kind in ["nutrient_pump_check","seedling_rack_check"]:
		state.optional_checks={"enabled":true}
		state.completed["power"]=true
		state.systems.hydro.flow=96.0
		if preset=="blocked": script_steps=[[0.2,"click","record"]]
		elif preset=="observed": script_steps=[[0.1,"click","flow" if kind=="nutrient_pump_check" else "sensor"]]
		elif preset=="completed":
			state.optional_checks["amara_nutrient_pump" if kind=="nutrient_pump_check" else "amara_seedling_sensor"]=true
		return
	if kind == "irrigation": _apply_irr(preset, prop)
	if kind == "records":
		match preset:
			"wrong": script_steps = [[2.0, "click", "slip:0"]]
			"right": script_steps = [[2.0, "click", "slip:1"]]
	if kind == "power":
		match preset:
			"interlocked":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":false,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(393-390)*100.0/20.0,(38+60)*100.0/120.0],"nutrient_rotations":[]}
			"working":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":false,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(400-390)*100.0/20.0,(2+60)*100.0/120.0],"nutrient_rotations":[]}
				script_steps = [[0.2, "click", "sync"]]
			"verified":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair"); A(prop, "sync"); A(prop, "restore")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(400-390)*100.0/20.0,(1+60)*100.0/120.0],"nutrient_rotations":[]}
				state.verification.power = 4.0; A(prop, "verify")
				script_steps = [[0.05, "comms", ""]]

func _apply_cargo(preset: String) -> void:
	if preset == "start": return
	if preset == "blocked":
		script_steps = [[0.2,"click","read"]]
		return
	for action in ["manifest","seal","tare"]:
		A("cargo.scale",action)
		if preset == {"manifest":"tag","seal":"seal","tare":"zero"}[action]: return
	state.flags["cargo.reference_checked"] = true
	if preset == "reference": return
	A("cargo.mover","move_load","scale")
	if preset == "mover": return
	A("cargo.scale","weigh")
	if preset == "read": return
	A("cargo.scale","cargo_decide","accept")

func _apply_mover(preset: String) -> void:
	if preset == "start": return
	if preset == "blocked":
		script_steps = [[0.2,"click","drive"]]
		return
	var n := int(preset.trim_prefix("stage")) if preset.begins_with("stage") else 5
	for i in range(1,mini(n,5)+1): state.flags["cargo.mover.stage."+str(i)]=true
	if preset == "completed":
		A("cargo.scale","manifest")
		A("cargo.mover","move_load","scale")

func _apply_cylinder(preset: String) -> void:
	if preset == "start": return
	if preset == "blocked":
		script_steps = [[0.2,"click","chain"]]
		return
	var n := int(preset.trim_prefix("stage")) if preset.begins_with("stage") else 4
	for i in range(1,mini(n,4)+1): state.flags["cargo.cylinder.stage."+str(i)]=true
	if preset == "completed":
		A("cargo.cylinders","cylinder","coolant_charge")
		state.flags["cargo.cylinder.issued"]=true

func _apply_trolley(preset: String) -> void:
	if preset == "start": return
	if preset == "blocked":
		script_steps = [[0.2,"click","send"]]
		return
	var n := int(preset.trim_prefix("stage")) if preset.begins_with("stage") else 5
	for i in range(1,mini(n,5)+1): state.flags["cargo.trolley.stage."+str(i)]=true
	if preset == "completed":
		state.completed["cargo"]=true
		A("cargo.trolley","transfer_kit")
		state.flags["cargo.trolley.issued"]=true

func _apply_duct(preset: String) -> void:
	# The reference depicts a repair order. It is not assigned on the first
	# playable watch, so previews use an isolated maintenance scenario.
	state.work_order_context="maintenance"
	state.authorized_work_orders=PackedStringArray(["life"])
	state.completed["power"]=true
	# Match the prototype's illustrated fault readings in visual fixtures only.
	state.systems.life.airflow=41.0
	state.systems.life.co2=0.09
	state.systems.life.reserve=78.0
	if preset=="start": return
	if preset=="blocked":
		script_steps=[[0.2,"click","restore"]]
		return
	A("life.duct","observe")
	if preset=="observed": return
	A("life.duct","diagnose","airflow")
	if preset=="diagnosed": return
	A("life.duct","isolate")
	if preset=="isolated": return
	state.systems.life.serviced=true
	if preset=="serviced": return
	A("life.duct","restore")
	if preset=="working": return
	state.verification.life=state.verify_seconds("life")
	A("life.duct","verify")

func _apply_filter(preset: String) -> void:
	state.work_order_context="maintenance"
	state.authorized_work_orders=PackedStringArray(["life"])
	state.completed["power"]=true
	state.flags["life.observed"]=true
	state.flags["life.diagnosed"]=true
	state.systems.life.isolated=true
	inv.items["filter_cartridge"]=1
	if preset=="blocked":
		script_steps=[[0.2,"click","prime"]]
		return
	var n := int(preset.trim_prefix("stage")) if preset.begins_with("stage") else 0
	if preset=="completed": n=8
	for i in range(1,n+1): state.flags["life.filter.step."+str(i)]=true
	state.legacy_progress["air_filter"]={"task":"air_filter","complete":preset=="completed","filter_stage":2 if n>=6 else 1 if n>=3 else 0,"filter_rotation":0 if n>=5 else 2,"filter_airflow":65.0 if n>=8 else 40.0,"power":[],"nutrient_rotations":[]}
	if preset=="completed":
		state.flags["legacy.air_filter"]=true
		state.systems.life.serviced=true

func _apply_scrubber(preset: String) -> void:
	state.reset("return")
	state.flags.assigned=true
	state.completed["power"]=true
	state.authorized_work_orders=PackedStringArray(["life"])
	inv.items["scrubber_media"]=1
	if preset=="start": return
	if preset=="blocked":
		script_steps=[[0.2,"click","swap"]]
		return
	A("life.scrubber","observe")
	if preset=="observed": return
	A("life.scrubber","diagnose","scrubber")
	if preset=="diagnosed": return
	A("life.scrubber","isolate")
	if preset=="isolated": return
	state.flags["life.scrubber.unbolted"]=true
	if preset=="unbolted": return
	A("life.scrubber","scrubber_service")
	if preset=="serviced": return
	A("life.scrubber","restore")
	if preset=="working": return
	state.verification.life=state.verify_seconds("life")
	A("life.scrubber","verify")

func _apply_oxygen(preset: String) -> void:
	state.reset("return")
	state.flags.assigned=true
	state.flags["life.diagnosed"]=true
	state.completed["power"]=true
	state.authorized_work_orders=PackedStringArray(["life"])
	inv.items["oxygen_reserve"]=1
	if preset=="start": return
	if preset=="blocked":
		script_steps=[[0.2,"click","check"]]
		return
	var n := int(preset.trim_prefix("stage")) if preset.begins_with("stage") else 0
	if preset=="completed": n=6
	for i in range(1,n+1): state.flags["life.oxygen.stage."+str(i)]=true
	if preset=="completed": A("life.oxygen","oxygen_reserve")

func _apply_turbine(preset: String) -> void:
	state.reset("outbound")
	state.flags.assigned=true
	state.completed.cargo=true; state.completed.power=true
	state.flags["engine.observed"]=true;state.flags["engine.diagnosed"]=true
	state.authorized_work_orders=PackedStringArray(["engine"])
	if preset=="start": return
	state.flags["engine.turbine.inspected.1"]=true
	if preset=="blocked": script_steps=[[0.1,"click","resume"]];return
	if preset=="inspected": return
	state.systems.engine.load=0.6
	if preset=="limited": return
	state.systems.engine.health[0]=1.0
	state.systems.engine.serviced=true
	state.systems.engine.temperature=60.0
	state.completed.engine=true
	if preset=="cooled": return
	state.systems.engine.load=1.0

func _apply_valve(preset: String) -> void:
	state.reset("return")
	state.flags.assigned=true
	state.completed["cargo"]=true;state.completed["power"]=true
	state.authorized_work_orders=PackedStringArray(["engine"])
	inv.items["engineering_multitool"]=1
	if preset=="start": return
	state.flags["engine.observed"]=true
	if preset=="compared": return
	state.flags["engine.diagnosed"]=true
	if preset=="diagnosed": return
	state.systems.engine.load=0.6
	if preset=="blocked": script_steps=[[0.1,"click","wheel:1"]];return
	state.systems.engine.isolated[1]=true
	if preset=="isolated": return
	if preset=="turn1": state.flags["engine.valve.2.service_turns"]=1;return
	if preset=="turn2": state.flags["engine.valve.2.service_turns"]=2;return
	state.systems.engine.valves[1]=1.0;state.systems.engine.serviced=true
	if preset=="serviced": return
	state.systems.engine.isolated[1]=false
	if preset=="working": return
	state.completed["engine"]=true

func _apply_pump(preset: String) -> void:
	state.reset("outbound")
	state.flags.assigned=true
	state.completed["cargo"]=true;state.completed["power"]=true
	state.authorized_work_orders=PackedStringArray(["engine"])
	inv.items["engineering_multitool"]=1
	inv.items["coolant_charge"]=1
	if preset=="start": return
	if preset=="blocked": script_steps=[[0.1,"click","charge"]];return
	state.flags["engine.observed"]=true
	if preset=="observed": return
	state.flags["engine.diagnosed"]=true
	if preset=="diagnosed": return
	state.systems.engine.load=0.6
	if preset=="limited": return
	state.systems.engine.isolated[0]=true
	if preset=="isolated": return
	state.flags["engine.pump.1.seal_checked"]=true
	if preset=="sealed": return
	state.systems.engine.health[0]=1.0;state.systems.engine.serviced=true
	if preset=="serviced": return
	state.systems.engine.isolated[0]=false;state.systems.engine.temperature=60.0
	if preset=="working": return
	state.completed["engine"]=true

func _power_on() -> void:
	state.systems.power.calibrated = true; state.systems.power.restored = true; state.systems.power.isolated = false
	state.systems.power.essential = 65; state.systems.power.science = 15; state.systems.power.reserve = 20

func _apply_irr(preset: String, prop: String) -> void:
	match preset:
		"interlocked":
			A(prop, "observe"); A(prop, "diagnose", "restriction")
		"power":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on()
		"working":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on(); A(prop, "isolate"); A(prop, "align")
			state.legacy_progress["nutrient_flow"] = {"task":"nutrient_flow","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[],"nutrient_rotations":[2,5,3]}
			script_steps = [[0.2, "click", "sv"]]
		"verified":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on(); A(prop, "isolate"); A(prop, "align")
			state.legacy_progress["nutrient_flow"] = {"task":"nutrient_flow","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[],"nutrient_rotations":[2,5,3]}
			A(prop, "restore"); state.verification.hydro = 4.0; A(prop, "verify")

func _process(delta: float) -> bool:
	if capture_in_progress: return false
	frames += 1
	elapsed += delta
	if state != null and dlg == null: state.tick(delta)
	while not script_steps.is_empty() and elapsed >= script_steps[0][0]:
		var s: Array = script_steps.pop_front()
		match s[1]:
			"click": layer.screen.on_click(s[2], null)
			"comms": layer.show_comms()
			"pick": dlg.pick(s[2])
	if elapsed >= wait and frames > 5:
		if not capture_in_progress:
			capture_in_progress=true;_capture.call_deferred()
	return false

func _capture() -> void:
	if is_instance_valid(layer) and is_instance_valid(layer.screen):
		layer.screen.set_process(false);layer.screen.now=wait;layer.screen.queue_redraw()
		for child in layer.screen.get_children():
			if child is CanvasItem: child.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := get_root().get_texture().get_image()
	img.save_png(out)
	var evidence := {"kind":board_kind,"preset":board_preset,"image_size":[img.get_width(),img.get_height()]}
	if state!=null:
		evidence["systems"]=state.systems.duplicate(true);evidence["flags"]=state.flags.duplicate(true);evidence["completed"]=state.completed.duplicate(true)
		evidence["verification"]=state.verification.duplicate(true)
		evidence["legacy"]=state.legacy_progress.duplicate(true)
		evidence["optional"]=state.optional_checks.duplicate(true);evidence["story"]=state.story_progress.duplicate(true)
		evidence["stocks"]=state.stocks.duplicate(true);evidence["inventory"]={"items":inv.items.duplicate(true)}
	if is_instance_valid(layer):
		evidence["feedback"]=layer.screen.fb.duplicate(true);evidence["procedure"]=layer.screen.artifact_proc_state.duplicate(true)
		if board_kind=="supply_stores": evidence["ui"]={"selected":layer.screen.selected,"page":layer.screen.page,"log_lines":layer.screen.log_lines.duplicate(true),"carried":layer.screen._carried()}
	var file := FileAccess.open(out.get_basename()+".json",FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(evidence,"\t"));file.close()
	print("saved ", out, " ", img.get_size())
	if is_instance_valid(layer): layer.queue_free()
	await process_frame
	quit()
