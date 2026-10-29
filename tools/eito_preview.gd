extends SceneTree
## Renders redesigned screens in given states for visual comparison with the design.
## godot --path . --script res://tools/eito_preview.gd -- <kind> <preset> <out.png> [seconds]
const LAYER := preload("res://scripts/ui/eito/eito_layer.gd")
const STATE := preload("res://scripts/ship/ship_mission_state.gd")

class Inv extends RefCounted:
	var items := {"engineering_multitool":1}
	func inventory_count(i: StringName) -> int: return int(items.get(str(i), 0))
	func inventory_take(i: StringName, n := 1) -> bool:
		if inventory_count(i) < n: return false
		items[str(i)] -= n; return true
	func inventory_put(i: StringName, n := 1) -> bool:
		items[str(i)] = inventory_count(i) + n; return true

var inv := Inv.new()
var state
var layer
var frames := 0
var wait := 1.0
var elapsed := 0.0
var out := ""
var script_steps := []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var kind: String = args[0] if args.size() > 0 else "power"
	var preset: String = args[1] if args.size() > 1 else "start"
	out = args[2] if args.size() > 2 else "/tmp/eito.png"
	wait = float(args[3]) if args.size() > 3 else 1.0
	state = STATE.new(); state.configure(inv); state.configure_first_watch()
	state.flags.assigned = true
	state.authorized_work_orders = PackedStringArray(["crew", "hydro.inspect", "power", "hydro"])
	if kind == "dialogue":
		_dialogue(preset); return
	var prop: String = {"power":"power.breaker", "irrigation":"hydro.console", "records":"quarters.desk"}.get(kind, "power.breaker")
	_apply(kind, preset, prop)
	layer = LAYER.new()
	layer.setup(state, prop, "Preview", kind)
	layer.story_mode = true
	get_root().add_child(layer)

var dlg
func _dialogue(preset: String) -> void:
	var bg := ColorRect.new(); bg.color = Color("#0b1417"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cl := CanvasLayer.new(); cl.add_child(bg); get_root().add_child(cl)
	dlg = preload("res://scripts/ui/crew_dialogue.gd").new()
	get_root().add_child(dlg)
	var lines: Array[String] = []
	match preset:
		"maya":
			lines = ["Thura, it's Maya. The watch is yours from now. Start with the crew records."]
			dlg.start_dialogue(lines, false, {"id":"maya", "speaker":"MAYA CHEN / CDR / TERMINAL TEXT", "objective":"Accept Maya's watch", "choices":[{"id":"a","label":"Accept the watch"},{"id":"b","label":"Anything I should check first?"}]})
		"maya_more":
			lines = ["Thura, it's Maya.", "Second line."]
			dlg.start_dialogue(lines, false, {"id":"maya", "speaker":"MAYA CHEN / CDR / TERMINAL TEXT", "objective":"Accept Maya's watch"})
		"amara":
			lines = ["Thura. Glad you're on watch. The beds aren't getting enough water."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."},{"id":"b","label":"What have you checked so far?"}]})
		"amara_typing":
			lines = ["Thura. Glad you're on watch. The beds aren't getting enough water."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."}]})
		"amara_echo":
			lines = ["Thura. Glad you're on watch."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll look at the irrigation."}]})
			script_steps = [[1.0, "pick", 0]]
		"amara_long":
			lines = ["Delivery is low. The console by the west wall has the reservoir chemistry, pump capacity and flow readings. Have a look, then tell me what you find."]
			dlg.start_dialogue(lines, false, {"id":"amara", "speaker":"AMARA OKOYE / MED / HYDROPONICS", "objective":"Meet Amara", "choices":[{"id":"a","label":"I'll check the readings"},{"id":"b","label":"Is the pump failing?"},{"id":"c","label":"A moment first"}]})
		"ribbon":
			dlg.flash_objective("Restore irrigation")

func A(prop: String, action: String, value = null) -> void:
	var r: Dictionary = state.act(prop, action, value)
	if not r.ok: push_warning("%s %s -> %s" % [prop, action, r.message])

func _apply(kind: String, preset: String, prop: String) -> void:
	if kind == "irrigation": _apply_irr(preset, prop)
	if kind == "records":
		match preset:
			"wrong": script_steps = [[2.0, "click", "slip:0"]]
			"right": script_steps = [[2.0, "click", "slip:1"]]
	if kind == "power":
		match preset:
			"interlocked":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":false,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(393-390)*100.0/20.0,(38+60)*100.0/120.0],"nutrient_rotations":[]}
			"working":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":false,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(400-390)*100.0/20.0,(2+60)*100.0/120.0],"nutrient_rotations":[]}
				script_steps = [[0.2, "click", "sync"]]
			"verified":
				A(prop, "observe"); A(prop, "diagnose", "cell"); A(prop, "isolate"); A(prop, "allocation", "repair"); A(prop, "sync"); A(prop, "restore")
				state.legacy_progress["auxiliary_power"] = {"task":"auxiliary_power","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[(231-200)*100.0/60.0,(400-390)*100.0/20.0,(1+60)*100.0/120.0],"nutrient_rotations":[]}
				state.verification.power = 4.0; A(prop, "verify")
				script_steps = [[0.05, "comms", ""]]

func _power_on() -> void:
	state.systems.power.calibrated = true; state.systems.power.restored = true; state.systems.power.isolated = false
	state.systems.power.essential = 65; state.systems.power.science = 15; state.systems.power.reserve = 20

func _apply_irr(preset: String, prop: String) -> void:
	match preset:
		"interlocked":
			A(prop, "observe"); A(prop, "diagnose", "restriction")
		"power":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on()
		"working":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on(); A(prop, "isolate"); A(prop, "align")
			state.legacy_progress["nutrient_flow"] = {"task":"nutrient_flow","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[],"nutrient_rotations":[2,5,3]}
			script_steps = [[0.2, "click", "sv"]]
		"verified":
			A(prop, "observe"); A(prop, "diagnose", "restriction"); _power_on(); A(prop, "isolate"); A(prop, "align")
			state.legacy_progress["nutrient_flow"] = {"task":"nutrient_flow","complete":true,"filter_stage":0,"filter_rotation":0,"filter_airflow":0.0,"power":[],"nutrient_rotations":[2,5,3]}
			A(prop, "restore"); state.verification.hydro = 4.0; A(prop, "verify")

func _process(delta: float) -> bool:
	frames += 1
	elapsed += delta
	if state != null and dlg == null: state.tick(delta)
	while not script_steps.is_empty() and elapsed >= script_steps[0][0]:
		var s: Array = script_steps.pop_front()
		match s[1]:
			"click": layer.screen.on_click(s[2], null)
			"comms": layer.show_comms()
			"pick": dlg.pick(s[2])
	if elapsed >= wait and frames > 5:
		var img := get_root().get_texture().get_image()
		img.save_png(out)
		print("saved ", out, " ", img.get_size())
		return true
	return false
