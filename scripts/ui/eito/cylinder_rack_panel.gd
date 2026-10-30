extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 cylinder rack. The artifact's illustrated bay and release
## sequence remain separate controls; only the final lift issues real stock.

const IDS := ["coolant_charge","oxygen_reserve","inert_purge"]
const CODES := ["COOL-02","O2-01","N2-03"]
const DESCRIPTIONS := ["Sealed service coolant","Oxygen reserve · oxidiser","Inert purge gas"]
const STEPS := [
	{"id":"order","do":"Read the work order.","why":"It names the exact cylinder engines need.","ok":"Order: COOL-02 for coolant pump 1."},
	{"id":"cool","do":"Select the cylinder labelled COOL-02.","why":"Match the printed label. The blue band helps, but the label decides.","ok":"COOL-02 selected. Label shown on the reader."},
	{"id":"confirm","do":"Confirm the printed label.","why":"The item code must match the order. No live pressure reading is available.","ok":"COOL-02 label matches the work order."},
	{"id":"chain","do":"Unhook this bay’s chain.","why":"Only this bay. The others stay restrained.","ok":"Bay 1 chain off. The others stay chained."},
	{"id":"lift","do":"Lift the cylinder out.","why":"Keep the valve cap on while you carry it.","ok":"COOL-02 retrieved into carried inventory."},
]
const NEED := ["Read the work order first.","Select COOL-02 first.","Confirm the label first.","Unhook the chain first.","Lift it out."]
const DONE := {"do":"Coolant charge retrieved.","why":"COOL-02 is in your carried inventory for engine service."}
var ctl
var fb := {"s":"","t":"All three bays chained."}
var selected := -1
var _materials := {}

func F(kind: String,w := 400,sp := 0.0) -> Font:
	return UI.artifact_font(kind,w,sp)

func setup(host_layer) -> void:
	ctl=host_layer
	if _stage()>1: selected=0
	if _stage()==5: fb={"s":"ok","t":"COOL-02 issued to carried inventory."}

func _stock(index: int) -> int:
	return int(ctl.state.stocks["cargo.cylinders"].get(IDS[index],0))

func _stage() -> int:
	if bool(ctl.state.flags.get("cargo.cylinder.issued",false)): return 5
	var i := 0
	while i<4 and bool(ctl.state.flags.get("cargo.cylinder.stage."+str(i+1),false)): i+=1
	return i

func _advance(n: int) -> void:
	ctl.state.flags["cargo.cylinder.stage."+str(n)]=true
	ctl.state.changed.emit()

func _reset_issue() -> void:
	ctl.state.flags.erase("cargo.cylinder.issued")
	for n in range(1,5): ctl.state.flags.erase("cargo.cylinder.stage."+str(n))
	selected=-1
	ctl.state.changed.emit()

func say(s: String,message: String) -> void:
	fb={"s":s,"t":message};pop("cylinder:fb")

func paint() -> void:
	screen_bg()
	hud("Retrieve the coolant charge" if ctl.state.phase=="outbound" else "Check the labelled service cylinders","CARGO BAY · CYLINDER RACK","Step away")
	_rack()
	_order()
	_reader()
	_release()
	_paint_code()
	_paper()

func _material(name: String,r: Rect2) -> void:
	if not _materials.has(name): _materials[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	draw_texture_rect(_materials[name],r,false)

func _module(name: String,r: Rect2,title: String) -> void:
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _rack() -> void:
	var r := Rect2(20,56,680,432)
	_module("cylinder_rack_module",r,"SECURED RACK · 3 BAYS")
	module_chip(r,"Bay 1 unchained" if _stage()==4 else "All chained","warn" if _stage()==4 else "ok")
	for i in range(3):
		var x := 34.0+i*221.3
		var bay := Rect2(x,100,209.3,370)
		var edge := UI.CUE if selected==i else UI.EDGE
		B(bay,{"bg":Color("#0f1619"),"border":edge,"insets":[[3,3,0,Color.BLACK]]})
		if not (i==0 and _stage()==5 and _stock(0)==0):
			var name: String = "cylinder_cool_unchained_art" if i==0 and _stage()>=4 else "cylinder_"+str(["cool","o2","n2"][i])+"_art"
			_material(name,Rect2(x+29.65,110,150,300))
			T(F("label",400,0.48),12,"5.1" if i==1 else "2.2",x+29.65+48,258,UI.INK,18,1,54)
			T(F("label",400,0.48),12,CODES[i],x+29.65+45,321,UI.INK,18,1,60)
		T(F("label",400,0.78),13,"BAY %d · %s" % [i+1,CODES[i]],x+4,413,UI.CUE if selected==i else UI.LABEL,19,1,201)
		hit("cyl:"+str(i),bay,{"locked":i==0 and _stock(0)==0})
		if i==0 and _stage()==1: cue(bay)

func _order() -> void:
	var r := Rect2(720,56,260,220)
	_material("cylinder_work_order_paper",r)
	T(F("label",400,0.78),13,"WORK ORDER · ENGINES",736,73,Color("#6a5a2a"),18)
	var order_text := "Coolant pump 1 needs a sealed service charge." if ctl.state.phase=="outbound" else "Current engine work order calls for valve inspection."
	P(F("body",600),20,order_text,736,94,228,24,UI.INK,true)
	var extra := "Bring: COOL-02 (blue band). Oxygen and inert gas are not coolant." if ctl.state.phase=="outbound" else "COOL-02 remains a service supply. Check the active work order before issue."
	P(F("body"),15,extra,736,148,228,19.5,UI.INK_2)
	T(F("label",400,0.78),13,"READ ✓" if _stage()>0 else "TAP TO READ",736,219,Color("#6a5a2a"),18)
	hit("order",r)
	if _stage()==0: cue(Rect2(736,70,228,164))

func _reader() -> void:
	_material("cylinder_reader_bezel",Rect2(992,56,268,220))
	var glass := Rect2(1004,68,244,196)
	artifact_glass(glass)
	T(F("num"),18,"LABEL READER",1018,80,UI.PHOS,30)
	T(F("num"),18,CODES[selected] if selected>=0 else "—",1018,80,UI.PHOS_DIM,30,2,216)
	if selected<0:
		T(F("num"),20,"Select a cylinder",1018,111,UI.PHOS,23)
		T(F("num"),20,"to read its label",1018,136,UI.PHOS_DIM,23)
	else:
		T(F("num"),20,CODES[selected]+(" SEALED COOLANT" if selected==0 else " OXYGEN RESERVE" if selected==1 else " INERT PURGE GAS"),1018,111,UI.PHOS,23)
		T(F("num"),20,"Service charge · engines" if selected==0 else "Oxidiser · life support" if selected==1 else "Purge only · not coolant",1018,136,UI.PHOS_DIM,23)
	T(F("num"),20,"PRESSURE ---",1018,163,UI.PHOS,23)
	for i in range(10): R(Rect2(1018+i*21.6,187,20,10),Color("#0b1714"))
	artifact_glass_overlay(glass)

func _release() -> void:
	var r := Rect2(720,288,540,200)
	_module("cylinder_release_module",r,"RELEASE")
	module_chip(r,"Retrieved" if _stage()==5 else "Bay 1 unchained" if _stage()==4 else "Locked in","ok" if _stage()==5 else "warn" if _stage()==4 else "off")
	_push("confirm",788,334,116,"LABEL OK","Matches the order",_stage()>=2,_stage()==2)
	_push("chain",948,334,84,"CHAIN","Unhook this bay only",_stage()>=3,_stage()==3)
	_push("lift",1080,334,108,"LIFT OUT","Two hands, valve cap on",_stage()>=4,_stage()==4)

func _push(id: String,x: float,y: float,w: float,label: String,sub: String,enabled: bool,guided: bool) -> void:
	dim=not enabled
	var done := id=="chain" and _stage()>=4 or id=="lift" and _stage()>=5
	var top := Color("#7fd685") if done else Color("#cfc7a8")
	var bottom := Color("#4c9f52") if done else Color("#a9a083")
	B(Rect2(x,y+(3 if done else 0),w,50),{"grad":[[0.0,top],[1.0,bottom]],"border":UI.EDGE,"insets":[[2,2,0,Color("#c9f5c9") if done else Color("#f0ead2")],[-2,-2,0,Color("#2c6a31") if done else Color("#7e7660")]],"outer":[[0,3 if done else 6,0,UI.EDGE]]})
	T(F("label",400,0.64),16,label,x,y+(3 if done else 0),UI.INK,50,1,w)
	dim=false
	P(F("body"),15,sub,x-2,y+58,w+4,17.25,Color("#b4c3c1"),false,1)
	hit(id,Rect2(x,y,w,82),{"locked":not enabled})
	if guided: cue(Rect2(x,y,w,50))

func _paint_code() -> void:
	var r := Rect2(720,500,540,204)
	_module("cylinder_paint_module",r,"PAINT CODE")
	T(F("body"),16,"Read the label, not just the colour",1000,504,Color("#ddd8c8"),30,2,234)
	for i in range(3):
		var x := 734.0+i*174.0
		B(Rect2(x,544,163,18),{"bg":[Color("#3fb8e8"),Color("#f4f1e6"),Color("#1b1f21")][i],"border":Color("#557178") if i==2 else UI.EDGE})
		T(F("label",400,0.78),13,CODES[i],x,568,UI.TEXT,18)
		P(F("body"),15,DESCRIPTIONS[i],x,590,163,18,Color("#b4c3c1"))

func _paper() -> void:
	_material("cargo_procedure_paper",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<5 else DONE
	artifact_procedure(st,5,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit(); return
	var st := _stage()
	if id.begins_with("cyl:"):
		selected=int(id.get_slice(":",1))
		if selected==1: say("warn","That is O2-01, oxygen. It is not coolant and must not go near engines."); return
		if selected==2: say("warn","That is N2-03, inert purge gas. It cannot charge a coolant loop."); return
		id="cool"
	if st==5 and id=="order" and _stock(0)>0:
		_reset_issue();_advance(1);say("ok","Next COOL-02 issue: verify the printed label.");return
	if st>=5: say("ok","Already retrieved. %d COOL-02 remain in the rack." % _stock(0)); return
	if id!=STEPS[st].id: say("warn",NEED[st]); return
	if id=="lift":
		if _stock(0)<=0: say("warn","No COOL-02 remains in this rack.");return
		var before := _stock(0)
		ctl.act("cylinder","coolant_charge")
		if _stock(0)==before: return
		ctl.state.flags["cargo.cylinder.issued"]=true
		ctl.state.changed.emit()
		say("ok",STEPS[st].ok)
		return
	_advance(st+1)
	if id=="cool": selected=0
	say("ok",STEPS[st].ok)
