class_name WalkHud
extends CanvasLayer

signal modal_state_changed(is_open: bool)

const MAP_TEXTURE := preload("res://art/overview/asteria_overview.png")
const THURA_ATLAS := preload("res://art/characters/runtime/thura_walk_4dir.png")
const CHARACTER_FRAME_SIZE := Vector2(313.5, 313.5)

const GOLD := Color(1.0, 0.78, 0.38)
const PALE := Color(0.96, 0.985, 1.0)
const MUTED := Color(0.7, 0.8, 0.83)
const CYAN := Color(0.36, 0.9, 1.0)
const ORANGE := Color(1.0, 0.68, 0.32)
const GREEN := Color(0.48, 0.93, 0.64)
const SURFACE := Color(0.025, 0.055, 0.074)
const SURFACE_RAISED := Color(0.042, 0.084, 0.103)
const SURFACE_HOVER := Color(0.068, 0.125, 0.141)
const EDGE := Color(0.34, 0.51, 0.55)
const EDGE_SOFT := Color(0.24, 0.39, 0.43)

const ITEM_DATA := {
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
		var unit := minf(size.x, size.y) / 24.0
		var origin := (size - Vector2.ONE * unit * 24.0) * 0.5
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
	func _block(origin: Vector2, unit: float, x: int, y: int, width: int, height: int, color: Color, filled := true) -> void:
		var rect := Rect2(origin + Vector2(float(x), float(y)) * unit, Vector2(float(width), float(height)) * unit)
		if filled:
			draw_rect(rect, color, true)
		else:
			draw_rect(rect, color, false, 1.0, false)


class MapDot extends Control:
	var dot_color := Color(1.0, 0.78, 0.38)

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, 6.0, Color(0.015, 0.035, 0.045, 0.96))
		draw_circle(center, 4.0, dot_color)
		draw_arc(center, 4.8, 0.0, TAU, 20, Color(0.94, 0.97, 0.96), 1.0, false)


class MapPin extends Control:
	var pin_color := Color(1.0, 0.68, 0.32)

	func _draw() -> void:
		var outline := PackedVector2Array([
			Vector2(10.0, 27.0), Vector2(4.0, 18.0), Vector2(1.0, 13.0),
			Vector2(1.0, 9.0), Vector2(2.0, 5.0), Vector2(6.0, 1.0),
			Vector2(10.0, 0.0), Vector2(14.0, 1.0), Vector2(18.0, 5.0),
			Vector2(19.0, 9.0), Vector2(19.0, 13.0), Vector2(16.0, 18.0),
		])
		draw_colored_polygon(outline, Color(0.012, 0.032, 0.042, 1.0))
		var fill := PackedVector2Array([
			Vector2(10.0, 23.0), Vector2(6.0, 16.0), Vector2(3.0, 12.0),
			Vector2(3.0, 9.0), Vector2(4.0, 6.0), Vector2(7.0, 3.0),
			Vector2(10.0, 2.0), Vector2(13.0, 3.0), Vector2(16.0, 6.0),
			Vector2(17.0, 9.0), Vector2(17.0, 12.0), Vector2(14.0, 16.0),
		])
		draw_colored_polygon(fill, pin_color)
		draw_circle(Vector2(10.0, 9.0), 3.1, Color(0.012, 0.032, 0.042, 1.0))
		draw_circle(Vector2(10.0, 9.0), 1.5, Color(0.94, 0.97, 0.96))


class TaskLocationMarker extends Control:
	const MARKER_SIZE := Vector2(40.0, 54.0)
	const DARK := Color(0.012, 0.032, 0.042, 1.0)
	const ACCENT := Color(1.0, 0.68, 0.32, 1.0)
	const PALE := Color(0.96, 0.985, 1.0, 1.0)
	var _pulse_phase := 0.0

	func _ready() -> void:
		custom_minimum_size = MARKER_SIZE
		size = MARKER_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		_pulse_phase = fposmod(_pulse_phase + delta * 2.2, TAU)
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(MARKER_SIZE.x * 0.5, 18.0)
		var pulse := (sin(_pulse_phase) + 1.0) * 0.5
		draw_arc(center, 13.0 + pulse * 4.0, 0.0, TAU, 28, Color(ACCENT, 0.16 + (1.0 - pulse) * 0.16), 1.5, false)
		var outline := PackedVector2Array([
			Vector2(20.0, 52.0), Vector2(14.0, 42.0), Vector2(7.0, 33.0),
			Vector2(4.0, 27.0), Vector2(4.0, 20.0), Vector2(6.0, 14.0),
			Vector2(11.0, 8.0), Vector2(17.0, 5.0), Vector2(20.0, 4.0),
			Vector2(23.0, 5.0), Vector2(29.0, 8.0), Vector2(34.0, 14.0),
			Vector2(36.0, 20.0), Vector2(36.0, 27.0), Vector2(33.0, 33.0),
			Vector2(26.0, 42.0),
		])
		draw_colored_polygon(outline, DARK)
		draw_circle(center, 11.0, ACCENT)
		draw_circle(center, 7.5, DARK)
		draw_string(ThemeDB.fallback_font, Vector2(18.0, 23.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, PALE)


class InventoryCell extends PanelContainer:
	const CELL_GOLD := Color(1.0, 0.78, 0.38)
	const CELL_PALE := Color(0.96, 0.985, 1.0)
	const CELL_MUTED := Color(0.7, 0.8, 0.83)
	const CELL_SURFACE := Color(0.025, 0.055, 0.074)
	const CELL_EDGE := Color(0.34, 0.51, 0.55)
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
		var stack := VBoxContainer.new()
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 0)
		add_child(stack)
		_badge = Label.new()
		_badge.add_theme_font_size_override("font_size", 9)
		_badge.add_theme_color_override("font_color", CELL_MUTED)
		_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stack.add_child(_badge)
		var icon_center := CenterContainer.new()
		icon_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon = TextureRect.new()
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_icon.custom_minimum_size = Vector2.ONE * icon_size
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_center.add_child(_icon)
		stack.add_child(icon_center)
		_name = Label.new()
		_name.add_theme_font_size_override("font_size", 8)
		_name.add_theme_color_override("font_color", CELL_PALE)
		_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name.clip_text = true
		stack.add_child(_name)
		_refresh()

	func set_item(item: StringName, item_short: String, tint: Color, selected: bool, texture: Texture2D = null) -> void:
		item_id = item
		short_label = item_short
		icon_color = tint
		is_selected = selected
		item_texture = texture
		_refresh()

	func _refresh() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = CELL_SURFACE if not is_selected else Color(0.105, 0.148, 0.151)
		style.border_color = CELL_GOLD if is_selected else CELL_EDGE
		style.set_border_width_all(1 if not is_selected else 2)
		style.set_corner_radius_all(0)
		style.content_margin_left = 3.0
		style.content_margin_right = 3.0
		style.content_margin_top = 2.0
		style.content_margin_bottom = 2.0
		add_theme_stylebox_override("panel", style)
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
		preview.custom_minimum_size = Vector2(116.0, 48.0)
		var preview_style := StyleBoxFlat.new()
		preview_style.bg_color = Color(0.025, 0.055, 0.074, 0.98)
		preview_style.border_color = icon_color
		preview_style.set_border_width_all(1)
		preview_style.set_corner_radius_all(0)
		preview.add_theme_stylebox_override("panel", preview_style)
		var preview_label := Label.new()
		preview_label.text = short_label
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.add_theme_font_size_override("font_size", 10)
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


func _process(_delta: float) -> void:
	_update_world_task_markers()
	if _active_overlay == &"map":
		_update_map_markers()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root)
	_world_task_marker_layer = Control.new()
	_world_task_marker_layer.name = "WorldTaskMarkers"
	_world_task_marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_task_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_world_task_marker_layer)
	_build_mission_panel()
	_build_top_controls()
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
	var panel := PanelContainer.new()
	_mission_panel = panel
	panel.name = "MissionTracker"
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 18.0
	panel.offset_top = 18.0
	panel.offset_right = 360.0
	panel.offset_bottom = 198.0 + maxi(_task_entries.size() - 3, 0) * 32.0
	var mission_style := _panel_style(SURFACE, Color(1.0, 0.78, 0.38, 0.94), 13.0)
	mission_style.border_width_left = 3
	panel.add_theme_stylebox_override("panel", mission_style)
	_root.add_child(panel)
	var stack := VBoxContainer.new()
	_mission_stack = stack
	stack.add_theme_constant_override("separation", 7)
	panel.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_child(_label("ACTIVE MISSION  /  EREBOS", 10, GOLD))
	heading.add_spacer(false)
	_mission_progress_label = _label("00 / 02", 10, MUTED)
	heading.add_child(_mission_progress_label)
	stack.add_child(heading)
	stack.add_child(_label("Restore Ship & Study Erebos", 17, PALE))
	_mission_progress_bar = ProgressBar.new()
	_mission_progress_bar.min_value = 0.0
	_mission_progress_bar.max_value = maxi(_task_entries.size(), 1)
	_mission_progress_bar.show_percentage = false
	_mission_progress_bar.custom_minimum_size.y = 6.0
	_mission_progress_bar.add_theme_stylebox_override("background", _panel_style(Color(0.09, 0.16, 0.17), Color(0.09, 0.16, 0.17), 0.0))
	_mission_progress_bar.add_theme_stylebox_override("fill", _panel_style(GOLD, GOLD, 0.0))
	stack.add_child(_mission_progress_bar)
	for entry in _task_entries:
		_add_mission_row(entry)


func _add_mission_row(entry: Dictionary) -> void:
	if not is_instance_valid(_mission_stack):
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	var mark := _label("□", 14, MUTED)
	mark.custom_minimum_size.x = 18.0
	row.add_child(mark)
	var objective := _label(str(entry.get("title", "Ship work order")), 12, PALE)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(objective)
	_mission_stack.add_child(row)
	_mission_rows[entry["id"]] = {"mark": mark, "label": objective}


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
	controls.anchor_left = 1.0
	controls.anchor_right = 1.0
	controls.anchor_top = 0.0
	controls.anchor_bottom = 0.0
	controls.offset_left = -318.0
	controls.offset_top = 18.0
	controls.offset_right = -18.0
	controls.offset_bottom = 70.0
	controls.add_theme_constant_override("separation", 6)
	_root.add_child(controls)
	controls.add_child(_navigation_button(&"map", "SHIP MAP", "M", _open_map))
	controls.add_child(_navigation_button(&"inventory", "INVENTORY", "I", _open_inventory))
	controls.add_child(_navigation_button(&"settings", "SETTINGS", "ESC", _open_settings))


func _build_context_prompt() -> void:
	_context_prompt = PanelContainer.new()
	_context_prompt.name = "InteractionPrompt"
	_context_prompt.anchor_left = 0.5
	_context_prompt.anchor_right = 0.5
	_context_prompt.anchor_top = 1.0
	_context_prompt.anchor_bottom = 1.0
	_context_prompt.offset_left = -280.0
	_context_prompt.offset_top = -128.0
	_context_prompt.offset_right = 280.0
	_context_prompt.offset_bottom = -88.0
	_context_prompt.visible = false
	_context_prompt.add_theme_stylebox_override("panel", _panel_style(SURFACE, ORANGE, 9.0))
	_root.add_child(_context_prompt)
	_context_label = _label("", 11, PALE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_context_prompt.add_child(_context_label)


func _build_hotbar() -> void:
	var bar := HBoxContainer.new()
	bar.name = "Hotbar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 5)
	var frame := PanelContainer.new()
	frame.name = "QuickbarFrame"
	frame.anchor_left = 0.5
	frame.anchor_right = 0.5
	frame.anchor_top = 1.0
	frame.anchor_bottom = 1.0
	frame.offset_left = -275.0
	frame.offset_top = -82.0
	frame.offset_right = 275.0
	frame.offset_bottom = -12.0
	frame.add_theme_stylebox_override("panel", _panel_style(SURFACE, EDGE, 6.0))
	_root.add_child(frame)
	frame.add_child(bar)
	for index in range(9):
		var cell := InventoryCell.new()
		cell.custom_minimum_size = Vector2(54.0, 54.0)
		cell.configure(&"hotbar", index, _hotbar_items[index], _short_item_name(_hotbar_items[index]), _item_color(_hotbar_items[index]), index == _selected_hotbar_index, "", _item_icon_texture(_hotbar_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		bar.add_child(cell)
		_hotbar_slots.append(cell)


func _create_map_overlay() -> void:
	var modal := _create_modal_shell("SHIP MAP", Vector2(1060.0, 620.0))
	_overlay_nodes[&"map"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	var map_wrapper := CenterContainer.new()
	map_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_wrapper.custom_minimum_size = Vector2(1000.0, 500.0)
	content.add_child(map_wrapper)
	_map_surface = Control.new()
	_map_surface.custom_minimum_size = Vector2(980.0, 490.0)
	_map_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_wrapper.add_child(_map_surface)
	var image := TextureRect.new()
	image.texture = MAP_TEXTURE
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_surface.add_child(image)
	_map_player_marker = _map_marker(GOLD, true)
	_map_surface.add_child(_map_player_marker)
	for entry in _task_entries:
		_add_map_task_marker(entry)
	var map_legend := HBoxContainer.new()
	map_legend.add_theme_constant_override("separation", 14)
	map_legend.add_child(_label("THURA  /  CURRENT POSITION", 10, GOLD))
	map_legend.add_child(_label("OPEN TASK", 10, ORANGE))
	map_legend.add_child(_label("COMPLETE", 10, GREEN))
	map_legend.add_child(_label("HOVER PINS FOR DETAILS", 9, MUTED))
	map_legend.add_spacer(false)
	map_legend.add_child(_label("M OR ESC  /  CLOSE", 10, MUTED))
	content.add_child(map_legend)
	_update_map_markers()


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
	marker.mouse_filter = Control.MOUSE_FILTER_STOP
	marker.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	var modal := _create_modal_shell("PERSONAL LOADOUT  /  INVENTORY", Vector2(1140.0, 620.0))
	_overlay_nodes[&"inventory"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	content.add_child(columns)

	var character_panel := PanelContainer.new()
	character_panel.custom_minimum_size.x = 360.0
	character_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE_RAISED, EDGE_SOFT, 10.0))
	columns.add_child(character_panel)
	var character_stack := VBoxContainer.new()
	character_stack.add_theme_constant_override("separation", 8)
	character_panel.add_child(character_stack)
	character_stack.add_child(_label("OPERATOR  /  THURA MIN", 11, GOLD))
	var character_row := HBoxContainer.new()
	character_row.add_theme_constant_override("separation", 8)
	character_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_stack.add_child(character_row)
	var portrait := TextureRect.new()
	var portrait_texture := AtlasTexture.new()
	portrait_texture.atlas = THURA_ATLAS
	portrait_texture.region = Rect2(Vector2.ZERO, CHARACTER_FRAME_SIZE)
	portrait.texture = portrait_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(174.0, 244.0)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	character_row.add_child(portrait)
	var equipment_stack := VBoxContainer.new()
	equipment_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_stack.add_theme_constant_override("separation", 7)
	character_row.add_child(equipment_stack)
	for index in range(EQUIPMENT_SLOTS.size()):
		var cell := InventoryCell.new()
		cell.custom_minimum_size = Vector2(146.0, 48.0)
		var slot_id: StringName = EQUIPMENT_SLOTS[index]
		var item_id: StringName = _equipment_items[slot_id]
		cell.configure(&"equipment", index, item_id, _short_item_name(item_id), _item_color(item_id), false, String(EQUIPMENT_LABELS[index]), _item_icon_texture(item_id))
		cell.drop_requested.connect(_on_inventory_drop_requested)
		equipment_stack.add_child(cell)
		_equipment_cells.append(cell)

	var inventory_panel := PanelContainer.new()
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE_RAISED, EDGE_SOFT, 10.0))
	columns.add_child(inventory_panel)
	var inventory_stack := VBoxContainer.new()
	inventory_stack.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(inventory_stack)
	var cargo_heading := HBoxContainer.new()
	cargo_heading.add_child(_label("CARGO HOLD", 11, GOLD))
	cargo_heading.add_spacer(false)
	_cargo_count_label = _label("08 / 27 USED", 9, CYAN)
	cargo_heading.add_child(_cargo_count_label)
	inventory_stack.add_child(cargo_heading)
	inventory_stack.add_child(_label("DRAG ITEMS TO QUICK ACCESS OR A COMPATIBLE SLOT", 9, MUTED))
	var cargo_grid := GridContainer.new()
	cargo_grid.columns = 9
	cargo_grid.add_theme_constant_override("h_separation", 5)
	cargo_grid.add_theme_constant_override("v_separation", 5)
	inventory_stack.add_child(cargo_grid)
	for index in range(27):
		var cell := InventoryCell.new()
		cell.custom_minimum_size = Vector2(72.0, 72.0)
		cell.configure(&"storage", index, _storage_items[index], _short_item_name(_storage_items[index]), _item_color(_storage_items[index]), false, "", _item_icon_texture(_storage_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		cargo_grid.add_child(cell)
		_storage_cells.append(cell)
	inventory_stack.add_child(_label("QUICK ACCESS  /  1–9", 10, GOLD))
	var quick_grid := GridContainer.new()
	quick_grid.columns = 9
	quick_grid.add_theme_constant_override("h_separation", 5)
	inventory_stack.add_child(quick_grid)
	for index in range(9):
		var cell := InventoryCell.new()
		cell.custom_minimum_size = Vector2(72.0, 72.0)
		cell.configure(&"hotbar", index, _hotbar_items[index], _short_item_name(_hotbar_items[index]), _item_color(_hotbar_items[index]), index == _selected_hotbar_index, "", _item_icon_texture(_hotbar_items[index]))
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		quick_grid.add_child(cell)
		_inventory_hotbar_cells.append(cell)
	content.add_child(_label("Equipment is session-only. Suit Flashlight fits SUIT; handheld gear fits TOOL.", 10, MUTED))
	_refresh_inventory_cells()


func _create_settings_overlay() -> void:
	var modal := _create_modal_shell("SHIP SETTINGS", Vector2(500.0, 390.0))
	_overlay_nodes[&"settings"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	content.add_theme_constant_override("separation", 12)
	content.add_child(_label("AUDIO OUTPUT", 11, GOLD))
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	volume_row.add_child(_label("MASTER VOLUME", 11, PALE))
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 1.0
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.custom_minimum_size.y = 24.0
	var master_bus_index := AudioServer.get_bus_index("Master")
	_volume_slider.value = 100.0
	if master_bus_index >= 0:
		_volume_slider.value = 0.0 if AudioServer.is_bus_mute(master_bus_index) else AudioServer.get_bus_volume_linear(master_bus_index) * 100.0
	_volume_slider.value_changed.connect(_on_master_volume_changed)
	volume_row.add_child(_volume_slider)
	_volume_label = _label("%d%%" % roundi(_volume_slider.value), 11, CYAN)
	_volume_label.custom_minimum_size.x = 36.0
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_label)
	content.add_child(volume_row)
	content.add_child(HSeparator.new())
	content.add_child(_label("CONTROLS", 11, GOLD))
	var hints := GridContainer.new()
	hints.columns = 2
	hints.add_theme_constant_override("h_separation", 16)
	hints.add_theme_constant_override("v_separation", 9)
	hints.add_child(_key_hint("MOVE", "WASD / ARROWS"))
	hints.add_child(_key_hint("INTERACT", "E"))
	hints.add_child(_key_hint("QUICK SLOT", "1–9 / WHEEL"))
	hints.add_child(_key_hint("INVENTORY", "I"))
	hints.add_child(_key_hint("SHIP MAP", "M"))
	hints.add_child(_key_hint("SETTINGS / CLOSE", "ESC"))
	content.add_child(hints)
	content.add_spacer(false)
	content.add_child(_label("Walking pauses while these panels are open.", 10, MUTED))


func _key_hint(action_name: String, key_name: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(208.0, 28.0)
	row.add_theme_constant_override("separation", 5)
	row.add_child(_label(action_name, 10, PALE))
	row.add_spacer(false)
	var keycap := PanelContainer.new()
	keycap.add_theme_stylebox_override("panel", _panel_style(SURFACE, EDGE, 5.0))
	var key_label := _label(key_name, 9, CYAN)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.add_child(key_label)
	row.add_child(keycap)
	return row


func _create_modal_shell(title: String, minimum_size: Vector2) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	_root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.018, 0.032, 0.78)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var frame := PanelContainer.new()
	frame.custom_minimum_size = minimum_size
	frame.add_theme_stylebox_override("panel", _panel_style(Color(0.031, 0.067, 0.086, 0.99), Color(1.0, 0.78, 0.38, 0.94), 14.0))
	center.add_child(frame)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	frame.add_child(layout)
	var heading := HBoxContainer.new()
	var title_label := _label(title, 18, PALE)
	heading.add_child(title_label)
	heading.add_spacer(false)
	var close_button := _button("×", Vector2(38.0, 36.0), GOLD)
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.pressed.connect(_close_overlay)
	heading.add_child(close_button)
	layout.add_child(heading)
	var separator := HSeparator.new()
	separator.add_theme_color_override("separator_color", Color(1.0, 0.78, 0.38, 0.52))
	layout.add_child(separator)
	var content := VBoxContainer.new()
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
	if not is_instance_valid(_map_surface):
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
		marker.pin_color = GREEN if is_complete else ORANGE
		marker.tooltip_text = ("COMPLETE  /  " if is_complete else "OPEN TASK  /  ") + str(entry.get("title", "Ship task"))
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
	_mission_progress_label.text = "%02d / %02d" % [completed_count, total]
	_mission_progress_label.add_theme_color_override("font_color", GREEN if completed_count == total else MUTED)
	_mission_progress_bar.max_value = maxi(total, 1)
	_mission_progress_bar.value = completed_count
	for task_id in _mission_rows:
		var row: Dictionary = _mission_rows[task_id]
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		row["mark"].text = "✓" if is_complete else "□"
		row["mark"].add_theme_color_override("font_color", GREEN if is_complete else MUTED)
		row["label"].add_theme_color_override("font_color", GREEN if is_complete else PALE)
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
	_context_label.text = text
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
	for name in _overlay_nodes:
		_overlay_nodes[name].visible = name == overlay_name
	var was_closed := _active_overlay == &""
	_active_overlay = overlay_name
	if was_closed:
		_context_prompt.visible = false
		modal_state_changed.emit(true)
	if overlay_name == &"map":
		_update_map_markers()


func _close_overlay() -> void:
	if _active_overlay == &"":
		return
	for overlay in _overlay_nodes.values():
		overlay.visible = false
	_active_overlay = &""
	_context_prompt.visible = false
	modal_state_changed.emit(false)


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
	button.custom_minimum_size = Vector2(92.0, 52.0)
	button.tooltip_text = "%s  /  %s" % [title, shortcut]
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _nav_button_style(GOLD, false))
	button.add_theme_stylebox_override("hover", _nav_button_style(CYAN, true))
	button.add_theme_stylebox_override("pressed", _nav_button_style(CYAN, true))
	button.add_theme_stylebox_override("focus", _nav_button_style(GOLD, true))
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 5)
	var icon := PixelIcon.new()
	icon.icon_kind = icon_kind
	icon.tint = GOLD
	icon.custom_minimum_size = Vector2(19.0, 19.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)
	var labels := VBoxContainer.new()
	labels.add_theme_constant_override("separation", 0)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_label := _label(title, 10, PALE)
	var shortcut_label := _label(shortcut, 8, MUTED)
	labels.add_child(title_label)
	labels.add_child(shortcut_label)
	layout.add_child(labels)
	button.add_child(layout)
	button.pressed.connect(callback)
	return button


func _nav_button_style(accent: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE if not highlighted else SURFACE_HOVER
	style.border_color = Color(accent.r, accent.g, accent.b, 1.0 if highlighted else 0.82)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(0)
	style.content_margin_left = 6.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String, minimum_size: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", PALE)
	button.add_theme_stylebox_override("normal", _button_style(accent, false))
	button.add_theme_stylebox_override("hover", _button_style(accent, true))
	button.add_theme_stylebox_override("pressed", _button_style(accent, true))
	button.add_theme_stylebox_override("focus", _button_style(accent, true))
	return button


func _button_style(accent: Color, highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SURFACE_RAISED if not highlighted else SURFACE_HOVER
	style.border_color = accent if highlighted else Color(accent.r, accent.g, accent.b, 0.86)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(0)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _panel_style(background: Color, border: Color, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
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
	var icon := AtlasTexture.new()
	icon.atlas = item["texture"]
	icon.region = item["icon_region"]
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
	if event.keycode == KEY_ESCAPE:
		if _active_overlay != &"":
			_close_overlay()
		else:
			_open_settings()
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


func _select_hotbar(index: int) -> void:
	if index < 0 or index >= _hotbar_items.size():
		return
	_selected_hotbar_index = index
	_refresh_hotbar()
	_refresh_inventory_cells()
