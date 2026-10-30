extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 pallet-mover board. The controls retain the artifact's six-step
## handling sequence; the final set-down calls the existing secured transfer.

const STEPS := [
	{"id":"key","do":"Turn the key on.","why":"Start the secured-transfer handling sequence.","ok":"Key control acknowledged. Battery telemetry is unavailable."},
	{"id":"lower","do":"Lower the forks to the floor.","why":"They have to slide under the crate pallet.","ok":"Forks down. Slide them under the pallet."},
	{"id":"lift","do":"Lift the crate clear of the floor.","why":"Keep the sealed load low and stable during transfer.","ok":"Fork handling confirmed. The load mass remains unverified until weighing."},
	{"id":"dest_scale","do":"Set the destination to the scale.","why":"The lane lights up so you can check it is clear.","ok":"Lane to the scale lit and clear."},
	{"id":"drive","do":"Confirm the secured lane transfer.","why":"Record the destination at the inspection scale.","ok":"Secured lane transfer prepared for the scale."},
	{"id":"lower","do":"Lower the crate onto the scale.","why":"Forks fully down so the scale reads only the crate.","ok":"Crate set down on the scale. Weigh it at the scale."},
]
const NEED := ["Turn the key on first.","Lower the forks first.","Lift the crate first.","Choose the scale as destination first.","Drive the lane first.","Lower the crate onto the scale."]
const DONE := {"do":"Crate delivered to the scale.","why":"Go to the inspection scale to weigh it. The mover can take it back to staging later."}
var ctl
var fb := {"s":"","t":"Mover parked in staging. Key is off."}
var _materials := {}

func F(kind: String, w := 400, sp := 0.0) -> Font:
	return UI.artifact_font(kind,w,sp)

func setup(host_layer) -> void:
	ctl=host_layer
	if _location()=="scale": fb={"s":"ok","t":"Crate set down on the scale. Weigh it at the scale."}

func _cargo() -> Dictionary: return ctl.state.systems.cargo
func _location() -> String: return str(_cargo().location)
func _stage() -> int:
	if _location() in ["scale","secured","quarantine"]: return 6
	var i := 0
	while i<5 and bool(ctl.state.flags.get("cargo.mover.stage."+str(i+1),false)): i+=1
	return i

func _set_stage(n: int) -> void:
	ctl.state.flags["cargo.mover.stage."+str(n)]=true
	ctl.state.changed.emit()

func say(s: String, message: String) -> void:
	fb={"s":s,"t":message};pop("mover:fb")

func paint() -> void:
	screen_bg()
	hud("Inspect and secure the cargo","CARGO BAY · PALLET MOVER","Step away")
	_lane()
	_tiller()
	_destinations()
	_load()
	_paper()

func _material(name: String,r: Rect2) -> void:
	if not _materials.has(name): _materials[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	draw_texture_rect(_materials[name],r,false)

func _module(r: Rect2,title: String) -> void:
	var name := "mover_tiller_module" if title=="TILLER HEAD" else "mover_load_module"
	_material(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _outline(r: Rect2,c: Color,w := 2.0) -> void:
	R(Rect2(r.position,Vector2(r.size.x,w)),c)
	R(Rect2(r.position,Vector2(w,r.size.y)),c)
	R(Rect2(r.position+Vector2(0,r.size.y-w),Vector2(r.size.x,w)),c)
	R(Rect2(r.position+Vector2(r.size.x-w,0),Vector2(w,r.size.y)),c)

func _dashed(r: Rect2,c: Color,on := 10.0,off := 6.0,w := 3.0) -> void:
	var stride := int(on+off)
	for x in range(int(r.position.x),int(r.end.x),stride):
		R(Rect2(x,r.position.y,minf(on,r.end.x-x),w),c)
		R(Rect2(x,r.end.y-w,minf(on,r.end.x-x),w),c)
	for y in range(int(r.position.y),int(r.end.y),stride):
		R(Rect2(r.position.x,y,w,minf(on,r.end.y-y)),c)
		R(Rect2(r.end.x-w,y,w,minf(on,r.end.y-y)),c)

func _lane() -> void:
	_material("mover_lane_bezel",Rect2(20,56,680,432))
	var glass := Rect2(32,68,656,408)
	artifact_glass(glass)
	T(F("num",400,0.88),22,"CARGO BAY · FLOOR LANE",46,74,UI.PHOS,30)
	T(F("num",400,0.88),22,"ROUTE DIAGRAM",46,74,UI.PHOS_DIM,30,2,628)
	var o := Vector2(36,106)
	_outline(Rect2(o+Vector2(8,4),Vector2(636,324)),UI.PHOS_FAINT)
	_dashed(Rect2(o+Vector2(36,170),Vector2(190,130)),UI.YELLOW,10,6,3)
	T(F("label"),13,"STAGING",o.x+36,o.y+303,UI.YELLOW,18,1,190)
	_outline(Rect2(o+Vector2(430,40),Vector2(180,150)),UI.PHOS,3)
	_dashed(Rect2(o+Vector2(438,48),Vector2(164,134)),UI.PHOS_FAINT,6,6,2)
	T(F("label"),13,"SCALE",o.x+430,o.y+164,UI.PHOS,18,1,180)
	B(Rect2(o+Vector2(470,200),Vector2(150,100)),{"bg":UI.GLASS_2,"border":UI.PHOS_DIM})
	T(F("label"),12,"CYLINDER RACK",o.x+470,o.y+239,UI.PHOS_DIM,18,1,150)
	B(Rect2(o+Vector2(270,40),Vector2(110,70)),{"bg":UI.GLASS_2,"border":UI.PHOS_DIM})
	T(F("label"),12,"TROLLEY",o.x+270,o.y+63,UI.PHOS_DIM,18,1,110)
	var st := _stage()
	var route_color := UI.PHOS if st>=4 else UI.PHOS_FAINT
	for pair in [[Vector2(131,170),Vector2(131,150)],[Vector2(131,150),Vector2(520,150)],[Vector2(520,150),Vector2(520,120)]]:
		draw_line(o+pair[0],o+pair[1],route_color,4)
	var mover := o+Vector2(520,80) if st>=5 else o+Vector2(131,210)
	B(Rect2(mover+Vector2(-26,-16),Vector2(52,30)),{"bg":UI.YELLOW,"border":UI.EDGE})
	for x in [-20,10]: B(Rect2(mover+Vector2(x,14),Vector2(10,48)),{"bg":UI.BONE,"border":UI.EDGE})
	if st>=2:
		B(Rect2(mover+Vector2(-34,20),Vector2(68,44)),{"bg":UI.PHOS_FAINT,"border":UI.PHOS})
		T(F("num"),18,"A12",mover.x-34,mover.y+29,UI.PHOS,24,1,68)
	B(Rect2(mover+Vector2(-4,-30),Vector2(8,16)),{"bg":Color("#3a4448"),"border":UI.EDGE})
	R(Rect2(46,433,624,2),UI.PHOS_FAINT)
	T(F("num"),20,"FORKS  -- mm",48,442,UI.PHOS,24)
	T(F("num"),20,"LOAD  --.- kg",160,442,UI.PHOS,24)
	T(F("num"),20,"SPEED  --",270,442,UI.PHOS_DIM,24)
	artifact_glass_overlay(glass)

func _fork_mm(st: int) -> int:
	return [90,90,0,60,60,60,0][mini(st,6)]

func _tiller() -> void:
	var r := Rect2(720,56,540,330)
	_module(r,"TILLER HEAD")
	module_chip(r,"Powered" if _stage()>=1 else "Key off","ok" if _stage()>=1 else "off")
	_material("mover_tiller_art",Rect2(734,100,516,270))
	var st := _stage()
	# The controls are separate live regions over the artifact's tiller drawing.
	T(F("label",400,0.78),13,"THROTTLE",764,155,UI.TEXT if st==4 else Color("#8e9b99"),18,1,100)
	T(F("num"),30,"◀ ▶",764,178,UI.TEXT if st==4 else Color("#8e9b99"),36,1,100)
	T(F("body"),14,"confirm route",764,212,Color("#b4c3c1"),18,1,100)
	hit("drive",Rect2(764,140,100,110),{"locked":st!=4})
	if st==4: cue(Rect2(764,140,100,110))
	draw_circle(Vector2(992,156),22,UI.EDGE)
	draw_circle(Vector2(992,155),19,Color("#26363b"))
	T(F("label"),11,"HORN",970,145,UI.TEXT,20,1,44)
	hit("horn",Rect2(970,134,44,44),{"locked":st==0})
	draw_circle(Vector2(992,222),31,UI.EDGE)
	draw_circle(Vector2(992,218),27,Color("#c2341f"))
	draw_circle(Vector2(990,215),22,Color("#e46a52"))
	T(F("label"),10,"BELLY",962,208,Color("#fff2e8"),20,1,60)
	hit("belly",Rect2(962,192,60,60))
	_key("lift",Rect2(870,296,92,38),"▲ LIFT",st>=2,st==2)
	_key("lower",Rect2(1022,296,92,38),"▼ LOWER",st>=1,st==1 or st==5)
	_key_switch(st)
	T(F("label"),13,"BATTERY",754,336,UI.LABEL,17)
	for i in range(10): R(Rect2(754+i*11,355,10,10),Color("#0b1714"))
	B(Rect2(1165,334,55,32),{"bg":UI.GLASS,"border":Color.BLACK})
	T(F("num"),26,"--%",1173,336,UI.PHOS,30)

func _key_switch(st: int) -> void:
	var c := Vector2(1166,184)
	draw_circle(c,27,UI.EDGE);draw_circle(c,23,Color("#26363b"));draw_circle(c,18,Color("#9db3b4"))
	var angle := deg_to_rad(-45 if st>=1 else 45)
	draw_line(c+Vector2(-17,0).rotated(angle),c+Vector2(17,0).rotated(angle),UI.EDGE,6)
	T(F("label",400,0.78),13,"KEY "+("ON" if st>=1 else "OFF"),1118,230,UI.TEXT,18,1,100)
	hit("key",Rect2(1118,140,100,110),{"locked":st>=1})
	if st==0: cue(Rect2(1118,140,100,110))

func _key(id: String,r: Rect2,label: String,enabled: bool,guided: bool,selected := false) -> void:
	artifact_key(id,r,label,selected,not enabled)
	if guided: cue(r)

func _destinations() -> void:
	_material("mover_destination_module",Rect2(720,398,540,90))
	T(F("label",400,0.96),16,"DESTINATION",740,434,UI.LABEL,32)
	_key("dest_staging",Rect2(889,424,166,38),"STAGING",_stage()==6,false)
	_key("dest_scale",Rect2(1070,424,166,38),"SCALE",_stage()>=3,_stage()==3,_stage()>=4)

func _load() -> void:
	var r := Rect2(720,500,540,204)
	_module(r,"FORKS AND LOAD")
	var st := _stage()
	module_chip(r,"Carrying A12" if st>=3 and st<=5 else "Empty","ok" if st>=3 and st<=5 else "off")
	B(Rect2(736,546,40,136),{"bg":UI.EDGE,"border":UI.EDGE,"insets":[[2,2,0,Color.BLACK]]})
	var bar_height := roundf(float(_fork_mm(st))/90.0*120.0)
	if bar_height>0: R(Rect2(742,676-bar_height,28,bar_height),UI.YELLOW)
	var g := Rect2(792,546,452,70)
	artifact_glass(g)
	T(F("num"),22,"LOAD CELL",806,551,UI.PHOS_DIM,28)
	T(F("num"),22,"--.- kg",806,551,UI.PHOS,28,2,424)
	T(F("num"),22,"FORK HEIGHT",806,581,UI.PHOS_DIM,28)
	T(F("num"),22,"-- mm",806,581,UI.PHOS,28,2,424)
	artifact_glass_overlay(g)
	P(F("body"),15,"Lift only 60 mm: enough to clear the floor, low enough to stay stable. Lower fully before you drive away.",792,621,452,18,Color("#b4c3c1"))

func _paper() -> void:
	_material("cargo_procedure_paper",Rect2(20,500,680,204))
	var st := _stage()
	var cur: Dictionary=STEPS[st] if st<6 else DONE
	artifact_procedure(st,6,str(cur.do),str(cur.why),fb)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit(); return
	var st := _stage()
	if id=="horn": say("ok" if st>0 else "warn","Beep. Use it at blind corners."); return
	if id=="belly": say("","Belly button: if the tiller pins you, the mover backs away."); return
	if id=="dest_staging":
		if st==6:
			ctl.act("move_load","staging")
			if _location()=="staging":
				for n in range(1,6): ctl.state.flags.erase("cargo.mover.stage."+str(n))
				ctl.state.changed.emit()
				say("ok","Identified load returned to marked staging.")
		else: say("warn","The crate is already in staging.")
		return
	if st>=6: say("ok","Delivered. Step away when ready."); return
	if id!=STEPS[st].id: say("warn",NEED[st]); return
	if st==5:
		if not bool(ctl.state.flags.get("cargo.manifest",false)):
			say("warn","Confirm the manifest identity at the inspection scale first."); return
		ctl.act("move_load","scale")
		if _location()=="scale": say("ok",STEPS[st].ok)
		return
	_set_stage(st+1)
	say("ok",STEPS[st].ok)
