extends "res://scripts/ui/eito/eito_screen.gd"
## Drawing primitives shared by the Stations 02 ports. Each station owns its
## original composition, graphics and procedure; this only paints its materials.
var ctl
var mats := {}
var fb := {"s":"off","t":""}

func setup(host_layer) -> void: ctl=host_layer
func F(kind: String,w := 400,sp := 0.0) -> Font: return UI.artifact_font(kind,w,sp)
func say(s: String,message: String) -> void: fb={"s":s,"t":message};pop("station:fb")
func _mat(name: String,r: Rect2,graphic := false) -> void:
	var key := name+"_dim" if dim else name
	if not mats.has(key):
		var file := "res://art/ui/eito/stations02/"+("graphics/" if graphic else "materials/")+key+".res"
		if not ResourceLoader.exists(file): file="res://art/ui/eito/stations02/"+("graphics/" if graphic else "materials/")+name+".res"
		mats[key]=load(file)
	if mats[key]!=null: draw_texture_rect(mats[key],r,false)
func _module(name: String,r: Rect2,title: String) -> void:
	_mat(name,r)
	R(Rect2(r.position.x+4,r.position.y+34,r.size.x-8,2),Color("#0f181b"))
	R(Rect2(r.position.x+4,r.position.y+36,r.size.x-8,2),Color("#2e444a"))
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+10,Color("#0a1012"),20)
	T(F("label",400,0.96),16,title,r.position.x+26,r.position.y+8,UI.LABEL,20)
func _keycap(id: String,r: Rect2,label: String,selected := false,locked := false,sz := 18) -> void:
	artifact_key(id,r,label,selected,locked,sz)
func _procedure(material_name: String,stage: int,total: int,todo: String,why: String) -> void:
	_mat(material_name,Rect2(20,500,680,204))
	artifact_procedure(stage,total,todo,why,fb)
func _action(id: String) -> Dictionary:
	for a in ctl.state.actions(ctl.prop_id):
		if str(a.id)==id: return a
	return {}
func _can(id: String) -> bool:
	var a := _action(id)
	if a.is_empty(): say("lock","This operation is not available on the current watch.");return false
	if not bool(a.enabled): say("lock",str(a.get("reason","The current prerequisites are not met.")));return false
	return true
