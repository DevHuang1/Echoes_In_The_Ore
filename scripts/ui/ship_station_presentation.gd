extends RefCounted
## Presentation only: formats the existing model, never stores game progress.
const UI := preload("res://scripts/ui/equipment_ui.gd")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
const LABELS := {
	"record":"RECORD NOTE", "assign":"ACCEPT DUTIES", "file_report":"FILE REPORT",
	"observe":"CAPTURE", "diagnose":"DIAGNOSE", "isolate":"ISOLATE", "restore":"RESTORE",
	"allocation":"SET LOADS", "verify":"VERIFY", "reduce_load":"60% OUTPUT", "resume_output":"NOMINAL OUTPUT",
	"legacy:auxiliary_power":"BANK CONTROLS", "legacy:air_filter":"FILTER CONTROLS", "legacy:nutrient_flow":"VALVE CONTROLS",
	"scrubber_service":"REPLACE MEDIA", "engine_service":"SERVICE", "oxygen_reserve":"SWAP O2 BANK", "dose":"DISPENSE",
	"manifest":"READ MANIFEST", "seal":"CHECK SEAL", "tare":"ZERO + CHECK", "weigh":"READ MASS", "cargo_decide":"LOG DECISION",
	"move_load":"TRANSFER LOAD", "transfer_kit":"ISSUE COOL-02", "cylinder":"ISSUE CYLINDER", "recover_supplies":"RECOVERY ISSUE",
	"roster":"READ ROSTER", "crew_log":"READ CHECK-INS", "crew_compare":"LOG CONCLUSION", "rest":"SHORT REST",
	"route":"COMPARE", "correction":"SET CORRECTION", "nav_verify":"VERIFY HEADING", "prepare_report":"PREPARE REPORT",
	"channel":"SET PROTOCOL", "transmit":"TRANSMIT", "turbine":"READ MACHINE", "chair":"CHECK ACCESS", "hide":"CONCEAL",
}
const ITEMS := {"filter_cartridge":"FILTER-A", "scrubber_media":"SCRUB-A", "coolant_charge":"COOL-02",
	"nutrient_buffer":"BUFFER-A", "oxygen_reserve":"O2-01", "inert_purge":"N2-03",
	"engineering_multitool":"MULTITOOL", "pressure_sealant":"SEALANT"}

static func action_label(id: String,title: String) -> String:
	if id=="story:briefing": return "COMMAND TEXT"
	if id=="story:summary": return "REVIEW + HANDOFF"
	if id.begins_with("optional:"): return "OPTIONAL CHECK"
	if id.begins_with("take:"): return "TAKE / "+ITEMS.get(id.trim_prefix("take:"),id.trim_prefix("take:").to_upper())
	if id.begins_with("store:"): return "STORE / "+ITEMS.get(id.trim_prefix("store:"),id.trim_prefix("store:").to_upper())
	return LABELS.get(id,title)

static func option_label(action: String, option: Array) -> String:
	var id: String=str(option[0])
	var names := {"cell":"BANK NOT SYNCED","load":"LOAD OVER CAPACITY","oxygen":"OXYGEN SUPPLY",
		"airflow":"FILTER RESTRICTION","scrubber":"CO2 REMOVAL","restriction":"MANIFOLD RESTRICTION","balance":"RESERVOIR EC","pump":"PUMP DELIVERY",
		"valve":"VALVE 2 RESTRICTION","balanced":"70 / 20 / 10","reserve":"70 / 10 / 20","overload":"70 / 35 / 10",
		"accept":"ACCEPT + SECURE","quarantine":"QUARANTINE UNOPENED","scale":"TO INSPECTION SCALE","staging":"TO STAGING",
		"records_match":"ROUTINE RECORDS MATCH","unconfirmed":"WHEREABOUTS UNCONFIRMED",
		"standard":"EARTH / STANDARD","robust":"EARTH / REPEATED","local":"LOCAL CREW CHANNEL"}
	if action=="diagnose" and id=="load": return "EXCESS OUTPUT" if option[1].contains("both loops") else "LOAD OVER CAPACITY"
	if action=="diagnose" and id=="pump" and option[1].contains("mechanical"): return "PUMP MECHANICAL FAULT"
	return ITEMS.get(id,names.get(id,str(option[1])))

static func task(definition: Dictionary) -> String:
	if definition.get("kind")=="crew": return "crew"
	if definition.get("kind")=="navigation": return "navigation"
	if definition.get("kind")=="communications": return "communications"
	return definition.get("room","")

static func option_index(state: Object,d: Dictionary,action: Dictionary) -> int:
	# Initialize selectors from an applied setting/conclusion when one exists.
	# An unanswered diagnosis remains a player choice, not a supplied solution.
	var value: Variant=null
	match str(action.id):
		"allocation":
			var p: Dictionary=state.systems.power
			if p.science==20 and p.reserve==10: value="balanced"
			elif p.science==10 and p.reserve==20: value="reserve"
			elif p.science==35 and p.reserve==10: value="overload"
		"cargo_decide":
			if state.completed.has("cargo"): value="quarantine" if state.systems.cargo.quarantined else "accept"
		"crew_compare":
			if state.systems.crew.confirmed: value="unconfirmed" if state.phase=="return" else "records_match"
		"channel":
			var c: Dictionary=state.systems.communications
			value="local" if c.channel=="local" else c.mode
		"move_load": value=state.systems.cargo.location
		"diagnose":
			var room: String=d.get("room","")
			if state.flags.get(room+".diagnosed",false):
				value={"power":"load" if state.phase=="return" else "cell","life":"scrubber" if state.phase=="return" else "airflow","hydro":"balance" if state.phase=="return" else "restriction","engine":"valve" if state.phase=="return" else "pump"}.get(room)
	for i in range(action.options.size()):
		if action.options[i][0]==value: return i
	return 0

static func pages(definition: Dictionary) -> Array:
	var kind: String=definition.get("kind","")
	match kind:
		"planning": return ["DUTIES","SIGN-OFF","RECORDS"]
		"storage": return ["SUPPLIES","RETURN","RECORDS"]
		"storage_hide","cargo_hide": return ["ACCESS","RECORDS"]
		"crew": return ["ROSTER","COMPARE","RECORDS"]
		"communications": return ["REPORT","TRANSMIT","RECORDS"]
		"navigation": return ["COMPARE","CORRECT","RECORDS"]
		"rest","chair": return ["ACCESS","RECORDS"]
		"transfer": return ["HANDLING","SUPPLY RUN","RECORDS"]
		"cylinders": return ["ISSUE","RECORDS"]
		"cargo": return ["INSPECT","WEIGH","DISPOSITION","RECORDS"]
	return ["INSPECT","SERVICE","VERIFY","RECORDS"]

static func action_page(id: String, definition: Dictionary) -> String:
	if id.begins_with("optional:"): return "INSPECT"
	if id=="story:briefing": return "DUTIES"
	if id=="story:summary": return "SIGN-OFF"
	var kind: String=definition.get("kind","")
	if id=="record": return "RECORDS"
	if id.begins_with("take:") or id=="recover_supplies": return "SUPPLIES"
	if id.begins_with("store:"): return "RETURN"
	if id in ["hide","rest","chair"]: return "ACCESS" if kind in ["storage_hide","cargo_hide","rest","chair"] else "INSPECT"
	match kind:
		"planning": return "DUTIES" if id=="assign" else "SIGN-OFF"
		"crew": return "COMPARE" if id=="crew_compare" else "ROSTER"
		"communications": return "REPORT" if id=="prepare_report" else "TRANSMIT"
		"navigation": return "COMPARE" if id=="route" else "CORRECT"
		"transfer": return "HANDLING" if id=="move_load" else "SUPPLY RUN"
		"cylinders": return "ISSUE"
		"cargo","cargo_hide":
			if id=="cargo_decide": return "DISPOSITION"
			return "WEIGH" if id in ["tare","weigh"] else "INSPECT"
	if id in ["observe","diagnose","turbine"]: return "INSPECT"
	if id in ["verify","restore","resume_output"]: return "VERIFY"
	return "SERVICE"

static func suggested_page(state: Object, definition: Dictionary) -> String:
	var kind: String=definition.get("kind","")
	var room: String=definition.get("room","")
	if room in ["power","life","hydro","engine"] and kind not in ["storage_hide"]:
		if state.completed.has(room): return "VERIFY"
		if state.systems[room].get("restored",false) or float(state.verification.get(room,0))>0: return "VERIFY"
		if state.flags.get(room+".diagnosed",false): return "SERVICE"
	return str(pages(definition)[0])

static func metric(title: String,value: String,hint: String,reading: float,maximum: float,color: Color=UI.CYAN) -> Array:
	return [title,value,hint,reading,maximum,color]

static func metrics(state: Object,d: Dictionary) -> Array:
	var kind: String=d.get("kind","");var room: String=d.get("room","")
	var s: Dictionary=state.systems
	if kind in ["storage_hide","cargo_hide"]:
		return [metric("COVER","AVAILABLE","Use H beside this prop",1,1)]
	if kind=="storage":
		var stock: Dictionary=state.stocks.get(d.id,{})
		var n := 0
		for count in stock.values(): n+=int(count)
		var inv: Dictionary=state.inventory.inventory_snapshot()
		var free: int=inv.storage.count(&"")+inv.hotbar.count(&"")
		return [metric("STATION STOCK","%d ITEMS" % n,"Service supplies",n,maxi(12,n)),metric("CARRY SPACE","%d FREE" % free,"36 carry slots",free,36),metric("TRANSFER","READY","One item per transfer",1,1)]
	if kind=="planning":
		if state.work_order_context=="first_watch":
			var progress: Dictionary=state.story_progress
			return [metric("FIRST WATCH","%d / 5" % int(progress.get("completed",0)),"Story missions",int(progress.get("completed",0)),5),metric("REQUIRED WORK","2 REPAIRS","Power / irrigation",int(state.completed.has("power"))+int(state.completed.has("hydro")),2),metric("HANDOFF","ACKNOWLEDGED" if progress.get("acknowledged",false) else "PENDING","Maya / terminal text",int(progress.get("acknowledged",false)),1)]
		return [metric("DUTY LOG","%d / 8" % state.completed.size(),"Verified procedures",state.completed.size(),8),metric("ASSIGNMENT","ACCEPTED" if state.flags.get("assigned",false) else "AWAITING","Accept duties",int(state.flags.get("assigned",false)),1),metric("REPORT","FILED" if state.flags.get("report_filed",false) else "OPEN","Relay + sign-off",int(state.flags.get("report_filed",false)),1)]
	if kind=="navigation":
		var n: Dictionary=s.navigation
		return [metric("REFERENCE","%.1f deg" % n.planned,"Planned heading",n.planned,360),metric("INSTRUMENT","%.1f deg" % n.instrument,"Independent reading",n.instrument,360),metric("CORRECTED","%.1f deg" % (n.instrument+n.correction),"Ref +/- 0.2 deg",n.instrument+n.correction,360,UI.CYAN if absf(n.instrument+n.correction-n.planned)<=0.2 else UI.AMBER)]
	if kind=="communications":
		var c: Dictionary=s.communications
		return [metric("SIGNAL","%d%%" % c.signal,"STD 60% / RPT 35%",c.signal,100,UI.AMBER if c.signal<60 else UI.CYAN),metric("PACKET","READY" if c.report_ready else "NOT READY","Verified readings",int(c.report_ready),1),metric("LINK","ACKNOWLEDGED" if c.acknowledged else "IN TRANSIT" if c.sent else "STANDBY","Earth acknowledgement",float(state.verification.get("ack",0)),3)]
	if kind in ["crew","rest","chair"]:
		var conclusion: String=("UNCONFIRMED" if state.phase=="return" else "MATCHED") if s.crew.confirmed else "PENDING"
		return [metric("WATCH","A1-DUTY","Authorised roster",1,1),metric("CHECK-IN",conclusion,"Pre-incident roster" if state.phase=="return" else "Routine watch records",int(s.crew.confirmed),1,UI.AMBER if state.phase=="return" else UI.CYAN),metric("FATIGUE","%.0f%%" % s.crew.fatigue,"Rest clears fatigue",s.crew.fatigue,100,UI.AMBER if s.crew.fatigue>60 else UI.CYAN)]
	match room:
		"power":
			var p: Dictionary=s.power;var total: int=p.essential+p.science+p.reserve
			return [metric("ESSENTIAL","%d / 70" % p.essential,"Minimum allocation",p.essential,100),metric("SCIENCE","%d UNITS" % p.science,"Irrigation / nav",p.science,100,UI.AMBER if not state.bus_powered("science") else UI.CYAN),metric("TOTAL LOAD","%d / %d" % [total,p.capacity],"Reserve %d units" % p.reserve,total,p.capacity,UI.RED if total>p.capacity else UI.CYAN)]
		"cargo":
			var c: Dictionary=s.cargo
			return [metric("MANIFEST",str(c.id),"Expected %.1f kg" % c.manifest_mass,1,1),metric("LOAD MASS","%.1f kg" % c.measured_mass if c.weighed else "NOT READ","%.1f +/- 0.5 kg" % c.manifest_mass,c.measured_mass if c.weighed else 0,100,UI.AMBER if c.weighed and absf(c.measured_mass-c.manifest_mass)>0.5 else UI.CYAN),metric("CUSTODY",str(c.location).to_upper(),"UNOPENED / QUARANTINE" if c.quarantined else "Secured handling record",int(c.weighed),1)]
		"engine":
			var e: Dictionary=s.engine
			var loop_index := 0 if str(d.id).ends_with(".1") or str(d.id).ends_with(".3") else 1
			var flow: float=state.engine_flow(loop_index)
			var common := [metric("TEMPERATURE","%.1f C" % e.temperature,"Verify <= 65 C",e.temperature,110,UI.RED if e.temperature>65 else UI.CYAN),metric("LOOP %d FLOW" % (loop_index+1),"%.0f%%" % (flow*100),"Healthy >= 90%",flow*100,100,UI.AMBER if flow<0.9 else UI.CYAN)]
			if kind=="turbine":
				var in_range: bool=flow>=0.9 and e.temperature<=65
				var verified: bool=in_range and state.completed.has("engine")
				common.append(metric("COOLING","VERIFIED" if verified else "IN RANGE" if in_range else "OUT OF RANGE","Read-only / loop and temperature",int(in_range),1,UI.CYAN if in_range else UI.AMBER))
			elif kind=="engine_valve":
				common.append(metric("VALVE %d" % (loop_index+1),"%.0f%%" % (e.valves[loop_index]*100),"Measured opening",e.valves[loop_index]*100,100))
			else:
				common.append(metric("PUMP %d" % (loop_index+1),"%.0f%%" % (e.health[loop_index]*100),"Measured health",e.health[loop_index]*100,100))
			return common
		"life":
			var l: Dictionary=s.life
			return [metric("OXYGEN","%.1f%%" % l.oxygen,"Range 20-22%",l.oxygen,25,UI.CYAN if l.oxygen>=20 and l.oxygen<=22 else UI.RED),metric("CO2","%.3f%%" % l.co2,"Maximum 0.100%",l.co2,0.2,UI.RED if l.co2>0.1 else UI.CYAN),metric("AIRFLOW","%.0f%%" % l.airflow,"Range 62-72%",l.airflow,100,UI.AMBER if l.airflow<62 or l.airflow>72 else UI.CYAN)]
		"hydro":
			var h: Dictionary=s.hydro
			var env: Dictionary=state.hydro_environment()
			return [metric("RESERVOIR EC","%.2f" % h.ec,"Range 1.8-2.4",h.ec,4.0,UI.AMBER if h.ec<1.8 or h.ec>2.4 else UI.CYAN),metric("DELIVERY","%.0f%%" % h.flow,"Healthy >= 90%",h.flow,100,UI.AMBER if h.flow<90 else UI.CYAN),metric("PUMP CAPACITY","%.0f%%" % env.pump_capacity,"Bay humidity %.0f%% RH" % env.humidity,env.pump_capacity,100)]
	return [metric("SHIP STORE","AVAILABLE","Optional supplies",1,1)]

static func condition(state: Object,d: Dictionary) -> String:
	var t := task(d);var room: String=d.get("room","");var kind: String=d.get("kind","")
	if kind in ["storage","storage_hide","chair"]: return "ACCESS READY"
	if kind=="rest":
		for action in state.actions(d.id):
			if action.id=="rest": return "REST READY" if action.enabled else "REST INTERLOCKED"
	if state.work_order_context=="first_watch":
		if kind=="planning": return "WATCH HANDED OVER" if state.story_progress.get("acknowledged",false) else "FIRST WATCH"
		if room=="life" and state.systems.life.airflow>=62 and state.systems.life.co2<=0.1: return "ROUTINE / HEALTHY"
		if room=="engine" and state.engine_flow(0)>=0.9 and state.engine_flow(1)>=0.9 and state.systems.engine.temperature<=65: return "ROUTINE / HEALTHY"
	if state.completed.has(t): return "VERIFIED"
	if kind=="planning": return "WATCH FILED" if state.flags.get("report_filed",false) else "DUTY LOG"
	if not state.prerequisite(t).is_empty(): return "INTERLOCKED"
	if room in ["power","life","hydro"] and state.systems[room].isolated: return "ISOLATED"
	if room=="engine" and (state.systems.engine.isolated[0] or state.systems.engine.isolated[1]): return "ISOLATED"
	if kind=="communications" and state.systems.communications.sent: return "TRANSMITTING"
	if float(state.verification.get(t,0))>=6: return "READY TO VERIFY"
	if float(state.verification.get(t,0))>0: return "OBSERVING"
	if room in ["power","life","hydro","engine"]: return "FAULT / INSPECT"
	return "AWAITING REVIEW"

static func clean(text: String) -> String:
	for item in ITEMS: text=text.replace(item,ITEMS[item])
	text=text.replace(" without advancing the story","").replace("; no ship layout or map image is needed","").replace("no unfinished-room objective is required","authorised maintenance supplies are available")
	for entry in [
		["Auxiliary calibration: true","Auxiliary bank: SYNCHRONIZED"],
		["Auxiliary calibration: false","Auxiliary bank: SYNCHRONIZATION REQUIRED"],
		["Pump service isolation: true","Nutrient delivery: ISOLATED"],
		["Pump service isolation: false","Nutrient delivery: CONNECTED"],
		["service isolation: true","service circuit: ISOLATED"],
		["service isolation: false","service circuit: CONNECTED"],
		["manifold verified: true","manifold: ALIGNED"],
		["manifold verified: false","manifold: MISALIGNED"],
		["log reviewed: true","log: REVIEWED"],["log reviewed: false","log: NOT REVIEWED"],
		["comparison recorded: true","comparison: RECORDED"],["comparison recorded: false","comparison: PENDING"],
		["acknowledgement: true","acknowledgement: RECEIVED"],["acknowledgement: false","acknowledgement: AWAITING"]]:
		text=text.replace(entry[0],entry[1])
	return text.replace("true","CONFIRMED").replace("false","PENDING").replace("POST-INCIDENT RETURN / development scenario; crew outcomes unconfirmed.","RETURN WATCH / crew whereabouts unconfirmed.").replace("This is an independently identified machine.","").replace("Amara's existing hydroponics dialogue and inspection jobs remain available.","Amara has pump and seedling inspection requests.").replace("The unfinished shuttle area is not a required workstation for these duties.","These optional ship stores remain available during the watch.").replace("Existing ","").replace("existing ","")
