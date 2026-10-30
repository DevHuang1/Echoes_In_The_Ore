extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 coolant-pump board. The original cutaway, gauge and charge-port
## graphics are extracted from the artifact. All readings and service gates
## come from the live engine model; pressure/RPM/sight level are not invented.

const STEPS := [
	{"do":"Read flow and pump health.","why":"Compare both cooling loops before diagnosing a component."},
	{"do":"Look at the pump cutaway.","why":"Confirm which loop has low pump delivery."},
	{"do":"Reduce turbine load to 60%.","why":"Less heat while the diagnosed loop is off."},
	{"do":"Isolate the diagnosed pump.","why":"Shut the service loop before opening the pump."},
	{"do":"Inspect the shaft seal with the multitool.","why":"This is a service checklist step; no separate seal sensor exists."},
	{"do":"Charge the service loop from COOL-02.","why":"The one-time pump service consumes the sealed coolant charge."},
	{"do":"Restore the cooling loop.","why":"Cancel isolation and observe flow recovery."},
	{"do":"Verify flow and temperature.","why":"Healthy readings must persist for the full observation timer."},
]
const DONE := {"do":"Coolant loop verified.","why":"Return to the turbine panel to resume full output."}
var ctl
var fb := {"s":"warn","t":"Read the live cooling-loop values first."}
var mats := {}
var spin_started_at := 0.0
var was_isolated := false

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func setup(host_layer) -> void:
	ctl=host_layer;was_isolated=_isolated()
func tick(_delta: float) -> void:
	if ctl==null: return
	var isolated := _isolated()
	if was_isolated and not isolated: spin_started_at=now
	was_isolated=isolated
func _s() -> Object: return ctl.state
func _e() -> Dictionary: return _s().systems.engine
func _n() -> int: return int(ctl.prop_id.get_slice(".",2))
func _i() -> int: return _n()-1
func _target() -> bool: return ctl.prop_id=="engine.pump.1" and _s().phase=="outbound"
func _isolated() -> bool: return bool(_e().isolated[_i()])
func _serviced() -> bool: return bool(_e().serviced) and float(_e().health[_i()])>=0.99
func _seal() -> bool: return bool(_s().flags.get("engine.pump.1.seal_checked",false))
func _stage() -> int:
	if _s().completed.has("engine") and _target(): return 8
	if not bool(_s().flags.get("engine.observed",false)): return 0
	if not _target() or not bool(_s().flags.get("engine.diagnosed",false)): return 1
	if float(_e().load)>0.6: return 2
	if not _isolated() and not _serviced(): return 3
	if _isolated() and not _seal(): return 4
	if _isolated() and not _serviced(): return 5
	if _isolated(): return 6
	return 7
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("pump:fb")

func _mat(name: String,r: Rect2,graphics := false) -> void:
	var key := name+"_dim" if dim and graphics else name
	if not mats.has(key):
		var file := "res://art/ui/eito/stations02/"+("graphics/" if graphics else "materials/")+key+".res"
		if not ResourceLoader.exists(file): file="res://art/ui/eito/stations02/"+("graphics/" if graphics else "materials/")+name+".res"
		mats[key]=load(file)
	if mats[key]!=null: draw_texture_rect(mats[key],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func paint() -> void:
	screen_bg()
	hud("Restore engine coolant flow" if _target() else "Inspect cooling pump %d"%_n(),"ENGINE ROOM · COOLANT PUMP %d"%_n(),"Step away")
	_mimic();_cutaway();_readouts();_paper();_controls()

func _dashed_line(a: Vector2,b: Vector2,col: Color) -> void:
	var span := b-a;var length := span.length()
	if length<1: return
	var d := span/length;var off := fmod(now*10.0,24.0)
	var t := -off
	while t<length:
		var lo := maxf(0.0,t);var hi := minf(length,t+14.0)
		if hi>lo: draw_line(a+d*lo,a+d*hi,col,6)
		t+=24.0
func _dashed_rect(r: Rect2,col: Color) -> void:
	_dashed_line(r.position,Vector2(r.end.x,r.position.y),col)
	_dashed_line(Vector2(r.end.x,r.position.y),r.end,col)
	_dashed_line(r.end,Vector2(r.position.x,r.end.y),col)
	_dashed_line(Vector2(r.position.x,r.end.y),r.position,col)

func _mimic() -> void:
	var r := Rect2(20,56,640,300)
	_module("coolant_pump_mod_0",r,"COOLANT LOOPS · MIMIC")
	var low: bool = _s().engine_flow(_i())<0.9
	var both_good: bool=_s().engine_flow(0)>=0.9 and _s().engine_flow(1)>=0.9
	module_chip(r,"Loop %d isolated"%_n() if _isolated() else "Loop %d low delivery"%_n() if low else "Both loops normal" if both_good else "Loop %d flow normal"%_n(),"warn" if _isolated() else "fault" if low else "ok")
	B(Rect2(34,100,612,236),{"notch":true,"grad":[[0.0,Color("#34494f")],[1.0,Color("#22333a")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]]})
	var glass := Rect2(48,114,584,208)
	artifact_glass(glass)
	# Exact source SVG layers preserve both loop paths, symbols, lettering and
	# the four-step dashed-flow animation rather than redrawing a simpler mimic.
	var art_rect := Rect2(49,116,580,204)
	_mat("pump_mimic_base",art_rect,true)
	for i in range(2):
		var status := "isolated" if bool(_e().isolated[i]) else "good" if _s().engine_flow(i)>=0.9 else "low"
		var period := 0.6 if i==0 and status=="good" else 1.6
		var frame := 0 if status=="isolated" else int(fmod(now,period)/period*4.0)
		_mat("pump_mimic_loop%d_%s_%d"%[i+1,status,frame],art_rect,true)
	_mat("pump_mimic_load_60" if float(_e().load)<=0.6 else "pump_mimic_load_100",art_rect,true)
	artifact_glass_overlay(glass)

func _cutaway() -> void:
	var r := Rect2(680,56,580,300)
	_module("coolant_pump_mod_1",r,"PUMP %d · CUTAWAY"%_n())
	T(F("body"),16,"RPM —",1124,63,Color("#ddd8c8"),27,2,112)
	dim=_stage()<1
	_mat("pump_cutaway_base",Rect2(694,107,230,230),true)
	var period := 3.0 if _s().engine_flow(_i())<0.9 else 1.2
	var frame := 0 if _isolated() else int(fmod(now-spin_started_at,period)/period*8.0)
	_mat("pump_impeller_frame_"+str(frame),Rect2(694,107,230,230),true)
	_mat("pump_cutaway_hub",Rect2(694,107,230,230),true)
	T(F("label",400,0.7),11,"SERVICE CHECK" if _seal() else "SHAFT SEAL",743,319,Color("#e9b52c"),18,1,132)
	dim=false
	hit("diagnose",Rect2(694,107,230,230))
	if _stage()==1: cue(Rect2(694,107,230,230))
	_gauge(936,"SUCTION")
	_gauge(1120,"DISCHARGE")
	B(Rect2(937,256,40,80),{"bg":Color("#10171a"),"border":UI.EDGE})
	B(Rect2(987,256,22,80),{"bg":Color("#efe8d4"),"border":UI.EDGE})
	var temperature_h := clampf(float(_e().temperature),0,100)*0.74
	R(Rect2(994,332-temperature_h,6,temperature_h),Color("#e0763a"))
	var g := Rect2(1018,254,228,90)
	artifact_glass(g)
	var names := ["SIGHT GLASS","ENGINE TEMP","LIMIT"]
	var vals := ["UNMEASURED","%.0f C"%float(_e().temperature),"65 C"]
	for i in range(3):
		T(F("num"),19,names[i],1028,260+i*27,UI.PHOS_DIM,24)
		T(F("num"),19,vals[i],1130,260+i*27,UI.PHOS,24,2,105)
	artifact_glass_overlay(g)

func _gauge(x: float,label: String) -> void:
	_mat("pump_pressure_gauge_base",Rect2(x,100,120,120),true)
	T(F("num"),20,"—",x+30,186,UI.INK,26,1,60)
	T(F("label"),12,label+" BAR",x-12,225,UI.TEXT,20,1,144)
	hit("observe",Rect2(x,100,120,145))
	if _stage()==0: cue(Rect2(x,100,120,145))

func _readouts() -> void:
	var r := Rect2(20,368,680,120)
	_module("coolant_pump_mod_2",r,"LOOP READOUTS")
	T(F("body"),16,"Healthy flow ≥90% · temp ≤65 C",397,374,Color("#ddd8c8"),27,2,277)
	for loop in range(2):
		var g := Rect2(34+loop*332,412,320,62)
		artifact_glass(g)
		T(F("num"),19,"LOOP %d FLOW"%(loop+1),48+loop*332,418,UI.PHOS_DIM,24)
		T(F("num"),19,"%.0f%%"%(_s().engine_flow(loop)*100.0),250+loop*332,418,UI.PHOS,24,2,90)
		T(F("num"),19,"PUMP HEALTH",48+loop*332,446,UI.PHOS_DIM,24)
		T(F("num"),19,"%.0f%%"%(float(_e().health[loop])*100.0),250+loop*332,446,UI.PHOS,24,2,90)
		artifact_glass_overlay(g)

func _paper() -> void:
	_mat("coolant_pump_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<8 else DONE
	artifact_procedure(st,8,str(cur.do),str(cur.why),fb)

func _controls() -> void:
	var r := Rect2(720,368,540,336)
	_module("coolant_pump_mod_3",r,"PUMP %d CONTROLS"%_n())
	T(F("label"),13,"LOOP ISOLATED" if _isolated() else "LOOP LIVE",1126,375,UI.WARN,30,2,116)
	_push("reduce",Rect2(770,422,100,50),"LOAD 60%","Ask turbine for 60%",_stage()==2)
	_push("isolate",Rect2(938,422,103,50),"ISOLATE","Shut loop %d valves"%_n(),_stage()==3)
	_push("seal",Rect2(1112,422,100,50),"RESEAT","Seal · multitool",_stage()==4)
	_mat("pump_cool02_charge",Rect2(771,532,96,60),true)
	hit("charge",Rect2(771,532,96,60),{"locked":_stage()!=5})
	if _stage()==5: cue(Rect2(771,532,96,60))
	T(F("body"),15,"Charge port",759,600,Color("#b4c3c1"),20,1,120)
	_push("restore",Rect2(938,538,103,50),"RESTORE","Open loop %d"%_n(),_stage()==6)
	_push("verify",Rect2(1112,538,100,50),"VERIFY","Flow and temperature",_stage()==7)
	P(F("body"),15,"After verification, resume full output at the turbine panel.",733,651,511,19,Color("#b4c3c1"))

func _push(id: String,r: Rect2,label: String,caption: String,ready: bool) -> void:
	# The prototype stops dimming controls once their step has passed. Keep the
	# native hit region locked except at the one genuine gameplay action step.
	var step: int={"reduce":2,"isolate":3,"seal":4,"restore":6,"verify":7}[id]
	var restored := id=="restore" and _stage()>=7
	var face := Rect2(r.position+Vector2(0,3),r.size) if restored else r
	dim=not _target() or _stage()<step
	B(face,{"grad":[[0.0,Color("#8adcf2") if id=="verify" else Color("#e46a52") if id=="isolate" else Color("#7fd685") if restored else Color("#cfc7a8")],[1.0,Color("#4aa4c2") if id=="verify" else Color("#b43c28") if id=="isolate" else Color("#4c9f52") if restored else Color("#a9a083")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#c9f5c9") if restored else Color("#f0ead2")],[-2,-2,0,Color("#2c6a31") if restored else Color("#7e7660")]],"outer":[[0,3 if restored else 6,0,UI.EDGE]]})
	T(F("label",400,0.65),15,label,face.position.x,face.position.y,Color("#fff2e8") if id=="isolate" else UI.INK,face.size.y,1,face.size.x)
	dim=false
	P(F("body"),15,caption,r.position.x-20,r.end.y+9,r.size.x+40,18,Color("#b4c3c1"),false,1)
	hit(id,r,{"locked":not ready})
	if ready: cue(r)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id=="observe":
		ctl.act("observe")
		if bool(_s().flags.get("engine.observed",false)): say("ok","Pump %d health %.0f%%; loop flow %.0f%%. Pressure sensors are unavailable."%[_n(),float(_e().health[_i()])*100.0,_s().engine_flow(_i())*100.0])
		return
	if id=="diagnose":
		if not _target(): say("warn","No pump service order for this machine. Inspect its live condition.");return
		if _stage()!=1: say("warn","Compare the cooling loops before diagnosing this pump.");return
		ctl.act("diagnose","pump")
		if bool(_s().flags.get("engine.diagnosed",false)): say("ok","Low pump delivery diagnosed. Reduce turbine output before service.")
		return
	if id=="reduce":
		if _stage()!=2: say("warn","Diagnose this pump before reducing output.");return
		ctl.act("reduce_load")
		if float(_e().load)<=0.6: say("ok","Output reduced to 60% for cooling service.")
		return
	if id=="isolate":
		if _stage()!=3: say("fault","Diagnose the pump and reduce turbine output first.");return
		ctl.act("isolate")
		if _isolated(): say("ok","Pump %d loop isolated."%_n())
		return
	if id=="seal":
		if _stage()!=4: say("warn","Isolate the diagnosed pump before inspecting its seal.");return
		if not ctl.has_tool(): say("warn","Carry the engineering multitool from the crew wardrobe.");return
		_s().flags["engine.pump.1.seal_checked"]=true;_s().changed.emit()
		say("ok","Seal service check recorded; final coolant service occurs at the charge port.")
		return
	if id=="charge":
		if _stage()!=5: say("warn","Inspect the seal with the multitool before charging the isolated pump.");return
		ctl.act("engine_service")
		if _serviced(): say("ok","COOL-02 consumed once; pump delivery restored in the live model.")
		return
	if id=="restore":
		if _stage()!=6: say("warn","Complete the pump service before restoring the loop.");return
		ctl.act("restore")
		if not _isolated(): say("ok","Cooling loop restored. Wait for healthy readings.")
		return
	if id=="verify":
		if _stage()!=7: say("warn","Restore the serviced loop before verification.");return
		ctl.act("verify")
		if _s().completed.has("engine"): say("ok","Cooling verified after stable readings; return to the turbine.")
