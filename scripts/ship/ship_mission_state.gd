extends RefCounted
## Serializable ship-side state owned by BareShipWalkthrough. Inventory remains
## owned by WalkHud; every transfer/consumption uses that inventory's public API.
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
signal changed
signal objective_completed(id: String)
var _inventory_ref: WeakRef
var inventory: Object:
	get:
		return _inventory_ref.get_ref() if _inventory_ref!=null else null
	set(value):
		_inventory_ref=weakref(value) if is_instance_valid(value) else null
var phase := "outbound"
var flags := {}
var completed := {}
var evidence := {}
var journal: Array = []
var stocks := {}
var legacy_progress := {}
var systems := {}
var verification := {}
var transactions := {}
var elapsed := 0.0
var work_order_context := "maintenance"
var authorized_work_orders := PackedStringArray()
var optional_checks := {}
var story_progress := {}
## Auxiliary power plans shown on the redesigned power panel (percent of output).
const POWER_PLANS := {"standard":[50,40,10], "science":[45,45,10], "repair":[65,15,20]}
const POWER_MIN := {"essential":60, "reserve":15}
## Seconds of steady readings before Verify unlocks (three samples on the panels).
const VERIFY_SECONDS := {"power":3.3, "hydro":3.6}

func configure(existing_inventory: Object, context := "outbound") -> void:
	inventory = existing_inventory
	reset(context)

func reset(context: String) -> void:
	work_order_context = "maintenance"; authorized_work_orders = PackedStringArray(); optional_checks = {}; story_progress = {}
	phase = "return" if context == "return" else "outbound"
	flags = {}; completed = {}; evidence = {}; journal = []; legacy_progress = {}
	verification = {}; transactions = {}; elapsed = 0.0
	stocks = {
		"quarters.drawer.1":{"filter_cartridge":2,"scrubber_media":2},
		"quarters.drawer.2":{"nutrient_buffer":2,"coolant_charge":2},
		"quarters.wardrobe":{"engineering_multitool":1,"pressure_sealant":1},
		"cargo.locker":{},
		"cargo.trolley":{"filter_cartridge":2,"coolant_charge":3,"scrubber_media":2,"nutrient_buffer":2},
		"cargo.cylinders":{"coolant_charge":2,"oxygen_reserve":2,"inert_purge":2},
		"engine.locker.1":{}, "engine.locker.2":{}, "shuttle.bundle":{},
	}
	systems = {
		"power":{"essential":70 if phase=="return" else 50,"science":35 if phase=="return" else 40,"reserve":10,"capacity":100,"isolated":false,"calibrated":phase=="return","restored":false},
		"life":{"oxygen":20.9,"co2":0.17 if phase=="return" else 0.08,"airflow":67.0 if phase=="return" else 18.0,"reserve":20.0 if phase=="return" else 60.0,"isolated":false,"serviced":false,"restored":false,"scrubber":0.35 if phase=="return" else 1.0},
		"hydro":{"ec":3.6 if phase=="return" else 2.0,"flow":48.0 if phase=="return" else 25.0,"isolated":false,"aligned":phase=="return","dosed":false,"restored":false},
		"engine":{"health":[1.0,1.0] if phase=="return" else [0.35,1.0],"valves":[1.0,0.35] if phase=="return" else [1.0,1.0],"isolated":[false,false],"load":1.0,"temperature":90.0,"serviced":false},
		"cargo":{"id":"CARGO-A12","manifest_mass":84.0,"measured_mass":86.0 if phase=="return" else 84.0,"location":"staging","tare":false,"weighed":false,"seal_checked":false,"quarantined":false},
		"navigation":{"planned":272.0 if phase=="return" else 92.0,"instrument":281.0 if phase=="return" else 98.0,"correction":0.0,"verified":false},
		"communications":{"report_ready":false,"report_id":"","report_text":"","channel":"local","mode":"standard","sent":false,"acknowledged":false,"signal":45 if phase=="return" else 82},
		"crew":{"fatigue":35.0,"roster":"A1-DUTY","record_checked":false,"confirmed":false},
	}
	_log("context", "POST-INCIDENT RETURN / development scenario; crew outcomes unconfirmed." if phase=="return" else "OUTBOUND / pre-incident ship duties. Review assignments at the bridge table.")
	changed.emit()

func configure_first_watch() -> void:
	# Only the two authored work orders are faulty. Healthy equipment is not
	# marked as a completed procedure and does not demand pointless consumables.
	work_order_context = "first_watch"
	systems.life.airflow = 67.0; systems.life.co2 = 0.07; systems.life.restored = true
	systems.engine.health = [1.0, 1.0]; systems.engine.temperature = 60.0
	systems.navigation.instrument = systems.navigation.planned
	systems.hydro.flow = 0.0
	journal.clear()
	_log("context", "DAY 184 / Asteria-1. Preparing for the Erebos survey. Receive the watch at the bridge planning table.")
	changed.emit()

func _log(id: String, text: String) -> void:
	journal.append({"id":id,"phase":phase,"time":elapsed,"text":text})
	if journal.size()>120: journal.pop_front()

func _has(item: String, count := 1) -> bool:
	return inventory != null and inventory.inventory_count(StringName(item)) >= count

func _consume(item: String, transaction: String) -> bool:
	if transactions.has(transaction): return true
	if inventory == null or not inventory.inventory_take(StringName(item),1): return false
	transactions[transaction] = true
	return true

func _done(id: String) -> void:
	if completed.has(id): return
	completed[id] = true
	_log("complete."+id,"Verified "+id+" procedure; equipment and duty log updated.")
	objective_completed.emit(id)

func prerequisite(task: String) -> String:
	if work_order_context == "first_watch":
		if not flags.get("assigned", false): return "Receive Maya's watch assignment at the bridge planning table. You may inspect live readings first."
		if task in authorized_work_orders: return ""
		if task == "cargo" and completed.has("crew"): return ""
		return "No repair work order here for this watch. Inspect routine readings, or follow the primary objective."
	if not flags.get("assigned",false): return "Review and accept duties at the bridge planning table first."
	var requirements := {"crew":[],"cargo":["crew"],"power":["cargo"],"life":["power"],"hydro":["life"],"engine":["power","cargo"],"navigation":["crew","engine"],"communications":["crew","cargo","power","life","hydro","engine","navigation"]}
	for needed in requirements.get(task,[]):
		if not completed.has(needed): return "First verify the "+str(needed)+" duty. See the planning table for the next action."
	return ""

func narrative(room: String) -> String:
	if work_order_context == "first_watch":
		return {"bridge": "DAY 184 aboard Asteria-1, preparing for the Erebos survey. Maya's watch covers service power and nutrient delivery; other routine work is optional.", "hydro": "Amara Okoye, MED, is tending the grow beds. Compare healthy pump capacity and normal reservoir chemistry with actual delivery and the science/service supply.", "engine": "Both cooling loops are operating normally. No cooling repair is assigned on this watch.", "life": "Oxygen, carbon-dioxide removal and airflow are in their routine ranges. No filter replacement is assigned on this watch."}.get(room, "Routine watch observation. Personal belongings remain private; shared service stores are authorized.")
	var outbound := {
		"bridge":"Asteria-1 is bound for the Erebos survey and autonomous ore-extraction trials. Before filing the duty report, compare the planned route with the helm instruments and confirm the relay conditions.",
		"quarters":"Duty roster: "+", ".join(CATALOG.CREW)+". Compare the watch entries with the expected duty activity. Shared maintenance stores are authorised for this work; personal possessions remain private.",
		"cargo":"Routine stores are listed as CARGO-A12. Check identity, exterior seal and mass before releasing the load. Labelled coolant, oxygen and inert-gas cylinders have different service uses.",
		"engine":"Engineering watch: compare both cooling loops before servicing a component. A weak pump and a restricted valve can both reduce flow, but their pressure readings differ.",
		"power":"Thura learned to diagnose before repairing. Preserve essential supply while testing the auxiliary circuit; a science-load deferral must not cut life support.",
		"life":"Routine oxygen and CO2 readings are different measurements. A normal oxygen level does not prove that airflow or CO2 removal is adequate.",
		"hydro":"Amara's existing hydroponics dialogue and inspection jobs remain available. Record reservoir and plant observations before changing the manifold.",
		"shuttle":"This bundle is ship stores. The unfinished shuttle area is not a required workstation for these duties.",
	}
	if phase=="outbound": return outbound.get(room,"Routine ship record.")
	var returning := {
		"bridge":"After the Erebos incident, the return flight reference disagrees with the planned Earth-bound heading. Correct the measured discrepancy, then send confirmed ship conditions over the weakened relay.",
		"quarters":"The available watch record predates the incident. The old duty roster does not confirm where the crew are now. Record the missing check-in confirmation as unresolved; the record supports no further conclusion.",
		"cargo":"The recovered-material load has a gap in its custody record. Compare the exterior seal with the measured mass, then quarantine the unopened container and preserve the discrepancy in the report.",
		"engine":"Reduced output buys a safe cooling-service window. It temporarily limits available thrust until restoration, so the bridge must verify the revised flight readings.",
		"power":"The science circuit's requested load exceeds the allocation. Retain essential services and record the nonessential work deferred while restoring the reserve margin.",
		"life":"Compare the archived filter result with current gas readings. Airflow is normal but CO2 removal is poor; repeating the outbound filter replacement is not the correct diagnosis.",
		"hydro":"Amara's observation records a reservoir/flow difference after the incident. It is evidence to compare with power and pump logs, not proof of a new property or weakness of Echo.",
		"shuttle":"Ship-store custody remains active during the return watch. This bundle can hold service spares without opening the quarantined recovered-material load.",
	}
	return returning.get(room,"Post-incident record; details not confirmed by existing canon.")

func hydro_environment() -> Dictionary:
	# Existing diagnostic observations, shared by prose and instrument widgets.
	# These are simulation constants, not UI-only successful readings.
	return {"pump_capacity":100.0,"humidity":62.0}

func readings(room: String) -> String:
	match room:
		"engine":
			var e: Dictionary=systems.engine
			return "Temperature %.1f C (verify <= 65) | output %.0f%%\nLoop 1: pump %.0f%% / valve %.0f%% / flow %.0f%%\nLoop 2: pump %.0f%% / valve %.0f%% / flow %.0f%%\nUpstream/downstream pressure: %s\nSafe verification needs restored circulation and a stable 6-second observation." % [e.temperature,e.load*100,e.health[0]*100,e.valves[0]*100,engine_flow(0)*100,e.health[1]*100,e.valves[1]*100,engine_flow(1)*100,"3.2 / 0.8 bar: restriction across valve 2" if phase=="return" and e.valves[1]<0.9 else "1.1 / 1.0 bar: low pump delivery" if e.health[0]<0.9 else "2.2 / 2.0 bar: normal"]
		"power":
			var p: Dictionary=systems.power
			if phase=="outbound":
				return "Plan: essential %d%% / science %d%% / reserve %d%% of auxiliary output\nWhile the service circuit is isolated: essential >= %d%%, reserve >= %d%%.\nBank B synchronized: %s | service isolation: %s | circuit live: %s\nEssential bus: %d V | science/service bus: %d V (feeds the irrigation supply valve, navigation correction and transmission)." % [p.essential,p.science,p.reserve,POWER_MIN.essential,POWER_MIN.reserve,str(p.calibrated),str(p.isolated),str(p.restored and not p.isolated),24 if bus_powered("essential") else 0,24 if bus_powered("science") else 0]
			return "Essential %d + science %d + reserve %d = %d / %d units\nEssential minimum: 70. Science may be deferred, never essential life support.\nAuxiliary calibration: %s | service isolation: %s\nEssential bus: %d V | science/service bus: %d V (feeds irrigation, navigation correction and transmission)." % [p.essential,p.science,p.reserve,p.essential+p.science+p.reserve,p.capacity,str(p.calibrated),str(p.isolated),24 if bus_powered("essential") else 0,24 if bus_powered("science") else 0]
		"life":
			var l: Dictionary=systems.life
			return "Oxygen %.1f%% (20-22) | CO2 %.3f%% (<= 0.10)\nAirflow %.0f%% (62-72) | scrubber performance %.0f%%\nOxygen reserve %.0f%% (routine issue threshold 50%%). Topping up reserve does not fix CO2 removal or airflow.\nReplacement filter: FILTER-A, scrubber medium: SCRUB-A. O2-01 is not coolant." % [l.oxygen,l.co2,l.airflow,l.scrubber*100,l.reserve]
		"hydro":
			var h: Dictionary=systems.hydro
			var environment := hydro_environment()
			var condition := "Recovering with normal irrigation" if h.flow>=90 and h.ec>=1.8 and h.ec<=2.4 else "Reservoir imbalance / wilt warning" if h.ec>2.4 else "Dry root-zone warning / inadequate delivery"
			return "Reservoir EC %.2f (1.8-2.4) | delivery %.0f%% (>= 90)\nPump capacity %.0f%% / healthy | bay humidity %.0f%% (55-70)\nPlant condition: %s\nPump service isolation: %s | manifold verified: %s\nOne BUFFER-A dose reduces the simulated EC reading by 1.6. Plant condition recovers only with restored delivery." % [h.ec,h.flow,environment.pump_capacity,environment.humidity,condition,str(h.isolated),str(h.aligned)]
		"cargo":
			var c: Dictionary=systems.cargo
			return "Manifest %s | expected %.1f kg (+/- 0.5)\nScale: %s | measured: %s | load position: %s\nCOOL-02: sealed service coolant; O2-01: oxygen; N2-03: inert purge. These cylinders are not interchangeable." % [c.id,c.manifest_mass,"zeroed" if c.tare else "not zeroed",str(c.measured_mass)+" kg" if c.weighed else "not measured",c.location]
		"bridge":
			var n: Dictionary=systems.navigation
			var c: Dictionary=systems.communications
			return ("Route reference %.1f deg | instrument %.1f deg | correction %.1f deg\nCorrected heading %.1f deg; tolerance +/- 0.2 deg. Destination context: %s.\nTransmission signal %d%% | %s / %s | acknowledgement: %s" % [n.planned,n.instrument,n.correction,n.instrument+n.correction,"Earth return" if phase=="return" else "Erebos expedition",c.signal,c.channel,c.mode,str(c.acknowledged)])+("\n\nPREPARED REPORT / "+c.report_id+"\n"+c.report_text if c.report_ready else "")
		"quarters": return "Roster A1-DUTY | log reviewed: %s | comparison recorded: %s\nFatigue %.0f%%. Rest reduces fatigue only; it never advances the chapter or clears duties." % [str(flags.get("crew.log",false)),str(systems.crew.confirmed),systems.crew.fatigue]
	return "Ship store access; no unfinished-room objective is required."

func engine_flow(index: int) -> float:
	var e: Dictionary=systems.engine
	return 0.0 if e.isolated[index] else float(e.health[index])*float(e.valves[index])

func bus_powered(bus: String) -> bool:
	var p: Dictionary=systems.power
	if phase=="outbound":
		# Isolating the service circuit never drops essential power (design: "Essential
		# power is still on"); the plan minimums gate the bank B work instead.
		if bus=="essential": return true
		return bus_powered("essential") and p.calibrated and p.restored and not p.isolated and p.science>=10
	if bus=="essential": return p.essential>=70
	return bus_powered("essential") and p.calibrated and p.restored and not p.isolated and p.science>=10 and p.essential+p.science+p.reserve<=p.capacity

func tick(delta: float) -> void:
	elapsed += maxf(delta,0.0)
	if work_order_context == "first_watch" and not systems.hydro.restored:
		systems.hydro.flow = 30.0
	if systems.hydro.restored:
		systems.hydro.flow=0.0 if systems.hydro.isolated or not bus_powered("science") else 96.0 if systems.hydro.aligned and systems.hydro.ec>=1.8 and systems.hydro.ec<=2.4 else 32.0
	var e: Dictionary=systems.engine
	var minimum := minf(engine_flow(0),engine_flow(1))
	var target := 42.0+18.0*float(e.load)+45.0*(1.0-minimum)
	e.temperature = move_toward(float(e.temperature),target,maxf(delta,0.0)*7.0)
	for task in ["engine","power","life","hydro"]:
		var stable := false
		match task:
			"engine": stable=e.serviced and minimum>=0.9 and e.temperature<=65.0
			"power": stable=systems.power.restored and systems.power.calibrated and not systems.power.isolated and (phase=="outbound" or (systems.power.essential>=70 and systems.power.essential+systems.power.science+systems.power.reserve<=systems.power.capacity))
			"life": stable=systems.life.restored and not systems.life.isolated and systems.life.oxygen>=20.0 and systems.life.oxygen<=22.0 and systems.life.airflow>=62 and systems.life.airflow<=72 and systems.life.co2<=0.1
			"hydro": stable=systems.hydro.restored and not systems.hydro.isolated and systems.hydro.flow>=90 and systems.hydro.ec>=1.8 and systems.hydro.ec<=2.4
		verification[task] = float(verification.get(task,0.0))+delta if stable else 0.0
	if systems.communications.sent and not systems.communications.acknowledged:
		verification["ack"] = float(verification.get("ack",0.0))+delta
		if verification.ack>=3.0:
			systems.communications.acknowledged=true
			_log("communications.ack","Earth relay acknowledged "+str(systems.communications.report_id)+"; transmitted measurements retained with the duty record.")
			_done("communications");changed.emit()

func _action(id: String, title: String, allowed := true, reason := "", options: Array = []) -> Dictionary:
	return {"id":id,"title":title,"enabled":allowed,"reason":reason if not allowed else "","options":options}

func _gated(id: String, title: String, task: String, condition := true, reason := "", options: Array = []) -> Dictionary:
	var prerequisite_reason := prerequisite(task)
	if work_order_context == "first_watch" and (id == "observe" or (id == "diagnose" and task == "hydro" and "hydro.inspect" in authorized_work_orders)):
		prerequisite_reason = ""
	if task in ["navigation","communications"] and prerequisite_reason.is_empty() and not bus_powered("science"): prerequisite_reason="Science/service bus is unavailable. Restore a safe allocation at the power breaker; essential systems remain fed."
	if completed.has(task): prerequisite_reason="This procedure is already verified. Monitor its readings or use the safe restore control; no repeat consumption/reward is needed."
	return _action(id,title,prerequisite_reason.is_empty() and condition,prerequisite_reason if not prerequisite_reason.is_empty() else reason,options)

func actions(prop_id: String) -> Array:
	var def: Dictionary=CATALOG.definition(prop_id)
	if def.is_empty(): return []
	var room: String=def.room;var kind: String=def.kind
	if kind in ["storage_hide","cargo_hide"]:
		return [_action("hide","Enter concealment (H exits safely)")]
	var result: Array=[_action("record","Read and record this phase's crew/system note")]
	if kind=="planning":
		if work_order_context == "first_watch":
			result.append(_action("story:briefing", "Speak to Maya / watch assignment"))
			result.append(_action("story:summary", "Review the measured watch summary", story_progress.get("can_submit",false), "Verify the two assigned repairs and report back to Amara first. A completed watch may be reviewed in Records."))
			return result
		result.append(_action("assign","Accept ship-side duties",not flags.get("assigned",false),"Assignments already accepted; progress is retained."))
		result.append(_action("file_report","File the verified ship-side report",completed.size()==8 and not flags.get("report_filed",false),"Verify all eight listed procedures and obtain the transmission acknowledgement first."))
		return result
	if kind=="storage" or prop_id=="cargo.trolley":
		for item in stocks.get(prop_id,{}):
			result.append(_action("take:"+item,"Retrieve "+item+" (stock "+str(stocks[prop_id][item])+")",stocks[prop_id][item]>0,"Stock empty; return a carried spare or use the cargo recovery issue."))
		for item in ["filter_cartridge","scrubber_media","coolant_charge","nutrient_buffer","oxygen_reserve","inert_purge","engineering_multitool","pressure_sealant"]:
			if _has(item): result.append(_action("store:"+item,"Store carried "+item))
		if prop_id=="cargo.trolley": result.append(_action("recover_supplies","Issue a logged replacement duty kit",flags.get("assigned",false),"Review bridge assignments first."))
	if kind=="chair": result.append(_action("chair","Inspect station seat / operator access"))
	if kind=="rest": result.append(_action("rest","Take a short rest without advancing the story",(bus_powered("essential") and systems.life.airflow>=62 and systems.life.co2<=0.1 and engine_flow(0)>=0.9 and engine_flow(1)>=0.9 and systems.engine.temperature<=65) if work_order_context=="first_watch" else not flags.get("assigned",false) or (completed.has("power") and completed.has("life") and completed.has("engine")),"Restore essential power, healthy air and cooling before resting."))
	if work_order_context == "first_watch" and optional_checks.get("enabled", false):
		var optional_id: String = "amara_nutrient_pump" if prop_id == "hydro.pump" else "amara_seedling_sensor" if prop_id == "hydro.seedlings" else ""
		if not optional_id.is_empty(): result.append(_action("optional:"+optional_id, "OPTIONAL / record the pump inspection" if prop_id=="hydro.pump" else "OPTIONAL / check the seedling sensor", not optional_checks.get(optional_id,false), "This optional check is already recorded."))
	if kind=="crew":
		result.append(_gated("roster","Compare duty roster and expected activity","crew"))
		result.append(_gated("crew_log","Review authorised watch/check-in records","crew",flags.get("crew.roster",false),"Read the duty roster first."))
		var conclusions := [["records_match","The routine records match the expected watch"],["unconfirmed","The old roster does not confirm present crew whereabouts"]]
		if phase=="outbound": conclusions = [["all_checked_in","Everyone on the roster has checked in."],["one_missing","One expected check-in is missing."],["not_aboard","Someone on the roster isn't aboard."]]
		result.append(_gated("crew_compare","Record the supported check-in conclusion","crew",flags.get("crew.log",false),"Compare the roster with the available records first.",conclusions))
	if kind=="cargo":
		result.append(_gated("manifest","Read container ID, manifest and seal record","cargo"))
		result.append(_gated("seal","Inspect the exterior seal without opening the load","cargo",flags.get("cargo.manifest",false),"Read the manifest first."))
		if prop_id=="cargo.scale":
			result.append(_gated("tare","Zero empty scale and check the 20 kg reference","cargo",systems.cargo.location=="staging","Return the load to staging with the pallet mover before zeroing."))
			result.append(_gated("weigh","Read the settled load mass","cargo",systems.cargo.location=="scale" and systems.cargo.tare,"Zero the empty scale, then bring the identified load onto it using the mover."))
			result.append(_gated("cargo_decide","Record the inspection disposition","cargo",systems.cargo.weighed and systems.cargo.seal_checked,"Obtain mass and seal readings before deciding.",[["accept","Accept: ID matches and mass is within tolerance"],["quarantine","Quarantine unopened: record the discrepancy"]]))
	if kind=="transfer":
		result.append(_gated("move_load","Transfer identified load to scale / staging","cargo",flags.get("cargo.manifest",false),"Confirm the manifest identity before transferring.",[["scale","Secured transfer to inspection scale"],["staging","Return to marked staging"]]))
		if prop_id=="cargo.trolley": result.append(_action("transfer_kit","Issue one COOL-02 kit from the trolley for engine service",completed.has("cargo") and stocks["cargo.trolley"].get("coolant_charge",0)>0,"Inspect cargo first; a COOL-02 kit must remain in the trolley drawer."))
	if kind=="cylinders":
		result.append(_action("cylinder","Select and retrieve the labelled service cylinder",flags.get("assigned",false),"Review bridge assignments first.",[["coolant_charge","COOL-02 / sealed coolant service charge"],["oxygen_reserve","O2-01 / oxygen reserve"],["inert_purge","N2-03 / inert purge gas"]]))
	if room in ["power","life","hydro","engine"]:
		var task: String=room
		result.append(_gated("observe","Capture the live readings and compare operating ranges",task))
		var options := {
			"power":[["cell","Auxiliary bank not synchronized"],["load","Nonessential load exceeds allocation"],["oxygen","Oxygen supply fault"]],
			"life":[["airflow","Restricted airflow / filter"],["scrubber","Poor CO2 removal with normal airflow"],["oxygen","Inadequate oxygen supply"]],
			"hydro":[["restriction","Manifold restricts delivery; reservoir EC is normal"],["balance","Reservoir imbalance with a healthy pump"],["pump","Pump mechanical failure"]],
			"engine":[["pump","Low pump delivery / coolant service needed"],["valve","Restriction across valve 2; pump remains healthy"],["load","Excess load alone; both loops healthy"]],
		}
		result.append(_gated("diagnose","Record a diagnosis supported by those readings",task,flags.get(task+".observed",false),"Capture readings first.",options[task]))
		if room=="power":
			result.append(_gated("isolate","Isolate the auxiliary/science service circuit (essential stays live)",task,flags.get("power.diagnosed",false),"Diagnose the cell or allocation problem first."))
			if phase=="outbound":
				result.append(_gated("allocation","Choose the auxiliary power plan",task,systems.power.isolated,"Isolate the service circuit first.",[["standard","Standard: 50 essential / 40 science / 10 reserve"],["science","Science first: 45 / 45 / 10"],["repair","Repair hold: 65 / 15 / 20"]]))
				result.append(_gated("sync","Synchronize bank B with banks A and C",task,systems.power.isolated and flags.get("power.allocated",false) and _has("engineering_multitool"),"Isolate the service circuit, choose a safe power plan and carry the engineering multitool."))
			else:
				result.append(_gated("allocation","Configure the circuit allocation",task,systems.power.isolated,"Isolate the nonessential service circuit first.",[["balanced","70 essential + 20 science + 10 reserve"],["reserve","70 essential + 10 science + 20 reserve"],["overload","70 essential + 35 science + 10 reserve"]]))
			if prop_id=="power.cell": result.append(_gated("legacy:auxiliary_power","Synchronize the existing auxiliary-power banks",task,systems.power.isolated and _has("engineering_multitool"),"Isolate the service circuit and carry the engineering multitool."))
			result.append(_action("restore","Restore circuit / cancel isolation safely"))
		if room=="life":
			if prop_id=="life.oxygen": result.append(_action("oxygen_reserve","Swap a labelled O2-01 reserve bank (optional)",flags.get("life.diagnosed",false) and systems.life.reserve<50 and _has("oxygen_reserve"),"Read the gas diagnosis first. O2 reserve is only needed below 50%; retrieve O2-01 from the cargo cylinder rack. It does not repair airflow or CO2 removal."))
			result.append(_gated("isolate","Isolate the affected service housing; reserve air remains live",task,flags.get("life.diagnosed",false),"Distinguish oxygen, CO2 removal and airflow first."))
			if prop_id=="life.filter" and phase=="outbound": result.append(_gated("legacy:air_filter","Open the existing filter replacement controls",task,systems.life.isolated and _has("filter_cartridge"),"Isolate the housing and retrieve FILTER-A from the shared quarters drawers or maintenance trolley."))
			if prop_id=="life.scrubber" and phase=="return": result.append(_gated("scrubber_service","Replace SCRUB-A medium in the isolated scrubber",task,systems.life.isolated and _has("scrubber_media") and _has("engineering_multitool"),"Isolate the scrubber; obtain SCRUB-A and the multitool. A new filter will not fix this fault."))
			result.append(_action("restore","Restore airflow / cancel service isolation safely"))
		if room=="hydro":
			result.append(_gated("isolate","Stop nutrient delivery and isolate the dosing/manifold access",task,flags.get("hydro.diagnosed",false),"Compare pump, reservoir and flow readings first."))
			if prop_id=="hydro.console" and phase=="outbound": result.append(_gated("legacy:nutrient_flow","Operate the existing labelled manifold valves",task,systems.hydro.isolated and _has("engineering_multitool"),"Isolate nutrient delivery and carry the multitool."))
			if phase=="outbound": result.append(_gated("align","Set the three manifold valves to their marks",task,systems.hydro.isolated and _has("engineering_multitool"),"Close the supply valve and carry the engineering multitool."))
			if phase=="return":
				var dose: Dictionary=_gated("dose","Calculate and add BUFFER-A dilution",task,systems.hydro.isolated and _has("nutrient_buffer"),"Isolate dosing and retrieve BUFFER-A from the shared quarters drawer or maintenance trolley.")
				dose["number"]={"min":0.25,"max":2.0,"step":0.25,"value":1.0,"suffix":" dose"};result.append(dose)
			result.append(_action("restore","Restore irrigation / cancel dosing isolation safely"))
		if room=="engine":
			var loop_index := 1 if phase=="return" else 0
			var service_id := "engine.valve.2" if phase=="return" else "engine.pump.1"
			result.append(_gated("reduce_load","Request 60% output for the maintenance window",task,flags.get("engine.diagnosed",false),"Diagnose before reducing available thrust."))
			if prop_id==service_id:
				result.append(_gated("isolate","Isolate this diagnosed cooling-loop component",task,flags.get("engine.diagnosed",false) and systems.engine.load<=0.6,"Diagnose first and reduce output to 60%."))
				result.append(_gated("engine_service","Open valve 2 fully" if phase=="return" else "Service pump 1 using COOL-02",task,systems.engine.isolated[loop_index] and _has("engineering_multitool") and (phase=="return" or _has("coolant_charge")),"Isolate the correct component. Carry the multitool and, for pump service, COOL-02 coolant."))
				result.append(_action("restore","Restore this loop / cancel isolation safely"))
			result.append(_action("resume_output","Restore nominal output after cooling verification",completed.has("engine"),"Verify cooling before requesting nominal thrust."))
		if not completed.has(task):
			var needed := verify_seconds(task)
			result.append(_gated("verify","Observe and verify the recovered system",task,float(verification.get(task,0.0))>=needed,"Restore the system and wait for three steady readings. Current stable time: %.1f of %.1f s." % [float(verification.get(task,0.0)), needed]))
	if kind=="turbine": result.append(_action("turbine","Inspect this turbine's assigned cooling loop and output"))
	if kind=="navigation":
		result.append(_gated("route","Compare planned route and independent instrument reading","navigation"))
		var correct: Dictionary=_gated("correction","Configure instrument reference correction","navigation",flags.get("navigation.compared",false),"Read both route and instrument readings before correcting.")
		correct["number"]={"min":-20.0,"max":20.0,"step":0.1,"value":systems.navigation.correction,"suffix":" deg"}; result.append(correct)
		result.append(_gated("nav_verify","Verify corrected heading against the planned reference","navigation",flags.get("navigation.compared",false),"Compare readings and apply an appropriate correction first."))
	if kind=="communications":
		result.append(_gated("prepare_report","Prepare a report containing verified duties and phase-appropriate evidence","communications",not systems.communications.sent,"The report is already in transit; wait for its acknowledgement."))
		result.append(_gated("channel","Check signal and select the transmission protocol","communications",systems.communications.report_ready and not systems.communications.sent,"Prepare the verified report first; a packet already in transit retains its protocol.",[["standard","Earth relay / standard packet (requires >= 60% signal)"],["robust","Earth relay / repeated critical packet (requires >= 35%)"],["local","Local crew channel / no Earth acknowledgement"]]))
		result.append(_gated("transmit","Transmit and monitor acknowledgement","communications",systems.communications.report_ready and not systems.communications.sent,"Prepare the report and choose a viable link. A failed attempt preserves the report."))
	return result

func verify_seconds(task: String) -> float:
	return float(VERIFY_SECONDS.get(task, 6.0)) if phase=="outbound" else 6.0

func act(prop_id: String, action_id: String, value: Variant = null) -> Dictionary:
	if inventory==null: return _reply(false,"This station's ship inventory is no longer active. Reopen it in the current ship scene.")
	var available: Array=actions(prop_id)
	var chosen: Dictionary={}
	for action in available:
		if action.id==action_id: chosen=action;break
	if chosen.is_empty(): return _reply(false,"That action does not belong to this prop.")
	if not chosen.enabled: return _reply(false,chosen.reason)
	var def: Dictionary=CATALOG.definition(prop_id)
	var room: String=def.room
	if not chosen.options.is_empty() and not chosen.options.any(func(option: Array): return option[0]==value): return _reply(false,"Choose one of the labelled operating options.")
	if chosen.has("number") and (not (value is float or value is int) or not is_finite(float(value)) or float(value)<chosen.number.min or float(value)>chosen.number.max): return _reply(false,"The setting is outside this control's allowed range.")
	var message := ""
	if action_id.begins_with("story:"): return {"ok":true,"event":"story","action":action_id}
	if action_id.begins_with("optional:"): return {"ok":true,"event":"optional","task":action_id.trim_prefix("optional:")}
	if action_id.begins_with("take:"):
		var item := action_id.trim_prefix("take:")
		if not inventory.inventory_put(StringName(item),1): return _reply(false,"Inventory full. Store an item before retrieving a spare; nothing was removed.")
		stocks[prop_id][item]-=1; message="Retrieved one "+item+" into your existing inventory."
	elif action_id.begins_with("store:"):
		var item := action_id.trim_prefix("store:")
		if not inventory.inventory_take(StringName(item),1): return _reply(false,"The carried item is no longer available.")
		if not stocks.has(prop_id): stocks[prop_id]={}
		stocks[prop_id][item]=int(stocks[prop_id].get(item,0))+1
		message="Stored one "+item+"; retrieval remains available here."
	else:
		match action_id:
			"record":
				evidence[phase+"."+room]=narrative(room)
				message=narrative(room)
			"assign": flags.assigned=true;message="Duties accepted. Start with the authorised crew records, then cargo inspection. The planning table lists prerequisites and current objectives."
			"file_report": flags.report_filed=true;message="Verified ship-side report filed. The duty log retains the measurements, corrections and unresolved records from this watch."
			"chair": message="Operator seat and access inspected. Operate the adjacent console while standing."
			"rest": systems.crew.fatigue=0.0;message="Short rest complete; fatigue recovered. Duty assignments and unresolved records remain active."
			"hide": return {"ok":true,"event":"hide","message":"Enter the marked concealment space. Press H to leave safely."}
			"roster": flags["crew.roster"]=true;message="Roster A1-DUTY read. Expected activity is a logged duty watch, not proof of present location. Compare the authorised check-in record."
			"crew_log":
				flags["crew.log"]=true
				message="Six crew on the watch roster, five check-ins received. Mateo Ruiz has not checked in this watch. Record that comparison." if phase=="outbound" else "The available watch entry predates the incident. Current check-in confirmation is absent; record present whereabouts as unconfirmed."
			"crew_compare":
				if value!=("unconfirmed" if phase=="return" else "one_missing"): return _reply(false,"That conclusion is not supported by the records. Review the roster and watch-entry dates." if phase=="return" else ("Not supported: Mateo Ruiz has no check-in." if value=="all_checked_in" else "Not supported: these records show check-ins, not who is aboard."))
				systems.crew.confirmed=true;_done("crew");message="Crew check-in comparison recorded with its evidence limits."
			"manifest": flags["cargo.manifest"]=true;message="CARGO-A12: expected 84.0 kg +/- 0.5. Use only the identified load. Compare the exterior seal and actual mass."
			"seal":
				systems.cargo.seal_checked=true
				message="Routine seal number and exterior condition match the manifest." if phase=="outbound" else "The post-incident custody log has a seal-record gap. Keep the recovered-material container unopened and record the uncertainty."
			"tare": systems.cargo.tare=true;message="Empty scale zeroed; 20 kg reference reads 20.0. Bring the identified load from staging to the scale."
			"move_load":
				systems.cargo.location=value
				systems.cargo.weighed=false
				message="Secured transfer recorded: identified load CARGO-A12 is now at "+str(value)+". Confirm its settled mass at the scale before recording a disposition."
			"weigh": systems.cargo.weighed=true;message="Settled reading %.1f kg. Compare with 84.0 +/- 0.5 and the seal record before releasing the load." % systems.cargo.measured_mass
			"cargo_decide":
				var discrepant: bool=absf(float(systems.cargo.measured_mass)-float(systems.cargo.manifest_mass))>0.5 or phase=="return"
				if value!=("quarantine" if discrepant else "accept"): return _reply(false,"The disposition contradicts the mass/seal readings. No container was opened or released.")
				systems.cargo.quarantined=discrepant;systems.cargo.location="quarantine" if discrepant else "secured"
				_done("cargo");message="Inspection disposition and custody location recorded. Shared maintenance supplies are available."
			"cylinder":
				var item: String=str(value)
				if int(stocks["cargo.cylinders"].get(item,0))<=0: return _reply(false,"This labelled cylinder has no remaining issue. Return the carried one or use the cargo replacement kit for service supplies.")
				if not inventory.inventory_put(StringName(item),1): return _reply(false,"Inventory full. The cylinder remains secured in its rack.")
				stocks["cargo.cylinders"][item]-=1;message="Issued labelled "+item+". Its identity is retained in inventory; other contents cannot substitute for it."
			"transfer_kit":
				if not inventory.inventory_put(&"coolant_charge",1): return _reply(false,"Inventory full. The sealed COOL-02 kit remains in the trolley drawer.")
				stocks["cargo.trolley"].coolant_charge-=1
				message="One sealed COOL-02 kit issued from the trolley drawer into the carried inventory for engine service."
			"recover_supplies":
				var issued := false
				for item in ["filter_cartridge","coolant_charge","scrubber_media","nutrient_buffer"]:
					var total: int=inventory.inventory_count(StringName(item))
					for stock in stocks.values(): total+=int(stock.get(item,0))
					if total<2:
						stocks["cargo.trolley"][item]=int(stocks["cargo.trolley"].get(item,0))+2-total;issued=true
				message="Logged replacement stock issued in the maintenance trolley drawer." if issued else "Existing supplies remain in inventory/storage. No extra stock issued; retrieve or transfer those first."
			"observe": flags[room+".observed"]=true;message=readings(room)
			"diagnose":
				var expected: String={"power":"load" if phase=="return" else "cell","life":"scrubber" if phase=="return" else "airflow","hydro":"balance" if phase=="return" else "restriction","engine":"valve" if phase=="return" else "pump"}[room]
				if value!=expected: return _reply(false,"The readings do not support that diagnosis. Compare the labelled ranges and component measurements; nothing was consumed or isolated.")
				flags[room+".diagnosed"]=true;message="Diagnosis supported by measurements. Obtain the correct supply/tool, isolate access, service, restore, then verify."
			"isolate":
				if room=="engine": systems.engine.isolated[1 if phase=="return" else 0]=true
				else: systems[room].isolated=true
				message="Service access isolated. Essential reserve systems stay online. Closing this panel leaves isolation recorded; Restore is always available here."
			"allocation" when POWER_PLANS.has(str(value)):
				var plan: Array=POWER_PLANS[str(value)]
				if plan[0] < POWER_MIN.essential or plan[2] < POWER_MIN.reserve: return _reply(false,"That plan would drop %s power below its minimum while the service circuit is isolated." % ("essential" if plan[0] < POWER_MIN.essential else "reserve"))
				systems.power.essential=plan[0];systems.power.science=plan[1];systems.power.reserve=plan[2]
				flags["power.allocated"]=true;message="%s plan applied. Essential and reserve power stay above their minimums while bank B is serviced." % {"standard":"Standard","science":"Science-first","repair":"Repair hold"}[str(value)]
			"sync":
				systems.power.calibrated=true;flags["legacy.auxiliary_power"]=true
				message="Bank B synchronized with banks A and C. The service circuit is still isolated; restore it next."
			"align":
				systems.hydro.aligned=true;flags["legacy.nutrient_flow"]=true
				message="Manifold valves set to their marks. The supply is still closed; reopen it next."
			"allocation":
				if value=="overload": return _reply(false,"Requested total 115 exceeds capacity 100. Essential services remain untouched; select a safe allocation or restore/cancel.")
				systems.power.essential=70;systems.power.science=10 if value=="reserve" else 20;systems.power.reserve=20 if value=="reserve" else 10
				flags["power.allocated"]=true;message="Allocation applied to connected equipment. Nonessential science load is deferred; essential supply stays at 70."
			"scrubber_service":
				if not _consume("scrubber_media",phase+".life.service"): return _reply(false,"SCRUB-A is no longer carried. Retrieve it; no progress was lost.")
				systems.life.scrubber=1.0;systems.life.serviced=true;message="SCRUB-A medium replaced. Restore circulation and compare CO2 with the archived filter/airflow record."
			"oxygen_reserve":
				if not _consume("oxygen_reserve",phase+".life.reserve"): return _reply(false,"The labelled O2-01 reserve cylinder is not carried; other cylinder contents cannot substitute.")
				systems.life.reserve=100.0;message="Sealed O2-01 reserve bank swapped while the main line remains fed. Reserve charge restored; CO2 and filter readings are unchanged."
			"dose":
				var predicted: float=float(systems.hydro.ec)-float(value)*1.6
				if predicted<1.8 or predicted>2.4: return _reply(false,"Calculated EC %.2f is outside 1.8-2.4. Adjust the dose before dispensing; BUFFER-A was not consumed." % predicted)
				if not _consume("nutrient_buffer",phase+".hydro.service"): return _reply(false,"Retrieve BUFFER-A first; the reservoir was not changed.")
				systems.hydro.ec=predicted;systems.hydro.dosed=true;message="Measured buffer dilution applied. Restore circulation and observe actual delivery recovery."
			"reduce_load": systems.engine.load=0.6;message="Output reduced to 60%. Available thrust is limited during maintenance; life support and essential power remain supplied."
			"engine_service":
				if phase=="outbound":
					if not _consume("coolant_charge",phase+".engine.service"): return _reply(false,"COOL-02 is required; oxygen and inert gas cannot substitute. Retrieve the coolant charge.")
					systems.engine.health[0]=1.0
				else: systems.engine.valves[1]=1.0
				systems.engine.serviced=true;message="Diagnosed component serviced. Restore the loop, then watch temperature, pressure and flow recover together."
			"restore":
				if room=="engine": systems.engine.isolated[1 if phase=="return" else 0]=false
				else:
					systems[room].isolated=false
					systems[room].restored=true
					if room=="life" and systems.life.serviced:
						systems.life.airflow=67.0;systems.life.co2=0.07
					if room=="hydro" and systems.hydro.aligned and (phase=="outbound" or systems.hydro.dosed): systems.hydro.flow=96.0
				message="Service isolation cancelled/restored. Observe the readings: restoration alone does not count as a verified repair."
			"verify":
				if room=="power" and not flags.get("power.allocated",false): return _reply(false,"Record an explicit safe circuit allocation before signing off the distribution work order.")
				_done(room);message="Healthy operating values sustained and verification recorded. Dependent objectives are now available."
			"resume_output": systems.engine.load=1.0;message="Cooling verified; nominal output restored. The temporary thrust restriction is removed."
			"turbine":
				var number: int=int(prop_id.get_slice(".",2))
				message="Turbine %d / cooling loop %d / output %.0f%% / flow %.0f%% / %.1f C. This is an independently identified machine." % [number,1 if number in [1,3] else 2,systems.engine.load*100,engine_flow(0 if number in [1,3] else 1)*100,systems.engine.temperature]
			"route": flags["navigation.compared"]=true;message="Compare planned and instrument headings. Correction is planned minus instrument; no ship layout or map image is needed."
			"correction": systems.navigation.correction=float(value);message="Instrument reference correction applied; compare the resulting heading with the plan before verifying."
			"nav_verify":
				if absf(float(systems.navigation.instrument)+float(systems.navigation.correction)-float(systems.navigation.planned))>0.2: return _reply(false,"Corrected heading remains outside +/- 0.2 deg. Review both readings and adjust the signed correction.")
				systems.navigation.verified=true;_done("navigation");message="Corrected flight reference verified against the plan. The report now includes the discrepancy and correction."
			"prepare_report":
				var c: Dictionary=systems.communications
				c.report_id="A1-DUTY-"+phase.to_upper()
				c.report_text="WATCH / "+phase.to_upper()+"\nCrew records: "+("present whereabouts unconfirmed" if phase=="return" else "one expected check-in missing (Mateo Ruiz)")+"\n"
				for area in ["cargo","power","life","hydro","engine"]: c.report_text+="\n"+str(area).to_upper()+"\n"+readings(area)+"\n"
				c.report_text+="\nVerified heading %.1f deg (correction %.1f).\nRecorded phase evidence:\n" % [systems.navigation.instrument+systems.navigation.correction,systems.navigation.correction]
				for key in evidence:
					if str(key).begins_with(phase+"."): c.report_text+=str(evidence[key])+"\n"
				c.report_ready=true;message="Prepared "+str(c.report_id)+" from the verified measurements and this phase's evidence. Review the retained report preview before transmitting."
			"channel": systems.communications.channel="local" if value=="local" else "earth";systems.communications.mode="robust" if value=="robust" else "standard";message="Transmission conditions checked. Standard needs 60% signal; the repeated critical packet needs 35%. A local channel cannot produce an Earth acknowledgement."
			"transmit":
				var c: Dictionary=systems.communications
				var minimum: int=35 if c.mode=="robust" else 60
				if c.channel!="earth" or c.signal<minimum: return _reply(false,"No acknowledgement: selected channel/protocol cannot support this link. Prepared report retained; choose the Earth relay and a protocol suitable for the signal.")
				c.sent=true;verification.ack=0.0;message="Report transmitted. Monitoring acknowledgement; leaving/reopening the console will not resend or consume anything."
			_:
				if action_id.begins_with("legacy:"): return {"ok":true,"event":"legacy","task":action_id.trim_prefix("legacy:"),"message":"Existing controls opened; partial progress will resume after cancellation."}
	_log(prop_id+":"+action_id,message)
	changed.emit()
	return _reply(true,message)

func _reply(ok: bool, message: String) -> Dictionary:
	return {"ok":ok,"message":message}

func legacy_complete(task_id: String, prop_id: String) -> bool:
	if flags.get("legacy."+task_id,false): return false
	var authorised := actions(prop_id).any(func(a: Dictionary): return a.id=="legacy:"+task_id and a.enabled)
	if not authorised: return false
	if task_id=="auxiliary_power": systems.power.calibrated=true
	elif task_id=="air_filter":
		if not _consume("filter_cartridge",phase+".life.service"): return false
		systems.life.serviced=true
	elif task_id=="nutrient_flow": systems.hydro.aligned=true
	else: return false
	flags["legacy."+task_id]=true
	_log("legacy."+task_id,"Existing "+task_id+" controls completed. Restore and verify the connected system before duty sign-off.")
	changed.emit()
	return true

func next_step(task: String) -> String:
	if completed.has(task): return "Verified; its equipment state remains available for monitoring."
	var blocked := prerequisite(task)
	if not blocked.is_empty(): return blocked
	match task:
		"crew": return "Desk/communal table: read roster, compare authorised watch entries, record only the supported conclusion."
		"cargo": return "Read manifest/seal; zero the empty scale; mover transfers the identified load; weigh and decide release/quarantine."
		"power": return "Compare loads, diagnose, isolate service circuit, allocate safely, synchronize auxiliary banks if needed, restore and verify."
		"life": return "Compare oxygen, CO2 and airflow; diagnose; retrieve the correct spare; isolate, service, restore, verify."
		"hydro": return "Compare reservoir EC with flow/pump readings; isolate; align valves or calculate buffer dose; restore, verify."
		"engine": return "Compare both pumps and valve pressure drops; diagnose; obtain tool/coolant; reduce output, isolate the correct component, service, restore, verify."
		"navigation": return "Helm/flight console: compare route and instrument; apply planned-minus-instrument correction; verify."
		"communications": return "Flight-control console: prepare verified report, check signal/protocol, transmit, wait for acknowledgement."
	return "See duty record."

func snapshot() -> Dictionary:
	return {"version":2,"phase":phase,"context":work_order_context,"work_orders":Array(authorized_work_orders),"flags":flags.duplicate(true),"completed":completed.duplicate(true),"evidence":evidence.duplicate(true),"journal":journal.duplicate(true),"stocks":stocks.duplicate(true),"legacy_progress":legacy_progress.duplicate(true),"systems":systems.duplicate(true),"verification":verification.duplicate(true),"transactions":transactions.duplicate(true),"elapsed":elapsed}

func restore(data: Dictionary) -> bool:
	if not (data.get("version") is int or data.get("version") is float): return false
	# JSON numbers are floats. Array membership is type-sensitive, while the
	# numeric comparisons accept exactly the two supported serialized versions.
	if (data.get("version")!=1 and data.get("version")!=2) or data.get("phase","") not in ["outbound","return"]: return false
	var context: String = str(data.get("context", "maintenance")) if data.version == 2 else "maintenance"
	var orders: Variant = data.get("work_orders", []) if data.version == 2 else []
	if context not in ["maintenance", "first_watch"] or not orders is Array: return false
	if context == "first_watch" and data.phase != "outbound": return false
	for order in orders:
		if order not in ["crew", "cargo", "power", "life", "hydro", "engine", "navigation", "communications", "hydro.inspect"]: return false
	for key in ["flags","completed","evidence","stocks","legacy_progress","systems","verification","transactions"]:
		if not data.get(key) is Dictionary: return false
	if not data.get("journal") is Array or not (data.get("elapsed") is float or data.get("elapsed") is int): return false
	# Compare shape with a fresh model before mutating live state. Invalid/truncated
	# saves never partially replace an active mission or its inventory.
	var probe = get_script().new()
	probe.reset(data.phase)
	if not _same_shape(probe.systems,data.systems): return false
	for key in probe.stocks:
		# Saves written before the hiding-only locker rule have no trolley bin.
		if key != "cargo.trolley" and not data.stocks.has(key): return false
	if data.systems.engine.health.size()!=2 or data.systems.engine.valves.size()!=2 or data.systems.engine.isolated.size()!=2: return false
	for value in data.flags.values()+data.completed.values()+data.transactions.values():
		if not value is bool: return false
	for key in data.completed:
		if data.completed[key]!=true or not CATALOG.OBJECTIVES.any(func(row: Array): return row[0]==key): return false
	for key in data.stocks:
		if not probe.stocks.has(key): return false
		var stock: Variant=data.stocks[key]
		if not stock is Dictionary: return false
		for item in stock:
			if item not in ["filter_cartridge","scrubber_media","coolant_charge","nutrient_buffer","oxygen_reserve","inert_purge","engineering_multitool","pressure_sealant"]: return false
			if not _number_in_range(stock[item],0,10000,true): return false
	for value in data.verification.values():
		if not (value is int or value is float) or not is_finite(float(value)) or value<0: return false
	for value in data.evidence.values():
		if not value is String: return false
	if data.journal.size()>120: return false
	for entry in data.journal:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("text") is String or entry.get("phase") not in ["outbound","return"] or not _number_in_range(entry.get("time"),0,1e12): return false
	for key in data.legacy_progress:
		if not _valid_service_progress(key,data.legacy_progress[key]): return false
	if not is_finite(float(data.elapsed)) or data.elapsed<0: return false
	phase=data.phase
	work_order_context = context; authorized_work_orders = PackedStringArray(orders)
	for key in ["flags","completed","evidence","stocks","legacy_progress","systems","verification","transactions"]: set(key,data[key].duplicate(true))
	if not stocks.has("cargo.trolley"): stocks["cargo.trolley"] = {}
	# Older saves may still hold supplies in lockers. Move those counts into
	# the trolley's real drawers in memory; no real save is rewritten on load.
	for old_location in ["cargo.locker","engine.locker.1","engine.locker.2"]:
		for item in stocks[old_location]:
			stocks["cargo.trolley"][item] = int(stocks["cargo.trolley"].get(item,0)) + int(stocks[old_location][item])
		stocks[old_location].clear()
	journal=data.journal.duplicate(true);elapsed=float(data.elapsed)
	changed.emit()
	return true

func _number_in_range(value: Variant, minimum: float, maximum: float, integer := false) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value>=minimum and value<=maximum and (not integer or value==floor(value))

func _valid_service_progress(task: String, data: Variant) -> bool:
	if task not in ["auxiliary_power","air_filter","nutrient_flow"] or not data is Dictionary or data.get("task")!=task or not data.get("complete") is bool: return false
	if not _number_in_range(data.get("filter_stage"),0,2,true) or not _number_in_range(data.get("filter_rotation"),0,3,true) or not _number_in_range(data.get("filter_airflow"),0,100): return false
	if not data.get("power") is Array or data.power.size()!=(3 if task=="auxiliary_power" else 0): return false
	if not data.get("nutrient_rotations") is Array or data.nutrient_rotations.size()!=(3 if task=="nutrient_flow" else 0): return false
	for value in data.power:
		if not _number_in_range(value,0,100): return false
	for value in data.nutrient_rotations:
		if not _number_in_range(value,0,7,true): return false
	return true

func _same_shape(template: Variant, value: Variant) -> bool:
	if template is Dictionary:
		if not value is Dictionary: return false
		for key in template:
			if not value.has(key) or not _same_shape(template[key],value[key]): return false
		return true
	if template is Array:
		if not value is Array or template.size()!=value.size(): return false
		for i in range(template.size()):
			if not _same_shape(template[i],value[i]): return false
		return true
	if template is float or template is int: return (value is float or value is int) and is_finite(float(value)) and absf(float(value))<1000000
	return typeof(template)==typeof(value)
