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
const PLANET_SCENE_PATH := "res://scenes/planet/mock_planet_exterior.tscn"
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
const RED := Color(1.0, 0.35, 0.35)
const VIOLET := Color(0.78, 0.56, 1.0)
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
		"desc": "High-temperature cutting head mounted on the extraction rig. It cuts mineral lattice and is not carried as a personal weapon.",
		"texture": preload("res://art/tools/industrial_plasma_cutter.png"), "icon_region": Rect2(95.0, 340.0, 840.0, 650.0),
	},
	&"harmonic_bypass_coupler": {
		"name": "Harmonic Bypass Coupler", "short": "BYPASS", "color": GOLD, "equip_slot": &"tool",
		"desc": "Mateo Ruiz's auxiliary frequency bridge. Bypasses the locked bore motor on the Erebos extraction rig.",
		"texture": preload("res://art/tools/engineering_multitool.png"), "icon_region": Rect2(45.0, 335.0, 930.0, 790.0),
	},
	&"resonance_ore_core": {
		"name": "Pristine Resonance Core", "short": "RESONANCE CORE", "color": CYAN, "equip_slot": &"pack",
		"desc": "High-purity crystalline ore extracted at 4-pulse harmonic resonance. Ready for Cargo Bay containment.",
		"texture": preload("res://art/planet/resonance_ore_sample.png"), "icon_region": Rect2(0.0, 0.0, 1240.0, 1268.0),
	},
	&"resonance_ore_core_fractured": {
		"name": "Fractured Resonance Core", "short": "FRACTURED CORE", "color": ORANGE, "equip_slot": &"pack",
		"desc": "Resonance core with lattice micro-fractures from unstable drilling harmonics. Requires careful stabilization.",
		"texture": preload("res://art/planet/resonance_ore_sample.png"), "icon_region": Rect2(0.0, 0.0, 1240.0, 1268.0),
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
	&"resonance_ore_sample": {
		"name": "Sealed Resonance Ore Sample", "short": "ORE SAMPLE", "color": CYAN, "equip_slot": &"pack",
		"desc": "Quest sample from Erebos. Deliver it to Dr. Amara Okoye for analysis.",
		"texture": preload("res://art/planet/resonance_ore_sample.png"), "icon_region": Rect2(0.0, 0.0, 1240.0, 1268.0),
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
const ITEM_LIMITS: Dictionary = {
	&"emergency_flare": {"default": 5, "max": 10, "unit": "FLARES"},
	&"captains_revolver": {"default": 6, "max": 18, "unit": "ROUNDS"},
	&"survey_beacon": {"default": 3, "max": 6, "unit": "BEACONS"},
	&"medical_injector": {"default": 3, "max": 5, "unit": "DOSES"},
	&"pressure_sealant": {"default": 50, "max": 100, "unit": "PSI"},
}


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


class AchievementMedalIcon extends Control:
	var medal_color: Color = Color(1.0, 0.78, 0.38, 1.0)
	var unlocked: bool = true

	func _ready() -> void:
		custom_minimum_size = Vector2(20.0, 20.0)
		size = Vector2(20.0, 20.0)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center: Vector2 = (size * 0.5).floor()
		var col: Color = medal_color if unlocked else Color(0.28, 0.36, 0.40, 0.55)
		draw_rect(Rect2(center + Vector2(-4.0, -6.0), Vector2(8.0, 6.0)), col, true)
		draw_rect(Rect2(center + Vector2(-6.0, -5.0), Vector2(2.0, 3.0)), col.darkened(0.2), true)
		draw_rect(Rect2(center + Vector2(4.0, -5.0), Vector2(2.0, 3.0)), col.darkened(0.2), true)
		draw_rect(Rect2(center + Vector2(-1.0, 0.0), Vector2(2.0, 4.0)), col, true)
		draw_rect(Rect2(center + Vector2(-4.0, 4.0), Vector2(8.0, 2.0)), col, true)


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
var _objective_toast: PanelContainer
var _objective_toast_title: Label
var _objective_toast_sub: Label
var _objective_toast_timer: float = 0.0
var _dev_sections: Dictionary = {}
var _dev_tab_buttons: Dictionary = {}
var _dev_active_tab: StringName = &"all"
var _dev_god_mode_active: bool = false
var _unlocked_items: Dictionary = {}
var _collected_logs: Dictionary = {}
var _unlocked_achievements: Dictionary = {}
var _current_story_act: String = "ACT I — THE LONG APPROACH"
var _item_amounts: Dictionary = {}
var _equipped_status_label: Label
var _story_act_label: Label
var _comms_panel: PanelContainer = null
var _comms_speaker_label: Label = null
var _comms_message_label: Label = null
var _comms_status_label: Label = null
var _comms_timer: float = 0.0
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
var _achievement_filter: StringName = &"all"
var _profile_score_label: Label
var _profile_progress_bar: ProgressBar
var _profile_achievements_list: VBoxContainer
var _profile_filter_buttons: Dictionary = {}
var _profile_view_tab: StringName = &"achievements"
var _profile_tab_buttons: Dictionary = {}
var _tasks_list_container: VBoxContainer
var _tasks_arsenal_container: VBoxContainer
var _tasks_progress_bar: ProgressBar
var _tasks_filter_tab: StringName = &"all"
var _tasks_filter_buttons: Dictionary = {}
var _arsenal_filter_tab: StringName = &"all"
var _tasks_status_summary_label: Label
var _tasks_arsenal_summary_label: Label
var _tasks_arsenal_bar: ProgressBar
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
var _operator_input_locked := false
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
	&"harmonic_bypass_coupler",
]

const ARSENAL_CATALOG: Array[Dictionary] = [
	{
		"id": &"captains_revolver",
		"category": "LETHAL WEAPON",
		"category_color": Color(1.0, 0.45, 0.25),
		"role": "12mm Kinetic Service Sidearm",
		"desc": "Standard-issue lethal sidearm surrendered by Commander Chen. Kinetic rounds pierce armor and blast structural bulkheads.",
		"unlock_lore": "Act IV Climax: Confront Commander Chen on Bridge during quarantine standoff.",
		"task_id": &"commanders_secret_bridge",
	},
	{
		"id": &"industrial_plasma_cutter",
		"category": "INDUSTRIAL TOOL",
		"category_color": Color(1.0, 0.78, 0.38),
		"role": "Thermal Plasma Cutting Beam",
		"desc": "High-temperature cutting beam for mineral lattice and damaged bulkheads. It cannot stop the Echo.",
		"unlock_lore": "Not issued during the Erebos survey. Find a safe industrial use later in the mission.",
		"task_id": &"subdeck_shadow_nest_check",
	},
	{
		"id": &"electrical_discharge_tool",
		"category": "STUN WEAPON",
		"category_color": Color(0.36, 0.9, 1.0),
		"role": "High-Voltage Arc Capacitor Tool",
		"desc": "Discharges high-voltage electric bursts that disrupt the acoustic and cellular matrix of colloidal fluid entities.",
		"unlock_lore": "Act IV, Chapter 3: Rescue Leila and assemble the capacitor arc tool together.",
		"task_id": &"subdeck_pipe_pressure",
	},
	{
		"id": &"mineral_survey_scanner",
		"category": "SURVEY INSTRUMENT",
		"category_color": Color(0.36, 0.9, 1.0),
		"role": "Sub-Harmonic Acoustic Detector",
		"desc": "Scans sub-surface ore density and tracks the four-pulse harmonic resonance frequency.",
		"unlock_lore": "Act I Milestone 3: Route hydroponics nutrient flow and isolate drone vibration telemetry.",
		"task_id": &"drone_vibration_scan",
	},
	{
		"id": &"survey_beacon",
		"category": "RECON INSTRUMENT",
		"category_color": Color(1.0, 0.78, 0.38),
		"role": "Deployable Waypoint Transponder",
		"desc": "Marks surface landing targets and deep cavern drop sites for planetary descent.",
		"unlock_lore": "Act I Milestone 4: Complete pre-descent shuttle bay beacon checklist.",
		"task_id": &"landing_prep_beacons",
	},
	{
		"id": &"emergency_flare",
		"category": "TACTICAL UTILITY",
		"category_color": Color(1.0, 0.5, 0.2),
		"role": "High-Output Magnesium Flare",
		"desc": "Ignites brilliantly to illuminate pitch-black caverns and distract hostile resonance forms.",
		"unlock_lore": "Act II Erebos: Survey at least 2 crystal anomaly sites on the planet surface.",
		"task_id": &"rig_test",
	},
	{
		"id": &"suit_flashlight",
		"category": "SUIT GEAR",
		"category_color": Color(0.94, 0.91, 0.82),
		"role": "Shoulder-Mounted High-Intensity LED Beam",
		"desc": "Shoulder-mounted floodlight. Press [F] anytime to illuminate darkened ship compartments.",
		"unlock_lore": "Act I Milestone 1: Listen to May's Yangon message & pilot ship through asteroid swarm.",
		"task_id": &"bridge_flight_piloting",
	},
	{
		"id": &"engineering_multitool",
		"category": "MAINTENANCE TOOL",
		"category_color": Color(1.0, 0.78, 0.38),
		"role": "Standard Diagnostic Instrument",
		"desc": "Used to calibrate power cells, bypass faulty relays, and synchronize electrical buses.",
		"unlock_lore": "Act I Milestone 2: Reconnect aux power bus and replace life-support scrubber cartridge.",
		"task_id": &"air_filter",
	},
	{
		"id": &"pressure_sealant",
		"category": "MAINTENANCE TOOL",
		"category_color": Color(0.36, 0.9, 1.0),
		"role": "Polymer Hull Sealant Injector",
		"desc": "Rapid-curing polymer foam injector. Seals microscopic hull breaches and fluid manifolds.",
		"unlock_lore": "Act I Milestone 3: Route hydroponics nutrient flow in greenhouse.",
		"task_id": &"nutrient_flow",
	},
	{
		"id": &"medical_injector",
		"category": "TACTICAL UTILITY",
		"category_color": Color(0.48, 0.93, 0.64),
		"role": "Neural Stimulant Auto-Injector",
		"desc": "Dispenses adrenaline and synthetic coagulant. Stabilizes vital signs during resonance attacks.",
		"unlock_lore": "Act III Lab Outbreak: Salvage emergency medical injector from overturned cart in med-lab.",
		"task_id": &"lab_trolley",
	},
	{
		"id": &"harmonic_bypass_coupler",
		"category": "MINING GEAR",
		"category_color": Color(1.0, 0.78, 0.38),
		"role": "Auxiliary Frequency Bridge",
		"desc": "Mateo Ruiz's auxiliary frequency bridge. Bypasses the locked bore motor on the Erebos extraction rig to enable deep core drilling.",
		"unlock_lore": "Act II Erebos: Report the rig bore failure to Amara, then collect the coupler from Mateo in the Shuttle Bay.",
		"task_id": &"erebos_deep_mining",
	},
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
	{"id": &"erebos_deep_mining", "title": "Echo In The Ore", "desc": "Extract an intact resonance core"},
	{"id": &"cargo_breach_inspection", "title": "Broken Containment", "desc": "Inspect breached core pod"},
	{"id": &"subdeck_inventory_manifest", "title": "False Signal", "desc": "Trace Ward's lure in Sub-Deck 02 storage"},
	{"id": &"subdeck_workshop_power", "title": "Sub-Deck Spark", "desc": "Restore S04 Workshop auxiliary power"},
	{"id": &"subdeck_coolant_manifold", "title": "Coolant Routing", "desc": "Align S05 Coolant Bay valves"},
	{"id": &"subdeck_pipe_pressure", "title": "High Voltage", "desc": "Stabilize Sub-Deck 02 turbines"},
	{"id": &"subdeck_shadow_nest_check", "title": "The Shadow Nest", "desc": "Analyze the sub-hull nest"},
	{"id": &"act_v_finale_home", "title": "Earthward", "desc": "Execute final helm protocol"},
]

const AUDIO_LOGS_CATALOG: Array[Dictionary] = [
	{
		"id": &"log_may_message",
		"title": "Paper Star",
		"speaker": "May (Yangon)",
		"act": "ACT I — SHIP",
		"location": "Cabin Bunk Terminal",
		"transcript": "May's personal farewell message from the Yangon spaceport rooftop. She handed Thura a folded foil origami paper star before launch, asking if astronauts ever get afraid. 'Remember: space only has the meaning you bring with you.'",
	},
	{
		"id": &"log_okoye_fields",
		"title": "Acoustic Growth Anomalies",
		"speaker": "Dr. Amara Okoye",
		"act": "ACT I — SHIP",
		"location": "Hydroponics Console",
		"transcript": "Astrobiology log 04. Okoye notes anomalous micro-harmonic vibrations resonating through the greenhouse fluid tubes. The root growth angles are orienting toward Erebos ahead of orbital insertion.",
	},
	{
		"id": &"log_ruiz_sponsors",
		"title": "Drill Governor Overclock",
		"speaker": "Mateo Ruiz",
		"act": "ACT I — SHIP",
		"location": "Drone Maintenance Rig",
		"transcript": "Ruiz venting frustration regarding corporate budgets. 'Management cut the core rig cooling lines by 40%. If the rock is hard crystal, I'm bypassing the safety governor myself. We aren't returning without our quota.'",
	},
	{
		"id": &"log_okoye_crystals",
		"title": "Reflective Lattice Scan",
		"speaker": "Dr. Amara Okoye",
		"act": "ACT II — EREBOS",
		"location": "Site K-12 Hollow Formations",
		"transcript": "Field survey recording. The cyan crystal formations at Site K-12 lack normal mineral cleavage planes. Under spectrum analysis, they do not merely reflect sunlight—they vibrate, absorbing and modulating acoustic pulses.",
	},
	{
		"id": &"log_ruiz_breach",
		"title": "Cavity Breach Mayday",
		"speaker": "Mateo Ruiz",
		"act": "ACT II — EREBOS",
		"location": "Main Subsurface Drill Breach",
		"transcript": "[HEAVY STATIC] The drill broke through! There's an open cavern down here... black structures like ribs. Wait—the rig lost all power! Something black is moving up the drill column! It's not stone, it's alive! [SIGNAL TERMINATED]",
	},
	{
		"id": &"log_okoye_containment_breach",
		"title": "Colloidal Fluidic Entity",
		"speaker": "Dr. Amara Okoye",
		"act": "ACT III — LAB",
		"location": "Wrecked Specimen Bench",
		"transcript": "Emergency recording! The containment glass fractured! The organism isn't mineral—it's a living colloidal suspension that mimics sound and memory! Kinetic rounds pass through its fluid mass! Use the high-voltage arc tool from my bench to stun it! [ALARM KLAXONS]",
	},
	{
		"id": &"log_chen_debate",
		"title": "Classified Mass Telemetry",
		"speaker": "Commander Maya Chen",
		"act": "ACT IV — BRIDGE",
		"location": "Mission Planning Table",
		"transcript": "Confidential flight log. Commander Chen confirms the specimen container gained 4.2 kilograms during ascent from Erebos. 'I chose not to alert Dr. Min. We lost two crew members. I needed the sample to prove their deaths were not in vain.'",
	},
	{
		"id": &"log_chen_farewell",
		"title": "Captain's Final Command",
		"speaker": "Commander Maya Chen",
		"act": "ACT IV — BRIDGE",
		"location": "Decontamination Airlock",
		"transcript": "My hands won't stop shaking. The acoustic humming in the walls... it's speaking in May's voice, Ruiz's voice, my own voice. Thura, take my revolver. Don't let that thing reach Earth. I'm sealing this hatch from the inside. Protect the navigation core.",
	},
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
	_build_objective_toast()


func _build_objective_toast() -> void:
	var toast := PanelContainer.new()
	_objective_toast = toast
	toast.name = "ObjectiveToast"
	toast.anchor_left = 0.5
	toast.anchor_top = 0.0
	toast.anchor_right = 0.5
	toast.anchor_bottom = 0.0
	toast.offset_left = -220.0
	toast.offset_top = 18.0
	toast.offset_right = 220.0
	toast.offset_bottom = 74.0
	var toast_style := _panel_style(Color(0.015, 0.035, 0.055, 0.96), Color(0.24, 0.95, 0.54, 0.9), 6.0)
	toast.add_theme_stylebox_override("panel", toast_style)
	toast.visible = false
	toast.modulate.a = 0.0
	_root.add_child(toast)

	var toast_vbox := VBoxContainer.new()
	toast_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toast_vbox.add_theme_constant_override("separation", 2)
	toast.add_child(toast_vbox)

	_objective_toast_title = _label("✔ OBJECTIVE COMPLETED", 15, Color(0.24, 0.95, 0.54))
	_objective_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_vbox.add_child(_objective_toast_title)

	_objective_toast_sub = _label("", 13, PALE)
	_objective_toast_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_toast_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_vbox.add_child(_objective_toast_sub)


func show_objective_toast(title: String, subtitle: String, is_complete: bool = false) -> void:
	if not is_instance_valid(_objective_toast) or not is_instance_valid(_objective_toast_title):
		return
	_objective_toast_title.text = title
	_objective_toast_title.add_theme_color_override("font_color", GREEN if is_complete else GOLD)
	_objective_toast_sub.text = subtitle
	_objective_toast.visible = true
	_objective_toast_timer = 3.5
	_play_mission_chime(is_complete)


func _play_mission_chime(is_complete: bool) -> void:
	if not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.bus = &"Master"
	add_child(player)
	var freq: float = 1174.66 if is_complete else 880.0
	var tone: AudioStreamWAV = DialogueAudioSynth.generate_tone(freq, 0.35 if is_complete else 0.2, 0.01, 0.12, "octave" if is_complete else "two_tone", 0.4)
	player.stream = tone
	player.play()
	player.finished.connect(player.queue_free)


func _is_equipment_task_entry(entry: Dictionary) -> bool:
	if bool(entry.get("is_equipment_task", false)):
		return true
	var reward_id: StringName = StringName(entry.get("reward_item", &""))
	return reward_id != &""


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


func _map_canvas_normalized_position(world_position: Vector2) -> Vector2:
	if _map_world_size.x <= 0.0 or _map_world_size.y <= 0.0:
		return Vector2.ZERO
	var world_normalized: Vector2 = (world_position - _map_world_origin) / _map_world_size
	if not is_instance_valid(_map_canvas):
		return world_normalized
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
	for entry in _task_entries:
		var tid: StringName = StringName(entry.get("id", &""))
		if tid == &"" or bool(_task_completed.get(tid, false)):
			continue
		if _show_all_active_tasks:
			active_ids.append(tid)
			continue
		active_ids.append(tid)
		break
	return active_ids


func is_task_unlocked_in_sequence(task_id: StringName) -> bool:
	var active_ids: Array[StringName] = _get_active_sequential_task_ids()
	return active_ids.has(task_id)
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


func set_task_completed(task_id: StringName, silent: bool = false) -> void:
	if _task_completed.has(task_id):
		var was_already_done: bool = bool(_task_completed[task_id])
		_task_completed[task_id] = true
		_refresh_mission_panel()
		_refresh_tasks_overlay()
		_update_world_task_markers()
		if not silent and not was_already_done:
			var completed_title := ""
			for entry in _task_entries:
				if StringName(entry.get("id", &"")) == task_id:
					completed_title = _format_clean_title(str(entry.get("title", "Duty")))
					break
			if not completed_title.is_empty():
				show_objective_toast("✔ OBJECTIVE COMPLETED", completed_title, true)
		unlock_achievement(task_id, silent or was_already_done)
	else:
		unlock_achievement(task_id, silent)


func set_show_all_active_tasks(show_all: bool) -> void:
	_show_all_active_tasks = show_all
	_refresh_mission_panel()
	_update_world_task_markers()


func set_map_textures(floor_tex: Texture2D, wall_tex: Texture2D) -> void:
	_custom_map_floor_tex = floor_tex
	_custom_map_wall_tex = wall_tex
	if is_instance_valid(_map_floor_layer) and floor_tex != null:
		_map_floor_layer.texture = floor_tex
	if is_instance_valid(_map_wall_layer) and wall_tex != null:
		_map_wall_layer.texture = wall_tex


func set_interaction_prompt(text: String, is_visible: bool) -> void:
	if not is_instance_valid(_context_prompt):
		return
	var formatted_text := text
	var key_hint_index := formatted_text.find("[E]")
	if key_hint_index != -1:
		# The E keycap is already displayed beside this text. Keep only the
		# immediate action so nearby prompts don't repeat the station name,
		# key, and mission description all at once.
		formatted_text = formatted_text.substr(key_hint_index + 3).strip_edges()
		formatted_text = formatted_text.trim_prefix("USE // ").trim_prefix("USE / ").trim_prefix("USE ")
		formatted_text = formatted_text.replace("   /   ", " ").replace(" // ", " · ").strip_edges()
	_context_label.text = formatted_text
	_context_prompt.visible = is_visible and _walking_visible and _active_overlay == &""


func set_walking_visible(is_visible: bool) -> void:
	_walking_visible = is_visible
	if is_instance_valid(_root):
		_root.visible = is_visible
	set_process_unhandled_input(is_visible)
	set_process_unhandled_key_input(is_visible)

func set_operator_input_locked(locked: bool) -> void:
	_operator_input_locked = locked
	if locked and is_instance_valid(_dev_panel): _dev_panel.hide()


func _on_inventory_cell_activated(slot_kind: StringName, slot_index: int) -> void:
	if _operator_input_locked: return
	if slot_kind == &"hotbar":
		_selected_hotbar_index = slot_index
		_refresh_hotbar()
		_refresh_inventory_cells()


func _on_inventory_drop_requested(target_kind: StringName, target_index: int, data: Dictionary) -> void:
	if _operator_input_locked: return
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
	if _operator_input_locked or not _walking_visible or not _overlay_nodes.has(overlay_name):
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


func _format_clean_title(raw_title: String) -> String:
	var clean := raw_title.strip_edges()
	if clean.begins_with("Amara: "):
		clean = clean.substr(7).strip_edges()
	var paren_pos := clean.find("(")
	if paren_pos != -1:
		var suffix := clean.substr(paren_pos)
		for marker in ["Task", "Unlock", "->", "Multitool", "Suit Light", "Plasma", "Discharger", "Scanner", "Act IV"]:
			if suffix.find(marker) != -1:
				clean = clean.substr(0, paren_pos).strip_edges()
				break
	var angle_pos := clean.find("<")
	if angle_pos != -1:
		clean = clean.substr(0, angle_pos).strip_edges()
	return clean


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
		var hotbar_item: StringName = _hotbar_items[_selected_hotbar_index]
		if hotbar_item != &"":
			active_item = hotbar_item
			_equipment_items[&"tool"] = hotbar_item
		else:
			active_item = &""
			_equipment_items[&"tool"] = &""
	var suit_item: StringName = StringName(_equipment_items.get(&"suit", &""))
	var flashlight_unlocked: bool = suit_item == &"suit_flashlight" or _unlocked_items.has(&"suit_flashlight")
	if is_instance_valid(_player):
		if _player.has_method("set_suit_flashlight_unlocked"):
			_player.set_suit_flashlight_unlocked(flashlight_unlocked)
		if active_item == &"":
			_player.unequip_item()
		else:
			_player.equip_item(active_item)
	_update_equipped_status_banner()


func _update_equipped_status_banner() -> void:
	if not is_instance_valid(_equipped_status_label):
		return
	var active_item: StringName = StringName(_equipment_items.get(&"tool", &""))
	var suit_item: StringName = StringName(_equipment_items.get(&"suit", &""))
	var flashlight_unlocked: bool = _unlocked_items.has(&"suit_flashlight") or suit_item == &"suit_flashlight"
	var flashlight_on := false
	if is_instance_valid(_player) and _player.has_method("is_suit_flashlight_enabled"):
		flashlight_on = _player.is_suit_flashlight_enabled()
	var flashlight_status := ("ON" if flashlight_on else "OFF") if flashlight_unlocked else "LOCKED"
	if active_item != &"" and ITEM_DATA.has(active_item):
		var item_name := str(ITEM_DATA[active_item]["name"]).to_upper()
		var amount_text := ""
		var banner_color: Color = _item_color(active_item)
		if is_item_limited(active_item):
			var amount := get_item_amount(active_item)
			amount_text = " [x%d]" % amount if amount > 0 else " [EMPTY / 0 LEFT]"
			if amount <= 0:
				banner_color = Color(1.0, 0.42, 0.35)
		_equipped_status_label.text = "EQUIPPED: %s%s  //  [F] LIGHT: %s" % [item_name, amount_text, flashlight_status]
		_equipped_status_label.add_theme_color_override("font_color", banner_color)
	else:
		_equipped_status_label.text = "UNARMED  //  [F] SUIT LIGHT: %s" % flashlight_status
		_equipped_status_label.add_theme_color_override("font_color", MUTED)


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
	if _operator_input_locked or not _walking_visible or _active_overlay != &"":
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_hotbar((_selected_hotbar_index - 1 + _hotbar_items.size()) % _hotbar_items.size())
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_hotbar((_selected_hotbar_index + 1) % _hotbar_items.size())
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if _operator_input_locked or not _walking_visible or not (event is InputEventKey) or not event.pressed or event.echo:
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


func grant_hotbar_item(item_id: StringName) -> bool:
	if not ITEM_DATA.has(item_id):
		return false
	if _hotbar_items.has(item_id) or _storage_items.has(item_id):
		return true
	for i in range(_hotbar_items.size()):
		if _hotbar_items[i] == &"":
			_hotbar_items[i] = item_id
			_refresh_hotbar()
			_refresh_inventory_cells()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	for i in range(_storage_items.size()):
		if _storage_items[i] == &"":
			_storage_items[i] = item_id
			_refresh_hotbar()
			_refresh_inventory_cells()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	return false


func consume_item(item_id: StringName) -> bool:
	for i in range(_hotbar_items.size()):
		if _hotbar_items[i] == item_id:
			_hotbar_items[i] = &""
			_refresh_hotbar()
			_refresh_inventory_cells()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	for i in range(_storage_items.size()):
		if _storage_items[i] == item_id:
			_storage_items[i] = &""
			_refresh_hotbar()
			_refresh_inventory_cells()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	return false


func inventory_count(item: StringName) -> int:
	var count := _storage_items.count(item) + _hotbar_items.count(item)
	for carried in _equipment_items.values():
		if StringName(carried) == item:
			count += 1
	return count


func _set_dev_active_tab(tab_id: StringName) -> void:
	_dev_active_tab = tab_id
	for t_id in _dev_tab_buttons:
		var btn: Button = _dev_tab_buttons[t_id]
		if is_instance_valid(btn):
			if t_id == tab_id:
				btn.add_theme_color_override("font_color", GOLD)
				btn.add_theme_stylebox_override("normal", _button_style(GOLD, true))
			else:
				btn.add_theme_color_override("font_color", MUTED)
				btn.add_theme_stylebox_override("normal", _button_style(MUTED, false))
	for s_id in _dev_sections:
		var sec: Control = _dev_sections[s_id]
		if is_instance_valid(sec):
			sec.visible = (tab_id == &"all" or tab_id == s_id)


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
	_dev_panel.offset_bottom = 510.0
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
	var mining_button := _button("START MINING TASK", Vector2(220, 36), GOLD)
	mining_button.tooltip_text = "Development shortcut: warp to the Erebos extraction rig with the mining task active."
	mining_button.pressed.connect(_on_dev_start_mining_task)
	stack.add_child(mining_button)

	_set_dev_active_tab(&"all")


func _on_dev_spawn_monster_chase(stage: int) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var current_scene := tree.current_scene
	if current_scene == null:
		return
	var villain: Node2D = tree.get_first_node_in_group("resonance_ore_villain") as Node2D
	if villain == null and current_scene.has_node("ResonanceOreVillain"):
		villain = current_scene.get_node("ResonanceOreVillain") as Node2D

	if villain == null:
		var villain_scene := load("res://scenes/ship/crew/resonance_ore_villain.tscn") as PackedScene
		if villain_scene != null:
			villain = villain_scene.instantiate() as Node2D
			var spawn_parent: Node = current_scene
			var floor_layer := current_scene.get_node_or_null("FloorLayer")
			if floor_layer != null:
				spawn_parent = floor_layer
			spawn_parent.add_child(villain)

	if villain != null:
		if is_instance_valid(_player):
			var spawn_offset := Vector2(160.0, 0.0)
			villain.global_position = _player.global_position + spawn_offset
		villain.set("stalk_player_distance", 9999.0)
		villain.set("is_active", true)
		villain.set("in_ducts", false)
		villain.visible = true
		match stage:
			1:
				if villain.has_method("fuse_with_amara"):
					villain.call("fuse_with_amara")
			2:
				if villain.has_method("mutate_to_stage2"):
					villain.call("mutate_to_stage2")
			3:
				if villain.has_method("mutate_to_final_form"):
					villain.call("mutate_to_final_form")
			_:
				villain.set("current_stage", 0)
				villain.set("is_fused_with_amara", false)
				villain.set("stalk_speed", 58.0)
				if villain.has_node("AnimatedSprite2D"):
					var spr := villain.get_node("AnimatedSprite2D") as AnimatedSprite2D
					spr.modulate = Color(0.3, 0.85, 1.0, 0.9)
					spr.scale = Vector2.ONE

		var lighting := _get_room_lighting()
		if lighting != null and lighting.has_method("set_flicker_current_room"):
			lighting.call("set_flicker_current_room", true)
			lighting.call("set_flicker_style", &"strobe")

		var stage_name := "ORIGINAL LIQUID ORE"
		var stage_color := CYAN
		match stage:
			1:
				stage_name = "STAGE 1 (INFECTED AMARA)"
				stage_color = CYAN
			2:
				stage_name = "STAGE 2 (MUTATED AMARA)"
				stage_color = ORANGE
			3:
				stage_name = "STAGE 3 (FINAL FORM TITAN)"
				stage_color = RED
		show_achievement_popup("PURSUIT TRIGGERED: " + stage_name, "Monster tracking at distance 9999", "DEV CHASE", stage_color)


func _on_dev_retreat_monster_ducts() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var villain: Node2D = tree.get_first_node_in_group("resonance_ore_villain") as Node2D
	var cur_scene := tree.current_scene
	if villain == null and cur_scene != null and cur_scene.has_node("ResonanceOreVillain"):
		villain = cur_scene.get_node("ResonanceOreVillain") as Node2D
	if villain != null and villain.has_method("disappear_into_ducts"):
		villain.call("disappear_into_ducts")
		show_achievement_popup("MONSTER RETREATED", "Villain entered ship ventilation ducts", "DEV MONSTER", CYAN)


func _on_dev_despawn_monster() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var villains := tree.get_nodes_in_group("resonance_ore_villain")
	for v in villains:
		v.queue_free()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.has_node("ResonanceOreVillain"):
		cur_scene.get_node("ResonanceOreVillain").queue_free()
	show_achievement_popup("MONSTER DESPAWNED", "All villain instances removed", "DEV MONSTER", MUTED)


func _on_dev_repel_monster_test(tool_id: StringName) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var villain: Node2D = tree.get_first_node_in_group("resonance_ore_villain") as Node2D
	var cur_scene := tree.current_scene
	if villain == null and cur_scene != null and cur_scene.has_node("ResonanceOreVillain"):
		villain = cur_scene.get_node("ResonanceOreVillain") as Node2D
	if villain != null and villain.has_method("repel_with_tool"):
		var p_pos := _player.global_position if is_instance_valid(_player) else Vector2.ZERO
		villain.call("repel_with_tool", tool_id, p_pos)
		show_achievement_popup("REPEL SIGNAL SENT", "Tested tool: %s" % tool_id, "DEV TEST", ORANGE)


func _on_dev_trigger_medbay_ambush() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	var target_medbay := Vector2(760.0, 200.0)
	if cur_scene != null and cur_scene.scene_file_path == "res://scenes/ship/bare_ship_walkthrough.tscn":
		if is_instance_valid(_player):
			_player.global_position = target_medbay
			if _player.camera != null:
				_player.camera.reset_smoothing()
		if cur_scene.has_method("_play_medbay_ambush_sequence"):
			cur_scene.call(&"_play_medbay_ambush_sequence")
	else:
		Engine.set_meta(&"dev_warp_target", target_medbay)
		Engine.set_meta(&"dev_trigger_ambush", true)
		tree.change_scene_to_file("res://scenes/ship/bare_ship_walkthrough.tscn")


func _on_dev_trigger_lab_breach() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	var target_lab := Vector2(430.0, 480.0)
	if cur_scene != null and cur_scene.scene_file_path == "res://scenes/ship/bare_ship_walkthrough.tscn":
		if is_instance_valid(_player):
			_player.global_position = target_lab
			if _player.camera != null:
				_player.camera.reset_smoothing()
		if cur_scene.has_method("_spawn_resonance_ore_villain"):
			cur_scene.call(&"_spawn_resonance_ore_villain", true)
		if cur_scene.has_method("_apply_lab_destruction_stage"):
			cur_scene.call(&"_apply_lab_destruction_stage", 2, true)
		show_achievement_popup("LAB BREACH TRIGGERED", "Containment shattered & ore unleashed", "DEV LAB", RED)
	else:
		Engine.set_meta(&"dev_warp_target", target_lab)
		Engine.set_meta(&"dev_trigger_lab_breach", true)
		tree.change_scene_to_file("res://scenes/ship/bare_ship_walkthrough.tscn")


func _on_dev_trigger_piloting_encounter(encounter_id: StringName) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.has_method("_open_ship_piloting_console"):
		cur_scene.call(&"_open_ship_piloting_console", encounter_id, true)
		return

	var pilot_script := load("res://scripts/ui/ship_piloting_console.gd") as Script
	if pilot_script != null:
		var pilot_console: CanvasLayer = pilot_script.new() as CanvasLayer
		if pilot_console != null:
			set_walking_visible(false)
			pilot_console.call(&"setup", encounter_id, true)
			pilot_console.connect(&"piloting_closed", func(): set_walking_visible(true))
			tree.root.add_child(pilot_console)


func _on_dev_set_cosmic_sector(sector_id: StringName) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	var backdrop: Node2D = null
	if cur_scene != null:
		backdrop = cur_scene.get_node_or_null("SpaceBackdrop") as Node2D
		if backdrop == null and cur_scene.get("space_backdrop") != null:
			backdrop = cur_scene.get("space_backdrop") as Node2D
	if backdrop == null:
		var found := tree.get_nodes_in_group("space_backdrop")
		if not found.is_empty():
			backdrop = found[0] as Node2D
	if backdrop != null and backdrop.has_method("set_cosmic_sector"):
		backdrop.call("set_cosmic_sector", sector_id, 1.5)
		show_achievement_popup("COSMIC SECTOR: " + str(sector_id).to_upper(), "Accretion/starfield blend active", "DEV COSMOS", GOLD)


func _on_dev_play_station_cutscene(station_id: StringName) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.has_method("_trigger_story_station"):
		cur_scene.call(&"_trigger_story_station", station_id)
		return
	if cur_scene != null and cur_scene.has_method("_build_cutscene_data"):
		var cutscene_data: Dictionary = cur_scene.call(&"_build_cutscene_data", station_id)
		if not cutscene_data.is_empty():
			var overlay_script := load("res://scripts/ui/story_cutscene_overlay.gd") as Script
			if overlay_script != null:
				var overlay: CanvasLayer = overlay_script.new() as CanvasLayer
				set_walking_visible(false)
				overlay.connect(&"cutscene_finished", func(_c_id, _ch_id):
					set_walking_visible(true)
					overlay.queue_free()
				)
				tree.root.add_child(overlay)
				overlay.call(&"play_cutscene", station_id, cutscene_data)


func _on_dev_play_prologue_montage() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	tree.change_scene_to_file("res://scenes/ui/earth_years_montage.tscn")


func _on_dev_play_thadingyut_cutscene() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cutscene_res := load("res://scenes/ui/thadingyut_memory_cutscene.tscn") as PackedScene
	if cutscene_res != null:
		var cutscene := cutscene_res.instantiate() as Control
		tree.root.add_child(cutscene)


func _on_dev_play_arrival_briefing() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var briefing_res := load("res://scenes/ui/arrival_briefing.tscn") as PackedScene
	if briefing_res != null:
		var briefing := briefing_res.instantiate() as CanvasLayer
		briefing.connect(&"dismissed", func(): briefing.queue_free())
		tree.root.add_child(briefing)


func _on_dev_play_epilogue(ending_id: StringName) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.has_method("_play_ending_epilogue"):
		cur_scene.call(&"_play_ending_epilogue", ending_id)


func _on_dev_warp_to_deck(scene_path: String, target_pos: Vector2) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.scene_file_path == scene_path:
		if is_instance_valid(_player):
			_player.global_position = target_pos
			if _player.camera != null:
				_player.camera.reset_smoothing()
		return
	Engine.set_meta(&"dev_warp_target", target_pos)
	tree.change_scene_to_file(scene_path)


func _on_dev_start_mining_task() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	Engine.set_meta(&"dev_start_mining_task", true)
	Engine.set_meta(&"harmonic_bypass_coupler_unlocked", true)
	Engine.set_meta(&"dev_warp_target", Vector2(1060.0, 520.0))
	get_tree().change_scene_to_file(PLANET_SCENE_PATH)


func _on_dev_warp_to_room_coords(scene_path: String, coords: Vector2, room_name: String) -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var cur_scene := tree.current_scene
	if cur_scene != null and cur_scene.scene_file_path == scene_path:
		if is_instance_valid(_player):
			_player.global_position = coords
			if _player.camera != null:
				_player.camera.reset_smoothing()
			show_achievement_popup("WARPED TO " + room_name.to_upper(), "Coordinates: %s" % str(coords), "DEV WARP", CYAN)
		return
	Engine.set_meta(&"dev_warp_target", coords)
	tree.change_scene_to_file(scene_path)


func _on_dev_toggle_god_mode() -> void:
	_dev_god_mode_active = not _dev_god_mode_active
	if is_instance_valid(_player):
		_player.is_concealed = _dev_god_mode_active
		if _dev_god_mode_active:
			_player.modulate = Color(0.6, 1.0, 0.9, 0.7)
			show_achievement_popup("GOD MODE: ENABLED", "Invisible to monster & invulnerable", "DEV CHEAT", GREEN)
		else:
			_player.modulate = Color(1.0, 1.0, 1.0, 1.0)
			show_achievement_popup("GOD MODE: DISABLED", "Standard vulnerability restored", "DEV CHEAT", MUTED)


func _on_dev_complete_all_tasks() -> void:
	var tasks_to_complete: Array[StringName] = [
		&"cabin_may_recording",
		&"bridge_flight_piloting",
		&"auxiliary_power",
		&"air_filter",
		&"nutrient_flow",
		&"drone_vibration_scan",
		&"landing_prep_beacons",
		&"erebos_landing_descent",
		&"cargo_breach_inspection",
		&"commanders_secret_bridge",
		&"subdeck_workshop_power",
		&"act_v_finale_home"
	]
	for t in tasks_to_complete:
		_task_completed[t] = true
	if is_inside_tree():
		var tree := get_tree()
		var cur_scene: Node = tree.current_scene if tree != null else null
		if cur_scene != null and cur_scene.get("_completed_story_stations") != null:
			var st_dict: Dictionary = cur_scene.get("_completed_story_stations")
			for t in tasks_to_complete:
				st_dict[t] = true
		if cur_scene != null and cur_scene.get("_completed_crew_tasks") != null:
			var cr_dict: Dictionary = cur_scene.get("_completed_crew_tasks")
			for t in tasks_to_complete:
				cr_dict[t] = true
	_validate_inventory_against_task_progression()
	_refresh_mission_panel()
	_refresh_tasks_overlay()
	_save_persistent_inventory_state()
	show_achievement_popup("ALL MISSIONS CLEARED", "All main and crew tasks marked complete", "DEV PROGRESS", GOLD)


func _on_dev_unlock_all_achievements() -> void:
	for def in ACHIEVEMENTS_CATALOG:
		var aid: StringName = def["id"]
		unlock_achievement(aid, false)
	show_achievement_popup("ALL ACHIEVEMENTS UNLOCKED", "Every medal awarded", "DEV ACHIEVE", GOLD)


func _on_dev_override_crew_survival(all_survive: bool) -> void:
	Engine.set_meta(&"commander_chen_saved", all_survive)
	Engine.set_meta(&"mateo_ruiz_saved", all_survive)
	Engine.set_meta(&"leila_rescued", all_survive)
	Engine.set_meta(&"elias_ward_saved", all_survive)
	if is_inside_tree():
		var tree := get_tree()
		var current_scene: Node = tree.current_scene if tree != null else null
		if current_scene != null:
			if current_scene.get("_chen_rescued") != null:
				current_scene.set("_chen_rescued", all_survive)
			if current_scene.get("_leila_rescued") != null:
				current_scene.set("_leila_rescued", all_survive)
	var status_text := "ALL CREW SURVIVED (CHEN, MATEO, LEILA, WARD)" if all_survive else "ALL CREW FALLEN / SACRIFICED"
	show_achievement_popup("CREW FATE OVERRIDE", status_text, "DEV STORY", GREEN if all_survive else RED)


func _on_dev_trigger_asteroid_cutscene() -> void:
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if not is_inside_tree():
		return
	var tree := get_tree()
	var current_scene: Node = tree.current_scene
	if current_scene != null and current_scene.has_method("trigger_emergency_asteroid_cutscene"):
		current_scene.call("trigger_emergency_asteroid_cutscene")


func _on_dev_switch_deck() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var current_scene := tree.current_scene
	if current_scene != null and current_scene.scene_file_path == "res://scenes/ship/second_floor_subdeck.tscn":
		Engine.set_meta(&"returning_from_second_floor", true)
		tree.change_scene_to_file("res://scenes/ship/bare_ship_walkthrough.tscn")
	else:
		tree.change_scene_to_file("res://scenes/ship/second_floor_subdeck.tscn")


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
		var saved_amounts: Dictionary = state.get("item_amounts", {})
		for item_id in saved_amounts:
			_item_amounts[StringName(item_id)] = int(saved_amounts[item_id])
		for item_id in _unlocked_items:
			if ITEM_LIMITS.has(item_id) and not _item_amounts.has(item_id):
				_item_amounts[item_id] = ITEM_LIMITS[item_id]["default"]
		_validate_inventory_against_task_progression()
		var suit_item: StringName = StringName(_equipment_items.get(&"suit", &""))
		var flashlight_unlocked: bool = _unlocked_items.has(&"suit_flashlight") or suit_item == &"suit_flashlight"
		if is_instance_valid(_player):
			if _player.has_method("sync_equipment_amounts"):
				_player.sync_equipment_amounts(_item_amounts)
			if _player.has_method("set_suit_flashlight_unlocked"):
				_player.set_suit_flashlight_unlocked(flashlight_unlocked)
			if _player.has_method("set_suit_flashlight_enabled"):
				_player.set_suit_flashlight_enabled(bool(state.get("flashlight_enabled", flashlight_unlocked)))
	else:
		_validate_inventory_against_task_progression()
		_save_persistent_inventory_state()


func _is_progression_item_allowed(item_id: StringName) -> bool:
	if not ALL_PROGRESSION_ITEMS.has(item_id):
		return true
	# Ignore legacy unlock flags for combat items whose former Erebos-era unlocks
	# were removed from the story progression. Completed mission state is the
	# source of truth so old saves cannot carry chapter-late weapons back early.
	var progression_locked_item := item_id in [&"emergency_flare", &"industrial_plasma_cutter", &"electrical_discharge_tool"]
	if not progression_locked_item and Engine.has_meta(str(item_id) + "_unlocked") and bool(Engine.get_meta(str(item_id) + "_unlocked")):
		return true
	match item_id:
		&"suit_flashlight":
			return bool(_task_completed.get(&"bridge_flight_piloting", false))
		&"engineering_multitool":
			return bool(_task_completed.get(&"air_filter", false)) or bool(_task_completed.get(&"subdeck_workshop_power", false))
		&"pressure_sealant":
			return bool(_task_completed.get(&"nutrient_flow", false)) or bool(_task_completed.get(&"drone_vibration_scan", false)) or bool(_task_completed.get(&"subdeck_coolant_manifold", false))
		&"mineral_survey_scanner":
			return bool(_task_completed.get(&"drone_vibration_scan", false))
		&"survey_beacon":
			return bool(_task_completed.get(&"landing_prep_beacons", false))
		&"emergency_flare":
			return bool(_task_completed.get(&"subdeck_inventory_manifest", false))
		&"industrial_plasma_cutter":
			return false
		&"electrical_discharge_tool":
			var story_state: Dictionary = Engine.get_meta(&"echoes_story_progression_state", {})
			return bool(_task_completed.get(&"subdeck_pipe_pressure", false)) and bool(story_state.get("leila_rescued", false))
		&"medical_injector":
			return bool(_task_completed.get(&"lab_trolley", false))
		&"captains_revolver":
			return bool(_task_completed.get(&"commanders_secret_bridge", false)) or bool(_task_completed.get(&"act_v_finale_home", false))
		&"harmonic_bypass_coupler":
			return Engine.has_meta(&"harmonic_bypass_coupler_unlocked") and bool(Engine.get_meta(&"harmonic_bypass_coupler_unlocked"))
	return false


func _validate_inventory_against_task_progression() -> void:
	for item_id in ALL_PROGRESSION_ITEMS:
		if not _is_progression_item_allowed(item_id):
			if _unlocked_items.has(item_id):
				_unlocked_items.erase(item_id)
			for i in range(_hotbar_items.size()):
				if _hotbar_items[i] == item_id:
					_hotbar_items[i] = &""
			for s in range(_storage_items.size()):
				if _storage_items[s] == item_id:
					_storage_items[s] = &""
			for slot in _equipment_items:
				if _equipment_items[slot] == item_id:
					_equipment_items[slot] = &""
			if _item_amounts.has(item_id):
				_item_amounts.erase(item_id)

	var has_hotbar_item := false
	for i in range(_hotbar_items.size()):
		if _hotbar_items[i] != &"":
			has_hotbar_item = true
			break
	if not has_hotbar_item:
		_selected_hotbar_index = 0
		_equipment_items[&"tool"] = &""


func _save_persistent_inventory_state() -> void:
	var flashlight_on := false
	if is_instance_valid(_player) and _player.has_method("is_suit_flashlight_enabled"):
		flashlight_on = _player.is_suit_flashlight_enabled()
	var state := {
		"hotbar": _hotbar_items.duplicate(),
		"storage": _storage_items.duplicate(),
		"equipment": _equipment_items.duplicate(),
		"item_amounts": _item_amounts.duplicate(),
		"selected_hotbar_index": _selected_hotbar_index,
		"unlocked_items": _unlocked_items.duplicate(),
		"collected_logs": _collected_logs.duplicate(),
		"unlocked_achievements": _unlocked_achievements.duplicate(),
		"story_act": _current_story_act,
		"flashlight_enabled": flashlight_on,
	}
	Engine.set_meta(CAMPAIGN_META_KEY, state)


func is_item_limited(item_id: StringName) -> bool:
	return ITEM_LIMITS.has(item_id)


func get_item_amount(item_id: StringName) -> int:
	if not ITEM_LIMITS.has(item_id):
		return -1
	if not _item_amounts.has(item_id):
		_item_amounts[item_id] = ITEM_LIMITS[item_id]["default"]
	return int(_item_amounts[item_id])


func get_item_max_amount(item_id: StringName) -> int:
	if not ITEM_LIMITS.has(item_id):
		return -1
	return int(ITEM_LIMITS[item_id]["max"])


func set_item_amount(item_id: StringName, amount: int) -> void:
	if not ITEM_LIMITS.has(item_id):
		return
	var max_amt: int = int(ITEM_LIMITS[item_id]["max"])
	_item_amounts[item_id] = clampi(amount, 0, max_amt)
	if is_instance_valid(_player) and _player.has_method("set_equipment_amount"):
		_player.set_equipment_amount(item_id, _item_amounts[item_id])
	_refresh_hotbar()
	_refresh_inventory_cells()
	_update_equipped_status_banner()
	_save_persistent_inventory_state()


func add_item_amount(item_id: StringName, delta: int) -> int:
	if not ITEM_LIMITS.has(item_id):
		return -1
	var cur: int = get_item_amount(item_id)
	var max_amt: int = int(ITEM_LIMITS[item_id]["max"])
	var new_amt: int = clampi(cur + delta, 0, max_amt)
	set_item_amount(item_id, new_amt)
	return new_amt


func restock_all_equipment_amounts() -> void:
	for item_id in ITEM_LIMITS:
		_item_amounts[item_id] = int(ITEM_LIMITS[item_id]["max"])
		if is_instance_valid(_player) and _player.has_method("set_equipment_amount"):
			_player.set_equipment_amount(item_id, _item_amounts[item_id])
	_refresh_hotbar()
	_refresh_inventory_cells()
	_update_equipped_status_banner()
	_save_persistent_inventory_state()
	if is_instance_valid(_equipped_status_label):
		_equipped_status_label.text = "ALL FLARES, ROUNDS, BEACONS & DOSES RESTOCKED TO MAXIMUM"
		_equipped_status_label.add_theme_color_override("font_color", GREEN)


func _on_player_equipment_amount_changed(item_id: StringName, remaining_amount: int) -> void:
	_item_amounts[item_id] = remaining_amount
	_refresh_hotbar()
	_refresh_inventory_cells()
	_update_equipped_status_banner()
	_save_persistent_inventory_state()


func _on_player_equipment_depleted(item_id: StringName) -> void:
	if not ITEM_DATA.has(item_id):
		return
	var iname: String = str(ITEM_DATA[item_id]["name"]).to_upper()
	if is_instance_valid(_equipped_status_label):
		_equipped_status_label.text = "OUT OF %s (0 LEFT)   //   RESTOCK AT STORAGE OR SHIP CRATES" % iname
		_equipped_status_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.35))


func has_equipment_item(item_id: StringName) -> bool:
	return _unlocked_items.has(item_id)


func get_unlocked_equipment_count() -> int:
	return _unlocked_items.size()


func get_collected_logs_count() -> int:
	return _collected_logs.size()


func get_equipment_items() -> Dictionary:
	return _equipment_items.duplicate()


func get_hotbar_items() -> Array[StringName]:
	return _hotbar_items.duplicate()


func get_storage_items() -> Array[StringName]:
	return _storage_items.duplicate()


func get_active_overlay() -> StringName:
	return _active_overlay


func record_audio_log(log_id: StringName, _log_title: String = "") -> bool:
	if log_id == &"" or _collected_logs.has(log_id):
		return false
	_collected_logs[log_id] = true
	_refresh_story_act_label()
	_refresh_profile_overlay()
	_refresh_mission_panel()
	_refresh_tasks_overlay()
	_save_persistent_inventory_state()
	var def: Dictionary = get_audio_log_def(log_id)
	if not def.is_empty():
		var spk: String = str(def.get("speaker", "AUDIO INTERCEPT"))
		var title_str: String = str(def.get("title", "DATAPAD")).to_upper()
		var txt: String = str(def.get("transcript", ""))
		play_radio_transmission(spk, "[DECRYPTED // %s]\n\"%s\"" % [title_str, txt])
	return true


func get_audio_log_def(log_id: StringName) -> Dictionary:
	for def in AUDIO_LOGS_CATALOG:
		if def["id"] == log_id:
			return def
	return {}


func play_radio_transmission(speaker: String, text: String, is_static: bool = true) -> void:
	if not is_instance_valid(_comms_panel):
		return
	if is_instance_valid(_comms_speaker_label):
		_comms_speaker_label.text = ("// " + speaker).to_upper()
	if is_instance_valid(_comms_status_label):
		_comms_status_label.text = "[● STATIC INTERCOM]" if is_static else "[● SECURE LINK]"
		_comms_status_label.add_theme_color_override("font_color", ORANGE if is_static else CYAN)
	if is_instance_valid(_comms_message_label):
		_comms_message_label.text = text
	_comms_panel.visible = true
	_comms_timer = 5.8
	_comms_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(_comms_panel, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)


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
	Engine.set_meta(str(item_id) + "_unlocked", true)
	var already_had: bool = _unlocked_items.has(item_id)
	_unlocked_items[item_id] = true
	if ITEM_LIMITS.has(item_id):
		if not _item_amounts.has(item_id) or int(_item_amounts[item_id]) <= 0:
			_item_amounts[item_id] = int(ITEM_LIMITS[item_id]["default"])
		else:
			_item_amounts[item_id] = mini(int(_item_amounts[item_id]) + int(ITEM_LIMITS[item_id]["default"]), int(ITEM_LIMITS[item_id]["max"]))
		if is_instance_valid(_player) and _player.has_method("set_equipment_amount"):
			_player.set_equipment_amount(item_id, _item_amounts[item_id])

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
	_refresh_mission_panel()
	_refresh_tasks_overlay()
	if not already_had:
		show_equipment_unlocked_toast(item_id, reason_text)
	return not already_had


func unlock_all_equipment_items() -> void:
	for item_id in ALL_PROGRESSION_ITEMS:
		unlock_equipment_item(item_id, false, "Dev Menu Full Loadout")
		if is_item_limited(item_id):
			set_item_amount(item_id, get_item_max_amount(item_id))
	_select_hotbar(0, false)
	show_equipment_unlocked_toast(&"captains_revolver", "ALL 10 EQUIPMENT ITEMS UNLOCKED & RESTOCKED")


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
	_refresh_mission_panel()
	_refresh_tasks_overlay()
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
	for tid in _profile_tab_buttons:
		var tb: Button = _profile_tab_buttons[tid] as Button
		if is_instance_valid(tb):
			var is_active: bool = (tid == _profile_view_tab)
			tb.add_theme_color_override("font_color", GOLD if is_active else MUTED)

	for fid in _profile_filter_buttons:
		var fb: Button = _profile_filter_buttons[fid] as Button
		if is_instance_valid(fb):
			fb.visible = (_profile_view_tab == &"achievements")
			var is_active: bool = (fid == _achievement_filter)
			fb.add_theme_color_override("font_color", CYAN if is_active else MUTED)

	if not is_instance_valid(_profile_achievements_list):
		return
	for child in _profile_achievements_list.get_children():
		child.queue_free()

	if _profile_view_tab == &"achievements":
		var total_count: int = ACHIEVEMENTS_CATALOG.size()
		var unlocked_count: int = 0
		for def in ACHIEVEMENTS_CATALOG:
			if _unlocked_achievements.has(def["id"]):
				unlocked_count += 1
		if is_instance_valid(_profile_score_label):
			_profile_score_label.text = "%d / %d ACHIEVEMENTS" % [unlocked_count, total_count]
		if is_instance_valid(_profile_progress_bar):
			_profile_progress_bar.max_value = maxi(total_count, 1)
			_profile_progress_bar.value = unlocked_count

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
			_profile_achievements_list.add_child(_label("None yet.", 10, MUTED))
	else:
		var total_logs: int = AUDIO_LOGS_CATALOG.size()
		var unlocked_logs: int = 0
		for log_def in AUDIO_LOGS_CATALOG:
			if _collected_logs.has(log_def["id"]):
				unlocked_logs += 1
		if is_instance_valid(_profile_score_label):
			_profile_score_label.text = "%d / %d LOGS DECRYPTED" % [unlocked_logs, total_logs]
		if is_instance_valid(_profile_progress_bar):
			_profile_progress_bar.max_value = maxi(total_logs, 1)
			_profile_progress_bar.value = unlocked_logs

		for log_def in AUDIO_LOGS_CATALOG:
			var lid: StringName = log_def["id"]
			var is_unlocked: bool = _collected_logs.has(lid)
			_profile_achievements_list.add_child(_build_audio_log_card(log_def, is_unlocked))


func _build_audio_log_card(log_def: Dictionary, is_unlocked: bool) -> Control:
	var row_bg: Color = Color(0.04, 0.07, 0.09, 0.88) if is_unlocked else Color(0.018, 0.03, 0.042, 0.5)
	var row_border: Color = Color(0.24, 0.95, 0.54, 0.55) if is_unlocked else Color(0.18, 0.26, 0.3, 0.35)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _flat_box(row_bg, row_border, 8.0, 10.0, 1))

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	card.add_child(stack)

	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 8)
	stack.add_child(hdr_row)

	var act_tag := _label("[%s // %s]" % [str(log_def.get("act", "ACT")), str(log_def.get("location", "DECK"))], 8, CYAN if is_unlocked else MUTED)
	hdr_row.add_child(act_tag)
	hdr_row.add_spacer(false)
	var status_tag := _label("[● DECRYPTED]" if is_unlocked else "[LOCKED FILE]", 8, GREEN if is_unlocked else Color(0.85, 0.45, 0.35))
	hdr_row.add_child(status_tag)

	var title_text: String = str(log_def.get("title", "Audio Log"))
	var speaker_text: String = str(log_def.get("speaker", "Unknown"))
	var title_lbl := _label("%s  //  %s" % [title_text.to_upper(), speaker_text], 10, GOLD if is_unlocked else MUTED)
	stack.add_child(title_lbl)

	var body_text: String = str(log_def.get("transcript", "")) if is_unlocked else "[Encrypted audio datapad. Discover this station in Asteria-1 or Erebos to decrypt recording.]"
	var body_lbl := _label(body_text, 9, PALE if is_unlocked else MUTED)
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body_lbl)

	return card


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


func _refresh_tasks_overlay() -> void:
	if not is_instance_valid(_tasks_list_container) or not is_instance_valid(_tasks_arsenal_container):
		return

	# Update sub-filter button states for tasks
	for f_id in _tasks_filter_buttons:
		var btn: Button = _tasks_filter_buttons[f_id]
		var is_active: bool = (f_id == _tasks_filter_tab)
		btn.add_theme_color_override("font_color", GOLD if is_active else MUTED)
		var f_bg := Color(0.05, 0.09, 0.13, 0.9) if is_active else Color(0.02, 0.035, 0.05, 0.5)
		var f_border: Color = GOLD if is_active else Color(0.18, 0.28, 0.34, 0.45)
		btn.add_theme_stylebox_override("normal", _flat_box(f_bg, f_border, 10.0, 4.0, 1))

	# 2. Populate Tasks List
	for child in _tasks_list_container.get_children():
		_tasks_list_container.remove_child(child)
		child.queue_free()

	var completed_tasks := 0
	for tid in _task_completed:
		if bool(_task_completed[tid]):
			completed_tasks += 1
	var total_tasks := _task_entries.size()
	if is_instance_valid(_tasks_status_summary_label):
		_tasks_status_summary_label.text = "%d / %d COMPLETED" % [completed_tasks, maxi(total_tasks, 1)]
		_tasks_status_summary_label.add_theme_color_override("font_color", GREEN if completed_tasks >= total_tasks and total_tasks > 0 else Color(0.48, 0.93, 0.64))

	if is_instance_valid(_tasks_progress_bar):
		_tasks_progress_bar.max_value = maxi(total_tasks, 1)
		_tasks_progress_bar.value = completed_tasks

	var active_ids := _get_active_sequential_task_ids()
	var step_idx := 0
	for entry in _task_entries:
		step_idx += 1
		var tid: StringName = StringName(entry.get("id", &""))
		var is_done: bool = bool(_task_completed.get(tid, false))
		var is_active_task: bool = active_ids.has(tid)

		if _tasks_filter_tab == &"active" and is_done:
			continue
		if _tasks_filter_tab == &"active" and not is_active_task:
			continue
		if _tasks_filter_tab == &"completed" and not is_done:
			continue

		var card := PanelContainer.new()
		var card_bg: Color
		var card_border: Color
		if is_done:
			card_bg = Color(0.012, 0.032, 0.022, 0.92)
			card_border = Color(0.2, 0.52, 0.34, 0.5)
		elif is_active_task:
			card_bg = Color(0.016, 0.045, 0.065, 0.96)
			card_border = Color(0.35, 0.82, 0.98, 0.85)
		else:
			card_bg = Color(0.016, 0.025, 0.036, 0.88)
			card_border = Color(0.18, 0.28, 0.36, 0.45)

		card.add_theme_stylebox_override("panel", _flat_box(card_bg, card_border, 16.0, 10.0, 1))

		var card_box := VBoxContainer.new()
		card_box.add_theme_constant_override("separation", 4)
		card.add_child(card_box)

		# Top header row: Room · Step · Status
		var card_top := HBoxContainer.new()
		card_top.add_theme_constant_override("separation", 8)

		var room_text: String = str(entry.get("room_name", entry.get("marker_label", "MAIN DECK"))).to_upper()
		var room_lbl := _label(room_text, 10, CYAN if not is_done else Color(0.48, 0.72, 0.62))
		card_top.add_child(room_lbl)

		var bullet := _label("·", 10, MUTED)
		card_top.add_child(bullet)

		var step_lbl := _label("STEP %02d" % step_idx, 10, MUTED)
		card_top.add_child(step_lbl)

		card_top.add_spacer(false)

		var status_badge := Label.new()
		status_badge.add_theme_font_size_override("font_size", 10)
		if is_done:
			status_badge.text = "COMPLETED ✔"
			status_badge.add_theme_color_override("font_color", GREEN)
		elif is_active_task:
			status_badge.text = "● ACTIVE OBJECTIVE"
			status_badge.add_theme_color_override("font_color", ORANGE)
		else:
			status_badge.text = "PENDING"
			status_badge.add_theme_color_override("font_color", Color(0.45, 0.55, 0.62))
		card_top.add_child(status_badge)
		card_box.add_child(card_top)

		# Task title (clean, readable)
		var clean_title := _format_clean_title(str(entry.get("title", "Watch Duty")))
		var title_lbl := _label(clean_title, 13, PALE if not is_done else Color(0.72, 0.84, 0.76))
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_box.add_child(title_lbl)

		# Action hint
		var hint_str: String = str(entry.get("action_hint", entry.get("prompt", "")))
		if not hint_str.is_empty():
			var hint_lbl := _label("▶  " + hint_str, 10, Color(0.68, 0.84, 0.9) if not is_done else Color(0.48, 0.62, 0.55))
			hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(hint_lbl)
		var purpose_str: String = str(entry.get("purpose", ""))
		if not purpose_str.is_empty():
			var purpose_lbl := _label("WHY  " + purpose_str, 10, Color(0.68, 0.76, 0.82) if not is_done else Color(0.48, 0.62, 0.55))
			purpose_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card_box.add_child(purpose_lbl)

		# Reward preview row
		var r_item: StringName = StringName(entry.get("reward_item", &""))
		var m_item: StringName = StringName(entry.get("milestone_reward", r_item))
		if r_item != &"" and ITEM_DATA.has(r_item):
			var r_name: String = str(ITEM_DATA[r_item]["name"]).to_upper()
			var r_lbl := Label.new()
			r_lbl.add_theme_font_size_override("font_size", 10)
			if is_done:
				r_lbl.text = "★ WEAPON SECURED: " + r_name
				r_lbl.add_theme_color_override("font_color", GREEN)
			else:
				r_lbl.text = "⚡ UNLOCKS WEAPON: " + r_name
				r_lbl.add_theme_color_override("font_color", GOLD)
			card_box.add_child(r_lbl)
		elif m_item != &"" and ITEM_DATA.has(m_item):
			var m_name: String = str(ITEM_DATA[m_item]["name"]).to_upper()
			var m_lbl := Label.new()
			m_lbl.add_theme_font_size_override("font_size", 10)
			if is_done:
				m_lbl.text = "✓ CONTRIBUTED TOWARDS: " + m_name
				m_lbl.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
			else:
				m_lbl.text = "◈ ADVANCES ARSENAL MILESTONE: " + m_name
				m_lbl.add_theme_color_override("font_color", CYAN)
			card_box.add_child(m_lbl)

		_tasks_list_container.add_child(card)

	# 3. Populate Arsenal Progression Showcase
	for child in _tasks_arsenal_container.get_children():
		_tasks_arsenal_container.remove_child(child)
		child.queue_free()

	var unlocked_arsenal_count := 0
	for item_def in ARSENAL_CATALOG:
		var item_id: StringName = item_def["id"]
		var is_unlocked: bool = _unlocked_items.has(item_id) or (Engine.has_meta(str(item_id) + "_unlocked") and bool(Engine.get_meta(str(item_id) + "_unlocked")))
		if is_unlocked:
			unlocked_arsenal_count += 1

		if _arsenal_filter_tab == &"unlocked" and not is_unlocked:
			continue
		if _arsenal_filter_tab == &"locked" and is_unlocked:
			continue

		var card := PanelContainer.new()
		var card_bg := Color(0.015, 0.038, 0.028, 0.95) if is_unlocked else Color(0.016, 0.025, 0.036, 0.88)
		var card_border := Color(0.24, 0.82, 0.52, 0.7) if is_unlocked else Color(0.18, 0.28, 0.35, 0.45)
		card.add_theme_stylebox_override("panel", _flat_box(card_bg, card_border, 16.0, 10.0, 1))

		var card_hbox := HBoxContainer.new()
		card_hbox.add_theme_constant_override("separation", 14)
		card.add_child(card_hbox)

		# Icon thumbnail
		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(44, 44)
		icon_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var if_bg := Color(0.02, 0.05, 0.04) if is_unlocked else Color(0.018, 0.025, 0.032)
		var if_border: Color = item_def["category_color"] if is_unlocked else Color(0.25, 0.35, 0.4)
		icon_frame.add_theme_stylebox_override("panel", _flat_box(if_bg, if_border, 4.0, 4.0, 1))

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(36, 36)
		icon_rect.texture = _item_icon_texture(item_id)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if not is_unlocked:
			icon_rect.modulate = Color(0.38, 0.48, 0.55, 0.55)
		icon_frame.add_child(icon_rect)
		card_hbox.add_child(icon_frame)

		# Details stack
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 3)
		card_hbox.add_child(details)

		# Header row
		var d_top := HBoxContainer.new()
		d_top.add_theme_constant_override("separation", 8)

		var cat_lbl := _label(str(item_def["category"]), 10, item_def["category_color"])
		d_top.add_child(cat_lbl)

		var bullet := _label("·", 10, MUTED)
		d_top.add_child(bullet)

		var name_str: String = str(ITEM_DATA[item_id]["name"]).to_upper() if ITEM_DATA.has(item_id) else str(item_id).to_upper()
		var name_lbl := _label(name_str, 12, PALE if is_unlocked else Color(0.72, 0.82, 0.88))
		d_top.add_child(name_lbl)

		d_top.add_spacer(false)

		var status_badge := Label.new()
		status_badge.add_theme_font_size_override("font_size", 10)
		if is_unlocked:
			var is_equipped: bool = _equipment_items.values().has(item_id) or _hotbar_items.has(item_id)
			status_badge.text = "EQUIPPED" if is_equipped else "AUTHORIZED ✔"
			status_badge.add_theme_color_override("font_color", GREEN)
		else:
			status_badge.text = "LOCKED 🔒"
			status_badge.add_theme_color_override("font_color", Color(1.0, 0.5, 0.38))
		d_top.add_child(status_badge)
		details.add_child(d_top)

		# Role
		var role_lbl := _label(str(item_def["role"]), 10, Color(0.68, 0.82, 0.9))
		details.add_child(role_lbl)

		# Unlock Lore / Requirement
		var lore_lbl := Label.new()
		lore_lbl.add_theme_font_size_override("font_size", 10)
		lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_unlocked:
			lore_lbl.text = "✔ STATUS: Authorized for field operations."
			lore_lbl.add_theme_color_override("font_color", Color(0.48, 0.93, 0.64))
		else:
			lore_lbl.text = "🔒 CLEARANCE: " + str(item_def["unlock_lore"])
			lore_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.4))
		details.add_child(lore_lbl)

		_tasks_arsenal_container.add_child(card)

	if is_instance_valid(_tasks_arsenal_summary_label):
		_tasks_arsenal_summary_label.text = "%d / %d UNLOCKED" % [unlocked_arsenal_count, ARSENAL_CATALOG.size()]
	if is_instance_valid(_tasks_arsenal_bar):
		_tasks_arsenal_bar.max_value = ARSENAL_CATALOG.size()
		_tasks_arsenal_bar.value = unlocked_arsenal_count


func _select_hotbar(index: int, allow_toggle_unequip: bool = false) -> void:
	if _operator_input_locked or index < 0 or index >= _hotbar_items.size():
		return
	if allow_toggle_unequip and _selected_hotbar_index == index and _equipment_items.get(&"tool", &"") != &"":
		_unequip_active_tool()
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
