extends "res://scripts/ui/eito/eito_screen.gd"
## The filter housing board from Stations 02. Its eight visible manipulations
## culminate in the existing one-time air_filter service receipt.

const STEPS := [
	{"do":"Open the left latch.","why":"Over-centre latches hold the housing shut."},
	{"do":"Open the right latch.","why":"Both must be open before the cartridge moves."},
	{"do":"Pull out the old cartridge.","why":"Use the handle under the bay."},
	{"do":"Pick the replacement cartridge.","why":"Duct 2 takes FILTER-A."},
	{"do":"Turn the arrow towards the fan, then insert.","why":"The AIRFLOW arrow must point to the fan side."},
	{"do":"Pull the seat lever down.","why":"It presses the gasket onto the frame."},
	{"do":"Close both latches.","why":"They clamp the housing over the gasket."},
	{"do":"Set airflow inside the band, then confirm.","why":"The live setting must be 62–72% before service can be recorded."},
]
const DONE := {"do":"Filter replaced.","why":"Go back to the air duct panel and restore duct 2."}
const NEED := ["Open the left latch first.","Open the right latch first.","Pull the old cartridge first.","Pick FILTER-A first.","Insert the correctly oriented cartridge first.","Seat the cartridge first.","Close both latches first.","Confirm the airflow setting."]
var ctl
var fb := {"s":"","t":"Housing closed. Isolate duct 2 before opening."}
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func _s() -> Object: return ctl.state
func _flag(k: String) -> bool: return bool(_s().flags.get("life.filter."+k,false))
func _stage() -> int:
	if bool(_s().flags.get("legacy.air_filter",false)): return 8
	var i := 0
	while i<8 and _flag("step."+str(i+1)): i+=1
	return i
func _progress() -> Dictionary:
	return _s().legacy_progress["air_filter"]
func _rotation() -> int: return int(_progress().filter_rotation)*90
func _setting() -> float: return float(_progress().filter_airflow)

func setup(host_layer) -> void:
	ctl=host_layer
	if not _s().legacy_progress.has("air_filter"):
		_s().legacy_progress["air_filter"]={"task":"air_filter","complete":false,"filter_stage":0,"filter_rotation":2,"filter_airflow":40.0,"power":[],"nutrient_rotations":[]}
	# Saved progress from the old three-stage service control remains usable.
	# Its release stage maps to an opened/emptied housing; its seated stage
	# maps to a cartridge ready for the final latches and flow setting.
	elif not _flag("step.1") and not bool(_s().flags.get("legacy.air_filter",false)):
		var old_stage: int=int(_progress().filter_stage)
		var mapped: int=6 if old_stage>=2 else 4 if old_stage==1 else 0
		for i in range(1,mapped+1): _s().flags["life.filter.step."+str(i)]=true
	if _stage()==8: fb={"s":"ok","t":"FILTER-A service recorded. Restore the duct and verify readings."}
	elif bool(_s().systems.life.isolated): fb={"s":"","t":"Housing closed. Duct isolated."}

func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("filter:fb")
func _advance() -> void:
	var n := _stage()+1
	_s().flags["life.filter.step."+str(n)]=true
	_s().changed.emit()

func _material(name: String,r: Rect2) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)

## CSS .locked applies saturate(.2) brightness(.6) to the entire button.
func _locked_color(c: Color) -> Color:
	return UI.filt(c,0.2,0.6)

func paint() -> void:
	screen_bg()
	hud("Replace the duct 2 filter","LIFE SUPPORT · AIR FILTER SERVICE","Step away")
	_housing()
	_choices()
	_fit()
	_setting_panel()
	_paper()

func _module(name: String,r: Rect2,title: String) -> void:
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _housing() -> void:
	var r := Rect2(20,56,640,432)
	_module("filter_cartridge_housing_mod_0",r,"FILTER HOUSING · DUCT 2")
	B(Rect2(494,59,138,30),{"bg":Color("#1d180e"),"border":UI.EDGE})
	hazard(Rect2(496,61,8,26),UI.WARN,Color("#1d180e"))
	T(F("label",400,0.7),13,"DUCT ISOLATED" if bool(_s().systems.life.isolated) else "DUCT LIVE",506,64,UI.WARN,22,1,124)
	B(Rect2(32,100,614,370),{"grad":[[0.0,Color("#e7dfc7")],[1.0,Color("#c9c0a4")]],"border":UI.EDGE})
	for p in [Vector2(44,110),Vector2(625,110),Vector2(44,456),Vector2(625,456)]: draw_texture_rect(UI.tex("screw"),Rect2(p,Vector2(12,12)),false)
	B(Rect2(129,131,450,314),{"bg":Color("#10171a"),"border":UI.EDGE,"insets":[[4,4,0,Color("#2a3236")]]})
	var st := _stage()
	var asset := "filter_bay_old" if st<3 else "filter_bay_empty" if st<5 else "filter_bay_new"
	_material(asset,Rect2(133,135,442,306))
	if st<3: T(F("label",400,0.6),14,"FILTER-A · REPLACE",189,239,UI.INK,18)
	elif st>=5: T(F("label",400,0.6),14,"FILTER-A · NEW",189,239,UI.INK,18)
	_latch("latch1",Rect2(50,250,56,80),st>=1 and st<7,st==0)
	_latch("latch2",Rect2(570,250,56,80),st>=2 and st<7,st==1)
	var pull_locked := st<2
	B(Rect2(284,444,130,26),{"bg":_locked_color(Color("#3a4448")) if pull_locked else Color("#3a4448"),"border":_locked_color(UI.EDGE) if pull_locked else UI.EDGE})
	T(F("label",400,0.6),13,"PULL HANDLE",284,446,_locked_color(UI.WARN) if pull_locked else UI.WARN,20,1,130)
	hit("pull",Rect2(284,444,130,26),{"locked":st<2 or st>=3})
	if st==2: cue(Rect2(284,444,130,26))

func _latch(id: String,r: Rect2,open: bool,guided: bool) -> void:
	B(Rect2(r.position+Vector2(8,10),Vector2(40,60)),{"bg":Color("#3a4448"),"border":UI.EDGE})
	var p := r.position+Vector2(28,58)
	draw_line(p,r.position+(Vector2(52,34) if open else Vector2(28,18)),UI.WARN,8)
	draw_circle(p,5,UI.EDGE)
	hit(id,r,{"locked":_stage() >= 2 and id=="latch1" or _stage()>=7})
	if guided: cue(r)

func _choices() -> void:
	var r := Rect2(680,56,580,220)
	_module("filter_cartridge_housing_mod_1",r,"CARTRIDGE CHOICE")
	T(F("body"),16,"From shared stores",1020,67,Color("#ddd8c8"),21,2,220)
	var codes := ["OLD · FILTER-A","FILTER-A","FILTER-C"]
	var notes := ["CLOGGED · BIN IT","DUCT 1–2 · NEW","SCRUBBER INLET"]
	var fills := [Color("#6d5a3a"),UI.PAPER,Color("#cfd8c8")]
	for i in range(3):
		var box := Rect2(694+i*188,100,176,150)
		var locked := _stage()!=3
		B(box,{"bg":_locked_color(Color("#151b1e")) if locked else Color("#151b1e"),"border":_locked_color(UI.EDGE) if locked else UI.EDGE,"bw":3})
		B(Rect2(box.position+Vector2(32,15),Vector2(112,64)),{"bg":_locked_color(fills[i]) if locked else fills[i],"border":_locked_color(UI.EDGE) if locked else UI.EDGE,"bw":3})
		for j in range(7): R(Rect2(box.position+Vector2(46+j*14,15),Vector2(2,64)),_locked_color(Color("#05090b",0.5)) if locked else Color("#05090b",0.5))
		T(F("label",400,0.75),13,codes[i],box.position.x+4,box.position.y+88,_locked_color(UI.WARN) if locked else UI.WARN,18,1,168)
		var note_color := Color("#e0763a") if i==0 else UI.LIVE if i==1 else Color("#9db3b4")
		T(F("label",400,0.72),13,notes[i],box.position.x+4,box.position.y+109,_locked_color(note_color) if locked else note_color,17,1,168)
		hit("cart:"+str(i),box,{"locked":_stage()!=3})
		if i==1 and _stage()==3: cue(box)

func _fit() -> void:
	var r := Rect2(680,288,580,200)
	_module("filter_cartridge_housing_mod_2",r,"FIT")
	module_chip(r,"Seated" if _stage()>=6 else "Not seated" if _stage()==5 else "No cartridge","ok" if _stage()>=6 else "warn" if _stage()==5 else "")
	var c := Vector2(764,389)
	draw_circle(c,48,Color("#26363b"));draw_circle(c,39,UI.EDGE);draw_circle(c,34,Color("#2a3236"))
	draw_arc(c,48,0,TAU,64,Color("#557178"),1.5)
	var a := deg_to_rad(float(_rotation() if _stage()>=4 else 0))
	var v := Vector2(cos(a),sin(a))
	draw_line(c-v*25,c+v*20,UI.WARN,6)
	draw_line(c+v*20,c+v.rotated(0.5)*12,UI.WARN,6)
	draw_line(c+v*20,c+v.rotated(-0.5)*12,UI.WARN,6)
	hit("rotate",Rect2(716,341,96,96),{"locked":_stage()!=4})
	if _stage()==4 and _rotation()!=0: cue(Rect2(716,341,96,96))
	T(F("body"),16,"Turn cartridge",716,447,UI.TEXT,20,1,96)
	push("insert",840,363,110,"INSERT","","",_stage() not in [4,8],false,96,50,16,15,-1,8,false)
	T(F("body"),15,"Slide into bay",840,445,Color("#b4c3c1"),18,1,110)
	B(Rect2(1025,344,28,94),{"bg":Color("#1a2023"),"border":UI.EDGE})
	B(Rect2(1013,420 if _stage()>=6 else 352,46,20),{"bg":_locked_color(Color("#e0763a")) if _stage()<5 else Color("#e0763a"),"border":UI.EDGE})
	hit("seat",Rect2(1006,341,70,110),{"locked":_stage()!=5})
	if _stage()==5: cue(Rect2(1006,341,70,110))
	T(F("body"),16,"Seat lever",992,447,UI.TEXT,20,1,100)
	push("relatch",1120,363,110,"LATCH","","done" if _stage()>=7 else "",_stage() not in [6,8],false,96,50,16,15,-1,8,false)
	T(F("body"),15,"Close both",1120,445,Color("#b4c3c1"),18,1,110)
	T(F("body"),15,"latches",1120,463,Color("#b4c3c1"),18,1,110)
	if _stage()==4 and _rotation()==0: cue(Rect2(847,363,96,50))
	if _stage()==6: cue(Rect2(1127,363,96,50))

func _setting_panel() -> void:
	var r := Rect2(720,500,540,204)
	_module("filter_cartridge_housing_mod_3",r,"AIRFLOW SETPOINT")
	T(F("body"),16,"Band 62–72%",1120,511,Color("#ddd8c8"),21,2,122)
	_key("down",Rect2(734,545,44,44),"−")
	var track := Rect2(793,544,321,44)
	B(track,{"bg":Color("#10171a"),"border":UI.EDGE})
	R(Rect2(track.position.x+track.size.x*0.62,track.position.y+3,track.size.x*0.10,38),Color("#2f7a37",0.7))
	var pos := track.position.x+3+_setting()*((track.size.x-6)/100.0)
	B(Rect2(pos-4,538,8,50),{"bg":UI.WARN,"border":UI.EDGE})
	_key("up",Rect2(1129,545,44,44),"+")
	T(F("num"),34,"%.0f" % _setting(),1181,541,UI.LIVE if _setting()>=62 and _setting()<=72 else UI.WARN,42,2,64)
	push("prime",734,609,84,"SET","","working" if _stage()>=7 else "",_stage() not in [7,8],false,84,50,16,15,-1,8,false)
	P(F("body"),16,"Set airflow inside the green band, then confirm. This is an airflow percentage, not pressure.",836,610,404,20,Color("#b4c3c1"))
	if _stage()==7: cue(Rect2(734,609,84,50))

func _key(id: String,r: Rect2,label: String) -> void:
	artifact_key(id,r,label,false,_stage()!=7,22)

func _paper() -> void:
	_material("filter_cartridge_housing_paper_0",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<8 else DONE
	artifact_procedure(st,8,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	var st := _stage()
	if st==8: say("ok","Filter already serviced; restore and verify at the duct.");return
	if id in ["up","down"]:
		if st!=7: say("warn",NEED[st]);return
		var p := _progress()
		p.filter_airflow=clampf(float(p.filter_airflow)+(5 if id=="up" else -5),0,100)
		_s().legacy_progress["air_filter"]=p;_s().changed.emit();return
	if id=="rotate":
		if st!=4: say("warn",NEED[st]);return
		var p := _progress();p.filter_rotation=(int(p.filter_rotation)+1)%4
		_s().legacy_progress["air_filter"]=p;_s().changed.emit()
		say("","Cartridge turned. Point its arrow toward the fan.");return
	if id.begins_with("cart:"):
		if st!=3: say("warn",NEED[st]);return
		if id!="cart:1": say("warn","FILTER-A is the labelled replacement for duct 2.");return
		if _s().inventory.inventory_count(&"filter_cartridge")<1: say("warn","FILTER-A is not carried. Retrieve it from shared quarters drawers or the maintenance trolley.");return
		_advance();say("ok","FILTER-A selected from carried supplies.");return
	var expected := ["latch1","latch2","pull","pick","insert","seat","relatch","prime"]
	if id!=expected[st]: say("warn",NEED[st]);return
	if st==0:
		var reason: String=_s().prerequisite("life")
		if not reason.is_empty(): say("lock",reason);return
		if not bool(_s().systems.life.isolated): say("lock","Isolate duct 2 from the air duct assembly before opening this housing.");return
	if st==4 and _rotation()!=0: say("warn","Arrow points the wrong way. Turn it toward the fan side.");return
	if st==7:
		if _setting()<62 or _setting()>72: say("warn","Airflow setting must be inside the 62–72% band.");return
		if not _s().legacy_complete("air_filter","life.filter"):
			say("lock","FILTER-A service could not be recorded. Check the active work order, isolation and carried cartridge.");return
		ctl.legacy_receipt_recorded.emit("air_filter")
		var p := _progress();p.filter_stage=2;p.complete=true
		_s().legacy_progress["air_filter"]=p
		say("ok","FILTER-A installed. Restore the duct and verify sustained readings.")
		return
	_advance()
	if st==2:
		var p := _progress();p.filter_stage=1;_s().legacy_progress["air_filter"]=p
	elif st==5:
		var p := _progress();p.filter_stage=2;_s().legacy_progress["air_filter"]=p
	say("ok",["Left latch open.","Right latch open.","Old cartridge out.","FILTER-A selected.","Cartridge inserted toward fan.","Cartridge seated.","Housing latched."][st])
