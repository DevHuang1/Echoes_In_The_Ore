extends "res://scripts/ui/eito/artifact_station_screen.gd"
## Artifact heading board with live signed reference correction.
var dial := 0.0
var compass: Control
const DO := ["Read the planned heading.","Read the instrument heading.","Dial in the correction, then apply.","Verify the corrected heading.","Heading on plan."]
const WHY := ["It is on the flight plan card.","The number under the lubber line on the compass.","Correction = planned − instrument. Within ±0.2°.","Corrected must match planned within ±0.2°.","The measured heading and correction are retained in the ship log."]
func setup(host_layer) -> void:
	super.setup(host_layer);dial=float(_n().correction);fb={"s":"off","t":"Heading check due."}
func _ready() -> void:
	super._ready()
	compass=_Compass.new();compass.board=self;compass.position=Vector2(96,100);compass.size=Vector2(368,368)
	compass.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;compass.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(compass)
func tick(_delta: float) -> void:
	if is_instance_valid(compass): compass.queue_redraw()
func _n() -> Dictionary: return ctl.state.systems.navigation
func _done() -> bool: return bool(_n().verified)
func _stage() -> int:
	if _done(): return 4
	if not bool(ctl.state.flags.get("navigation.plan_read",false)): return 0
	if not bool(ctl.state.flags.get("navigation.compared",false)): return 1
	if not bool(ctl.state.flags.get("navigation.correction_applied",false)) or absf(_error())>0.2001: return 2
	return 3
func _heading() -> float: return float(_n().instrument)+float(_n().correction)
func _error() -> float: return float(_n().planned)-_heading()
func _pad(v: float) -> String: return "%05.1f°"%v
func paint() -> void:
	screen_bg();hud("Check the heading against the plan","BRIDGE · HELM CONSOLE","Step away")
	_hsi();_plan();_reads();_encoder()
	var st := _stage();_procedure("main_helm_console_paper_1",st,4,DO[st],WHY[st])

func _hsi() -> void:
	var r := Rect2(20,56,520,432);_module("main_helm_console_mod_0",r,"HEADING SITUATION")
	var err := _error()
	module_chip(r,"On course" if absf(err)<=0.2 else "Course bar %.1f° %s"%[absf(err),"left" if err<0 else "right"],"ok" if absf(err)<=0.2 else "warn")
	hit("instrument",Rect2(96,100,368,368))
	if _stage()==1: cue(Rect2(96,100,368,368))

func _plan() -> void:
	_mat("main_helm_console_paper_0",Rect2(560,56,330,432))
	T(F("label",400,1.04),13,"FLIGHT PLAN · "+ctl.state.phase.to_upper(),580,72,Color("#6a5a2a"),16)
	T(F("label"),24,"EREBOS → EARTH" if ctl.state.phase=="return" else "EARTH → EREBOS",580,94,UI.INK,31)
	R(Rect2(580,143,290,2),Color("#a39a7b"))
	var labels := ["Planned heading","Tolerance","Next burn"]
	var values := [_pad(float(_n().planned)),"±0.2°","—"]
	for i in range(3):
		T(F("body"),18,labels[i],580,153+i*44,UI.INK,23.4)
		T(F("num"),26,values[i],763,153+i*44,UI.INK,26,2,107)
		for xx in range(580,871,10): R(Rect2(xx,187+i*44,5,1),Color("#c3b997"))
	P(F("body"),16,"Instrument drift is corrected by hand. Enter the difference, not a new heading.",580,291,290,21,UI.INK_2)
	var stamp := "READ" if _stage()>0 else "PLAN"
	var stamp_w := tw(F("label",400,2.2),22,stamp)+30.0
	var ink := UI.INK;ink.a=0.85
	draw_set_transform(Vector2(580+stamp_w*0.5,392.9),deg_to_rad(-5))
	B(Rect2(-stamp_w*0.5,-21.5,stamp_w,43),{"border":ink,"bw":3})
	T(F("label",400,2.2),22,stamp,-stamp_w*0.5+15,-14.5,ink,29)
	draw_set_transform(Vector2.ZERO)
	hit("planned",Rect2(572,65,306,355))
	if _stage()==0: cue(Rect2(580,72,290,340))

func _reads() -> void:
	_module("main_helm_console_mod_1",Rect2(910,56,350,432),"READOUTS")
	var vals := [_pad(float(_n().planned)) if _stage()>=1 else "---.-°",_pad(float(_n().instrument)) if _stage()>=2 else "---.-°",("+" if dial>0 else "")+"%.1f°"%dial,_pad(_heading())]
	var labels := ["PLANNED","INSTRUMENT","CORRECTION (DIAL)","CORRECTED"]
	var cols := [Color("#e9b52c"),Color("#dfe9e6"),Color("#55e0d0"),Color("#7fe08a") if absf(_error())<=0.2 else Color("#e0763a")]
	for i in range(4):
		var y := 100+i*78
		T(F("label",400,1.04),13,labels[i],924,y,UI.LABEL,16)
		var r := Rect2(924,y+16,322,52);artifact_glass(r)
		T(F("num"),44,vals[i],938,y+18,cols[i],48,2,294)
		artifact_glass_overlay(r)

func _encoder() -> void:
	var r := Rect2(720,500,540,204);_module("main_helm_console_mod_2",r,"HEADING CORRECTION")
	T(F("body"),16,"±20.0° · 0.1 step",1095,506,Color("#ddd8c8"),28,2,147)
	_keycap("m10",Rect2(734,558,64,38),"−1.0")
	_keycap("m01",Rect2(734,602,64,38),"−0.1")
	_keycap("p01",Rect2(936,558,64,38),"+0.1")
	_keycap("p10",Rect2(936,602,64,38),"+1.0")
	# The encoder's circles and needle retain the SVG dimensions.
	draw_circle(Vector2(867,599),50,Color("#1a2023"));draw_arc(Vector2(867,599),50,0,TAU,80,UI.EDGE,4)
	draw_circle(Vector2(867,599),38,Color("#3a4448"));draw_arc(Vector2(867,599),38,0,TAU,64,UI.EDGE,3)
	var a := deg_to_rad(dial*6.5);var end := Vector2(867,599)+Vector2(sin(a),-cos(a))*33
	draw_line(Vector2(867,599),end,Color("#e9b52c"),6);draw_circle(end,3,Color("#e9b52c"))
	draw_line(Vector2(867,547),Vector2(867,555),Color("#dfe9e6"),3)
	push("apply",1014,545,110,"APPLY","","",_stage()<2 or _done(),_done(),110,50,16,15,-1,8,false)
	push("verify",1014,603,110,"VERIFY","","working",_stage()<3 or _done(),_done(),110,50,16,15,-1,8,false)
	if _stage()==2: cue(Rect2(1014,545,110,50))
	if _stage()==3: cue(Rect2(1014,603,110,50))

func on_click(id: String,_event) -> void:
	match id:
		"esc": close_requested.emit()
		"planned":
			ctl.state.flags["navigation.plan_read"]=true;say("ok","Planned heading "+_pad(float(_n().planned))+".")
		"instrument":
			if _stage()<1: say("warn","Read the flight plan first.");return
			if not _can("route"): return
			ctl.act("route");say("ok","Instrument reads %s. Correction = planned − instrument."%_pad(float(_n().instrument)))
		"m10","m01","p01","p10":
			if _done(): say("ok","Heading already verified.");return
			dial=snappedf(clampf(dial+{"m10":-1.0,"m01":-0.1,"p01":0.1,"p10":1.0}[id],-20.0,20.0),0.1)
			say("off","Correction %+.1f°."%dial)
		"apply":
			if not _can("correction"): return
			ctl.act("correction",dial);ctl.state.flags["navigation.correction_applied"]=true
			say("ok" if absf(_error())<=0.2 else "warn","Corrected %s. %s"%[_pad(_heading()),"On plan." if absf(_error())<=0.2 else "Off plan by %.1f°. Try again."%absf(_error())])
		"verify":
			if not _can("nav_verify"): return
			ctl.act("nav_verify")
			if _done(): say("ok","Corrected %s. On plan. Verified."%_pad(_heading()))

func on_wheel(id: String,dir: int) -> bool:
	if id not in ["m10","m01","p01","p10"]: return false
	on_click("p01" if dir>0 else "m01",null);return true
func on_key(id: String,event: InputEventKey) -> bool:
	if id not in ["m10","m01","p01","p10"] or event.keycode not in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: return false
	var positive := event.keycode in [KEY_RIGHT,KEY_UP]
	on_click(("p10" if positive else "m10") if event.shift_pressed else ("p01" if positive else "m01"),null);return true

class _Compass extends Control:
	var board
	var textures := {}
	func _texture(name: String) -> Texture2D:
		var key := name+"_hi"+("_dim" if board._stage()<1 else "")
		if not textures.has(key): textures[key]=load("res://art/ui/eito/stations02/graphics/"+key+".res")
		return textures[key]
	func _draw() -> void:
		if board.ctl==null: return
		var err: float=board._error()
		draw_texture_rect(_texture("helm_hsi_base"),Rect2(0,0,368,368),false)
		draw_set_transform(Vector2(184,184),deg_to_rad(-board._heading()))
		draw_texture_rect(_texture("helm_hsi_rose"),Rect2(-184,-184,368,368),false)
		draw_set_transform(Vector2(184,184),deg_to_rad(err))
		draw_texture_rect(_texture("helm_hsi_bug"),Rect2(-184,-184,368,368),false)
		draw_texture_rect(_texture("helm_hsi_course"),Rect2(-184,-184,368,368),false)
		var x := clampf(err*10.0,-60.0,60.0)
		var col := Color("#7fe08a") if absf(err)<=0.2 else Color("#e9b52c")
		if board._stage()<1: col=UI.filt(col,0.2,0.6)
		draw_line(Vector2(x,-52),Vector2(x,52),col,7,true)
		draw_set_transform(Vector2.ZERO)
		draw_texture_rect(_texture("helm_hsi_ship"),Rect2(0,0,368,368),false)
		var text_col := Color("#dfe9e6")
		if board._stage()<1: text_col=UI.filt(text_col,0.2,0.6)
		UI.text(self,board.F("num"),22,board._pad(board._heading()),145,225,text_col,22,1,78)
