extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 duct assembly. The HTML's physical section graphic is kept as
## separate transparent artwork; readings and interlocks come from the ship.

const STEPS := [
	{"do":"Compare the duct instruments.","why":"Read airflow, cabin CO₂ and oxygen separately."},
	{"do":"Record the supported fault.","why":"Low airflow and poor CO₂ removal require different service."},
	{"do":"Isolate the affected housing.","why":"Reserve air remains available while the service housing is open."},
	{"do":"Restore duct circulation.","why":"Service the correct component at its station first, then open the duct."},
	{"do":"Verify sustained healthy readings.","why":"Wait for the ship's steady-reading timer, then record verification."},
]
const DONE := {"do":"Duct airflow verified.","why":"The duty record retains the recovered readings."}
var ctl
var fb := {"s":"warn","t":"Read the live instruments before service."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font:
	return UI.artifact_font(kind,w,sp)

func setup(host_layer) -> void:
	ctl = host_layer
	if ctl.state.completed.has("life"): fb={"s":"ok","t":"Life-support readings were verified."}
	elif ctl.state.work_order_context=="first_watch": fb={"s":"","t":"Routine inspection only; no duct repair work order this watch."}

func _life() -> Dictionary: return ctl.state.systems.life
func _flag(k: String) -> bool: return bool(ctl.state.flags.get(k,false))
func _done() -> bool: return ctl.state.completed.has("life")
func _stage() -> int:
	if _done(): return 5
	if not _flag("life.observed"): return 0
	if not _flag("life.diagnosed"): return 1
	if not bool(_life().isolated) and not bool(_life().restored): return 2
	if bool(_life().isolated): return 3
	return 4

func _material(name: String,r: Rect2,modulate := Color.WHITE) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	if mats[name] != null: draw_texture_rect(mats[name],r,false,modulate)

func say(s: String,message: String) -> void:
	fb={"s":s,"t":message}; pop("duct:fb")

func paint() -> void:
	screen_bg()
	hud("Restore cabin airflow" if ctl.state.work_order_context != "first_watch" else "Inspect cabin airflow","LIFE SUPPORT · AIR DUCT ASSEMBLY","Step away")
	_duct()
	_instruments()
	_log()
	_controls()
	_paper()

func _module(name: String,r: Rect2,title: String) -> void:
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _duct() -> void:
	var r := Rect2(20,56,860,300)
	_module("air_duct_assembly_mod_0",r,"DUCT 2 · SECTION VIEW")
	var isolated: bool=bool(_life().isolated)
	var good: bool=float(_life().airflow)>=62.0 and float(_life().airflow)<=72.0 and float(_life().co2)<=0.1
	module_chip(r,"Isolated" if isolated else "Flow normal" if good else "Low flow","warn" if isolated else "ok" if good else "fault")
	B(Rect2(34,100,832,236),{"bg":Color("#102024"),"border":UI.EDGE,"insets":[[3,3,0,Color("#668087")],[-3,-3,0,Color("#060d10")]]})
	artifact_glass(Rect2(48,114,804,208))
	# The section illustration was rasterized directly from the artifact SVG.
	# Eight phase frames preserve its rotating fan and moving airflow streaks.
	var period := 1.2 if good else 3.0
	var frame := int(floorf(fposmod(now,period)/period*8.0))
	var variant := "isolated_00" if isolated else ("restored_" if good else "initial_")+"%02d" % frame
	_material("duct_"+variant,Rect2(49,116,800,204))
	artifact_glass_overlay(Rect2(48,114,804,208))

func _gauge(center: Vector2,light: bool,value: String,unit: String,angle: float,locked: bool) -> void:
	var name := "duct_gauge_0" if light else "duct_gauge_1"
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	var texture: Texture2D=mats[name]
	if locked:
		if not mats.has(name+"_locked"):
			mats[name+"_locked"]=ImageTexture.create_from_image(UI.filt_image(texture.get_image(),0.2,0.6))
		texture=mats[name+"_locked"]
	draw_texture_rect(texture,Rect2(center-Vector2(75,75),Vector2(150,150)),false)
	dim=locked
	var v := Vector2(sin(angle),-cos(angle))
	if not light: draw_line(center,center+v*59,C(Color("#7fe08a")),4)
	T(F("num"),22,value,center.x-64,center.y+28,Color("#1f2326") if light else Color("#7fe08a"),26,1,128)
	if not unit.is_empty(): T(F("label",400,0.7),10,unit,center.x-64,center.y+51,Color("#565b50") if light else Color("#7fe08a"),13,1,128)
	dim=false

func _instruments() -> void:
	var r := Rect2(900,56,360,300)
	_module("air_duct_assembly_mod_1",r,"INSTRUMENTS")
	# No differential-pressure sensor exists in the live model. Preserve the
	# instrument shape and show an explicitly unavailable reading.
	_gauge(Vector2(994,175),true,"—","PA",deg_to_rad(270),false)
	var flow: float=float(_life().airflow)
	_gauge(Vector2(1165,175),false,"%.0f%%" % flow,"",deg_to_rad(-135.0+clampf(flow,0,100)*2.7),_stage()==0)
	T(F("label",400,0.8),13,"FILTER ΔP",924,256,UI.TEXT,18,1,140)
	dim=_stage()==0
	T(F("label",400,0.8),13,"AIRFLOW · 62–72",1094,256,UI.TEXT,18,1,140)
	dim=false
	var co2: float=float(_life().co2)
	T(F("num"),19,"CABIN CO2",914,285,UI.PHOS_DIM,23)
	T(F("num"),19,"%.3f%%" % co2,914,285,UI.PHOS if co2<=0.1 else UI.WARN,23,2,332)
	T(F("num"),19,"RESERVE AIR",914,314,UI.PHOS_DIM,23)
	T(F("num"),19,("FEEDING" if bool(_life().isolated) else "STANDBY")+" · %.0f%%" % float(_life().reserve),914,314,UI.PHOS,23,2,332)
	hit("compare",Rect2(920,102,150,178));hit("diagnose",Rect2(1090,102,150,178))
	if _stage()==0: cue(Rect2(920,102,150,178))
	elif _stage()==1: cue(Rect2(1090,102,150,178))

func _log() -> void:
	var r := Rect2(20,368,680,120)
	_module("air_duct_assembly_mod_2",r,"AIRFLOW LOG · CURRENT READ")
	T(F("body"),16,"Band 62–72%",546,379,Color("#ddd8c8"),21)
	var g := Rect2(34,412,652,64)
	artifact_glass(g)
	R(Rect2(36,440,648,6),Color("#7fe08a",0.25))
	# Only the current reading is stored. Empty cells are not fabricated history.
	for i in range(12):
		var x := 46.0+i*53.7
		var h := 5.0 if i<11 else clampf(float(_life().airflow),0,100)*0.48
		R(Rect2(x,473-h,48,h),Color("#3a4448") if i<11 else UI.LIVE if float(_life().airflow)>=62 and float(_life().airflow)<=72 else UI.WARN)
	artifact_glass_overlay(g)

func _controls() -> void:
	var r := Rect2(720,368,540,336)
	_module("air_duct_assembly_mod_3",r,"DUCT 2 CONTROLS")
	var isolated: bool=bool(_life().isolated)
	var lock_r := Rect2(1118,370,112,30)
	B(lock_r,{"bg":Color("#1d180e"),"border":UI.EDGE})
	hazard(Rect2(1120,372,8,26),UI.WARN,Color("#1d180e"))
	T(F("label",400,0.7),13,"DUCT 2 ISOLATED" if isolated else "DUCT 2 LIVE",1130,375,UI.WARN,22,1,98)
	var st := _stage()
	push("isolate",720,420,160,"ISOLATE","","red",st<2 or st==4,false,106,50,16,15,-1,8,false)
	push("restore",909,420,160,"RESTORE","","done" if st>=4 else "",st<3,false,106,50,16,15,-1,8,false)
	push("verify",1107,420,160,"VERIFY","","working",st<4,false,106,50,16,15,-1,8,false)
	P(F("body"),15,"Close dampers · reserve air on",740,478,120,17.25,Color("#b4c3c1"),false,1)
	P(F("body"),15,"Open dampers · fan up",929,478,120,17.25,Color("#b4c3c1"),false,1)
	P(F("body"),15,"Wait for steady readings",1127,478,120,17.25,Color("#b4c3c1"),false,1)
	T(F("label",400,0.8),13,"STEADY READS",734,530,UI.LABEL,18)
	var ready: float=clampf(float(ctl.state.verification.get("life",0.0))/float(ctl.state.verify_seconds("life")),0.0,1.0)
	for i in range(3):
		var rr := Rect2(876+i*124,532,122,10)
		R(rr,UI.PHOS if ready >= float(i+1)/3.0 else Color("#0b1714"))
		R(Rect2(rr.position,Vector2(rr.size.x,1)),Color.BLACK)
	P(F("body"),16,"The filter is replaced at the air-filter service console. This panel only isolates, restores and proves the duct.",734,561,500,20,Color("#b4c3c1"))
	if st==2: cue(Rect2(747,420,106,55))
	elif st==3: cue(Rect2(936,420,106,55))
	elif st==4: cue(Rect2(1134,420,106,55))

func _paper() -> void:
	_material("air_duct_assembly_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<5 else DONE
	artifact_procedure(st,5,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if _done() and id in ["isolate","restore","verify"]: say("ok","Duct airflow is already verified.");return
	if id=="compare":
		if _stage()==0:
			ctl.act("observe")
			if _flag("life.observed"): say("ok","Live airflow %.0f%%; CO₂ %.3f%%; oxygen %.1f%%. Filter ΔP unavailable." % [float(_life().airflow),float(_life().co2),float(_life().oxygen)])
		else: say("warn","The live instrument readings are already recorded.")
		return
	if id=="diagnose":
		if not _flag("life.observed"): say("warn","Compare the live instruments first.");return
		if _flag("life.diagnosed"): say("ok","The supported fault is recorded.");return
		ctl.act("diagnose","scrubber" if ctl.state.phase=="return" else "airflow")
		if _flag("life.diagnosed"): say("ok","Fault diagnosis recorded from airflow and CO₂ readings.")
		return
	if id=="isolate":
		if _stage()<2: say("warn","Record the supported diagnosis first.");return
		if bool(_life().isolated): say("ok","Duct housing already isolated; reserve air remains available.");return
		ctl.act("isolate")
		if bool(_life().isolated): say("ok","Housing isolated. Service the diagnosed component at its station.")
		return
	if id=="restore":
		if not bool(_life().isolated): say("warn","The duct housing is not isolated.");return
		if not bool(_life().serviced): say("warn","Service the diagnosed filter or scrubber at its own station first.");return
		ctl.act("restore")
		if bool(_life().restored): say("ok","Duct circulation restored. Wait for sustained healthy readings.")
		return
	if id=="verify":
		if _done(): say("ok","Life-support verification already recorded.");return
		if not bool(_life().restored): say("warn","Restore the serviced duct first.");return
		ctl.act("verify")
		if _done(): say("ok","Healthy life-support readings verified in the duty record.")
