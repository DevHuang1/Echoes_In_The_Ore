extends "res://scripts/ui/eito/artifact_station_screen.gd"
## Artifact planning-table composition. The schematic stays blank, and the
## cards reflect the actual story watch or explicit maintenance scenario.
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
var tab := 0
var selected := 0
var records_scroll := 0
func setup(host_layer) -> void: super.setup(host_layer);fb={"s":"off","t":"Planning table on."}
func _story() -> bool: return ctl.state.work_order_context=="first_watch"
func _progress() -> Dictionary: return ctl.state.story_progress
func _receipts() -> Dictionary: return _progress().get("receipts",{})
func _cards() -> Array:
	if _story():
		var receipts := _receipts()
		return [
			{"id":"crew","name":"Review duty roster","done":ctl.state.completed.has("crew"),"room":"CREW QUARTERS","do":"Compare the roster and watch records.","why":"Use the personal computer desk below the bridge corridor."},
			{"id":"hydro.inspect","name":"Inspect nutrient delivery","done":bool(receipts.get("amara.observation_reported",false)),"room":"HYDROPONICS","do":"Inspect nutrient delivery and report to Amara.","why":"Compare reservoir EC, pump capacity, delivered flow and service power."},
			{"id":"power","name":"Restore service power","done":ctl.state.completed.has("power"),"room":"POWER","do":"Restore and verify the science/service feed.","why":"Receive engineering's acknowledgement after stable readings."},
			{"id":"hydro","name":"Restore irrigation","done":ctl.state.completed.has("hydro"),"room":"HYDROPONICS","do":"Restore nutrient delivery, then report to Amara.","why":"Use the existing manifold procedure and verify the recovered readings."},
			{"id":"handoff","name":"Hand over the watch","done":bool(_progress().get("acknowledged",false)),"room":"BRIDGE","do":"Review the measured summary with Maya.","why":"Return after Amara acknowledges the two assigned repairs."},
		]
	var cards := []
	for row in CATALOG.OBJECTIVES:
		cards.append({"id":row[0],"name":row[1],"done":ctl.state.completed.has(row[0]),"room":row[2],"do":ctl.state.next_step(row[0]),"why":ctl.state.prerequisite(row[0])})
	return cards
func _objective() -> String:
	if _story(): return str(_progress().get("objective",{}).get("title",ctl.story_objective if not ctl.story_objective.is_empty() else "Receive the watch"))
	return "Review the verified duties" if ctl.state.flags.get("assigned",false) else "Accept the ship-side duties"
func _save_exists() -> bool: return not str(ctl.save_path).is_empty() and FileAccess.file_exists(ctl.save_path)
func paint() -> void:
	screen_bg();hud(_objective(),"BRIDGE · PLANNING TABLE","Step away",-10.0,"DAY 184" if _story() else ctl.state.phase.to_upper())
	_schematic();_tabs();_detail();_tapes()

func _schematic() -> void:
	var r := Rect2(20,56,760,432);_module("mission_planning_table_mod_0",r,"SHIP SCHEMATIC · DECK 1")
	var cards := _cards();var done := 0
	for card in cards:
		if card.done: done+=1
	module_chip(r,"%d / %d duties done"%[done,cards.size()],"live")
	UI.bezel(self,Rect2(34,100,732,368))
	# Deliberately blank: no prototype ship illustration, room markers or hits.
	artifact_glass(Rect2(48,114,704,340));artifact_glass_overlay(Rect2(48,114,704,340))

func _tabs() -> void:
	for i in range(3):
		var r := Rect2(800+i*154,56,148,36)
		B(r,{"bg":Color("#efe8d4") if tab==i else Color("#bfb69a"),"border":UI.EDGE,"bw":3})
		T(F("label"),13,["DUTIES","BRIEFING","RECORDS"][i],r.position.x+4,r.position.y+5,UI.INK,26)
		hit("tab:"+str(i),r)
	_mat("mission_planning_table_paper_0",Rect2(800,90,460,398))
	match tab:
		0: _duties()
		1: _briefing()
		2: _records()
func _duties() -> void:
	T(F("label",400,0.75),13,"DUTY CARDS · CURRENT WATCH",818,104,Color("#6a5a2a"),20)
	var cards := _cards();var rowh := 40 if cards.size()<=6 else 38
	for i in range(cards.size()):
		var c: Dictionary=cards[i];var y := 128+i*rowh
		B(Rect2(818,y,22,22),{"border":UI.INK})
		if c.done: T(F("num"),20,"✓",821,y-1,Color("#2f7a37"),25)
		T(F("body"),17,str(c.name),850,y,UI.INK,26)
		T(F("label"),11,"DONE" if c.done else "OPEN",1183,y+2,Color("#2f7a37") if c.done else Color("#9c3b20"),20,2,58)
		for x in range(818,1243,10): R(Rect2(x,y+30,5,1),Color("#c3b997"))
		hit("duty:"+str(i),Rect2(816,y-4,428,rowh))

func _briefing() -> void:
	B(Rect2(818,104,64,64),{"bg":Color("#3a4448"),"border":UI.EDGE,"bw":3})
	T(F("label"),22,"M",818,115,Color("#e9b52c"),40,1,64)
	T(F("label"),18,"MAYA",894,116,UI.INK,24)
	T(F("label",400,1.04),13,"CDR · COMMS",894,140,Color("#6a5a2a"),16)
	var text := "Receive Maya's actual watch assignment over the ship comms."
	if _story(): text=str(_progress().get("objective",{}).get("description",text))
	else: text="Accept the current maintenance scenario's duties. Existing progress is retained."
	var text_rows := P(F("body"),18,text,818,180,424,23.4,UI.INK)
	var action := "story:briefing" if _story() else "assign"
	var a := _action(action);var locked := a.is_empty() or not bool(a.get("enabled",false))
	var by := 194.0+text_rows*23.4
	push("brief",818,by,200,"HEAR BRIEFING" if _story() else "ACCEPT DUTIES","","",locked,false,200,50,16,15,-1,8,false)
	if not locked: cue(Rect2(818,by,200,50))

func _summary_lines() -> PackedStringArray:
	var text := str(_progress().get("summary","")) if _story() else ""
	if text.is_empty():
		for c in _cards(): text+=("VERIFIED · " if c.done else "OPEN · ")+str(c.name)+"\n"
		if _story():
			text+="\nMeasured power\n"+ctl.state.readings("power")+"\n\nMeasured irrigation\n"+ctl.state.readings("hydro")
		else:
			text+="\n"+str(ctl.state.systems.communications.report_text)
	var lines := PackedStringArray()
	for line in text.split("\n"):
		var parts: PackedStringArray=UI.wrap_text(F("body"),16,line,360)
		if parts.is_empty(): lines.append("")
		else: lines.append_array(parts)
	return lines
func _records() -> void:
	T(F("label",400,0.75),13,"WATCH SUMMARY · REVIEW",818,104,Color("#6a5a2a"),20)
	var lines := _summary_lines();records_scroll=clampi(records_scroll,0,maxi(0,lines.size()-5))
	var count := mini(5,lines.size()-records_scroll)
	for i in range(count):
		var y := 120.0+i*34.8
		T(F("num"),18,"—",818,y+6,UI.INK,20.8)
		T(F("body"),16,lines[records_scroll+i],882,y+6,UI.INK,20.8)
		for x in range(818,1242,10): R(Rect2(x,y+32.8,5,2),Color("#c3b997"))
	hit("records:scroll",Rect2(816,120,426,count*34.8),{"focus":false,"wheel_only":true})
	var by := 132.0+count*34.8
	T(F("num"),15,"SCROLL · %d–%d / %d"%[records_scroll+1,mini(records_scroll+5,lines.size()),lines.size()],818,by+63,UI.INK_2,18)
	if _story() and bool(_progress().get("acknowledged",false)):
		B(Rect2(818,by+3,200,50),{"grad":[[0.0,Color("#7fd685")],[1.0,Color("#4c9f52")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#c9f5c9")],[-2,-2,0,Color("#2c6a31")]],"outer":[[0,3,0,UI.EDGE]]})
		T(F("label",400,0.64),16,"ACKNOWLEDGED",818,by+3,UI.INK,50,1,200)
	else:
		var a := _action("story:summary" if _story() else "file_report")
		push("review",818,by,200,"SIGN SUMMARY" if _story() else "FILE REPORT","","",a.is_empty() or not bool(a.get("enabled",false)),false,200,50,16,15,-1,8,false)

func _detail() -> void:
	_mat("mission_planning_table_paper_1",Rect2(20,500,680,204))
	var cards := _cards();selected=clampi(selected,0,cards.size()-1);var c: Dictionary=cards[selected]
	var hh := artifact_procedure(-1,0,str(c.do),str(c.why),fb,str(c.room))
	chip(38+tw(F("label",400,0.75),15,str(c.room))+12,514+(hh-23)*0.5,"Done" if c.done else "Open","ok" if c.done else "warn",16,UI.INK,23)

func _tapes() -> void:
	var r := Rect2(720,500,540,204);_module("mission_planning_table_mod_1",r,"LOG TAPES · SAVE / LOAD")
	T(F("body"),16,"1 live slot",1130,506,Color("#ddd8c8"),28,2,111)
	for i in range(3):
		var x := 734+i*175;var available := i==0
		B(Rect2(x,546,162,76),{"bg":Color("#1a2023"),"border":UI.EDGE,"bw":3})
		B(Rect2(x+11,557,140,22),{"bg":Color("#efe8d4") if available and _save_exists() else Color("#6f807c"),"border":UI.EDGE})
		T(F("label"),12,"SHIP SAVE" if available and _save_exists() else "EMPTY" if available else "UNAVAILABLE",x+19,558,UI.INK,20)
		for xx in [x+36,x+125]: draw_arc(Vector2(xx,597),10,0,TAU,32,Color("#9db3b4"),3)
		T(F("num"),14,"--:--",x+64,587,Color("#9db3b4"),20,1,34)
		_keycap("save:"+str(i),Rect2(x,628,78,38),"SAVE",false,not available or ctl.save_path.is_empty(),11)
		_keycap("load:"+str(i),Rect2(x+84,628,78,38),"LOAD",false,not available or not _save_exists(),11)

func external_feedback(message: String,success: bool) -> void: say("ok" if success else "fault",message)
func on_wheel(id: String,dir: int) -> bool:
	if id!="records:scroll": return false
	records_scroll=maxi(0,records_scroll-dir*3);return true
func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id.begins_with("tab:"): tab=int(id.get_slice(":",1));return
	if id.begins_with("duty:"):
		selected=int(id.get_slice(":",1));var c: Dictionary=_cards()[selected];say("ok" if c.done else "warn",str(c.name)+": "+("done." if c.done else "open."));return
	if id=="brief":
		var action := "story:briefing" if _story() else "assign"
		if _can(action): ctl.act(action)
		return
	if id=="review":
		var action := "story:summary" if _story() else "file_report"
		if _can(action): ctl.act(action)
		return
	if id.begins_with("save:") or id.begins_with("load:"):
		if int(id.get_slice(":",1))!=0: say("warn","The game currently supports one ship save slot.");return
		if ctl.save_path.is_empty(): say("warn","This preview has no save destination.");return
		if id.begins_with("load:"):
			if not _save_exists(): say("warn","The ship save slot is empty.");return
			ctl.load_requested.emit()
		else: ctl.save_requested.emit()
