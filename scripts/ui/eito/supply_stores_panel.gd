extends "res://scripts/ui/eito/eito_screen.gd"
## Stations 02 supply-store board. Only the three actual quarters stores are
## offered here. Cargo and engine lockers remain hiding-only and cannot be used
## to transfer supplies. Every transfer goes through ShipMissionState.

const IDS := ["quarters.drawer.1", "quarters.drawer.2", "quarters.wardrobe"]
const NAMES := ["Crew drawer A", "Crew drawer B", "Wardrobe"]
const PLATES := ["QUARTERS · DRAWER A", "QUARTERS · DRAWER B", "QUARTERS · WARDROBE"]
const CODES := {"filter_cartridge":"FILTER-A", "scrubber_media":"SCRUB-A", "nutrient_buffer":"BUFFER-A", "coolant_charge":"COOL-02", "engineering_multitool":"MT-4", "pressure_sealant":"SEAL-P", "oxygen_reserve":"O2-01", "inert_purge":"N2-03"}
const NAMES_ITEM := {"filter_cartridge":"Air filter cartridge", "scrubber_media":"Scrubber media", "nutrient_buffer":"Nutrient buffer", "coolant_charge":"Coolant cylinder", "engineering_multitool":"Multitool", "pressure_sealant":"Pressure sealant", "oxygen_reserve":"Oxygen reserve", "inert_purge":"Inert purge"}
const CARRIABLE := ["filter_cartridge", "scrubber_media", "nutrient_buffer", "coolant_charge", "engineering_multitool", "pressure_sealant", "oxygen_reserve", "inert_purge"]
const HUD := preload("res://scripts/ui/walk_hud.gd")

var ctl
var selected := 0
var page := 0
var fb := {"s":"", "t":"Store open."}
var log_lines: Array = []
var mats := {}

func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func setup(host_layer) -> void:
	ctl=host_layer
	selected=maxi(0,IDS.find(ctl.prop_id))

func _material(name: String,r: Rect2) -> void:
	if not mats.has(name): mats[name]=load("res://art/ui/eito/stations02/materials/"+name+".res")
	if mats[name]!=null: draw_texture_rect(mats[name],r,false)

func say(s: String,message: String) -> void:
	fb={"s":s,"t":message};pop("stores:fb")

func _items() -> Array:
	var items: Array=[]
	for id in ctl.state.stocks.get(IDS[selected],{}): items.append(str(id))
	items.sort()
	return items

func _carried() -> Array:
	var carried: Array=[]
	if ctl.state.inventory.has_method("inventory_snapshot"):
		var snapshot: Dictionary=ctl.state.inventory.inventory_snapshot()
		for id in snapshot.storage+snapshot.hotbar+snapshot.equipment.values():
			if not str(id).is_empty(): carried.append(str(id))
		return carried
	for id in CARRIABLE:
		for _n in range(int(ctl.state.inventory.inventory_count(StringName(id)))): carried.append(id)
	return carried

func paint() -> void:
	screen_bg()
	hud("Take or put away equipment",PLATES[selected],"Close store",-10.0,"STORES")
	_tabs()
	_bins()
	_carry()
	_log()
	_issue()

func _header(r: Rect2,title: String) -> void:
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)

func _tabs() -> void:
	for i in range(4):
		var r := Rect2(20+i*312.5,56,302.5,44)
		var on := i==selected
		var available := i<3
		artifact_key("tab:"+str(i),r,"",on,not available)
		var label: String = NAMES[i] if available else "Trolley drawers"
		var f := F("body",400,0.72);var number_font := F("num",400,0.72)
		var number_w := tw(number_font,22,"0%d"%(i+1))
		var w := number_w+10+tw(f,18,label)
		var x := r.position.x+(r.size.x-w)*0.5
		dim=not available
		T(number_font,22,"0%d"%(i+1),x,56+(2 if on else 0),Color("#e9b52c"),44)
		T(f,18,label,x+number_w+10,56+(2 if on else 0),UI.CUE if on else UI.TEXT,44)
		dim=false

func _bins() -> void:
	var r := Rect2(20,112,760,376)
	_material("supply_drawers_and_lockers_mod_0",r)
	_header(r,NAMES[selected].to_upper()+" · CREW QUARTERS")
	module_chip(r,"Store open","ok")
	B(Rect2(34,156,732,300),{"bg":Color("#1b2326"),"border":UI.EDGE,"bw":3})
	for x in range(41,763,8): R(Rect2(x,159,4,294),Color("#222c30"))
	var items := _items()
	# The source CSS grid distributes spare height after each row's intrinsic
	# content height. Empty bins have a shorter label stack than stocked bins.
	var top_h := 170.0 if items.size()<=3 else 137.0
	for i in range(6):
		var col := i%3; var row := i/3
		var box := Rect2(41+col*(243.333333),163 if row==0 else 175+top_h,231.333333,top_h if row==0 else 274-top_h)
		var active := i<items.size()
		var count := int(ctl.state.stocks[IDS[selected]].get(items[i],0)) if active else 0
		dim=not active or count<=0
		B(box,{"grad":[[0.0,Color("#3a4448")],[1.0,Color("#2a3236")]],"border":UI.EDGE,"bw":3,"insets":[[0,-16,0,Color("#1a2023")]]})
		if active:
			var id: String=items[i]
			var code := str(CODES.get(id,id.to_upper()))
			var tagw := tw(F("label"),13,code)+16
			B(Rect2(box.position.x+13,box.position.y+11,tagw,24),{"bg":Color("#efe8d4"),"border":UI.EDGE})
			T(F("label"),13,code,box.position.x+21,box.position.y+15,UI.INK,16)
			T(F("body"),16,str(NAMES_ITEM.get(id,id)),box.position.x+13,box.position.y+39,Color("#dfe9e6"),20.8)
			var qty := "%02d"%count
			T(F("num"),34,qty,box.position.x+13,box.position.y+63.8,Color("#7fe08a") if count>0 else Color("#e0763a"),34)
			T(F("label",400,0.78),13,"pcs",box.position.x+19+tw(F("num"),34,qty),box.position.y+77.8,UI.TEXT,16)
			T(F("label",400,0.78),13,"TAKE ONE" if count>0 else "EMPTY",box.position.x+13,box.position.y+101.8,Color("#9db3b4"),16)
			hit("take:"+id,box,{"locked":count==0})
		else:
			B(Rect2(box.position.x+13,box.position.y+11,16,8),{"bg":Color("#efe8d4"),"border":UI.EDGE})
			T(F("body"),16,"empty",box.position.x+13,box.position.y+23,Color("#dfe9e6"),20.8)
		dim=false

func _carry() -> void:
	var r := Rect2(800,112,460,376)
	_material("supply_drawers_and_lockers_mod_1",r)
	_header(r,"CARRIED")
	var carried := _carried()
	T(F("body"),16,"%d carried"%carried.size(),1104,119.6,Color("#ddd8c8"),20.8,2,130)
	page=mini(page,maxi(0,(carried.size()-1)/6))
	for i in range(6):
		var idx := page*6+i
		var box := Rect2(814+(i%3)*147.333333,156+(i/3)*102,137.333333,92)
		var active := idx<carried.size()
		dim=not active
		B(box,{"grad":[[0.0,Color("#3a4448") if active else Color("#151b1e")],[1.0,Color("#2a3236") if active else Color("#151b1e")]],"border":UI.EDGE,"bw":3,"insets":[[0,0,2,Color("#3a4448")]]})
		if active:
			var id: String=carried[idx]
			var definition: Dictionary=HUD.ITEM_DATA.get(StringName(id),{})
			var name_text := str(NAMES_ITEM.get(id,definition.get("name",id)))
			var rows := UI.wrap_text(F("body"),14,name_text,box.size.x-6).size()
			var top := box.position.y+(92-20-rows*18.2)*0.5
			T(F("label"),13,str(CODES.get(id,definition.get("short",id.to_upper()))),box.position.x,top,Color("#e9b52c"),16,1,box.size.x)
			P(F("body"),14,name_text,box.position.x+3,top+20,box.size.x-6,18.2,Color("#dfe9e6"),false,1)
			hit(("store:" if id in CARRIABLE else "carry:")+id,box)
		else: T(F("body"),14,"empty",box.position.x,box.position.y+38.9,Color("#dfe9e6"),18.2,1,box.size.x)
		dim=false
	P(F("body"),16,"Click a bin to take one. Click a carried item to put it back in this store.",814,364,432,20,Color("#b4c3c1"))
	if carried.size()>6:
		T(F("label"),12,"PAGE %d / %d · WHEEL TO SCROLL"%[page+1,int(ceil(float(carried.size())/6.0))],814,441,UI.LABEL,18)
		hit("carry:scroll",Rect2(814,156,430,208),{"wheel_only":true,"focus":false})

func _log() -> void:
	_material("supply_drawers_and_lockers_paper_0",Rect2(20,500,760,204))
	T(F("label",400,0.78),13,"CUSTODY LOG · "+NAMES[selected].to_upper(),38,525.5,Color("#6a5a2a"),16)
	var stamp_w := tw(F("label",400,2.2),22,"CHECKED")+30.0
	var ink := Color(UI.INK,0.85)
	draw_set_transform(Vector2(762-stamp_w*0.5,533.5),deg_to_rad(-4))
	B(Rect2(-stamp_w*0.5,-21.5,stamp_w,43),{"border":ink,"bw":3})
	T(F("label",400,2.2),22,"CHECKED",-stamp_w*0.5+15,-14.5,ink,29)
	draw_set_transform(Vector2.ZERO)
	for i in range(mini(4,log_lines.size())):
		var line: Dictionary=log_lines[i]
		var y := 566+i*34.1
		T(F("num"),18,str(line.t),38,y,UI.INK,18)
		T(F("label"),13,str(line.dir),110,y,Color("#9c3b20") if line.dir=="OUT" else Color("#2f7a37"),16)
		T(F("body"),17,str(line.what),192,y,UI.INK,22.1)
		T(F("num"),18,"YOU",38,y,UI.INK,18,2,724)
		for x in range(38,761,10): R(Rect2(x,y+27.1,5,2),Color("#c3b997"))

func _issue() -> void:
	var r := Rect2(800,500,460,204)
	_material("supply_drawers_and_lockers_mod_2",r)
	_header(r,"SUPPLY TRANSFER")
	module_chip(r,"Available","live")
	var note := "Shared quarters stores. One item moves between this furniture and your existing inventory per click."
	var note_h := UI.wrap_text(F("body"),16,note,266).size()*20.0
	var group_h := maxf(50,note_h);var cy := 544+(group_h-50)*0.5
	# The prototype-only kit button becomes a genuine read-only store indicator
	# in the same cap and column. Transfers remain on the individual item bins.
	B(Rect2(814,cy,150,50),{"grad":[[0.0,Color("#cfc7a8")],[1.0,Color("#a9a083")]],"border":UI.EDGE,"insets":[[2,2,0,Color("#f0ead2")],[-2,-2,0,Color("#7e7660")]],"outer":[[0,6,0,UI.EDGE]]})
	T(F("label",400,0.64),16,"STORE OPEN",814,cy,Color("#1f2326"),50,1,150)
	P(F("body"),16,note,980,544,266,20,Color("#b4c3c1"))
	var feedback_top := 544+group_h+10
	T(F("num"),22,"FEEDBACK",814,feedback_top,UI.PHOS_DIM,28.6)
	var lines := UI.wrap_text(F("num"),22,str(fb.t),328)
	var w := minf(328,tw(F("num"),22,str(fb.t)))
	var x := 1246-w-24
	lamp(Vector2(x,feedback_top+(lines.size()*28.6-18)*0.5),str(fb.s))
	P(F("num"),22,str(fb.t),x+24,feedback_top,w,28.6,UI.TEXT)

func on_wheel(id: String,dir: int) -> bool:
	if id!="carry:scroll": return false
	page=clampi(page-dir,0,maxi(0,(_carried().size()-1)/6));return true

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit();return
	if id.begins_with("carry:"):
		say("warn","Service supplies only; equipment stays carried.");return
	if id.begins_with("tab:"):
		var n := int(id.trim_prefix("tab:"))
		if n==selected: return
		say("warn","Visit that furniture to transfer items.")
		return
	if id.begins_with("take:") or id.begins_with("store:"):
		var item := id.get_slice(":",1)
		var before := int(ctl.state.stocks[IDS[selected]].get(item,0))
		ctl.act(id)
		var after := int(ctl.state.stocks[IDS[selected]].get(item,0))
		if before==after: return
		var taking := id.begins_with("take:")
		log_lines.push_front({"t":"--:--","dir":"OUT" if taking else "IN","what":str(NAMES_ITEM.get(item,item))+" "+str(CODES.get(item,item))})
		if log_lines.size()>4: log_lines.resize(4)
		say("ok",("Took " if taking else "Stored ")+str(NAMES_ITEM.get(item,item))+".")
