class_name WalkHud
extends CanvasLayer

signal modal_state_changed(is_open: bool)
signal inventory_changed
signal mission_scenario_requested(context: String)

const PIXEL_THEME := preload("res://themes/ship_pixel_theme.tres")
const EC := preload("res://scripts/ui/eito/eito_controls.gd")
const EUI := preload("res://scripts/ui/eito/eito_ui.gd")
const ESTYLE := preload("res://scripts/ui/eito/eito_style.gd")
const MAP_CONTENT_VISIBLE := false
const THURA_ATLAS := preload("res://art/characters/runtime/thura_walk_4dir.png")
const CHARACTER_FRAME_SIZE := Vector2(313.5, 313.5)

# Design palette (eito_ui): amber warn, bone text, label grey-green, live cyan,
# ok green; surfaces are drawn by EitoStyle materials.
const GOLD := Color("#f0b23a")
const PALE := Color("#e6e1d2")
const MUTED := Color("#a9c4c2")
const CYAN := Color("#62d0f0")
const ORANGE := Color("#f0b23a")
const GREEN := Color("#5fd067")
const SURFACE := Color("#0a1114")
const SURFACE_RAISED := Color("#101a1e")
const SURFACE_HOVER := Color("#1b292e")
const EDGE := Color("#2a3b40")
const EDGE_SOFT := Color("#1b292e")

const ITEM_DATA := {
	&"filter_cartridge":{"name":"FILTER-A / sealed airflow cartridge","short":"FILTER-A","color":CYAN,"equip_slot":&""},
	&"scrubber_media":{"name":"SCRUB-A / CO2 scrubber medium","short":"SCRUB-A","color":GREEN,"equip_slot":&""},
	&"coolant_charge":{"name":"COOL-02 / sealed service coolant","short":"COOL-02","color":CYAN,"equip_slot":&""},
	&"nutrient_buffer":{"name":"BUFFER-A / nutrient dilution dose","short":"BUFFER","color":GREEN,"equip_slot":&""},
	&"oxygen_reserve":{"name":"O2-01 / oxygen reserve cylinder","short":"O2-01","color":PALE,"equip_slot":&""},
	&"inert_purge":{"name":"N2-03 / inert purge cylinder","short":"N2-03","color":MUTED,"equip_slot":&""},
	&"captains_revolver": {
		"name": "Captain's Revolver", "short": "REVOLVER", "color": ORANGE, "equip_slot": &"tool",
		"texture": preload("res://art/tools/captains_revolver.png"), "icon_region": Rect2(35.0, 292.0, 960.0, 880.0),
	},
	&"industrial_plasma_cutter": {
		"name": "Industrial Plasma Cutter", "short": "PLASMA", "color": GOLD, "equip_slot": &"tool",
		"texture": preload("res://art/tools/industrial_plasma_cutter.png"), "icon_region": Rect2(95.0, 340.0, 840.0, 650.0),
	},
	&"suit_flashlight": {
		"name": "Suit Flashlight", "short": "LIGHT", "color": PALE, "equip_slot": &"suit",
		"texture": preload("res://art/tools/suit_flashlight.png"), "icon_region": Rect2(65.0, 360.0, 900.0, 620.0),
	},
	&"mineral_survey_scanner": {
		"name": "Mineral Survey Scanner", "short": "SCANNER", "color": CYAN, "equip_slot": &"tool",
		"texture": preload("res://art/tools/mineral_survey_scanner.png"), "icon_region": Rect2(90.0, 232.0, 850.0, 940.0),
	},
	&"engineering_multitool": {
		"name": "Engineering Multitool", "short": "MULTI", "color": GOLD, "equip_slot": &"tool",
		"texture": preload("res://art/tools/engineering_multitool.png"), "icon_region": Rect2(45.0, 335.0, 930.0, 790.0),
	},
	&"survey_beacon": {
		"name": "Survey Beacon", "short": "BEACON", "color": GOLD, "equip_slot": &"tool",
		"texture": preload("res://art/tools/survey_beacon.png"), "icon_region": Rect2(100.0, 350.0, 830.0, 780.0),
	},
	&"emergency_flare": {
		"name": "Emergency Flare", "short": "FLARE", "color": ORANGE, "equip_slot": &"tool",
		"texture": preload("res://art/tools/emergency_flare.png"), "icon_region": Rect2(220.0, 225.0, 740.0, 940.0),
	},
	&"pressure_sealant": {
		"name": "Pressure Sealant", "short": "SEALANT", "color": CYAN, "equip_slot": &"tool",
		"texture": preload("res://art/tools/pressure_sealant.png"), "icon_region": Rect2(150.0, 390.0, 740.0, 780.0),
	},
	&"medical_injector": {
		"name": "Medical Injector", "short": "MEDICAL", "color": GREEN, "equip_slot": &"tool",
		"texture": preload("res://art/tools/medical_injector.png"), "icon_region": Rect2(180.0, 250.0, 760.0, 925.0),
	},
	&"electrical_discharge_tool": {
		"name": "Electrical Discharge Tool", "short": "DISCHARGE", "color": CYAN, "equip_slot": &"tool",
		"texture": preload("res://art/tools/electrical_discharge_tool.png"), "icon_region": Rect2(100.0, 410.0, 860.0, 710.0),
	},
}

const EQUIPMENT_SLOTS: Array[StringName] = [&"head", &"suit", &"pack", &"tool"]
const EQUIPMENT_LABELS := [&"HEAD", &"SUIT", &"PACK", &"TOOL"]
const HOTBAR_KEY_CODES: Array[int] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9]


class PixelIcon extends Control:
	const ICON_PALE := Color(0.96, 0.985, 1.0)
	var icon_kind: StringName = &""
	var tint := Color(0.36, 0.9, 1.0)

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var unit := maxf(1, floorf(minf(size.x, size.y) / 24.0))
		var origin := ((size - Vector2.ONE * unit * 24.0) * 0.5).floor()
		match icon_kind:
			&"map":
				_block(origin, unit, 2, 5, 20, 14, tint.darkened(0.45), false)
				_block(origin, unit, 4, 7, 4, 10, tint)
				_block(origin, unit, 10, 6, 4, 12, tint.darkened(0.25))
				_block(origin, unit, 16, 7, 4, 10, tint)
				_block(origin, unit, 8, 5, 2, 14, ICON_PALE)
				_block(origin, unit, 14, 5, 2, 14, ICON_PALE)
			&"inventory":
				_block(origin, unit, 8, 3, 8, 3, tint, false)
				_block(origin, unit, 5, 6, 14, 15, tint.darkened(0.38), false)
				_block(origin, unit, 7, 8, 10, 11, tint)
				_block(origin, unit, 10, 8, 4, 2, ICON_PALE)
			&"settings":
				_block(origin, unit, 9, 3, 6, 4, tint)
				_block(origin, unit, 9, 17, 6, 4, tint)
				_block(origin, unit, 3, 9, 4, 6, tint)
				_block(origin, unit, 17, 9, 4, 6, tint)
				_block(origin, unit, 5, 5, 4, 4, tint)
				_block(origin, unit, 15, 5, 4, 4, tint)
				_block(origin, unit, 5, 15, 4, 4, tint)
				_block(origin, unit, 15, 15, 4, 4, tint)
				_block(origin, unit, 8, 8, 8, 8, ICON_PALE, false)
				_block(origin, unit, 10, 10, 4, 4, tint.darkened(0.3))
			&"dev":
				_block(origin, unit, 3, 4, 18, 16, tint.darkened(0.42), false)
				_block(origin, unit, 5, 6, 14, 12, tint.darkened(0.65))
				_block(origin, unit, 11, 6, 4, 4, ICON_PALE)
				_block(origin, unit, 9, 10, 6, 3, tint)
				_block(origin, unit, 10, 13, 4, 5, ICON_PALE)
	func _block(origin: Vector2, unit: float, x: int, y: int, width: int, height: int, color: Color, filled := true) -> void:
		var rect := Rect2(origin + Vector2(float(x), float(y)) * unit, Vector2(float(width), float(height)) * unit)
		if filled:
			draw_rect(rect, color, true)
		else:
			draw_rect(rect, color, false, 1.0, false)


class MapDot extends Control:
	var dot_color := Color(0.36, 0.9, 1.0)
	var _pulse := 0.0

	func _process(delta: float) -> void:
		_pulse = fposmod(_pulse + delta * 3.0, TAU)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var sweep := (sin(_pulse) + 1.0) * 0.5
		draw_arc(center, 7.0 + sweep * 5.0, 0.0, TAU, 24, Color(dot_color.r, dot_color.g, dot_color.b, 0.35 * (1.0 - sweep)), 1.5, false)
		draw_circle(center, 6.0, Color(0.015, 0.035, 0.045, 0.96))
		draw_circle(center, 4.0, dot_color)
		draw_circle(center, 1.8, Color(0.96, 0.985, 1.0))


## Chart glass for the ship map: phosphor grid and a standby message while the
## deck schematic stays disabled (markers keep their data underneath).
class MapScreen extends Control:
	var _now := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _process(delta: float) -> void:
		_now += delta; queue_redraw()
	func _draw() -> void:
		var faint := EUI.PHOS_FAINT
		var x := fposmod(size.x * 0.5, 24.0)
		while x < size.x:
			var major := is_zero_approx(fposmod(x - size.x * 0.5, 96.0))
			draw_rect(Rect2(roundf(x), 0, 1, size.y), faint if not major else Color(faint, 1.0).lightened(0.12))
			x += 24.0
		var y := fposmod(size.y * 0.5, 24.0)
		while y < size.y:
			var major := is_zero_approx(fposmod(y - size.y * 0.5, 96.0))
			draw_rect(Rect2(0, roundf(y), size.x, 1), faint if not major else Color(faint, 1.0).lightened(0.12))
			y += 24.0
		# sweep line
		var sy := fposmod(_now * 60.0, size.y)
		draw_rect(Rect2(0, roundf(sy), size.x, 2), Color(EUI.PHOS, 0.10))
		var c := size * 0.5
		var box := Rect2(c - Vector2(230, 52), Vector2(460, 104))
		EUI.box(self, box, {"notch":true, "bg":Color(0.016, 0.063, 0.047, 0.92), "border":EUI.PHOS_DIM})
		var fl := EUI.font("label", 400, 1.28)
		EUI.text(self, fl, 16, "DECK CHART NOT LOADED", box.position.x, box.position.y + 18, EUI.PHOS, 24, 1, box.size.x)
		EUI.text(self, EUI.font("body"), 16, "Survey schematic awaiting approval", box.position.x, box.position.y + 50, EUI.PHOS_DIM, 22, 1, box.size.x)
		if fmod(_now, 1.0) < 0.5:
			draw_rect(Rect2(box.position.x + box.size.x * 0.5 - 6, box.position.y + 80, 12, 4), EUI.PHOS)


class MapPin extends Control:
	var pin_color := Color(1.0, 0.68, 0.32)
	var is_complete := false
	var _pulse := 0.0

	func _process(delta: float) -> void:
		if not is_complete:
			_pulse = fposmod(_pulse + delta * 3.5, TAU)
			queue_redraw()

	func _draw() -> void:
		var center := Vector2(10.0, 10.0)
		if not is_complete:
			var wave := (sin(_pulse) + 1.0) * 0.5
			draw_arc(center, 9.0 + wave * 4.0, 0.0, TAU, 20, Color(pin_color.r, pin_color.g, pin_color.b, 0.4 * (1.0 - wave)), 1.5, false)
		var outline := PackedVector2Array([
			Vector2(10.0, 26.0), Vector2(4.0, 17.0), Vector2(2.0, 12.0),
			Vector2(2.0, 8.0), Vector2(4.0, 4.0), Vector2(8.0, 1.0),
			Vector2(12.0, 1.0), Vector2(16.0, 4.0), Vector2(18.0, 8.0),
			Vector2(18.0, 12.0), Vector2(16.0, 17.0),
		])
		draw_colored_polygon(outline, Color(0.012, 0.032, 0.042, 1.0))
		var fill := PackedVector2Array([
			Vector2(10.0, 23.0), Vector2(5.5, 15.5), Vector2(3.5, 11.0),
			Vector2(3.5, 8.0), Vector2(5.0, 5.0), Vector2(8.5, 2.5),
			Vector2(11.5, 2.5), Vector2(15.0, 5.0), Vector2(16.5, 8.0),
			Vector2(16.5, 11.0), Vector2(14.5, 15.5),
		])
		draw_colored_polygon(fill, pin_color)
		draw_circle(center, 4.5, Color(0.012, 0.032, 0.042, 1.0))
		if is_complete:
			draw_circle(center, 2.5, Color(0.96, 0.985, 1.0))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(8.5, 14.0), "!", HORIZONTAL_ALIGNMENT_CENTER, -1.0, 11, Color(0.96, 0.985, 1.0))


class TaskLocationMarker extends Control:
	const MARKER_SIZE := Vector2(40.0, 54.0)
	const DARK := Color(0.012, 0.032, 0.042, 1.0)
	const ACCENT := Color(1.0, 0.68, 0.32, 1.0)
	const PALE := Color(0.96, 0.985, 1.0, 1.0)
	var _pulse_phase := 0.0

	func _ready() -> void:
		custom_minimum_size = MARKER_SIZE
		size = MARKER_SIZE
		theme = PIXEL_THEME
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		_pulse_phase = fposmod(_pulse_phase + delta * 2.2, TAU)
		queue_redraw()

	func _draw() -> void:
		# Notched chip with a pulsing warn lamp, corner cue brackets and a stem.
		var bob := roundf(sin(_pulse_phase) * 1.5)
		var chip := Rect2(6, 2 + bob, 28, 28)
		EUI.box(self, chip, {"notch":true, "bg":Color("#0a1114"), "border":EUI.WARN})
		var a := 0.55 + 0.45 * (sin(_pulse_phase * 2.0) * 0.5 + 0.5)
		draw_texture_rect(EUI.tex("g_warn"), Rect2(chip.position + Vector2(-1, -1), Vector2(30, 30)), false, Color(1, 1, 1, a))
		draw_texture_rect(EUI.tex("l_warn"), Rect2(chip.position + Vector2(5, 5), Vector2(18, 18)), false)
		var g := chip.grow(3 + roundf(1.5 + sin(_pulse_phase * 2.0) * 1.5))
		for c in [[g.position, Vector2(1, 1)], [Vector2(g.end.x, g.position.y), Vector2(-1, 1)], [Vector2(g.position.x, g.end.y), Vector2(1, -1)], [g.end, Vector2(-1, -1)]]:
			var p: Vector2 = c[0]; var d: Vector2 = c[1]
			draw_rect(Rect2(p.x if d.x > 0 else p.x - 7, p.y if d.y > 0 else p.y - 2, 7, 2), EUI.CUE)
			draw_rect(Rect2(p.x if d.x > 0 else p.x - 2, p.y if d.y > 0 else p.y - 7, 2, 7), EUI.CUE)
		draw_rect(Rect2(19, chip.end.y + 2, 2, MARKER_SIZE.y - chip.end.y - 6), EUI.WARN)
		draw_rect(Rect2(17, MARKER_SIZE.y - 4, 6, 2), EUI.WARN)


class InventoryCell extends PanelContainer:
	const CELL_GOLD := Color("#fff2b8")
	const CELL_PALE := Color("#e6e1d2")
	const CELL_MUTED := Color("#6f8a8c")
	const CELL_SURFACE := Color("#081013")
	const CELL_EDGE := Color("#05090b")
	signal activated(slot_kind: StringName, slot_index: int)
	signal drop_requested(target_kind: StringName, target_index: int, data: Dictionary)

	var slot_kind: StringName = &""
	var slot_index := 0
	var item_id: StringName = &""
	var short_label := ""
	var slot_label := ""
	var icon_color := Color(0.36, 0.9, 1.0)
	var is_selected := false
	var item_texture: Texture2D
	var icon_size := 27.0
	var _badge: Label
	var _icon: TextureRect
	var _name: Label
	var _hovered := false

	func configure(kind: StringName, index: int, item: StringName, item_short: String, tint: Color, selected: bool, label_override := "", texture: Texture2D = null) -> void:
		slot_kind = kind
		slot_index = index
		item_id = item
		short_label = item_short
		icon_color = tint
		is_selected = selected
		slot_label = label_override
		item_texture = texture
		var available_width := maxf(custom_minimum_size.x - 12.0, 20.0)
		var available_height := maxf(custom_minimum_size.y - 25.0, 20.0)
		icon_size = minf(42.0, minf(available_width, available_height))

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func(): _hovered = true; _refresh())
		mouse_exited.connect(func(): _hovered = false; _refresh())
		resized.connect(_resize_icon)
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 0)
		add_child(stack)
		_badge = Label.new()
		_badge.theme_type_variation = &"EitoTag"
		_badge.add_theme_font_size_override("font_size", 12)
		_badge.add_theme_color_override("font_color", CELL_MUTED)
		_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stack.add_child(_badge)
		var icon_center := CenterContainer.new()
		icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon = TextureRect.new()
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.custom_minimum_size = Vector2.ONE * icon_size
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_center.add_child(_icon)
		stack.add_child(icon_center)
		_name = Label.new()
		_name.theme_type_variation = &"EitoTag"
		_name.add_theme_font_size_override("font_size", 12)
		_name.add_theme_color_override("font_color", CELL_PALE)
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name.clip_text = true
		_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		stack.add_child(_name)
		_refresh()
		_resize_icon.call_deferred()

	func _resize_icon() -> void:
		if is_instance_valid(_icon):
			var limit := 40.0 if slot_kind == &"hotbar" else 64.0
			_icon.custom_minimum_size = Vector2.ONE * maxf(20, minf(limit, minf(size.x - 16, size.y - 32)))

	func set_item(item: StringName, item_short: String, tint: Color, selected: bool, texture: Texture2D = null) -> void:
		item_id = item
		short_label = item_short
		icon_color = tint
		is_selected = selected
		item_texture = texture
		_refresh()

	func _refresh() -> void:
		var style_name := "selected" if is_selected else "hover" if _hovered else "normal"
		add_theme_stylebox_override("panel", get_theme_stylebox(style_name, "InventorySlot"))
		if _badge == null:
			return
		_badge.text = slot_label if not slot_label.is_empty() else str(slot_index + 1) if slot_kind == &"hotbar" else "%02d" % (slot_index + 1)
		_badge.add_theme_color_override("font_color", CELL_GOLD if is_selected else CELL_MUTED)
		var has_item := item_id != &""
		_icon.visible = has_item
		_icon.texture = item_texture if has_item else null
		_name.text = short_label if has_item else ("EMPTY" if slot_kind == &"equipment" else "")
		_name.add_theme_color_override("font_color", icon_color if has_item else CELL_MUTED)
		tooltip_text = item_id.replace("_", " ").capitalize() if has_item else "Empty slot"

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			activated.emit(slot_kind, slot_index)
			accept_event()

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if item_id == &"":
			return null
		var preview := PanelContainer.new()
		preview.custom_minimum_size = Vector2(156.0, 40.0)
		preview.theme = PIXEL_THEME
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.add_theme_stylebox_override("panel", ESTYLE.make("chip", 8))
		var preview_label := Label.new()
		preview_label.theme_type_variation = &"EitoTag"
		preview_label.text = short_label
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.add_theme_font_size_override("font_size", 12)
		preview_label.add_theme_color_override("font_color", CELL_PALE)
		preview.add_child(preview_label)
		set_drag_preview(preview)
		return {"source_kind": slot_kind, "source_index": slot_index, "item_id": item_id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return data is Dictionary and StringName(data.get("item_id", &"")) != &""

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if data is Dictionary:
			drop_requested.emit(slot_kind, slot_index, data)


var _player: ShipPlayer
var _task_entries: Array[Dictionary] = []
var _task_completed: Dictionary = {}
var _map_world_origin := Vector2.ZERO
var _map_world_size := Vector2(1774.0, 887.0)

var _root: Control
var _world_task_marker_layer: Control
var _mission_panel: PanelContainer
var _story_tracker_enabled := false
var _mission_stack: VBoxContainer
var _mission_progress_label: Label
var _mission_progress_bar: ProgressBar
var _mission_rows: Dictionary = {}
var _cargo_count_label: Label
var _context_prompt: PanelContainer
var _context_label: Label
var _hotbar_items: Array[StringName] = [&"", &"", &"", &"", &"", &"", &"", &"", &""]
var _storage_items: Array[StringName] = []
var _equipment_items: Dictionary = {&"head": &"", &"suit": &"suit_flashlight", &"pack": &"", &"tool": &"mineral_survey_scanner"}
var _item_icon_cache: Dictionary = {}
var _selected_hotbar_index := 0
var _hotbar_slots: Array = []
var _storage_cells: Array = []
var _equipment_cells: Array = []
var _inventory_hotbar_cells: Array = []
var _active_overlay: StringName = &""
var _overlay_nodes: Dictionary = {}
var _map_surface: Control
var _map_player_marker: Control
var _map_task_markers: Dictionary = {}
var _world_task_markers: Dictionary = {}
var _volume_slider: HSlider
var _volume_label: Label
var _walking_visible := true
var _modal_frames: Dictionary = {}
var _operator_panel: PanelContainer
var _cargo_grid: GridContainer
var _previous_focus: Control
var _resize_queued := false
var _dev_panel: PanelContainer
var _dev_current_room_label: Label
var _dev_room_name_label: Label
var _dev_flicker_here_btn: Button
var _dev_flicker_all_btn: Button
var _dev_style_btn: Button
var _dev_speed_btn: Button
var _dev_room_flicker_btn: Button
var _dev_force_lights_btn: Button
var _dev_selected_room_index := 0
const DEV_FLICKER_STYLES: Array[StringName] = [&"erratic", &"strobe", &"brownout", &"pulse"]
const DEV_FLICKER_SPEEDS: Array[float] = [0.5, 1.0, 1.5, 2.5]


func setup(player: ShipPlayer, task_entries: Array[Dictionary], map_world_origin: Vector2, map_world_size: Vector2) -> void:
	_player = player
	_map_world_origin = map_world_origin
	_map_world_size = map_world_size
	_task_entries.clear()
	_task_completed.clear()
	for entry in task_entries:
		_task_entries.append(entry.duplicate(true))
		_task_completed[entry["id"]] = false
	_storage_items.resize(27)
	_storage_items.fill(&"")
	_storage_items[0] = &"captains_revolver"
	_storage_items[1] = &"industrial_plasma_cutter"
	_storage_items[2] = &"engineering_multitool"
	_storage_items[3] = &"survey_beacon"
	_storage_items[4] = &"emergency_flare"
	_storage_items[5] = &"pressure_sealant"
	_storage_items[6] = &"medical_injector"
	_storage_items[7] = &"electrical_discharge_tool"


func _ready() -> void:
	layer = 10
	_build_ui()
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	get_viewport().size_changed.connect(_queue_resize)
	_queue_resize()


func _process(_delta: float) -> void:
	_update_world_task_markers()
	if _active_overlay == &"map":
		_update_map_markers()
	if is_instance_valid(_dev_panel) and _dev_panel.visible:
		_refresh_dev_menu()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.name = "HUD"
	_root.theme = PIXEL_THEME
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_world_task_marker_layer = Control.new()
	_world_task_marker_layer.name = "WorldTaskMarkers"
	_world_task_marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_task_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_world_task_marker_layer)
	_build_mission_panel()
	_build_top_controls()
	_build_dev_menu_panel()
	_build_context_prompt()
	_build_hotbar()
	_create_map_overlay()
	for entry in _task_entries:
		_add_world_task_marker(entry)
	_create_inventory_overlay()
	_create_settings_overlay()
	_refresh_mission_panel()
	_refresh_inventory_cells()
	_refresh_hotbar()


func _build_mission_panel() -> void:
	# Watch log plate: stamped header strip, mission count and segmented progress,
	# then one row per work order.
	var panel := EC.Plate.new("WATCH LOG", "module", true, 16.0)
	_mission_panel = panel
	panel.name = "MissionTracker"
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 18.0
	panel.offset_top = 14.0
	panel.offset_right = 378.0
	panel.offset_bottom = 214.0 + maxi(_task_entries.size() - 3, 0) * 32.0
	panel.minimum_size_changed.connect(func():
		if _story_tracker_enabled: _fit_story_tracker.call_deferred())
	_root.add_child(panel)
	var stack := VBoxContainer.new()
	_mission_stack = stack
	stack.add_theme_constant_override("separation", 6)
	panel.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	heading.add_child(_tag("TASKS COMPLETED", 12, MUTED))
	heading.add_spacer(false)
	_mission_progress_label = _label("00 / 02  (0%)", 16, EUI.PHOS)
	heading.add_child(_mission_progress_label)
	stack.add_child(heading)
	_mission_progress_bar = ProgressBar.new()
	_mission_progress_bar.min_value = 0.0
	_mission_progress_bar.max_value = maxi(_task_entries.size(), 1)
	_mission_progress_bar.show_percentage = false
	_mission_progress_bar.custom_minimum_size.y = 14.0
	stack.add_child(_mission_progress_bar)
	var sub_heading := _tag("ACTIVE WORK ORDERS", 12, MUTED)
	stack.add_child(sub_heading)
	for entry in _task_entries:
		_add_mission_row(entry)


func _add_mission_row(entry: Dictionary) -> void:
	if not is_instance_valid(_mission_stack):
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.tooltip_text=str(entry.get("marker_label","TASK"))+" / "+str(entry.get("description",entry.get("title","Ship work order")))
	var tag_text: String = str(entry.get("marker_label", "TASK"))
	var tag := _tag(tag_text, 12, GOLD)
	tag.custom_minimum_size.x = 96.0
	tag.clip_text = true
	row.add_child(tag)
	var title_text: String = str(entry.get("title", "Ship work order"))
	if title_text.begins_with("Amara: "):
		title_text = title_text.substr(7)
	var objective := _label(title_text, 16, PALE)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.clip_text = true
	row.add_child(objective)
	var status := _tag("● PENDING", 12, ORANGE)
	status.custom_minimum_size.x = 84.0
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status)
	_mission_stack.add_child(row)
	_mission_rows[entry["id"]] = {"mark": status, "label": objective, "tag": tag}


func add_task_entry(entry: Dictionary) -> void:
	var task_id := StringName(entry.get("id", &""))
	if task_id == &"" or _task_completed.has(task_id):
		return
	var task_copy := entry.duplicate(true)
	task_copy["id"] = task_id
	_task_entries.append(task_copy)
	_task_completed[task_id] = false
	_add_mission_row(task_copy)
	if is_instance_valid(_mission_panel):
		_mission_panel.offset_bottom = 198.0 + maxi(_task_entries.size() - 3, 0) * 32.0
	_add_map_task_marker(task_copy)
	_add_world_task_marker(task_copy)
	_refresh_mission_panel()


func _build_top_controls() -> void:
	var controls := HBoxContainer.new()
	controls.name = "TopRightControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.offset_left = -626.0
	controls.offset_top = 14.0
	controls.offset_right = -18.0
	controls.offset_bottom = 74.0
	controls.add_theme_constant_override("separation", 8)
	_root.add_child(controls)
	controls.add_child(_navigation_button(&"map", "SHIP MAP", "M", _open_map))
	controls.add_child(_navigation_button(&"inventory", "INVENTORY", "I", _open_inventory))
	controls.add_child(_navigation_button(&"settings", "SETTINGS", "Esc", _open_settings))
	controls.add_child(_navigation_button(&"dev", "DEV MENU", "F3", _toggle_dev_menu))


func _build_context_prompt() -> void:
	# The design's HUD chip: notched dark strip, keycap, then the action.
	_context_prompt = PanelContainer.new()
	_context_prompt.name = "InteractionPrompt"
	_context_prompt.anchor_left = 0.5
	_context_prompt.anchor_right = 0.5
	_context_prompt.anchor_top = 1.0
	_context_prompt.anchor_bottom = 1.0
	_context_prompt.offset_left = -300.0
	_context_prompt.offset_top = -158.0
	_context_prompt.offset_right = 300.0
	_context_prompt.offset_bottom = -114.0
	_context_prompt.visible = false
	var prompt_style := ESTYLE.make("chip", 8.0)
	prompt_style.content_margin_left = 14.0; prompt_style.content_margin_right = 16.0
	_context_prompt.add_theme_stylebox_override("panel", prompt_style)
	_root.add_child(_context_prompt)
	var prompt_box := HBoxContainer.new()
	prompt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_box.add_theme_constant_override("separation", 10)
	_context_prompt.add_child(prompt_box)
	prompt_box.add_child(EC.Keycap.new("E", 14, 28.0, 24.0))
	_context_label = _label("", 17, PALE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_box.add_child(_context_label)


func _build_hotbar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "Hotbar"
	bar.add_theme_constant_override("separation", 6)
	var frame := PanelContainer.new()
	frame.name = "QuickbarFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	frame.offset_left = -340.0
	frame.offset_right = 340.0
	frame.offset_top = -104.0
	frame.offset_bottom = -12.0
	frame.add_theme_stylebox_override("panel", ESTYLE.make("module", 10.0))
	_root.add_child(frame)
	frame.add_child(bar)
	for index in range(9):
		var cell := InventoryCell.new()
		cell.name = "QuickSlot%d" % (index + 1)
		cell.custom_minimum_size = Vector2(68, 68)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.configure(&"hotbar", index, _hotbar_items[index], _short_item_name(_hotbar_items[index]), _item_color(_hotbar_items[index]), index == _selected_hotbar_index, "", _item_icon_texture(_hotbar_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		bar.add_child(cell)
		_hotbar_slots.append(cell)


func _create_map_overlay() -> void:
	var modal := _create_modal_shell("SHIP MAP", Vector2(1140, 660))
	_overlay_nodes[&"map"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	_map_surface = PanelContainer.new()
	_map_surface.name = "BlankMapViewport"
	_map_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_surface.add_theme_stylebox_override("panel", PIXEL_THEME.get_stylebox("panel", "MapViewport"))
	content.add_child(_map_surface)
	# Phosphor chart glass. Deck content stays disabled until the map is approved.
	var chart := MapScreen.new()
	chart.name = "ChartGrid"
	_map_surface.add_child(chart)
	# Retain marker nodes/data for later, without rendering or receiving input.
	_map_player_marker = _map_marker(GOLD, true)
	_map_player_marker.hide()
	_map_surface.add_child(_map_player_marker)
	for entry in _task_entries:
		_add_map_task_marker(entry)
	var legend := HFlowContainer.new()
	legend.name = "MapLegend"
	legend.add_theme_constant_override("h_separation", 24)
	legend.add_theme_constant_override("v_separation", 8)
	for item in [["Current position", "live"], ["Open task", "warn"], ["Complete", "ok"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(EC.Lamp.new(item[1]))
		row.add_child(_label(item[0], 15, PALE))
		legend.add_child(row)
	var close_hint := HBoxContainer.new()
	close_hint.add_theme_constant_override("separation", 6)
	close_hint.add_child(EC.Keycap.new("M"))
	close_hint.add_child(EC.Keycap.new("Esc"))
	close_hint.add_child(_label("Close", 15, MUTED))
	legend.add_child(close_hint)
	content.add_child(legend)


func _add_map_task_marker(entry: Dictionary) -> void:
	if not is_instance_valid(_map_surface):
		return
	var task_id: StringName = entry["id"]
	if _map_task_markers.has(task_id):
		return
	var marker := MapPin.new()
	marker.custom_minimum_size = Vector2(20.0, 28.0)
	marker.pin_color = ORANGE
	marker.tooltip_text = str(entry.get("title", "Ship task"))
	marker.visible = MAP_CONTENT_VISIBLE
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.focus_mode = Control.FOCUS_NONE
	_map_surface.add_child(marker)
	_map_task_markers[task_id] = {"marker": marker}


func _add_world_task_marker(entry: Dictionary) -> void:
	if not is_instance_valid(_world_task_marker_layer):
		return
	var task_id := StringName(entry.get("id", &""))
	if task_id == &"" or _world_task_markers.has(task_id):
		return
	var marker := TaskLocationMarker.new()
	marker.name = "Task_%s" % String(task_id)
	marker.tooltip_text = str(entry.get("title", "Open ship task"))
	_world_task_marker_layer.add_child(marker)
	_world_task_markers[task_id] = marker


func _create_inventory_overlay() -> void:
	var modal := _create_modal_shell("PERSONAL LOADOUT / INVENTORY", Vector2(1232, 672))
	_overlay_nodes[&"inventory"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	var columns := HBoxContainer.new()
	columns.name = "InventoryColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 12)
	content.add_child(columns)

	# Operator: Thura on phosphor glass, flanked by the four equipment wells.
	_operator_panel = PanelContainer.new()
	_operator_panel.custom_minimum_size.x = 300
	_operator_panel.add_theme_stylebox_override("panel", ESTYLE.make("glass", 12))
	columns.add_child(_operator_panel)
	var character_stack := VBoxContainer.new()
	character_stack.add_theme_constant_override("separation", 10)
	_operator_panel.add_child(character_stack)
	var operator_head := HBoxContainer.new()
	operator_head.add_theme_constant_override("separation", 8)
	operator_head.add_child(EC.Lamp.new("ok"))
	operator_head.add_child(_tag("OPERATOR / THURA MIN", 12, EUI.PHOS))
	character_stack.add_child(operator_head)
	character_stack.add_child(HSeparator.new())
	var character_row := HBoxContainer.new()
	character_row.add_theme_constant_override("separation", 6)
	character_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_stack.add_child(character_row)
	var left_slots := VBoxContainer.new()
	var right_slots := VBoxContainer.new()
	for slot_stack in [left_slots, right_slots]:
		slot_stack.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_stack.add_theme_constant_override("separation", 24)
	character_row.add_child(left_slots)
	var portrait := TextureRect.new()
	portrait.name = "OperatorPortrait"
	var portrait_texture := AtlasTexture.new()
	portrait_texture.atlas = THURA_ATLAS
	portrait_texture.region = Rect2(79, 43, 157, 267)
	portrait_texture.filter_clip = true
	portrait.texture = portrait_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(80, 160)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_row.add_child(portrait)
	character_row.add_child(right_slots)
	for index in range(EQUIPMENT_SLOTS.size()):
		var cell := InventoryCell.new()
		cell.name = "Equipment_%s" % EQUIPMENT_SLOTS[index]
		cell.custom_minimum_size = Vector2(76, 108)
		var slot_id: StringName = EQUIPMENT_SLOTS[index]
		var item_id: StringName = _equipment_items[slot_id]
		cell.configure(&"equipment", index, item_id, _short_item_name(item_id), _item_color(item_id), false, String(EQUIPMENT_LABELS[index]), _item_icon_texture(item_id))
		cell.drop_requested.connect(_on_inventory_drop_requested)
		(left_slots if index % 2 == 0 else right_slots).add_child(cell)
		_equipment_cells.append(cell)
	var vitals := HBoxContainer.new()
	vitals.add_theme_constant_override("separation", 8)
	vitals.add_child(_tag("SUIT", 12, EUI.PHOS_DIM))
	var suit_cells := EC.Cells.new(10, 10)
	suit_cells.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	suit_cells.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	suit_cells.set_value(10, EUI.PHOS)
	vitals.add_child(suit_cells)
	vitals.add_child(_label("Nominal", 15, EUI.PHOS))
	character_stack.add_child(vitals)

	var inventory_panel := PanelContainer.new()
	inventory_panel.name = "CargoPanel"
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.add_theme_stylebox_override("panel", ESTYLE.make("bezel", 12))
	columns.add_child(inventory_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(stack)
	var cargo_heading := HBoxContainer.new()
	cargo_heading.add_child(EC.stamp(_tag("CARGO HOLD", 16, MUTED)))
	cargo_heading.add_spacer(false)
	_cargo_count_label = _label("08 / 27 USED", 16, EUI.PHOS)
	cargo_heading.add_child(_cargo_count_label)
	stack.add_child(cargo_heading)
	_cargo_grid = GridContainer.new()
	_cargo_grid.name = "CargoGrid"
	_cargo_grid.columns = 9
	_cargo_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cargo_grid.add_theme_constant_override("h_separation", 6)
	_cargo_grid.add_theme_constant_override("v_separation", 6)
	stack.add_child(_cargo_grid)
	for index in range(27):
		var cell := InventoryCell.new()
		cell.name = "CargoSlot%02d" % (index + 1)
		cell.custom_minimum_size = Vector2(90, 80)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.configure(&"storage", index, _storage_items[index], _short_item_name(_storage_items[index]), _item_color(_storage_items[index]), false, "", _item_icon_texture(_storage_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		_cargo_grid.add_child(cell)
		_storage_cells.append(cell)
	var quick_heading := HBoxContainer.new()
	quick_heading.add_theme_constant_override("separation", 8)
	quick_heading.add_child(EC.stamp(_tag("QUICK ACCESS", 16, MUTED)))
	quick_heading.add_child(EC.Keycap.new("1-9"))
	stack.add_child(quick_heading)
	var quick_grid := GridContainer.new()
	quick_grid.name = "InventoryQuickAccess"
	quick_grid.columns = 9
	quick_grid.add_theme_constant_override("h_separation", 6)
	stack.add_child(quick_grid)
	for index in range(9):
		var cell := InventoryCell.new()
		cell.name = "InventoryQuickSlot%d" % (index + 1)
		cell.custom_minimum_size = Vector2(90, 76)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.configure(&"hotbar", index, _hotbar_items[index], _short_item_name(_hotbar_items[index]), _item_color(_hotbar_items[index]), index == _selected_hotbar_index, "", _item_icon_texture(_hotbar_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		quick_grid.add_child(cell)
		_inventory_hotbar_cells.append(cell)
	var hint := _label("Drag items to quick access or a compatible slot.", 15, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 8)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_row.add_child(hint)
	hint_row.add_child(EC.Keycap.new("I"))
	hint_row.add_child(EC.Keycap.new("Esc"))
	hint_row.add_child(_label("Close", 15, MUTED))
	content.add_child(hint_row)
	_refresh_inventory_cells()


func _create_settings_overlay() -> void:
	var modal := _create_modal_shell("SHIP SETTINGS", Vector2(860, 560))
	_overlay_nodes[&"settings"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	content.add_theme_constant_override("separation", 12)
	var audio := PanelContainer.new()
	audio.add_theme_stylebox_override("panel", ESTYLE.make("bezel", 14))
	content.add_child(audio)
	var audio_stack := VBoxContainer.new()
	audio_stack.add_theme_constant_override("separation", 10)
	audio.add_child(audio_stack)
	audio_stack.add_child(EC.stamp(_tag("AUDIO OUTPUT", 16, MUTED)))
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 16)
	volume_row.add_child(_label("Master volume", 17, PALE))
	_volume_slider = HSlider.new()
	_volume_slider.name = "MasterVolume"
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 1
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.custom_minimum_size = Vector2(180, 32)
	var master_bus_index := AudioServer.get_bus_index("Master")
	_volume_slider.value = 100
	if master_bus_index >= 0:
		_volume_slider.value = 0.0 if AudioServer.is_bus_mute(master_bus_index) else AudioServer.get_bus_volume_linear(master_bus_index) * 100.0
	_volume_slider.value_changed.connect(_on_master_volume_changed)
	volume_row.add_child(_volume_slider)
	var readout := PanelContainer.new()
	readout.add_theme_stylebox_override("panel", ESTYLE.make("glass", 6))
	readout.custom_minimum_size = Vector2(76, 0)
	_volume_label = _label("%d%%" % roundi(_volume_slider.value), 18, EUI.PHOS)
	_volume_label.custom_minimum_size.x = 52
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	readout.add_child(_volume_label)
	volume_row.add_child(readout)
	audio_stack.add_child(volume_row)
	var controls := PanelContainer.new()
	controls.add_theme_stylebox_override("panel", ESTYLE.make("bezel", 14))
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(controls)
	var control_stack := VBoxContainer.new()
	control_stack.add_theme_constant_override("separation", 10)
	controls.add_child(control_stack)
	control_stack.add_child(EC.stamp(_tag("CONTROLS", 16, MUTED)))
	var hints := GridContainer.new()
	hints.name = "ControlHints"
	hints.columns = 2
	hints.add_theme_constant_override("h_separation", 32)
	hints.add_theme_constant_override("v_separation", 10)
	for pair in [["Move", "WASD / Arrows"], ["Interact", "E"], ["Quick slot", "1-9 / Wheel"], ["Inventory", "I"], ["Ship map", "M"], ["Settings / close", "Esc"]]:
		hints.add_child(_key_hint(pair[0], pair[1]))
	control_stack.add_child(hints)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	foot.add_child(EC.Lamp.new("ok"))
	foot.add_child(_label("Walking pauses while these panels are open.", 15, MUTED))
	content.add_child(foot)


func _key_hint(action_name: String, key_name: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(340, 32)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	row.add_child(_label(action_name, 16, PALE))
	row.add_spacer(false)
	for part in key_name.split(" / "):
		row.add_child(EC.Keycap.new(part, 14, 28.0, 26.0))
	return row


func _create_modal_shell(title: String, desired_size: Vector2) -> Dictionary:
	var overlay := Control.new()
	overlay.name = title.replace(" / ", "_").replace(" ", "_")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	_root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.02, 0.03, 0.035, 0.86)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dimmer)
	# Screwed metal plate, like the design's station frames.
	var frame := PanelContainer.new()
	frame.name = "WindowFrame"
	frame.minimum_size_changed.connect(_queue_resize)
	frame.add_theme_stylebox_override("panel", ESTYLE.make("module", 24.0, true))
	overlay.add_child(frame)
	_modal_frames[overlay] = {"frame": frame, "desired": desired_size}
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	frame.add_child(layout)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	var icon := PixelIcon.new()
	icon.icon_kind = &"map" if title == "SHIP MAP" else &"settings" if title == "SHIP SETTINGS" else &"inventory"
	icon.tint = GOLD
	icon.custom_minimum_size = Vector2(28, 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(icon)
	var title_label := EC.stamp(_tag(title, 20, MUTED))
	title_label.name = "WindowTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_child(title_label)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.theme_type_variation = &"CloseButton"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.name = "Close"
	close_button.tooltip_text = "Close / Esc"
	close_button.add_theme_font_size_override("font_size", 16)
	close_button.pressed.connect(_close_overlay)
	heading.add_child(close_button)
	layout.add_child(heading)
	layout.add_child(HSeparator.new())
	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(content)
	return {"root": overlay, "content": content}


func _map_marker(color: Color, _is_player: bool) -> Control:
	var marker := MapDot.new()
	marker.dot_color = color
	marker.custom_minimum_size = Vector2(16.0, 16.0)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.tooltip_text = "Thura / current position"
	return marker


func _update_map_markers() -> void:
	if not MAP_CONTENT_VISIBLE or not is_instance_valid(_map_surface):
		return
	if is_instance_valid(_player) and _map_world_size.x > 0.0 and _map_world_size.y > 0.0:
		_set_marker_position(_map_player_marker, (_player.global_position - _map_world_origin) / _map_world_size)
	for entry in _task_entries:
		var task_id: StringName = entry["id"]
		if not _map_task_markers.has(task_id):
			continue
		var marker_data: Dictionary = _map_task_markers[task_id]
		var task_position: Vector2 = entry["position"]
		var normalized: Vector2 = (task_position - _map_world_origin) / _map_world_size
		var marker := marker_data["marker"] as MapPin
		_set_map_pin_position(marker, normalized)
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		marker.is_complete = is_complete
		marker.pin_color = GREEN if is_complete else ORANGE
		marker.tooltip_text = ("[NOMINAL] " if is_complete else "[ALERT] ") + str(entry.get("title", "Ship task"))
		marker.queue_redraw()


func _update_world_task_markers() -> void:
	if not is_instance_valid(_world_task_marker_layer):
		return
	var canvas_transform := get_viewport().get_canvas_transform()
	var visible_rect := get_viewport().get_visible_rect()
	for entry in _task_entries:
		var task_id: StringName = entry["id"]
		if not _world_task_markers.has(task_id):
			continue
		var marker := _world_task_markers[task_id] as TaskLocationMarker
		if not is_instance_valid(marker):
			continue
		if bool(_task_completed.get(task_id, false)) or not _walking_visible or _active_overlay != &"":
			marker.visible = false
			continue
		var target_world_position: Vector2 = entry.get("marker_position", entry.get("position", Vector2.ZERO))
		var target_screen_position := canvas_transform * target_world_position
		var marker_size := marker.custom_minimum_size
		marker.position = target_screen_position - Vector2(marker_size.x * 0.5, marker_size.y)
		marker.visible = visible_rect.grow(12.0).has_point(target_screen_position)


func _set_marker_position(marker: Control, normalized: Vector2) -> void:
	if not is_instance_valid(marker):
		return
	var safe_position := Vector2(clampf(normalized.x, 0.01, 0.99), clampf(normalized.y, 0.02, 0.98))
	marker.anchor_left = safe_position.x
	marker.anchor_right = safe_position.x
	marker.anchor_top = safe_position.y
	marker.anchor_bottom = safe_position.y
	marker.offset_left = -marker.custom_minimum_size.x * 0.5
	marker.offset_right = marker.custom_minimum_size.x * 0.5
	marker.offset_top = -marker.custom_minimum_size.y * 0.5
	marker.offset_bottom = marker.custom_minimum_size.y * 0.5
	marker.size = marker.custom_minimum_size


func _set_map_pin_position(marker: Control, normalized: Vector2) -> void:
	if not is_instance_valid(marker):
		return
	var safe_position := Vector2(clampf(normalized.x, 0.01, 0.99), clampf(normalized.y, 0.02, 0.98))
	marker.anchor_left = safe_position.x
	marker.anchor_right = safe_position.x
	marker.anchor_top = safe_position.y
	marker.anchor_bottom = safe_position.y
	marker.offset_left = -10.0
	marker.offset_right = 10.0
	marker.offset_top = -27.0
	marker.offset_bottom = 1.0
	marker.size = marker.custom_minimum_size


func _refresh_mission_panel() -> void:
	if not is_instance_valid(_mission_progress_label):
		return
	var completed_count := 0
	for task_id in _task_completed:
		if _task_completed[task_id]:
			completed_count += 1
	var total := _task_entries.size()
	var pct := int(roundf((float(completed_count) / float(maxi(total, 1))) * 100.0))
	_mission_progress_label.text = "%02d / %02d  (%d%%)" % [completed_count, total, pct]
	_mission_progress_label.add_theme_color_override("font_color", GREEN if completed_count == total else EUI.PHOS)
	_mission_progress_bar.max_value = maxi(total, 1)
	_mission_progress_bar.value = completed_count
	for task_id in _mission_rows:
		var row: Dictionary = _mission_rows[task_id]
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		if is_complete:
			row["mark"].text = "✔ DONE"
			row["mark"].add_theme_color_override("font_color", GREEN)
			row["label"].add_theme_color_override("font_color", Color("#7f9a92"))
			if row.has("tag"):
				row["tag"].add_theme_color_override("font_color", Color("#4f6b51"))
		else:
			row["mark"].text = "● PENDING"
			row["mark"].add_theme_color_override("font_color", ORANGE)
			row["label"].add_theme_color_override("font_color", PALE)
			if row.has("tag"):
				row["tag"].add_theme_color_override("font_color", GOLD)
	_update_map_markers()


func set_task_completed(task_id: StringName) -> void:
	if not _task_completed.has(task_id):
		return
	_task_completed[task_id] = true
	_refresh_mission_panel()
	_update_world_task_markers()


func set_interaction_prompt(text: String, is_visible: bool) -> void:
	if not is_instance_valid(_context_prompt):
		return
	var formatted_text := text
	if formatted_text.find("[E]") != -1:
		formatted_text = formatted_text.replace("[E]", "").replace("   /   ", " // ").strip_edges()
		if not formatted_text.begins_with("USE") and not formatted_text.begins_with("INTERACT"):
			formatted_text = "USE // " + formatted_text
	_context_label.text = formatted_text
	_context_prompt.visible = is_visible and _walking_visible and _active_overlay == &""


func set_walking_visible(is_visible: bool) -> void:
	_walking_visible = is_visible
	if is_instance_valid(_root):
		_root.visible = is_visible
	set_process_unhandled_input(is_visible)
	set_process_unhandled_key_input(is_visible)


func _on_inventory_cell_activated(slot_kind: StringName, slot_index: int) -> void:
	if slot_kind == &"hotbar":
		_selected_hotbar_index = slot_index
		_refresh_hotbar()
		_refresh_inventory_cells()


func _on_inventory_drop_requested(target_kind: StringName, target_index: int, data: Dictionary) -> void:
	var source_kind := StringName(data.get("source_kind", &""))
	var source_index := int(data.get("source_index", -1))
	if source_kind == &"" or source_index < 0 or (source_kind == target_kind and source_index == target_index):
		return
	var source_item := _get_slot_item(source_kind, source_index)
	var target_item := _get_slot_item(target_kind, target_index)
	if source_item == &"":
		return
	if target_kind == &"equipment" and not _item_fits_equipment_slot(source_item, target_index):
		return
	if source_kind == &"equipment" and target_item != &"" and not _item_fits_equipment_slot(target_item, source_index):
		return
	_set_slot_item(source_kind, source_index, target_item)
	_set_slot_item(target_kind, target_index, source_item)
	_refresh_hotbar()
	_refresh_inventory_cells()
	inventory_changed.emit()


func _get_slot_item(slot_kind: StringName, slot_index: int) -> StringName:
	match slot_kind:
		&"hotbar":
			return _hotbar_items[slot_index] if slot_index >= 0 and slot_index < _hotbar_items.size() else &""
		&"storage":
			return _storage_items[slot_index] if slot_index >= 0 and slot_index < _storage_items.size() else &""
		&"equipment":
			if slot_index >= 0 and slot_index < EQUIPMENT_SLOTS.size():
				return StringName(_equipment_items.get(EQUIPMENT_SLOTS[slot_index], &""))
	return &""


func _set_slot_item(slot_kind: StringName, slot_index: int, item_id: StringName) -> void:
	match slot_kind:
		&"hotbar":
			if slot_index >= 0 and slot_index < _hotbar_items.size():
				_hotbar_items[slot_index] = item_id
		&"storage":
			if slot_index >= 0 and slot_index < _storage_items.size():
				_storage_items[slot_index] = item_id
		&"equipment":
			if slot_index >= 0 and slot_index < EQUIPMENT_SLOTS.size():
				_equipment_items[EQUIPMENT_SLOTS[slot_index]] = item_id


func _item_fits_equipment_slot(item_id: StringName, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= EQUIPMENT_SLOTS.size() or not ITEM_DATA.has(item_id):
		return false
	return ITEM_DATA[item_id]["equip_slot"] == EQUIPMENT_SLOTS[slot_index]


func _refresh_hotbar() -> void:
	for index in range(_hotbar_slots.size()):
		var item_id: StringName = _hotbar_items[index]
		_hotbar_slots[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), index == _selected_hotbar_index, _item_icon_texture(item_id))


func _refresh_inventory_cells() -> void:
	for index in range(_storage_cells.size()):
		var item_id: StringName = _storage_items[index]
		_storage_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), false, _item_icon_texture(item_id))
	for index in range(_inventory_hotbar_cells.size()):
		var item_id: StringName = _hotbar_items[index]
		_inventory_hotbar_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), index == _selected_hotbar_index, _item_icon_texture(item_id))
	for index in range(_equipment_cells.size()):
		var slot_id: StringName = EQUIPMENT_SLOTS[index]
		var item_id: StringName = StringName(_equipment_items.get(slot_id, &""))
		_equipment_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), false, _item_icon_texture(item_id))
	if is_instance_valid(_cargo_count_label):
		var used_slots := 0
		for item_id in _storage_items:
			if item_id != &"":
				used_slots += 1
		_cargo_count_label.text = "%02d / %02d USED" % [used_slots, _storage_items.size()]


func _open_map() -> void:
	_open_overlay(&"map")


func _open_inventory() -> void:
	_refresh_inventory_cells()
	_open_overlay(&"inventory")


func _open_settings() -> void:
	_open_overlay(&"settings")


func _open_overlay(overlay_name: StringName) -> void:
	if not _walking_visible or not _overlay_nodes.has(overlay_name):
		return
	if is_instance_valid(_dev_panel): _dev_panel.hide()
	for name in _overlay_nodes:
		_overlay_nodes[name].visible = name == overlay_name
	var was_closed := _active_overlay == &""
	if was_closed:
		_previous_focus = get_viewport().gui_get_focus_owner()
	_active_overlay = overlay_name
	if was_closed:
		_context_prompt.visible = false
		modal_state_changed.emit(true)
	if overlay_name == &"map":
		_update_map_markers()
	var close := _overlay_nodes[overlay_name].find_child("Close", true, false) as Button
	close.grab_focus()
	_queue_resize()


func _close_overlay() -> void:
	if _active_overlay == &"":
		return
	for overlay in _overlay_nodes.values():
		overlay.visible = false
	_active_overlay = &""
	_context_prompt.visible = false
	modal_state_changed.emit(false)
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()


func _on_master_volume_changed(value: float) -> void:
	var master_bus_index := AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		return
	if value <= 0.0:
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value / 100.0))
	_volume_label.text = "%d%%" % roundi(value)


func _navigation_button(icon_kind: StringName, title: String, shortcut: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = title.replace(" ", "")
	button.custom_minimum_size = Vector2(146, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s / %s" % [title, shortcut]
	button.focus_mode = Control.FOCUS_ALL
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 10
	layout.offset_right = -10
	layout.offset_bottom = -3
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 10)
	var icon := PixelIcon.new()
	icon.icon_kind = icon_kind
	icon.tint = GOLD
	icon.custom_minimum_size = Vector2(24, 24)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)
	var labels := VBoxContainer.new()
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.add_theme_constant_override("separation", 3)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_label := _tag(title, 12, PALE)
	var shortcut_cap := EC.Keycap.new(shortcut, 12, 24.0, 18.0)
	shortcut_cap.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	labels.add_child(title_label)
	labels.add_child(shortcut_cap)
	layout.add_child(labels)
	button.add_child(layout)
	button.mouse_entered.connect(func(): title_label.add_theme_color_override("font_color", EUI.CUE))
	button.mouse_exited.connect(func(): title_label.add_theme_color_override("font_color", PALE))
	button.pressed.connect(callback)
	return button


func _nav_button_style(_accent: Color, highlighted: bool) -> StyleBox:
	return PIXEL_THEME.get_stylebox("hover" if highlighted else "normal", "Button")

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(font_size, 12))
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Silkscreen caps label (the design's tags, keys and module titles).
func _tag(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.theme_type_variation = &"EitoTag"
	return label


func _button(text: String, minimum_size: Vector2, _accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	return button


func _button_style(_accent: Color, highlighted: bool) -> StyleBox:
	return PIXEL_THEME.get_stylebox("hover" if highlighted else "normal", "Button")

func _panel_style(background: Color, border: Color, padding: float) -> StyleBox:
	if padding >= 5:
		var frame := PIXEL_THEME.get_stylebox("panel", "PanelContainer").duplicate() as StyleBox
		frame.content_margin_left = padding
		frame.content_margin_right = padding
		frame.content_margin_top = padding
		frame.content_margin_bottom = padding
		return frame
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.anti_aliasing = false
	return style

func _short_item_name(item_id: StringName) -> String:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return ""
	return str(ITEM_DATA[item_id]["short"])


func _item_color(item_id: StringName) -> Color:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return MUTED
	return ITEM_DATA[item_id]["color"]


func _item_icon_texture(item_id: StringName) -> Texture2D:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return null
	if _item_icon_cache.has(item_id):
		return _item_icon_cache[item_id]
	var item: Dictionary = ITEM_DATA[item_id]
	if not item.has("texture"):
		return null # Consumables use labelled dynamic slots; no invented artwork.
	# Downsample the existing poster crop once. Nearest display then preserves
	# readable icon pixels instead of aliasing a thousand-pixel source each frame.
	var source: Image = item["texture"].get_image()
	if source.is_compressed():
		source.decompress()
	var thumbnail := source.get_region(Rect2i(item["icon_region"]))
	var ratio := 64.0 / maxf(thumbnail.get_width(), thumbnail.get_height())
	thumbnail.resize(maxi(1, roundi(thumbnail.get_width() * ratio)), maxi(1, roundi(thumbnail.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	var icon := ImageTexture.create_from_image(thumbnail)
	_item_icon_cache[item_id] = icon
	return icon


func _unhandled_input(event: InputEvent) -> void:
	if not _walking_visible or _active_overlay != &"":
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_hotbar((_selected_hotbar_index - 1 + _hotbar_items.size()) % _hotbar_items.size())
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_hotbar((_selected_hotbar_index + 1) % _hotbar_items.size())
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _walking_visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F3 or event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F1:
		_toggle_dev_menu()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE:
		if _active_overlay != &"":
			_close_overlay()
		else:
			_open_settings()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_M and _active_overlay == &"map":
		_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if _active_overlay != &"":
		return
	if event.keycode == KEY_I:
		_open_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_M:
		_open_map()
		get_viewport().set_input_as_handled()
		return
	var hotbar_index := HOTBAR_KEY_CODES.find(event.keycode)
	if hotbar_index >= 0:
		_select_hotbar(hotbar_index)
		get_viewport().set_input_as_handled()


func _get_room_lighting() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("ship_room_lighting")
	if not nodes.is_empty():
		return nodes[0] as Node2D
	if is_instance_valid(_player) and _player.get_parent() != null:
		return _player.get_parent().get_node_or_null("ShipRoomLighting") as Node2D
	return null


func inventory_count(item: StringName) -> int:
	var count := _storage_items.count(item)+_hotbar_items.count(item)
	for carried in _equipment_items.values():
		if StringName(carried)==item: count+=1
	return count


func inventory_put(item: StringName, amount := 1) -> bool:
	if amount<1 or not ITEM_DATA.has(item): return false
	var spaces := _storage_items.count(&"")+_hotbar_items.count(&"")
	if spaces<amount: return false
	for i in range(amount):
		var index := _storage_items.find(&"")
		if index>=0: _storage_items[index]=item
		else: _hotbar_items[_hotbar_items.find(&"")]=item
	_refresh_hotbar();_refresh_inventory_cells();inventory_changed.emit()
	return true


func inventory_take(item: StringName, amount := 1) -> bool:
	if amount<1 or inventory_count(item)<amount: return false
	for i in range(amount):
		var index := _storage_items.find(item)
		if index>=0: _storage_items[index]=&"";continue
		index=_hotbar_items.find(item)
		if index>=0: _hotbar_items[index]=&"";continue
		for slot in _equipment_items:
			if StringName(_equipment_items[slot])==item:
				_equipment_items[slot]=&"";break
	_refresh_hotbar();_refresh_inventory_cells();inventory_changed.emit()
	return true


func inventory_snapshot() -> Dictionary:
	# Array(existing_array) aliases its storage in Godot. Snapshots must own copies
	# so later drag/drop and consumption cannot mutate a save/scenario baseline.
	return {"storage":_storage_items.duplicate(),"hotbar":_hotbar_items.duplicate(),"equipment":_equipment_items.duplicate(),"selected":_selected_hotbar_index}


func inventory_valid(data: Dictionary) -> bool:
	if not data.get("storage") is Array or data.storage.size()!=27 or not data.get("hotbar") is Array or data.hotbar.size()!=9 or not data.get("equipment") is Dictionary or data.equipment.size()!=4: return false
	for item in data.storage+data.hotbar+data.equipment.values():
		if not (item is String or item is StringName): return false
		if str(item)!="" and not ITEM_DATA.has(StringName(item)): return false
	for slot in EQUIPMENT_SLOTS:
		if not data.equipment.has(str(slot)): return false
		var item := StringName(data.equipment[str(slot)])
		if item!=&"" and ITEM_DATA[item].equip_slot!=slot: return false
	if not (data.get("selected") is int or data.get("selected") is float): return false
	return is_finite(float(data.selected)) and data.selected==floor(data.selected) and data.selected>=0 and data.selected<9


func inventory_restore(data: Dictionary) -> bool:
	if not inventory_valid(data): return false
	for i in range(27): _storage_items[i]=StringName(data.storage[i])
	for i in range(9): _hotbar_items[i]=StringName(data.hotbar[i])
	for slot in EQUIPMENT_SLOTS: _equipment_items[slot]=StringName(data.equipment[str(slot)])
	_selected_hotbar_index=int(data.selected)
	_refresh_hotbar();_refresh_inventory_cells();inventory_changed.emit()
	return true


func set_ship_objectives(entries: Array, completed_ids: Dictionary) -> void:
	_story_tracker_enabled=false
	# Reuse the existing mission tracker and completion dictionary. Its dynamic
	# rows are rebuilt in place; the inventory, settings, map and hotbar stay live.
	_task_entries.clear();_task_completed.clear();_mission_rows.clear()
	# The original three service markers remain available as data, but must not
	# linger at (0,0) after the tracker switches to the integrated ship duties.
	for marker in _world_task_markers.values():
		if is_instance_valid(marker): marker.hide()
	# Keep header/progress/subheading (first three children), replace objective rows.
	for i in range(_mission_stack.get_child_count()-1,2,-1):
		var child := _mission_stack.get_child(i)
		_mission_stack.remove_child(child);child.queue_free()
	for entry in entries:
		_task_entries.append(entry.duplicate(true));_task_completed[entry.id]=completed_ids.has(str(entry.id))
		_add_mission_row(entry)
		_add_world_task_marker(entry);_add_map_task_marker(entry)
	_mission_panel.offset_bottom=198.0+maxi(entries.size()-3,0)*32.0
	_refresh_mission_panel()
	_update_world_task_markers()

func set_story_objective(entry: Dictionary, completed_missions: int, optional_enabled: bool, optional_completed: int) -> void:
	# Reuse the tracker and its world marker; optional checks never enter the
	# chapter denominator or masquerade as additional required machine repairs.
	set_ship_objectives([entry], {str(entry.id):true} if completed_missions==5 else {})
	# One objective: give its title a full line under the location tag.
	var only: Dictionary = _mission_rows.get(entry.id, {})
	if not only.is_empty():
		var title_label: Label = only["label"]
		var row_node := title_label.get_parent()
		row_node.remove_child(title_label)
		var spacer := Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_node.add_child(spacer); row_node.move_child(spacer, 1)
		title_label.clip_text = false
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.custom_minimum_size.x = 300
		title_label.add_theme_font_size_override("font_size", 20)
		_mission_stack.add_child(title_label)
	_mission_progress_label.text = "%d / 5 MISSIONS" % completed_missions
	_mission_progress_bar.max_value = 5; _mission_progress_bar.value = completed_missions
	var description := _label(str(entry.description), 15, Color("#b4c3c1"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 300
	_mission_stack.add_child(description)
	_mission_stack.add_child(HSeparator.new())
	var optional := _tag("OPTIONAL / %d OF 2 OBSERVATIONS" % mini(optional_completed,2) if optional_enabled else "OPTIONAL / EXPLORE SHIP SYSTEMS", 12, MUTED)
	optional.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_stack.add_child(optional)
	_mission_panel.offset_bottom = 300
	_story_tracker_enabled=true
	_fit_story_tracker.call_deferred()

func _fit_story_tracker() -> void:
	# Wrapped text briefly reports a taller minimum before its first container
	# layout. Refit when that minimum settles, including hidden startup layouts.
	if _story_tracker_enabled and is_instance_valid(_mission_panel):
		_mission_panel.size=Vector2(360,minf(_mission_panel.get_combined_minimum_size().y,296.0))


func _build_dev_menu_panel() -> void:
	_dev_panel = PanelContainer.new()
	_dev_panel.name = "DevMenuPanel"
	_dev_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_dev_panel.offset_left = -410.0
	_dev_panel.offset_top = 88.0
	_dev_panel.offset_right = -18.0
	_dev_panel.offset_bottom = 458.0
	_dev_panel.visible = false
	_dev_panel.add_theme_stylebox_override("panel", ESTYLE.make("module", 14.0))
	_root.add_child(_dev_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	_dev_panel.add_child(stack)
	stack.add_child(EC.Hazard.new(6))

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var title := EC.stamp(_tag("DEV MENU / LIGHTING TEST", 14, GOLD))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.name = "DevClose"
	close_btn.text = "X"
	close_btn.theme_type_variation = &"CloseButton"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.pressed.connect(func(): _dev_panel.visible = false)
	header.add_child(close_btn)
	stack.add_child(header)
	stack.add_child(HSeparator.new())

	_dev_current_room_label = _tag("OCCUPIED: HALLWAY", 12, EUI.PHOS)
	_dev_current_room_label.clip_text = true
	stack.add_child(_dev_current_room_label)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	_dev_flicker_here_btn = _button("FLICKER HERE: OFF", Vector2(176, 38), ORANGE)
	_dev_flicker_here_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_flicker_here_btn.pressed.connect(_on_dev_toggle_flicker_here)
	row1.add_child(_dev_flicker_here_btn)
	_dev_flicker_all_btn = _button("FLICKER ALL: OFF", Vector2(176, 38), ORANGE)
	_dev_flicker_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_flicker_all_btn.pressed.connect(_on_dev_toggle_flicker_all)
	row1.add_child(_dev_flicker_all_btn)
	stack.add_child(row1)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	_dev_style_btn = _button("MODE: ERRATIC", Vector2(176, 38), CYAN)
	_dev_style_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_style_btn.pressed.connect(_on_dev_cycle_style)
	row2.add_child(_dev_style_btn)
	_dev_speed_btn = _button("SPEED: 1.0X", Vector2(176, 38), CYAN)
	_dev_speed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_speed_btn.pressed.connect(_on_dev_cycle_speed)
	row2.add_child(_dev_speed_btn)
	stack.add_child(row2)

	stack.add_child(HSeparator.new())
	stack.add_child(_tag("TARGET ROOM FLICKER & WARP", 12, MUTED))

	var room_nav := HBoxContainer.new()
	room_nav.add_theme_constant_override("separation", 8)
	var prev_btn := _button("<", Vector2(44, 38), CYAN)
	prev_btn.pressed.connect(func(): _step_dev_room(-1))
	room_nav.add_child(prev_btn)
	_dev_room_name_label = _label("R01 Bridge", 16, PALE)
	_dev_room_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_room_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dev_room_name_label.clip_text = true
	room_nav.add_child(_dev_room_name_label)
	var next_btn := _button(">", Vector2(44, 38), CYAN)
	next_btn.pressed.connect(func(): _step_dev_room(1))
	room_nav.add_child(next_btn)
	stack.add_child(room_nav)

	var room_actions := HBoxContainer.new()
	room_actions.add_theme_constant_override("separation", 8)
	_dev_room_flicker_btn = _button("ROOM FLICKER: OFF", Vector2(176, 38), ORANGE)
	_dev_room_flicker_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_room_flicker_btn.pressed.connect(_on_dev_toggle_selected_room_flicker)
	room_actions.add_child(_dev_room_flicker_btn)
	var warp_btn := _button("WARP TO ROOM", Vector2(176, 38), GREEN)
	warp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warp_btn.pressed.connect(_on_dev_warp_to_selected_room)
	room_actions.add_child(warp_btn)
	stack.add_child(room_actions)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 8)
	_dev_force_lights_btn = _button("ALL LIT: OFF", Vector2(176, 38), GOLD)
	_dev_force_lights_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_force_lights_btn.pressed.connect(_on_dev_toggle_force_lights)
	row3.add_child(_dev_force_lights_btn)
	var reset_btn := _button("RESET LIGHTS", Vector2(176, 38), MUTED)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.pressed.connect(_on_dev_reset_lights)
	row3.add_child(reset_btn)
	stack.add_child(row3)
	stack.add_child(_tag("SHIP MISSIONS / DEVELOPMENT ONLY", 12, GOLD))
	var scenarios := HBoxContainer.new()
	for context in ["outbound","return"]:
		var scenario := _button("TEST "+str(context).to_upper(),Vector2(170,36),CYAN)
		scenario.tooltip_text="Development scenario; separate save file. Does not replace a canonical chapter transition."
		scenario.pressed.connect(func(): mission_scenario_requested.emit(context);_dev_panel.hide())
		scenarios.add_child(scenario)
	stack.add_child(scenarios)


func _toggle_dev_menu() -> void:
	if not _walking_visible or not is_instance_valid(_dev_panel):
		return
	if _active_overlay != &"":
		_close_overlay()
	_dev_panel.visible = not _dev_panel.visible
	if _dev_panel.visible:
		# Mission scenario buttons extend the existing dev panel. Keep it above
		# the prompt/quickbar at smaller sizes so both scenario entries can click.
		_root.move_child(_dev_panel,_root.get_child_count()-1)
		_refresh_dev_menu()


func _step_dev_room(delta_idx: int) -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("get_room_definitions"):
		return
	var defs: Array = lighting.call("get_room_definitions")
	if defs.is_empty():
		return
	_dev_selected_room_index = posmod(_dev_selected_room_index + delta_idx, defs.size())
	_refresh_dev_menu()


func _on_dev_toggle_flicker_here() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("set_flicker_current_room"):
		return
	var cur_state: bool = bool(lighting.call("is_flicker_current_room"))
	lighting.call("set_flicker_current_room", not cur_state)
	_refresh_dev_menu()


func _on_dev_toggle_flicker_all() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("set_flicker_all_rooms"):
		return
	var cur_state: bool = bool(lighting.call("is_flicker_all_rooms"))
	lighting.call("set_flicker_all_rooms", not cur_state)
	_refresh_dev_menu()


func _on_dev_cycle_style() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("get_flicker_style"):
		return
	var cur_style: StringName = StringName(lighting.call("get_flicker_style"))
	var idx: int = DEV_FLICKER_STYLES.find(cur_style)
	var next_style: StringName = DEV_FLICKER_STYLES[(idx + 1) % DEV_FLICKER_STYLES.size()]
	lighting.call("set_flicker_style", next_style)
	_refresh_dev_menu()


func _on_dev_cycle_speed() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("get_flicker_speed"):
		return
	var current: float = float(lighting.call("get_flicker_speed"))
	var next_speed: float = DEV_FLICKER_SPEEDS[0]
	for i in range(DEV_FLICKER_SPEEDS.size()):
		if is_equal_approx(current, DEV_FLICKER_SPEEDS[i]):
			next_speed = DEV_FLICKER_SPEEDS[(i + 1) % DEV_FLICKER_SPEEDS.size()]
			break
	lighting.call("set_flicker_speed", next_speed)
	_refresh_dev_menu()


func _on_dev_toggle_selected_room_flicker() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("get_room_definitions"):
		return
	var defs: Array = lighting.call("get_room_definitions")
	if defs.is_empty():
		return
	_dev_selected_room_index = clampi(_dev_selected_room_index, 0, defs.size() - 1)
	var sel_def: Dictionary = defs[_dev_selected_room_index]
	var room_id: StringName = sel_def["id"]
	lighting.call("toggle_room_flicker", room_id)
	_refresh_dev_menu()


func _on_dev_warp_to_selected_room() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not is_instance_valid(_player) or not lighting.has_method("get_room_definitions"):
		return
	var defs: Array = lighting.call("get_room_definitions")
	if defs.is_empty():
		return
	_dev_selected_room_index = clampi(_dev_selected_room_index, 0, defs.size() - 1)
	var def: Dictionary = defs[_dev_selected_room_index]
	var floor_pos: Vector2 = def.get("teleport_pos", Vector2(900.0, 500.0))
	var parent_node := lighting.get_parent() as Node2D
	var floor_layer: Node2D = null
	if parent_node != null:
		floor_layer = parent_node.get_node_or_null("FloorLayer") as Node2D
	if floor_layer != null:
		_player.global_position = floor_layer.to_global(floor_pos)
	else:
		_player.global_position = lighting.to_global(floor_pos)
	if _player.camera != null:
		_player.camera.reset_smoothing()
	_refresh_dev_menu()


func _on_dev_toggle_force_lights() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("set_force_all_lights_on"):
		return
	var cur_state: bool = bool(lighting.call("is_force_all_lights_on"))
	lighting.call("set_force_all_lights_on", not cur_state)
	_refresh_dev_menu()


func _on_dev_reset_lights() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not lighting.has_method("clear_all_flicker"):
		return
	lighting.call("clear_all_flicker")
	lighting.call("set_force_all_lights_on", false)
	lighting.call("set_flicker_style", &"erratic")
	lighting.call("set_flicker_speed", 1.0)
	_refresh_dev_menu()


func _refresh_dev_menu() -> void:
	var lighting: Node2D = _get_room_lighting()
	if lighting == null or not is_instance_valid(_dev_panel) or not lighting.has_method("get_room_definitions"):
		return
	var defs: Array = lighting.call("get_room_definitions")
	var cur_id: StringName = StringName(lighting.call("get_current_player_room_id"))
	var cur_label := "HALLWAY / CORRIDOR"
	for def in defs:
		if def["id"] == cur_id:
			cur_label = str(def.get("label", String(cur_id))).to_upper()
			break
	_dev_current_room_label.text = "OCCUPIED: " + cur_label
	var here_on: bool = bool(lighting.call("is_flicker_current_room"))
	var all_on: bool = bool(lighting.call("is_flicker_all_rooms"))
	var cur_style: String = String(lighting.call("get_flicker_style")).to_upper()
	var cur_speed: float = float(lighting.call("get_flicker_speed"))
	var all_lit: bool = bool(lighting.call("is_force_all_lights_on"))
	_dev_flicker_here_btn.text = "FLICKER HERE: " + ("ON" if here_on else "OFF")
	_dev_flicker_all_btn.text = "FLICKER ALL: " + ("ON" if all_on else "OFF")
	_dev_style_btn.text = "MODE: " + cur_style
	_dev_speed_btn.text = "SPEED: %.1fX" % cur_speed
	_dev_force_lights_btn.text = "ALL LIT: " + ("ON" if all_lit else "OFF")
	if not defs.is_empty():
		_dev_selected_room_index = clampi(_dev_selected_room_index, 0, defs.size() - 1)
		var sel_def: Dictionary = defs[_dev_selected_room_index]
		var sel_id: StringName = sel_def["id"]
		_dev_room_name_label.text = str(sel_def.get("label", String(sel_id)))
		var room_on: bool = bool(lighting.call("is_room_flickering", sel_id))
		_dev_room_flicker_btn.text = "ROOM FLICKER: " + ("ON" if room_on else "OFF")


func _select_hotbar(index: int) -> void:
	if index < 0 or index >= _hotbar_items.size():
		return
	_selected_hotbar_index = index
	_refresh_hotbar()
	_refresh_inventory_cells()



func _queue_resize() -> void:
	if not _resize_queued:
		_resize_queued = true
		_resize_ui.call_deferred()


func _resize_ui() -> void:
	_resize_queued = false
	if not is_instance_valid(_root):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var inventory_width := minf(1232, viewport_size.x - 32)
	_operator_panel.custom_minimum_size.x = 300 if inventory_width >= 1100 else 264
	var cell_width := maxf(48, floorf((inventory_width - 64 - 12 - _operator_panel.custom_minimum_size.x - 48) / 9.0))
	var cell_height := 80.0 if viewport_size.y >= 680 else 64.0
	for cell in _storage_cells:
		cell.custom_minimum_size = Vector2(cell_width, cell_height)
	for cell in _inventory_hotbar_cells:
		cell.custom_minimum_size = Vector2(cell_width, 72)
	for data in _modal_frames.values():
		var frame: PanelContainer = data["frame"]
		var desired: Vector2 = data["desired"]
		frame.size = Vector2(minf(desired.x, viewport_size.x - 32), minf(desired.y, viewport_size.y - 32)).floor()
		frame.position = ((viewport_size - frame.size) * 0.5).floor()
