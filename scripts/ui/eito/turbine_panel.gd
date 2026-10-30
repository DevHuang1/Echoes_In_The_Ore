extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 main turbine. Each physical turbine displays its assigned loop.
## Cooling verified is a live, read-only engine result, never a sign-off button.

const STEPS := [
	{"do":"Look through the inspection port.","why":"Check the blades and the heat ring."},
	{"do":"Pull the lever back to the 60% detent.","why":"Less output, less heat while the diagnosed loop is serviced."},
	{"do":"Service and verify the diagnosed cooling loop.","why":"Full output waits for verified cooling."},
	{"do":"Push the lever to 100%.","why":"Cooling is back. Resume full output."},
]
const DONE := {"do":"Turbine at full output.","why":"The verified engine record retains the measured cooling state."}
var ctl
var fb := {"s":"warn","t":"Inspect this turbine and read the actual loop conditions."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func setup(host_layer) -> void: ctl=host_layer
func _s() -> Object: return ctl.state
func _e() -> Dictionary: return _s().systems.engine
func _number() -> int: return int(ctl.prop_id.get_slice(".",2))
func _loop() -> int: return 0 if _number() in [1,3] else 1
func _inspected() -> bool: return bool(_s().flags.get("engine.turbine.inspected."+str(_number()),false))
func _cooled() -> bool: return _s().completed.has("engine") and _s().engine_flow(_loop())>=0.9 and float(_e().temperature)<=65.0
func _limited() -> bool: return float(_e().load)<=0.6
func _stage() -> int:
	if not _inspected(): return 0
	if not _limited() and not _s().completed.has("engine"): return 1
	if not _cooled(): return 2
	if _limited(): return 3
	return 4

func _mat(name: String,r: Rect2) -> void:
	var path := "res://art/ui/eito/stations02/"
	if not mats.has(name): mats[name]=load(path+("graphics/" if name.begins_with("turbine_") and name not in ["turbine_mod_0","turbine_mod_1","turbine_mod_2","turbine_mod_3","turbine_paper_0"] else "materials/")+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("turbine:fb")

func paint() -> void:
	screen_bg()
	hud("Protect the turbine while cooling is short" if not _cooled() else "Resume full output","ENGINE ROOM · MAIN TURBINE","Step away")
	_port();_instruments();_lever();_paper();_cooling()

func _port() -> void:
	var r := Rect2(20,56,560,432)
	_module("turbine_mod_0",r,"TURBINE · INSPECTION PORT")
	module_chip(r,"Thrust limited" if _limited() else "Full output" if _cooled() else "Running hot","warn" if _limited() else "ok" if _cooled() else "fault")
	B(Rect2(34,100,532,370),{"grad":[[0.0,Color("#34494f")],[1.0,Color("#22333a")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]]})
	artifact_glass(Rect2(48,114,504,342))
	_mat("turbine_ring",Rect2(130,116,340,340))
	# Rotation is confined to the rotor blades. Equipment art, panel and HUD
	# stay in the original artifact orientation.
	var period := 3.0 if _limited() else 1.2
	var frame := int(fmod(now,period)/period*8.0)
	_mat("turbine_blades_frame_"+str(frame),Rect2(130,116,340,340))
	_mat("turbine_hub",Rect2(130,116,340,340))
	artifact_glass_overlay(Rect2(48,114,504,342))
	var port_text := "BLADES CLEAN · HEAT RING NORMAL" if _cooled() else "BLADES CLEAN · HEAT RING HIGH" if _inspected() else "INSPECTION PORT"
	R(Rect2(214,431,172,19),Color("#0b1416"))
	T(F("label",400,0.7),11,port_text,214,431,Color("#55e0d0"),19,1,172)
	hit("inspect",Rect2(34,100,532,370))
	if _stage()==0: cue(Rect2(34,100,532,370))

func _instruments() -> void:
	var r := Rect2(600,56,660,250)
	_module("turbine_mod_1",r,"INSTRUMENTS")
	_mat("turbine_tach_base",Rect2(614,100,190,190))
	# The gauge sweep visualizes commanded output. There is no live RPM sensor.
	draw_set_transform(Vector2(709,195),deg_to_rad(-135.0+float(_e().load)*220.0))
	_mat("turbine_tach_needle",Rect2(-95,-95,190,190))
	draw_set_transform(Vector2.ZERO)
	_mat("turbine_tach_hub",Rect2(614,100,190,190))
	T(F("num"),26,"%.0f%%"%(float(_e().load)*100.0),669,225,Color("#dfe9e6"),29,1,82)
	T(F("label"),10,"OUTPUT",669,251,Color("#9db3b4"),14,1,82)
	var glass := Rect2(822,114,424,138)
	artifact_glass(glass)
	var names := ["OUTPUT","TEMP","COOLING","THRUST"]
	var values := ["%.0f%%"%(float(_e().load)*100.0),"%.0f C"%float(_e().temperature),"LOOP %d · %.0f%%"%[_loop()+1,_s().engine_flow(_loop())*100.0],"LIMITED" if _limited() else "NOMINAL"]
	for i in range(4):
		var y := 126+i*29
		T(F("num"),21,names[i],836,y,UI.PHOS_DIM,27)
		T(F("num"),21,values[i],1010,y,UI.PHOS,27,2,220)
	artifact_glass_overlay(glass)
	lamp(Vector2(822,258),"warn" if _limited() else "off")
	T(F("label"),12,"THRUST LIMITED",850,257,UI.TEXT,18)
	lamp(Vector2(1036,258),"ok" if _cooled() else "off")
	T(F("label"),12,"COOLING VERIFIED",1064,257,UI.TEXT,18)

func _lever() -> void:
	var r := Rect2(600,318,660,170)
	_module("turbine_mod_2",r,"OUTPUT LEVER")
	T(F("body"),16,"Detents 60 · 100",1070,325,Color("#ddd8c8"),28,2,165)
	B(Rect2(654,416,552,14),{"bg":Color("#10171a"),"border":UI.EDGE})
	for n in range(6):
		var x := 654+n*110.4
		R(Rect2(x,430,2,8),Color("#9db3b4"))
		T(F("label"),12,str(n*20),x-20,440,UI.TEXT,20,1,40)
	_key("reduce",Rect2(953.19,362,64,38),"60",_stage()==1)
	_key("resume",Rect2(1174,362,64,38),"100",_stage()==3)
	var hx := 654+552*float(_e().load)
	B(Rect2(hx-15,402,30,40),{"grad":[[0.0,Color("#e0763a")],[1.0,Color("#a8501f")]],"border":UI.EDGE})
	if _stage()==1: cue(Rect2(953.19,362,64,38))
	if _stage()==3: cue(Rect2(1174,362,64,38))

func _key(id: String,r: Rect2,label: String,guided: bool) -> void:
	artifact_key(id,r,label,false,not guided)

func _paper() -> void:
	_mat("turbine_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<4 else DONE
	artifact_procedure(st,4,str(cur.do),str(cur.why),fb)

func _cooling() -> void:
	var r := Rect2(720,500,540,204)
	_module("turbine_mod_3",r,"FROM COOLANT LOOP %d"%(_loop()+1))
	module_chip(r,"Verified" if _cooled() else "Waiting","ok" if _cooled() else "off")
	B(Rect2(734,546,174,53),{"grad":[[0.0,Color("#7fd685") if _cooled() else Color("#9aa6a4")],[1.0,Color("#4c9f52") if _cooled() else Color("#68716f")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#c9f5c9") if _cooled() else Color("#c4cfca")],[-2,-2,0,Color("#2c6a31") if _cooled() else Color("#394442")]],"outer":[[0,6,0,UI.EDGE]]})
	T(F("label",400,0.64),14,"PUMP VERIFIED" if _cooled() else "PUMP PENDING",734,546,UI.INK,53,1,174)
	P(F("body"),16,"Read-only status. This lights when the diagnosed cooling loop is verified at its own station.",923,547,315,20,Color("#b4c3c1"))

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id=="inspect":
		ctl.act("turbine")
		_s().flags["engine.turbine.inspected."+str(_number())]=true
		_s().changed.emit()
		say("ok","Turbine %d inspection recorded. Loop %d flow %.0f%%."%[_number(),_loop()+1,_s().engine_flow(_loop())*100.0]);return
	if id=="reduce":
		if _stage()!=1: say("warn","Inspect and diagnose the cooling fault before reducing output.");return
		ctl.act("reduce_load")
		if _limited(): say("ok","Output reduced to 60%; thrust limited during service.")
		return
	if id=="resume":
		if not _cooled(): say("fault","Cooling is not verified. Full output is blocked.");return
		ctl.act("resume_output")
		if not _limited(): say("ok","Nominal output restored after verified cooling.")
