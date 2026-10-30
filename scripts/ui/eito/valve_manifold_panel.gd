extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 three-handwheel manifold. The ship models one valve opening per
## cooling loop, so the centre wheel is the service target only for the assigned
## return-watch valve. The outer wheels are illustrated, not separate sensors.

const STEPS := [
	{"do":"Compare the cooling-loop readings.","why":"A restricted valve can lower flow even when the pump is healthy."},
	{"do":"Find the restricted valve.","why":"Check the centre handwheel against the live loop opening."},
	{"do":"Isolate the diagnosed loop.","why":"Reduce turbine output to 60% first; keep the other loop available."},
	{"do":"Open the diagnosed valve fully.","why":"The multitool and isolated loop are required for service."},
	{"do":"Restore the loop.","why":"Cancel service isolation, then watch flow and temperature."},
	{"do":"Verify recovered cooling.","why":"Hold healthy readings for the real six-second observation."},
]
const DONE := {"do":"Cooling loop verified.","why":"The engine record retains the repaired opening and stable readings."}
var ctl
var fb := {"s":"warn","t":"Read this loop before handling a valve."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func setup(host_layer) -> void: ctl=host_layer
func _s() -> Object: return ctl.state
func _e() -> Dictionary: return _s().systems.engine
func _loop() -> int: return int(ctl.prop_id.get_slice(".",2))-1
func _target() -> bool: return ctl.prop_id=="engine.valve.2" and _s().phase=="return"
func _opening() -> float: return float(_e().valves[_loop()])
func _isolation() -> bool: return bool(_e().isolated[_loop()])
func _service() -> bool: return bool(_e().serviced) and _opening()>=0.99
func _restored() -> bool: return _service() and not _isolation()
func _stage() -> int:
	if _s().completed.has("engine"): return 6
	if not bool(_s().flags.get("engine.observed",false)): return 0
	if not bool(_s().flags.get("engine.diagnosed",false)): return 1
	if not _isolation(): return 2 if not _service() else 5
	if not _service(): return 3
	return 4
func _turns() -> int: return int(_s().flags.get("engine.valve.2.service_turns",0))
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("valve:fb")

func _mat(name: String,r: Rect2,graphics := false) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/"+("graphics/" if graphics else "materials/")+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func paint() -> void:
	screen_bg()
	hud("Clear the restriction in the feed line" if _target() else "Inspect the cooling valve manifold","ENGINE ROOM · VALVE MANIFOLD","Step away")
	_manifold();_paper();_control()

func _manifold() -> void:
	var r := Rect2(20,56,1240,432)
	_module("valve_manifold_mod_0",r,"FEED MANIFOLD · 3 VALVES")
	module_chip(r,"Restricted" if _opening()<0.9 else "Feed normal" if _restored() else "Line live","fault" if _opening()<0.9 else "ok")
	B(Rect2(34,100,1212,370),{"bg":Color("#1b2326"),"border":UI.EDGE})
	for x in range(37,1246,12): R(Rect2(x+6,103,6,364),Color("#222c30"))
	var flow_art := "valve_manifold_isolated"
	if not _isolation():
		var good := _restored()
		var period := 0.6 if good else 1.6
		flow_art="valve_manifold_"+("good" if good else "low")+"_"+str(int(floorf(fposmod(now,period)/period*4.0)))
	_mat(flow_art,Rect2(37,103,1234,364),true)
	_gauge("valve_up_gauge_base",Rect2(97,133,150,190),"UPSTREAM")
	_gauge("valve_down_gauge_base",Rect2(1057,133,150,190),"DOWNSTREAM")
	for i in range(3): _wheel(i)
	if _stage()==0:
		cue(Rect2(97,133,150,190));cue(Rect2(1057,133,150,190))

func _gauge(name: String,r: Rect2,id: String) -> void:
	_mat(name,r,true)
	# Pressure values are absent from the runtime sensor model. Retain the exact
	# dial art and the readout position without inventing a bar value or needle.
	T(F("num"),24,"—",r.position.x+36,r.position.y+86,UI.INK,28,1,78)
	# Captions are drawn here in the artifact's Silkscreen; the dial art carries none.
	T(F("label"),9,"BAR",r.position.x+35,r.position.y+119,Color("#565b50"),12,1,80)
	T(F("label"),11,id,r.position.x,r.position.y+162,Color("#dfe9e6"),14,1,150)
	hit("compare",r)

func _wheel(i: int) -> void:
	var x := 317.0+i*290.0
	var opening := _opening() if i==1 else 1.0
	var turns := _turns() if i==1 else 0
	var art := "valve_wheel_2" if i==1 and opening<0.9 and turns==0 else "valve_wheel_1"
	if i==1 and turns>0 and opening<0.9:
		draw_set_transform(Vector2(x+75,192),deg_to_rad(-90.0*turns))
		_mat("valve_wheel_2",Rect2(-75,-75,150,150),true)
		draw_set_transform(Vector2.ZERO)
	else: _mat(art,Rect2(x,117,150,150),true)
	var pct := opening*100.0
	var stem := Rect2(x+62,267,26,50)
	B(stem,{"bg":Color("#10171a"),"border":UI.EDGE})
	R(Rect2(stem.position.x+3,stem.end.y-3-(stem.size.y-6)*opening,stem.size.x-6,(stem.size.y-6)*opening),Color("#7fe08a") if opening>=0.9 else Color("#e0763a"))
	B(Rect2(x+40,317,70,22),{"bg":Color("#6f807c"),"border":UI.EDGE})
	B(Rect2(x+33,410,84,25),{"bg":Color("#efe8d4"),"border":UI.EDGE})
	T(F("label"),13,"VALVE %d"%(i+1),x+33,412,UI.INK,21,1,84)
	var txt := ("%.0f%% OPEN"%pct if opening<0.99 else "OPEN") if i==1 else "SCHEMATIC"
	T(F("num"),20,txt,x+4,435,Color("#7fe08a") if opening>=0.99 else Color("#e0763a"),24,1,142)
	hit("wheel:"+str(i),Rect2(x,117,150,150),{"fixed":i!=1})
	if i==1 and _stage() in [1,3]: cue(Rect2(x,117,150,150))

func _paper() -> void:
	_mat("valve_manifold_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<6 else DONE
	artifact_procedure(st,6,str(cur.do),str(cur.why),fb)

func _control() -> void:
	var r := Rect2(720,500,540,204)
	_module("valve_manifold_mod_1",r,"LINE CONTROL")
	var lock_text := "ISOLATED · BYPASS ON" if _isolation() else "LINE LIVE"
	var lock_width := 204.0 if _isolation() else 101.0
	var lock_x := 1233.0-lock_width
	B(Rect2(lock_x,502,lock_width,30),{"bg":Color("#1d180e"),"border":UI.EDGE})
	hazard(Rect2(lock_x+2,504,8,26),UI.WARN,Color("#1d180e"))
	T(F("label",400,0.7),13,lock_text,lock_x+14,507,UI.WARN,22,1,lock_width-16)
	_push("isolate",Rect2(766,544,104,50),"ISOLATE","Bypass on · feed held",_stage()==2 and _e().load<=0.6)
	_push("restore",Rect2(945,544,110,50),"RESTORE","Bypass off",_stage()==4)
	_push("verify",Rect2(1123,544,98,50),"VERIFY","Stable cooling",_stage()==5)
	T(F("num"),18,"LOOP %d FLOW"%(_loop()+1),733,655,UI.PHOS_DIM,28)
	T(F("num"),22,"%.0f%%"%(_s().engine_flow(_loop())*100.0),1096,655,UI.PHOS,28,2,147)

func _push(id: String,r: Rect2,label: String,caption: String,ready: bool) -> void:
	# The reference leaves completed controls colored. Their hit regions stay
	# locked, so this presentation cannot repeat a repair or verification.
	var done := _stage()==6
	var restored := done and id=="restore"
	var face := Rect2(r.position+Vector2(0,3),r.size) if restored else r
	dim=not ready and not done
	B(face,{"grad":[[0.0,Color("#8adcf2") if id=="verify" else Color("#e46a52") if id=="isolate" else Color("#7fd685") if restored else Color("#cfc7a8")],[1.0,Color("#4aa4c2") if id=="verify" else Color("#b43c28") if id=="isolate" else Color("#4c9f52") if restored else Color("#a9a083")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#c9f5c9") if restored else Color("#f0ead2")],[-2,-2,0,Color("#2c6a31") if restored else Color("#7e7660")]],"outer":[[0,3 if restored else 6,0,UI.EDGE]]})
	T(F("label",400,0.65),15,label,face.position.x,face.position.y,Color("#fff2e8") if id=="isolate" else UI.INK,face.size.y,1,face.size.x)
	dim=false
	P(F("body"),15,caption,r.position.x-20,r.end.y+9,r.size.x+40,18,Color("#b4c3c1"),false,1)
	hit(id,r,{"locked":not ready})
	if ready: cue(r)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id=="compare":
		ctl.act("observe")
		if bool(_s().flags.get("engine.observed",false)): say("ok","Loop %d flow %.0f%%; valve opening %.0f%%. Pressure sensors are unavailable."%[_loop()+1,_s().engine_flow(_loop())*100.0,_opening()*100.0])
		return
	if id.begins_with("wheel:"):
		var n := int(id.trim_prefix("wheel:"))
		if n!=1: say("warn","This outer handwheel has no separate gameplay valve or reading.");return
		if not _target(): say("warn","No service order for this manifold. Inspect its live loop status.");return
		if _stage()==1:
			ctl.act("diagnose","valve")
			if bool(_s().flags.get("engine.diagnosed",false)): say("ok","Valve 2 restriction diagnosed; reduce output at the turbine.")
			return
		if _stage()!=3: say("warn","Diagnose, reduce output and isolate the loop before turning this valve.");return
		if not ctl.has_tool(): say("warn","Carry the engineering multitool from the crew wardrobe.");return
		var turns := _turns()+1
		if turns<3:
			_s().flags["engine.valve.2.service_turns"]=turns;_s().changed.emit()
			say("ok","Handwheel service turn %d of 3. The live valve opening remains %.0f%% until service is complete."%[turns,_opening()*100.0])
		else:
			ctl.act("engine_service")
			if _service(): say("ok","Valve 2 opened fully in the live cooling model.")
		return
	if id=="isolate":
		if float(_e().load)>0.6: say("fault","Reduce turbine output to 60% before isolating this loop.");return
		if not _target() or _stage()!=2: say("warn","Diagnose the assigned valve restriction first.");return
		ctl.act("isolate")
		if _isolation(): say("ok","Loop %d isolated for valve service."%(_loop()+1))
		return
	if id=="restore":
		if _stage()!=4: say("warn","Complete valve service before restoring the loop.");return
		ctl.act("restore")
		if _restored(): say("ok","Loop restored. Wait for stable cooling readings.")
		return
	if id=="verify":
		if _stage()!=5: say("warn","Restore the serviced line before verifying cooling.");return
		ctl.act("verify")
		if _s().completed.has("engine"): say("ok","Engine cooling verified after stable readings.")
