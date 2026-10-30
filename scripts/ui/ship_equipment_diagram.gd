extends Control
## Live instrument schematics, never a ship map or a second simulation.
const UI := preload("res://scripts/ui/equipment_ui.gd")
const PRESENT := preload("res://scripts/ui/ship_station_presentation.gd")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
var model: Object
var definition := {}

func _init() -> void:
	custom_minimum_size=Vector2(260,130)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func bind(state: Object, prop: Dictionary) -> void:
	model=state;definition=prop;queue_redraw()

func point(x: float,y: float) -> Vector2:
	return Vector2(roundf(x*size.x/600.0),roundf(y*size.y/240.0))

func area(x: float,y: float,w: float,h: float) -> Rect2:
	return Rect2(point(x,y),point(w,h))

func text_at(x: float,y: float,text: String,color: Color=UI.TEXT,font_size:=12) -> void:
	draw_string(UI.FONT,point(x,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func module(x: float,y: float,w: float,h: float,title: String,color: Color=UI.CYAN) -> void:
	var rect := area(x,y,w,h)
	draw_rect(rect,UI.METAL);draw_rect(rect.grow(-3),UI.SHADOW)
	draw_line(rect.position,Vector2(rect.end.x,rect.position.y),UI.EDGE,2)
	var well := rect.grow(-7);draw_rect(well,UI.WELL)
	for corner in [rect.position+Vector2(3,3),rect.end-Vector2(6,6)]: draw_rect(Rect2(corner,Vector2(3,3)),UI.EDGE)
	draw_rect(Rect2(rect.position+Vector2(10,10),Vector2(6,6)),color)
	text_at(x+25,y+22,title,color)

func pipe(points: Array,color: Color) -> void:
	for i in range(points.size()-1):
		var a: Vector2=point(points[i].x,points[i].y)
		var b: Vector2=point(points[i+1].x,points[i+1].y)
		draw_line(a,b,UI.SHADOW,10);draw_line(a,b,UI.METAL,6);draw_line(a,b,color,2)

func _draw() -> void:
	if model==null: return
	draw_rect(Rect2(Vector2.ZERO,size),UI.WELL)
	for x in range(12,int(size.x),18): draw_rect(Rect2(x,8,2,2),UI.SHADOW)
	var kind: String=definition.get("kind","")
	if kind=="storage": _storage();return
	if kind=="planning": _planning();return
	if kind=="navigation": _navigation();return
	if kind=="communications": _communications();return
	if kind in ["crew","rest","chair"]: _quarters(kind);return
	match str(definition.get("room","")):
		"power": _power()
		"engine": _engine()
		"life": _life()
		"hydro": _hydro()
		"cargo": _cargo(kind)
		_: _storage()

func _power() -> void:
	var p: Dictionary=model.systems.power
	var science: bool=model.bus_powered("science")
	var essential: bool=model.bus_powered("essential")
	pipe([Vector2(160,70),Vector2(230,70),Vector2(230,45),Vector2(330,45)],UI.CYAN if essential else UI.RED)
	pipe([Vector2(230,70),Vector2(230,125),Vector2(330,125)],UI.CYAN if science else UI.AMBER)
	pipe([Vector2(230,125),Vector2(230,205),Vector2(330,205)],UI.AMBER)
	module(15,25,145,90,"AUX BANK",UI.CYAN if p.calibrated else UI.AMBER)
	text_at(30,75,"SYNCED" if p.calibrated else "NOT SYNCED",UI.TEXT)
	for i in range(3): draw_rect(area(35+i*34,90,23,8),UI.CYAN if p.calibrated else UI.AMBER)
	module(15,145,145,75,"SERVICE",UI.AMBER if p.isolated else UI.CYAN)
	text_at(30,195,"ISOLATED" if p.isolated else "CONNECTED")
	draw_rect(area(180,132 if p.isolated else 157,24,7),UI.AMBER if p.isolated else UI.EDGE)
	module(330,15,250,60,"ESSENTIAL / %d V" % (24 if essential else 0),UI.CYAN if essential else UI.RED)
	text_at(345,60,"LIFE SUPPORT / %d UNITS" % p.essential)
	module(330,95,250,60,"SCIENCE / %d V" % (24 if science else 0),UI.CYAN if science else UI.AMBER)
	text_at(345,140,"IRRIGATION - NAV - RELAY",UI.MUTED)
	module(330,175,250,60,"RESERVE",UI.AMBER)
	text_at(345,220,"%d UNITS / CAPACITY %d" % [p.reserve,p.capacity])

func _engine() -> void:
	var id: String=str(definition.get("id",""))
	if id.begins_with("engine.pump"): _engine_pump();return
	if id.begins_with("engine.turbine"): _engine_turbine();return
	if id.begins_with("engine.valve"): _engine_valve();return
	var e: Dictionary=model.systems.engine
	for i in range(2):
		var y := 20.0+i*100
		var flow: float=model.engine_flow(i)
		var c := UI.CYAN if flow>=0.9 else UI.AMBER
		pipe([Vector2(133,y+48),Vector2(209,y+48),Vector2(350,y+48),Vector2(410,y+48)],c)
		pipe([Vector2(515,y+75),Vector2(515,y+90),Vector2(65,y+90),Vector2(65,y+75)],c)
		module(12,y,130,75,"PUMP %d" % (i+1),UI.AMBER if e.isolated[i] else c)
		text_at(27,y+47,"HEALTH %.0f%%" % (e.health[i]*100))
		text_at(27,y+68,"ISOLATED" if e.isolated[i] else "IN CIRCUIT",UI.AMBER if e.isolated[i] else UI.MUTED)
		module(209,y,140,75,"VALVE %d" % (i+1),UI.AMBER if e.valves[i]<0.9 else UI.CYAN)
		var center := point(240,y+57)
		var radius := minf(13.0,size.y*0.045)
		draw_arc(center,radius,0,TAU,16,UI.METAL,3,false)
		draw_line(center-Vector2(radius-3,0),center+Vector2(radius-3,0),UI.AMBER,3)
		text_at(265,y+64,"%.0f%%" % (e.valves[i]*100))
		module(410,y,175,75,"TURBINES",c)
		var numbers: String="01 + 03" if i==0 else "02 + 04"
		text_at(425,y+47,numbers)
		text_at(425,y+68,"OUTPUT %.0f%%" % (e.load*100),UI.MUTED)
	var pressure: String=model.readings("engine").get_slice("\n",3).trim_prefix("Upstream/downstream pressure: ")
	text_at(20,238,pressure,UI.AMBER if e.health[0]<0.9 or e.valves[1]<0.9 else UI.CYAN)

func _engine_loop() -> int:
	var id: String=str(definition.get("id",""))
	return 0 if id.ends_with(".1") or id.ends_with(".3") else 1

func _engine_pump() -> void:
	var e: Dictionary=model.systems.engine
	var loop_index := _engine_loop()
	var flow: float=model.engine_flow(loop_index)
	var good: bool=flow>=0.9 and e.temperature<=65
	module(12,18,385,194,"COOLANT PUMP %d / CUTAWAY" % (loop_index+1),UI.CYAN if good else UI.AMBER)
	module(415,18,173,194,"LOOP READOUT",UI.CYAN if good else UI.AMBER)
	pipe([Vector2(20,111),Vector2(130,111),Vector2(290,111),Vector2(386,111)],UI.CYAN if good else UI.AMBER)
	var center := point(210,111)
	for radius in [64.0,49.0,31.0]: draw_arc(center,radius,0,TAU,32,UI.METAL,5,false)
	for i in range(6):
		var a := Vector2.from_angle(i*TAU/6)
		draw_line(center+a*12,center+a*39,UI.EDGE,7)
	text_at(32,197,"HEALTH %.0f%%" % (e.health[loop_index]*100),UI.CYAN if good else UI.AMBER)
	text_at(431,89,"FLOW %.0f%%" % (flow*100),UI.CYAN if good else UI.AMBER)
	text_at(431,128,"TEMP %.1f C" % e.temperature)
	text_at(431,165,"ISOLATED" if e.isolated[loop_index] else "IN CIRCUIT",UI.AMBER if e.isolated[loop_index] else UI.MUTED)
	text_at(18,237,"SERVICE REQUIRES COOL-02 + MULTITOOL / STABLE FLOW VERIFICATION",UI.MUTED)

func _engine_turbine() -> void:
	var e: Dictionary=model.systems.engine
	var loop_index := _engine_loop()
	var flow: float=model.engine_flow(loop_index)
	var cooling: bool=flow>=0.9 and e.temperature<=65
	var verified: bool=cooling and model.completed.has("engine")
	module(12,18,358,194,"TURBINE / INSPECTION PORT",UI.CYAN if cooling else UI.AMBER)
	module(390,18,198,194,"OUTPUT AND COOLING",UI.CYAN if cooling else UI.AMBER)
	var center := point(190,112)
	for radius in [78.0,66.0,29.0]: draw_arc(center,radius,0,TAU,40,UI.METAL,5,false)
	for i in range(8):
		var a := Vector2.from_angle(i*TAU/8)
		draw_line(center+a*32,center+a*61,UI.EDGE,9)
	text_at(405,81,"OUTPUT %.0f%%" % (e.load*100))
	text_at(405,120,"FLOW %.0f%%" % (flow*100),UI.CYAN if cooling else UI.AMBER)
	text_at(405,160,"VERIFIED" if verified else "IN RANGE" if cooling else "OUT OF RANGE",UI.CYAN if cooling else UI.AMBER)
	text_at(18,237,"COOLING INDICATOR IS READ-ONLY / CONTROL VIA ENGINE SERVICE",UI.MUTED)

func _engine_valve() -> void:
	var e: Dictionary=model.systems.engine
	var loop_index := _engine_loop()
	var opening: float=e.valves[loop_index]
	var color: Color=UI.CYAN if opening>=0.9 else UI.AMBER
	module(12,18,395,194,"FEED MANIFOLD / LOOP %d" % (loop_index+1),color)
	module(425,18,163,194,"LINE CONTROL",color)
	pipe([Vector2(30,143),Vector2(390,143)],color)
	for i in range(3):
		var x := 76.0+i*116
		pipe([Vector2(x,78),Vector2(x,143)],color)
		var center := point(x,69)
		draw_arc(center,21,0,TAU,16,UI.AMBER,5,false)
		draw_line(center-Vector2(13,0),center+Vector2(13,0),UI.AMBER,4)
		text_at(x-12,197,"V%d" % (i+1),UI.MUTED)
	text_at(443,104,"%.0f%%" % (opening*100),color,24)
	text_at(443,153,"ISOLATED" if e.isolated[loop_index] else "IN CIRCUIT",UI.MUTED)
	text_at(18,237,"THREE PHYSICAL HANDWHEELS / ONE RECORDED LOOP OPENING",UI.MUTED)

func _life() -> void:
	match str(definition.get("id","")):
		"life.duct": _life_duct();return
		"life.filter": _life_filter();return
		"life.scrubber": _life_scrubber();return
		"life.oxygen": _life_oxygen();return
	var l: Dictionary=model.systems.life
	var flow := UI.AMBER if l.airflow<62 or l.isolated else UI.CYAN
	pipe([Vector2(125,65),Vector2(180,65),Vector2(320,65),Vector2(460,65)],flow)
	module(10,20,115,100,"INTAKE",flow)
	for i in range(5): draw_rect(area(27,58+i*9,75,3),UI.METAL)
	module(170,20,125,100,"FILTER",UI.CYAN if l.serviced or model.phase=="return" else UI.AMBER)
	for i in range(6): draw_rect(area(187+i*14,60,6,39),UI.METAL)
	module(335,20,125,100,"SCRUBBER",UI.CYAN if l.scrubber>=0.9 else UI.RED)
	text_at(350,66,"SCRUB-A")
	text_at(350,96,"%.0f%%" % (l.scrubber*100),UI.CYAN if l.scrubber>=0.9 else UI.RED)
	module(495,20,95,100,"AIR",flow)
	text_at(508,70,"%.0f%%" % l.airflow)
	pipe([Vector2(180,185),Vector2(545,185),Vector2(545,120)],UI.CYAN)
	module(10,150,190,75,"RESERVE O2",UI.AMBER if l.reserve<50 else UI.CYAN)
	text_at(25,202,"O2-01 / %.0f%%" % l.reserve)
	text_at(235,175,"RESERVE SUPPLY RETAINED",UI.MUTED)
	text_at(235,220,"HOUSING ISOLATED" if l.isolated else "CIRCULATION CONNECTED",UI.AMBER if l.isolated else UI.CYAN)

func _life_duct() -> void:
	var l: Dictionary=model.systems.life
	var flow: Color=UI.CYAN if l.airflow>=62 and l.airflow<=72 and not l.isolated else UI.AMBER
	module(12,20,376,192,"DUCT 2 / SECTION",flow)
	module(408,20,180,192,"INSTRUMENTS",flow)
	draw_rect(area(40,76,321,75),UI.METAL)
	draw_rect(area(47,83,307,61),UI.WELL)
	for x in range(73,340,26): draw_rect(area(float(x),89,5,50),UI.SHADOW)
	pipe([Vector2(20,113),Vector2(360,113)],flow)
	text_at(28,193,"SERVICE HOUSING / "+("ISOLATED" if l.isolated else "CONNECTED"),UI.MUTED)
	text_at(425,82,"AIRFLOW %.0f%%" % l.airflow,flow)
	text_at(425,120,"O2 %.1f%%" % l.oxygen)
	text_at(425,158,"CO2 %.3f%%" % l.co2)
	text_at(20,237,"CURRENT READINGS ONLY / NO RECORDED TREND",UI.MUTED)

func _life_filter() -> void:
	var l: Dictionary=model.systems.life
	module(12,18,363,194,"FILTER HOUSING / DUCT 2",UI.CYAN if l.serviced else UI.AMBER)
	module(394,18,194,194,"FIT AND AIRFLOW",UI.CYAN if l.airflow>=62 else UI.AMBER)
	draw_rect(area(95,56,188,128),UI.METAL)
	draw_rect(area(105,67,168,107),UI.SHADOW)
	for x in range(118,266,18): draw_rect(area(float(x),76,7,88),UI.EDGE if l.serviced else UI.AMBER)
	text_at(24,202,"FILTER-A / "+("SEATED" if l.serviced else "SERVICE NEEDED"),UI.CYAN if l.serviced else UI.AMBER)
	text_at(416,84,"HOUSING",UI.MUTED)
	text_at(416,116,"ISOLATED" if l.isolated else "CONNECTED",UI.AMBER if l.isolated else UI.CYAN)
	text_at(416,163,"%.0f%%" % l.airflow,UI.CYAN if l.airflow>=62 else UI.AMBER,24)
	text_at(18,237,"AIRFLOW TARGET 62-72% / FILTER SERVICE USES EXISTING CONTROLS",UI.MUTED)

func _life_scrubber() -> void:
	var l: Dictionary=model.systems.life
	var healthy: bool=l.scrubber>=0.9 and l.co2<=0.1
	module(12,18,365,194,"SWING BEDS / CO2 REMOVAL",UI.CYAN if healthy else UI.AMBER)
	module(395,18,193,194,"CABIN CO2",UI.CYAN if l.co2<=0.1 else UI.RED)
	for i in range(2):
		var x := 43.0+i*155
		draw_rect(area(x,66,123,106),UI.METAL)
		draw_rect(area(x+9,77,105,83),UI.WELL)
		for y in range(88,155,14): draw_rect(area(x+18,float(y),87,5),UI.CYAN if healthy else UI.AMBER)
		text_at(x+22,191,"BED "+("A" if i==0 else "B"),UI.MUTED)
	text_at(412,99,"%.3f%%" % l.co2,UI.CYAN if l.co2<=0.1 else UI.RED,23)
	text_at(412,146,"REMOVAL %.0f%%" % (l.scrubber*100),UI.MUTED)
	text_at(18,237,"SCRUB-A MEDIUM / MAXIMUM CABIN CO2 0.100%",UI.MUTED)

func _life_oxygen() -> void:
	var l: Dictionary=model.systems.life
	module(12,18,388,194,"OXYGEN RACK / RESERVE",UI.CYAN if l.reserve>=50 else UI.AMBER)
	module(416,18,172,194,"REGULATOR",UI.CYAN if l.oxygen>=20 and l.oxygen<=22 else UI.AMBER)
	for i in range(3):
		var x := 38.0+i*118
		draw_rect(area(x,65,75,129),UI.METAL)
		draw_rect(area(x+10,76,55,106),UI.WELL)
		draw_rect(area(x+27,52,20,18),UI.EDGE)
		text_at(x+15,204,"O2-%02d" % (i+1),UI.MUTED)
	text_at(432,93,"%.1f%%" % l.oxygen,UI.CYAN if l.oxygen>=20 and l.oxygen<=22 else UI.AMBER,23)
	text_at(432,145,"BANK %.0f%%" % l.reserve,UI.MUTED)
	text_at(18,237,"O2 RESERVE IS DISTINCT FROM CO2 REMOVAL",UI.MUTED)

func _hydro() -> void:
	match str(definition.get("id","")):
		"hydro.pump": _hydro_pump();return
		"hydro.seedlings": _hydro_seedlings();return
	var h: Dictionary=model.systems.hydro
	var env: Dictionary=model.hydro_environment()
	var good: bool=h.flow>=90 and h.ec>=1.8 and h.ec<=2.4
	var flow := UI.CYAN if good else UI.AMBER
	pipe([Vector2(135,70),Vector2(205,70),Vector2(350,70),Vector2(450,70)],flow)
	pipe([Vector2(540,190),Vector2(540,225),Vector2(70,225),Vector2(70,170)],flow)
	module(10,20,135,170,"RESERVOIR",UI.CYAN if h.ec>=1.8 and h.ec<=2.4 else UI.AMBER)
	draw_rect(area(32,85,90,80),UI.SHADOW)
	draw_rect(area(35,100,84,62),Color("245c67"))
	text_at(25,63,"EC %.2f" % h.ec)
	text_at(25,180,"BUFFER-A",UI.MUTED)
	module(205,20,130,100,"PUMP",UI.AMBER if h.isolated else UI.CYAN)
	draw_arc(point(270,80),18,0,TAU,16,UI.EDGE,4,false)
	text_at(218,155,"ISOLATED" if h.isolated else "CAPACITY %.0f%%" % env.pump_capacity,UI.MUTED)
	module(355,20,90,100,"VALVES",UI.CYAN if h.aligned else UI.AMBER)
	for i in range(3): draw_rect(area(370+i*19,65,8,32),UI.CYAN if h.aligned else UI.AMBER)
	module(470,20,120,175,"GROW BEDS",flow)
	for i in range(3):
		draw_rect(area(485,65+i*32,85,22),UI.SHADOW)
		for x in range(3):
			var center := point(500+x*23,75+i*32)
			draw_line(center+Vector2(0,7),center-Vector2(0,5),UI.CYAN if good else UI.AMBER,3)
	text_at(210,186,"RECOVERING" if good else "DELIVERY WARNING",flow)
	text_at(210,210,"BAY %.0f%% RH / RANGE 55-70" % env.humidity,UI.MUTED)

func _hydro_pump() -> void:
	var h: Dictionary=model.systems.hydro
	var env: Dictionary=model.hydro_environment()
	var good: bool=h.flow>=90 and not h.isolated
	module(12,18,390,194,"NUTRIENT PUMP / RUNNING STATE",UI.CYAN if good else UI.AMBER)
	module(420,18,168,194,"HANDHELD READINGS",UI.CYAN if good else UI.AMBER)
	pipe([Vector2(20,110),Vector2(130,110),Vector2(275,110),Vector2(389,110)],UI.CYAN if good else UI.AMBER)
	var center := point(201,112)
	for radius in [66.0,49.0,27.0]: draw_arc(center,radius,0,TAU,24,UI.METAL,6,false)
	for i in range(6):
		var a := Vector2.from_angle(i*TAU/6)
		draw_line(center+a*23,center+a*43,UI.EDGE,7)
	text_at(30,195,"ISOLATED" if h.isolated else "DELIVERY CONNECTED",UI.AMBER if h.isolated else UI.CYAN)
	text_at(434,88,"FLOW %.0f%%" % h.flow)
	text_at(434,126,"EC %.2f" % h.ec)
	text_at(434,163,"CAP %.0f%%" % env.pump_capacity,UI.MUTED)
	text_at(18,237,"OPTIONAL CHECK RECORDS EXISTING PUMP READINGS",UI.MUTED)

func _hydro_seedlings() -> void:
	var h: Dictionary=model.systems.hydro
	var env: Dictionary=model.hydro_environment()
	var humidity: float=env.humidity
	var healthy: bool=humidity>=55 and humidity<=70 and h.flow>=90
	module(12,18,377,194,"SEEDLING RACK / THREE SHELVES",UI.CYAN if healthy else UI.AMBER)
	module(408,18,180,194,"BAY COMPARISON",UI.CYAN if healthy else UI.AMBER)
	for i in range(3):
		var y := 70.0+i*47
		draw_rect(area(34,y,331,10),UI.METAL)
		for x in range(53,345,43):
			var center := point(float(x),y-6)
			draw_line(center+Vector2(0,8),center-Vector2(0,7),UI.CYAN if healthy else UI.AMBER,3)
			draw_line(center-Vector2(0,3),center-Vector2(7,8),UI.CYAN if healthy else UI.AMBER,3)
			draw_line(center-Vector2(0,3),center+Vector2(7,-8),UI.CYAN if healthy else UI.AMBER,3)
	text_at(426,91,"%.0f%% RH" % humidity,UI.CYAN if healthy else UI.AMBER,21)
	text_at(426,129,"BAND 55-70%",UI.MUTED)
	text_at(426,166,"FLOW %.0f%%" % h.flow)
	text_at(18,237,"OPTIONAL SENSOR CHECK / NO CALIBRATION CONTROL IN GAME",UI.MUTED)

func _cargo(kind: String) -> void:
	var c: Dictionary=model.systems.cargo
	match str(definition.get("id","")):
		"cargo.scale": _cargo_scale();return
		"cargo.mover": _cargo_mover();return
		"cargo.trolley": _cargo_trolley();return
	if kind=="cylinders":
		var ids := ["coolant_charge","oxygen_reserve","inert_purge"]
		for i in range(3):
			var x := 20.0+i*195
			module(x,30,170,185,PRESENT.ITEMS[ids[i]])
			draw_rect(area(x+50,75,60,85),UI.METAL)
			draw_rect(area(x+65,60,30,15),UI.EDGE)
			draw_rect(area(x+55,106,50,24),UI.INK)
			text_at(x+23,185,"STOCK %d" % model.stocks["cargo.cylinders"].get(ids[i],0))
		text_at(25,235,"COOLANT / OXYGEN / INERT PURGE - NOT INTERCHANGEABLE",UI.MUTED)
		return
	pipe([Vector2(175,120),Vector2(230,120),Vector2(395,120),Vector2(445,120)],UI.AMBER if c.quarantined else UI.CYAN)
	module(15,35,160,155,"CARGO-A12")
	draw_rect(area(37,90,115,70),UI.METAL)
	for x in [50,130]: draw_rect(area(x,90,9,70),UI.SHADOW)
	text_at(30,215,"SEAL: "+("GAP" if model.phase=="return" else "MATCH") if c.seal_checked else "SEAL: NOT CHECKED",UI.AMBER if model.phase=="return" else UI.MUTED)
	module(230,35,165,155,"INSPECTION")
	text_at(247,102,"%.1f kg" % c.measured_mass if c.weighed else "--.- kg",UI.CYAN,20)
	text_at(247,135,"ZEROED" if c.tare else "ZERO REQUIRED",UI.CYAN if c.tare else UI.AMBER)
	draw_rect(area(245,155,135,12),UI.METAL)
	text_at(240,215,"%.1f +/- 0.5 kg" % c.manifest_mass,UI.MUTED)
	module(445,35,140,155,"CUSTODY",UI.AMBER if c.quarantined else UI.CYAN)
	text_at(460,100,str(c.location).to_upper(),UI.AMBER if c.quarantined else UI.TEXT)
	text_at(460,135,"UNOPENED" if c.quarantined else "HANDLING LOG",UI.MUTED)
	text_at(25,238,"20 kg CHECK REFERENCE / TARE EMPTY PLATFORM",UI.MUTED)

func _cargo_scale() -> void:
	var c: Dictionary=model.systems.cargo
	module(10,18,180,192,"SCALE / LOAD CELL",UI.CYAN if c.tare else UI.AMBER)
	module(208,18,205,192,"PLATFORM",UI.CYAN if c.location=="scale" else UI.MUTED)
	module(430,18,160,192,"CUSTODY",UI.AMBER if c.quarantined else UI.CYAN)
	draw_rect(area(28,70,144,75),UI.INK)
	text_at(38,111,"%.1f kg" % c.measured_mass if c.weighed else "--.- kg",UI.CYAN,23)
	text_at(28,174,"ZEROED" if c.tare else "ZERO REQUIRED",UI.CYAN if c.tare else UI.AMBER)
	draw_rect(area(228,63,165,120),UI.METAL)
	draw_rect(area(237,72,147,102),UI.WELL)
	for x in [245.0,375.0]: draw_rect(area(x,80,7,86),UI.EDGE)
	text_at(240,202,"LOAD: "+str(c.location).to_upper(),UI.CYAN if c.location=="scale" else UI.MUTED)
	text_at(447,83,str(c.id))
	text_at(447,120,"SEAL CHECKED" if c.seal_checked else "SEAL PENDING",UI.CYAN if c.seal_checked else UI.AMBER)
	text_at(447,158,"QUARANTINED" if c.quarantined else "UNOPENED")
	text_at(20,236,"MANIFEST %.1f kg  /  TOLERANCE +/- 0.5 kg" % c.manifest_mass,UI.MUTED)

func _cargo_mover() -> void:
	var c: Dictionary=model.systems.cargo
	module(12,16,220,200,"TILLER HEAD")
	module(250,16,338,200,"FORKS AND LOAD",UI.CYAN if c.location=="scale" else UI.AMBER)
	draw_rect(area(60,55,110,35),UI.METAL)
	draw_rect(area(75,90,80,62),UI.SHADOW)
	for x in [83.0,139.0]: draw_rect(area(x,143,10,28),UI.METAL)
	text_at(34,198,"IDENTIFIED LOAD / "+str(c.id),UI.MUTED)
	draw_rect(area(282,66,260,74),UI.SHADOW)
	for y in [72.0,122.0]:
		draw_rect(area(296,y,234,12),UI.METAL)
		draw_rect(area(520,y,14,15),UI.EDGE)
	text_at(275,180,"DESTINATION / "+str(c.location).to_upper(),UI.CYAN)
	text_at(16,236,"SECURED TRANSFER ONLY / NO PHYSICAL DRIVING",UI.MUTED)

func _cargo_trolley() -> void:
	var stock: Dictionary=model.stocks.get("cargo.trolley",{})
	module(12,15,270,205,"MAINTENANCE TROLLEY")
	for i in range(3):
		var y := 62.0+i*43
		draw_rect(area(35,y,223,34),UI.METAL)
		draw_rect(area(47,y+4,199,26),UI.SHADOW)
		draw_rect(area(115,y+15,60,5),UI.EDGE)
	for x in [55.0,228.0]: draw_arc(point(x,205),9,0,TAU,12,UI.METAL,3,false)
	module(300,15,288,205,"DRAWER STOCK",UI.CYAN)
	var items := [["filter_cartridge","FILTER-A"],["scrubber_media","SCRUB-A"],["coolant_charge","COOL-02"],["nutrient_buffer","BUFFER-A"]]
	for i in range(items.size()):
		var y := 68.0+i*35
		text_at(322,y,items[i][1],UI.MUTED)
		text_at(505,y,"x%d" % int(stock.get(items[i][0],0)),UI.CYAN)
	text_at(16,238,"ISSUE KIT TO CARRIED INVENTORY / STOCK DEDUCTS ONCE",UI.MUTED)

func _planning() -> void:
	# The approved planning frame leaves its central viewport empty until a
	# real ship schematic exists. Live assignment/status text stays in Records.
	draw_rect(Rect2(Vector2.ZERO,size),Color("04100c"))
	draw_rect(Rect2(Vector2.ZERO,Vector2(size.x,2)),UI.METAL)
	draw_rect(Rect2(Vector2.ZERO,Vector2(2,size.y)),UI.METAL)

func _navigation() -> void:
	var n: Dictionary=model.systems.navigation
	var good: bool=absf(n.instrument+n.correction-n.planned)<=0.2
	var center := point(170,120)
	var radius := minf(size.x*0.21,size.y*0.40)
	draw_arc(center,radius,0,TAU,48,UI.METAL,7,false)
	for i in range(12):
		var a := Vector2.from_angle(i*TAU/12-PI/2)
		draw_line(center+a*(radius-7),center+a*radius,UI.EDGE,2)
	for entry in [[n.planned,UI.MUTED],[n.instrument+n.correction,UI.CYAN if good else UI.AMBER]]:
		var a := Vector2.from_angle(deg_to_rad(entry[0])-PI/2)
		draw_line(center,center+a*(radius-12),entry[1],3)
	text_at(120,235,"HEADING REFERENCE",UI.MUTED)
	module(350,25,235,78,"SIGNED CORRECTION",UI.CYAN if good else UI.AMBER)
	text_at(370,79,"%+.1f deg" % n.correction,UI.TEXT,20)
	module(350,130,235,80,"REFERENCE CHECK",UI.CYAN if good else UI.AMBER)
	text_at(370,182,"IN TOLERANCE" if good else "OUT OF TOLERANCE")
	text_at(370,202,"TARGET +/- 0.2 deg",UI.MUTED)

func _communications() -> void:
	var c: Dictionary=model.systems.communications
	var linked: bool=c.channel=="earth"
	pipe([Vector2(170,100),Vector2(225,100),Vector2(370,100),Vector2(430,100)],UI.CYAN if c.acknowledged else UI.AMBER)
	module(15,40,155,140,"DUTY PACKET",UI.CYAN if c.report_ready else UI.MUTED)
	for i in range(5): draw_rect(area(35,83+i*13,110 if i<4 else 75,3),UI.EDGE if c.report_ready else UI.SHADOW)
	module(225,40,145,140,"TRANSMITTER",UI.CYAN if c.sent else UI.AMBER)
	text_at(242,103,str(c.mode).to_upper())
	text_at(242,143,"SENT" if c.sent else "STANDBY",UI.MUTED)
	module(430,40,155,140,"EARTH RELAY" if linked else "LOCAL CREW",UI.CYAN if c.acknowledged else UI.AMBER)
	text_at(445,103,"ACK RECEIVED" if c.acknowledged else "AWAITING ACK" if c.sent else "NO PACKET")
	text_at(25,220,"ACK %.1f / 3.0 s" % minf(3,float(model.verification.get("ack",0))),UI.CYAN if c.acknowledged else UI.MUTED)

func _quarters(kind: String) -> void:
	if kind=="crew":
		for i in range(CATALOG.CREW.size()):
			var y := 15.0+i*43
			draw_rect(area(15,y,570,36),UI.INK)
			draw_rect(area(24,y+12,7,7),UI.CYAN if model.flags.get("crew.log",false) else UI.MUTED)
			text_at(47,y+25,CATALOG.CREW[i])
			var record: String=("OLD LOG / UNCONFIRMED" if model.phase=="return" else "ROUTINE ENTRY") if model.flags.get("crew.log",false) else "AWAITING REVIEW"
			text_at(335,y+25,record,UI.AMBER if model.phase=="return" else UI.MUTED)
		return
	if kind=="chair":
		module(30,25,250,185,"OPERATOR ACCESS")
		draw_rect(area(105,65,95,30),UI.METAL)
		draw_rect(area(105,95,95,60),Color("285464"))
		draw_rect(area(88,96,16,70),UI.METAL);draw_rect(area(201,96,16,70),UI.METAL)
		draw_rect(area(145,165,18,20),UI.EDGE);draw_rect(area(110,184,85,8),UI.METAL)
		text_at(320,70,"STATION ACCESS",UI.CYAN)
		text_at(320,115,"USE ADJACENT CONSOLE")
		text_at(320,155,"DUTIES REMAIN RECORDED",UI.MUTED)
		return
	module(30,25,250,185,"CAPSULE REST" if kind=="rest" else "OPERATOR ACCESS")
	for i in range(2):
		draw_rect(area(60,75+i*60,190,45),UI.METAL)
		draw_rect(area(75,83+i*60,160,28),Color("285464"))
	text_at(320,70,"REST AVAILABLE" if kind=="rest" else "STANDING CONSOLE ACCESS",UI.CYAN)
	text_at(320,115,"FATIGUE %.0f%%" % model.systems.crew.fatigue)
	text_at(320,155,"DUTIES REMAIN RECORDED",UI.MUTED)

func _storage() -> void:
	var stocks: Dictionary=model.stocks.get(definition.get("id",""),{})
	var keys: Array=stocks.keys()
	if keys.is_empty():
		module(50,45,500,145,"SHARED SERVICE STORE")
		text_at(75,110,"EMPTY / RETURN CARRIED SUPPLIES",UI.MUTED)
		text_at(75,153,"SELECT CARRIED ITEMS UNDER RETURN",UI.MUTED)
		return
	for i in range(keys.size()):
		var x := 12.0+(i%2)*296
		var y := 14.0+int(i/2.0)*55
		var item: String=str(keys[i]);var count: int=stocks[item]
		module(x,y,280,48,PRESENT.ITEMS.get(item,item.to_upper()),UI.CYAN if count>0 else UI.MUTED)
		text_at(x+25,y+39,"STOCK %d / CARRIED %d" % [count,model.inventory.inventory_count(StringName(item))],UI.MUTED)
