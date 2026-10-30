extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 scrubber board. The two-bed drawing remains an equipment mimic;
## only the aggregate scrubber/CO2 values reported by the ship are treated as
## measurements. Service consumes the real SCRUB-A inventory item once.

const STEPS := [
	{"do":"Read the cabin CO₂ level.","why":"Compare the current value with the 0.10% limit."},
	{"do":"Compare scrubber performance.","why":"Normal airflow with high CO₂ points to removal, not the filter."},
	{"do":"Isolate the scrubber housing.","why":"Keep reserve air available while the service housing is open."},
	{"do":"Undo the hatch clamp with the multitool.","why":"The service canister is held by a clamp bolt."},
	{"do":"Replace the canister with SCRUB-A.","why":"Use the labelled medium carried from shared stores."},
	{"do":"Restore the scrubber.","why":"Restart circulation after the canister is secured."},
	{"do":"Verify CO₂ removal.","why":"Wait for sustained healthy readings below 0.10%."},
]
const DONE := {"do":"Scrubber verified.","why":"Cabin CO₂ has remained below its limit."}
const NEED := ["Read the cabin CO₂ first.","Compare removal performance first.","Isolate the housing first.","Undo the clamp first.","Replace the medium first.","Restore circulation first.","Wait for healthy readings before verifying."]
var ctl
var fb := {"s":"warn","t":"Cabin CO₂ is above the limit."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func _s() -> Object: return ctl.state
func _life() -> Dictionary: return _s().systems.life
func _flag(k: String) -> bool: return bool(_s().flags.get(k,false))
func _stage() -> int:
	if _s().completed.has("life"): return 7
	if not _flag("life.observed"): return 0
	if not _flag("life.diagnosed"): return 1
	if bool(_life().isolated):
		if not _flag("life.scrubber.unbolted"): return 3
		if not bool(_life().serviced): return 4
		return 5
	if bool(_life().restored): return 6
	return 2

func setup(host_layer) -> void:
	ctl=host_layer
	if _s().work_order_context=="first_watch": fb={"s":"","t":"Routine inspection only; no scrubber repair order this watch."}
	elif _s().completed.has("life"): fb={"s":"ok","t":"Life-support readings were verified."}

func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("scrubber:fb")
func _material(name: String,r: Rect2) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)

func paint() -> void:
	screen_bg()
	hud("Bring cabin CO₂ back down","LIFE SUPPORT · CO₂ SCRUBBER","Step away")
	_mimic()
	_co2()
	_performance()
	_hatch()
	_paper()

func _module(name: String,r: Rect2,title: String) -> void:
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _mimic() -> void:
	var r := Rect2(20,56,700,432)
	_module("co2_air_scrubber_mod_0",r,"SWING BEDS · MIMIC")
	var iso: bool=bool(_life().isolated)
	var good: bool=float(_life().co2)<=0.1 and float(_life().scrubber)>=0.9
	module_chip(r,"Circulation restored" if good else "Housing isolated" if iso else "Removal low","ok" if good else "warn" if iso else "fault")
	B(Rect2(34,100,672,376),{"bg":Color("#102024"),"border":UI.EDGE,"insets":[[3,3,0,Color("#668087")],[-3,-3,0,Color("#060d10")]]})
	artifact_glass(Rect2(48,114,644,348))
	_material("scrubber_mimic_restored" if good else "scrubber_mimic_isolated" if iso else "scrubber_mimic_initial",Rect2(50,116,644,340))
	artifact_glass_overlay(Rect2(48,114,644,348))
	T(F("label",400,0.65),11,"CABIN AIR IN · CO₂ %.3f%%" % float(_life().co2),60,146,UI.WARN,16)
	T(F("label",400,0.65),13,"BED A · MEDIA HOUSING",138,263,Color("#e0763a") if not good else Color("#55e0d0"),18,1,190)
	T(F("label",400,0.65),13,"BED B · AIR PATH",432,263,Color("#55e0d0"),18,1,150)

func _co2() -> void:
	var r := Rect2(740,56,520,212)
	_module("co2_air_scrubber_mod_1",r,"CABIN CO₂ · CURRENT")
	T(F("body"),16,"Limit 0.10%",1133,67,Color("#ddd8c8"),21,2,112)
	var g := Rect2(754,100,492,140)
	artifact_glass(g)
	for y in [152.0,212.0]: R(Rect2(756,y,488,1),Color("#2a3a3c"))
	for x in range(756,1240,14): R(Rect2(x,151,8,2),Color("#e0763a"))
	T(F("num"),16,"0.10%",760,133,Color("#e0763a"),19)
	var co2: float=float(_life().co2)
	var yy := clampf(151.0-(co2-0.1)*400.0,111,223)
	R(Rect2(1209,yy-3,16,6),UI.LIVE if co2<=0.1 else UI.WARN)
	T(F("num"),18,"NOW %.3f%%" % co2,1080,222,UI.PHOS,22,2,160)
	artifact_glass_overlay(g)
	hit("compare",Rect2(754,100,492,140))
	if _stage()==0: cue(Rect2(754,100,492,140))

func _performance() -> void:
	var r := Rect2(740,280,520,208)
	_module("co2_air_scrubber_mod_2",r,"SCRUBBER PERFORMANCE")
	T(F("body"),16,"Live system",1138,291,Color("#ddd8c8"),21,2,105)
	var val: float=float(_life().scrubber)*100.0
	dim=_stage()==0
	T(F("label",400,0.72),12,"REMOVAL",754,332,UI.TEXT,20)
	for i in range(10):
		var rr := Rect2(824+i*35.6,332,34,10)
		R(rr,UI.PHOS if i < int(ceilf(val/10.0)) else Color("#0b1714"))
		R(Rect2(rr.position,Vector2(rr.size.x,1)),Color.BLACK)
	T(F("num"),26,"%.0f%%" % val,1180,325,UI.TEXT,32,2,65)
	T(F("label",400,0.72),12,"BED",754,362,UI.TEXT,16)
	T(F("label",400,0.72),12,"DETAIL",754,378,UI.TEXT,16)
	for i in range(10): R(Rect2(824+i*35.6,373,34,10),Color("#0b1714"))
	T(F("num"),26,"N/A",1180,363,UI.TEXT,32,2,65)
	dim=false
	P(F("body"),16,"Individual bed saturation is not measured. Compare the ship's scrubber performance with cabin CO₂ and airflow.",754,405,490,20,Color("#b4c3c1"))
	hit("diagnose",Rect2(750,322,500,74))
	if _stage()==1: cue(Rect2(750,322,500,74))

func _hatch() -> void:
	var r := Rect2(720,500,540,204)
	_module("co2_air_scrubber_mod_3",r,"SERVICE HATCH")
	var iso: bool=bool(_life().isolated)
	B(Rect2(1027,502,204,30),{"bg":Color("#1d180e"),"border":UI.EDGE})
	hazard(Rect2(1029,504,8,26),UI.WARN,Color("#1d180e"))
	T(F("label",400,0.7),13,"SAFE TO OPEN" if iso else "LIVE · DO NOT OPEN",1039,507,UI.WARN,22,1,190)
	var st := _stage()
	push("isolate",732,563,128,"ISOLATE","","red",st<2 or st>=4,false,112,50,16,15,-1,8,false)
	T(F("body"),16,"Reserve air",732,619,Color("#b4c3c1"),18,1,128)
	T(F("body"),16,"online",732,637,Color("#b4c3c1"),18,1,128)
	dim=st!=3
	var hex := PackedVector2Array([Vector2(919,550),Vector2(944,564),Vector2(944,594),Vector2(919,608),Vector2(894,594),Vector2(894,564)])
	draw_colored_polygon(hex,C(Color("#9db3b4")));draw_polyline(hex,C(UI.EDGE),3,true)
	draw_circle(Vector2(919,579),10,C(Color("#3a4448")))
	draw_line(Vector2(919,570),Vector2(919,589),C(UI.WARN),4)
	P(F("body"),16,"Clamp · multitool",874,617,90,18,UI.TEXT,false,1)
	dim=false
	hit("unbolt",Rect2(872,546,96,110),{"locked":st!=3})
	var cr := Rect2(1006,554,70,60)
	dim=st!=4
	B(cr,{"bg":UI.PAPER if bool(_life().serviced) else Color("#8a7a52"),"border":UI.EDGE})
	B(Rect2(1000,548,82,18),{"bg":Color("#3a4448"),"border":UI.EDGE})
	T(F("label",400,0.55),10,"SCRUB-A" if bool(_life().serviced) else "SPENT",1006,582,UI.INK,15,1,70)
	P(F("body"),16,"Twist-lock canister",990,617,108,18,UI.TEXT,false,1)
	dim=false
	hit("swap",Rect2(982,546,116,110),{"locked":st!=4})
	push("restore",1105,546,130,"RESTORE","","done" if st>=6 else "",st<5,false,110,50,16,15,-1,8,false)
	push("verify",1105,604,130,"VERIFY","","working" if st==6 else "done" if st==7 else "",st<6,false,110,50,16,15,-1,8,false)
	if st==2: cue(Rect2(740,563,112,50))
	elif st==3: cue(Rect2(872,546,96,110))
	elif st==4: cue(Rect2(982,546,116,110))
	elif st==5: cue(Rect2(1115,546,110,50))
	elif st==6: cue(Rect2(1115,604,110,50))

func _paper() -> void:
	_material("co2_air_scrubber_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<7 else DONE
	artifact_procedure(st,7,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	var st := _stage()
	if st==7: say("ok","Scrubber already verified.");return
	if id != ["compare","diagnose","isolate","unbolt","swap","restore","verify"][st]: say("warn",NEED[st]);return
	if st==0:
		ctl.act("observe")
		if _flag("life.observed"): say("ok","Cabin CO₂ %.3f%%; airflow %.0f%%; removal %.0f%%." % [float(_life().co2),float(_life().airflow),float(_life().scrubber)*100.0])
	elif st==1:
		ctl.act("diagnose","scrubber")
		if _flag("life.diagnosed"): say("ok","High CO₂ with normal airflow supports scrubber service.")
	elif st==2:
		ctl.act("isolate")
		if bool(_life().isolated): say("ok","Scrubber housing isolated; reserve air remains online.")
	elif st==3:
		if not ctl.has_tool(): say("warn","Carry the engineering multitool to release this clamp.");return
		_s().flags["life.scrubber.unbolted"]=true;_s().changed.emit()
		say("ok","Service clamp released with the multitool.")
	elif st==4:
		if _s().inventory.inventory_count(&"scrubber_media")<1: say("warn","Carry SCRUB-A from shared stores before replacing the canister.");return
		ctl.act("scrubber_service")
		if bool(_life().serviced): say("ok","SCRUB-A medium installed and the service hatch secured.")
	elif st==5:
		ctl.act("restore")
		if bool(_life().restored): say("ok","Scrubber circulation restored. Wait for healthy readings.")
	elif st==6:
		ctl.act("verify")
		if _s().completed.has("life"): say("ok","Sustained healthy CO₂ removal verified.")
