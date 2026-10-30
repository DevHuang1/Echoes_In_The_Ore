class_name WalkHud
extends CanvasLayer

signal modal_state_changed(is_open: bool)
signal inventory_changed
signal mission_scenario_requested(context: String)

const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const PIXEL_THEME := preload("res://themes/ship_pixel_theme.tres")
const STORY_SAVE := preload("res://scripts/ship/ship_story_save.gd")
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
const RED := Color(1.0, 0.35, 0.35)
const SURFACE := Color(0.035, 0.055, 0.085)
const SURFACE_RAISED := Color(0.042, 0.084, 0.103)
const SURFACE_HOVER := Color(0.068, 0.125, 0.141)
const EDGE := Color(0.34, 0.51, 0.55)
const EDGE_SOFT := Color(0.24, 0.39, 0.43)

const ITEM_DATA := {
	&"filter_cartridge": {
		"name": "FILTER-A / sealed airflow cartridge", "short": "FILTER-A", "color": CYAN, "equip_slot": &"",
		"desc": "Standard atmospheric filtration unit for life support scrubbers.",
	},
	&"scrubber_media": {
		"name": "SCRUB-A / CO2 scrubber medium", "short": "SCRUB-A", "color": GREEN, "equip_slot": &"",
		"desc": "Chemical reactant pack for CO2 reduction manifolds.",
	},
	&"coolant_charge": {
		"name": "COOL-02 / sealed service coolant", "short": "COOL-02", "color": CYAN, "equip_slot": &"",
		"desc": "Pressurized cryogenic coolant charge for secondary thermal loops.",
	},
	&"nutrient_buffer": {
		"name": "BUFFER-A / nutrient dilution dose", "short": "BUFFER", "color": GREEN, "equip_slot": &"",
		"desc": "Concentrated mineral nutrient dose for hydroponic growth cycles.",
	},
	&"oxygen_reserve": {
		"name": "O2-01 / oxygen reserve cylinder", "short": "O2-01", "color": PALE, "equip_slot": &"",
		"desc": "High-pressure emergency oxygen canister.",
	},
	&"inert_purge": {
		"name": "N2-03 / inert purge cylinder", "short": "N2-03", "color": MUTED, "equip_slot": &"",
		"desc": "Inert nitrogen gas canister for line clearing and pressure balancing.",
	},
	&"captains_revolver": {
		"name": "Captain's Revolver", "short": "REVOLVER", "color": ORANGE, "equip_slot": &"tool",
		"desc": "Lethal 12mm service sidearm surrendered by Commander Chen. Kinetic rounds are deadly against structural cores and bulkheads.",
		"texture": preload("res://art/tools/captains_revolver.png"), "icon_region": Rect2(35.0, 292.0, 960.0, 880.0),
	},
	&"industrial_plasma_cutter": {
		"name": "Industrial Plasma Cutter", "short": "PLASMA", "color": GOLD, "equip_slot": &"tool",
		"desc": "High-temperature thermal cutting beam recovered from Ruiz's drill rig. Cuts dense mineral lattices and wards off shadow entities.",
		"texture": preload("res://art/tools/industrial_plasma_cutter.png"), "icon_region": Rect2(89.0, 340.0, 840.0, 650.0),
	},
	&"suit_flashlight": {
		"name": "Suit Flashlight", "short": "LIGHT", "color": PALE, "equip_slot": &"suit",
		"desc": "Harness-mounted high-intensity LED beam. Press [F] to illuminate darkened ship compartments and subsurface caverns.",
		"texture": preload("res://art/tools/suit_flashlight.png"), "icon_region": Rect2(65.0, 360.0, 900.0, 620.0),
	},
	&"mineral_survey_scanner": {
		"name": "Mineral Survey Scanner", "short": "SCANNER", "color": CYAN, "equip_slot": &"tool",
		"desc": "Sub-harmonic acoustic detector. Maps ore density and tracks the four-pulse resonance signatures.",
		"texture": preload("res://art/tools/mineral_survey_scanner.png"), "icon_region": Rect2(90.0, 232.0, 850.0, 940.0),
	},
	&"engineering_multitool": {
		"name": "Engineering Multitool", "short": "MULTI", "color": GOLD, "equip_slot": &"tool",
		"desc": "Standard Asteria-1 maintenance instrument. Used to calibrate relays, sync power cells, and bypass circuitry.",
		"texture": preload("res://art/tools/engineering_multitool.png"), "icon_region": Rect2(45.0, 335.0, 930.0, 790.0),
	},
	&"survey_beacon": {
		"name": "Survey Beacon", "short": "BEACON", "color": GOLD, "equip_slot": &"tool",
		"desc": "Deployable high-gain locator transponder. Marks navigation waypoints and deep-trench exploration drop sites.",
		"texture": preload("res://art/tools/survey_beacon.png"), "icon_region": Rect2(100.0, 350.0, 830.0, 780.0),
	},
	&"emergency_flare": {
		"name": "Emergency Flare", "short": "FLARE", "color": ORANGE, "equip_slot": &"tool",
		"desc": "High-output magnesium flare. Ignites intensely to illuminate broad subterranean spaces and distract entities.",
		"texture": preload("res://art/tools/emergency_flare.png"), "icon_region": Rect2(220.0, 225.0, 740.0, 940.0),
	},
	&"pressure_sealant": {
		"name": "Pressure Sealant", "short": "SEALANT", "color": CYAN, "equip_slot": &"tool",
		"desc": "Rapid-curing polymer foam injector. Seals microscopic hull fractures and coolant manifold leaks.",
		"texture": preload("res://art/tools/pressure_sealant.png"), "icon_region": Rect2(150.0, 390.0, 740.0, 780.0),
	},
	&"medical_injector": {
		"name": "Medical Injector", "short": "MEDICAL", "color": GREEN, "equip_slot": &"tool",
		"desc": "Emergency adrenaline and coagulant auto-injector salvaged from Dr. Okoye's lab med-cart.",
		"texture": preload("res://art/tools/medical_injector.png"), "icon_region": Rect2(180.0, 250.0, 760.0, 925.0),
	},
	&"electrical_discharge_tool": {
		"name": "Electrical Discharge Tool", "short": "DISCHARGE", "color": CYAN, "equip_slot": &"tool",
		"desc": "High-voltage arc capacitor tool salvaged from the wrecked specimen table. Stuns colloidal fluid entities.",
		"texture": preload("res://art/tools/electrical_discharge_tool.png"), "icon_region": Rect2(100.0, 410.0, 860.0, 710.0),
	},
	&"resonance_ore_sample": {
		"name": "Resonance Ore Sample", "short": "RES ORE", "color": GOLD, "equip_slot": &"pack",
		"desc": "Extracted crystalline resonance ore from the surface of Erebos.",
		"texture": preload("res://art/planet/resonance_ore_intact.png"), "icon_region": Rect2(140.0, 120.0, 974.0, 1014.0),
	},
}

const ITEM_LIMITS: Dictionary = {
	&"emergency_flare": {
		"default": 5,
		"max": 10,
		"unit": "FLARES",
	},
	&"captains_revolver": {
		"default": 6,
		"max": 18,
		"unit": "ROUNDS",
	},
	&"survey_beacon": {
		"default": 3,
		"max": 6,
		"unit": "BEACONS",
	},
	&"medical_injector": {
		"default": 3,
		"max": 5,
		"unit": "DOSES",
	},
	&"pressure_sealant": {
		"default": 50,
		"max": 100,
		"unit": "PSI",
	},
}

const EQUIPMENT_SLOTS: Array[StringName] = [&"head", &"suit", &"pack", &"tool"]
const EQUIPMENT_LABELS := [&"HEAD", &"SUIT", &"PACK", &"TOOL"]

## Ordered display data for the five First Watch missions.
const ROADMAP_STEPS: Array[Dictionary] = [
	{"mission": "story.a1.010_watch_briefing", "title": "Receive the Watch",
	 "room": "BRIDGE", "desc": "Speak to Maya at the bridge planning table beside the main helm.",
	 "receipt": "watch.accepted"},
	{"mission": "story.a1.020_meet_amara",     "title": "Review the Duty Roster",
	 "room": "QUARTERS", "desc": "Use the personal computer desk in Crew Quarters to compare roster records.",
	 "receipt": "roster.reviewed"},
	{"mission": "story.a1.030_aux_service",    "title": "Meet Amara & Inspect Delivery",
	 "room": "HYDROPONICS", "desc": "Talk to Amara in Hydroponics, then inspect nutrient delivery at the console.",
	 "receipt": "amara.observation_reported"},
	{"mission": "story.a1.040_irrigation_report", "title": "Restore Service Power & Irrigation",
	 "room": "POWER / HYDROPONICS", "desc": "Diagnose and restore auxiliary power, then verify nutrient delivery.",
	 "receipt": "power.reported"},
	{"mission": "story.a1.050_watch_handoff",  "title": "Hand Over the Watch",
	 "room": "BRIDGE", "desc": "Return to the bridge planning table and submit the verified watch summary.",
	 "receipt": "amara.repair_reported"},
]

const SHIP_CATALOG_AREAS := {
	"bridge":   Rect2(60,   195, 310, 300),
	"quarters": Rect2(275,  445, 390, 225),
	"cargo":    Rect2(690,  400, 535, 270),
	"engine":   Rect2(1338, 205, 290, 355),
	"power":    Rect2(1050, 255, 162, 140),
	"life":     Rect2(1215, 190, 160, 215),
	"hydro":    Rect2(15,   605, 600, 245),
	"shuttle":  Rect2(1190, 495, 190, 215),
}
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
			&"tasks":
				_block(origin, unit, 4, 3, 16, 18, tint.darkened(0.4), false)
				_block(origin, unit, 7, 1, 10, 4, tint)
				_block(origin, unit, 7, 7, 10, 2, ICON_PALE)
				_block(origin, unit, 7, 11, 10, 2, ICON_PALE)
				_block(origin, unit, 7, 15, 10, 2, ICON_PALE)
				_block(origin, unit, 5, 7, 2, 2, Color(0.48, 0.93, 0.64))
				_block(origin, unit, 5, 11, 2, 2, Color(0.48, 0.93, 0.64))
				_block(origin, unit, 5, 15, 2, 2, Color(1.0, 0.78, 0.38))
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
	var item_amount: int = -1
	var icon_size := 27.0
	var _badge: Label
	var _icon: TextureRect
	var _name: Label
	var _hovered := false

	func configure(kind: StringName, index: int, item: StringName, item_short: String, tint: Color, selected: bool, label_override := "", texture: Texture2D = null, amount: int = -1) -> void:
		slot_kind = kind
		slot_index = index
		item_id = item
		short_label = item_short
		icon_color = tint
		is_selected = selected
		slot_label = label_override
		item_texture = texture
		item_amount = amount
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

	func set_item(item: StringName, item_short: String, tint: Color, selected: bool, texture: Texture2D = null, amount: int = -1) -> void:
		item_id = item
		short_label = item_short
		icon_color = tint
		is_selected = selected
		item_texture = texture
		item_amount = amount
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
		if has_item:
			if item_amount >= 0:
				_name.text = "%s x%d" % [short_label, item_amount] if item_amount > 0 else "%s 0" % short_label
				_name.add_theme_color_override("font_color", icon_color if item_amount > 0 else Color(1.0, 0.42, 0.35))
			else:
				_name.text = short_label
				_name.add_theme_color_override("font_color", icon_color)
		else:
			_name.text = ("EMPTY" if slot_kind == &"equipment" else "")
			_name.add_theme_color_override("font_color", CELL_MUTED)
		if has_item and ITEM_DATA.has(item_id):
			var it_def: Dictionary = ITEM_DATA[item_id]
			var amt_str: String = ""
			if item_amount >= 0:
				amt_str = " [%d REMAINING]" % item_amount
			tooltip_text = "%s%s\n%s" % [str(it_def["name"]).to_upper(), amt_str, str(it_def.get("desc", ""))]
		elif has_item:
			tooltip_text = item_id.replace("_", " ").capitalize()
		else:
			tooltip_text = "Empty slot"

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
		var ib := get_tree().root.get_node_or_null("InputBindings") if is_inside_tree() and get_tree() != null and get_tree().root != null else null
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
var _mission_tracker_minimized: bool = false
var _mission_minimize_btn: Button
var _mission_details_box: VBoxContainer
var _objective_toast: PanelContainer
var _objective_toast_title: Label
var _objective_toast_sub: Label
var _objective_toast_timer: float = 0.0
var _last_active_task_id: StringName = &""
var _active_task_card: PanelContainer
var _active_room_tag: Label
var _active_priority_tag: Label
var _active_task_title: Label
var _active_action_hint: Label
var _active_reward_card: PanelContainer
var _active_reward_icon: TextureRect
var _active_reward_badge: Label
var _active_reward_name: Label
var _active_reward_desc: Label
var _upcoming_task_row: HBoxContainer
var _upcoming_task_label: Label
var _tasks_dossier_btn: Button
var _tasks_list_container: VBoxContainer
var _tasks_arsenal_container: VBoxContainer
var _tasks_main_tab: StringName = &"tasks"
var _tasks_main_tab_buttons: Dictionary = {}
var _tasks_tab_view: VBoxContainer
var _arsenal_tab_view: VBoxContainer
var _tasks_progress_bar: ProgressBar
var _tasks_filter_tab: StringName = &"all"
var _tasks_filter_buttons: Dictionary = {}
var _arsenal_filter_tab: StringName = &"all"
var _arsenal_filter_buttons: Dictionary = {}
var _tasks_status_summary_label: Label
var _tasks_arsenal_summary_label: Label
var _tasks_arsenal_bar: ProgressBar
var _top_controls: HBoxContainer
var _quickbar_frame: PanelContainer
var _status_pill: PanelContainer
var _pulse_anim_time: float = 0.0
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
var _profile_view_tab: StringName = &"achievements"
var _profile_tab_buttons: Dictionary = {}
var _comms_panel: PanelContainer = null
var _comms_speaker_label: Label = null
var _comms_message_label: Label = null
var _comms_status_label: Label = null
var _comms_timer: float = 0.0
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
var _storage_items: Array[StringName] = [
	&"", &"", &"", &"", &"", &"", &"", &"", &"",
	&"", &"", &"", &"", &"", &"", &"", &"", &"",
	&"", &"", &"", &"", &"", &"", &"", &"", &"",
]
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
var _show_all_active_tasks: bool = true
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
var _dev_sections: Dictionary = {}
var _dev_tab_buttons: Dictionary = {}
var _dev_active_tab: StringName = &"all"
var _dev_god_mode_active: bool = false
## ── Roadmap & story-map additions ───────────────────────────────────────────
var _story_completed_count: int = 0
var _story_objective_room: String = ""
var _story_last_unlock_slide: Dictionary = {}
var _roadmap_view_container: ScrollContainer = null
var _roadmap_replay_btn: Button = null
var _tasks_list_scroll: ScrollContainer = null
var _story_archives_view_container: ScrollContainer = null
var _story_archives_inner: VBoxContainer = null
## Objective pin on the ship map (story mode only)
var _map_obj_pin: MapPin = null
var _map_obj_pin_label: Label = null
var _mobile_controls_layer: Control = null
var _mobile_joystick: MobileTouchJoystick = null
var _mobile_shoot_btn: Button = null
var _mobile_pickup_btn: Button = null
var _mobile_drop_btn: Button = null
var _mobile_light_btn: Button = null
var _mobile_mode_toggle_btn: Button = null
var _top_mode_btn: Button = null
var _dropped_world_items: Array[Dictionary] = []
var _world_dropped_canvas: Node2D = null
var _world_drop_pulse: float = 0.0
var _item_amounts: Dictionary = {}
const DEV_FLICKER_STYLES: Array[StringName] = [&"erratic", &"strobe", &"brownout", &"pulse"]
const DEV_FLICKER_SPEEDS: Array[float] = [0.5, 1.0, 1.5, 2.5]
const CAMPAIGN_META_KEY: StringName = &"echoes_campaign_inventory_state"
const CHECKPOINT_META_KEY: StringName = &"echoes_last_checkpoint_state"

var _suit_status_label: Label = null
var _suit_progress_bar: ProgressBar = null
var _low_health_vignette: ColorRect = null
var _game_over_overlay: Control = null
var _game_over_telemetry_label: Label = null
var _game_over_btn_reload: Button = null
var _game_over_btn_restart: Button = null
var _game_over_btn_menu: Button = null
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
		"category": "HEAVY WEAPON",
		"category_color": Color(1.0, 0.78, 0.38),
		"role": "Thermal Plasma Cutting Beam",
		"desc": "High-temperature cutting beam recovered from Ruiz's rig. Slices through mineral crystalline lattice and repels shadow entities.",
		"unlock_lore": "Act II Erebos: Investigate the drilling rig breach cavity and recover Mateo Ruiz's cutter.",
		"task_id": &"north_viridian_ore",
	},
	{
		"id": &"electrical_discharge_tool",
		"category": "STUN WEAPON",
		"category_color": Color(0.36, 0.9, 1.0),
		"role": "High-Voltage Arc Capacitor Tool",
		"desc": "Discharges high-voltage electric bursts that disrupt the acoustic and cellular matrix of colloidal fluid entities.",
		"unlock_lore": "Act III Lab Outbreak: Salvage from wrecked specimen bench (or rescue Leila in Sub-Deck 02).",
		"task_id": &"lab_specimen",
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
	_load_persistent_inventory_state()
	_ensure_world_dropped_canvas()
	if is_instance_valid(_player):
		if not _player.equipment_amount_changed.is_connected(_on_player_equipment_amount_changed):
			_player.equipment_amount_changed.connect(_on_player_equipment_amount_changed)
		if not _player.equipment_depleted.is_connected(_on_player_equipment_depleted):
			_player.equipment_depleted.connect(_on_player_equipment_depleted)
		if not _player.suit_integrity_changed.is_connected(_on_suit_integrity_changed):
			_player.suit_integrity_changed.connect(_on_suit_integrity_changed)
		if not _player.player_died.is_connected(_on_player_died):
			_player.player_died.connect(_on_player_died)
		if _player.has_method("sync_equipment_amounts"):
			_player.sync_equipment_amounts(_item_amounts)
		_on_suit_integrity_changed(_player.get_suit_integrity(), _player.get_max_suit_integrity())
	_sync_player_equipped_item()
	if is_instance_valid(_world_task_marker_layer):
		for marker in _world_task_markers.values():
			if is_instance_valid(marker):
				marker.queue_free()
		_world_task_markers.clear()
		for entry in _task_entries:
			_add_world_task_marker(entry)
	if is_instance_valid(_map_canvas):
		for m_data in _map_task_markers.values():
			var pin = m_data.get("marker")
			if is_instance_valid(pin):
				pin.queue_free()
		_map_task_markers.clear()
		for entry in _task_entries:
			_add_map_task_marker(entry)
	_refresh_mission_panel()
	_refresh_tasks_overlay()
	_update_world_task_markers()


func _ready() -> void:
	layer = 10
	_build_ui()
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_queue_resize)
	_queue_resize()


func _process(delta: float) -> void:
	_world_drop_pulse = fposmod(_world_drop_pulse + delta * 3.5, TAU)
	if is_instance_valid(_world_dropped_canvas):
		_world_dropped_canvas.queue_redraw()
	_update_world_task_markers()
	_refresh_mobile_controls()
	if _objective_toast_timer > 0.0:
		_objective_toast_timer = maxf(_objective_toast_timer - delta, 0.0)
		if is_instance_valid(_objective_toast):
			if _objective_toast_timer > 3.0:
				_objective_toast.modulate.a = clampf((3.5 - _objective_toast_timer) / 0.5, 0.0, 1.0)
			elif _objective_toast_timer < 0.5:
				_objective_toast.modulate.a = clampf(_objective_toast_timer / 0.5, 0.0, 1.0)
			else:
				_objective_toast.modulate.a = 1.0
			if is_zero_approx(_objective_toast_timer):
				_objective_toast.visible = false
	if _unlock_toast_timer > 0.0:
		_unlock_toast_timer = maxf(_unlock_toast_timer - delta, 0.0)
		if is_zero_approx(_unlock_toast_timer) and is_instance_valid(_unlock_toast_panel):
			_unlock_toast_panel.visible = false
	if _comms_timer > 0.0:
		_comms_timer = maxf(_comms_timer - delta, 0.0)
		if is_zero_approx(_comms_timer) and is_instance_valid(_comms_panel):
			_comms_panel.visible = false
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
	if is_instance_valid(_root):
		_root.queue_free()
	_hotbar_slots.clear()
	_storage_cells.clear()
	_inventory_hotbar_cells.clear()
	_equipment_cells.clear()
	_overlay_nodes.clear()
	_modal_frames.clear()
	_mission_rows.clear()
	_world_task_markers.clear()
	_map_task_markers.clear()
	if _storage_items.size() < 27:
		_storage_items.resize(27)
		_storage_items.fill(&"")
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
	_build_comms_transmission_panel()
	_build_context_prompt()
	_build_hotbar()
	_build_low_health_vignette()
	_build_mobile_touch_controls()
	_create_map_overlay()
	for entry in _task_entries:
		_add_world_task_marker(entry)
	_create_tasks_overlay()
	_create_inventory_overlay()
	_create_profile_overlay()
	_create_settings_overlay()
	_build_game_over_overlay()
	_refresh_mission_panel()
	_refresh_tasks_overlay()
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
	panel.offset_right = 350.0
	panel.offset_bottom = 126.0
	var mission_style := _panel_style(Color(0.012, 0.024, 0.038, 0.92), Color(0.24, 0.65, 0.85, 0.75), 8.0)
	panel.add_theme_stylebox_override("panel", mission_style)
	_root.add_child(panel)

	var stack := VBoxContainer.new()
	_mission_stack = stack
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)

	# 1. Header Bar: Dot + "ACTIVE OBJECTIVE" + Step Badge + [-] Minimize + [T] Dossier Button
	var heading := HBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation", 6)

	var live_dot := Label.new()
	live_dot.text = "●"
	live_dot.add_theme_color_override("font_color", Color(0.24, 0.95, 0.54))
	live_dot.add_theme_font_size_override("font_size", 10)
	heading.add_child(live_dot)

	var hdr_lbl: Label = SKIN.clean_label("ACTIVE OBJECTIVE", SKIN.FONT_SMALL, GOLD)
	hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(hdr_lbl)

	heading.add_spacer(false)

	_mission_progress_label = SKIN.pixel_label("STEP 01 / 11", SKIN.FONT_TELEMETRY, GREEN)
	_mission_progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_mission_progress_label)

	_mission_minimize_btn = Button.new()
	_mission_minimize_btn.text = "—"
	_mission_minimize_btn.custom_minimum_size = Vector2(22, 20)
	_mission_minimize_btn.tooltip_text = "Minimize / Expand Objective Tracker"
	_mission_minimize_btn.add_theme_font_size_override("font_size", 9)
	_mission_minimize_btn.add_theme_color_override("font_color", PALE)
	_mission_minimize_btn.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.05, 0.08, 0.8), Color(0.3, 0.5, 0.6, 0.6), 3.0))
	_mission_minimize_btn.add_theme_stylebox_override("hover", _panel_style(Color(0.05, 0.12, 0.18, 0.95), GOLD, 3.0))
	_mission_minimize_btn.pressed.connect(_toggle_mission_tracker_minimized)
	heading.add_child(_mission_minimize_btn)

	_tasks_dossier_btn = Button.new()
	_tasks_dossier_btn.text = "[T]"
	_tasks_dossier_btn.custom_minimum_size = Vector2(28, 20)
	_tasks_dossier_btn.tooltip_text = "Open full Mission Dossier & Arsenal [T]"
	_tasks_dossier_btn.add_theme_font_size_override("font_size", 9)
	_tasks_dossier_btn.add_theme_color_override("font_color", CYAN)
	_tasks_dossier_btn.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.06, 0.09, 0.9), CYAN, 3.0))
	_tasks_dossier_btn.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.12, 0.18, 0.95), GOLD, 3.0))
	_tasks_dossier_btn.pressed.connect(_open_tasks)
	heading.add_child(_tasks_dossier_btn)
	stack.add_child(heading)

	# 2. Sleek Slim Progress Bar
	_mission_progress_bar = ProgressBar.new()
	_mission_progress_bar.min_value = 0.0
	_mission_progress_bar.max_value = maxi(_task_entries.size(), 1)
	_mission_progress_bar.show_percentage = false
	_mission_progress_bar.custom_minimum_size.y = 3.0
	_mission_progress_bar.add_theme_stylebox_override("background", _panel_style(Color(0.015, 0.03, 0.045), Color(0.12, 0.22, 0.28), 0.0))
	_mission_progress_bar.add_theme_stylebox_override("fill", _panel_style(Color(0.24, 0.95, 0.54), Color(0.24, 0.95, 0.54), 0.0))
	stack.add_child(_mission_progress_bar)

	# 3. Details Box (collapsible via minimize button)
	_mission_details_box = VBoxContainer.new()
	_mission_details_box.name = "MissionDetailsBox"
	_mission_details_box.add_theme_constant_override("separation", 3)
	stack.add_child(_mission_details_box)

	var card_top := HBoxContainer.new()
	card_top.add_theme_constant_override("separation", 6)
	_active_room_tag = SKIN.pixel_label("[CREW LIVING QUARTERS]", SKIN.FONT_TELEMETRY, CYAN)
	_active_priority_tag = SKIN.clean_label("CURRENT", SKIN.FONT_TINY, ORANGE)
	card_top.add_child(_active_room_tag)
	card_top.add_spacer(false)
	card_top.add_child(_active_priority_tag)
	_mission_details_box.add_child(card_top)

	_active_task_title = SKIN.clean_label("Play May's Yangon message", SKIN.FONT_BODY, PALE)
	_active_task_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_details_box.add_child(_active_task_title)

	_active_action_hint = SKIN.clean_label("▶ Access Thura's terminal desk at your bunk", SKIN.FONT_SMALL, Color(0.72, 0.88, 0.94))
	_active_action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mission_details_box.add_child(_active_action_hint)

	_build_objective_toast()


func _toggle_mission_tracker_minimized() -> void:
	_mission_tracker_minimized = not _mission_tracker_minimized
	if is_instance_valid(_mission_details_box):
		_mission_details_box.visible = not _mission_tracker_minimized
	if is_instance_valid(_mission_minimize_btn):
		_mission_minimize_btn.text = "+" if _mission_tracker_minimized else "—"
	if is_instance_valid(_mission_panel):
		_mission_panel.offset_bottom = _mission_panel.offset_top + (36.0 if _mission_tracker_minimized else 126.0)


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

	_objective_toast_title = SKIN.clean_label("✔ OBJECTIVE COMPLETED", SKIN.FONT_SUBHEAD, Color(0.24, 0.95, 0.54))
	_objective_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_vbox.add_child(_objective_toast_title)

	_objective_toast_sub = SKIN.clean_label("", SKIN.FONT_SMALL, PALE)
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


func _build_comms_transmission_panel() -> void:
	_comms_panel = PanelContainer.new()
	_comms_panel.name = "CommsTransmissionPanel"
	_comms_panel.anchor_left = 1.0
	_comms_panel.anchor_right = 1.0
	_comms_panel.anchor_top = 0.0
	_comms_panel.anchor_bottom = 0.0
	_comms_panel.offset_left = -440.0
	_comms_panel.offset_right = -16.0
	_comms_panel.offset_top = 172.0
	_comms_panel.offset_bottom = 276.0
	_comms_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comms_panel.visible = false
	_comms_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.012, 0.032, 0.048, 0.96), Color(0.24, 0.85, 0.72, 0.8), 8.0))
	_root.add_child(_comms_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comms_panel.add_child(stack)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(top_row)

	_comms_status_label = _label("[● STATIC INTERCOM]", 8, ORANGE)
	top_row.add_child(_comms_status_label)
	top_row.add_spacer(false)
	_comms_speaker_label = _label("// TRANSMISSION", 9, GOLD)
	top_row.add_child(_comms_speaker_label)

	var sep := HSeparator.new()
	sep.modulate = Color(0.3, 0.6, 0.6, 0.3)
	stack.add_child(sep)

	_comms_message_label = _label("", 9, PALE)
	_comms_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_comms_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(_comms_message_label)


func _build_top_controls() -> void:
	var controls := HBoxContainer.new()
	_top_controls = controls
	controls.name = "TopRightControls"
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.offset_left = -980.0
	controls.offset_top = 18.0
	controls.offset_right = -18.0
	controls.offset_bottom = 82.0
	controls.add_theme_constant_override("separation", 6)
	_root.add_child(controls)
	_top_mode_btn = _build_top_mode_toggle_button()
	controls.add_child(_top_mode_btn)
	controls.add_child(_navigation_button(&"tasks", "TASKS", "T", _open_tasks))
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
	_status_pill = status_pill
	status_pill.name = "EquippedStatusPill"
	status_pill.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	status_pill.offset_left = -334.0
	status_pill.offset_right = 334.0
	status_pill.offset_top = -130.0
	status_pill.offset_bottom = -104.0
	status_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_pill.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.035, 0.048, 0.90), EDGE_SOFT, 4.0))
	_root.add_child(status_pill)
	var pill_box := HBoxContainer.new()
	pill_box.name = "StatusPillBox"
	pill_box.add_theme_constant_override("separation", 10)
	pill_box.alignment = BoxContainer.ALIGNMENT_CENTER
	status_pill.add_child(pill_box)

	var suit_sec := HBoxContainer.new()
	suit_sec.add_theme_constant_override("separation", 6)
	suit_sec.alignment = BoxContainer.ALIGNMENT_CENTER

	_suit_status_label = _label("SUIT: 100% NOMINAL", 8, GREEN)
	_suit_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	suit_sec.add_child(_suit_status_label)

	_suit_progress_bar = ProgressBar.new()
	_suit_progress_bar.custom_minimum_size = Vector2(84.0, 7.0)
	_suit_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_suit_progress_bar.min_value = 0.0
	_suit_progress_bar.max_value = 100.0
	_suit_progress_bar.value = 100.0
	_suit_progress_bar.show_percentage = false
	_suit_progress_bar.add_theme_stylebox_override("background", _panel_style(Color(0.015, 0.03, 0.045), Color(0.12, 0.22, 0.28), 2.0))
	_suit_progress_bar.add_theme_stylebox_override("fill", _panel_style(Color(0.24, 0.95, 0.54), Color(0.24, 0.95, 0.54), 2.0))
	suit_sec.add_child(_suit_progress_bar)
	pill_box.add_child(suit_sec)

	var pill_sep := VSeparator.new()
	pill_sep.add_theme_color_override("separator_color", Color(0.24, 0.42, 0.46, 0.6))
	pill_box.add_child(pill_sep)

	_equipped_status_label = _label("UNARMED // COMPLETE TASKS TO OBTAIN GEAR", 9, GOLD)
	_equipped_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_equipped_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_box.add_child(_equipped_status_label)

	if is_instance_valid(_player):
		_on_suit_integrity_changed(_player.get_suit_integrity(), _player.get_max_suit_integrity())

	var bar := HBoxContainer.new()
	bar.name = "Hotbar"
	bar.add_theme_constant_override("separation", 4)
	var frame := PanelContainer.new()
	_quickbar_frame = frame
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
	## Story-mode objective pin — pulsing MapPin + room label above it.
	_map_obj_pin = MapPin.new()
	_map_obj_pin.custom_minimum_size = Vector2(20.0, 28.0)
	_map_obj_pin.pin_color = GOLD
	_map_obj_pin.visible = false
	_map_obj_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(_map_obj_pin)
	_map_obj_pin_label = _label("", 9, GOLD)
	_map_obj_pin_label.visible = false
	_map_obj_pin_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_canvas.add_child(_map_obj_pin_label)
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
	var tab_ach := _flat_filter_button("ACHIEVEMENTS")
	tab_ach.pressed.connect(func():
		_profile_view_tab = &"achievements"
		_refresh_profile_overlay()
	)
	top_bar.add_child(tab_ach)
	_profile_tab_buttons[&"achievements"] = tab_ach

	var tab_logs := _flat_filter_button("AUDIO LOGS & DOSSIERS")
	tab_logs.pressed.connect(func():
		_profile_view_tab = &"logs"
		_refresh_profile_overlay()
	)
	top_bar.add_child(tab_logs)
	_profile_tab_buttons[&"logs"] = tab_logs

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


func _create_tasks_overlay() -> void:
	var modal := _create_modal_shell("MISSION DOSSIER & TASKS", Vector2(940, 580))
	_overlay_nodes[&"tasks"] = modal["root"]
	var content: VBoxContainer = modal["content"]
	content.add_theme_constant_override("separation", 10)

	var columns := HBoxContainer.new()
	columns.name = "TasksColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	content.add_child(columns)

	# --- Left Column: Assigned Watch Duties ---
	var left_col := VBoxContainer.new()
	left_col.name = "LeftTasksColumn"
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.15
	left_col.add_theme_constant_override("separation", 8)
	columns.add_child(left_col)

	var left_header := HBoxContainer.new()
	left_header.add_theme_constant_override("separation", 8)
	var left_title := SKIN.clean_label("WATCH TASKS & OBJECTIVES", SKIN.FONT_SUBHEAD, GOLD)
	left_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_header.add_child(left_title)
	left_header.add_spacer(false)
	_tasks_status_summary_label = SKIN.pixel_label("0 / 0 COMPLETED", SKIN.FONT_SMALL, GREEN)
	_tasks_status_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left_header.add_child(_tasks_status_summary_label)
	left_col.add_child(left_header)

	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 6)
	for filter_def in [["ALL TASKS", &"all"], ["ACTIVE", &"active"], ["COMPLETED", &"completed"], ["ROADMAP", &"roadmap"], ["STORY ARCHIVES", &"story_archives"]]:
		var f_label: String = filter_def[0]
		var f_id: StringName = filter_def[1]
		var f_btn := _flat_filter_button(f_label)
		f_btn.pressed.connect(func():
			_tasks_filter_tab = f_id
			_refresh_tasks_overlay()
		)
		filter_bar.add_child(f_btn)
		_tasks_filter_buttons[f_id] = f_btn
	left_col.add_child(filter_bar)

	var hint_banner := SKIN.clean_label("Complete watch tasks to clear security locks and earn survival gear.", SKIN.FONT_SMALL, Color(0.6, 0.75, 0.82))
	left_col.add_child(hint_banner)

	var tasks_scroll := ScrollContainer.new()
	tasks_scroll.name = "TasksScroll"
	_tasks_list_scroll = tasks_scroll
	tasks_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tasks_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tasks_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(tasks_scroll)

	_tasks_list_container = VBoxContainer.new()
	_tasks_list_container.name = "TasksList"
	_tasks_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tasks_list_container.add_theme_constant_override("separation", 8)
	tasks_scroll.add_child(_tasks_list_container)

	## Roadmap view — vertical timeline shown when the ROADMAP filter is active.
	_roadmap_view_container = ScrollContainer.new()
	_roadmap_view_container.name = "RoadmapScroll"
	_roadmap_view_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roadmap_view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roadmap_view_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_roadmap_view_container.visible = false
	left_col.add_child(_roadmap_view_container)
	var _roadmap_inner := VBoxContainer.new()
	_roadmap_inner.name = "RoadmapInner"
	_roadmap_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roadmap_inner.add_theme_constant_override("separation", 6)
	_roadmap_view_container.add_child(_roadmap_inner)
	_roadmap_replay_btn = Button.new()
	_roadmap_replay_btn.text = "[ ▶ REPLAY LAST BRIEFING ]"
	_roadmap_replay_btn.visible = false
	_roadmap_replay_btn.add_theme_font_size_override("font_size", 9)
	_roadmap_replay_btn.add_theme_color_override("font_color", CYAN)
	_roadmap_replay_btn.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.06, 0.10, 0.9), CYAN, 3.0))
	_roadmap_replay_btn.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.12, 0.18, 0.95), GOLD, 3.0))
	_roadmap_replay_btn.pressed.connect(_on_roadmap_replay_pressed)
	_roadmap_inner.add_child(_roadmap_replay_btn)

	## Story & Memory Archives view — chronological cutscene replays & collected storyboards
	_story_archives_view_container = ScrollContainer.new()
	_story_archives_view_container.name = "StoryArchivesScroll"
	_story_archives_view_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_archives_view_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_story_archives_view_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_story_archives_view_container.visible = false
	left_col.add_child(_story_archives_view_container)
	_story_archives_inner = VBoxContainer.new()
	_story_archives_inner.name = "StoryArchivesInner"
	_story_archives_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story_archives_inner.add_theme_constant_override("separation", 8)
	_story_archives_view_container.add_child(_story_archives_inner)

	# --- Vertical Divider ---
	var divider := VSeparator.new()
	divider.modulate = Color(1.0, 1.0, 1.0, 0.25)
	columns.add_child(divider)

	# --- Right Column: Arsenal & Weapon Progression Showcase ---
	var right_col := VBoxContainer.new()
	right_col.name = "RightArsenalColumn"
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	columns.add_child(right_col)

	var right_header := HBoxContainer.new()
	right_header.add_theme_constant_override("separation", 8)
	var right_title := Label.new()
	right_title.name = "Label"
	SKIN.style_label(right_title, true, SKIN.FONT_SUBHEAD, GOLD)
	right_title.text = "SURVIVAL ARSENAL & WEAPONS"
	right_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_header.add_child(right_title)
	right_header.add_spacer(false)
	_tasks_arsenal_summary_label = SKIN.pixel_label("0 / 10 UNLOCKED", SKIN.FONT_SMALL, GOLD)
	_tasks_arsenal_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	right_header.add_child(_tasks_arsenal_summary_label)
	right_col.add_child(right_header)

	_tasks_arsenal_bar = ProgressBar.new()
	_tasks_arsenal_bar.min_value = 0.0
	_tasks_arsenal_bar.max_value = maxi(ARSENAL_CATALOG.size(), 1)
	_tasks_arsenal_bar.show_percentage = false
	_tasks_arsenal_bar.custom_minimum_size.y = 4.0
	_tasks_arsenal_bar.add_theme_stylebox_override("background", _flat_box(Color(0.02, 0.05, 0.07), Color.TRANSPARENT, 0.0, 0.0, 0))
	_tasks_arsenal_bar.add_theme_stylebox_override("fill", _flat_box(GOLD, Color.TRANSPARENT, 0.0, 0.0, 0))
	right_col.add_child(_tasks_arsenal_bar)

	var rule_banner := SKIN.clean_label("WEAPONS ARE LOCKED AT START // EARNED ONLY BY COMPLETING TASKS", SKIN.FONT_SMALL, Color(1.0, 0.78, 0.42))
	right_col.add_child(rule_banner)

	var arsenal_scroll := ScrollContainer.new()
	arsenal_scroll.name = "ArsenalScroll"
	arsenal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arsenal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arsenal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(arsenal_scroll)

	_tasks_arsenal_container = VBoxContainer.new()
	_tasks_arsenal_container.name = "ArsenalList"
	_tasks_arsenal_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tasks_arsenal_container.add_theme_constant_override("separation", 8)
	arsenal_scroll.add_child(_tasks_arsenal_container)


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
	content.add_child(HSeparator.new())
	# ── MOBILE / PC MODE TOGGLE ─────────────────────────────────────────────
	content.add_child(_label("INPUT MODE", 16, GOLD))
	var mode_desc_lbl := _label(
		"MOBILE: on-screen joystick + touch buttons.\nPC: keyboard & mouse only, no touch controls.", 11, MUTED)
	mode_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(mode_desc_lbl)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 12)
	content.add_child(mode_row)
	var auto_btn := _mode_toggle_option_btn("AUTO", -1)
	var pc_btn   := _mode_toggle_option_btn("[ PC MODE ]", 0)
	var mob_btn  := _mode_toggle_option_btn("[ MOBILE MODE ]", 1)
	_mobile_mode_toggle_btn = mob_btn
	mode_row.add_child(auto_btn)
	mode_row.add_child(pc_btn)
	mode_row.add_child(mob_btn)
	_refresh_mode_toggle_buttons(auto_btn, pc_btn, mob_btn)
	# ────────────────────────────────────────────────────────────────────────

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


func _get_input_bindings() -> Node:
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("InputBindings")
	return null


func _current_mobile_override() -> int:
	var ib := _get_input_bindings()
	if ib != null and "mobile_mode_override" in ib:
		return int(ib.get("mobile_mode_override"))
	return -1


func _set_mobile_override(value: int) -> void:
	var ib := _get_input_bindings()
	if ib != null:
		if ib.has_method("set_mobile_mode_override"):
			ib.call("set_mobile_mode_override", value)
		elif "mobile_mode_override" in ib:
			ib.set("mobile_mode_override", value)
	_refresh_mobile_controls()
	_update_top_mode_btn()
	_queue_resize()


func _is_mobile_mode_active() -> bool:
	var cur := _current_mobile_override()
	if cur == 0:
		return false
	if cur == 1:
		return true
	var ib := _get_input_bindings()
	return (ib != null and ib.has_method("is_mobile_or_touch") and bool(ib.call("is_mobile_or_touch")))


func _build_top_mode_toggle_button() -> Button:
	var btn := Button.new()
	btn.name = "TopModeToggle"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(96.0, 60.0)
	btn.add_theme_font_override("font", SKIN.get_pixel_font())
	btn.add_theme_font_size_override("font_size", 9)
	btn.pressed.connect(_on_top_mode_toggle_pressed)
	_update_top_mode_btn(btn)
	return btn


func _on_top_mode_toggle_pressed() -> void:
	DialogueAudioSynth.play_sfx("switch_toggle", self, -5.0)
	var cur := _current_mobile_override()
	# Cycle: PC (0) -> MOBILE (1) -> AUTO (-1) -> PC (0)
	var next_mode: int
	if cur == 0:
		next_mode = 1
	elif cur == 1:
		next_mode = -1
	else:
		next_mode = 0
	_set_mobile_override(next_mode)
	if is_instance_valid(_mobile_mode_toggle_btn):
		var row: HBoxContainer = _mobile_mode_toggle_btn.get_parent() as HBoxContainer
		if row != null and row.get_child_count() >= 3:
			_refresh_mode_toggle_buttons(
				row.get_child(0) as Button,
				row.get_child(1) as Button,
				row.get_child(2) as Button)


func _update_top_mode_btn(btn: Button = null) -> void:
	var target_btn: Button = btn if btn != null else _top_mode_btn
	if not is_instance_valid(target_btn):
		return
	var cur := _current_mobile_override()
	var is_active_mobile := _is_mobile_mode_active()
	if cur == 0:
		target_btn.text = "MODE: PC\n[KBD+MOUSE]"
		target_btn.tooltip_text = "Input Mode: PC (Keyboard/Mouse active). Click to toggle Mobile mode."
		_style_top_mode_btn(target_btn, false)
	elif cur == 1:
		target_btn.text = "MODE: MOB\n[TOUCH]"
		target_btn.tooltip_text = "Input Mode: Mobile (Touch controls active). Click to toggle Auto-detect."
		_style_top_mode_btn(target_btn, true)
	else:
		target_btn.text = "MODE: AUTO\n[%s]" % ("MOB" if is_active_mobile else "PC")
		target_btn.tooltip_text = "Input Mode: Auto-detect (Currently %s). Click to force PC mode." % ("Mobile" if is_active_mobile else "PC")
		_style_top_mode_btn(target_btn, is_active_mobile)


func _style_top_mode_btn(btn: Button, is_mobile: bool) -> void:
	if not is_instance_valid(btn):
		return
	var accent: Color = ORANGE if is_mobile else CYAN
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, accent, 4.0))
	btn.add_theme_stylebox_override("hover", _panel_style(SURFACE_HOVER, GOLD, 4.0))
	btn.add_theme_stylebox_override("pressed", _panel_style(SURFACE, GOLD, 4.0))


func _mode_toggle_option_btn(label: String, override_value: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(148, 44)
	btn.add_theme_font_override("font", SKIN.get_pixel_font())
	btn.add_theme_font_size_override("font_size", 12)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func():
		_set_mobile_override(override_value)
		# Re-apply button highlight to all three siblings
		var row: HBoxContainer = btn.get_parent() as HBoxContainer
		if row != null:
			_refresh_mode_toggle_buttons(
				row.get_child(0) as Button,
				row.get_child(1) as Button,
				row.get_child(2) as Button)
	)
	return btn


func _refresh_mode_toggle_buttons(auto_btn: Button, pc_btn: Button, mob_btn: Button) -> void:
	var cur := _current_mobile_override()
	_style_mode_btn(auto_btn, cur == -1)
	_style_mode_btn(pc_btn,   cur == 0)
	_style_mode_btn(mob_btn,  cur == 1)


func _style_mode_btn(btn: Button, active: bool) -> void:
	if not is_instance_valid(btn):
		return
	if active:
		btn.add_theme_color_override("font_color", SURFACE)
		btn.add_theme_stylebox_override("normal",   _panel_style(CYAN,    CYAN,    8.0))
		btn.add_theme_stylebox_override("hover",    _panel_style(CYAN,    GOLD,    8.0))
		btn.add_theme_stylebox_override("pressed",  _panel_style(CYAN,    GOLD,    8.0))
		btn.add_theme_stylebox_override("focus",    _panel_style(CYAN,    GOLD,    8.0))
	else:
		btn.add_theme_color_override("font_color", MUTED)
		btn.add_theme_stylebox_override("normal",   _panel_style(SURFACE, EDGE,    8.0))
		btn.add_theme_stylebox_override("hover",    _panel_style(SURFACE_HOVER, CYAN, 8.0))
		btn.add_theme_stylebox_override("pressed",  _panel_style(SURFACE, CYAN,    8.0))
		btn.add_theme_stylebox_override("focus",    _panel_style(SURFACE, EDGE,    8.0))

func _create_modal_shell(title: String, desired_size: Vector2) -> Dictionary:
	var overlay := Control.new()
	overlay.name = title.replace(" / ", "_").replace(" ", "_")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	_root.add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.005, 0.012, 0.02, 0.94)
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
	icon.icon_kind = &"map" if title == "SHIP MAP" else &"settings" if title == "SHIP SETTINGS" else &"profile" if title == "PROFILE" else &"tasks" if ("MISSION" in title or "TASK" in title or "DOSSIER" in title) else &"inventory"
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
		var task_position: Vector2 = entry.get("position", Vector2.ZERO)
		var normalized: Vector2 = _map_canvas_normalized_position(task_position)
		var marker := marker_data["marker"] as MapPin
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		marker.visible = is_complete or active_ids.has(task_id)
		_set_map_pin_position(marker, normalized)
		marker.is_complete = is_complete
		marker.pin_color = GREEN if is_complete else ORANGE
		marker.tooltip_text = ("[NOMINAL] " if is_complete else "[ALERT] ") + str(entry.get("title", "Ship task"))
		marker.queue_redraw()
	## Story-mode objective pin: gold pulsing pin at the active room's centre.
	_update_map_objective_pin()


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
	if not is_instance_valid(_world_task_marker_layer) or get_viewport() == null:
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
	_refresh_story_act_label()

	var active_ids: Array[StringName] = _get_active_sequential_task_ids()

	# 1. Determine active primary task and next preview task
	var active_entry: Dictionary = {}
	var next_entry: Dictionary = {}
	var found_active := false
	for entry in _task_entries:
		var tid: StringName = StringName(entry.get("id", &""))
		if not bool(_task_completed.get(tid, false)):
			if not found_active:
				active_entry = entry
				found_active = true
			elif next_entry.is_empty() and not String(tid).begins_with("amara_"):
				next_entry = entry

	if is_instance_valid(_active_task_card):
		if found_active and not active_entry.is_empty():
			var room_tag_text: String = str(active_entry.get("room_name", active_entry.get("marker_label", "MAIN DECK"))).to_upper()
			_active_room_tag.text = "[%s]" % room_tag_text
			_active_priority_tag.text = "ACTIVE OBJECTIVE"
			_active_priority_tag.add_theme_color_override("font_color", ORANGE)
			_active_task_title.text = _format_clean_title(str(active_entry.get("title", "Ship duty")))
			var hint: String = str(active_entry.get("action_hint", "Proceed to location and press [E] to interact"))
			_active_action_hint.text = "▶ %s" % hint

			var cur_id: StringName = StringName(active_entry.get("id", &""))
			if _last_active_task_id != &"" and _last_active_task_id != cur_id:
				var new_title := _format_clean_title(str(active_entry.get("title", "Next Duty")))
				show_objective_toast("⚡ NEW OBJECTIVE", new_title, false)
			_last_active_task_id = cur_id

			if is_instance_valid(_active_reward_card):
				var r_item: StringName = StringName(active_entry.get("reward_item", &""))
				var m_item: StringName = StringName(active_entry.get("milestone_reward", r_item))
				if r_item != &"" and ITEM_DATA.has(r_item):
					_active_reward_icon.texture = _item_icon_texture(r_item)
					_active_reward_badge.text = "⚡ WEAPON / GEAR UNLOCKS ON THIS TASK:"
					_active_reward_badge.add_theme_color_override("font_color", GOLD)
					_active_reward_name.text = str(ITEM_DATA[r_item]["name"]).to_upper()
					_active_reward_desc.text = "Complete current objective to obtain this weapon!"
					_active_reward_card.visible = true
				elif m_item != &"" and ITEM_DATA.has(m_item):
					_active_reward_icon.texture = _item_icon_texture(m_item)
					_active_reward_badge.text = "NEXT ARSENAL REWARD IN PROGRESS:"
					_active_reward_badge.add_theme_color_override("font_color", CYAN)
					_active_reward_name.text = "%s  (LOCKED 🔒)" % str(ITEM_DATA[m_item]["name"]).to_upper()
					_active_reward_desc.text = "Advance current objective to unlock"
					_active_reward_card.visible = true
				else:
					_active_reward_badge.text = "WEAPON STATUS: UNARMED"
					_active_reward_badge.add_theme_color_override("font_color", MUTED)
					_active_reward_name.text = "COMPLETE TASKS TO OBTAIN WEAPONS"
					_active_reward_desc.text = "All weapons are locked until duties are complete."
					_active_reward_icon.texture = _item_icon_texture(&"captains_revolver")
					_active_reward_card.visible = true

			if not next_entry.is_empty() and is_instance_valid(_upcoming_task_row):
				_upcoming_task_label.text = _format_clean_title(str(next_entry.get("title", "Next ship duty")))
				_upcoming_task_row.visible = true
			elif is_instance_valid(_upcoming_task_row):
				_upcoming_task_row.visible = false
		else:
			_active_room_tag.text = "[ALL OBJECTIVES COMPLETE]"
			_active_priority_tag.text = "WATCH COMPLETE"
			_active_priority_tag.add_theme_color_override("font_color", GREEN)
			_active_task_title.text = "All sector tasks executed successfully"
			_active_action_hint.text = "All sector weapons & gear unlocked."
			if is_instance_valid(_active_reward_card):
				_active_reward_badge.text = "ARSENAL STATUS:"
				_active_reward_name.text = "ALL WEAPONS & GEAR SECURED"
				_active_reward_desc.text = "Loadout fully operational"
				_active_reward_icon.texture = _item_icon_texture(&"captains_revolver")
			if is_instance_valid(_upcoming_task_row):
				_upcoming_task_row.visible = false

	# 2. Update secondary / crew duty rows
	for task_id in _mission_rows:
		var row_data: Dictionary = _mission_rows[task_id]
		var row_ctrl: Control = row_data["row"] as Control
		var row_icon: TaskRowIcon = row_data["icon"] as TaskRowIcon
		var is_complete: bool = bool(_task_completed.get(task_id, false))
		var is_side: bool = String(task_id).begins_with("amara_")
		var show_row: bool = is_side and (active_ids.has(task_id) or is_complete)
		row_ctrl.visible = show_row
		if is_instance_valid(row_icon):
			row_icon.is_complete = is_complete
			row_icon.queue_redraw()
		if is_complete:
			row_data["mark"].text = "DONE"
			row_data["mark"].add_theme_color_override("font_color", GREEN)
		else:
			row_data["mark"].text = "DUTY"
			row_data["mark"].add_theme_color_override("font_color", CYAN)

	if is_instance_valid(_mission_summary_label):
		_mission_summary_label.text = "✔ %d/%d Tasks Complete  ·  [T] View Arsenal Roadmap" % [completed_count, total]

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
		var amt: int = get_item_amount(item_id) if is_item_limited(item_id) else -1
		_hotbar_slots[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), index == _selected_hotbar_index, _item_icon_texture(item_id), amt)


func _refresh_inventory_cells() -> void:
	for index in range(_storage_cells.size()):
		var item_id: StringName = _storage_items[index]
		var amt: int = get_item_amount(item_id) if is_item_limited(item_id) else -1
		_storage_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), false, _item_icon_texture(item_id), amt)
	for index in range(_inventory_hotbar_cells.size()):
		var item_id: StringName = _hotbar_items[index]
		var amt: int = get_item_amount(item_id) if is_item_limited(item_id) else -1
		_inventory_hotbar_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), index == _selected_hotbar_index, _item_icon_texture(item_id), amt)
	for index in range(_equipment_cells.size()):
		var slot_id: StringName = EQUIPMENT_SLOTS[index]
		var item_id: StringName = StringName(_equipment_items.get(slot_id, &""))
		var amt: int = get_item_amount(item_id) if is_item_limited(item_id) else -1
		_equipment_cells[index].set_item(item_id, _short_item_name(item_id), _item_color(item_id), false, _item_icon_texture(item_id), amt)
	if is_instance_valid(_cargo_count_label):
		var used_slots := 0
		for item_id in _storage_items:
			if item_id != &"":
				used_slots += 1
		_cargo_count_label.text = "%02d / %02d USED" % [used_slots, _storage_items.size()]


func inventory_count(item: StringName) -> int:
	var count := _storage_items.count(item) + _hotbar_items.count(item)
	for carried in _equipment_items.values():
		if StringName(carried) == item:
			count += 1
	return count


func inventory_put(item: StringName, amount := 1) -> bool:
	if amount < 1 or not ITEM_DATA.has(item):
		return false
	var spaces := _storage_items.count(&"") + _hotbar_items.count(&"")
	if spaces < amount:
		return false
	for i in range(amount):
		var index := _storage_items.find(&"")
		if index >= 0:
			_storage_items[index] = item
		else:
			_hotbar_items[_hotbar_items.find(&"")] = item
	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()
	inventory_changed.emit()
	return true


func inventory_take(item: StringName, amount := 1) -> bool:
	if amount < 1 or inventory_count(item) < amount:
		return false
	for i in range(amount):
		var index := _storage_items.find(item)
		if index >= 0:
			_storage_items[index] = &""
			continue
		index = _hotbar_items.find(item)
		if index >= 0:
			_hotbar_items[index] = &""
			continue
		for slot in _equipment_items:
			if StringName(_equipment_items[slot]) == item:
				_equipment_items[slot] = &""
				break
	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()
	inventory_changed.emit()
	return true


func inventory_snapshot() -> Dictionary:
	# Array(existing_array) aliases its storage in Godot. Snapshots must own copies
	# so later drag/drop and consumption cannot mutate a save/scenario baseline.
	return {
		"storage": _storage_items.duplicate(),
		"hotbar": _hotbar_items.duplicate(),
		"equipment": _equipment_items.duplicate(),
		"selected": _selected_hotbar_index,
	}


func inventory_valid(data: Dictionary) -> bool:
	if not data.get("storage") is Array or data.storage.size() != 27 or not data.get("hotbar") is Array or data.hotbar.size() != 9 or not data.get("equipment") is Dictionary or data.equipment.size() != 4:
		return false
	for item in data.storage + data.hotbar + data.equipment.values():
		if not (item is String or item is StringName):
			return false
		if str(item) != "" and not ITEM_DATA.has(StringName(item)):
			return false
	for slot in EQUIPMENT_SLOTS:
		if not data.equipment.has(str(slot)):
			return false
		var item := StringName(data.equipment[str(slot)])
		if item != &"" and ITEM_DATA[item].equip_slot != slot:
			return false
	if not (data.get("selected") is int or data.get("selected") is float):
		return false
	return is_finite(float(data.selected)) and data.selected == floor(data.selected) and data.selected >= 0 and data.selected < 9


func inventory_restore(data: Dictionary) -> bool:
	if not inventory_valid(data):
		return false
	for i in range(27):
		_storage_items[i] = StringName(data.storage[i])
	for i in range(9):
		_hotbar_items[i] = StringName(data.hotbar[i])
	for slot in EQUIPMENT_SLOTS:
		_equipment_items[slot] = StringName(data.equipment[str(slot)])
	_selected_hotbar_index = int(data.selected)
	_refresh_hotbar()
	_refresh_inventory_cells()
	_sync_player_equipped_item()
	_save_persistent_inventory_state()
	inventory_changed.emit()
	return true


func grant_hotbar_item(item_id: StringName) -> void:
	if _hotbar_items.has(item_id):
		return
	for i in range(_hotbar_items.size()):
		if _hotbar_items[i] == &"":
			_hotbar_items[i] = item_id
			_refresh_hotbar()
			_refresh_inventory_cells()
			_sync_player_equipped_item()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return


func consume_item(item_id: StringName) -> bool:
	for i in range(_hotbar_items.size()):
		if _hotbar_items[i] == item_id:
			_hotbar_items[i] = &""
			_refresh_hotbar()
			_refresh_inventory_cells()
			_sync_player_equipped_item()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	for i in range(_storage_items.size()):
		if _storage_items[i] == item_id:
			_storage_items[i] = &""
			_refresh_inventory_cells()
			_sync_player_equipped_item()
			_save_persistent_inventory_state()
			inventory_changed.emit()
			return true
	return false


func set_ship_objectives(entries: Array, completed_ids: Dictionary) -> void:
	# Reuse the existing mission tracker and completion dictionary. Its dynamic
	# rows are rebuilt in place; the inventory, settings, map and hotbar stay live.
	_task_entries.clear()
	_task_completed.clear()
	_mission_rows.clear()
	# The original service markers remain available as data, but must not
	# linger at (0,0) after the tracker switches to the integrated ship duties.
	for marker in _world_task_markers.values():
		if is_instance_valid(marker):
			marker.hide()
	# Keep header/progress/details (first three children), replace objective rows.
	if is_instance_valid(_mission_stack):
		for i in range(_mission_stack.get_child_count() - 1, 2, -1):
			var child := _mission_stack.get_child(i)
			_mission_stack.remove_child(child)
			child.queue_free()
	for entry in entries:
		_task_entries.append(entry.duplicate(true))
		_task_completed[entry.id] = completed_ids.has(str(entry.id))
		_add_mission_row(entry)
		_add_world_task_marker(entry)
		_add_map_task_marker(entry)
	if is_instance_valid(_mission_panel):
		_mission_panel.offset_bottom = 198.0 + maxi(entries.size() - 3, 0) * 32.0
	_refresh_mission_panel()
	_update_world_task_markers()


func set_story_objective(entry: Dictionary, completed_missions: int, optional_enabled: bool = false, optional_completed: int = 0) -> void:
	# Reuse the tracker and its world marker; optional checks never enter the
	# chapter denominator or masquerade as additional required machine repairs.
	_story_completed_count = completed_missions
	_story_objective_room = str(entry.get("marker_label", "")).to_lower()
	set_ship_objectives([entry], {str(entry.id): true} if completed_missions == 5 else {})
	if is_instance_valid(_mission_progress_label):
		_mission_progress_label.text = "%d / 5 MISSIONS" % completed_missions
	if is_instance_valid(_mission_progress_bar):
		_mission_progress_bar.max_value = 5
		_mission_progress_bar.value = completed_missions
	if is_instance_valid(_mission_stack):
		var description := _label(str(entry.get("description", "")), 12, PALE)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size.x = 280
		_mission_stack.add_child(description)
		_mission_stack.add_child(HSeparator.new())
		var optional := _label("OPTIONAL / %d OF 2 OBSERVATIONS" % mini(optional_completed, 2) if optional_enabled else "OPTIONAL / EXPLORE AND INSPECT SHIP SYSTEMS", 10, MUTED)
		optional.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mission_stack.add_child(optional)
	_refresh_roadmap(completed_missions)


func _open_map() -> void:
	_open_overlay(&"map")


func _open_inventory() -> void:
	_refresh_inventory_cells()
	_refresh_profile_overlay()
	_open_overlay(&"inventory")


func _open_profile() -> void:
	_refresh_profile_overlay()
	_open_overlay(&"profile")


func _set_hud_gameplay_elements_visible(is_vis: bool) -> void:
	if is_instance_valid(_mission_panel):
		_mission_panel.visible = is_vis
	if is_instance_valid(_top_controls):
		_top_controls.visible = is_vis
	if is_instance_valid(_quickbar_frame):
		_quickbar_frame.visible = is_vis
	if is_instance_valid(_status_pill):
		_status_pill.visible = is_vis
	if is_instance_valid(_world_task_marker_layer):
		_world_task_marker_layer.visible = is_vis
	if is_instance_valid(_context_prompt):
		_context_prompt.visible = false


func _open_tasks() -> void:
	_tasks_main_tab = &"tasks"
	_refresh_tasks_overlay()
	_open_overlay(&"tasks")


func _open_settings() -> void:
	_open_overlay(&"settings")


func _open_overlay(overlay_name: StringName) -> void:
	if not _walking_visible or not _overlay_nodes.has(overlay_name):
		return
	DialogueAudioSynth.play_sfx("terminal_open", self, -4.0)
	for name in _overlay_nodes:
		_overlay_nodes[name].visible = name == overlay_name
	var was_closed := _active_overlay == &""
	if was_closed and get_viewport() != null:
		_previous_focus = get_viewport().gui_get_focus_owner()
	_active_overlay = overlay_name
	if was_closed:
		_set_hud_gameplay_elements_visible(false)
		modal_state_changed.emit(true)
	if overlay_name == &"map":
		_update_map_markers()
	var close := _overlay_nodes[overlay_name].find_child("Close", true, false) as Button
	if is_instance_valid(close) and close.is_inside_tree():
		close.grab_focus()
	_queue_resize()


func _close_overlay() -> void:
	if _active_overlay == &"":
		return
	DialogueAudioSynth.play_sfx("switch_toggle", self, -5.0)
	for overlay in _overlay_nodes.values():
		overlay.visible = false
	_active_overlay = &""
	_set_hud_gameplay_elements_visible(true)
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

func _format_clean_title(raw_title: String) -> String:
	var clean := raw_title.strip_edges()
	if clean.begins_with("Amara: "):
		clean = clean.substr(7).strip_edges()
	var paren_pos := clean.find("(")
	if paren_pos != -1:
		var sub := clean.substr(paren_pos)
		if sub.find("Task") != -1 or sub.find("Unlock") != -1 or sub.find("->") != -1 or sub.find("Multitool") != -1 or sub.find("Suit Light") != -1 or sub.find("Plasma") != -1 or sub.find("Discharger") != -1 or sub.find("Scanner") != -1 or sub.find("Act IV") != -1:
			clean = clean.substr(0, paren_pos).strip_edges()
	var angle_pos := clean.find("<")
	if angle_pos != -1:
		clean = clean.substr(0, angle_pos).strip_edges()
	return clean


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	var clean_size: int = maxi(font_size, 10)
	label.add_theme_font_size_override("font_size", clean_size)
	label.add_theme_constant_override("line_spacing", 4)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, minimum_size: Vector2, accent: Color) -> Button:
	var button := Button.new()
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.text = text
	button.tooltip_text = text
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
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
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
			var ib := get_tree().root.get_node_or_null("InputBindings") if is_inside_tree() and get_tree() != null and get_tree().root != null else null
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
	if event.keycode == KEY_T and _active_overlay == &"tasks":
		_close_overlay()
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
	if event.keycode == KEY_T:
		_open_tasks()
		get_viewport().set_input_as_handled()
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


func _dev_section_container(parent: Control, section_id: StringName, title_text: String, title_col: Color) -> VBoxContainer:
	var sec_box := VBoxContainer.new()
	sec_box.name = "DevSection_" + String(section_id)
	sec_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_box.add_theme_constant_override("separation", 6)

	var header := _label(title_text, 11, title_col)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.clip_text = true
	header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sec_box.add_child(header)
	sec_box.add_child(HSeparator.new())

	parent.add_child(sec_box)
	_dev_sections[section_id] = sec_box
	return sec_box


func _dev_btn(text: String, callback: Callable, color: Color = CYAN, height: float = 34.0) -> Button:
	var btn := _button(text, Vector2(0, height), color)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 9)
	btn.pressed.connect(callback)
	return btn


func _dev_row(btn1: Control, btn2: Control = null, btn3: Control = null) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if btn1 != null:
		btn1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn1)
	if btn2 != null:
		btn2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn2)
	if btn3 != null:
		btn3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn3)
	return row


func _build_dev_menu_panel() -> void:
	_dev_panel = PanelContainer.new()
	_dev_panel.name = "DevMenuPanel"
	_dev_panel.anchor_left = 1.0
	_dev_panel.anchor_right = 1.0
	_dev_panel.anchor_top = 0.0
	_dev_panel.anchor_bottom = 1.0
	_dev_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_dev_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dev_panel.offset_left = -536.0
	_dev_panel.offset_top = 16.0
	_dev_panel.offset_right = -16.0
	_dev_panel.offset_bottom = -16.0
	_dev_panel.visible = false
	_dev_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_dev_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, GOLD, 12.0))
	if _root != null:
		_root.add_child(_dev_panel)
	else:
		add_child(_dev_panel)

	var main_stack := VBoxContainer.new()
	main_stack.add_theme_constant_override("separation", 6)
	_dev_panel.add_child(main_stack)

	# 1. Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var title := _label("DEV MENU // ALL SCENARIOS & GAMEPLAY TESTER", 11, GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.name = "DevClose"
	close_btn.text = "X"
	close_btn.theme_type_variation = &"CloseButton"
	close_btn.custom_minimum_size = Vector2(34, 30)
	close_btn.pressed.connect(func(): _dev_panel.visible = false)
	header.add_child(close_btn)
	main_stack.add_child(header)
	main_stack.add_child(HSeparator.new())

	# 2. Filter Tabs
	var tabs_grid := GridContainer.new()
	tabs_grid.name = "DevTabsGrid"
	tabs_grid.columns = 3
	tabs_grid.add_theme_constant_override("h_separation", 6)
	tabs_grid.add_theme_constant_override("v_separation", 6)
	tabs_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tab_defs: Array = [
		[&"all", "ALL"],
		[&"monster", "👾 MONSTER"],
		[&"flight", "🚀 FLIGHT"],
		[&"story", "🎬 STORY"],
		[&"warp", "🚪 WARP"],
		[&"cheats", "💡 CHEATS"]
	]
	for tab_pair in tab_defs:
		var tab_id: StringName = tab_pair[0]
		var tab_title: String = tab_pair[1]
		var t_btn := Button.new()
		t_btn.clip_text = true
		t_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		t_btn.text = tab_title
		t_btn.tooltip_text = tab_title
		t_btn.custom_minimum_size = Vector2(0, 28)
		t_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_btn.add_theme_font_size_override("font_size", 10)
		t_btn.pressed.connect(func(): _set_dev_active_tab(tab_id))
		tabs_grid.add_child(t_btn)
		_dev_tab_buttons[tab_id] = t_btn
	main_stack.add_child(tabs_grid)
	main_stack.add_child(HSeparator.new())

	# 3. Scroll Container for Sections
	var scroll := ScrollContainer.new()
	scroll.name = "DevScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_stack.add_child(scroll)

	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 14)
	scroll.add_child(content_box)

	# SECTION 1: MONSTER & AMARA SCENARIOS
	var sec_monster := _dev_section_container(content_box, &"monster", "👾 MONSTER & AMARA INFECTION SCENARIOS", ORANGE)
	sec_monster.add_child(_dev_row(
		_dev_btn("CHASE: STAGE 1 (INFECTED AMARA)", func(): _on_dev_spawn_monster_chase(1), CYAN),
		_dev_btn("CHASE: STAGE 2 (MUTATED AMARA)", func(): _on_dev_spawn_monster_chase(2), ORANGE)
	))
	sec_monster.add_child(_dev_row(
		_dev_btn("CHASE: FINAL FORM (BONE SCYTHE)", func(): _on_dev_spawn_monster_chase(3), RED),
		_dev_btn("CHASE: ORIGINAL LIQUID ORE", func(): _on_dev_spawn_monster_chase(0), CYAN)
	))
	sec_monster.add_child(_dev_row(
		_dev_btn("TRIGGER MED BAY AMBUSH (WARD & AMARA)", _on_dev_trigger_medbay_ambush, GOLD)
	))
	sec_monster.add_child(_dev_row(
		_dev_btn("TRIGGER LAB BREACH RAMPAGE", _on_dev_trigger_lab_breach, RED)
	))
	sec_monster.add_child(_dev_row(
		_dev_btn("FORCE RETREAT INTO DUCTS", _on_dev_retreat_monster_ducts, MUTED),
		_dev_btn("DESPAWN MONSTER", _on_dev_despawn_monster, MUTED)
	))
	sec_monster.add_child(_dev_row(
		_dev_btn("TEST REPEL: EMERGENCY FLARE", func(): _on_dev_repel_monster_test(&"emergency_flare"), ORANGE),
		_dev_btn("TEST REPEL: PLASMA CUTTER", func(): _on_dev_repel_monster_test(&"plasma_cutter"), CYAN)
	))

	# SECTION 2: 3D FLIGHT & BLACK HOLE DRIVING
	var sec_flight := _dev_section_container(content_box, &"flight", "🚀 3D FLIGHT COCKPIT & SPACE HAZARDS", CYAN)
	sec_flight.add_child(_dev_row(
		_dev_btn("DRIVE: BLACK HOLE SLINGSHOT (3D)", func(): _on_dev_trigger_piloting_encounter(&"black_hole_slingshot"), ORANGE),
		_dev_btn("DRIVE: ASTEROID SWARM (3D)", func(): _on_dev_trigger_piloting_encounter(&"bridge_flight_piloting"), CYAN)
	))
	sec_flight.add_child(_dev_row(
		_dev_btn("DRIVE: STAR VEERING (3D)", func(): _on_dev_trigger_piloting_encounter(&"star_veering"), GOLD),
		_dev_btn("DRIVE: EREBOS LANDING RINGS (3D)", func(): _on_dev_trigger_piloting_encounter(&"erebos_orbital_landing"), GREEN)
	))
	sec_flight.add_child(_dev_row(
		_dev_btn("BACKDROP: BLACK HOLE ACCRETION", func(): _on_dev_set_cosmic_sector(&"black_hole"), ORANGE),
		_dev_btn("BACKDROP: ASTEROID BELT", func(): _on_dev_set_cosmic_sector(&"asteroid_belt"), CYAN)
	))
	sec_flight.add_child(_dev_row(
		_dev_btn("BACKDROP: STELLAR CORONA", func(): _on_dev_set_cosmic_sector(&"stellar_corona"), GOLD),
		_dev_btn("BACKDROP: NORMAL DEEP SPACE", func(): _on_dev_set_cosmic_sector(&"normal_space"), MUTED)
	))
	sec_flight.add_child(_dev_row(
		_dev_btn("TRIGGER RANDOM EMERGENCY ASTEROID CUTSCENE", _on_dev_trigger_asteroid_cutscene, ORANGE)
	))

	# SECTION 3: STORY CUTSCENES & PROLOGUES
	var sec_story := _dev_section_container(content_box, &"story", "🎬 STORY CUTSCENES, PROLOGUE & EPILOGUES", GOLD)
	sec_story.add_child(_dev_row(
		_dev_btn("ACT V FINALE: HOMECOMING", func(): _on_dev_play_station_cutscene(&"act_v_finale_home"), GOLD),
		_dev_btn("COMMANDER'S SECRET BRIDGE LOG", func(): _on_dev_play_station_cutscene(&"commanders_secret_bridge"), CYAN)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("CABIN MAY AUDIO RECORDING", func(): _on_dev_play_station_cutscene(&"cabin_may_recording"), GOLD),
		_dev_btn("CARGO BREACH INVESTIGATION", func(): _on_dev_play_station_cutscene(&"cargo_breach_inspection"), ORANGE)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("EREBOS TOUCHDOWN CUTSCENE", func(): _on_dev_play_station_cutscene(&"erebos_touchdown_confirmed"), GREEN),
		_dev_btn("SUBDECK SHADOW NEST CHECK", func(): _on_dev_play_station_cutscene(&"subdeck_shadow_nest_check"), ORANGE)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("PLAY PROLOGUE MONTAGE (EARTH YEARS)", _on_dev_play_prologue_montage, CYAN)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("PLAY THADINGYUT MEMORY (FESTIVAL)", _on_dev_play_thadingyut_cutscene, GOLD)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("PLAY ARRIVAL BRIEFING (DAY 184)", _on_dev_play_arrival_briefing, CYAN),
		_dev_btn("EPILOGUE 1: DAWN (RETURN HOME)", func(): _on_dev_play_epilogue(&"ending_dawn"), GREEN)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("EPILOGUE 2: THE LAST TRAJECTORY", func(): _on_dev_play_epilogue(&"ending_trajectory"), ORANGE),
		_dev_btn("EPILOGUE 3: HOMECOMING", func(): _on_dev_play_epilogue(&"ending_homecoming"), RED)
	))
	sec_story.add_child(_dev_row(
		_dev_btn("EPILOGUE 4: VOICES (TRANSMIT)", func(): _on_dev_play_epilogue(&"ending_voices"), CYAN)
	))

	# SECTION 4: WARP & ROOM NAVIGATION
	var sec_warp := _dev_section_container(content_box, &"warp", "🚪 WARP & NAVIGATION", GREEN)
	sec_warp.add_child(_dev_row(
		_dev_btn("WARP: DECK 1 (MAIN SHIP)", func(): _on_dev_warp_to_deck("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(400, 300)), CYAN),
		_dev_btn("WARP: DECK 2 (LOWER SUBDECK)", func(): _on_dev_warp_to_deck("res://scenes/ship/second_floor_subdeck.tscn", Vector2(882, 385)), ORANGE)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("WARP: EREBOS SURFACE (EXTERIOR)", func(): _on_dev_warp_to_deck("res://scenes/planet/mock_planet_exterior.tscn", Vector2(1060, 520)), GREEN)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("[D1] R01 Bridge", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(200.0, 350.0), "R01 Bridge"), CYAN),
		_dev_btn("[D1] R03 Med Bay", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(850.0, 160.0), "R03 Med Bay"), CYAN)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("[D1] R04 Research Lab", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(430.0, 480.0), "R04 Research Lab"), CYAN),
		_dev_btn("[D1] R07 Crew Quarters", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(485.0, 550.0), "R07 Crew Quarters"), CYAN)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("[D1] R06 Engine Room", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(1472.0, 390.0), "R06 Engine Room"), CYAN),
		_dev_btn("[D1] R05 Life Support", func(): _on_dev_warp_to_room_coords("res://scenes/ship/bare_ship_walkthrough.tscn", Vector2(1275.0, 336.0), "R05 Life Support"), CYAN)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("[D2] S04 Tool Workshop", func(): _on_dev_warp_to_room_coords("res://scenes/ship/second_floor_subdeck.tscn", Vector2(535.0, 675.0), "S04 Tool Workshop"), ORANGE),
		_dev_btn("[D2] S06 Shadow Nest", func(): _on_dev_warp_to_room_coords("res://scenes/ship/second_floor_subdeck.tscn", Vector2(1600.0, 680.0), "S06 Shadow Nest"), ORANGE)
	))
	sec_warp.add_child(_dev_row(
		_dev_btn("[SURF] Central Drill Rig", func(): _on_dev_warp_to_room_coords("res://scenes/planet/mock_planet_exterior.tscn", Vector2(1060.0, 520.0), "Erebos Central Rig"), GREEN),
		_dev_btn("[SURF] Hollow Crystals", func(): _on_dev_warp_to_room_coords("res://scenes/planet/mock_planet_exterior.tscn", Vector2(310.0, 435.0), "Erebos Crystal Site"), GREEN)
	))

	var nav_lbl := _label("DYNAMIC ROOM LIGHTING & TELEPORT", 10, GOLD)
	sec_warp.add_child(nav_lbl)
	var room_nav := HBoxContainer.new()
	room_nav.add_theme_constant_override("separation", 8)
	var prev_btn := _button("<", Vector2(44, 34), CYAN)
	prev_btn.pressed.connect(func(): _step_dev_room(-1))
	room_nav.add_child(prev_btn)
	_dev_room_name_label = _label("R01 Bridge", 11, PALE)
	_dev_room_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_room_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dev_room_name_label.clip_text = true
	room_nav.add_child(_dev_room_name_label)
	var next_btn := _button(">", Vector2(44, 34), CYAN)
	next_btn.pressed.connect(func(): _step_dev_room(1))
	room_nav.add_child(next_btn)
	sec_warp.add_child(room_nav)

	var room_actions := HBoxContainer.new()
	room_actions.add_theme_constant_override("separation", 8)
	_dev_room_flicker_btn = _button("ROOM FLICKER: OFF", Vector2(0, 34), ORANGE)
	_dev_room_flicker_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_room_flicker_btn.pressed.connect(_on_dev_toggle_selected_room_flicker)
	room_actions.add_child(_dev_room_flicker_btn)
	var warp_btn := _button("WARP TO ROOM", Vector2(0, 34), GREEN)
	warp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warp_btn.pressed.connect(_on_dev_warp_to_selected_room)
	room_actions.add_child(warp_btn)
	sec_warp.add_child(room_actions)

	# SECTION 5: CHEATS, GEAR & LIGHTING
	var sec_cheats := _dev_section_container(content_box, &"cheats", "💡 CHEATS, GEAR & LIGHTING TUNING", MUTED)
	sec_cheats.add_child(_dev_row(
		_dev_btn("TOGGLE GOD MODE (STEALTH / INVULNERABLE)", _on_dev_toggle_god_mode, GREEN)
	))
	sec_cheats.add_child(_dev_row(
		_dev_btn("UNLOCK ALL 10 GEAR ITEMS", unlock_all_equipment_items, GREEN),
		_dev_btn("RESTOCK ALL FLARES & AMMO", restock_all_equipment_amounts, GOLD)
	))
	sec_cheats.add_child(_dev_row(
		_dev_btn("COMPLETE ALL MAIN & CREW TASKS", _on_dev_complete_all_tasks, GOLD)
	))
	sec_cheats.add_child(_dev_row(
		_dev_btn("UNLOCK NEXT ACHIEVEMENT", _on_dev_unlock_next_achievement, CYAN),
		_dev_btn("UNLOCK ALL ACHIEVEMENTS", _on_dev_unlock_all_achievements, CYAN)
	))
	sec_cheats.add_child(_dev_row(
		_dev_btn("CREW FATE: SET ALL SURVIVED", func(): _on_dev_override_crew_survival(true), GREEN),
		_dev_btn("CREW FATE: SET ALL INFECTED / LOST", func(): _on_dev_override_crew_survival(false), RED)
	))

	_dev_current_room_label = _label("OCCUPIED: HALLWAY", 11, CYAN)
	_dev_current_room_label.clip_text = true
	sec_cheats.add_child(_dev_current_room_label)

	var f_row1 := HBoxContainer.new()
	f_row1.add_theme_constant_override("separation", 8)
	_dev_flicker_here_btn = _button("FLICKER HERE: OFF", Vector2(0, 34), ORANGE)
	_dev_flicker_here_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_flicker_here_btn.pressed.connect(_on_dev_toggle_flicker_here)
	f_row1.add_child(_dev_flicker_here_btn)
	_dev_flicker_all_btn = _button("FLICKER ALL: OFF", Vector2(0, 34), ORANGE)
	_dev_flicker_all_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_flicker_all_btn.pressed.connect(_on_dev_toggle_flicker_all)
	f_row1.add_child(_dev_flicker_all_btn)
	sec_cheats.add_child(f_row1)

	var f_row2 := HBoxContainer.new()
	f_row2.add_theme_constant_override("separation", 8)
	_dev_style_btn = _button("MODE: ERRATIC", Vector2(0, 34), CYAN)
	_dev_style_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_style_btn.pressed.connect(_on_dev_cycle_style)
	f_row2.add_child(_dev_style_btn)
	_dev_speed_btn = _button("SPEED: 1.0X", Vector2(0, 34), CYAN)
	_dev_speed_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_speed_btn.pressed.connect(_on_dev_cycle_speed)
	f_row2.add_child(_dev_speed_btn)
	sec_cheats.add_child(f_row2)

	var f_row3 := HBoxContainer.new()
	f_row3.add_theme_constant_override("separation", 8)
	_dev_force_lights_btn = _button("ALL LIT: OFF", Vector2(0, 34), GOLD)
	_dev_force_lights_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_force_lights_btn.pressed.connect(_on_dev_toggle_force_lights)
	f_row3.add_child(_dev_force_lights_btn)
	var reset_btn := _button("RESET ALL LIGHTS", Vector2(0, 34), MUTED)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.pressed.connect(_on_dev_reset_lights)
	f_row3.add_child(reset_btn)
	sec_cheats.add_child(f_row3)

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
	if villain == null:
		villain = tree.get_first_node_in_group("ship_villain") as Node2D
	if villain == null and current_scene.has_node("ResonanceOreVillain"):
		villain = current_scene.get_node("ResonanceOreVillain") as Node2D
	if villain == null:
		var floor_layer := current_scene.get_node_or_null("FloorLayer")
		if floor_layer != null and floor_layer.has_node("ResonanceOreVillain"):
			villain = floor_layer.get_node("ResonanceOreVillain") as Node2D

	if villain == null:
		var villain_scene := load("res://scenes/ship/crew/resonance_ore_villain.tscn") as PackedScene
		if villain_scene != null:
			villain = villain_scene.instantiate() as Node2D
			villain.name = "ResonanceOreVillain"
			current_scene.add_child(villain)

	if villain != null:
		var spawn_pos := Vector2.ZERO
		if is_instance_valid(_player):
			var candidates: Array[Vector2] = [
				_player.global_position + Vector2(140.0, 0.0),
				_player.global_position + Vector2(-140.0, 0.0),
				_player.global_position + Vector2(0.0, 120.0),
				_player.global_position + Vector2(0.0, -120.0),
				_player.global_position + Vector2(110.0, 90.0),
				_player.global_position + Vector2(-110.0, -90.0),
			]
			for cand in candidates:
				if villain.has_method("_position_is_walkable") and bool(villain.call("_position_is_walkable", cand)):
					spawn_pos = cand
					break
			if spawn_pos == Vector2.ZERO:
				spawn_pos = _player.global_position + Vector2(130.0, 0.0)

		if villain.has_method("wake_up"):
			villain.call("wake_up", spawn_pos)
		else:
			villain.global_position = spawn_pos
			villain.visible = true
			villain.modulate.a = 1.0
			villain.scale = Vector2.ONE
			villain.set_physics_process(true)

		if villain.has_method("set_form_stage"):
			villain.call("set_form_stage", stage, true)
		elif villain.has_method("set_stage"):
			villain.call("set_stage", stage)

		villain.set("stalk_player_distance", 9999.0)

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
	if villain == null:
		villain = tree.get_first_node_in_group("ship_villain") as Node2D
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
	var cur_scene := tree.current_scene
	var nodes_to_free: Array[Node] = []
	for v in tree.get_nodes_in_group("resonance_ore_villain"):
		if is_instance_valid(v) and not nodes_to_free.has(v):
			nodes_to_free.append(v)
	for v in tree.get_nodes_in_group("ship_villain"):
		if is_instance_valid(v) and not nodes_to_free.has(v):
			nodes_to_free.append(v)
	if cur_scene != null:
		var named_v := cur_scene.get_node_or_null("ResonanceOreVillain")
		if is_instance_valid(named_v) and not nodes_to_free.has(named_v):
			nodes_to_free.append(named_v)
		var floor_layer := cur_scene.get_node_or_null("FloorLayer")
		if floor_layer != null:
			var stray := floor_layer.get_node_or_null("ResonanceOreVillain")
			if is_instance_valid(stray) and not nodes_to_free.has(stray):
				nodes_to_free.append(stray)
	for n in nodes_to_free:
		n.queue_free()
	Engine.set_meta(&"resonance_ore_villain_spawned", false)
	Engine.set_meta(&"echo_disappeared_into_ducts", false)
	show_achievement_popup("MONSTER DESPAWNED", "All villain instances removed", "DEV MONSTER", MUTED)


func _on_dev_repel_monster_test(tool_id: StringName) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var villain: Node2D = tree.get_first_node_in_group("resonance_ore_villain") as Node2D
	if villain == null:
		villain = tree.get_first_node_in_group("ship_villain") as Node2D
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
		if cur_scene.has_method("_play_lab_breach_wave"):
			cur_scene.call(&"_play_lab_breach_wave")
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
	var cur_scene: Node = tree.current_scene if tree != null else null
	if cur_scene == null:
		cur_scene = get_parent()
	var cutscene_data: Dictionary = {}
	if cur_scene != null and cur_scene.has_method("_build_cutscene_data"):
		cutscene_data = cur_scene.call(&"_build_cutscene_data", station_id)
	elif cur_scene != null and cur_scene.has_method("_build_subdeck_cutscene"):
		cutscene_data = cur_scene.call(&"_build_subdeck_cutscene", station_id)
	
	if cutscene_data.is_empty():
		var ship_script := load("res://scripts/ship/bare_ship_walkthrough.gd") as Script
		if ship_script != null:
			var dummy = ship_script.new()
			if dummy.has_method("_build_cutscene_data"):
				cutscene_data = dummy.call(&"_build_cutscene_data", station_id)
			dummy.free()
	if cutscene_data.is_empty():
		var subdeck_script := load("res://scripts/ship/second_floor_subdeck.gd") as Script
		if subdeck_script != null:
			var dummy_sub = subdeck_script.new()
			if dummy_sub.has_method("_build_subdeck_cutscene"):
				cutscene_data = dummy_sub.call(&"_build_subdeck_cutscene", station_id)
			dummy_sub.free()

	if not cutscene_data.is_empty():
		var overlay_script := load("res://scripts/ui/story_cutscene_overlay.gd") as Script
		if overlay_script != null:
			var overlay: CanvasLayer = overlay_script.new() as CanvasLayer
			set_walking_visible(false)
			if cur_scene != null:
				cur_scene.set("_cutscene_open", true)
			overlay.connect(&"cutscene_finished", func(_c_id, _ch_id):
				set_walking_visible(true)
				if is_instance_valid(cur_scene):
					cur_scene.set("_cutscene_open", false)
					if cur_scene.has_method("_update_player_walk_state"):
						cur_scene.call("_update_player_walk_state")
					if cur_scene.has_method("_restore_camera_from_prop"):
						cur_scene.call("_restore_camera_from_prop")
				overlay.queue_free()
			)
			tree.root.add_child(overlay)
			overlay.call(&"play_cutscene", station_id, cutscene_data)
			return

	if cur_scene != null and cur_scene.has_method("_trigger_story_station"):
		cur_scene.call(&"_trigger_story_station", station_id)


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
		var cutscene := cutscene_res.instantiate() as CanvasLayer
		if cutscene != null:
			set_walking_visible(false)
			cutscene.connect(&"finished", func(): set_walking_visible(true))
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
		_queue_resize()
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
	if is_instance_valid(_dev_current_room_label):
		_dev_current_room_label.text = "OCCUPIED: " + cur_label
	var here_on: bool = bool(lighting.call("is_flicker_current_room"))
	var all_on: bool = bool(lighting.call("is_flicker_all_rooms"))
	var cur_style: String = String(lighting.call("get_flicker_style")).to_upper()
	var cur_speed: float = float(lighting.call("get_flicker_speed"))
	var all_lit: bool = bool(lighting.call("is_force_all_lights_on"))
	if is_instance_valid(_dev_flicker_here_btn):
		_dev_flicker_here_btn.text = "FLICKER HERE: " + ("ON" if here_on else "OFF")
	if is_instance_valid(_dev_flicker_all_btn):
		_dev_flicker_all_btn.text = "FLICKER ALL: " + ("ON" if all_on else "OFF")
	if is_instance_valid(_dev_style_btn):
		_dev_style_btn.text = "MODE: " + cur_style
	if is_instance_valid(_dev_speed_btn):
		_dev_speed_btn.text = "SPEED: %.1fX" % cur_speed
	if is_instance_valid(_dev_force_lights_btn):
		_dev_force_lights_btn.text = "ALL LIT: " + ("ON" if all_lit else "OFF")
	if not defs.is_empty():
		_dev_selected_room_index = clampi(_dev_selected_room_index, 0, defs.size() - 1)
		var sel_def: Dictionary = defs[_dev_selected_room_index]
		var sel_id: StringName = sel_def["id"]
		if is_instance_valid(_dev_room_name_label):
			_dev_room_name_label.text = str(sel_def.get("label", String(sel_id)))
		var room_on: bool = bool(lighting.call("is_room_flickering", sel_id))
		if is_instance_valid(_dev_room_flicker_btn):
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
	if Engine.has_meta(str(item_id) + "_unlocked") and bool(Engine.get_meta(str(item_id) + "_unlocked")):
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
			return bool(_task_completed.get(&"rig_test", false)) or bool(_task_completed.get(&"subdeck_inventory_manifest", false)) or bool(_task_completed.get(&"west_cyan_ore", false))
		&"industrial_plasma_cutter":
			return bool(_task_completed.get(&"north_viridian_ore", false)) or bool(_task_completed.get(&"subdeck_shadow_nest_check", false))
		&"electrical_discharge_tool":
			return bool(_task_completed.get(&"lab_specimen", false)) or bool(_task_completed.get(&"subdeck_pipe_pressure", false))
		&"medical_injector":
			return bool(_task_completed.get(&"lab_trolley", false))
		&"captains_revolver":
			return bool(_task_completed.get(&"commanders_secret_bridge", false)) or bool(_task_completed.get(&"act_v_finale_home", false))
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
	DialogueAudioSynth.play_sfx("radio_squelch", self, -4.0)
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
	DialogueAudioSynth.play_sfx("unlock_chime", self, -2.0)
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
	DialogueAudioSynth.play_sfx("unlock_chime", self, -3.0)
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

	## Switch between task list, roadmap view, and story archives view.
	var is_roadmap_tab: bool = (_tasks_filter_tab == &"roadmap")
	var is_archives_tab: bool = (_tasks_filter_tab == &"story_archives")
	if is_instance_valid(_roadmap_view_container):
		_roadmap_view_container.visible = is_roadmap_tab
	if is_instance_valid(_story_archives_view_container):
		_story_archives_view_container.visible = is_archives_tab
	if is_instance_valid(_tasks_list_scroll):
		_tasks_list_scroll.visible = not is_roadmap_tab and not is_archives_tab
	if is_roadmap_tab:
		_refresh_roadmap(_story_completed_count)
		return
	if is_archives_tab:
		_refresh_story_archives()
		return

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
	if index < 0 or index >= _hotbar_items.size():
		return
	if allow_toggle_unequip and _selected_hotbar_index == index and _equipment_items.get(&"tool", &"") != &"":
		_unequip_active_tool()
		return
	DialogueAudioSynth.play_sfx("item_equip", self, -5.0)
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
		var amt_str: String = ""
		var banner_color: Color = _item_color(active_item)
		if is_item_limited(active_item):
			var cur_amt: int = get_item_amount(active_item)
			if cur_amt > 0:
				amt_str = " [x%d]" % cur_amt
			else:
				amt_str = " [EMPTY / 0 LEFT]"
				banner_color = Color(1.0, 0.42, 0.35)
		_equipped_status_label.text = "EQUIPPED: %s%s   //   [SHOOT / SPACE] USE   [PICK UP / E]   [DROP / G]   [F] LIGHT: %s" % [full_name, amt_str, light_str]
		_equipped_status_label.add_theme_color_override("font_color", banner_color)
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
	_mobile_shoot_btn = _button("SHOOT", Vector2(280.0, 52.0), ORANGE)
	_mobile_shoot_btn.name = "MobileShootButton"
	_mobile_shoot_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mobile_shoot_btn.offset_left = -300.0
	_mobile_shoot_btn.offset_top = -134.0
	_mobile_shoot_btn.offset_right = -20.0
	_mobile_shoot_btn.offset_bottom = -82.0
	_mobile_shoot_btn.focus_mode = Control.FOCUS_NONE
	_mobile_shoot_btn.visible = false
	_mobile_shoot_btn.button_down.connect(_on_mobile_shoot_down)
	_mobile_shoot_btn.button_up.connect(_on_mobile_shoot_up)
	_mobile_controls_layer.add_child(_mobile_shoot_btn)

	# Bottom-Right PICK UP, DROP & LIGHT Buttons
	var action_row := HBoxContainer.new()
	action_row.name = "MobileItemActionsRow"
	action_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	action_row.offset_left = -300.0
	action_row.offset_top = -72.0
	action_row.offset_right = -20.0
	action_row.offset_bottom = -20.0
	action_row.add_theme_constant_override("separation", 6)
	action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_controls_layer.add_child(action_row)

	_mobile_pickup_btn = _button("PICK UP", Vector2(92.0, 52.0), CYAN)
	_mobile_pickup_btn.name = "MobilePickUpButton"
	_mobile_pickup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mobile_pickup_btn.focus_mode = Control.FOCUS_NONE
	_mobile_pickup_btn.pressed.connect(_on_mobile_pickup_pressed)
	action_row.add_child(_mobile_pickup_btn)

	_mobile_drop_btn = _button("DROP", Vector2(88.0, 52.0), GOLD)
	_mobile_drop_btn.name = "MobileDropButton"
	_mobile_drop_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mobile_drop_btn.focus_mode = Control.FOCUS_NONE
	_mobile_drop_btn.pressed.connect(_on_mobile_drop_pressed)
	action_row.add_child(_mobile_drop_btn)

	_mobile_light_btn = _button("LIGHT", Vector2(88.0, 52.0), PALE)
	_mobile_light_btn.name = "MobileLightButton"
	_mobile_light_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mobile_light_btn.focus_mode = Control.FOCUS_NONE
	_mobile_light_btn.visible = false
	_mobile_light_btn.pressed.connect(func():
		DialogueAudioSynth.play_sfx("flashlight_click", self, -4.0)
		if is_instance_valid(_player) and _player.has_method("toggle_suit_flashlight"):
			_player.toggle_suit_flashlight()
			_update_equipped_status_banner()
			_refresh_mobile_controls()
	)
	action_row.add_child(_mobile_light_btn)


func _refresh_mobile_controls() -> void:
	_update_top_mode_btn()
	if not is_instance_valid(_mobile_controls_layer):
		return
	var is_mobile := _is_mobile_mode_active()
	var show_controls: bool = is_mobile and _walking_visible and _active_overlay == &""
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

	if is_instance_valid(_mobile_light_btn):
		var suit_eq_item: StringName = StringName(_equipment_items.get(&"suit", &""))
		var has_light: bool = _unlocked_items.has(&"suit_flashlight") or (suit_eq_item == &"suit_flashlight")
		_mobile_light_btn.visible = has_light
		if has_light:
			var light_on: bool = false
			if is_instance_valid(_player) and _player.has_method("is_suit_flashlight_enabled"):
				light_on = _player.is_suit_flashlight_enabled()
			_mobile_light_btn.text = "LIGHT: ON" if light_on else "LIGHT: OFF"
			_mobile_light_btn.add_theme_color_override("font_color", GOLD if light_on else MUTED)


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


func _spawn_world_dropped_item(item_id: StringName, world_pos: Vector2, item_amount: int = -1) -> void:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return
	_ensure_world_dropped_canvas()
	var amt: int = item_amount
	if amt < 0 and is_item_limited(item_id):
		amt = get_item_amount(item_id)
	_dropped_world_items.append({
		"item_id": item_id,
		"pos": world_pos,
		"amount": amt,
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
			var amt_suffix := ""
			if entry.has("amount") and int(entry["amount"]) >= 0:
				amt_suffix = " (x%d)" % int(entry["amount"])
			var lbl_str: String = "[PICK UP] %s%s" % [_short_item_name(item_id), amt_suffix]
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
	var cur_amt: int = get_item_amount(dropped_id) if is_item_limited(dropped_id) else -1
	_spawn_world_dropped_item(dropped_id, drop_pos, cur_amt)
	if is_item_limited(dropped_id):
		_item_amounts[dropped_id] = 0
		if is_instance_valid(_player) and _player.has_method("set_equipment_amount"):
			_player.set_equipment_amount(dropped_id, 0)

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
		var picked_amt: int = int(picked_entry.get("amount", -1))
		_dropped_world_items.remove_at(near_idx)
		if is_instance_valid(_world_dropped_canvas):
			_world_dropped_canvas.queue_redraw()
		_equip_or_store_picked_item(picked_id, picked_amt)
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
		var picked_amt2: int = int(picked_entry2.get("amount", -1))
		_dropped_world_items.remove_at(room_idx)
		if is_instance_valid(_world_dropped_canvas):
			_world_dropped_canvas.queue_redraw()
		_equip_or_store_picked_item(picked_id2, picked_amt2)
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


func _equip_or_store_picked_item(item_id: StringName, picked_amount: int = -1) -> void:
	if item_id == &"" or not ITEM_DATA.has(item_id):
		return
	_unlocked_items[item_id] = true
	if is_item_limited(item_id):
		var add_amt: int = picked_amount if picked_amount >= 0 else int(ITEM_LIMITS[item_id]["default"])
		if _item_amounts.has(item_id):
			_item_amounts[item_id] = mini(int(_item_amounts[item_id]) + add_amt, int(ITEM_LIMITS[item_id]["max"]))
		else:
			_item_amounts[item_id] = mini(add_amt, int(ITEM_LIMITS[item_id]["max"]))
		if is_instance_valid(_player) and _player.has_method("set_equipment_amount"):
			_player.set_equipment_amount(item_id, _item_amounts[item_id])
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
	if not is_instance_valid(_root) or get_viewport() == null or not is_instance_valid(_operator_panel):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var is_mobile_active := _is_mobile_mode_active()

	# Mobile vs PC layout optimization for quickbar & status pill
	if is_instance_valid(_quickbar_frame) and is_instance_valid(_status_pill):
		if is_mobile_active:
			var slot_w: float = clampf(floorf((viewport_size.x - 420.0) / 9.0), 38.0, 52.0)
			var total_w: float = slot_w * 9.0 + 32.0
			var half_w: float = total_w * 0.5
			_quickbar_frame.offset_left = -half_w
			_quickbar_frame.offset_right = half_w
			_quickbar_frame.offset_top = -slot_w - 24.0
			_quickbar_frame.offset_bottom = -8.0
			_status_pill.offset_left = -half_w
			_status_pill.offset_right = half_w
			_status_pill.offset_top = -slot_w - 50.0
			_status_pill.offset_bottom = -slot_w - 26.0
			for slot in _hotbar_slots:
				slot.custom_minimum_size = Vector2(slot_w, slot_w)
		else:
			_quickbar_frame.offset_left = -334.0
			_quickbar_frame.offset_right = 334.0
			_quickbar_frame.offset_top = -102.0
			_quickbar_frame.offset_bottom = -14.0
			_status_pill.offset_left = -334.0
			_status_pill.offset_right = 334.0
			_status_pill.offset_top = -130.0
			_status_pill.offset_bottom = -104.0
			for slot in _hotbar_slots:
				slot.custom_minimum_size = Vector2(68.0, 68.0)

	# Mobile vs PC layout optimization for top navigation controls
	if is_instance_valid(_top_controls):
		if is_mobile_active or viewport_size.x < 1100.0:
			_top_controls.offset_top = 8.0
			_top_controls.offset_bottom = 58.0
			_top_controls.add_theme_constant_override("separation", 4)
			for child in _top_controls.get_children():
				if child is Button:
					child.custom_minimum_size = Vector2(74.0 if is_mobile_active else 92.0, 46.0)
		else:
			_top_controls.offset_top = 18.0
			_top_controls.offset_bottom = 82.0
			_top_controls.add_theme_constant_override("separation", 6)
			for child in _top_controls.get_children():
				if child is Button:
					if child == _top_mode_btn:
						child.custom_minimum_size = Vector2(96.0, 60.0)
					else:
						child.custom_minimum_size = Vector2(138.0, 60.0)

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
	if is_instance_valid(_dev_panel):
		var dev_width := minf(520.0, maxf(320.0, viewport_size.x - 32.0))
		_dev_panel.anchor_left = 1.0
		_dev_panel.anchor_right = 1.0
		_dev_panel.anchor_top = 0.0
		_dev_panel.anchor_bottom = 1.0
		_dev_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_dev_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		_dev_panel.offset_left = -dev_width - 16.0
		_dev_panel.offset_right = -16.0
		_dev_panel.offset_top = 16.0
		_dev_panel.offset_bottom = -16.0


## ─────────────────────────────────────────────────────────────────────────────
## ROADMAP — vertical First-Watch mission timeline (story mode only)
## ─────────────────────────────────────────────────────────────────────────────

func _refresh_roadmap(completed: int) -> void:
	if not is_instance_valid(_roadmap_view_container):
		return
	var inner: Node = _roadmap_view_container.get_child(0) if _roadmap_view_container.get_child_count() > 0 else null
	if inner == null:
		return
	## Clear previous step rows (keep replay btn which is always first child).
	for i in range(inner.get_child_count() - 1, 0, -1):
		var ch: Node = inner.get_child(i)
		inner.remove_child(ch)
		ch.queue_free()

	var chapter_lbl := _label("CHAPTER I  ·  FIRST WATCH  ·  ASTERIA-1 / DAY 184", 10, MUTED)
	chapter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(chapter_lbl)
	inner.add_child(HSeparator.new())

	for i in range(ROADMAP_STEPS.size()):
		var step: Dictionary = ROADMAP_STEPS[i]
		var is_done: bool  = (i < completed)
		var is_active: bool = (i == completed and completed < ROADMAP_STEPS.size())
		var is_locked: bool = (not is_done and not is_active)

		## Row container
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		## Left border indicator (4 px wide ColorRect acting as a border stripe)
		var stripe := ColorRect.new()
		stripe.custom_minimum_size = Vector2(4.0, 0.0)
		stripe.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if is_done:
			stripe.color = Color(0.48, 0.93, 0.64, 0.95)   # green
		elif is_active:
			stripe.color = GOLD                              # gold
		else:
			stripe.color = Color(0.24, 0.39, 0.43, 0.35)   # dim edge
		row.add_child(stripe)

		## Content vbox
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		row.add_child(vbox)

		## Status icon + title row
		var title_row := HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 6)
		var icon_lbl := _label("✓" if is_done else "→" if is_active else "○", 11,
			GREEN if is_done else GOLD if is_active else Color(0.45, 0.55, 0.62))
		title_row.add_child(icon_lbl)
		var title_lbl := _label(step["title"], 11,
			Color(0.65, 0.78, 0.72) if is_done else PALE if is_active else Color(0.50, 0.60, 0.65))
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_row.add_child(title_lbl)
		if is_locked:
			title_row.add_child(_label("🔒", 9, Color(0.38, 0.48, 0.54)))
		vbox.add_child(title_row)

		## Room tag
		var room_lbl := _label("[%s]" % step["room"], 9,
			CYAN if is_active else Color(0.35, 0.55, 0.62) if is_done else Color(0.28, 0.38, 0.44))
		vbox.add_child(room_lbl)

		## Description — shown only for active step
		if is_active:
			var desc_lbl := _label(step["desc"], 10, Color(0.78, 0.88, 0.90))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.custom_minimum_size.x = 240
			vbox.add_child(desc_lbl)

		## Panel wrapper
		var card := PanelContainer.new()
		var bg_col: Color
		var bd_col: Color
		if is_done:
			bg_col = Color(0.012, 0.030, 0.022, 0.80)
			bd_col = Color(0.20, 0.52, 0.34, 0.40)
		elif is_active:
			bg_col = Color(0.025, 0.055, 0.080, 0.96)
			bd_col = Color(0.85, 0.68, 0.22, 0.90)
		else:
			bg_col = Color(0.012, 0.022, 0.032, 0.60)
			bd_col = Color(0.20, 0.30, 0.36, 0.30)
		card.modulate.a = 0.55 if is_locked else 1.0
		card.add_theme_stylebox_override("panel", _flat_box(bg_col, bd_col, 10.0, 8.0, 1))
		card.add_child(row)
		inner.add_child(card)

		## Connector line between steps
		if i < ROADMAP_STEPS.size() - 1:
			var conn := ColorRect.new()
			conn.color = Color(0.30, 0.45, 0.50, 0.25)
			conn.custom_minimum_size = Vector2(2.0, 10.0)
			conn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			inner.add_child(conn)

	## Show/hide the replay button
	if is_instance_valid(_roadmap_replay_btn):
		_roadmap_replay_btn.visible = not _story_last_unlock_slide.is_empty()


func _on_roadmap_replay_pressed() -> void:
	if _story_last_unlock_slide.is_empty():
		return
	var cur_scene: Node = get_tree().current_scene if (is_inside_tree() and get_tree().current_scene != null) else get_parent()
	set_walking_visible(false)
	if is_instance_valid(cur_scene):
		cur_scene.set("_cutscene_open", true)
		if cur_scene.has_method("_update_player_walk_state"):
			cur_scene.call("_update_player_walk_state")

	## Re-display the last unlock briefing via StoryCutsceneOverlay.
	var overlay := get_node_or_null("RoadmapCutsceneOverlay") as CanvasLayer
	if overlay == null:
		var OverlayScript := load("res://scripts/ui/story_cutscene_overlay.gd") as Script
		if OverlayScript == null:
			return
		overlay = OverlayScript.new() as CanvasLayer
		overlay.name = "RoadmapCutsceneOverlay"
		add_child(overlay)
		if not overlay.is_node_ready():
			overlay._ready()

	var on_finish := func(_c_id: StringName, _ch_id: StringName):
		set_walking_visible(true)
		if is_instance_valid(cur_scene):
			cur_scene.set("_cutscene_open", false)
			if cur_scene.has_method("_update_player_walk_state"):
				cur_scene.call("_update_player_walk_state")
			if cur_scene.has_method("_restore_camera_from_prop"):
				cur_scene.call("_restore_camera_from_prop")

	if overlay.has_signal(&"cutscene_finished"):
		for conn in overlay.get_signal_connection_list(&"cutscene_finished"):
			overlay.disconnect(&"cutscene_finished", conn.callable)
		overlay.connect(&"cutscene_finished", on_finish, CONNECT_ONE_SHOT)

	if overlay.has_method("play_cutscene"):
		overlay.call("play_cutscene", &"roadmap.replay", _story_last_unlock_slide)


## Injects a last-unlock slide so the roadmap replay button works.
func set_story_last_unlock_slide(data: Dictionary) -> void:
	_story_last_unlock_slide = data
	if is_instance_valid(_roadmap_replay_btn):
		_roadmap_replay_btn.visible = not data.is_empty()


## ─────────────────────────────────────────────────────────────────────────────
## MAP OBJECTIVE PIN — gold pulsing pin + room label for the active mission room
## ─────────────────────────────────────────────────────────────────────────────

func _update_map_objective_pin() -> void:
	if not is_instance_valid(_map_obj_pin) or not is_instance_valid(_map_obj_pin_label):
		return
	## Only show during story mode and when the room is known.
	if _story_objective_room.is_empty() or _story_completed_count >= 5:
		_map_obj_pin.visible = false
		_map_obj_pin_label.visible = false
		return

	## Look up a matching area key (the marker_label from the story is all-caps;
	## we lower-cased it into _story_objective_room).
	var area_key := ""
	if _story_objective_room == "amara":
		area_key = "hydro"
	else:
		for key in SHIP_CATALOG_AREAS:
			if _story_objective_room.find(key) >= 0:
				area_key = key
				break
	if area_key.is_empty():
		_map_obj_pin.visible = false
		_map_obj_pin_label.visible = false
		return

	var area: Rect2 = SHIP_CATALOG_AREAS[area_key]
	## area is in ship-pixel coords; _map_world_origin and _map_world_size
	## describe the full world rect. Normalise center to [0,1].
	var center_world: Vector2 = area.get_center()
	var norm: Vector2 = _map_canvas_normalized_position(_map_world_origin + center_world)
	_set_map_pin_position(_map_obj_pin, norm)
	_map_obj_pin.pin_color = GOLD
	_map_obj_pin.is_complete = false
	_map_obj_pin.visible = true
	_map_obj_pin.queue_redraw()

	## Position the label just above the pin.
	var pin_size: Vector2 = _map_obj_pin.custom_minimum_size
	var canvas_size: Vector2 = _map_canvas.size
	var label_pos := Vector2(
		norm.x * canvas_size.x - 36.0,
		norm.y * canvas_size.y - pin_size.y - 18.0)
	_map_obj_pin_label.text = _story_objective_room.to_upper()
	_map_obj_pin_label.position = label_pos.floor()
	_map_obj_pin_label.visible = true

	## Dim every non-active floor area by modulating the canvas layers.
	## We only adjust the floor/wall textures; markers stay at full brightness.
	_dim_map_non_objective_rooms(area_key)


func _dim_map_non_objective_rooms(active_key: String) -> void:
	## The floor plan is a single texture so we can't dim per-room on it, but
	## we can modulate the entire canvas slightly and let the bright pin pop.
	## For richer per-room dimming, a room-rect overlay layer would be needed.
	## Here: floor and wall textures stay at 0.55 alpha when not the active room,
	## and the canvas alpha is full (allowing the gold pin to stand out).
	if not is_instance_valid(_map_floor_layer):
		return
	## Gentle dimming: reduce floor opacity if an objective room is known.
	var dim_alpha: float = 0.60 if not active_key.is_empty() else 1.0
	_map_floor_layer.modulate = Color(1.0, 1.0, 1.0, dim_alpha)
	if is_instance_valid(_map_wall_layer):
		_map_wall_layer.modulate = Color(1.0, 1.0, 1.0, dim_alpha)


## ─────────────────────────────────────────────────────────────────────────────
## STORY & MEMORY ARCHIVES — Cutscene Replays, Storyboard Artwork & Lore
## ─────────────────────────────────────────────────────────────────────────────

const STORY_ARCHIVES_CATALOG: Array[Dictionary] = [
	{
		"id": &"cabin_may_recording",
		"act": "PROLOGUE & ACT I — THE LONG APPROACH",
		"title": "The Paper Star & May's Transmission",
		"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
		"lore": "Thura's physics-teacher mother on the rainy Yangon rooftop during the blackout: 'They learn what their fear is trying to tell them.' Sister May folds him a paper star from their mother's lesson book before departure.",
		"speaker": "MAY MIN & YOUNG THURA",
		"unlocked_by": &"always",
	},
	{
		"id": &"bridge_flight_piloting",
		"act": "ACT I — THE LONG APPROACH",
		"title": "Through the Shearwater Debris Belt",
		"image": "res://art/storyboards/thura_earth/07_astronaut_selected.png",
		"lore": "Asteria-1 breaches the basalt debris belt of Erebos. Thura takes auxiliary retro-steering at the Bridge Flight Helm to evade incoming high-velocity rock fragments.",
		"speaker": "PILOT ELIAS WARD",
		"unlocked_by": &"bridge_flight_piloting",
	},
	{
		"id": &"drone_vibration_scan",
		"act": "ACT I — THE LONG APPROACH",
		"title": "Four Pulses, Seven Seconds",
		"image": "res://art/storyboards/thura_earth/02_radio_with_father.png",
		"lore": "Thura calibrates the autonomous mining drone's acoustic array, remembering his father's radio tuning bench in Yangon. A rhythmic signal echoes up from Erebos: 4 pulses, 7 seconds of silence.",
		"speaker": "TELEMETRY & MATEO RUIZ",
		"unlocked_by": &"drone_vibration_scan",
	},
	{
		"id": &"landing_prep_beacons",
		"act": "ACT I — THE LONG APPROACH",
		"title": "Preparing for Site K-12 Surface Survey",
		"image": "res://art/planet/erebos_extraction_surface_v2.png",
		"lore": "Pre-descent engineering and science tasks complete. Ward issues surface beacons, recording bad jokes for his daughter back in Houston.",
		"speaker": "PILOT ELIAS WARD",
		"unlocked_by": &"landing_prep_beacons",
	},
	{
		"id": &"erebos_landing_descent",
		"act": "ACT I — THE DESCENT",
		"title": "Atmospheric Insertion & Retro-Burn",
		"image": "res://art/planet/erebos_extraction_surface_v2.png",
		"lore": "Commander Chen fires main retro-thrusters as Asteria-1 enters the upper gravity well of Erebos, steering through gravitational turbulence and basalt dust plumes.",
		"speaker": "COMMANDER MAYA CHEN",
		"unlocked_by": &"erebos_landing_descent",
	},
	{
		"id": &"erebos_touchdown_confirmed",
		"act": "ACT II — TOUCHDOWN // SITE K-12",
		"title": "Touchdown on Resonant Bedrock",
		"image": "res://art/planet/erebos_extraction_surface_v2.png",
		"lore": "THUD! Asteria-1's hydraulic landing struts bite into the basalt bedrock of Erebos. Commander Chen depressurizes the exterior airlock for EVA extraction operations.",
		"speaker": "COMMANDER MAYA CHEN",
		"unlocked_by": &"erebos_landing_descent",
	},
	{
		"id": &"cargo_breach_inspection",
		"act": "ACT III & IV — FIRST BLOOD",
		"title": "The Sample Container is Empty",
		"image": "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png",
		"lore": "Returned from Erebos, the black drill core container sits completely empty with melted cable ducts. Deck lights fail across Asteria-1 as Dr. Okoye's voice whispers across the empty corridors.",
		"speaker": "THE ECHO (OKOYE'S VOICE)",
		"unlocked_by": &"cargo_breach_inspection",
	},
	{
		"id": &"subdeck_shadow_nest_check",
		"act": "ACT IV — SUB-DECK 02",
		"title": "Shadow Containment Nest & Traits",
		"image": "res://art/overview/subdeck_02_walkable_mask.png",
		"lore": "In the breached shadow vault of Sub-Deck 02, black mineral tendrils fuse with the bulkheads. Thura discovers the Echo mimics human voices to lure crew away from safety.",
		"speaker": "DR. THURA MIN",
		"unlocked_by": &"subdeck_shadow_nest_check",
	},
	{
		"id": &"commanders_secret_bridge",
		"act": "ACT IV — BRIDGE STANDOFF",
		"title": "The Tragic Surrender & Quarantine",
		"image": "res://art/concepts/bridge_room_props/Pixel-art mission planning table sprite sheet.png",
		"lore": "Commander Chen fights off the psychological acoustic assault of the Echo before sealing the decontamination lock, handing Thura his service revolver as his final captain's order.",
		"speaker": "COMMANDER MAYA CHEN",
		"unlocked_by": &"commanders_secret_bridge",
	},
	{
		"id": &"act_v_finale_home",
		"act": "ACT V — EARTH APPROACH",
		"title": "Mother's Echo & The Final Trajectory",
		"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
		"lore": "At the master airlock, the Echo mimics the voice of Thura's physics-teacher mother from Yangon: 'Do astronauts ever get afraid?' Holding May's paper star, Thura executes the final trajectory choice.",
		"speaker": "THE ECHO (MOTHER'S VOICE)",
		"unlocked_by": &"act_v_finale_home",
	},
	{
		"id": &"thadingyut_memory",
		"act": "YANGON MEMORY ARCHIVES",
		"title": "Thadingyut Festival of Lights",
		"image": "res://art/storyboards/thura_earth/09_thadingyut_star_memory.png",
		"lore": "A glowing childhood memory during the Festival of Lights in Yangon, watching candles and sparklers shine into the dark sky with his mother.",
		"speaker": "THURA & MOTHER",
		"unlocked_by": &"always",
	},
]


func _is_story_archive_unlocked(entry: Dictionary) -> bool:
	var unlocked_by: StringName = entry.get("unlocked_by", &"")
	if unlocked_by == &"always":
		return true
	var eid: StringName = entry.get("id", &"")
	if _task_completed.get(eid, false) or _task_completed.get(unlocked_by, false):
		return true
	if Engine.has_meta(&"ship_landed_on_erebos") and bool(Engine.get_meta(&"ship_landed_on_erebos")):
		if eid in [&"erebos_landing_descent", &"erebos_touchdown_confirmed", &"landing_prep_beacons", &"bridge_flight_piloting", &"drone_vibration_scan"]:
			return true
	if Engine.has_meta(&"echo_outbreak_active") or Engine.has_meta(&"returning_from_planet"):
		if eid in [&"cargo_breach_inspection", &"erebos_landing_descent", &"erebos_touchdown_confirmed", &"landing_prep_beacons", &"bridge_flight_piloting", &"drone_vibration_scan"]:
			return true
	return false


func _refresh_story_archives() -> void:
	if not is_instance_valid(_story_archives_inner):
		return
	for ch in _story_archives_inner.get_children():
		_story_archives_inner.remove_child(ch)
		ch.queue_free()

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	var title_lbl := _label("CHRONOLOGICAL STORY & MEMORY ARCHIVES", 11, GOLD)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_box.add_child(title_lbl)

	var sub_lbl := _label("Replay unlocked story cutscenes, view collected Yangon memory storyboards, and read deep space logs.", 9, MUTED)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_box.add_child(sub_lbl)
	_story_archives_inner.add_child(header_box)
	_story_archives_inner.add_child(HSeparator.new())

	for entry in STORY_ARCHIVES_CATALOG:
		var is_unlocked: bool = _is_story_archive_unlocked(entry)
		var card := PanelContainer.new()
		var bg_col := Color(0.016, 0.035, 0.052, 0.94) if is_unlocked else Color(0.010, 0.018, 0.026, 0.65)
		var bd_col := Color(0.35, 0.82, 0.98, 0.65) if is_unlocked else Color(0.18, 0.28, 0.35, 0.35)
		card.add_theme_stylebox_override("panel", _flat_box(bg_col, bd_col, 12.0, 8.0, 1))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		card.add_child(hbox)

		# Thumbnail image
		var img_path: String = str(entry.get("image", ""))
		if not img_path.is_empty() and ResourceLoader.exists(img_path):
			var thumb := TextureRect.new()
			thumb.custom_minimum_size = Vector2(96.0, 64.0)
			thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			thumb.texture = load(img_path) as Texture2D
			thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			thumb.modulate = Color.WHITE if is_unlocked else Color(0.4, 0.45, 0.5, 0.5)
			var thumb_frame := PanelContainer.new()
			thumb_frame.add_theme_stylebox_override("panel", _flat_box(Color.BLACK, Color(0.3, 0.45, 0.55, 0.6), 2.0, 2.0, 1))
			thumb_frame.add_child(thumb)
			hbox.add_child(thumb_frame)

		# Middle content
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 3)
		hbox.add_child(vbox)

		var top_row := HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 8)
		top_row.add_child(_label(str(entry.get("act", "")), 9, GOLD if is_unlocked else MUTED))
		top_row.add_spacer(false)
		top_row.add_child(_label(str(entry.get("speaker", "")), 9, CYAN if is_unlocked else MUTED))
		vbox.add_child(top_row)

		var entry_title := _label(str(entry.get("title", "")), 11, PALE if is_unlocked else MUTED)
		vbox.add_child(entry_title)

		var lore_lbl := _label(str(entry.get("lore", "")), 9, Color(0.72, 0.82, 0.88) if is_unlocked else Color(0.45, 0.52, 0.58))
		lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lore_lbl)

		# Right action column
		var right_box := VBoxContainer.new()
		right_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(right_box)

		if is_unlocked:
			var replay_btn := Button.new()
			replay_btn.text = "[ ▶ REPLAY ]"
			replay_btn.custom_minimum_size = Vector2(100.0, 36.0)
			replay_btn.add_theme_font_size_override("font_size", 9)
			replay_btn.add_theme_color_override("font_color", CYAN)
			replay_btn.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.08, 0.12, 0.9), CYAN, 3.0))
			replay_btn.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.14, 0.22, 0.95), GOLD, 3.0))
			var eid: StringName = StringName(entry.get("id", &""))
			replay_btn.pressed.connect(func(): _replay_story_archive(eid))
			right_box.add_child(replay_btn)
		else:
			var locked_lbl := _label("[ 🔒 LOCKED ]", 9, MUTED)
			right_box.add_child(locked_lbl)

		_story_archives_inner.add_child(card)


func _replay_story_archive(archive_id: StringName) -> void:
	_close_overlay()

	var cutscene_data: Dictionary = _get_archive_cutscene_data(archive_id)
	if cutscene_data.is_empty():
		return

	var cur_scene: Node = get_tree().current_scene if (is_inside_tree() and get_tree().current_scene != null) else get_parent()
	set_walking_visible(false)
	if is_instance_valid(cur_scene):
		cur_scene.set("_cutscene_open", true)
		if cur_scene.has_method("_update_player_walk_state"):
			cur_scene.call("_update_player_walk_state")

	var overlay := get_node_or_null("RoadmapCutsceneOverlay") as CanvasLayer
	if overlay == null:
		var OverlayScript := load("res://scripts/ui/story_cutscene_overlay.gd") as Script
		if OverlayScript == null:
			return
		overlay = OverlayScript.new() as CanvasLayer
		overlay.name = "RoadmapCutsceneOverlay"
		add_child(overlay)
		if not overlay.is_node_ready():
			overlay._ready()

	var on_finish := func(_c_id: StringName, _ch_id: StringName):
		set_walking_visible(true)
		if is_instance_valid(cur_scene):
			cur_scene.set("_cutscene_open", false)
			if cur_scene.has_method("_update_player_walk_state"):
				cur_scene.call("_update_player_walk_state")
			if cur_scene.has_method("_restore_camera_from_prop"):
				cur_scene.call("_restore_camera_from_prop")

	if overlay.has_signal(&"cutscene_finished"):
		for conn in overlay.get_signal_connection_list(&"cutscene_finished"):
			overlay.disconnect(&"cutscene_finished", conn.callable)
		overlay.connect(&"cutscene_finished", on_finish, CONNECT_ONE_SHOT)

	if overlay.has_method("play_cutscene"):
		overlay.call("play_cutscene", archive_id, cutscene_data)


func _get_archive_cutscene_data(archive_id: StringName) -> Dictionary:
	match archive_id:
		&"cabin_may_recording":
			return {
				"act": "PROLOGUE & ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // HABITATION RING",
				"title": "THE PAPER STAR & MAY'S TRANSMISSION",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "MEMORY // THE SKY ABOVE YANGON",
						"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
						"text": "Rain falls against a window in Yangon. The electricity has gone out. Young Thura climbs onto the roof with his mother, a physics teacher.\n\nYOUNG THURA: \"Do astronauts ever get afraid?\"\nMOTHER: \"Of course.\"\nYOUNG THURA: \"Then how do they go?\"\nMOTHER: \"They learn what their fear is trying to tell them.\"",
					},
					{
						"speaker": "MAY MIN // DELAYED EARTH RECORDING",
						"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
						"text": "Attached to Thura's sleeping compartment is the paper star May folded from one of their mother's old physics lesson books.\n\nMAY'S RECORDING: \"Ko Thura, everyone here keeps asking when you will bring back an alien. Please bring a friendly one. Also, Ma would say you look too thin.\"",
					},
					{
						"speaker": "PILOT ELIAS WARD // BRIDGE INTERCOM",
						"text": "ELIAS WARD (INTERCOM): \"Thura, glad you're up! Report to the Bridge Flight Helm in R01 — Autopilot is guiding us into the Erebos debris belt and Commander Chen wants you on the auxiliary flight controls before we issue your EVA Suit Flashlight.\"",
					},
				],
			}
		&"bridge_flight_piloting":
			return {
				"act": "ACT I — THE LONG APPROACH // HELM CLEARANCE",
				"clock": "ASTERIA-1 // DAY 184 // BRIDGE FLIGHT DECK",
				"title": "THROUGH THE SHEARWATER DEBRIS BELT",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "ELIAS WARD // PILOT & NAVIGATION OFFICER",
						"image": "res://art/storyboards/thura_earth/07_astronaut_selected.png",
						"text": "ELIAS WARD: \"Nice hands on the thrusters, Thura! Those Erebos shearwater fragments came in hot, and the autopilot's optical sensors didn't even flag them until we were right on top of the swarm.\"\n\nCOMMANDER MAYA CHEN: \"Stay alert. Autopilot will hold our orbital approach, but if another debris wave crosses our vector, we'll need manual evasion again. Report to Power Maintenance and Life Support next.\"",
					},
				],
			}
		&"drone_vibration_scan":
			return {
				"act": "ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // DRONE MAINTENANCE BAY",
				"title": "FOUR PULSES, SEVEN SECONDS",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "NARRATION // DRONE TELEMETRY BENCH",
						"image": "res://art/storyboards/thura_earth/02_radio_with_father.png",
						"text": "In Yangon, Thura's father repaired generators and radios, teaching him to diagnose machines by listening to their sounds. As Thura calibrates the autonomous mining drone's acoustic array, a repeating vibration echoes up from Erebos below.",
					},
					{
						"speaker": "ACOUSTIC TELEMETRY // EREBOS ORBITAL FEED",
						"text": "4 PULSES  ...  7-SECOND PAUSE  ...  4 PULSES  ...  7-SECOND PAUSE.\n\nMATEO RUIZ (MINING SPECIALIST): \"It is a rock, Thura. Rocks make noise. The commercial sponsors didn't fund Asteria-1 so we could panic over echoes.\"\n\nDR. THURA MIN: \"Not usually with timing.\"",
					},
				],
			}
		&"landing_prep_beacons":
			return {
				"act": "ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // SHUTTLE BAY",
				"title": "PREPARING FOR SITE K-12",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "ELIAS WARD // PILOT & NAVIGATION OFFICER",
						"text": "ELIAS WARD: \"All pre-descent engineering and science tasks are green. Here's your Survey Beacon kit, Thura. I just recorded three terrible knock-knock jokes for my daughter back in Houston, so make sure we come back from this rock.\"\n\nCOMMANDER MAYA CHEN (INTERCOM): \"Pre-descent checklist verified. Thura, report to the Bridge Flight Helm to take manual retro-control and initiate our orbital landing descent to Site K-12!\"",
					},
				],
			}
		&"erebos_landing_descent":
			return {
				"act": "ACT I — THE DESCENT // ORBITAL INSERTION",
				"clock": "ASTERIA-1 // DAY 184 // EREBOS EXOSPHERE",
				"title": "ATMOSPHERIC INSERTION & RETRO-BURN",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "COMMANDER MAYA CHEN // SHIPWIDE DESCENT ALERT",
						"image": "res://art/planet/erebos_extraction_surface_v2.png",
						"text": "COMMANDER MAYA CHEN: \"All hands, this is Commander Chen. De-orbit burn sequence initiated. Main retro-thrusters firing in 3... 2... 1.\n\nAsteria-1 has breached the upper gravity well of Erebos. Thura, manual retro-steering is yours at the Bridge Helm — guide our descent corridor toward Site K-12!\"",
					},
				],
			}
		&"erebos_touchdown_confirmed":
			return {
				"act": "ACT II — TOUCHDOWN // SITE K-12",
				"clock": "EREBOS BASALT CRATER // SITE K-12 // 0.84G SURFACE",
				"title": "TOUCHDOWN CONFIRMED ON BEDROCK",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DESCENT TELEMETRY // SITE K-12 BEDROCK",
						"image": "res://art/planet/erebos_extraction_surface_v2.png",
						"text": "THUD! The massive hydraulic landing struts of Asteria-1 bite into the resonant basalt bedrock of Erebos.\n\nShock absorbers hiss as planetary equalization cycles engage. Through the bridge viewports, the jagged black horizon of Erebos stretches out under a rust-colored twilight sky.",
					},
					{
						"speaker": "COMMANDER MAYA CHEN // SHIPWIDE INTERCOM",
						"text": "COMMANDER MAYA CHEN: \"Touchdown confirmed! Asteria-1 is safely down on Site K-12.\n\nAtmospheric pressure: 1.02 atm. Gravity: 0.84G. Exterior Airlock is now unlocked for surface operations. Dr. Min, don your EVA gear and begin extraction survey.\"",
					},
				],
			}
		&"cargo_breach_inspection":
			return {
				"act": "ACT III & IV — THE RETURN & FIRST BLOOD",
				"clock": "ASTERIA-1 // RETURN TRAJECTORY // CARGO HOLD",
				"title": "THE SAMPLE CONTAINER IS EMPTY",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "ACT III // THE RETURN FROM EREBOS",
						"image": "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png",
						"text": "Ruiz and Dr. Okoye are officially recorded as missing. Before emergency evacuation from Site K-12, the automated rig sealed its final black drill core inside a reinforced container. It did not accidentally enter the container — it allowed itself to be collected.",
					},
					{
						"speaker": "LEILA HADDAD & DR. THURA MIN // CARGO BAY",
						"text": "The sample container had been gaining mass. Now, inside the cargo bay, the reinforced container sits completely empty. There is no broken lock — only a narrow opening melted into the ship's cable ducts.\n\nSuddenly, the deck lights fail. Across multiple speakers simultaneously, Dr. Okoye's voice whispers:\nOKOYE'S VOICE: \"Thura, I found him.\"",
					},
					{
						"speaker": "ACT IV — CHAPTER 1: FIRST BLOOD",
						"text": "The colony of mineral organisms has absorbed recorded sounds and electrical patterns from the crew's equipment. The crew names it THE ECHO.\n\nMinutes later, Elias Ward investigates a false distress call in the medical bay using Okoye's voice. Thura watches the video feed freeze for exactly seven seconds. When it returns, Ward is gone — and his voice begins calling from Sub-Deck 02.",
					},
				],
			}
		&"subdeck_shadow_nest_check":
			return {
				"act": "ACT IV — THE ECHO'S TRAITS",
				"clock": "ASTERIA-1 // SUB-DECK 02 // SHADOW VAULT",
				"title": "DORMANT FOR THOUSANDS OF YEARS",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DR. THURA MIN // CONTAINMENT ANALYSIS",
						"image": "res://art/overview/subdeck_02_walkable_mask.png",
						"text": "Inside the breached shadow vault, black mineral ribs have fused into the bulkhead. Thura's analysis is complete: the Echo cannot survive prolonged atmospheric re-entry temperatures. If lured into the mining module and detached at a steep entry angle, the heat of Earth's atmosphere will destroy it completely.",
					},
				],
			}
		&"commanders_secret_bridge":
			return {
				"act": "ACT IV — CHAPTER 4: THE TRAGIC SURRENDER",
				"clock": "ASTERIA-1 // BRIDGE COMMAND DECK",
				"title": "THE TRAGIC SURRENDER",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "COMMANDER MAYA CHEN // BRIDGE",
						"image": "res://art/concepts/bridge_room_props/Pixel-art mission planning table sprite sheet.png",
						"text": "CHEN: \"Thura... do you hear them? Ward... Ruiz... even May from the Yangon archives. They're not speaking over the radio. They're echoing inside my own skull.\"\n\nCHEN: \"The ore... it doesn't just mimic sound. It copies memory. It's rewriting what I remember... every voice I ever loved. Two people were already gone. I thought bringing back the sample might tell us why, but I only gave it transportation.\"",
					},
					{
						"speaker": "COMMANDER MAYA CHEN // THE FINAL ORDER",
						"text": "Chen reverses the grip on his service revolver and presses the cold steel into Thura's palm.\n\nCHEN: \"Take it. It's the only kinetic firearm on Asteria-1. Don't let that thing reach Earth. If you have to burn the core... burn it. That is my final command as captain.\"",
					},
				],
			}
		&"act_v_finale_home":
			return {
				"act": "ACT V — HOME // FINAL DECISION",
				"clock": "ASTERIA-1 // EARTH APPROACH VECTOR",
				"title": "SOME DISCOVERIES ARE WORTH LEAVING BEHIND",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "THE ECHO (MOTHER'S VOICE) // FINAL AIRLOCK",
						"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
						"text": "As Thura reaches the airlock to lure the Echo into the mining module for uncontrolled atmospheric burn-up, the speaker crackles with the voice of his mother from Yangon:\n\nMOTHER'S VOICE: \"Do astronauts ever get afraid?\"\nThura stops. The creature continues:\nMOTHER'S VOICE: \"Then how do they go?\"",
					},
					{
						"speaker": "DR. THURA MIN // THE PAPER STAR",
						"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
						"text": "Thura removes the folded paper star from his suit and looks at it.\n\nTHURA: \"You heard the words.\"\nHe reaches for the master airlock and navigation core controls.\nTHURA: \"But you never understood them.\"",
					},
				],
			}
		&"thadingyut_memory":
			return {
				"act": "YANGON MEMORY ARCHIVES",
				"clock": "YANGON, MYANMAR // MEMORY ARCHIVE",
				"title": "THADINGYUT FESTIVAL OF LIGHTS",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "THURA // CHILDHOOD MEMORY",
						"image": "res://art/storyboards/thura_earth/09_thadingyut_star_memory.png",
						"text": "During Thadingyut, the Festival of Lights, candles and sparklers glow in every window along the streets of Yangon.",
					},
					{
						"speaker": "MOTHER // PHYSICS LESSON",
						"image": "res://art/storyboards/thura_earth/11_thadingyut_star_lesson.png",
						"text": "YOUNG THURA: \"Ma, why does that star keep shining?\"\nMOTHER: \"Its light has travelled a long way to find us. Even when the night is dark, it remembers where it came from.\"",
					},
				],
			}
	return {}


func _build_low_health_vignette() -> void:
	if _low_health_vignette != null:
		return
	_low_health_vignette = ColorRect.new()
	_low_health_vignette.name = "LowHealthVignette"
	_low_health_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_low_health_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_health_vignette.color = Color(0.85, 0.05, 0.08, 0.22)
	_low_health_vignette.visible = false
	_root.add_child(_low_health_vignette)


func _build_game_over_overlay() -> void:
	if _game_over_overlay != null:
		return
	var overlay := Control.new()
	overlay.name = "GameOverOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	overlay.z_index = 100
	_root.add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.015, 0.005, 0.008, 0.94)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dimmer)

	var frame := PanelContainer.new()
	frame.name = "GameOverFrame"
	frame.anchor_left = 0.5
	frame.anchor_top = 0.5
	frame.anchor_right = 0.5
	frame.anchor_bottom = 0.5
	frame.offset_left = -340.0
	frame.offset_top = -240.0
	frame.offset_right = 340.0
	frame.offset_bottom = 240.0
	var frame_style := _panel_style(Color(0.025, 0.01, 0.015, 0.98), Color(0.9, 0.22, 0.26, 0.9), 8.0)
	frame.add_theme_stylebox_override("panel", frame_style)
	overlay.add_child(frame)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(layout)

	var badge_row := HBoxContainer.new()
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.add_theme_constant_override("separation", 8)
	var badge_lbl := SKIN.pixel_label("[ EMERGENCY TELEMETRY // SIGNAL LOST ]", SKIN.FONT_TELEMETRY, Color(1.0, 0.35, 0.38))
	badge_row.add_child(badge_lbl)
	layout.add_child(badge_row)

	var title_lbl := SKIN.pixel_label("SUIT INTEGRITY FAILURE", SKIN.FONT_TITLE, Color(1.0, 0.25, 0.30))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title_lbl)

	var sub_lbl := SKIN.clean_label("CREW SPECIALIST: THURA MIN — VITAL SIGNS FLATLINED", SKIN.FONT_BODY, PALE)
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(sub_lbl)

	var div := HSeparator.new()
	div.add_theme_color_override("separator_color", Color(0.65, 0.18, 0.22, 0.7))
	layout.add_child(div)

	var telemetry_box := PanelContainer.new()
	var tel_style := _panel_style(Color(0.015, 0.005, 0.008, 0.90), Color(0.4, 0.15, 0.18, 0.6), 4.0)
	telemetry_box.add_theme_stylebox_override("panel", tel_style)
	var tel_vbox := VBoxContainer.new()
	tel_vbox.add_theme_constant_override("separation", 4)
	_game_over_telemetry_label = SKIN.pixel_label("DIAGNOSIS: FATAL PHYSICAL TRAUMA / SUIT BREACH\nLOCATION: ASTERIA-1 HULL\nATMOSPHERE RECOVERY: FAILED", SKIN.FONT_TINY, Color(0.85, 0.75, 0.78))
	_game_over_telemetry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tel_vbox.add_child(_game_over_telemetry_label)
	telemetry_box.add_child(tel_vbox)
	layout.add_child(telemetry_box)

	var btns_box := VBoxContainer.new()
	btns_box.add_theme_constant_override("separation", 10)
	btns_box.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(btns_box)

	_game_over_btn_reload = Button.new()
	_game_over_btn_reload.text = "[ RELOAD CHECKPOINT  ↺ ]"
	_game_over_btn_reload.custom_minimum_size = Vector2(360.0, 44.0)
	_game_over_btn_reload.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_game_over_btn_reload.add_theme_font_override("font", SKIN.get_pixel_font())
	_game_over_btn_reload.add_theme_font_size_override("font_size", 13)
	_game_over_btn_reload.add_theme_stylebox_override("normal", _panel_style(Color(0.02, 0.08, 0.12, 0.95), CYAN, 4.0))
	_game_over_btn_reload.add_theme_stylebox_override("hover", _panel_style(Color(0.04, 0.16, 0.24, 0.98), GOLD, 4.0))
	_game_over_btn_reload.pressed.connect(_on_game_over_reload_checkpoint)
	btns_box.add_child(_game_over_btn_reload)

	_game_over_btn_restart = Button.new()
	_game_over_btn_restart.text = "[ RESTART EXPEDITION  ⚠ ]"
	_game_over_btn_restart.custom_minimum_size = Vector2(360.0, 38.0)
	_game_over_btn_restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_game_over_btn_restart.add_theme_font_override("font", SKIN.get_pixel_font())
	_game_over_btn_restart.add_theme_font_size_override("font_size", 12)
	_game_over_btn_restart.add_theme_stylebox_override("normal", _panel_style(Color(0.08, 0.02, 0.03, 0.92), Color(0.85, 0.35, 0.38), 4.0))
	_game_over_btn_restart.add_theme_stylebox_override("hover", _panel_style(Color(0.18, 0.04, 0.06, 0.98), RED, 4.0))
	_game_over_btn_restart.pressed.connect(_on_game_over_restart_expedition)
	btns_box.add_child(_game_over_btn_restart)

	_game_over_btn_menu = Button.new()
	_game_over_btn_menu.text = "[ RETURN TO MAIN MENU  ⌂ ]"
	_game_over_btn_menu.custom_minimum_size = Vector2(360.0, 34.0)
	_game_over_btn_menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_game_over_btn_menu.add_theme_font_override("font", SKIN.get_pixel_font())
	_game_over_btn_menu.add_theme_font_size_override("font_size", 11)
	_game_over_btn_menu.add_theme_stylebox_override("normal", _panel_style(Color(0.03, 0.05, 0.07, 0.85), Color(0.35, 0.45, 0.52), 4.0))
	_game_over_btn_menu.add_theme_stylebox_override("hover", _panel_style(Color(0.06, 0.10, 0.14, 0.95), PALE, 4.0))
	_game_over_btn_menu.pressed.connect(_on_game_over_main_menu)
	btns_box.add_child(_game_over_btn_menu)

	_game_over_overlay = overlay


func _on_suit_integrity_changed(current: float, max_val: float) -> void:
	if not is_instance_valid(_suit_progress_bar) or not is_instance_valid(_suit_status_label):
		return
	_suit_progress_bar.max_value = max_val
	_suit_progress_bar.value = current
	var pct: int = int(round((current / maxf(max_val, 1.0)) * 100.0))
	var col: Color = GREEN
	var status_str := "NOMINAL"
	if pct <= 29:
		col = RED
		status_str = "CRITICAL"
	elif pct <= 69:
		col = GOLD
		status_str = "WARNING"
	_suit_status_label.text = "SUIT: %d%% %s" % [pct, status_str]
	_suit_status_label.add_theme_color_override("font_color", col)
	_suit_progress_bar.add_theme_stylebox_override("fill", _panel_style(col, col, 2.0))
	if is_instance_valid(_low_health_vignette):
		_low_health_vignette.visible = (pct <= 29 and pct > 0)


func _on_player_died() -> void:
	if not is_instance_valid(_game_over_overlay):
		return
	for key in _overlay_nodes:
		if is_instance_valid(_overlay_nodes[key]):
			_overlay_nodes[key].visible = false
	if is_instance_valid(_dev_panel):
		_dev_panel.visible = false
	if is_instance_valid(_low_health_vignette):
		_low_health_vignette.visible = false

	var loc_name: String = _active_room_tag.text if is_instance_valid(_active_room_tag) and not _active_room_tag.text.is_empty() else "ASTERIA-1 DECK"
	var last_cp_info := "LAST CHECKPOINT: RECORDED"
	if Engine.has_meta(CHECKPOINT_META_KEY):
		var cp: Dictionary = Engine.get_meta(CHECKPOINT_META_KEY)
		var cp_loc: String = str(cp.get("location", loc_name))
		last_cp_info = "LAST CHECKPOINT: %s" % cp_loc

	if is_instance_valid(_game_over_telemetry_label):
		_game_over_telemetry_label.text = "DIAGNOSIS: FATAL PHYSICAL TRAUMA // SUIT INTEGRITY BREACH\nSECTOR: %s\n%s\nSTATUS: EXPEDITION HALTED" % [loc_name, last_cp_info]

	_game_over_overlay.visible = true
	set_walking_visible(false)
	if is_instance_valid(_game_over_btn_reload) and _game_over_btn_reload.is_inside_tree():
		_game_over_btn_reload.grab_focus()


func record_checkpoint(location_name: String = "") -> void:
	var tree: SceneTree = get_tree() if is_inside_tree() else Engine.get_main_loop() as SceneTree
	var scene_file := ""
	if tree != null and tree.current_scene != null:
		scene_file = tree.current_scene.scene_file_path
	if scene_file.is_empty():
		scene_file = "res://scenes/ship/bare_ship_walkthrough.tscn"

	var cur_loc := location_name
	if cur_loc.is_empty():
		cur_loc = _active_room_tag.text if is_instance_valid(_active_room_tag) and not _active_room_tag.text.is_empty() else "ASTERIA-1 DECK"

	var player_pos := Vector2.ZERO
	if is_instance_valid(_player):
		player_pos = _player.global_position

	var inv_snap := inventory_snapshot()
	var story_snap: Dictionary = {}
	if Engine.has_meta(&"echoes_story_progression_state"):
		story_snap = Engine.get_meta(&"echoes_story_progression_state").duplicate(true)

	var checkpoint := {
		"scene_path": scene_file,
		"location": cur_loc,
		"inventory": inv_snap,
		"story_state": story_snap,
		"player_pos": [player_pos.x, player_pos.y],
		"timestamp": Time.get_unix_time_from_system()
	}
	Engine.set_meta(CHECKPOINT_META_KEY, checkpoint)

	var cur_scene = tree.current_scene if tree != null else null
	if cur_scene != null and cur_scene.has_method("ship_save_game"):
		cur_scene.call("ship_save_game")


func _on_game_over_reload_checkpoint() -> void:
	DialogueAudioSynth.play_sfx("button_click", self, -2.0)
	if is_instance_valid(_game_over_overlay):
		_game_over_overlay.visible = false
	set_walking_visible(true)

	if Engine.has_meta(CHECKPOINT_META_KEY):
		var cp: Dictionary = Engine.get_meta(CHECKPOINT_META_KEY)
		var scene_to_load: String = str(cp.get("scene_path", "res://scenes/ship/bare_ship_walkthrough.tscn"))
		if is_instance_valid(_player):
			_player.reset_player_state()
		get_tree().change_scene_to_file(scene_to_load)
	else:
		if is_instance_valid(_player):
			_player.reset_player_state()
		get_tree().reload_current_scene()


func _on_game_over_restart_expedition() -> void:
	DialogueAudioSynth.play_sfx("button_click", self, -2.0)
	if is_instance_valid(_game_over_overlay):
		_game_over_overlay.visible = false
	set_walking_visible(true)
	Engine.remove_meta(CAMPAIGN_META_KEY)
	Engine.remove_meta(CHECKPOINT_META_KEY)
	get_tree().change_scene_to_file("res://scenes/ui/landing_screen.tscn")


func _on_game_over_main_menu() -> void:
	DialogueAudioSynth.play_sfx("button_click", self, -2.0)
	if is_instance_valid(_game_over_overlay):
		_game_over_overlay.visible = false
	set_walking_visible(true)
	get_tree().change_scene_to_file("res://scenes/ui/landing_screen.tscn")


