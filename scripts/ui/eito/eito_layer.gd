extends CanvasLayer
## Hosts one redesigned screen in the game. Keeps the procedure-panel contract the
## walkthrough already uses (action_requested, closed, feedback, close_panel,
## prop_id) so ShipMissionState stays the single owner of equipment truth.
const UI := preload("res://scripts/ui/eito/eito_ui.gd")
const SCREENS := {
	"power": preload("res://scripts/ui/eito/power_panel.gd"),
	"irrigation": preload("res://scripts/ui/eito/irrigation_panel.gd"),
	"records": preload("res://scripts/ui/eito/crew_records_panel.gd"),
	"cargo_scale": preload("res://scripts/ui/eito/cargo_scale_panel.gd"),
	"pallet_mover": preload("res://scripts/ui/eito/pallet_mover_panel.gd"),
	"cylinder_rack": preload("res://scripts/ui/eito/cylinder_rack_panel.gd"),
	"maintenance_trolley": preload("res://scripts/ui/eito/maintenance_trolley_panel.gd"),
	"air_duct": preload("res://scripts/ui/eito/air_duct_panel.gd"),
	"air_filter": preload("res://scripts/ui/eito/air_filter_panel.gd"),
	"co2_scrubber": preload("res://scripts/ui/eito/co2_scrubber_panel.gd"),
	"oxygen_rack": preload("res://scripts/ui/eito/oxygen_rack_panel.gd"),
	"supply_stores": preload("res://scripts/ui/eito/supply_stores_panel.gd"),
	"turbine": preload("res://scripts/ui/eito/turbine_panel.gd"),
	"valve_manifold": preload("res://scripts/ui/eito/valve_manifold_panel.gd"),
	"coolant_pump": preload("res://scripts/ui/eito/coolant_pump_panel.gd"),
	"nutrient_pump_check": preload("res://scripts/ui/eito/nutrient_pump_check_panel.gd"),
	"seedling_rack_check": preload("res://scripts/ui/eito/seedling_rack_check_panel.gd"),
	"helm": preload("res://scripts/ui/eito/helm_panel.gd"),
	"communications": preload("res://scripts/ui/eito/communications_panel.gd"),
	"planning_table": preload("res://scripts/ui/eito/planning_table_panel.gd"),
}

signal action_requested(action_id: String, value: Variant)
signal legacy_receipt_recorded(task_id: String)
signal save_requested
signal load_requested
signal closed

var state: Object
var prop_id := ""
var display_title := ""
var kind := ""
var story_mode := false
var story_objective := ""
var save_path := ""
var screen: Control
var _closing := false
var _bg: Control

static func kind_for(model: Object, id: String) -> String:
	if model == null: return ""
	if id == "cargo.scale": return "cargo_scale"
	if id == "cargo.mover": return "pallet_mover"
	if id == "cargo.cylinders": return "cylinder_rack"
	if id == "cargo.trolley": return "maintenance_trolley"
	if id == "life.duct": return "air_duct"
	if id == "life.filter": return "air_filter"
	if id == "life.scrubber": return "co2_scrubber"
	if id == "life.oxygen": return "oxygen_rack"
	if id in ["quarters.drawer.1", "quarters.drawer.2", "quarters.wardrobe"]: return "supply_stores"
	if id.begins_with("engine.turbine."): return "turbine"
	if id.begins_with("engine.valve."): return "valve_manifold"
	if id.begins_with("engine.pump."): return "coolant_pump"
	if id == "hydro.pump": return "nutrient_pump_check"
	if id == "hydro.seedlings": return "seedling_rack_check"
	if id in ["bridge.helm","bridge.flight.upper","bridge.flight.lower"]: return "helm"
	if id.begins_with("bridge.comms."): return "communications"
	if id == "bridge.planning": return "planning_table"
	if model.phase != "outbound": return ""
	if id.begins_with("power."): return "power"
	if id == "hydro.console": return "irrigation"
	if id in ["quarters.desk", "quarters.table"]: return "records"
	return ""

func setup(model: Object, id: String, title: String, screen_kind := "") -> void:
	state = model; prop_id = id; display_title = title
	kind = screen_kind if not screen_kind.is_empty() else kind_for(model, id)

func _ready() -> void:
	layer = 21
	_bg = _Backdrop.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)
	screen = SCREENS[kind].new()
	screen.name = kind.capitalize() + "Screen"
	add_child(screen)
	screen.setup(self)
	screen.close_requested.connect(close_panel)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(screen): return
	var vs := get_viewport().get_visible_rect().size
	# The design is a 1280x720 stage: centred on wider windows, scaled down
	# uniformly only if the logical viewport is ever smaller than that.
	var s := minf(1.0, minf(vs.x / 1280.0, vs.y / 720.0))
	screen.scale = Vector2(s, s)
	screen.position = ((vs - Vector2(1280, 720) * s) * 0.5).floor()
	_bg.stage_origin = screen.position

## Sends an operation to the walkthrough owner. Without an owner (previews and
## tests) the model is driven directly.
func act(action_id: String, value: Variant = null) -> void:
	if action_requested.get_connections().is_empty():
		var result: Dictionary = state.act(prop_id, action_id, value)
		if not result.get("ok", false): feedback(str(result.get("message", "")), false)
	else:
		action_requested.emit(action_id, value)

func feedback(message: String, success := true) -> void:
	if is_instance_valid(screen) and screen.has_method("external_feedback"):
		screen.external_feedback(message,success);return
	if success or not is_instance_valid(screen) or not screen.has_method("say"): return
	var first := message.strip_edges().get_slice("\n", 0)
	screen.say("lock", first)

func has_tool() -> bool:
	return state != null and state.inventory != null and int(state.inventory.inventory_count(&"engineering_multitool")) > 0

func show_comms() -> void:
	if is_instance_valid(screen) and screen.has_method("show_comms"): screen.show_comms()

func _schedule_rebuild() -> void:
	pass

func close_panel() -> void:
	if _closing: return
	_closing = true
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if _closing or not is_instance_valid(screen): return
	if event is InputEventKey and screen.key(event):
		get_viewport().set_input_as_handled()

## Extends the ".screen" bulkhead stripes beyond the 1280x720 frame on wider windows.
class _Backdrop extends Control:
	var stage_origin := Vector2.ZERO
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, UI.BULK)
		var bottom := stage_origin.y + 720.0
		var y := bottom + ceilf((size.y - bottom) / 50.0) * 50.0
		while y > 0.0:
			draw_rect(Rect2(0, y - 46, size.x, 46), Color("#0e171b"))
			draw_rect(Rect2(0, y - 48, size.x, 2), Color("#0a1215"))
			draw_rect(Rect2(0, y - 50, size.x, 2), Color(21/255.0, 34/255.0, 39/255.0, 0x28/255.0))
			y -= 50.0
		draw_rect(r, Color(0, 0, 0, 0.2))
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED: queue_redraw()
