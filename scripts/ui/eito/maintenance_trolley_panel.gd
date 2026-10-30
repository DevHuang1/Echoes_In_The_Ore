extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 trolley board. The HTML prototype sends a cart to engine-room
## lockers; the playable game keeps supplies in this real trolley and issues one
## kit to carried inventory through its existing transfer_kit action.

const STEPS := [
	{"id":"brake","do":"Release the castor brake.","why":"A braked trolley skids instead of rolling.","ok":"Brake control released for handling."},
	{"id":"drawer","do":"Open drawer 2.","why":"This drawer holds sealed COOL-02 coolant kits.","ok":"Drawer 2 open. Check the labelled kit."},
	{"id":"kit","do":"Select one COOL-02 kit.","why":"The sealed coolant item is distinct from oxygen or inert gas.","ok":"COOL-02 selected from trolley stock."},
	{"id":"dest1","do":"Choose carried inventory.","why":"The kit stays with you until engine service uses it.","ok":"Destination: carried inventory."},
	{"id":"sign","do":"Confirm the custody slip.","why":"The item and destination must match before issue.","ok":"Custody slip confirmed for one COOL-02 kit."},
	{"id":"send","do":"Issue the kit.","why":"One sealed kit moves from trolley stock into your inventory.","ok":"One COOL-02 kit issued to carried inventory."},
]
const NEED := ["Check the parked trolley first.","Open drawer 2 first.","Select COOL-02 first.","Choose carried inventory first.","Confirm the custody slip first.","Issue the kit."]
const DONE := {"do":"Coolant kit issued.","why":"Carry COOL-02 to the engine service station when that work order is active."}
var ctl
var fb := {"s":"","t":"Trolley parked. Sealed supplies remain in its drawers."}
var _materials := {}

func F(kind: String,w := 400,sp := 0.0) -> Font:
	return UI.artifact_font(kind,w,sp)

func setup(host_layer) -> void:
	ctl=host_layer
	if _stage()==6: fb={"s":"ok","t":"One COOL-02 kit was issued to carried inventory."}

func _stock() -> int: return int(ctl.state.stocks["cargo.trolley"].get("coolant_charge",0))
func _stage() -> int:
	if bool(ctl.state.flags.get("cargo.trolley.issued",false)): return 6
	var i := 0
	while i<5 and bool(ctl.state.flags.get("cargo.trolley.stage."+str(i+1),false)): i+=1
	return i

func _advance(n: int) -> void:
	ctl.state.flags["cargo.trolley.stage."+str(n)]=true
	ctl.state.changed.emit()

func _reset_issue() -> void:
	ctl.state.flags.erase("cargo.trolley.issued")
	for n in range(1,6): ctl.state.flags.erase("cargo.trolley.stage."+str(n))
	ctl.state.changed.emit()

func say(s: String,message: String) -> void:
	fb={"s":s,"t":message};pop("trolley:fb")

func paint() -> void:
	screen_bg()
	hud("Issue a coolant kit for engine service","CARGO BAY · MAINTENANCE TROLLEY","Step away")
	_front()
	_drawer()
	_destination()
	_custody()
	_route()
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

func _key(id: String,r: Rect2,label: String,enabled: bool,guided: bool) -> void:
	artifact_key(id,r,label,false,not enabled)
	if guided: cue(r)

func _front() -> void:
	var r := Rect2(20,56,420,432)
	_module("trolley_front_module",r,"TROLLEY · FRONT")
	module_chip(r,"Brake on" if _stage()==0 else "Brake off","warn" if _stage()==0 else "ok")
	var art := "trolley_body_braked" if _stage()==0 else "trolley_body_unbraked" if _stage()==1 else "trolley_body_drawer_open"
	_material(art,Rect2(34,100,396,300))
	_key("brake",Rect2(34,408,184,38),"CASTOR BRAKE",true,_stage()==0)
	_key("drawer",Rect2(238,408,184,38),"OPEN DRAWER 2",_stage()>=1,_stage()==1)
	for x in [28,420]: draw_texture_rect(UI.tex("screw"),Rect2(x,468,12,12),false)

func _dash(r: Rect2,c: Color,width := 3.0) -> void:
	for x in range(int(r.position.x),int(r.end.x),8):
		R(Rect2(x,r.position.y,minf(4,r.end.x-x),width),c)
		R(Rect2(x,r.end.y-width,minf(4,r.end.x-x),width),c)
	for y in range(int(r.position.y),int(r.end.y),8):
		R(Rect2(r.position.x,y,width,minf(4,r.end.y-y)),c)
		R(Rect2(r.end.x-width,y,width,minf(4,r.end.y-y)),c)

func _drawer() -> void:
	_material("trolley_drawer_bezel",Rect2(452,56,248,432))
	B(Rect2(466,70,220,404),{"bg":Color("#14191b"),"border":Color.BLACK,"insets":[[4,4,0,Color(0,0,0,0.6)]]})
	T(F("label",400,0.78),13,"DRAWER 2 · FOAM",480,84,Color("#8fa9a7"),18)
	var st := _stage()
	var kit_r := Rect2(480,112,192,130)
	R(kit_r,Color("#0a0d0e"))
	_dash(kit_r,Color("#3fb8e8") if st>=3 and _stock()>0 else Color("#557178"))
	var alpha := 1.0 if st>=3 and _stock()>0 else 0.18
	var p := Vector2(528,128)
	B(Rect2(p+Vector2(32,0),Vector2(32,12)),{"bg":Color("#3a4448",alpha),"border":Color(UI.EDGE,alpha)})
	B(Rect2(p+Vector2(18,12),Vector2(60,84)),{"bg":Color("#d8cfb6",alpha),"border":Color(UI.EDGE,alpha)})
	R(Rect2(p+Vector2(18,32),Vector2(60,14)),Color("#3fb8e8",alpha))
	T(F("label",400,0.78),13,"SELECTED" if st>=3 else "COOL-02",480,214,UI.PHOS if st>=3 else Color("#8fa9a7"),18,1,192)
	hit("kit",kit_r,{"locked":st<2 or _stock()<=0})
	if st==2: cue(kit_r)
	var slots := [Rect2(480,254,90,64),Rect2(582,254,90,64),Rect2(480,328,90,64),Rect2(582,328,90,64)]
	for slot in slots: B(slot,{"bg":Color("#0a0d0e"),"border":Color("#26363b")})
	# The four separate foam cut-outs match the artifact's tool silhouettes.
	draw_colored_polygon(PackedVector2Array([Vector2(503,293),Vector2(544,273),Vector2(550,279),Vector2(510,301)]),Color("#9db3b4",0.35 if st<2 else 1.0))
	B(Rect2(612,271,24,38),{"bg":Color("#d8cfb6",0.35 if st<2 else 1.0),"border":UI.EDGE})
	R(Rect2(618,265,12,8),Color("#e9b52c",0.35 if st<2 else 1.0))
	draw_arc(Vector2(525,359),18,0,TAU,32,Color("#e8892a",0.35 if st<2 else 1.0),6)
	P(F("body"),14,"Empty cut-outs show at a glance what is missing.",480,404,192,17,Color("#8fa9a7"))

func _destination() -> void:
	var r := Rect2(720,56,540,220)
	_module("trolley_destination_module",r,"DESTINATION")
	T(F("body"),16,"Carried inventory",1038,60,Color("#ddd8c8"),30,2,198)
	var card1 := Rect2(734,100,250,148)
	var card2 := Rect2(996,100,250,148)
	dim=_stage()<3
	B(card1,{"grad":[[0.0,Color("#26363b")],[1.0,UI.HULL]],"border":UI.CUE if _stage()>=4 else UI.EDGE,"insets":[[2,2,0,Color("#46616a")]]})
	T(F("label",400,0.78),13,"CARRIED KIT · ENGINE",746,111,UI.LABEL,18)
	P(F("body"),16,"One sealed COOL-02 moves from this trolley into your inventory.",746,136,226,19.2,UI.TEXT)
	lamp(Vector2(746,215),"live" if _stage()>=4 and _stage()<6 else "ok" if _stage()==6 else "off")
	T(F("body"),16,"Issued" if _stage()==6 else "Selected" if _stage()>=4 else "Waiting",772,213,UI.TEXT,21)
	dim=false
	B(card2,{"grad":[[0.0,Color("#26363b")],[1.0,UI.HULL]],"border":UI.EDGE,"insets":[[2,2,0,Color("#46616a")]]})
	T(F("label",400,0.78),13,"TROLLEY DRAWER · STOCK",1008,111,UI.LABEL,18)
	P(F("body"),16,"Remaining sealed kits stay here. Hiding lockers hold no supplies.",1008,136,226,19.2,Color("#b4c3c1"))
	lamp(Vector2(1008,215),"off")
	T(F("body"),16,"%d kits in drawer" % _stock(),1034,213,UI.TEXT,21)
	hit("dest1",card1,{"locked":_stage()<3})
	hit("dest2",card2)
	if _stage()==3: cue(card1)

func _custody() -> void:
	var r := Rect2(720,288,540,200)
	_module("trolley_custody_module",r,"CUSTODY")
	var slip := Rect2(734,332,330,132)
	dim=_stage()<4
	B(slip,{"bg":UI.PAPER_HI,"border":Color("#6f6750")})
	T(F("label",400,0.78),13,"CUSTODY SLIP · SHIP STORES",748,345,Color("#6a5a2a"),18)
	T(F("body"),15,"Item: COOL-02 sealed coolant",748,365,UI.INK,19)
	T(F("body"),15,"From: trolley drawer 2",748,385,UI.INK,19)
	T(F("body"),15,"To: carried inventory",748,402,UI.INK,19)
	R(Rect2(748,425,302,2),Color("#a39a7b"))
	T(F("body"),18,"Confirmed" if _stage()>=5 else "Signature",748,429,Color("#1f3a80") if _stage()>=5 else Color("#a39a7b"),23)
	dim=false
	hit("sign",slip,{"locked":_stage()<4})
	if _stage()==4: cue(slip)
	var button := Rect2(1080,340,120,50)
	dim=_stage()<5
	B(button,{"grad":[[0.0,Color("#7fd685") if _stage()==6 else Color("#cfc7a8")],[1.0,Color("#4c9f52") if _stage()==6 else Color("#a9a083")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#f0ead2")],[-2,-2,0,Color("#7e7660")]],"outer":[[0,6,0,UI.EDGE]]})
	T(F("label",400,0.64),16,"ISSUE",1080,340,UI.INK,50,1,120)
	dim=false
	P(F("body"),15,"Carry it to the engine room",1080,400,120,17.25,Color("#b4c3c1"),false,1)
	hit("send",button,{"locked":_stage()<5})
	if _stage()==5: cue(button)

func _route() -> void:
	var r := Rect2(720,500,540,204)
	_module("trolley_route_module",r,"ROUTE")
	T(F("body"),16,"Carry: cargo bay → engines",1000,504,Color("#ddd8c8"),30,2,234)
	var glass := Rect2(734,546,512,130)
	artifact_glass(glass)
	B(Rect2(752,586,120,70),{"border":UI.PHOS_DIM})
	T(F("label"),11,"CARGO BAY",752,610,UI.PHOS_DIM,18,1,120)
	B(Rect2(1112,562,120,98),{"border":UI.PHOS_DIM})
	T(F("label"),11,"ENGINES",1112,606,UI.PHOS_DIM,18,1,120)
	B(Rect2(1182,568,40,18),{"bg":UI.PHOS if _stage()==6 else UI.GLASS,"border":UI.PHOS})
	T(F("num"),14,"L1",1182,568,UI.GLASS,18,1,40)
	var col := UI.PHOS if _stage()>=4 else UI.PHOS_FAINT
	for pair in [[Vector2(872,621),Vector2(1112,621)],[Vector2(1112,621),Vector2(1112,586)],[Vector2(1112,586),Vector2(1182,577)]]:
		draw_line(pair[0],pair[1],col,3)
	B(Rect2(848,610,24,22),{"bg":UI.BONE,"border":UI.EDGE})
	artifact_glass_overlay(glass)

func _paper() -> void:
	_material("cargo_procedure_paper",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<6 else DONE
	artifact_procedure(st,6,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	var st := _stage()
	if id=="dest2": say("warn","Supplies remain in this trolley. Hiding lockers do not store kits.");return
	if st==6 and id=="drawer" and _stock()>0:
		_reset_issue();_advance(1);say("ok","Next kit: drawer 2 ready for a new issue.");return
	if st>=6: say("ok","Already issued. %d COOL-02 kits remain in the trolley." % _stock());return
	if id!=STEPS[st].id: say("warn",NEED[st]);return
	if id=="kit" and _stock()<=0: say("warn","No COOL-02 kit remains in trolley drawer 2.");return
	if id=="send":
		var before := _stock()
		ctl.act("transfer_kit")
		if _stock()==before: return
		ctl.state.flags["cargo.trolley.issued"]=true
		ctl.state.changed.emit()
		say("ok",STEPS[st].ok)
		return
	_advance(st+1)
	say("ok",STEPS[st].ok)
