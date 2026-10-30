extends "res://scripts/ui/eito/eito_screen.gd"
## Cargo scale board from Stations 02. All equipment readings and decisions are
## taken from ShipMissionState; the reference-block inspection is a local UI step.

const STEPS := [
	{"do":"Read the shipping tag.","why":"It says what this load is and what it should weigh."},
	{"do":"Check the seal without opening the crate.","why":"Look through the magnifier. The number must match the tag."},
	{"do":"Zero the empty scale.","why":"The crate must still be in staging. Press ZERO."},
	{"do":"Check the 20 kg reference block.","why":"A known weight proves the scale reads true."},
	{"do":"Bring the crate onto the scale.","why":"Use the pallet mover. Never drag a sealed load."},
	{"do":"Wait for STABLE, then read the mass.","why":"A moving load reads wrong. Hold the reading once it settles."},
	{"do":"Record what the readings support.","why":"Compare ID, seal and mass with the tag."},
]
const DONE := {"do":"Cargo inspected and secured.","why":"The release slip is in the cargo log. Step away when ready."}
const NEED := ["Read the shipping tag first.","Check the seal first.","Zero the empty scale first.","Check the reference block first.","Bring the crate onto the scale first.","Read the settled mass first.","Record the disposition."]
var ctl
var fb := {"s":"","t":"Panel ready."}
var ref_checked := false
var _material_cache := {}

func F(kind: String,w := 400,sp := 0.0) -> Font:
	return UI.artifact_font(kind,w,sp)

func setup(host_layer) -> void:
	ctl = host_layer
	ref_checked = bool(ctl.state.flags.get("cargo.reference_checked", false))

func S() -> Object: return ctl.state
func CARGO() -> Dictionary: return S().systems.cargo
func tag_read() -> bool: return bool(S().flags.get("cargo.manifest", false))
func seal_read() -> bool: return bool(CARGO().seal_checked)
func zeroed() -> bool: return bool(CARGO().tare)
func on_scale() -> bool: return str(CARGO().location) == "scale"
func weighed() -> bool: return bool(CARGO().weighed)
func finished() -> bool: return S().completed.has("cargo")
func step() -> int:
	if finished(): return 7
	if not tag_read(): return 0
	if not seal_read(): return 1
	if not zeroed(): return 2
	# The existing tare action already verifies the reference block. A player
	# who used the separate mover before opening that readout must not be trapped.
	if not ref_checked and not on_scale(): return 3
	if not on_scale(): return 4
	if not weighed(): return 5
	return 6

func say(s: String, message: String) -> void:
	fb = {"s":s,"t":message}; pop("cargo:fb")

func paint() -> void:
	screen_bg()
	hud("Inspect and secure the cargo", "CARGO BAY · INSPECTION SCALE", "Step away")
	_indicator()
	_platform()
	_manifest()
	_reference()
	_position()
	_disposition()
	_paper()

func _material(asset_name: String,r: Rect2) -> void:
	if not _material_cache.has(asset_name):
		_material_cache[asset_name] = load("res://art/ui/eito/stations02/materials/"+asset_name+".res")
	draw_texture_rect(_material_cache[asset_name],r,false)

func _graphic(asset_name: String,r: Rect2) -> void:
	var key := asset_name+"_dim" if dim else asset_name
	if not _material_cache.has(key):
		var texture: Texture2D=load("res://art/ui/eito/stations02/graphics/"+asset_name+".res")
		_material_cache[key]=ImageTexture.create_from_image(UI.filt_image(texture.get_image(),0.2,0.6)) if dim else texture
	draw_texture_rect(_material_cache[key],r,false)

func module(r: Rect2,title: String) -> void:
	var mat := "cargo_manifest_module"
	match title:
		"CHECK WEIGHT": mat="cargo_weight_module"
		"LOAD POSITION": mat="cargo_position_module"
		"DISPOSITION": mat="cargo_disposition_module"
	_material(mat,r)
	var hx := r.position.x+4.0
	R(Rect2(hx,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(hx,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,hx+22,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,hx+22,r.position.y+8,UI.LABEL,20)

func _indicator() -> void:
	var bezel_r := Rect2(20,56,420,270)
	_material("cargo_indicator_bezel",bezel_r)
	var glass_r := Rect2(32,68,396,150)
	artifact_glass(glass_r)
	T(F("num",400,0.88),22,"GROSS WEIGHT",46,74,UI.PHOS,26)
	T(F("num",400,0.88),22,"CAP 500 kg · d 0.1",46,74,UI.PHOS_DIM,26,2,368)
	var reading := " --.-"
	if zeroed(): reading = "  0.0"
	if on_scale() and not weighed(): reading = " --.-"
	if weighed(): reading = "%5.1f" % float(CARGO().measured_mass)
	T(F("num"),92,"888.8",34,114,UI.PHOS_FAINT,92,2,328)
	T(F("num"),92,reading,34,114,UI.PHOS,92,2,328)
	T(F("num"),30,"kg",384,162,UI.PHOS_DIM,39)
	artifact_glass_overlay(glass_r)
	var lamps := [["ZERO","ok" if zeroed() and not on_scale() else ""],["STABLE","ok" if weighed() or zeroed() and not on_scale() else ""],["MOTION","warn" if on_scale() and not weighed() else ""],["REF","ok" if ref_checked else ""]]
	var lx := 32.0
	for pair in lamps:
		lamp(Vector2(lx,228),pair[1]); lx += 24.0
		lx += T(F("label",400,0.65),13,pair[0],lx,228,Color("#ddd8c8"),18) + 12.0
	_key("zero",Rect2(32,258,125.33,38),"ZERO",false,step()==2)
	_key("read",Rect2(167.33,258,125.34,38),"HOLD · READ",false,step()==5)
	_key("print",Rect2(302.67,258,125.33,38),"PRINT",false,false)

func _platform() -> void:
	var outer := Rect2(452,56,248,432)
	_material("cargo_platform_bezel",outer)
	var g := Rect2(464,68,224,408)
	artifact_glass(g)
	T(F("num",400,0.72),18,"PLATFORM",478,74,UI.PHOS,26)
	T(F("num",400,0.72),18,"TOP",478,74,UI.PHOS_DIM,26,2,196)
	_graphic("cargo_platform_loaded" if on_scale() else "cargo_platform_empty",Rect2(466,110,224,300))
	if on_scale():
		T(F("num"),20,str(CARGO().id),466,242.8,UI.PHOS,20,1,224)
	# Individual load-cell telemetry is not present in the game model.
	var cells := ["—","—","—","—"] if on_scale() else ["0.0","0.0","0.0","0.0"]
	T(F("num"),18,"LC1 "+cells[0],476,391.2,UI.PHOS,23.4)
	T(F("num"),18,"LC2 "+cells[1],476,391.2,UI.PHOS,23.4,2,200)
	T(F("num"),18,"LC3 "+cells[2],476,416.6,UI.PHOS,23.4)
	T(F("num"),18,"LC4 "+cells[3],476,416.6,UI.PHOS,23.4,2,200)
	T(F("num"),18,"MOVER BAY ↓",476,442.6,UI.PHOS_DIM,23.4)
	artifact_glass_overlay(g)

func _manifest() -> void:
	var r := Rect2(720,56,540,210)
	module(r,"MANIFEST AND SEAL")
	module_chip(r,"Record gap" if seal_read() and S().phase=="return" else "Seal intact" if seal_read() else "Seal not checked","warn" if seal_read() and S().phase=="return" else "ok" if seal_read() else "")
	var tag := Rect2(734,100,300,150)
	_graphic("cargo_shipping_tag_material",tag)
	var tag_text := "Sealed crate · expected %.1f kg ± 0.5 · exterior seal record" % float(CARGO().manifest_mass) if tag_read() else "Tap to read the tag."
	var rows := UI.wrap_text(F("body"),16,tag_text,244).size()
	var tag_y := 175.0-(16.0+33.0+rows*20.0)*0.5
	T(F("label",400,0.78),13,"SHIPPING TAG",776,tag_y,Color("#6a5a2a"),16)
	T(F("label",400,2.08),26,str(CARGO().id),776,tag_y+16,UI.INK,33)
	P(F("body"),16,tag_text,776,tag_y+49,244,20,UI.INK if tag_read() else UI.INK_2)
	hit("tag",tag)
	# Its original clipped tag silhouette also clips the CSS guidance corners.
	dim=step()<1
	_graphic("cargo_magnifier_base",Rect2(1068,100,150,150))
	if seal_read():
		B(Rect2(1101,151,66,30),{"bg":Color("#e9b52c"),"border":UI.EDGE})
		T(F("num"),20,"GAP" if S().phase=="return" else "MATCH",1102,156,UI.INK,20,1,64)
		T(F("label"),11,"RECORD GAP" if S().phase=="return" else "EXTERIOR",1102,193,UI.WARN if S().phase=="return" else UI.PHOS,14,1,64)
	else: T(F("label"),11,"INSPECT",1102,157,UI.PHOS_DIM,14,1,64)
	dim=false
	hit("seal",Rect2(1048,100,190,150))
	if step()==1: cue(Rect2(1048,100,190,150))
	for x in [726,1240]: draw_texture_rect(UI.tex("screw"),Rect2(x,248,12,12),false)

func _reference() -> void:
	var r := Rect2(720,278,264,210)
	module(r,"CHECK WEIGHT")
	dim=step()<3
	_graphic("cargo_reference_block",Rect2(734,322,62,80))
	T(F("body"),17,"Reference block",810,329,UI.TEXT,22.1)
	P(F("body"),15,"Read 20.0 kg. Scale is true." if ref_checked else "Place it on the zeroed platform.",810,355.1,160,19.5,Color("#b4c3c1"))
	dim=false
	for i in range(10):
		var cell := Rect2(734+i*23.8,416,21.8,10)
		R(cell,UI.PHOS if ref_checked else Color("#0b1714"))
		R(Rect2(cell.position,Vector2(cell.size.x,1)),Color.BLACK);R(Rect2(cell.position,Vector2(1,10)),Color.BLACK)
	T(F("label",400,0.78),13,"TOLERANCE ± 0.1 kg",734,432,Color("#8fa9a7"),16)
	hit("ref",Rect2(734,322,236,80))
	if step()==3: cue(Rect2(734,322,236,80))

func _position() -> void:
	var r := Rect2(996,278,264,210)
	module(r,"LOAD POSITION")
	var loc: String=str(CARGO().location)
	lamp(Vector2(1010,323),"ok" if loc=="staging" else "")
	T(F("body"),17,"Staging",1034,320,UI.TEXT,22)
	T(F("body"),17,"→",1115,320,Color("#557178"),22)
	lamp(Vector2(1159,323),"ok" if loc in ["scale","secured","quarantine"] else "")
	T(F("body"),17,"Secured" if loc=="secured" else "Held" if loc=="quarantine" else "On scale",1183,320,UI.TEXT,22)
	_key("mover",Rect2(1010,354.1,236,38),"SIGNAL PALLET MOVER",false,step()==4)
	P(F("body"),15,"Load secured after inspection." if loc=="secured" else "Quarantine hold; container remains unopened." if loc=="quarantine" else "The mover's own station carries the crate. This lamp follows it.",1010,402.1,236,18,Color("#b4c3c1"))

func _disposition() -> void:
	var r := Rect2(720,500,540,204)
	module(r,"DISPOSITION")
	module_chip(r,"Accepted" if finished() and not CARGO().quarantined else "Quarantined" if finished() else "Pending","ok" if finished() else "warn" if step()==6 else "")
	push("accept",734,544,120,"ACCEPT","ID, seal and mass match","",step()<6 or (weighed() and absf(float(CARGO().measured_mass)-float(CARGO().manifest_mass))>0.5),false,104,50,16,15,-1,8,false,Color("#23502a"))
	push("quarantine",868,544,123.125,"QUARANT.","Hold it unopened","",step()<6,false,123.125,50,16,15,-1,8,false,Color("#7a1f12"))
	if step()==6: cue(Rect2(740 if absf(float(CARGO().measured_mass)-float(CARGO().manifest_mass))<=0.5 else 866,546,112,80))
	var slip := Rect2(1005.125,544,240.875,128)
	B(slip,{"bg":UI.PAPER_HI,"border":Color("#6f6750")})
	T(F("label",400,0.78),13,"RELEASE SLIP · A12",1017.125,554,Color("#6a5a2a"),16)
	T(F("body"),15,"Measured: %.1f kg (stable)" % float(CARGO().measured_mass) if weighed() else "Measured: —",1017.125,570,UI.INK_2,19.5)
	T(F("body"),15,"Seal: Record gap" if seal_read() and S().phase=="return" else "Seal: Exterior match" if seal_read() else "Seal: —",1017.125,589.5,UI.INK_2,19.5)
	if finished():
		var label := "QUARANTINED" if CARGO().quarantined else "ACCEPTED"
		var stamp_w := tw(F("label",400,2.2),22,label)+30.0
		var ink := Color("#2f7a37",0.85)
		draw_set_transform(Vector2(1232-stamp_w*0.5,636.5),deg_to_rad(-6))
		B(Rect2(-stamp_w*0.5,-21.5,stamp_w,43),{"border":ink,"bw":3})
		T(F("label",400,2.2),22,label,-stamp_w*0.5+15,-14.5,ink,29)
		draw_set_transform(Vector2.ZERO)

func _paper() -> void:
	_material("cargo_procedure_paper",Rect2(20,500,680,204))
	var st := step()
	var cur: Dictionary=STEPS[st] if st<7 else DONE
	artifact_procedure(st,7,str(cur.do),str(cur.why),fb)
	B(Rect2(610.77,515.3,71.23,23.39),{"insets":[[2,2,0,Color("#e9e2c9")],[-2,-2,0,Color("#a39a7b")]]})
	T(F("body",400,0.9),18,"MANUAL",610.77,515.3,UI.INK,23.39,1,71.23)
	hit("manual",Rect2(610.77,515.3,71.23,23.39))

func _key(id: String,r: Rect2,label: String,active: bool,guided: bool) -> void:
	var locked := id=="zero" and (step()<2 or on_scale()) or id=="read" and (not on_scale() or not zeroed()) or id=="mover" and step()<4
	artifact_key(id,r,label,active,locked)
	if guided: cue(r)

func _outline(r: Rect2,color: Color,width: float) -> void:
	draw_rect(Rect2(r.position,Vector2(r.size.x,width)),color)
	draw_rect(Rect2(r.position,Vector2(width,r.size.y)),color)
	draw_rect(Rect2(r.position+Vector2(0,r.size.y-width),Vector2(r.size.x,width)),color)
	draw_rect(Rect2(r.position+Vector2(r.size.x-width,0),Vector2(width,r.size.y)),color)

func _dashed_rect(r: Rect2,color: Color) -> void:
	for x in range(int(r.position.x),int(r.end.x),14):
		R(Rect2(x,r.position.y,8,2),color);R(Rect2(x,r.end.y-2,8,2),color)
	for y in range(int(r.position.y),int(r.end.y),14):
		R(Rect2(r.position.x,y,2,8),color);R(Rect2(r.end.x-2,y,2,8),color)

func on_click(id: String,_event) -> void:
	if id=="esc": close_requested.emit(); return
	var st := step()
	if id=="manual": say("","Tag, seal, zero, reference, mover, read, record. In that order."); return
	if id=="print": say("ok" if weighed() else "warn","Printed: %s %.1f kg STABLE." % [CARGO().id,CARGO().measured_mass] if weighed() else "Nothing stable to print yet."); return
	if id=="mover": say("","Use the pallet mover's own station to transfer the identified load to this scale."); return
	if id=="ref":
		if zeroed() and not on_scale():
			ref_checked=true; S().flags["cargo.reference_checked"]=true
			say("ok","Reference reads 20.0 kg. Scale is true.")
		else: say("warn",NEED[mini(st,6)])
		return
	if id in ["tag","seal","zero","read","accept","quarantine"]:
		var op: String = {"tag":"manifest","seal":"seal","zero":"tare","read":"weigh","accept":"cargo_decide","quarantine":"cargo_decide"}[id]
		if id in ["accept","quarantine"] and st<6 or id=="read" and st<5 or id=="zero" and st<2 or id=="seal" and st<1:
			say("warn",NEED[mini(st,6)]); return
		var selected_value: Variant = null
		if id in ["accept","quarantine"]: selected_value=id
		ctl.act(op,selected_value)
		if step()>st: say("ok",["CARGO-A12: one sealed crate, expected %.1f kg ± 0.5." % float(CARGO().manifest_mass),"Exterior seal checked against the available record.","Scale zeroed; 20 kg reference reads true.","Reference reads 20.0 kg. Scale is true.","Crate on the platform. Waiting for it to settle.","Settled at %.1f kg." % float(CARGO().measured_mass),"Disposition recorded."][mini(st,6)])
		# Failed actions already report their authoritative reason through the owner.
