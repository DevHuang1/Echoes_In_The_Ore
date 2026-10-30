extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 optional rack board. Humidity/reference/offset telemetry does not
## exist in ShipMissionState, so the illustrated calibration dial is inert.

var ctl
var observed := false
var local_done := false
var fb := {"s":"off","t":"Optional visual check. Humidity measurements are unavailable."}
var mats := {}
func setup(host_layer) -> void: ctl=host_layer
func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func _done() -> bool: return local_done or bool(ctl.state.optional_checks.get("amara_seedling_sensor",false))
func _mat(name: String,r: Rect2,graphic := false) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/"+("graphics/" if graphic else "materials/")+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("seedling:fb")

func paint() -> void:
	screen_bg();hud("Check the seedling rack","HYDROPONICS · SEEDLING RACK","Step away",-10.0,"Optional")
	_rack();_compare();_procedure();_offset()

func _rack() -> void:
	var r := Rect2(20,56,640,432);_module("seedling_rack_sensor_optional_check_mod_0",r,"RACK S-2 · 3 SHELVES")
	module_chip(r,"Grow lights on" if ctl.state.bus_powered("science") else "Grow lights off","live" if ctl.state.bus_powered("science") else "warn")
	B(Rect2(34,100,612,370),{"bg":Color("#10171a"),"border":UI.EDGE})
	_mat("18_0",Rect2(37,103,634,364),true)
	var sensor := Rect2(537,143,120,140)
	B(sensor,{"grad":[[0.0,Color("#efe8d4")],[1.0,Color("#cdc4aa")]],"border":UI.EDGE,"bw":3})
	T(F("label"),11,"RH SENSOR S-2",537,154,UI.INK,14,1,120)
	B(Rect2(551,174,92,38),{"bg":Color("#0f1a1c"),"border":UI.EDGE})
	T(F("num"),34,"--%",551,176,Color("#7fe08a"),34,1,92)
	for i in range(4): R(Rect2(576.5+i*11,218,8,8),Color("#05090b"))
	T(F("label",400,0.78),13,"OFFSET —",537,232,Color("#565b50"),16,1,120)
	_mat("seedling_reference_base",Rect2(537,303,120,150),true)
	T(F("num"),18,"—",537,421.5,UI.INK,18,1,120)
	hit("sensor",Rect2(537,143,120,140))
	hit("reference",Rect2(537,303,120,150))
	if not observed and not _done(): cue(sensor)

func _compare() -> void:
	var r := Rect2(680,56,580,432);_module("seedling_rack_sensor_optional_check_mod_1",r,"COMPARE · HUMIDITY %")
	B(Rect2(700,136,540,22),{"bg":Color("#10171a"),"border":UI.EDGE})
	for i in range(5):
		var label := str(i*25);var x := 700.0+i*(540.0-tw(F("label",400,0.78),13,"100"))/4.0
		T(F("label",400,0.78),13,label,x,176,UI.LABEL,16)
	artifact_glass(Rect2(694,215,552,272))
	var labels := ["SENSOR","REFERENCE","ERROR"]
	for i in range(3):
		T(F("num"),22,labels[i],710,227+i*33.8,UI.PHOS_DIM,28.6)
		T(F("num"),26,"--%" if i==0 else "—",710,224+i*33.8,UI.PHOS_DIM,33.8,2,520)
	artifact_glass_overlay(Rect2(694,215,552,272))

func _procedure() -> void:
	_mat("seedling_rack_sensor_optional_check_paper_0",Rect2(20,500,680,204))
	var n := 2 if _done() else 1 if observed else 0
	var todo := ["Inspect the rack sensor housing.","Record this optional rack check.","Seedling rack check recorded."]
	var why := ["No humidity or calibrated reference reading is available.","Record the visual inspection without changing mist control.","No calibration adjustment was applied."]
	artifact_procedure(n,2,todo[n],why[n],fb)

func _offset() -> void:
	var r := Rect2(720,500,540,204);_module("seedling_rack_sensor_optional_check_mod_2",r,"CALIBRATION OFFSET")
	T(F("body"),16,"UNAVAILABLE",1100,507.6,Color("#ddd8c8"),20.8,2,134)
	_mat("18_2",Rect2(798,544,110,110),true)
	T(F("num"),18,"—",798,632.5,Color("#dfe9e6"),18,1,110)
	for x in [734,922]:
		dim=true;B(Rect2(x,577,50,44),{"notch":true,"insets":[[2,2,0,Color("#557178")],[-2,-2,0,Color("#141e22")]],"outer":[[0,3,0,UI.EDGE]]});T(F("body",400,0.88),22,"−" if x==734 else "+",x,577,UI.TEXT,44,1,50);dim=false
		hit("offset_unavailable",Rect2(x,577,50,44))
	push("offset_unavailable",986,545,140,"SET OFFSET","","",true,false,140,50,16,15,-1,8,false)
	push("record",986,603,140,"RECORD","","done" if _done() else "",not observed or _done(),_done(),140,50,16,15,-1,8,false)
	if observed and not _done(): cue(Rect2(986,603,140,50))

func on_click(id: String,_event) -> void:
	match id:
		"esc": close_requested.emit()
		"sensor": observed=true;say("ok","Sensor housing inspected. Numeric humidity is unavailable.")
		"reference": say("warn","No calibrated reference measurement is available in this watch.")
		"offset_unavailable": say("warn","Humidity calibration is unavailable; no offset was changed.")
		"record":
			if _done(): say("ok","The optional rack check is already recorded.");return
			if not observed: say("warn","Inspect the rack sensor housing first.");return
			var allowed := false
			for a in ctl.state.actions(ctl.prop_id):
				if a.id=="optional:amara_seedling_sensor" and a.enabled: allowed=true
			if not allowed: say("lock","This optional check becomes available after Amara unlocks crew activities.");return
			ctl.act("optional:amara_seedling_sensor")
			if ctl.action_requested.get_connections().is_empty() or bool(ctl.state.optional_checks.get("amara_seedling_sensor",false)):
				local_done=true;say("ok","Rack inspection recorded. No sensor adjustment was made.")
