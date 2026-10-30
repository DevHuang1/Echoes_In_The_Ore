extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 optional nutrient-pump inspection. The illustration is the
## artifact SVG; only flow percentage exists in the current ship model.

var ctl
var stage := 0
var fb := {"s":"off","t":"Optional check. Read the live nutrient delivery first."}
var mats := {}

func setup(host_layer) -> void: ctl=host_layer
func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func _done() -> bool: return bool(ctl.state.optional_checks.get("amara_nutrient_pump",false)) or stage>=2
func _mat(name: String,r: Rect2,graphic := false) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/"+("graphics/" if graphic else "materials/")+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("nutrient:fb")

func paint() -> void:
	screen_bg();hud("Inspect the nutrient pump","HYDROPONICS · NUTRIENT PUMP","Step away",-10.0,"Optional")
	_pump();_readings();_procedure();_card()

func _pump() -> void:
	var r := Rect2(20,56,520,432);_module("nutrient_pump_optional_check_mod_0",r,"PUMP N-1 · RUNNING")
	module_chip(r,"On line" if ctl.state.systems.hydro.flow>0 else "Stopped","ok" if ctl.state.systems.hydro.flow>0 else "warn")
	B(Rect2(34,100,492,370),{"grad":[[0.0,Color("#1b2326")],[1.0,Color("#141a1d")]],"border":UI.EDGE})
	_mat("nutrient_pump_base",Rect2(37,103,514,364),true)
	var frame := int(fmod(now,1.2)/1.2*8.0) if float(ctl.state.systems.hydro.flow)>0 else 0
	_mat("nutrient_impeller_frame_"+str(frame),Rect2(37,103,514,364),true)
	draw_circle(Vector2(407,363),6,Color("#e9b52c"));draw_arc(Vector2(407,363),6,0,TAU,24,UI.EDGE,2)
	# The artifact includes two physical probe touch points. They are retained as
	# unavailable labels because vibration and bearing temperature are unmodeled.
	for d in [[Rect2(273,283,74,32),"VIB PROBE",Color("#e9b52c")],[Rect2(355,283,74,32),"IR TEMP",Color("#e0763a")]]:
		dim=true;B(d[0],{"bg":d[2],"border":UI.EDGE});T(F("label"),11,d[1],d[0].position.x,d[0].position.y,UI.INK,32,1,74);dim=false
		hit("unavailable",d[0])
	# Actual nutrient flow is a percentage; the meter is illustrative.
	_mat("nutrient_rotameter_base",Rect2(493,193,50,200),true)
	var fy := 377.0-clampf(float(ctl.state.systems.hydro.flow),0,100)*1.7
	draw_colored_polygon(PackedVector2Array([Vector2(511,fy),Vector2(525,fy),Vector2(521,fy+14),Vector2(515,fy+14)]),Color("#e9b52c"))
	draw_polyline(PackedVector2Array([Vector2(511,fy),Vector2(525,fy),Vector2(521,fy+14),Vector2(515,fy+14),Vector2(511,fy)]),UI.EDGE,2,true)
	hit("flow",Rect2(493,193,50,200))
	if stage==0 and not _done(): cue(Rect2(493,193,50,200))

func _readings() -> void:
	var r := Rect2(560,56,700,432);_module("nutrient_pump_optional_check_mod_1",r,"HANDHELD READINGS")
	T(F("label"),13,"VIBRATION · mm/s",576,101,UI.LABEL,18)
	artifact_glass(Rect2(574,116,374,170))
	_mat("17_2",Rect2(576,126,370,150),true)
	T(F("num"),20,"RMS",574,287,UI.PHOS_DIM,27)
	T(F("num"),20,"—",924,287,UI.PHOS_DIM,27,2,24)
	T(F("label"),13,"BEARING TEMP",1046,101,UI.LABEL,18)
	_mat("17_3",Rect2(1014,116,180,170),true)
	draw_set_transform(Vector2(1110,166),deg_to_rad(-10))
	T(F("num"),24,"—",-20,-12,UI.PHOS,24,1,40)
	draw_set_transform(Vector2.ZERO)
	T(F("num"),20,"LIMIT",961,287,UI.PHOS_DIM,27)
	T(F("num"),20,"—",1218,287,UI.PHOS,27,2,28)
	for x in [574,918]: artifact_glass(Rect2(x,330,329,82))
	T(F("num"),22,"FLOW",588,342,UI.PHOS_DIM,28)
	T(F("num"),28,"%.0f%%"%float(ctl.state.systems.hydro.flow),786,342,UI.PHOS,34,2,103)
	T(F("num"),19,"EXPECTED",588,379,UI.PHOS_DIM,24)
	T(F("num"),19,"≥90%",752,379,UI.PHOS,24,2,137)
	T(F("num"),19,"HOURS",932,342,UI.PHOS_DIM,26)
	T(F("num"),19,"—",1188,342,UI.PHOS,26)
	T(F("num"),19,"LAST CHECK",932,379,UI.PHOS_DIM,24)
	T(F("num"),19,"—",1188,379,UI.PHOS,24)

func _procedure() -> void:
	_mat("nutrient_pump_optional_check_paper_0",Rect2(20,500,680,204))
	var n := 2 if _done() else stage
	var todo := ["Read the nutrient delivery flow.","Record the optional inspection.","Nutrient pump inspection recorded."]
	var why := ["The ship tracks delivered flow as a percentage of its normal rate.","Record the observation in the current watch.","No vibration or bearing-temperature telemetry was recorded."]
	artifact_procedure(n,2,todo[n],why[n],fb)

func _card() -> void:
	_mat("nutrient_pump_optional_check_paper_1",Rect2(720,500,540,204))
	T(F("label",400,0.75),15,"INSPECTION CARD · N-1",738,514,Color("#6a5a2a"),26)
	draw_set_transform(Vector2(1181,534),deg_to_rad(-4))
	B(Rect2(-62,-22,124,44),{"border":Color("#354346"),"bw":3})
	T(F("label",400,2.2),22,"LOGGED" if _done() else "BLANK",-59,-16,Color("#354346"),32,1,118)
	draw_set_transform(Vector2.ZERO)
	var labels := ["Vibration","Bearing temperature","Flow"]
	var values := ["— · unmeasured","— · unmeasured","%.0f%%"%float(ctl.state.systems.hydro.flow) if stage>=1 or _done() else ""]
	for i in range(3):
		var y := 562+i*34
		T(F("body"),17,labels[i],738,y,UI.INK,22)
		T(F("num"),20,values[i],1022,y,UI.INK,22,2,216)
		for x in range(738,1240,10): R(Rect2(x,y+27,5,1),Color("#c3b997"))
	push("record",1104,643,138,"RECORD","","done" if _done() else "",stage<1 or _done(),_done(),120,50,16,15,-1,8,false)

func on_click(id: String,_event) -> void:
	match id:
		"esc": close_requested.emit()
		"unavailable": say("warn","This ship does not expose vibration or bearing-temperature measurements.")
		"flow":
			if not _done(): stage=maxi(stage,1)
			say("ok","Nutrient delivery is %.0f%% of normal flow."%float(ctl.state.systems.hydro.flow))
		"record":
			if _done(): say("ok","The optional inspection is already recorded.");return
			if stage<1: say("warn","Read the live nutrient delivery first.");return
			var allowed := false
			for a in ctl.state.actions(ctl.prop_id):
				if a.id=="optional:amara_nutrient_pump" and a.enabled: allowed=true
			if not allowed: say("lock","This optional check becomes available after Amara unlocks crew activities.");return
			ctl.act("optional:amara_nutrient_pump")
			if ctl.action_requested.get_connections().is_empty() or bool(ctl.state.optional_checks.get("amara_nutrient_pump",false)):
				stage=2;say("ok","Pump inspection recorded for the current watch.")
