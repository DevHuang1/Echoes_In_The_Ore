extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 oxygen rack. The three-vessel drawing is retained, while only
## the ship's aggregate reserve and cabin oxygen are reported as readings.
## Valve handling is a guided service checklist; the final check invokes the
## existing one-time O2-01 reserve swap.

const STEPS := [
	{"do":"Read the reserve gauge.","why":"Swap the reserve only when it is below 50%."},
	{"do":"Confirm the cabin line is still fed.","why":"Keep the main oxygen path available during reserve service."},
	{"do":"Close the reserve service valve.","why":"Isolate the depleted bank before removing it."},
	{"do":"Remove the depleted reserve bank.","why":"Only after its service valve is shut."},
	{"do":"Fit the labelled O2-01 cylinder.","why":"O2-01 is oxygen; coolant and inert gas are not substitutes."},
	{"do":"Open the replacement bank valve.","why":"Reconnect the labelled reserve to the cabin path."},
	{"do":"Check cabin oxygen and reserve.","why":"Confirm the actual ship readings before recording the swap."},
]
const DONE := {"do":"Oxygen reserve swapped.","why":"The O2-01 issue and reserve reading are recorded."}
const NEED := ["Read the reserve gauge first.","Confirm the cabin line first.","Close the service valve first.","Remove the depleted bank first.","Fit O2-01 first.","Open its service valve first.","Check cabin oxygen and reserve."]
var ctl
var fb := {"s":"warn","t":"Read the reserve before handling a cylinder."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func _s() -> Object: return ctl.state
func _life() -> Dictionary: return _s().systems.life
func _stage() -> int:
	if bool(_s().transactions.get(_s().phase+".life.reserve",false)): return 7
	var i := 0
	while i<7 and bool(_s().flags.get("life.oxygen.stage."+str(i+1),false)): i+=1
	return i

func setup(host_layer) -> void:
	ctl=host_layer
	if _stage()==7: fb={"s":"ok","t":"O2-01 reserve swap recorded."}
	elif float(_life().reserve)>=50: fb={"s":"","t":"Reserve is above the 50% issue threshold; inspect only."}

func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("oxygen:fb")
func _advance() -> void:
	_s().flags["life.oxygen.stage."+str(_stage()+1)]=true
	_s().changed.emit()
func _material(name: String,r: Rect2) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)

func paint() -> void:
	screen_bg()
	hud("Swap the low oxygen reserve" if float(_life().reserve)<50 else "Inspect oxygen reserve","LIFE SUPPORT · O₂ SUPPLY RACK","Step away")
	_rack()
	_regulator()
	_spare()
	_paper()

func _module(name: String,r: Rect2,title: String) -> void:
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _rack() -> void:
	var r := Rect2(20,56,820,432)
	_module("oxygen_tank_rack_mod_0",r,"RACK · 3 POSITIONS")
	module_chip(r,"Main line fed","ok")
	B(Rect2(34,100,792,370),{"bg":Color("#1b2326"),"border":UI.EDGE})
	for y in range(105,467,12): R(Rect2(37,y,786,6),Color("#222c30"))
	R(Rect2(57,138,760,10),Color("#9db3b4"))
	for x in range(57,817,10): R(Rect2(x+fmod(now*12.5,10.0),141,3,4),Color("#7fe08a"))
	T(F("label",400,0.7),11,"TO CABIN →",712,115,UI.TEXT,16,2,100)
	for i in range(3): _tank(i)

func _tank(i: int) -> void:
	var x := 107.0+i*260.0
	var st := _stage()
	var present := i!=1 or st<4 or st>=5
	var valve_shut := i==1 and st>=3 and st<6 or i==2 and st<2
	_material("oxygen_valve_shut" if valve_shut else "oxygen_valve_open",Rect2(x+30,155,80,44))
	if present:
		_material("oxygen_tank" if i==1 else "oxygen_tank_plain",Rect2(x,205,140,250))
		var pct := float(_life().reserve) if i==1 and (st<5 or st>=7) else -1.0
		if pct>=0:
			var a := deg_to_rad(-135.0+clampf(pct,0,100)*2.7)
			var center := Vector2(x+70,325)
			draw_line(center,center+Vector2(sin(a),-cos(a))*30,Color("#1f2326"),3)
		T(F("num"),16,"%.0f%%" % pct if pct>=0 else "PENDING" if i==1 and st>=5 else "—",x+22,332,UI.INK,20,1,96)
		T(F("label",400,0.7),13,"O2-01" if i==1 and st>=5 else "RESERVE" if i==1 else "MAIN",x+20,398,UI.WARN,18,1,100)
	else: T(F("label",400,0.7),12,"EMPTY BAY",x+20,344,UI.PHOS,18,1,100)
	T(F("label",400,0.65),10,"BANK %d · %s" % [i+1,"RESERVE" if i==1 else "MAIN"],x+4,420,Color("#9db3b4"),14,1,132)
	hit("tank:"+str(i),Rect2(x,205,140,250))
	hit("valve:"+str(i),Rect2(x+30,155,80,44))
	if i==1 and st in [0,3,4]: cue(Rect2(x,205,140,250))
	if i==1 and st in [2,5] or i==2 and st==1: cue(Rect2(x+30,155,80,44))

func _regulator() -> void:
	var r := Rect2(860,56,400,432)
	_module("oxygen_tank_rack_mod_1",r,"REGULATOR · CABIN")
	_material("oxygen_regulator",Rect2(960,100,200,200))
	T(F("num"),26,"— kPa",978,229,UI.INK,33,1,164)
	var glass := Rect2(890,308,340,110)
	artifact_glass(glass)
	T(F("num"),19,"CABIN O₂",906,327,UI.PHOS_DIM,22)
	T(F("num"),26,"%.1f%%" % float(_life().oxygen),906,324,UI.PHOS,29,2,310)
	T(F("num"),19,"RESERVE",906,359,UI.PHOS_DIM,22)
	T(F("num"),19,"%.0f%%" % float(_life().reserve),906,359,UI.PHOS,22,2,310)
	T(F("num"),19,"SWAP BELOW",906,388,UI.PHOS_DIM,22)
	T(F("num"),19,"50%",906,388,UI.PHOS,22,2,310)
	artifact_glass_overlay(glass)
	push("check",972,428,176,"CHECK OUTLET","","working" if _stage()==6 else "done" if _stage()==7 else "",_stage()!=6,false,160,50,16,15,-1,8,false)
	if _stage()==6: cue(Rect2(980,428,160,50))

func _spare() -> void:
	_material("oxygen_tank_rack_paper_1",Rect2(720,500,540,204))
	T(F("label",400,0.65),13,"SPARE CYLINDER · FROM RACK",738,516,Color("#6a5a2a"),18)
	draw_set_transform(Vector2(1120,518),deg_to_rad(-6.0))
	B(Rect2(0,0,124,43),{"border":Color("#394149"),"bw":3})
	T(F("label",400,1.1),22,"FITTED" if _stage()>=5 else "READY",12,5,Color("#394149"),29,1,100)
	draw_set_transform(Vector2.ZERO)
	var c := Vector2(773,602)
	var pts := PackedVector2Array([c+Vector2(0,-31),c+Vector2(31,0),c+Vector2(0,31),c+Vector2(-31,0)])
	draw_colored_polygon(pts,UI.WARN);draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),UI.EDGE,3)
	T(F("label"),12,"5.1",745,594,UI.INK,18,1,56)
	T(F("label",400,1.1),24,"O2-01",824,565,UI.INK,31)
	T(F("body"),16,"Oxygen · oxidiser. White shoulder. Full: 100%.",824,596,UI.INK_2,20.8)
	T(F("body"),16,"No oil or grease on the fittings.",824,617,UI.INK_2,20.8)

func _paper() -> void:
	_material("oxygen_tank_rack_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<7 else DONE
	artifact_procedure(st,7,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	var st := _stage()
	if st==7: say("ok","Oxygen reserve swap already recorded.");return
	var expected := ["tank:1","valve:2","valve:1","tank:1","tank:1","valve:1","check"]
	if id!=expected[st]:
		if id=="tank:0" or id=="valve:0": say("warn","The unmeasured main path is not this reserve service target.")
		elif id=="tank:1" and st<3: say("fault","Close the reserve service valve before removing a bank.")
		else: say("warn",NEED[st])
		return
	if st==0 and float(_life().reserve)>=50: say("ok","Reserve %.0f%% is above the 50%% swap threshold. No cylinder issue needed." % float(_life().reserve));return
	if st==4 and _s().inventory.inventory_count(&"oxygen_reserve")<1: say("warn","Carry the labelled O2-01 cylinder from the cargo rack first.");return
	if st==6:
		ctl.act("oxygen_reserve")
		if _stage()==7: say("ok","O2-01 issued and reserve restored to %.0f%%; cabin O₂ %.1f%%." % [float(_life().reserve),float(_life().oxygen)])
		return
	_advance()
	say("ok",["Reserve %.0f%% is below the swap threshold." % float(_life().reserve),"Cabin oxygen path checked; proceed with the reserve.","Reserve service valve marked closed.","Depleted bank removed from the service bay.","Labelled O2-01 positioned for replacement.","Replacement valve marked open."][st])
