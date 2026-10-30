extends "res://scripts/ui/eito/artifact_station_screen.gd"
## Stations 02 teletype and guarded transmitter. The retained report and the
## acknowledgement timer belong to ShipMissionState, shared by both consoles.
var report_scroll := 0
const DO := ["Read the signal meter.","Print the watch report.","Select a viable Earth protocol.","Lift the guard over the send switch.","Send.","Monitor Earth acknowledgement.","Watch report sent."]
const WHY := ["The link must be strong enough for the protocol.","The teletype collects this watch's verified results.","Standard needs 60% signal; robust needs 35%.","The guard stops accidental sends.","Transmit the prepared report once.","A report is not done until Earth confirms it.","Earth acknowledged the retained duty report."]
func setup(host_layer) -> void: super.setup(host_layer);fb={"s":"off","t":"Report due this watch."}
func _c() -> Dictionary: return ctl.state.systems.communications
func _proto() -> String: return "local" if _c().channel=="local" else str(_c().mode)
func _stage() -> int:
	if bool(_c().acknowledged): return 6
	if bool(_c().sent): return 5
	if not bool(ctl.state.flags.get("communications.signal_read",false)): return 0
	if not bool(_c().report_ready): return 1
	if not bool(ctl.state.flags.get("communications.protocol_selected",false)): return 2
	if not bool(ctl.state.flags.get("communications.guard_open",false)): return 3
	return 4
func paint() -> void:
	screen_bg();hud("Send the watch report to Earth","BRIDGE · COMMUNICATIONS","Step away")
	_signal();_teletype();_protocol();_transmit();_log()
	var st := _stage()
	# The ACK arrives on the ship's timer, not on a click: replace a stale "waiting" line once it lands.
	if st==6 and str(fb.s) in ["live","off"]: fb={"s":"ok","t":"Earth relay acknowledged "+str(_c().report_id)+"."}
	_procedure("flight_control_comms_paper_0",st,6,DO[st],WHY[st])

func _signal() -> void:
	var r := Rect2(20,56,420,270);_module("flight_control_comms_mod_0",r,"SIGNAL · EARTH LINK")
	T(F("body"),16,"EARTH RELAY",321,63,Color("#ddd8c8"),27,2,96)
	_mat("comms_signal_plate",Rect2(34,100,392,200),true)
	_mat("comms_signal_base",Rect2(38,104,396,200),true)
	var a := deg_to_rad(-60.0+float(_c().signal)*1.2)
	var direction := Vector2(sin(a),-cos(a))
	# The source's overflow-hidden plate clips the needle below the pivot hood.
	draw_line(Vector2(236,300)+direction*(16.0/maxf(0.01,-direction.y)),Vector2(236,300)+direction*144,UI.INK,3,true)
	R(Rect2(206,284,60,12),UI.INK)
	T(F("num"),26,"%.0f%%"%float(_c().signal),366,267,UI.INK,31,2,48)
	hit("signal",Rect2(34,100,392,200))
	if _stage()==0: cue(Rect2(34,100,392,200))

func _report_lines() -> PackedStringArray:
	var out := PackedStringArray()
	for line in str(_c().report_text).split("\n"):
		# The HTML counts empty sc-for rows in its eleven-row paper, while
		# those rows take zero height. Keep them in the scroll sequence.
		if line.strip_edges().is_empty(): out.append("");continue
		var wrapped: PackedStringArray=UI.wrap_text(F("num"),18,line,294)
		out.append_array(wrapped)
	return out
func _teletype() -> void:
	var r := Rect2(460,56,420,432);_module("flight_control_comms_mod_1",r,"TELETYPE · REPORT")
	module_chip(r,"Printed" if _c().report_ready else "Ready","ok" if _c().report_ready else "off")
	B(Rect2(474,100,392,300),{"bg":Color("#1a2023"),"border":UI.EDGE,"bw":3})
	var lines := _report_lines()
	var h := 274.0 if _c().report_ready else 30.0
	var pr := Rect2(507,397-h,326,h)
	UI.artifact_paper(self,pr)
	if _c().report_ready and h>250:
		var rows := 11
		report_scroll=clampi(report_scroll,0,maxi(0,lines.size()-rows))
		var drawn := 0
		for i in range(mini(rows,lines.size()-report_scroll)):
			var line := lines[report_scroll+i]
			if line.is_empty(): continue
			T(F("num"),18,line,523,pr.position.y+12+drawn*20.7,UI.INK,20.7)
			drawn+=1
	B(Rect2(477,374,386,23),{"grad":[[0.0,Color("#3a4448")],[1.0,Color("#2a3236")]],"border":UI.EDGE,"bw":3})
	hit("report:scroll",Rect2(477,103,386,271),{"focus":false,"wheel_only":true})
	push("report",474,412,164,"PRINT REPORT","","done" if _c().report_ready else "",_stage()<1,false,164,50,16,15,-1,8,false)
	P(F("body"),15,"Collects this watch's duty results from the ship log.",653,417,212,18,Color("#b4c3c1"))
	if _stage()==1: cue(Rect2(474,412,164,44))

func _protocol() -> void:
	var r := Rect2(900,56,360,432);_module("flight_control_comms_mod_2",r,"PROTOCOL")
	_mat("comms_protocol_base",Rect2(980,100,200,160),true)
	var p := _proto();var rot: float={"local":-50.0,"standard":0.0,"robust":50.0}[p]
	draw_set_transform(Vector2(1080,196),deg_to_rad(rot))
	_mat("comms_protocol_needle",Rect2(-100,-96,200,160),true)
	draw_set_transform(Vector2.ZERO)
	var ids := ["local","standard","robust"]
	for i in range(3):
		_keycap("protocol:"+ids[i],Rect2(924+i*106,270,100,36),ids[i].to_upper(),p==ids[i],false,12)
		if _stage()==2 and ids[i]==("robust" if float(_c().signal)<60 else "standard"): cue(Rect2(924+i*106,270,100,36))
	var g := Rect2(920,322,320,100);artifact_glass(g)
	var keys := ["NEEDS","EARTH ACK","RATE"]
	var vals: Array={"local":["None","No · ship only","Fast"],"standard":["60% signal","Yes","Normal"],"robust":["35% signal","Yes","Slow"]}[p]
	for i in range(3):
		T(F("num"),20,keys[i],934,330+i*29,UI.PHOS_DIM,26)
		T(F("num"),20,vals[i],1081,330+i*29,UI.PHOS,26,2,145)
	artifact_glass_overlay(g)
	P(F("body"),15,"Outbound reports use standard. Robust is for weak links; local stays on board.",920,432,320,18,Color("#b4c3c1"))

func _transmit() -> void:
	var r := Rect2(20,338,420,150);_module("flight_control_comms_mod_3",r,"TRANSMIT")
	module_chip(r,"ACK","ok" if _c().acknowledged else "live" if _c().sent else "off")
	var open := bool(ctl.state.flags.get("communications.guard_open",false))
	dim=_stage()<3
	_mat("comms_guard_sent" if _c().sent else "comms_guard_open" if open else "15_2",Rect2(34,382,90,90),true)
	dim=false;hit("cover",Rect2(34,382,90,90))
	if _stage()==3: cue(Rect2(34,382,90,90))
	push("transmit",140,404,110,"SEND","","red",_stage()<4,false,110,50,16,15,-1,8,false)
	if _stage()==4: cue(Rect2(140,404,110,44))
	T(F("label",400,0.8),13,"ACK TIMER",266,391,UI.LABEL,18)
	var count := mini(8,int(float(ctl.state.verification.get("ack",0.0))/3.0*8.0)) if _c().sent else 0
	for i in range(8): B(Rect2(266+i*20,407,18,10),{"bg":Color("#7fe08a") if i<count else Color("#0c1518"),"border":UI.EDGE,"bw":1})
	_keycap("ack",Rect2(266,425,120,38),"CHECK ACK",false,_stage()<5,12)
	if _stage()==5: cue(Rect2(266,425,120,38))

func _log() -> void:
	_module("flight_control_comms_mod_4",Rect2(720,500,540,204),"LINK LOG")
	var g := Rect2(734,546,512,138);artifact_glass(g)
	var logs := PackedStringArray(["EARTH RELAY · SIGNAL %.0f%%"%float(_c().signal)])
	if bool(ctl.state.flags.get("communications.protocol_selected",false)): logs.append("PROTOCOL "+_proto().to_upper())
	if _c().report_ready: logs.append("REPORT "+str(_c().report_id)+" PREPARED")
	if _c().sent: logs.append("REPORT TRANSMITTED · WAITING FOR ACK")
	if _c().acknowledged: logs.append("EARTH RELAY · ACK RECEIVED")
	for i in range(logs.size()): T(F("num"),19,logs[i],748,553+i*22.8,Color("#7fe08a") if i==logs.size()-1 else Color("#55e0d0"),22.8)
	artifact_glass_overlay(g)

func on_wheel(id: String,dir: int) -> bool:
	if id!="report:scroll": return false
	report_scroll=maxi(0,report_scroll-dir*3);return true
func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id=="signal":
		ctl.state.flags["communications.signal_read"]=true
		say("ok","Signal %.0f%%. Standard needs 60%%; robust needs 35%%."%float(_c().signal));return
	if id=="report":
		if _stage()<1: say("warn","Read the signal first.");return
		if not _can("prepare_report"): return
		ctl.act("prepare_report");report_scroll=0
		if _c().report_ready: say("ok","Report prepared from the verified live measurements. Scroll the paper to review it.")
		return
	if id.begins_with("protocol:"):
		if not _can("channel"): return
		var p := id.get_slice(":",1);ctl.act("channel",p)
		ctl.state.flags["communications.protocol_selected"]=false
		if p=="local": say("warn","Local stays on board and cannot receive an Earth acknowledgement.");return
		var minimum := 35 if p=="robust" else 60
		if float(_c().signal)<minimum: say("warn","The signal is too weak for this protocol.");return
		ctl.state.flags["communications.protocol_selected"]=true;say("ok",p.capitalize()+" selected.");return
	if id=="cover":
		if _stage()<3: say("warn","Prepare the report and select a viable Earth protocol first.");return
		ctl.state.flags["communications.guard_open"]=true;say("ok","Guard up.");return
	if id=="transmit":
		if not bool(ctl.state.flags.get("communications.guard_open",false)): say("warn","The guard is down. Lift it first.");return
		if not _can("transmit"): return
		ctl.act("transmit")
		if _c().sent: say("ok","Report sent once. Monitoring the relay acknowledgement.")
		return
	if id=="ack":
		if _c().acknowledged: say("ok","Earth relay acknowledged "+str(_c().report_id)+".")
		elif _c().sent: say("live","Waiting for relay acknowledgement: %.1f / 3.0 s."%float(ctl.state.verification.get("ack",0.0)))
		else: say("warn","Transmit the prepared report first.")
