class_name WalkHud
extends CanvasLayer

signal modal_state_changed(is_open: bool)

const PIXEL_THEME := preload("res://themes/ship_pixel_theme.tres")
const MAP_CONTENT_VISIBLE := true
const MAP_FLOOR_TEXTURE := preload("res://art/concepts/Refined pixel-art spacecraft floor.png")
const MAP_WALL_TEXTURE := preload("res://art/concepts/ship_walls_valkyrie.png")
const THURA_ATLAS := preload("res://art/characters/runtime/thura_walk_4dir.png")
const CHARACTER_FRAME_SIZE := Vector2(313.5, 313.5)

const GOLD := Color(1.0, 0.78, 0.38)
const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.7, 0.8, 0.83)
const CYAN := Color(0.36, 0.9, 1.0)
const ORANGE := Color(1.0, 0.68, 0.32)
const GREEN := Color(0.48, 0.93, 0.64)
const SURFACE := Color(0.035, 0.055, 0.085)
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
			&"profile":
				_block(origin, unit, 5, 3, 14, 9, tint)
				_block(origin, unit, 3, 5, 2, 5, tint.darkened(0.25))
				_block(origin, unit, 19, 5, 2, 5, tint.darkened(0.25))
				_block(origin, unit, 9, 12, 6, 3, tint)
				_block(origin, unit, 10, 15, 4, 3, tint.darkened(0.2))
				_block(origin, unit, 7, 18, 10, 3, tint)
				_block(origin, unit, 10, 5, 4, 4, ICON_PALE)
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


class TaskRowIcon extends Control:
	var is_equipment_task: bool = false
	var is_complete: bool = false
	var accent_color: Color = Color(1.0, 0.68, 0.32, 1.0)

	func _ready() -> void:
		custom_minimum_size = Vector2(16.0, 16.0)
		size = Vector2(16.0, 16.0)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = (size * 0.5).floor()
		draw_rect(Rect2(c - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), Color(0.015, 0.032, 0.046, 0.96), true)
		var border_col: Color = Color(0.48, 0.93, 0.64, 0.95) if is_complete else (Color(0.36, 0.90, 1.0, 0.95) if is_equipment_task else accent_color)
		draw_rect(Rect2(c - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), border_col, false, 1.0)
		if is_complete:
			# Pixel-aligned checkmark
			draw_line(c + Vector2(-3.0, 0.0), c + Vector2(-1.0, 2.5), border_col, 1.6, false)
			draw_line(c + Vector2(-1.0, 2.5), c + Vector2(3.5, -2.5), border_col, 1.6, false)
		elif is_equipment_task:
			# Pixel-aligned gear/diamond icon for equipment-finding tasks
			var d_pts: PackedVector2Array = PackedVector2Array([
				c + Vector2(0.0, -4.0),
				c + Vector2(4.0, 0.0),
				c + Vector2(0.0, 4.0),
				c + Vector2(-4.0, 0.0),
			])
			draw_colored_polygon(d_pts, Color(0.36, 0.90, 1.0, 0.95))
			draw_rect(Rect2(c - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(0.96, 0.985, 1.0, 1.0), true)
		else:
			# Pixel-aligned exclamation mark for standard objectives
			draw_rect(Rect2(c + Vector2(-1.0, -4.0), Vector2(2.0, 5.0)), accent_color, true)
			draw_rect(Rect2(c + Vector2(-1.0, 2.0), Vector2(2.0, 2.0)), accent_color, true)


class AchievementMedalIcon extends Control:
	var medal_color: Color = Color(1.0, 0.78, 0.38, 1.0)
	var unlocked: bool = true

	func _ready() -> void:
		custom_minimum_size = Vector2(20.0, 20.0)
		size = Vector2(20.0, 20.0)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c: Vector2 = (size * 0.5).floor()
		var col: Color = medal_color if unlocked else Color(0.28, 0.36, 0.40, 0.55)
		draw_rect(Rect2(c + Vector2(-4.0, -6.0), Vector2(8.0, 6.0)), col, true)
		draw_rect(Rect2(c + Vector2(-6.0, -5.0), Vector2(2.0, 3.0)), col.darkened(0.2), true)
		draw_rect(Rect2(c + Vector2(4.0, -5.0), Vector2(2.0, 3.0)), col.darkened(0.2), true)
		draw_rect(Rect2(c + Vector2(-1.0, 0.0), Vector2(2.0, 4.0)), col, true)
		draw_rect(Rect2(c + Vector2(-4.0, 4.0), Vector2(8.0, 2.0)), col, true)


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
			draw_rect(Rect2(Vector2(9.0, 6.5), Vector2(2.0, 4.5)), Color(0.96, 0.985, 1.0), true)
			draw_rect(Rect2(Vector2(9.0, 12.0), Vector2(2.0, 1.8)), Color(0.96, 0.985, 1.0), true)


class TaskLocationMarker extends Control:
	const MARKER_SIZE := Vector2(32.0, 42.0)
	const DARK := Color(0.012, 0.032, 0.042, 1.0)
	const ACCENT_TASK := Color(1.0, 0.68, 0.32, 1.0)
	const ACCENT_GEAR := Color(0.36, 0.90, 1.0, 1.0)
	const PALE := Color(0.96, 0.985, 1.0, 1.0)
	var is_equipment_task: bool = false
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
		var center := Vector2(MARKER_SIZE.x * 0.5, 14.0)
		var accent: Color = ACCENT_GEAR if is_equipment_task else ACCENT_TASK
		var pulse := (sin(_pulse_phase) + 1.0) * 0.5
		draw_arc(center, 10.5 + pulse * 3.5, 0.0, TAU, 24, Color(accent, 0.18 + (1.0 - pulse) * 0.18), 1.5, false)
		var outline := PackedVector2Array([
			Vector2(16.0, 40.0), Vector2(11.0, 32.0), Vector2(5.5, 25.0),
			Vector2(3.5, 20.0), Vector2(3.5, 14.0), Vector2(5.5, 9.5),
			Vector2(9.5, 5.5), Vector2(13.5, 3.5), Vector2(16.0, 3.0),
			Vector2(18.5, 3.5), Vector2(22.5, 5.5), Vector2(26.5, 9.5),
			Vector2(28.5, 14.0), Vector2(28.5, 20.0), Vector2(26.5, 25.0),
			Vector2(21.0, 32.0),
		])
		draw_colored_polygon(outline, DARK)
		draw_circle(center, 9.0, accent)
		draw_circle(center, 6.2, DARK)
		if is_equipment_task:
			# Centered pixel diamond/gear badge for equipment tasks
			var d_pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0.0, -4.0),
				center + Vector2(4.0, 0.0),
				center + Vector2(0.0, 4.0),
				center + Vector2(-4.0, 0.0),
			])
			draw_colored_polygon(d_pts, accent)
			draw_rect(Rect2(center - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), PALE, true)
		else:
			# Pixel-perfect centered exclamation mark
			draw_rect(Rect2(center + Vector2(-1.0, -4.5), Vector2(2.0, 5.5)), PALE, true)
			draw_rect(Rect2(center + Vector2(-1.0, 2.2), Vector2(2.0, 2.0)), PALE, true)


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
		stack.add_theme_constant_override("separation", 1)
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
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.custom_minimum_size = Vector2.ONE * icon_size
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_center.add_child(_icon)
		stack.add_child(icon_center)
		_name = Label.new()
		_name.add_theme_font_size_override("font_size", 9)
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
		preview.custom_minimum_size = Vector2(156.0, 48.0)
		preview.theme = PIXEL_THEME
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var preview_style := PIXEL_THEME.get_stylebox("panel", "PanelContainer")
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


class MobileTouchJoystick extends Control:
	signal vector_changed(vec: Vector2)

	var _touch_index: int = -1
	var _mouse_dragging: bool = false
	var _knob_offset: Vector2 = Vector2.ZERO
	var _output_vector: Vector2 = Vector2.ZERO
	var _max_radius: float = 48.0

	func _ready() -> void:
		custom_minimum_size = Vector2(148.0, 148.0)
		size = Vector2(148.0, 148.0)
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE

	func _notification(what: int) -> void:
		if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
			_reset_stick()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			var st: InputEventScreenTouch = event as InputEventScreenTouch
			if st.pressed and _touch_index == -1:
				_touch_index = st.index
				_update_from_local_pos(st.position)
				accept_event()
			elif not st.pressed and st.index == _touch_index:
				_reset_stick()
				accept_event()
		elif event is InputEventScreenDrag:
			var sd: InputEventScreenDrag = event as InputEventScreenDrag
			if sd.index == _touch_index:
				_update_from_local_pos(sd.position)
				accept_event()
		elif event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					_mouse_dragging = true
					_update_from_local_pos(mb.position)
					accept_event()
				elif _mouse_dragging:
					_reset_stick()
					accept_event()
		elif event is InputEventMouseMotion:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			if _mouse_dragging:
				_update_from_local_pos(mm.position)
				accept_event()

	func _input(event: InputEvent) -> void:
		if _touch_index != -1 and event is InputEventScreenTouch:
			var st: InputEventScreenTouch = event as InputEventScreenTouch
			if not st.pressed and st.index == _touch_index:
				_reset_stick()
		elif _mouse_dragging and event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
				_reset_stick()

	func _update_from_local_pos(local_pos: Vector2) -> void:
		var center: Vector2 = size * 0.5
		_max_radius = maxf(28.0, minf(size.x, size.y) * 0.34)
		var delta_vec: Vector2 = local_pos - center
		var dist: float = delta_vec.length()
		if dist > _max_radius:
			_knob_offset = (delta_vec / dist) * _max_radius
		else:
			_knob_offset = delta_vec
		var norm: Vector2 = _knob_offset / _max_radius
		if norm.length() < 0.14:
			_output_vector = Vector2.ZERO
		else:
			_output_vector = norm.limit_length(1.0)
		_apply_joystick_vector(_output_vector)
		vector_changed.emit(_output_vector)
		queue_redraw()

	func _reset_stick() -> void:
		_touch_index = -1
		_mouse_dragging = false
		_knob_offset = Vector2.ZERO
		_output_vector = Vector2.ZERO
		_apply_joystick_vector(Vector2.ZERO)
		vector_changed.emit(Vector2.ZERO)
		queue_redraw()

	func _apply_joystick_vector(vec: Vector2) -> void:
		Engine.set_meta(&"echoes_mobile_joystick_vec", vec)
		var ib := get_tree().root.get_node_or_null("InputBindings") if get_tree() != null and get_tree().root != null else null
		if ib != null and ib.has_method("set_mobile_joystick_vector"):
			ib.call("set_mobile_joystick_vector", vec)
		else:
			_set_axis_action(&"move_left", maxf(0.0, -vec.x))
			_set_axis_action(&"move_right", maxf(0.0, vec.x))
			_set_axis_action(&"move_up", maxf(0.0, -vec.y))
			_set_axis_action(&"move_down", maxf(0.0, vec.y))

	func _set_axis_action(action: StringName, strength: float) -> void:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if strength > 0.12:
			Input.action_press(action, clampf(strength, 0.0, 1.0))
		elif Input.is_action_pressed(action):
			Input.action_release(action)

	func _draw() -> void:
		var center: Vector2 = (size * 0.5).floor()
		var outer_r: float = minf(size.x, size.y) * 0.45
		var active: bool = _output_vector.length_squared() > 0.01
		var ring_col: Color = Color(1.0, 0.78, 0.38, 0.92) if active else Color(0.36, 0.90, 1.0, 0.62)
		draw_circle(center, outer_r, Color(0.012, 0.028, 0.042, 0.78))
		draw_arc(center, outer_r, 0.0, TAU, 36, ring_col, 2.0, false)
		draw_arc(center, outer_r * 0.52, 0.0, TAU, 24, Color(0.24, 0.39, 0.43, 0.45), 1.0, false)
		for dir_vec in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var p1: Vector2 = center + dir_vec * (outer_r - 9.0)
			var p2: Vector2 = center + dir_vec * (outer_r - 3.0)
			draw_line(p1, p2, Color(0.70, 0.80, 0.83, 0.65), 2.0, false)
		var knob_pos: Vector2 = center + _knob_offset
		if active:
			draw_line(center, knob_pos, Color(0.36, 0.90, 1.0, 0.45), 2.5, false)
		draw_circle(knob_pos, 22.0, Color(0.025, 0.055, 0.078, 0.95))
		draw_circle(knob_pos, 17.0, Color(1.0, 0.78, 0.38, 0.92) if active else Color(0.36, 0.90, 1.0, 0.82))
		draw_circle(knob_pos, 7.0, Color(0.96, 0.985, 1.0, 0.95))


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
var _mission_summary_label: Label
var _cargo_count_label: Label
var _context_prompt: PanelContainer
var _context_label: Label
var _equipped_status_label: Label
var _story_act_label: Label
var _unlock_toast_panel: PanelContainer
var _unlock_toast_badge: Label
var _unlock_toast_icon: TextureRect
var _unlock_toast_title: Label
var _unlock_toast_subtitle: Label
var _unlock_toast_timer: float = 0.0
var _achievement_toast_panel: PanelContainer
var _achievement_toast_medal: AchievementMedalIcon
var _achievement_toast_badge: Label
var _achievement_toast_title: Label
var _achievement_toast_subtitle: Label
var _achievement_toast_timer: float = 0.0
var _achievement_toast_queue: Array[Dictionary] = []
var _achievement_toast_tween: Tween
var _unlocked_achievements: Dictionary = {}
var _achievement_filter: StringName = &"all"
var _profile_rank_label: Label
var _profile_score_label: Label
var _profile_progress_bar: ProgressBar
var _profile_stats_label: Label
var _profile_achievements_list: VBoxContainer
var _profile_filter_buttons: Dictionary = {}
var _inventory_ach_summary_label: Label
var _inventory_ach_bar: ProgressBar
var _hotbar_items: Array[StringName] = [
	&"",
	&"",
	&"",
	&"",
	&"",
	&"",
	&"",
	&"",
	&"",
]
var _storage_items: Array[StringName] = []
var _equipment_items: Dictionary = {&"head": &"", &"suit": &"", &"pack": &"", &"tool": &""}
var _unlocked_items: Dictionary = {}
var _collected_logs: Dictionary = {}
var _current_story_act: String = "ACT I — THE LONG APPROACH"
var _item_icon_cache: Dictionary = {}
var _selected_hotbar_index := 0
var _hotbar_slots: Array = []
var _storage_cells: Array = []
var _equipment_cells: Array = []
var _inventory_hotbar_cells: Array = []
var _active_overlay: StringName = &""
var _overlay_nodes: Dictionary = {}
var _map_surface: Control
var _map_canvas: Control
var _map_floor_layer: TextureRect
var _map_wall_layer: TextureRect
var _custom_map_floor_tex: Texture2D = null
var _custom_map_wall_tex: Texture2D = null
var _show_all_active_tasks: bool = false
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
var _mobile_controls_layer: Control = null
var _mobile_joystick: MobileTouchJoystick = null
var _mobile_shoot_btn: Button = null
var _mobile_pickup_btn: Button = null
var _mobile_drop_btn: Button = null
var _dropped_world_items: Array[Dictionary] = []
var _world_dropped_canvas: Node2D = null
var _world_drop_pulse: float = 0.0
const DEV_FLICKER_STYLES: Array[StringName] = [&"erratic", &"strobe", &"brownout", &"pulse"]
const DEV_FLICKER_SPEEDS: Array[float] = [0.5, 1.0, 1.5, 2.5]
const CAMPAIGN_META_KEY: StringName = &"echoes_campaign_inventory_state"
const ALL_PROGRESSION_ITEMS: Array[StringName] = [
	&"suit_flashlight",
	&"engineering_multitool",
	&"pressure_sealant",
	&"medical_injector",
	&"mineral_survey_scanner",
	&"survey_beacon",
	&"emergency_flare",
	&"industrial_plasma_cutter",
	&"electrical_discharge_tool",
	&"captains_revolver",
]

const ACHIEVEMENTS_CATALOG: Array[Dictionary] = [
	{"id": &"cabin_may_recording", "title": "Paper Star", "desc": "Play May's transmission"},
	{"id": &"bridge_flight_piloting", "title": "Shearwater Pilot", "desc": "Evade the asteroid swarm at manual helm"},
	{"id": &"auxiliary_power", "title": "Spark in the Dark", "desc": "Restore auxiliary power"},
	{"id": &"air_filter", "title": "Breath of Asteria", "desc": "Replace air scrubber"},
	{"id": &"nutrient_flow", "title": "Greenhouse", "desc": "Restore hydroponics flow"},
	{"id": &"drone_vibration_scan", "title": "Four Pulses", "desc": "Isolate the drone signal"},
	{"id": &"landing_prep_beacons", "title": "Site K-12 Ready", "desc": "Calibrate landing beacons"},
	{"id": &"west_cyan_ore", "title": "Hollow Resonance", "desc": "Scan western crystal vein"},
	{"id": &"north_viridian_ore", "title": "Into the Breach", "desc": "Recover the plasma cutter"},
	{"id": &"cargo_breach_inspection", "title": "Broken Containment", "desc": "Inspect breached core pod"},
	{"id": &"subdeck_inventory_manifest", "title": "False Signal", "desc": "Trace Ward's lure in Sub-Deck 02 storage"},
	{"id": &"subdeck_workshop_power", "title": "Sub-Deck Spark", "desc": "Restore S04 Workshop auxiliary power"},
	{"id": &"subdeck_coolant_manifold", "title": "Coolant Routing", "desc": "Align S05 Coolant Bay valves"},
	{"id": &"subdeck_pipe_pressure", "title": "High Voltage", "desc": "Stabilize Sub-Deck 02 turbines"},
	{"id": &"subdeck_shadow_nest_check", "title": "The Shadow Nest", "desc": "Analyze the sub-hull nest"},
	{"id": &"act_v_finale_home", "title": "Earthward", "desc": "Execute final helm protocol"},
]


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
	_load_persistent_inventory_state()
	_ensure_world_dropped_canvas()
	_sync_player_equipped_item()


func _ready() -> void:
	layer = 10
	_build_ui()
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	get_viewport().size_changed.connect(_queue_resize)
	_queue_resize()


func _process(delta: float) -> void:
	_world_drop_pulse = fposmod(_world_drop_pulse + delta * 3.5, TAU)
	if is_instance_valid(_world_dropped_canvas):
		_world_dropped_canvas.queue_redraw()
	_update_world_task_markers()
	_refresh_mobile_controls()
	if _unlock_toast_timer > 0.0:
		_unlock_toast_timer = maxf(_unlock_toast_timer - delta, 0.0)
		if is_zero_approx(_unlock_toast_timer) and is_instance_valid(_unlock_toast_panel):
			_unlock_toast_panel.visible = false
	if _achievement_toast_timer > 0.0:
		_achievement_toast_timer = maxf(_achievement_toast_timer - delta, 0.0)
		if is_zero_approx(_achievement_toast_timer):
			if not _achievement_toast_queue.is_empty():
				var next_toast: Dictionary = _achievement_toast_queue.pop_front()
				_display_achievement_toast_now(next_toast["title"], next_toast["subtitle"], next_toast["badge"], next_toast["color"])
			elif is_instance_valid(_achievement_toast_panel):
				_achievement_toast_panel.visible = false
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
	_build_unlock_toast()
	_build_context_prompt()
	_build_hotbar()
	_build_mobile_touch_controls()
	_create_map_overlay()
	for entry in _task_entries:
		_add_world_task_marker(entry)
	_create_inventory_overlay()
	_create_profile_overlay()
	_create_settings_overlay()
	_refresh_mission_panel()
	_refresh_inventory_cells()
	_refresh_profile_overlay()
	_refresh_hotbar()
	_refresh_mobile_controls()


func _build_mission_panel() -> void:
	var panel := PanelContainer.new()
	_mission_panel = panel
	panel.name = "MissionTracker"
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 16.0
	panel.offset_top = 16.0
	panel.offset_right = 400.0
	panel.offset_bottom = 126.0
	var mission_style := _panel_style(SURFACE, Color(1.0, 0.78, 0.38, 0.94), 10.0)
	panel.add_theme_stylebox_override("panel", mission_style)
	_root.add_child(panel)
	var stack := VBoxContainer.new()
	_mission_stack = stack
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)
	var heading := HBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	var hdr_lbl: Label = _label("CURRENT OBJECTIVE", 9, Color(0.24, 0.95, 0.54))
	hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(hdr_lbl)
	heading.add_spacer(false)
	_mission_progress_label = _label("STEP 01 / 01", 9, Color(0.48, 0.93, 0.64))
	_mission_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_mission_progress_label)
	stack.add_child(heading)
	_mission_progress_bar = ProgressBar.new()
	_mission_progress_bar.min_value = 0.0
	_mission_progress_bar.max_value = maxi(_task_entries.size(), 1)
	_mission_progress_bar.show_percentage = false
	_mission_progress_bar.custom_minimum_size.y = 5.0
	_mission_progress_bar.add_theme_stylebox_override("background", _panel_style(Color(0.02, 0.05, 0.07), Color(0.12, 0.22, 0.25), 0.0))
	_mission_progress_bar.add_theme_stylebox_override("fill", _panel_style(Color(0.24, 0.95, 0.54), Color(0.24, 0.95, 0.54), 0.0))
	stack.add_child(_mission_progress_bar)
	_story_act_label = _label("%s  //  GEAR %02d/10  ·  LOGS %d/8" % [_current_story_act, _unlocked_items.size(), _collected_logs.size()], 8, CYAN)
	_story_act_label.clip_text = true
	stack.add_child(_story_act_label)
	for entry in _task_entries:
		_add_mission_row(entry)
	_mission_summary_label = _label("", 8, MUTED)
	_mission_summary_label.clip_text = true
	_mission_summary_label.visible = false
	stack.add_child(_mission_summary_label)


func _is_equipment_task_entry(entry: Dictionary) -> bool:
	if bool(entry.get("is_equipment_task", false)):
		return true
	var reward_id: StringName = StringName(entry.get("reward_item", &""))
	return reward_id != &""


func _add_mission_row(entry: Dictionary) -> void:
	if not is_instance_valid(_mission_stack):
		return
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 20.0
	row.add_theme_constant_override("separation", 6)

	var is_eq: bool = _is_equipment_task_entry(entry)
	var row_icon := TaskRowIcon.new()
	row_icon.is_equipment_task = is_eq
	row.add_child(row_icon)

	var tag_text: String = str(entry.get("marker_label", "TASK")).to_upper()
	var tag: Label = _label("[%s]" % tag_text, 9, CYAN if is_eq else GOLD)
	tag.custom_minimum_size.x = 76.0
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.clip_text = true
	row.add_child(tag)

	var title_text: String = str(entry.get("title", "Ship work order"))
	if title_text.begins_with("Amara: "):
		title_text = title_text.substr(7)
	var objective: Label = _label(title_text, 9, PALE)
	objective.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective.clip_text = true
	row.add_child(objective)

	var status: Label = _label("GEAR" if is_eq else "NEXT", 8, CYAN if is_eq else ORANGE)
	status.custom_minimum_size.x = 42.0
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(status)

	_mission_stack.add_child(row)
	_mission_rows[entry["id"]] = {
		"row": row,
		"icon": row_icon,
		"mark": status,
		"label": objective,
		"tag": tag,
		"is_eq": is_eq,
	}


func add_task_entry(entry: Dictionary) -> void:
	var task_id := StringName(entry.get("id", &""))
	if task_id == &"" or _task_completed.has(task_id):
		return
	var task_copy := entry.duplicate(true)
	task_copy["id"] = task_id
	_task_entries.append(task_copy)
	_task_completed[task_id] = false
	_add_mission_row(task_copy)
	if is_instance_valid(_mission_summary_label) and _mission_summary_label.get_parent() == _mission_stack:
		_mission_stack.move_child(_mission_summary_label, _mission_stack.get_child_count() - 1)
	_add_map_task_marker(task_copy)
	_add_world_task_marker(task_copy)
	_refresh_mission_panel()


func _build_unlock_toast() -> void:
	# Keep notifications in the clear upper-right strip below the navigation controls.
	_unlock_toast_panel = PanelContainer.new()
	_unlock_toast_panel.name = "EquipmentUnlockToast"
	_unlock_toast_panel.anchor_left = 1.0
	_unlock_toast_panel.anchor_right = 1.0
	_unlock_toast_panel.anchor_top = 0.0
	_unlock_toast_panel.anchor_bottom = 0.0
	_unlock_toast_panel.offset_left = -376.0
	_unlock_toast_panel.offset_right = -16.0
	_unlock_toast_panel.offset_top = 96.0
	_unlock_toast_panel.offset_bottom = 162.0
	_unlock_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlock_toast_panel.visible = false
	_unlock_toast_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.010, 0.032, 0.052, 0.96), CYAN, 8.0))
	_root.add_child(_unlock_toast_panel)
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlock_toast_panel.add_child(hbox)
	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(42.0, 42.0)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.06, 0.09, 0.98), CYAN, 3.0))
	hbox.add_child(icon_box)
	_unlock_toast_icon = TextureRect.new()
	_unlock_toast_icon.custom_minimum_size = Vector2(34.0, 34.0)
	_unlock_toast_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_unlock_toast_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_unlock_toast_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_unlock_toast_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.add_child(_unlock_toast_icon)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlock_toast_badge = _label("[ GEAR UNLOCKED // TACTICAL LOADOUT ]", 8, CYAN)
	_unlock_toast_badge.clip_text = true
	_unlock_toast_title = _label("EQUIPMENT ACQUIRED", 10, GOLD)
	_unlock_toast_title.clip_text = true
	_unlock_toast_subtitle = _label("Added to active loadout", 9, PALE)
	_unlock_toast_subtitle.clip_text = true
	vbox.add_child(_unlock_toast_badge)
	vbox.add_child(_unlock_toast_title)
	vbox.add_child(_unlock_toast_subtitle)
	hbox.add_child(vbox)

	# Minimalist achievement pop-up toast
	_achievement_toast_panel = PanelContainer.new()
	_achievement_toast_panel.name = "AchievementUnlockToast"
	_achievement_toast_panel.anchor_left = 1.0
	_achievement_toast_panel.anchor_right = 1.0
	_achievement_toast_panel.anchor_top = 0.0
	_achievement_toast_panel.anchor_bottom = 0.0
	_achievement_toast_panel.offset_left = -276.0
	_achievement_toast_panel.offset_right = -16.0
	_achievement_toast_panel.offset_top = 96.0
	_achievement_toast_panel.offset_bottom = 146.0
	_achievement_toast_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_achievement_toast_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_achievement_toast_panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_open_profile()
	)
	_achievement_toast_panel.visible = false
	_achievement_toast_panel.add_theme_stylebox_override("panel", _flat_box(Color(0.02, 0.032, 0.048, 0.94), GOLD, 12.0, 8.0, 1))
	_root.add_child(_achievement_toast_panel)
	var ach_hbox := HBoxContainer.new()
	ach_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ach_hbox.add_theme_constant_override("separation", 10)
	ach_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_achievement_toast_panel.add_child(ach_hbox)
	_achievement_toast_medal = AchievementMedalIcon.new()
	ach_hbox.add_child(_achievement_toast_medal)
	var ach_vbox := VBoxContainer.new()
	ach_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ach_vbox.add_theme_constant_override("separation", 1)
	ach_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_achievement_toast_badge = _label("ACHIEVEMENT UNLOCKED", 8, GOLD)
	_achievement_toast_badge.clip_text = true
	_achievement_toast_title = _label("PAPER STAR", 10, PALE)
	_achievement_toast_title.clip_text = true
	ach_vbox.add_child(_achievement_toast_badge)
	ach_vbox.add_child(_achievement_toast_title)
	ach_hbox.add_child(ach_vbox)


func _build_top_controls() -> void:
	var controls := HBoxContainer.new()
	controls.name = "TopRightControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.offset_left = -760.0
	controls.offset_top = 18.0
	controls.offset_right = -18.0
	controls.offset_bottom = 82.0
	controls.add_theme_constant_override("separation", 8)
	_root.add_child(controls)
	controls.add_child(_navigation_button(&"map", "SHIP MAP", "M", _open_map))
	controls.add_child(_navigation_button(&"inventory", "INVENTORY", "I", _open_inventory))
	controls.add_child(_navigation_button(&"profile", "PROFILE", "P", _open_profile))
	controls.add_child(_navigation_button(&"settings", "SETTINGS", "ESC", _open_settings))
	controls.add_child(_navigation_button(&"dev", "DEV MENU", "F3", _toggle_dev_menu))

func _build_context_prompt() -> void:
	_context_prompt = PanelContainer.new()
	_context_prompt.name = "InteractionPrompt"
	_context_prompt.anchor_left = 0.5
	_context_prompt.anchor_right = 0.5
	_context_prompt.anchor_top = 1.0
	_context_prompt.anchor_bottom = 1.0
	_context_prompt.offset_left = -260.0
	_context_prompt.offset_top = -174.0
	_context_prompt.offset_right = 260.0
	_context_prompt.offset_bottom = -140.0
	_context_prompt.visible = false
	var prompt_style := _panel_style(Color(0.012, 0.025, 0.038, 0.95), ORANGE, 6.0)
	_context_prompt.add_theme_stylebox_override("panel", prompt_style)
	_root.add_child(_context_prompt)
	var prompt_box := HBoxContainer.new()
	prompt_box.alignment = BoxContainer.ALIGNMENT_CENTER
	prompt_box.add_theme_constant_override("separation", 8)
	_context_prompt.add_child(prompt_box)
	var keycap := PanelContainer.new()
	keycap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var keycap_style := _panel_style(ORANGE, Color(1.0, 0.82, 0.42), 3.0)
	keycap.add_theme_stylebox_override("panel", keycap_style)
	var keycap_label := _label("E", 9, Color(0.02, 0.035, 0.05))
	keycap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap.add_child(keycap_label)
	prompt_box.add_child(keycap)
	_context_label = _label("", 10, PALE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_box.add_child(_context_label)


func _build_hotbar() -> void:
	var status_pill := PanelContainer.new()
	status_pill.name = "EquippedStatusPill"
	status_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	status_pill.offset_left = -334.0
	status_pill.offset_right = 334.0
	status_pill.offset_top = -130.0
	status_pill.offset_bottom = -104.0
	status_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_pill.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.035, 0.048, 0.90), EDGE_SOFT, 4.0))
	_root.add_child(status_pill)
	_equipped_status_label = _label("UNARMED // COMPLETE TASKS TO OBTAIN GEAR", 9, GOLD)
	_equipped_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_pill.add_child(_equipped_status_label)

	var bar := HBoxContainer.new()
	bar.name = "Hotbar"
	bar.add_theme_constant_override("separation", 4)
	var frame := PanelContainer.new()
	frame.name = "QuickbarFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	frame.offset_left = -334.0
	frame.offset_right = 334.0
	frame.offset_top = -102.0
	frame.offset_bottom = -14.0
	frame.add_theme_stylebox_override("panel", _panel_style(SURFACE, EDGE, 10.0))
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
	_sync_player_equipped_item()

func _create_map_overlay() -> void:
	var modal := _create_modal_shell("SHIP MAP", Vector2(1140, 660))
	_overlay_nodes[&"map"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	_map_surface = PanelContainer.new()
	_map_surface.name = "ShipMapViewport"
	_map_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_surface.add_theme_stylebox_override("panel", PIXEL_THEME.get_stylebox("panel", "MapViewport"))
	content.add_child(_map_surface)
	_map_canvas = Control.new()
	_map_canvas.name = "MapCanvas"
	_map_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_surface.add_child(_map_canvas)
	_map_floor_layer = _add_map_art_layer("FloorPlan", _custom_map_floor_tex if _custom_map_floor_tex != null else MAP_FLOOR_TEXTURE)
	_map_wall_layer = _add_map_art_layer("WallOverlay", _custom_map_wall_tex if _custom_map_wall_tex != null else MAP_WALL_TEXTURE)
	_map_player_marker = _map_marker(GOLD, true)
	_map_player_marker.visible = MAP_CONTENT_VISIBLE
	_map_canvas.add_child(_map_player_marker)
	for entry in _task_entries:
		_add_map_task_marker(entry)
	var legend := HFlowContainer.new()
	legend.name = "MapLegend"
	legend.add_theme_constant_override("h_separation", 24)
	legend.add_theme_constant_override("v_separation", 8)
	for item in [["CURRENT POSITION", CYAN], ["OPEN TASK", ORANGE], ["COMPLETE", GREEN]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var swatch := ColorRect.new()
		swatch.color = item[1]
		swatch.custom_minimum_size = Vector2(8, 8)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(swatch)
		row.add_child(_label(item[0], 12, PALE))
		legend.add_child(row)
	legend.add_child(_label("M / ESC  CLOSE", 12, MUTED))
	content.add_child(legend)


func _add_map_art_layer(layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.texture = texture
	_map_canvas.add_child(layer)
	return layer


func set_map_textures(floor_tex: Texture2D, wall_tex: Texture2D) -> void:
	_custom_map_floor_tex = floor_tex
	_custom_map_wall_tex = wall_tex
	if is_instance_valid(_map_floor_layer) and floor_tex != null:
		_map_floor_layer.texture = floor_tex
	if is_instance_valid(_map_wall_layer) and wall_tex != null:
		_map_wall_layer.texture = wall_tex


func set_show_all_active_tasks(show_all: bool) -> void:
	_show_all_active_tasks = show_all
	_refresh_mission_panel()
	_update_world_task_markers()


func _add_map_task_marker(entry: Dictionary) -> void:
	if not is_instance_valid(_map_canvas):
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
	_map_canvas.add_child(marker)
	_map_task_markers[task_id] = {"marker": marker}


func _add_world_task_marker(entry: Dictionary) -> void:
	if not is_instance_valid(_world_task_marker_layer):
		return
	var task_id := StringName(entry.get("id", &""))
	if task_id == &"" or _world_task_markers.has(task_id):
		return
	var marker := TaskLocationMarker.new()
	marker.name = "Task_%s" % String(task_id)
	marker.is_equipment_task = _is_equipment_task_entry(entry)
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

	_operator_panel = PanelContainer.new()
	_operator_panel.custom_minimum_size.x = 300
	_operator_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE_RAISED, EDGE_SOFT, 10))
	columns.add_child(_operator_panel)
	var character_stack := VBoxContainer.new()
	character_stack.add_theme_constant_override("separation", 12)
	_operator_panel.add_child(character_stack)
	character_stack.add_child(_label("OPERATOR / THURA MIN", 12, GOLD))
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
		cell.activated.connect(_on_inventory_cell_activated)
		cell.drop_requested.connect(_on_inventory_drop_requested)
		(left_slots if index % 2 == 0 else right_slots).add_child(cell)
		_equipment_cells.append(cell)

	var inventory_panel := PanelContainer.new()
	inventory_panel.name = "CargoPanel"
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE_RAISED, EDGE_SOFT, 10))
	columns.add_child(inventory_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(stack)
	var cargo_heading := HBoxContainer.new()
	cargo_heading.add_child(_label("CARGO HOLD", 16, GOLD))
	cargo_heading.add_spacer(false)
	_cargo_count_label = _label("08 / 27 USED", 12, CYAN)
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
	stack.add_child(_label("QUICK ACCESS / 1-9", 16, GOLD))
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
	var hint := _label("DRAG ITEMS TO QUICK ACCESS OR A COMPATIBLE SLOT.  /  ESC CLOSE", 12, MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	_refresh_inventory_cells()


func _create_profile_overlay() -> void:
	var modal := _create_modal_shell("PROFILE", Vector2(760, 460))
	_overlay_nodes[&"profile"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	var columns := HBoxContainer.new()
	columns.name = "ProfileColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 20)
	content.add_child(columns)

	# Minimalist Left Sidebar: Portrait + Name + Simple Counter
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 176
	sidebar.alignment = BoxContainer.ALIGNMENT_CENTER
	sidebar.add_theme_constant_override("separation", 10)
	columns.add_child(sidebar)

	var portrait_box := PanelContainer.new()
	portrait_box.add_theme_stylebox_override("panel", _flat_box(Color(0.02, 0.036, 0.05, 0.75), Color(0.18, 0.28, 0.32, 0.6), 8.0, 10.0, 1))
	sidebar.add_child(portrait_box)
	var portrait := TextureRect.new()
	var portrait_texture := AtlasTexture.new()
	portrait_texture.atlas = THURA_ATLAS
	portrait_texture.region = Rect2(79, 43, 157, 267)
	portrait_texture.filter_clip = true
	portrait.texture = portrait_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(96, 148)
	portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_box.add_child(portrait)

	var name_lbl := _label("THURA MIN", 13, PALE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sidebar.add_child(name_lbl)

	_profile_score_label = _label("0 / %d UNLOCKED" % ACHIEVEMENTS_CATALOG.size(), 10, GOLD)
	_profile_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sidebar.add_child(_profile_score_label)

	_profile_progress_bar = ProgressBar.new()
	_profile_progress_bar.min_value = 0.0
	_profile_progress_bar.max_value = maxi(ACHIEVEMENTS_CATALOG.size(), 1)
	_profile_progress_bar.show_percentage = false
	_profile_progress_bar.custom_minimum_size.y = 4.0
	_profile_progress_bar.add_theme_stylebox_override("background", _flat_box(Color(0.02, 0.05, 0.07), Color.TRANSPARENT, 0.0, 0.0, 0))
	_profile_progress_bar.add_theme_stylebox_override("fill", _flat_box(GOLD, Color.TRANSPARENT, 0.0, 0.0, 0))
	sidebar.add_child(_profile_progress_bar)

	var divider := VSeparator.new()
	divider.modulate = Color(1.0, 1.0, 1.0, 0.25)
	columns.add_child(divider)

	# Minimalist Right Column: Clean Header + Flat Achievement List
	var a_stack := VBoxContainer.new()
	a_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	a_stack.add_theme_constant_override("separation", 8)
	columns.add_child(a_stack)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 6)
	top_bar.add_child(_label("ACHIEVEMENTS", 12, MUTED))
	top_bar.add_spacer(false)
	for filter_def in [["ALL", &"all"], ["UNLOCKED", &"unlocked"], ["LOCKED", &"locked"]]:
		var f_label: String = filter_def[0]
		var f_id: StringName = filter_def[1]
		var f_btn := _flat_filter_button(f_label)
		f_btn.pressed.connect(func():
			_achievement_filter = f_id
			_refresh_profile_overlay()
		)
		top_bar.add_child(f_btn)
		_profile_filter_buttons[f_id] = f_btn
	a_stack.add_child(top_bar)

	var scroll := ScrollContainer.new()
	scroll.name = "AchievementsScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	a_stack.add_child(scroll)

	_profile_achievements_list = VBoxContainer.new()
	_profile_achievements_list.name = "AchievementsList"
	_profile_achievements_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_achievements_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_profile_achievements_list)


func _create_settings_overlay() -> void:
	var modal := _create_modal_shell("SHIP SETTINGS", Vector2(860, 548))
	_overlay_nodes[&"settings"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	content.add_theme_constant_override("separation", 18)
	content.add_child(_label("AUDIO OUTPUT", 16, GOLD))
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 18)
	volume_row.add_child(_label("MASTER VOLUME", 16, PALE))
	_volume_slider = HSlider.new()
	_volume_slider.name = "MasterVolume"
	_volume_slider.min_value = 0
	_volume_slider.max_value = 100
	_volume_slider.step = 1
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.custom_minimum_size = Vector2(180, 32)
	var master_bus_index := AudioServer.get_bus_index("Master")
	_volume_slider.value = 100
	if master_bus_index >= 0:
		_volume_slider.value = 0.0 if AudioServer.is_bus_mute(master_bus_index) else AudioServer.get_bus_volume_linear(master_bus_index) * 100.0
	_volume_slider.value_changed.connect(_on_master_volume_changed)
	volume_row.add_child(_volume_slider)
	_volume_label = _label("%d%%" % roundi(_volume_slider.value), 16, CYAN)
	_volume_label.custom_minimum_size.x = 52
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	volume_row.add_child(_volume_label)
	content.add_child(volume_row)
	content.add_child(HSeparator.new())
	content.add_child(_label("CONTROLS", 16, GOLD))
	var hints := GridContainer.new()
	hints.name = "ControlHints"
	hints.columns = 2
	hints.add_theme_constant_override("h_separation", 24)
	hints.add_theme_constant_override("v_separation", 14)
	for pair in [["MOVE", "WASD / ARROWS"], ["INTERACT", "E"], ["QUICK SLOT", "1-9 / WHEEL"], ["INVENTORY", "I"], ["PROFILE / ACHIEVEMENTS", "P"], ["SHIP MAP", "M"], ["SETTINGS / CLOSE", "ESC"]]:
		hints.add_child(_key_hint(pair[0], pair[1]))
	content.add_child(hints)
	content.add_spacer(false)
	content.add_child(HSeparator.new())
	content.add_child(_label("WALKING PAUSES WHILE THESE PANELS ARE OPEN.", 12, MUTED))

func _key_hint(action_name: String, key_name: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(370, 40)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	row.add_child(_label(action_name, 12, PALE))
	row.add_spacer(false)
	var keycap := PanelContainer.new()
	keycap.custom_minimum_size = Vector2(164 if key_name.length() > 4 else 64, 40)
	keycap.add_theme_stylebox_override("panel", _panel_style(SURFACE, EDGE, 8))
	var key_label := _label(key_name, 12, CYAN)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.add_child(key_label)
	row.add_child(keycap)
	return row

func _create_modal_shell(title: String, desired_size: Vector2) -> Dictionary:
	var overlay := Control.new()
	overlay.name = title.replace(" / ", "_").replace(" ", "_")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	_root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.008, 0.014, 0.025, 0.86)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dimmer)
	var frame := PanelContainer.new()
	frame.name = "WindowFrame"
	frame.minimum_size_changed.connect(_queue_resize)
	frame.add_theme_stylebox_override("panel", PIXEL_THEME.get_stylebox("panel", "PanelContainer"))
	overlay.add_child(frame)
	_modal_frames[overlay] = {"frame": frame, "desired": desired_size}
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	frame.add_child(layout)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	var icon := PixelIcon.new()
	icon.icon_kind = &"map" if title == "SHIP MAP" else &"settings" if title == "SHIP SETTINGS" else &"profile" if title == "PROFILE" else &"inventory"
	icon.tint = GOLD
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(icon)
	var title_label := _label(title, 24, PALE)
	title_label.name = "WindowTitle"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_child(title_label)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.theme_type_variation = &"CloseButton"
	close_button.custom_minimum_size = Vector2(48, 48)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.name = "Close"
	close_button.tooltip_text = "Close / Esc"
	close_button.add_theme_font_size_override("font_size", 24)
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
	if not MAP_CONTENT_VISIBLE or not is_instance_valid(_map_canvas):
		return
	if is_instance_valid(_player) and _map_world_size.x > 0.0 and _map_world_size.y > 0.0:
		_set_marker_position(_map_player_marker, _map_canvas_normalized_position(_player.global_position))
	var active_ids: Array[StringName] = _get_active_sequential_task_ids()
	for entry in _task_entries:
		var task_id: StringName = entry["id"]
		if not _map_task_markers.has(task_id):
			continue
		var marker_data: Dictionary = _map_task_markers[task_id]
		var task_position: Vector2 = entry["position"]
		var normalized: Vector2 = _map_canvas_normalized_position(task_position)
		var marker := marker_data["marker"] as MapPin
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		marker.visible = is_complete or active_ids.has(task_id)
		_set_map_pin_position(marker, normalized)
		marker.is_complete = is_complete
		marker.pin_color = GREEN if is_complete else ORANGE
		marker.tooltip_text = ("[NOMINAL] " if is_complete else "[ALERT] ") + str(entry.get("title", "Ship task"))
		marker.queue_redraw()


func _map_canvas_normalized_position(world_position: Vector2) -> Vector2:
	if _map_world_size.x <= 0.0 or _map_world_size.y <= 0.0:
		return Vector2.ZERO
	var world_normalized: Vector2 = (world_position - _map_world_origin) / _map_world_size
	var canvas_size: Vector2 = _map_canvas.size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return world_normalized
	var fit_scale: float = minf(canvas_size.x / _map_world_size.x, canvas_size.y / _map_world_size.y)
	var image_size: Vector2 = _map_world_size * fit_scale
	var image_offset: Vector2 = (canvas_size - image_size) * 0.5
	var canvas_position: Vector2 = image_offset + world_normalized * image_size
	return canvas_position / canvas_size


func _get_active_sequential_task_ids() -> Array[StringName]:
	var active_ids: Array[StringName] = []
	var found_primary: bool = false
	var found_side: bool = false
	for entry in _task_entries:
		var tid: StringName = StringName(entry.get("id", &""))
		if tid == &"" or bool(_task_completed.get(tid, false)):
			continue
		if _show_all_active_tasks:
			active_ids.append(tid)
			continue
		var is_side: bool = String(tid).begins_with("amara_")
		if is_side:
			if not found_side:
				active_ids.append(tid)
				found_side = true
		else:
			if not found_primary:
				active_ids.append(tid)
				found_primary = true
	return active_ids


func is_task_unlocked_in_sequence(task_id: StringName) -> bool:
	var active_ids: Array[StringName] = _get_active_sequential_task_ids()
	return active_ids.has(task_id)


func _update_world_task_markers() -> void:
	if not is_instance_valid(_world_task_marker_layer):
		return
	var canvas_transform := get_viewport().get_canvas_transform()
	var visible_rect := get_viewport().get_visible_rect()
	var active_ids: Array[StringName] = _get_active_sequential_task_ids()
	for entry in _task_entries:
		var task_id: StringName = entry["id"]
		if not _world_task_markers.has(task_id):
			continue
		var marker := _world_task_markers[task_id] as TaskLocationMarker
		if not is_instance_valid(marker):
			continue
		if bool(_task_completed.get(task_id, false)) or not active_ids.has(task_id) or not _walking_visible or _active_overlay != &"":
			marker.visible = false
			continue
		var target_world_position: Vector2 = entry.get("marker_position", entry.get("position", Vector2.ZERO))
		var target_screen_position := canvas_transform * target_world_position
		var marker_size := marker.custom_minimum_size
		marker.position = (target_screen_position - Vector2(marker_size.x * 0.5, marker_size.y)).floor()
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
	var current_step: int = mini(completed_count + 1, maxi(total, 1))
	if completed_count >= total and total > 0:
		_mission_progress_label.text = "ALL %02d DONE (100%%)" % total
		_mission_progress_label.add_theme_color_override("font_color", GREEN)
	else:
		_mission_progress_label.text = "STEP %02d / %02d" % [current_step, maxi(total, 1)]
		_mission_progress_label.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
	_mission_progress_bar.max_value = maxi(total, 1)
	_mission_progress_bar.value = completed_count

	var active_ids: Array[StringName] = _get_active_sequential_task_ids()
	var visible_row_count: int = 0
	for task_id in _mission_rows:
		var row_data: Dictionary = _mission_rows[task_id]
		var row_ctrl: Control = row_data["row"] as Control
		var row_icon: TaskRowIcon = row_data["icon"] as TaskRowIcon
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		var is_eq: bool = bool(row_data.get("is_eq", false))
		var show_row: bool = active_ids.has(task_id) or (active_ids.is_empty() and is_complete)
		row_ctrl.visible = show_row
		if show_row:
			visible_row_count += 1
		if is_instance_valid(row_icon):
			row_icon.is_complete = is_complete
			row_icon.queue_redraw()
		if is_complete:
			row_data["mark"].text = "DONE"
			row_data["mark"].add_theme_color_override("font_color", GREEN)
			row_data["label"].add_theme_color_override("font_color", Color(0.52, 0.72, 0.65))
			row_data["tag"].add_theme_color_override("font_color", Color(0.38, 0.58, 0.50))
		else:
			row_data["mark"].text = "GEAR" if is_eq else "ACTIVE"
			row_data["mark"].add_theme_color_override("font_color", CYAN if is_eq else ORANGE)
			row_data["label"].add_theme_color_override("font_color", PALE)
			row_data["tag"].add_theme_color_override("font_color", CYAN if is_eq else GOLD)

	if is_instance_valid(_mission_summary_label):
		if completed_count > 0 and not active_ids.is_empty():
			_mission_summary_label.text = "✔ %d/%d COMPLETED  ·  NEXT UNLOCKS AFTER CURRENT STEP" % [completed_count, total]
			_mission_summary_label.visible = true
			visible_row_count += 1
		else:
			_mission_summary_label.visible = false

	if is_instance_valid(_mission_panel):
		_mission_panel.offset_bottom = 86.0 + float(maxi(visible_row_count, 1)) * 24.0
	_update_map_markers()


func set_task_completed(task_id: StringName, silent: bool = false) -> void:
	if _task_completed.has(task_id):
		var was_already_done: bool = bool(_task_completed[task_id])
		_task_completed[task_id] = true
		_refresh_mission_panel()
		_update_world_task_markers()
		unlock_achievement(task_id, silent or was_already_done)
	else:
		unlock_achievement(task_id, silent)


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
		_select_hotbar(slot_index, true)
	elif slot_kind == &"equipment":
		if slot_index >= 0 and slot_index < EQUIPMENT_SLOTS.size():
			var eq_slot: StringName = EQUIPMENT_SLOTS[slot_index]
			var cur_eq: StringName = StringName(_equipment_items.get(eq_slot, &""))
			if cur_eq != &"":
				for s_idx in range(_storage_items.size()):
					if _storage_items[s_idx] == &"":
						_storage_items[s_idx] = cur_eq
						break
				_equipment_items[eq_slot] = &""
				if eq_slot == &"tool":
					_selected_hotbar_index = -1
				_refresh_hotbar()
				_refresh_inventory_cells()
				_sync_player_equipped_item()
				_save_persistent_inventory_state()
	elif slot_kind == &"storage":
		var st_item: StringName = _get_slot_item(&"storage", slot_index)
		if st_item != &"" and ITEM_DATA.has(st_item):
			var target_eq_slot: StringName = ITEM_DATA[st_item]["equip_slot"]
			var prev_eq: StringName = StringName(_equipment_items.get(target_eq_slot, &""))
			_equipment_items[target_eq_slot] = st_item
			_storage_items[slot_index] = prev_eq if prev_eq != st_item else &""
			var h_idx: int = _hotbar_items.find(st_item)
			if h_idx >= 0:
				_selected_hotbar_index = h_idx
			_refresh_hotbar()
			_refresh_inventory_cells()
			_sync_player_equipped_item()
			_save_persistent_inventory_state()


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
	_sync_player_equipped_item()
	_save_persistent_inventory_state()


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
	_refresh_profile_overlay()
	_open_overlay(&"inventory")


func _open_profile() -> void:
	_refresh_profile_overlay()
	_open_overlay(&"profile")


func _open_settings() -> void:
	_open_overlay(&"settings")


func _open_overlay(overlay_name: StringName) -> void:
	if not _walking_visible or not _overlay_nodes.has(overlay_name):
		return
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
	button.custom_minimum_size = Vector2(138, 60)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "%s / %s" % [title, shortcut]
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", PIXEL_THEME.get_stylebox("normal", "Button"))
	button.add_theme_stylebox_override("hover", PIXEL_THEME.get_stylebox("hover", "Button"))
	button.add_theme_stylebox_override("pressed", PIXEL_THEME.get_stylebox("pressed", "Button"))
	button.add_theme_stylebox_override("focus", PIXEL_THEME.get_stylebox("focus", "Button"))
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 10
	layout.offset_right = -10
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 8)
	var icon := PixelIcon.new()
	icon.icon_kind = icon_kind
	icon.tint = GOLD
	icon.custom_minimum_size = Vector2(22, 22)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(icon)
	var labels := VBoxContainer.new()
	labels.alignment = BoxContainer.ALIGNMENT_CENTER
	labels.add_theme_constant_override("separation", 4)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title_label := _label(title, 9, PALE)
	var shortcut_label := _label(shortcut, 8, CYAN)
	labels.add_child(title_label)
	labels.add_child(shortcut_label)
	layout.add_child(labels)
	button.add_child(layout)
	button.mouse_entered.connect(func(): title_label.add_theme_color_override("font_color", GOLD))
	button.mouse_exited.connect(func(): title_label.add_theme_color_override("font_color", PALE))
	button.pressed.connect(callback)
	return button

func _nav_button_style(_accent: Color, highlighted: bool) -> StyleBox:
	return PIXEL_THEME.get_stylebox("hover" if highlighted else "normal", "Button")

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	var clean_size: int = 13 if font_size >= 16 else (11 if font_size >= 13 else (10 if font_size >= 11 else maxi(font_size, 8)))
	label.add_theme_font_size_override("font_size", clean_size)
	label.add_theme_constant_override("line_spacing", 4)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, minimum_size: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", PALE)
	button.add_theme_color_override("font_hover_color", PALE)
	button.add_theme_stylebox_override("normal", _button_style(accent, false))
	button.add_theme_stylebox_override("hover", _button_style(accent, true))
	button.add_theme_stylebox_override("pressed", _button_style(accent, true))
	button.add_theme_stylebox_override("focus", _button_style(accent, true))
	return button


func _button_style(_accent: Color, highlighted: bool) -> StyleBox:
	return PIXEL_THEME.get_stylebox("hover" if highlighted else "normal", "Button")

func _panel_style(background: Color, border: Color, padding: float) -> StyleBox:
	if padding >= 5:
		var frame := PIXEL_THEME.get_stylebox("panel", "PanelContainer").duplicate() as StyleBoxTexture
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


func _flat_box(background: Color, border: Color, pad_x: float, pad_y: float, border_w: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_w)
	style.content_margin_left = pad_x
	style.content_margin_right = pad_x
	style.content_margin_top = pad_y
	style.content_margin_bottom = pad_y
	style.anti_aliasing = false
	return style


func _flat_filter_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(72, 24)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", MUTED)
	btn.add_theme_color_override("font_hover_color", PALE)
	var normal_s := _flat_box(Color(0.02, 0.036, 0.05, 0.6), Color(0.18, 0.28, 0.32, 0.5), 8.0, 3.0, 1)
	var hover_s := _flat_box(Color(0.05, 0.08, 0.11, 0.85), GOLD, 8.0, 3.0, 1)
	btn.add_theme_stylebox_override("normal", normal_s)
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_stylebox_override("pressed", hover_s)
	return btn

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

	# Prefer the pre-extracted transparent background-removed icon from res://art/tools/icons/<item_id>.png
	var clean_icon_path: String = "res://art/tools/icons/%s.png" % String(item_id)
	var clean_abs_path: String = ProjectSettings.globalize_path(clean_icon_path)
	if FileAccess.file_exists(clean_abs_path):
		var clean_img: Image = Image.load_from_file(clean_abs_path)
		if clean_img != null and not clean_img.is_empty():
			var c_ratio: float = 64.0 / maxf(float(clean_img.get_width()), float(clean_img.get_height()))
			clean_img.resize(
				maxi(1, roundi(float(clean_img.get_width()) * c_ratio)),
				maxi(1, roundi(float(clean_img.get_height()) * c_ratio)),
				Image.INTERPOLATE_LANCZOS
			)
			var clean_tex: ImageTexture = ImageTexture.create_from_image(clean_img)
			_item_icon_cache[item_id] = clean_tex
			return clean_tex

	var item: Dictionary = ITEM_DATA[item_id]
	var source: Image = item["texture"].get_image()
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)
	var thumbnail := source.get_region(Rect2i(item["icon_region"]))
	var ratio := 64.0 / maxf(thumbnail.get_width(), thumbnail.get_height())
	thumbnail.resize(maxi(1, roundi(thumbnail.get_width() * ratio)), maxi(1, roundi(thumbnail.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	var icon := ImageTexture.create_from_image(thumbnail)
	_item_icon_cache[item_id] = icon
	return icon


func _unhandled_input(event: InputEvent) -> void:
	if not _walking_visible or _active_overlay != &"":
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var ib := get_tree().root.get_node_or_null("InputBindings") if get_tree() != null and get_tree().root != null else null
			if ib != null and ib.has_method("is_mobile_or_touch") and bool(ib.call("is_mobile_or_touch")):
				return
			if is_instance_valid(_player):
				if event.pressed and _player.has_method("start_using_equipment"):
					_player.start_using_equipment(true)
					_update_equipped_status_banner()
				elif not event.pressed and _player.has_method("stop_using_equipment"):
					_player.stop_using_equipment()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_hotbar((_selected_hotbar_index - 1 + _hotbar_items.size()) % _hotbar_items.size())
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
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
	if event.keycode == KEY_I and _active_overlay == &"inventory":
		_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_P and _active_overlay == &"profile":
		_close_overlay()
		get_viewport().set_input_as_handled()
		return
	if _active_overlay != &"":
		return
	if event.keycode == KEY_I:
		_open_inventory()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_P:
		_open_profile()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_M:
		_open_map()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_SPACE:
		if is_instance_valid(_player) and _player.has_method("start_using_equipment"):
			_player.start_using_equipment(false)
			_update_equipped_status_banner()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_G:
		drop_active_item()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_Q or event.keycode == KEY_0 or event.keycode == KEY_BACKSPACE:
		_unequip_active_tool()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_F:
		if is_instance_valid(_player) and _player.has_method("toggle_suit_flashlight"):
			_player.toggle_suit_flashlight()
			_update_equipped_status_banner()
			_save_persistent_inventory_state()
		get_viewport().set_input_as_handled()
		return
	var hotbar_index := HOTBAR_KEY_CODES.find(event.keycode)
	if hotbar_index >= 0:
		_select_hotbar(hotbar_index, true)
		get_viewport().set_input_as_handled()


func _get_room_lighting() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("ship_room_lighting")
	if not nodes.is_empty():
		return nodes[0] as Node2D
	if is_instance_valid(_player) and _player.get_parent() != null:
		return _player.get_parent().get_node_or_null("ShipRoomLighting") as Node2D
	return null


func _build_dev_menu_panel() -> void:
	_dev_panel = PanelContainer.new()
	_dev_panel.name = "DevMenuPanel"
	_dev_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_dev_panel.offset_left = -410.0
	_dev_panel.offset_top = 88.0
	_dev_panel.offset_right = -18.0
	_dev_panel.offset_bottom = 502.0
	_dev_panel.visible = false
	_dev_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, GOLD, 12.0))
	_root.add_child(_dev_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	_dev_panel.add_child(stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var title := _label("DEV MENU // LIGHTING TEST", 12, GOLD)
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

	_dev_current_room_label = _label("OCCUPIED: HALLWAY", 12, CYAN)
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
	stack.add_child(_label("TARGET ROOM FLICKER & WARP", 12, GOLD))

	var room_nav := HBoxContainer.new()
	room_nav.add_theme_constant_override("separation", 8)
	var prev_btn := _button("<", Vector2(44, 38), CYAN)
	prev_btn.pressed.connect(func(): _step_dev_room(-1))
	room_nav.add_child(prev_btn)
	_dev_room_name_label = _label("R01 Bridge", 12, PALE)
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
	_dev_force_lights_btn = _button("ALL LIT: OFF", Vector2(114, 38), GOLD)
	_dev_force_lights_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_force_lights_btn.pressed.connect(_on_dev_toggle_force_lights)
	row3.add_child(_dev_force_lights_btn)
	var reset_btn := _button("RESET", Vector2(104, 38), MUTED)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.pressed.connect(_on_dev_reset_lights)
	row3.add_child(reset_btn)
	var deck_btn := _button("SWITCH DECK", Vector2(124, 38), CYAN)
	deck_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deck_btn.pressed.connect(_on_dev_switch_deck)
	row3.add_child(deck_btn)
	stack.add_child(row3)
	var gear_btn := _button("DEV: UNLOCK ALL 10 GEAR ITEMS", Vector2(200, 36), GREEN)
	gear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_btn.pressed.connect(unlock_all_equipment_items)
	stack.add_child(gear_btn)
	var pilot_dev_btn: Button = _button("DEV: TRIGGER ASTEROID CUTSCENE", Vector2(200, 36), ORANGE)
	pilot_dev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pilot_dev_btn.pressed.connect(_on_dev_trigger_asteroid_cutscene)
	stack.add_child(pilot_dev_btn)
	var ach_dev_btn := _button("DEV: UNLOCK NEXT ACHIEVEMENT", Vector2(200, 36), GOLD)
	ach_dev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_dev_btn.pressed.connect(_on_dev_unlock_next_achievement)
	stack.add_child(ach_dev_btn)


func _on_dev_trigger_asteroid_cutscene() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.has_method("trigger_emergency_asteroid_cutscene"):
		current_scene.call("trigger_emergency_asteroid_cutscene")


func _on_dev_switch_deck() -> void:
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path == "res://scenes/ship/second_floor_subdeck.tscn":
		Engine.set_meta(&"returning_from_second_floor", true)
		get_tree().change_scene_to_file("res://scenes/ship/bare_ship_walkthrough.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ship/second_floor_subdeck.tscn")


func _toggle_dev_menu() -> void:
	if not _walking_visible or not is_instance_valid(_dev_panel):
		return
	if _active_overlay != &"":
		_close_overlay()
	_dev_panel.visible = not _dev_panel.visible
	if _dev_panel.visible:
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


func _load_persistent_inventory_state() -> void:
	if Engine.has_meta(CAMPAIGN_META_KEY):
		var state: Dictionary = Engine.get_meta(CAMPAIGN_META_KEY)
		var saved_hotbar: Array = state.get("hotbar", [])
		if saved_hotbar.size() == 9:
			for i in range(9):
				_hotbar_items[i] = StringName(saved_hotbar[i])
		var saved_storage: Array = state.get("storage", [])
		if saved_storage.size() == 27:
			for i in range(27):
				_storage_items[i] = StringName(saved_storage[i])
		var saved_eq: Dictionary = state.get("equipment", {})
		for k in [&"head", &"suit", &"pack", &"tool"]:
			if saved_eq.has(k):
				_equipment_items[k] = StringName(saved_eq[k])
		_selected_hotbar_index = int(state.get("selected_hotbar_index", 0))
		_unlocked_items = state.get("unlocked_items", {}).duplicate()
		_collected_logs = state.get("collected_logs", {}).duplicate()
		_unlocked_achievements = state.get("unlocked_achievements", {}).duplicate()
		_current_story_act = str(state.get("story_act", "ACT I — THE LONG APPROACH"))
		var suit_item: StringName = StringName(_equipment_items.get(&"suit", &""))
		var flashlight_unlocked: bool = _unlocked_items.has(&"suit_flashlight") or suit_item == &"suit_flashlight"
		if is_instance_valid(_player):
			if _player.has_method("set_suit_flashlight_unlocked"):
				_player.set_suit_flashlight_unlocked(flashlight_unlocked)
			if _player.has_method("set_suit_flashlight_enabled"):
				_player.set_suit_flashlight_enabled(bool(state.get("flashlight_enabled", flashlight_unlocked)))
	else:
		_save_persistent_inventory_state()


func _save_persistent_inventory_state() -> void:
	var flashlight_on := false
	if is_instance_valid(_player) and _player.has_method("is_suit_flashlight_enabled"):
		flashlight_on = _player.is_suit_flashlight_enabled()
	var state := {
		"hotbar": _hotbar_items.duplicate(),
		"storage": _storage_items.duplicate(),
		"equipment": _equipment_items.duplicate(),
		"selected_hotbar_index": _selected_hotbar_index,
		"unlocked_items": _unlocked_items.duplicate(),
		"collected_logs": _collected_logs.duplicate(),
		"unlocked_achievements": _unlocked_achievements.duplicate(),
		"story_act": _current_story_act,
		"flashlight_enabled": flashlight_on,
	}
	Engine.set_meta(CAMPAIGN_META_KEY, state)


func has_equipment_item(item_id: StringName) -> bool:
	return _unlocked_items.has(item_id)


func get_unlocked_equipment_count() -> int:
	return _unlocked_items.size()


func get_collected_logs_count() -> int:
	return _collected_logs.size()


func record_audio_log(log_id: StringName, _log_title: String = "") -> bool:
	if log_id == &"" or _collected_logs.has(log_id):
		return false
	_collected_logs[log_id] = true
	_refresh_story_act_label()
	_save_persistent_inventory_state()
	return true


func set_story_act_label(act_label: String) -> void:
	_current_story_act = act_label
	_refresh_story_act_label()
	_save_persistent_inventory_state()


func _refresh_story_act_label() -> void:
	if is_instance_valid(_story_act_label):
		_story_act_label.text = "%s  //  GEAR %02d/10  ·  LOGS %d/8" % [_current_story_act, _unlocked_items.size(), _collected_logs.size()]


func unlock_equipment_item(item_id: StringName, equip_immediately: bool = true, reason_text: String = "") -> bool:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return false
	var already_had: bool = _unlocked_items.has(item_id)
	_unlocked_items[item_id] = true
	var eq_slot: StringName = ITEM_DATA[item_id]["equip_slot"]
	if eq_slot == &"suit":
		_equipment_items[&"suit"] = item_id
		if is_instance_valid(_player):
			if _player.has_method("set_suit_flashlight_unlocked"):
				_player.set_suit_flashlight_unlocked(true)
			if equip_immediately and _player.has_method("set_suit_flashlight_enabled"):
				_player.set_suit_flashlight_enabled(true)
	else:
		var existing_idx: int = _hotbar_items.find(item_id)
		if existing_idx < 0 and _storage_items.find(item_id) < 0:
			var placed := false
			for i in range(_hotbar_items.size()):
				if _hotbar_items[i] == &"":
					_hotbar_items[i] = item_id
					existing_idx = i
					placed = true
					break
			if not placed:
				for s in range(_storage_items.size()):
					if _storage_items[s] == &"":
						_storage_items[s] = item_id
						break
		if equip_immediately and existing_idx >= 0:
			_selected_hotbar_index = existing_idx
			_equipment_items[&"tool"] = item_id
	_refresh_hotbar()
	_refresh_inventory_cells()
	_refresh_story_act_label()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()
	if _unlocked_items.size() >= ALL_PROGRESSION_ITEMS.size():
		unlock_achievement(&"full_arsenal_mastery", false)
	_refresh_profile_overlay()
	if not already_had:
		show_equipment_unlocked_toast(item_id, reason_text)
	return not already_had


func unlock_all_equipment_items() -> void:
	for item_id in ALL_PROGRESSION_ITEMS:
		unlock_equipment_item(item_id, false, "Dev Menu Full Loadout")
	_select_hotbar(0, false)
	show_equipment_unlocked_toast(&"captains_revolver", "ALL 10 EQUIPMENT ITEMS UNLOCKED")


func show_equipment_unlocked_toast(item_id: StringName, reason_text: String = "") -> void:
	if not is_instance_valid(_unlock_toast_panel) or not ITEM_DATA.has(item_id):
		return
	var item_name: String = str(ITEM_DATA[item_id]["name"]).to_upper()
	var slot_idx: int = _hotbar_items.find(item_id)
	if is_instance_valid(_unlock_toast_badge):
		if item_id == &"suit_flashlight":
			_unlock_toast_badge.text = "[ EQUIPMENT FOUND // SUIT HARNESS SLOT [F] ]"
		elif slot_idx >= 0:
			_unlock_toast_badge.text = "[ EQUIPMENT FOUND // QUICK SLOT [%d]  ·  %d/10 GEAR ]" % [slot_idx + 1, _unlocked_items.size()]
		else:
			_unlock_toast_badge.text = "[ EQUIPMENT FOUND // CARGO INVENTORY [I] ]"
	_unlock_toast_icon.texture = _item_icon_texture(item_id)
	_unlock_toast_title.text = item_name
	_unlock_toast_title.add_theme_color_override("font_color", _item_color(item_id))
	if reason_text.is_empty():
		if item_id == &"suit_flashlight":
			_unlock_toast_subtitle.text = "Shoulder beam online  ·  Press [F] anytime to toggle light"
		elif slot_idx >= 0:
			_unlock_toast_subtitle.text = "Press [%d] to hold in hand  ·  [Q] Unequip" % (slot_idx + 1)
		else:
			_unlock_toast_subtitle.text = "Press [I] to open Loadout & assign to Quick Bar"
	else:
		_unlock_toast_subtitle.text = reason_text
	_unlock_toast_panel.visible = true
	_unlock_toast_timer = 4.8


func _get_achievement_def(ach_id: StringName) -> Dictionary:
	for def in ACHIEVEMENTS_CATALOG:
		if def["id"] == ach_id:
			return def
	return {}


func unlock_achievement(ach_id: StringName, silent: bool = false) -> bool:
	if ach_id == &"":
		return false
	var def: Dictionary = _get_achievement_def(ach_id)
	if def.is_empty():
		return false
	var already_unlocked: bool = _unlocked_achievements.has(ach_id)
	_unlocked_achievements[ach_id] = true
	_save_persistent_inventory_state()
	_refresh_profile_overlay()
	if not already_unlocked and not silent:
		show_achievement_popup(str(def["title"]))
	return not already_unlocked


func _on_dev_unlock_next_achievement() -> void:
	for def in ACHIEVEMENTS_CATALOG:
		var aid: StringName = def["id"]
		if not _unlocked_achievements.has(aid):
			unlock_achievement(aid, false)
			return
	show_achievement_popup("All Achievements Unlocked")


func show_achievement_popup(title_text: String, subtitle_text: String = "", badge_text: String = "", accent_color: Color = GOLD) -> void:
	if not is_instance_valid(_achievement_toast_panel):
		return
	if _achievement_toast_timer > 0.0 and _achievement_toast_panel.visible:
		_achievement_toast_queue.append({
			"title": title_text,
			"subtitle": subtitle_text,
			"badge": badge_text,
			"color": accent_color,
		})
		return
	_display_achievement_toast_now(title_text, subtitle_text, badge_text, accent_color)


func _display_achievement_toast_now(title_text: String, _subtitle_text: String, _badge_text: String, accent_color: Color) -> void:
	if not is_instance_valid(_achievement_toast_panel):
		return
	if is_instance_valid(_achievement_toast_medal):
		_achievement_toast_medal.medal_color = accent_color
		_achievement_toast_medal.unlocked = true
		_achievement_toast_medal.queue_redraw()
	if is_instance_valid(_achievement_toast_badge):
		_achievement_toast_badge.text = "ACHIEVEMENT UNLOCKED"
		_achievement_toast_badge.add_theme_color_override("font_color", accent_color)
	_achievement_toast_title.text = title_text.to_upper()
	_achievement_toast_panel.visible = true
	_achievement_toast_timer = 3.6
	if is_instance_valid(_achievement_toast_tween) and _achievement_toast_tween.is_running():
		_achievement_toast_tween.kill()
	_achievement_toast_panel.offset_left = -20.0
	_achievement_toast_panel.offset_right = 240.0
	_achievement_toast_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_achievement_toast_tween = create_tween()
	_achievement_toast_tween.set_parallel(true)
	_achievement_toast_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_achievement_toast_tween.tween_property(_achievement_toast_panel, "offset_left", -276.0, 0.26)
	_achievement_toast_tween.tween_property(_achievement_toast_panel, "offset_right", -16.0, 0.26)
	_achievement_toast_tween.tween_property(_achievement_toast_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _refresh_profile_overlay() -> void:
	var total_count: int = ACHIEVEMENTS_CATALOG.size()
	var unlocked_count: int = 0
	for def in ACHIEVEMENTS_CATALOG:
		if _unlocked_achievements.has(def["id"]):
			unlocked_count += 1

	if is_instance_valid(_profile_score_label):
		_profile_score_label.text = "%d / %d UNLOCKED" % [unlocked_count, total_count]
	if is_instance_valid(_profile_progress_bar):
		_profile_progress_bar.max_value = maxi(total_count, 1)
		_profile_progress_bar.value = unlocked_count

	for f_id in _profile_filter_buttons:
		var btn: Button = _profile_filter_buttons[f_id] as Button
		if is_instance_valid(btn):
			var active: bool = (f_id == _achievement_filter)
			btn.add_theme_color_override("font_color", GOLD if active else MUTED)

	if not is_instance_valid(_profile_achievements_list):
		return
	for child in _profile_achievements_list.get_children():
		child.queue_free()

	var shown_count: int = 0
	for def in ACHIEVEMENTS_CATALOG:
		var aid: StringName = def["id"]
		var is_unlocked: bool = _unlocked_achievements.has(aid)
		if _achievement_filter == &"unlocked" and not is_unlocked:
			continue
		if _achievement_filter == &"locked" and is_unlocked:
			continue
		shown_count += 1
		_profile_achievements_list.add_child(_build_achievement_card(def, is_unlocked))

	if shown_count == 0:
		var empty_lbl := _label("None yet.", 10, MUTED)
		_profile_achievements_list.add_child(empty_lbl)


func _build_achievement_card(def: Dictionary, is_unlocked: bool) -> Control:
	var row_bg: Color = Color(0.04, 0.07, 0.09, 0.72) if is_unlocked else Color(0.018, 0.03, 0.042, 0.45)
	var row_border: Color = Color(1.0, 0.78, 0.38, 0.45) if is_unlocked else Color(0.16, 0.24, 0.28, 0.3)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 36.0
	card.add_theme_stylebox_override("panel", _flat_box(row_bg, row_border, 12.0, 6.0, 1))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(hbox)

	var medal := AchievementMedalIcon.new()
	medal.unlocked = is_unlocked
	medal.medal_color = GOLD
	hbox.add_child(medal)

	var t_lbl := _label(str(def["title"]).to_upper(), 10, PALE if is_unlocked else Color(0.48, 0.56, 0.60))
	t_lbl.custom_minimum_size.x = 150.0
	hbox.add_child(t_lbl)

	var d_lbl := _label(str(def["desc"]), 9, MUTED if is_unlocked else Color(0.36, 0.44, 0.48))
	d_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d_lbl.clip_text = true
	hbox.add_child(d_lbl)

	var status_lbl := _label("UNLOCKED" if is_unlocked else "LOCKED", 9, GOLD if is_unlocked else Color(0.34, 0.42, 0.46))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(status_lbl)

	return card


func _select_hotbar(index: int, allow_toggle_unequip: bool = false) -> void:
	if index < 0 or index >= _hotbar_items.size():
		return
	if allow_toggle_unequip and _selected_hotbar_index == index and _equipment_items.get(&"tool", &"") != &"":
		_unequip_active_tool()
		return
	_selected_hotbar_index = index
	var selected_item: StringName = _hotbar_items[index]
	if selected_item != &"" and ITEM_DATA.has(selected_item):
		var slot_name: StringName = ITEM_DATA[selected_item]["equip_slot"]
		_equipment_items[slot_name] = selected_item
	else:
		_equipment_items[&"tool"] = &""
	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()


func _unequip_active_tool() -> void:
	_selected_hotbar_index = -1
	_equipment_items[&"tool"] = &""
	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()


func _sync_player_equipped_item() -> void:
	var active_item: StringName = StringName(_equipment_items.get(&"tool", &""))
	if _selected_hotbar_index >= 0 and _selected_hotbar_index < _hotbar_items.size():
		var hb_item: StringName = _hotbar_items[_selected_hotbar_index]
		if hb_item != &"":
			active_item = hb_item
			_equipment_items[&"tool"] = hb_item
		else:
			active_item = &""
			_equipment_items[&"tool"] = &""
	var suit_eq_item: StringName = StringName(_equipment_items.get(&"suit", &""))
	var suit_has_light: bool = (suit_eq_item == &"suit_flashlight") or _unlocked_items.has(&"suit_flashlight")
	if is_instance_valid(_player):
		if _player.has_method("set_suit_flashlight_unlocked"):
			_player.set_suit_flashlight_unlocked(suit_has_light)
		if active_item == &"":
			_player.unequip_item()
		else:
			_player.equip_item(active_item)
	_update_equipped_status_banner()


func _update_equipped_status_banner() -> void:
	if not is_instance_valid(_equipped_status_label):
		return
	var active_item: StringName = StringName(_equipment_items.get(&"tool", &""))
	var suit_eq_item: StringName = StringName(_equipment_items.get(&"suit", &""))
	var light_unlocked: bool = _unlocked_items.has(&"suit_flashlight") or (suit_eq_item == &"suit_flashlight")
	var light_on: bool = false
	if is_instance_valid(_player) and _player.has_method("is_suit_flashlight_enabled"):
		light_on = _player.is_suit_flashlight_enabled()
	var light_str: String = ("ON" if light_on else "OFF") if light_unlocked else "LOCKED"
	if active_item != &"" and ITEM_DATA.has(active_item):
		var full_name: String = str(ITEM_DATA[active_item]["name"]).to_upper()
		_equipped_status_label.text = "EQUIPPED: %s   //   [SHOOT / SPACE] USE   [PICK UP / E]   [DROP / G]   [F] LIGHT: %s" % [full_name, light_str]
		_equipped_status_label.add_theme_color_override("font_color", _item_color(active_item))
	else:
		_equipped_status_label.text = "UNARMED // [PICK UP] GEAR OR COMPLETE TASKS   //   [F] SUIT LIGHT: %s" % light_str
		_equipped_status_label.add_theme_color_override("font_color", MUTED)
	_refresh_mobile_controls()


func _build_mobile_touch_controls() -> void:
	_mobile_controls_layer = Control.new()
	_mobile_controls_layer.name = "MobileTouchControls"
	_mobile_controls_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mobile_controls_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_mobile_controls_layer)

	# Bottom-Left Virtual Joystick
	_mobile_joystick = MobileTouchJoystick.new()
	_mobile_joystick.name = "MobileJoystick"
	_mobile_joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_mobile_joystick.offset_left = 20.0
	_mobile_joystick.offset_top = -168.0
	_mobile_joystick.offset_right = 168.0
	_mobile_joystick.offset_bottom = -20.0
	_mobile_controls_layer.add_child(_mobile_joystick)

	# Bottom-Right Conditional SHOOT Button (ONLY visible when a weapon or equipment item is equipped)
	_mobile_shoot_btn = _button("SHOOT", Vector2(216.0, 52.0), ORANGE)
	_mobile_shoot_btn.name = "MobileShootButton"
	_mobile_shoot_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mobile_shoot_btn.offset_left = -236.0
	_mobile_shoot_btn.offset_top = -134.0
	_mobile_shoot_btn.offset_right = -20.0
	_mobile_shoot_btn.offset_bottom = -82.0
	_mobile_shoot_btn.focus_mode = Control.FOCUS_NONE
	_mobile_shoot_btn.visible = false
	_mobile_shoot_btn.button_down.connect(_on_mobile_shoot_down)
	_mobile_shoot_btn.button_up.connect(_on_mobile_shoot_up)
	_mobile_controls_layer.add_child(_mobile_shoot_btn)

	# Bottom-Right PICK UP & DROP Buttons
	var action_row := HBoxContainer.new()
	action_row.name = "MobileItemActionsRow"
	action_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	action_row.offset_left = -236.0
	action_row.offset_top = -72.0
	action_row.offset_right = -20.0
	action_row.offset_bottom = -20.0
	action_row.add_theme_constant_override("separation", 8)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_controls_layer.add_child(action_row)

	_mobile_pickup_btn = _button("PICK UP", Vector2(104.0, 52.0), CYAN)
	_mobile_pickup_btn.name = "MobilePickUpButton"
	_mobile_pickup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mobile_pickup_btn.focus_mode = Control.FOCUS_NONE
	_mobile_pickup_btn.pressed.connect(_on_mobile_pickup_pressed)
	action_row.add_child(_mobile_pickup_btn)

	_mobile_drop_btn = _button("DROP", Vector2(104.0, 52.0), GOLD)
	_mobile_drop_btn.name = "MobileDropButton"
	_mobile_drop_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mobile_drop_btn.focus_mode = Control.FOCUS_NONE
	_mobile_drop_btn.pressed.connect(_on_mobile_drop_pressed)
	action_row.add_child(_mobile_drop_btn)


func _refresh_mobile_controls() -> void:
	if not is_instance_valid(_mobile_controls_layer):
		return
	var show_controls: bool = _walking_visible and _active_overlay == &""
	_mobile_controls_layer.visible = show_controls
	if not show_controls:
		if is_instance_valid(_player) and _player.has_method("set_touch_shoot_held"):
			_player.set_touch_shoot_held(false)
		return

	var active_item: StringName = StringName(_equipment_items.get(&"tool", &""))
	if is_instance_valid(_player) and _player.has_method("get_equipped_item"):
		var p_item: StringName = _player.get_equipped_item()
		if p_item != &"":
			active_item = p_item

	if is_instance_valid(_mobile_shoot_btn):
		var has_equipped_weapon_or_tool: bool = (active_item != &"")
		_mobile_shoot_btn.visible = has_equipped_weapon_or_tool
		if has_equipped_weapon_or_tool:
			var short_lbl: String = _short_item_name(active_item)
			_mobile_shoot_btn.text = "SHOOT // %s" % short_lbl if not short_lbl.is_empty() else "SHOOT"
			_mobile_shoot_btn.add_theme_color_override("font_color", _item_color(active_item))

	if is_instance_valid(_mobile_pickup_btn):
		var nearby_idx: int = _find_nearest_dropped_world_item(76.0)
		if nearby_idx >= 0:
			var d_id: StringName = _dropped_world_items[nearby_idx]["item_id"]
			_mobile_pickup_btn.add_theme_color_override("font_color", _item_color(d_id))
		elif is_instance_valid(_context_prompt) and _context_prompt.visible:
			_mobile_pickup_btn.add_theme_color_override("font_color", GOLD)
		else:
			_mobile_pickup_btn.add_theme_color_override("font_color", CYAN)

	if is_instance_valid(_mobile_drop_btn):
		_mobile_drop_btn.add_theme_color_override("font_color", ORANGE if active_item != &"" else MUTED)


func _on_mobile_shoot_down() -> void:
	if not _walking_visible or _active_overlay != &"":
		return
	if is_instance_valid(_player):
		if _player.has_method("set_touch_shoot_held"):
			_player.set_touch_shoot_held(true)
		elif _player.has_method("start_using_equipment"):
			_player.start_using_equipment(false)
		_update_equipped_status_banner()


func _on_mobile_shoot_up() -> void:
	if is_instance_valid(_player):
		if _player.has_method("set_touch_shoot_held"):
			_player.set_touch_shoot_held(false)
		elif _player.has_method("stop_using_equipment"):
			_player.stop_using_equipment()


func _on_mobile_pickup_pressed() -> void:
	pickup_nearby_or_interact()


func _on_mobile_drop_pressed() -> void:
	drop_active_item()


func _ensure_world_dropped_canvas() -> void:
	if not is_instance_valid(_player) or _player.get_parent() == null:
		return
	var parent_world: Node = _player.get_parent()
	if not is_instance_valid(_world_dropped_canvas) or _world_dropped_canvas.get_parent() != parent_world:
		_world_dropped_canvas = parent_world.get_node_or_null("WorldDroppedEquipmentCanvas") as Node2D
		if _world_dropped_canvas == null:
			_world_dropped_canvas = Node2D.new()
			_world_dropped_canvas.name = "WorldDroppedEquipmentCanvas"
			_world_dropped_canvas.z_index = 1
			parent_world.add_child.call_deferred(_world_dropped_canvas)
		if not _world_dropped_canvas.draw.is_connected(_on_world_dropped_canvas_draw):
			_world_dropped_canvas.draw.connect(_on_world_dropped_canvas_draw)
	if _dropped_world_items.is_empty():
		var spawn_center: Vector2 = _player.global_position
		_dropped_world_items.append({
			"item_id": &"captains_revolver",
			"pos": spawn_center + Vector2(-42.0, 8.0),
		})
		_dropped_world_items.append({
			"item_id": &"industrial_plasma_cutter",
			"pos": spawn_center + Vector2(42.0, 8.0),
		})


func _spawn_world_dropped_item(item_id: StringName, world_pos: Vector2) -> void:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return
	_ensure_world_dropped_canvas()
	_dropped_world_items.append({
		"item_id": item_id,
		"pos": world_pos,
	})
	if is_instance_valid(_world_dropped_canvas):
		_world_dropped_canvas.queue_redraw()


func _find_nearest_dropped_world_item(max_dist: float = 76.0) -> int:
	if not is_instance_valid(_player) or _dropped_world_items.is_empty():
		return -1
	var best_idx: int = -1
	var best_d: float = max_dist
	var ppos: Vector2 = _player.global_position
	for i in range(_dropped_world_items.size()):
		var entry: Dictionary = _dropped_world_items[i]
		var ipos: Vector2 = entry["pos"]
		var d: float = ppos.distance_to(ipos)
		if d <= best_d:
			best_d = d
			best_idx = i
	return best_idx


func _on_world_dropped_canvas_draw() -> void:
	if not is_instance_valid(_world_dropped_canvas):
		return
	var font: Font = PIXEL_THEME.default_font
	for i in range(_dropped_world_items.size()):
		var entry: Dictionary = _dropped_world_items[i]
		var item_id: StringName = entry["item_id"]
		if not ITEM_DATA.has(item_id):
			continue
		var pos: Vector2 = _world_dropped_canvas.to_local(entry["pos"])
		var col: Color = _item_color(item_id)
		var pulse: float = 0.5 + 0.5 * sin(_world_drop_pulse + float(i) * 1.4)
		_world_dropped_canvas.draw_circle(pos, 14.0 + pulse * 3.0, Color(col.r, col.g, col.b, 0.18 + 0.14 * pulse))
		_world_dropped_canvas.draw_arc(pos, 13.0 + pulse * 2.5, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.85), 1.5, false)
		_world_dropped_canvas.draw_circle(pos, 9.5, Color(0.012, 0.028, 0.042, 0.92))
		var tex: Texture2D = _item_icon_texture(item_id)
		if tex != null:
			var icon_rect := Rect2(pos - Vector2(10.0, 10.0), Vector2(20.0, 20.0))
			_world_dropped_canvas.draw_texture_rect(tex, icon_rect, false)
		if font != null and is_instance_valid(_player) and _player.global_position.distance_to(entry["pos"]) <= 96.0:
			var lbl_str: String = "[PICK UP] %s" % _short_item_name(item_id)
			_world_dropped_canvas.draw_string(font, pos + Vector2(-42.0, -16.0), lbl_str, HORIZONTAL_ALIGNMENT_CENTER, 84.0, 8, PALE)


func drop_active_item() -> bool:
	if not _walking_visible or _active_overlay != &"":
		return false
	var dropped_id: StringName = StringName(_equipment_items.get(&"tool", &""))
	if dropped_id == &"" and _selected_hotbar_index >= 0 and _selected_hotbar_index < _hotbar_items.size():
		dropped_id = _hotbar_items[_selected_hotbar_index]
	if dropped_id == &"":
		for i in range(_hotbar_items.size()):
			if _hotbar_items[i] != &"":
				dropped_id = _hotbar_items[i]
				_selected_hotbar_index = i
				break
	if dropped_id == &"":
		if is_instance_valid(_equipped_status_label):
			_equipped_status_label.text = "NO EQUIPPED WEAPON OR ITEM TO DROP"
		return false

	# Remove from hotbar / equipped slot
	var hb_idx: int = _hotbar_items.find(dropped_id)
	if hb_idx >= 0:
		_hotbar_items[hb_idx] = &""
	if _equipment_items.get(&"tool", &"") == dropped_id:
		_equipment_items[&"tool"] = &""
	_selected_hotbar_index = -1

	var drop_pos: Vector2 = Vector2(900.0, 500.0)
	if is_instance_valid(_player):
		if _player.has_method("set_touch_shoot_held"):
			_player.set_touch_shoot_held(false)
		var offset_dir: Vector2 = _player._get_facing_vector() if _player.has_method("_get_facing_vector") else Vector2.DOWN
		drop_pos = _player.global_position + offset_dir * 20.0
	_spawn_world_dropped_item(dropped_id, drop_pos)

	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()
	if is_instance_valid(_equipped_status_label) and ITEM_DATA.has(dropped_id):
		_equipped_status_label.text = "DROPPED: %s  //  TAP [PICK UP] WHEN NEARBY TO RECOVER" % str(ITEM_DATA[dropped_id]["name"]).to_upper()
		_equipped_status_label.add_theme_color_override("font_color", ORANGE)
	return true


func pickup_nearby_or_interact() -> bool:
	if not _walking_visible or _active_overlay != &"":
		return false
	_ensure_world_dropped_canvas()

	# 1. Pick up any nearby floor item within 82px
	var near_idx: int = _find_nearest_dropped_world_item(82.0)
	if near_idx >= 0:
		var picked_entry: Dictionary = _dropped_world_items[near_idx]
		var picked_id: StringName = picked_entry["item_id"]
		_dropped_world_items.remove_at(near_idx)
		if is_instance_valid(_world_dropped_canvas):
			_world_dropped_canvas.queue_redraw()
		_equip_or_store_picked_item(picked_id)
		return true

	# 2. If standing at an active station/task prompt, trigger the [E] interact action
	if is_instance_valid(_context_prompt) and _context_prompt.visible:
		var ev_press := InputEventAction.new()
		ev_press.action = &"interact"
		ev_press.pressed = true
		Input.parse_input_event(ev_press)
		var ev_rel := InputEventAction.new()
		ev_rel.action = &"interact"
		ev_rel.pressed = false
		Input.parse_input_event(ev_rel)
		return true

	# 3. If a floor item exists slightly further in the room (<= 180px), pick it up
	var room_idx: int = _find_nearest_dropped_world_item(180.0)
	if room_idx >= 0:
		var picked_entry2: Dictionary = _dropped_world_items[room_idx]
		var picked_id2: StringName = picked_entry2["item_id"]
		_dropped_world_items.remove_at(room_idx)
		if is_instance_valid(_world_dropped_canvas):
			_world_dropped_canvas.queue_redraw()
		_equip_or_store_picked_item(picked_id2)
		return true

	# 4. Otherwise, if unarmed and an item is in hotbar or storage, equip it into hand
	var active_item: StringName = StringName(_equipment_items.get(&"tool", &""))
	if active_item == &"":
		for i in range(_hotbar_items.size()):
			if _hotbar_items[i] != &"":
				_select_hotbar(i, false)
				return true
		for s in range(_storage_items.size()):
			var st_item: StringName = _storage_items[s]
			if st_item != &"" and ITEM_DATA.has(st_item) and ITEM_DATA[st_item]["equip_slot"] == &"tool":
				_on_inventory_cell_activated(&"storage", s)
				return true
	return false


func _equip_or_store_picked_item(item_id: StringName) -> void:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return
	_unlocked_items[item_id] = true
	var slot_idx: int = _hotbar_items.find(item_id)
	if slot_idx < 0:
		for i in range(_hotbar_items.size()):
			if _hotbar_items[i] == &"":
				_hotbar_items[i] = item_id
				slot_idx = i
				break
	if slot_idx >= 0:
		_selected_hotbar_index = slot_idx
	_equipment_items[ITEM_DATA[item_id]["equip_slot"]] = item_id
	_refresh_hotbar()
	_refresh_inventory_cells()
	_refresh_story_act_label()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()


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
