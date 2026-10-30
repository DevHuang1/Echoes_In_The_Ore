@tool
extends Node2D

const LOWER_PANEL_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png"
const CARGO_GRATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_cargo_grate.png"
const LOWER_PLATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png"
const SMALL_GRATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_small_grate.png"

const BACKDROP_ORIGIN: Vector2i = Vector2i(-320, -220)
const BACKDROP_SIZE: Vector2i = Vector2i(2420, 1320)

# Recessed sub-hull machinery bays placed in the structural cavities between the storage rooms
const MACHINERY_BAYS: Array = [
	# West mid-deck trench between S02 Bulk Storage and S04 Workshop
	Rect2(90.0, 436.0, 260.0, 72.0),
	Rect2(370.0, 436.0, 275.0, 72.0),
	# Southwest sub-hull reserve bay left of S04 Workshop
	Rect2(45.0, 525.0, 150.0, 285.0),
	# North central auxiliary machinery bay above S00 Upper Service Spine
	Rect2(680.0, 48.0, 340.0, 155.0),
	# West lift shaft machinery well (enclosed courtyard between S02, S00, S01, S04, S05)
	Rect2(680.0, 298.0, 155.0, 336.0),
	# East lift shaft machinery well (enclosed courtyard between S00, S01, S03, S05)
	Rect2(932.0, 338.0, 230.0, 296.0),
	# East mid-deck turbine & coolant trench between S03 Engine Hall and S06 Shadow Nest
	Rect2(1180.0, 462.0, 310.0, 165.0),
	Rect2(1505.0, 440.0, 235.0, 135.0),
	# Aft machinery bulkhead bay behind S03 and S06
	Rect2(1715.0, 120.0, 195.0, 680.0),
	# Lower hull structural bays along south perimeter
	Rect2(215.0, 828.0, 520.0, 120.0),
	Rect2(760.0, 838.0, 610.0, 115.0),
	Rect2(1395.0, 812.0, 330.0, 135.0),
]

# Heavy structural sub-hull conduit runs connecting the recessed machinery bays
var SUBHULL_CONDUIT_RUNS: Array = [
	PackedVector2Array([Vector2(-80.0, 472.0), Vector2(680.0, 472.0), Vector2(755.0, 472.0), Vector2(755.0, 630.0)]),
	PackedVector2Array([Vector2(755.0, 125.0), Vector2(1020.0, 125.0), Vector2(1020.0, 495.0), Vector2(1680.0, 495.0)]),
	PackedVector2Array([Vector2(1045.0, 350.0), Vector2(1045.0, 625.0), Vector2(1480.0, 625.0)]),
	PackedVector2Array([Vector2(120.0, 488.0), Vector2(120.0, 885.0), Vector2(1650.0, 885.0), Vector2(1795.0, 885.0)]),
	PackedVector2Array([Vector2(1795.0, 60.0), Vector2(1795.0, 885.0)]),
]

# Recessed sub-hull ventilation fans & heat-exchanger rotors spinning slowly in the machinery wells
const SUBHULL_FANS: Array = [
	# Aft machinery bulkhead bay — 3 massive primary drive exhaust turbines
	{"pos": Vector2(1805.0, 215.0), "radius": 44.0, "speed": 1.25, "blades": 8, "glow": Color(0.92, 0.44, 0.12, 0.36), "theme": &"exhaust"},
	{"pos": Vector2(1805.0, 460.0), "radius": 48.0, "speed": -1.10, "blades": 8, "glow": Color(0.92, 0.44, 0.12, 0.40), "theme": &"exhaust"},
	{"pos": Vector2(1805.0, 705.0), "radius": 44.0, "speed": 1.30, "blades": 8, "glow": Color(0.92, 0.44, 0.12, 0.36), "theme": &"exhaust"},

	# North central auxiliary bay — dual counter-rotating air intake turbines
	{"pos": Vector2(765.0, 124.0), "radius": 32.0, "speed": 1.05, "blades": 6, "glow": Color(0.28, 0.78, 0.90, 0.28), "theme": &"intake"},
	{"pos": Vector2(935.0, 124.0), "radius": 32.0, "speed": -1.05, "blades": 6, "glow": Color(0.28, 0.78, 0.90, 0.28), "theme": &"intake"},

	# West lift shaft machinery well — lift shaft ventilation and transformer cooler
	{"pos": Vector2(758.0, 395.0), "radius": 34.0, "speed": 0.85, "blades": 6, "glow": Color(0.35, 0.68, 0.85, 0.24), "theme": &"intake"},
	{"pos": Vector2(758.0, 540.0), "radius": 32.0, "speed": -0.95, "blades": 5, "glow": Color(0.80, 0.45, 0.18, 0.22), "theme": &"exhaust"},

	# East lift shaft machinery well — primary coolant circulating turbines
	{"pos": Vector2(1048.0, 415.0), "radius": 36.0, "speed": 0.95, "blades": 6, "glow": Color(0.30, 0.82, 0.92, 0.30), "theme": &"coolant"},
	{"pos": Vector2(1048.0, 560.0), "radius": 34.0, "speed": -0.85, "blades": 5, "glow": Color(0.30, 0.82, 0.92, 0.26), "theme": &"coolant"},

	# West mid-deck trench — inline blowers between S02 and S04
	{"pos": Vector2(215.0, 472.0), "radius": 24.0, "speed": 1.35, "blades": 4, "glow": Color(0.75, 0.42, 0.16, 0.20), "theme": &"vent"},
	{"pos": Vector2(510.0, 472.0), "radius": 24.0, "speed": -1.20, "blades": 4, "glow": Color(0.32, 0.72, 0.86, 0.20), "theme": &"vent"},

	# East mid-deck trench — turbine exhaust fans between S03 and S06
	{"pos": Vector2(1335.0, 545.0), "radius": 34.0, "speed": 1.15, "blades": 6, "glow": Color(0.88, 0.40, 0.12, 0.28), "theme": &"exhaust"},
	{"pos": Vector2(1615.0, 505.0), "radius": 28.0, "speed": -1.25, "blades": 5, "glow": Color(0.88, 0.40, 0.12, 0.24), "theme": &"exhaust"},

	# Southwest reserve bay — workshop auxiliary exhaust
	{"pos": Vector2(118.0, 660.0), "radius": 32.0, "speed": 0.90, "blades": 6, "glow": Color(0.40, 0.68, 0.82, 0.22), "theme": &"vent"},

	# Lower hull south bays — perimeter heat dissipation blowers
	{"pos": Vector2(460.0, 885.0), "radius": 26.0, "speed": -1.10, "blades": 4, "glow": Color(0.70, 0.38, 0.15, 0.20), "theme": &"exhaust"},
	{"pos": Vector2(1050.0, 890.0), "radius": 28.0, "speed": 1.05, "blades": 5, "glow": Color(0.32, 0.76, 0.86, 0.22), "theme": &"intake"},
	{"pos": Vector2(1560.0, 875.0), "radius": 26.0, "speed": -1.20, "blades": 4, "glow": Color(0.72, 0.40, 0.16, 0.20), "theme": &"exhaust"},
]

# Industrial pipe networks running through the structural trenches and bulkheads
var _pipe_networks: Array = [
	# West mid-deck trench highway (twin parallel lines: warm steam + cool return)
	{
		"pts": PackedVector2Array([
			Vector2(70.0, 462.0), Vector2(340.0, 462.0), Vector2(350.0, 448.0),
			Vector2(370.0, 448.0), Vector2(380.0, 462.0), Vector2(665.0, 462.0)
		]),
		"width": 9.0,
		"core_col": Color(0.88, 0.44, 0.16, 0.95),
		"pulse_col": Color(1.0, 0.75, 0.40, 0.90),
		"speed": 55.0,
		"flange_step": 60.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(70.0, 482.0), Vector2(665.0, 482.0)
		]),
		"width": 7.0,
		"core_col": Color(0.18, 0.68, 0.78, 0.95),
		"pulse_col": Color(0.55, 0.94, 0.96, 0.90),
		"speed": -45.0,
		"flange_step": 55.0,
	},

	# North central auxiliary bay transfer conduits
	{
		"pts": PackedVector2Array([
			Vector2(685.0, 92.0), Vector2(1015.0, 92.0)
		]),
		"width": 11.0,
		"core_col": Color(0.85, 0.42, 0.14, 0.95),
		"pulse_col": Color(1.0, 0.72, 0.38, 0.92),
		"speed": 50.0,
		"flange_step": 65.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(685.0, 155.0), Vector2(850.0, 155.0), Vector2(850.0, 182.0), Vector2(1015.0, 182.0)
		]),
		"width": 8.0,
		"core_col": Color(0.16, 0.64, 0.74, 0.95),
		"pulse_col": Color(0.50, 0.92, 0.95, 0.90),
		"speed": 40.0,
		"flange_step": 50.0,
	},

	# West lift shaft vertical hydraulic & conduit riser
	{
		"pts": PackedVector2Array([
			Vector2(715.0, 305.0), Vector2(715.0, 625.0)
		]),
		"width": 10.0,
		"core_col": Color(0.24, 0.28, 0.32, 0.95),
		"pulse_col": Color(0.55, 0.65, 0.75, 0.85),
		"speed": 35.0,
		"flange_step": 55.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(715.0, 470.0), Vector2(755.0, 470.0), Vector2(755.0, 625.0)
		]),
		"width": 7.0,
		"core_col": Color(0.78, 0.38, 0.14, 0.92),
		"pulse_col": Color(1.0, 0.70, 0.36, 0.88),
		"speed": 45.0,
		"flange_step": 48.0,
	},

	# East lift shaft coolant crossover loop
	{
		"pts": PackedVector2Array([
			Vector2(950.0, 355.0), Vector2(1135.0, 355.0), Vector2(1135.0, 625.0)
		]),
		"width": 10.0,
		"core_col": Color(0.18, 0.70, 0.80, 0.95),
		"pulse_col": Color(0.56, 0.95, 0.98, 0.92),
		"speed": 50.0,
		"flange_step": 55.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(950.0, 500.0), Vector2(1048.0, 500.0), Vector2(1048.0, 625.0)
		]),
		"width": 6.5,
		"core_col": Color(0.82, 0.40, 0.15, 0.92),
		"pulse_col": Color(1.0, 0.72, 0.38, 0.88),
		"speed": -40.0,
		"flange_step": 45.0,
	},

	# East mid-deck trench steam & bypass lines
	{
		"pts": PackedVector2Array([
			Vector2(1185.0, 485.0), Vector2(1480.0, 485.0), Vector2(1480.0, 540.0), Vector2(1730.0, 540.0)
		]),
		"width": 12.0,
		"core_col": Color(0.88, 0.45, 0.16, 0.95),
		"pulse_col": Color(1.0, 0.76, 0.42, 0.92),
		"speed": 55.0,
		"flange_step": 60.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(1185.0, 565.0), Vector2(1450.0, 565.0), Vector2(1730.0, 565.0)
		]),
		"width": 8.0,
		"core_col": Color(0.18, 0.68, 0.78, 0.95),
		"pulse_col": Color(0.55, 0.94, 0.96, 0.90),
		"speed": -48.0,
		"flange_step": 50.0,
	},

	# Southwest bay vertical drainage and coolant return
	{
		"pts": PackedVector2Array([
			Vector2(118.0, 530.0), Vector2(118.0, 805.0)
		]),
		"width": 9.0,
		"core_col": Color(0.20, 0.66, 0.76, 0.95),
		"pulse_col": Color(0.55, 0.92, 0.95, 0.90),
		"speed": 40.0,
		"flange_step": 50.0,
	},

	# Aft machinery bulkhead bay — massive primary vertical feed columns
	{
		"pts": PackedVector2Array([
			Vector2(1750.0, 130.0), Vector2(1750.0, 420.0), Vector2(1735.0, 440.0),
			Vector2(1735.0, 480.0), Vector2(1750.0, 500.0), Vector2(1750.0, 790.0)
		]),
		"width": 14.0,
		"core_col": Color(0.90, 0.42, 0.14, 0.98),
		"pulse_col": Color(1.0, 0.78, 0.42, 0.95),
		"speed": 60.0,
		"flange_step": 65.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(1860.0, 130.0), Vector2(1860.0, 790.0)
		]),
		"width": 12.0,
		"core_col": Color(0.20, 0.70, 0.82, 0.96),
		"pulse_col": Color(0.58, 0.96, 0.98, 0.92),
		"speed": -50.0,
		"flange_step": 60.0,
	},

	# South perimeter lower hull trunk lines
	{
		"pts": PackedVector2Array([
			Vector2(225.0, 885.0), Vector2(725.0, 885.0)
		]),
		"width": 10.0,
		"core_col": Color(0.26, 0.30, 0.35, 0.95),
		"pulse_col": Color(0.60, 0.70, 0.80, 0.85),
		"speed": 35.0,
		"flange_step": 60.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(770.0, 885.0), Vector2(1360.0, 885.0)
		]),
		"width": 10.0,
		"core_col": Color(0.82, 0.40, 0.15, 0.95),
		"pulse_col": Color(1.0, 0.72, 0.38, 0.90),
		"speed": 45.0,
		"flange_step": 60.0,
	},
	{
		"pts": PackedVector2Array([
			Vector2(1405.0, 875.0), Vector2(1715.0, 875.0)
		]),
		"width": 9.0,
		"core_col": Color(0.18, 0.68, 0.78, 0.95),
		"pulse_col": Color(0.55, 0.94, 0.96, 0.90),
		"speed": -40.0,
		"flange_step": 55.0,
	},
]

# Catenary sagging wires & hanging cable bundles spanning structural bays
const SAGGING_WIRE_HARNESSES: Array = [
	# North central auxiliary bay ceiling
	{"p0": Vector2(700.0, 65.0), "p1": Vector2(840.0, 65.0), "sag": 14.0, "strands": 3},
	{"p0": Vector2(860.0, 65.0), "p1": Vector2(1005.0, 65.0), "sag": 14.0, "strands": 3},

	# West mid-deck trench
	{"p0": Vector2(120.0, 442.0), "p1": Vector2(330.0, 442.0), "sag": 10.0, "strands": 3},
	{"p0": Vector2(380.0, 442.0), "p1": Vector2(620.0, 442.0), "sag": 10.0, "strands": 3},

	# West lift shaft well
	{"p0": Vector2(690.0, 340.0), "p1": Vector2(825.0, 355.0), "sag": 18.0, "strands": 4},
	{"p0": Vector2(690.0, 480.0), "p1": Vector2(825.0, 470.0), "sag": 16.0, "strands": 4},

	# East lift shaft well
	{"p0": Vector2(945.0, 475.0), "p1": Vector2(1140.0, 490.0), "sag": 20.0, "strands": 4},

	# East mid-deck trench
	{"p0": Vector2(1210.0, 452.0), "p1": Vector2(1460.0, 452.0), "sag": 11.0, "strands": 3},
	{"p0": Vector2(1490.0, 452.0), "p1": Vector2(1710.0, 452.0), "sag": 11.0, "strands": 3},

	# Southwest reserve bay
	{"p0": Vector2(55.0, 545.0), "p1": Vector2(185.0, 570.0), "sag": 16.0, "strands": 3},

	# Lower hull perimeter bays
	{"p0": Vector2(240.0, 842.0), "p1": Vector2(450.0, 842.0), "sag": 12.0, "strands": 3},
	{"p0": Vector2(800.0, 852.0), "p1": Vector2(1020.0, 852.0), "sag": 12.0, "strands": 3},
	{"p0": Vector2(1430.0, 830.0), "p1": Vector2(1660.0, 830.0), "sag": 14.0, "strands": 3},
]

# Industrial cable tray ladders running along bay bulkheads (parallel rails with rungs)
const CABLE_LADDER_TRAYS: Array = [
	# West lift shaft ladder (vertical along starboard wall)
	{"from": Vector2(815.0, 310.0), "to": Vector2(815.0, 620.0), "width": 14.0, "spacing": 16.0},
	# East lift shaft ladder (vertical along port wall)
	{"from": Vector2(955.0, 350.0), "to": Vector2(955.0, 620.0), "width": 14.0, "spacing": 16.0},
	# Southwest bay ladder (vertical along outer hull)
	{"from": Vector2(62.0, 540.0), "to": Vector2(62.0, 800.0), "width": 12.0, "spacing": 15.0},
	# Aft machinery bay ladder (vertical along centerline)
	{"from": Vector2(1780.0, 130.0), "to": Vector2(1780.0, 790.0), "width": 16.0, "spacing": 18.0},
]

# Structural junction boxes & breaker cabinets with telemetry status LEDs
const JUNCTION_BOXES: Array = [
	{"pos": Vector2(105.0, 454.0), "size": Vector2(18.0, 24.0), "led_col": Color(0.2, 0.9, 0.4, 0.95), "blink_speed": 1.2},
	{"pos": Vector2(640.0, 454.0), "size": Vector2(18.0, 24.0), "led_col": Color(1.0, 0.7, 0.2, 0.95), "blink_speed": 2.4},
	{"pos": Vector2(710.0, 78.0), "size": Vector2(22.0, 28.0), "led_col": Color(0.2, 0.8, 1.0, 0.95), "blink_speed": 1.6},
	{"pos": Vector2(985.0, 78.0), "size": Vector2(22.0, 28.0), "led_col": Color(0.2, 0.9, 0.4, 0.95), "blink_speed": 0.8},
	{"pos": Vector2(700.0, 440.0), "size": Vector2(20.0, 26.0), "led_col": Color(1.0, 0.6, 0.2, 0.95), "blink_speed": 2.0},
	{"pos": Vector2(700.0, 600.0), "size": Vector2(20.0, 26.0), "led_col": Color(0.2, 0.9, 0.4, 0.95), "blink_speed": 1.4},
	{"pos": Vector2(950.0, 440.0), "size": Vector2(20.0, 26.0), "led_col": Color(0.2, 0.8, 1.0, 0.95), "blink_speed": 1.8},
	{"pos": Vector2(1135.0, 440.0), "size": Vector2(20.0, 26.0), "led_col": Color(1.0, 0.3, 0.2, 0.95), "blink_speed": 3.2},
	{"pos": Vector2(1200.0, 468.0), "size": Vector2(22.0, 26.0), "led_col": Color(0.2, 0.9, 0.4, 0.95), "blink_speed": 1.1},
	{"pos": Vector2(1710.0, 468.0), "size": Vector2(22.0, 26.0), "led_col": Color(1.0, 0.65, 0.2, 0.95), "blink_speed": 2.1},
	{"pos": Vector2(1730.0, 310.0), "size": Vector2(24.0, 32.0), "led_col": Color(1.0, 0.35, 0.15, 0.95), "blink_speed": 1.5},
	{"pos": Vector2(1730.0, 580.0), "size": Vector2(24.0, 32.0), "led_col": Color(0.2, 0.8, 1.0, 0.95), "blink_speed": 1.9},
	{"pos": Vector2(160.0, 560.0), "size": Vector2(18.0, 24.0), "led_col": Color(0.2, 0.9, 0.4, 0.95), "blink_speed": 1.3},
	{"pos": Vector2(160.0, 750.0), "size": Vector2(18.0, 24.0), "led_col": Color(1.0, 0.7, 0.2, 0.95), "blink_speed": 2.7},
]

# Slotted metal heat-sink radiator fin banks
const HEAT_SINK_BANKS: Array = [
	Rect2(820.0, 105.0, 60.0, 38.0),
	Rect2(1440.0, 515.0, 75.0, 36.0),
	Rect2(1740.0, 345.0, 45.0, 85.0),
	Rect2(1740.0, 520.0, 45.0, 85.0),
	Rect2(395.0, 448.0, 55.0, 30.0),
]

var _time: float = 0.0
var _rotor_canvas: Node2D = null


func _load_png_image(res_path: String) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null and not img.is_empty():
		return img
	if ResourceLoader.exists(res_path):
		var tex: Texture2D = load(res_path) as Texture2D
		if tex != null:
			return tex.get_image()
	return null


func _tile_image_into_rect(dest: Image, tile_img: Image, target_rect: Rect2i) -> void:
	if tile_img == null or tile_img.is_empty():
		dest.fill_rect(target_rect, Color(0.11, 0.13, 0.16, 1.0))
		return
	var tw: int = tile_img.get_width()
	var th: int = tile_img.get_height()
	if tw <= 0 or th <= 0:
		return
	var y: int = target_rect.position.y
	while y < target_rect.end.y:
		var h: int = mini(th, target_rect.end.y - y)
		var x: int = target_rect.position.x
		while x < target_rect.end.x:
			var w: int = mini(tw, target_rect.end.x - x)
			dest.blit_rect(tile_img, Rect2i(0, 0, w, h), Vector2i(x, y))
			x += w
		y += h


func _ready() -> void:
	z_as_relative = false
	z_index = -3
	_build_machinery_backdrop()
	set_process(not Engine.is_editor_hint())


func _build_machinery_backdrop() -> void:
	for child in get_children():
		child.queue_free()

	# 1. Tiled sub-hull plating and grating base sprite covering the entire surround
	var panel_img: Image = _load_png_image(LOWER_PANEL_PATH)
	var grate_img: Image = _load_png_image(CARGO_GRATE_PATH)
	var plate_img: Image = _load_png_image(LOWER_PLATE_PATH)
	if panel_img != null:
		panel_img.convert(Image.FORMAT_RGBA8)
	if grate_img != null:
		grate_img.convert(Image.FORMAT_RGBA8)
	if plate_img != null:
		plate_img.convert(Image.FORMAT_RGBA8)

	var canvas: Image = Image.create(BACKDROP_SIZE.x, BACKDROP_SIZE.y, false, Image.FORMAT_RGBA8)
	_tile_image_into_rect(canvas, plate_img if plate_img != null else panel_img, Rect2i(0, 0, BACKDROP_SIZE.x, BACKDROP_SIZE.y))

	# Tile recessed grating and lower machinery panels inside each machinery bay
	for i in range(MACHINERY_BAYS.size()):
		var bay: Rect2 = MACHINERY_BAYS[i]
		var local_rect: Rect2i = Rect2i(
			int(bay.position.x) - BACKDROP_ORIGIN.x,
			int(bay.position.y) - BACKDROP_ORIGIN.y,
			int(bay.size.x),
			int(bay.size.y)
		).intersection(Rect2i(0, 0, BACKDROP_SIZE.x, BACKDROP_SIZE.y))
		if local_rect.size.x > 0 and local_rect.size.y > 0:
			var bay_tile: Image = grate_img if (i % 2 == 0 and grate_img != null) else panel_img
			_tile_image_into_rect(canvas, bay_tile, local_rect)

	var base_sprite: Sprite2D = Sprite2D.new()
	base_sprite.name = "SubhullPlatingBase"
	base_sprite.centered = false
	base_sprite.position = Vector2(BACKDROP_ORIGIN)
	base_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base_sprite.texture = ImageTexture.create_from_image(canvas)
	# Deep industrial slate tint so the recessed sub-hull sits naturally behind the lit walkable rooms
	base_sprite.modulate = Color(0.24, 0.27, 0.31, 1.0)
	add_child(base_sprite)

	# 2. Procedural structural girders, industrial pipes, wires, and rotating fan rotors
	_rotor_canvas = Node2D.new()
	_rotor_canvas.name = "SubhullStructureCanvas"
	_rotor_canvas.draw.connect(_on_structure_canvas_draw)
	add_child(_rotor_canvas)


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 10000.0)
	if is_instance_valid(_rotor_canvas):
		_rotor_canvas.queue_redraw()


func _on_structure_canvas_draw() -> void:
	if not is_instance_valid(_rotor_canvas):
		return

	var girder_shadow: Color = Color(0.03, 0.04, 0.05, 0.90)
	var girder_body: Color = Color(0.12, 0.14, 0.17, 0.95)
	var girder_highlight: Color = Color(0.22, 0.26, 0.30, 0.85)
	var rivet_col: Color = Color(0.30, 0.35, 0.40, 0.85)

	# 1. Heavy structural hull ribs / I-beam grid across the sub-hull
	var x_ribs: Array = [-160.0, 40.0, 205.0, 365.0, 525.0, 675.0, 835.0, 932.0, 1175.0, 1385.0, 1550.0, 1715.0, 1910.0]
	var y_min: float = float(BACKDROP_ORIGIN.y)
	var y_max: float = float(BACKDROP_ORIGIN.y + BACKDROP_SIZE.y)
	for rx in x_ribs:
		_rotor_canvas.draw_line(Vector2(rx, y_min), Vector2(rx, y_max), girder_shadow, 14.0, false)
		_rotor_canvas.draw_line(Vector2(rx, y_min), Vector2(rx, y_max), girder_body, 8.0, false)
		_rotor_canvas.draw_line(Vector2(rx - 2.0, y_min), Vector2(rx - 2.0, y_max), girder_highlight, 1.5, false)

	var y_ribs: Array = [-80.0, 42.0, 202.0, 336.0, 436.0, 512.0, 636.0, 825.0, 960.0]
	var x_min: float = float(BACKDROP_ORIGIN.x)
	var x_max: float = float(BACKDROP_ORIGIN.x + BACKDROP_SIZE.x)
	for ry in y_ribs:
		_rotor_canvas.draw_line(Vector2(x_min, ry), Vector2(x_max, ry), girder_shadow, 14.0, false)
		_rotor_canvas.draw_line(Vector2(x_min, ry), Vector2(x_max, ry), girder_body, 8.0, false)
		_rotor_canvas.draw_line(Vector2(x_min, ry - 2.0), Vector2(x_max, ry - 2.0), girder_highlight, 1.5, false)

		for rx in x_ribs:
			_rotor_canvas.draw_rect(Rect2(rx - 6.0, ry - 6.0, 12.0, 12.0), girder_body, true)
			_rotor_canvas.draw_circle(Vector2(rx - 3.5, ry - 3.5), 1.1, rivet_col)
			_rotor_canvas.draw_circle(Vector2(rx + 3.5, ry - 3.5), 1.1, rivet_col)
			_rotor_canvas.draw_circle(Vector2(rx - 3.5, ry + 3.5), 1.1, rivet_col)
			_rotor_canvas.draw_circle(Vector2(rx + 3.5, ry + 3.5), 1.1, rivet_col)

	# 2. Recessed machinery bay curbing & dark pit borders
	for bay in MACHINERY_BAYS:
		var r: Rect2 = bay
		_rotor_canvas.draw_rect(r.grow(4.0), Color(0.02, 0.025, 0.035, 0.88), false, 4.0)
		_rotor_canvas.draw_rect(r, Color(0.04, 0.05, 0.07, 0.42), true)
		_rotor_canvas.draw_rect(r, Color(0.24, 0.28, 0.33, 0.85), false, 2.0)

	# 3. Heat sink radiator fin banks in the trench bottoms
	for hsb in HEAT_SINK_BANKS:
		var hr: Rect2 = hsb
		_rotor_canvas.draw_rect(hr.grow(2.0), Color(0.04, 0.05, 0.07, 0.95), true)
		_rotor_canvas.draw_rect(hr, Color(0.12, 0.15, 0.18, 0.95), true)
		var fin_spacing: float = 4.0
		var fx: float = hr.position.x + 2.0
		while fx < hr.end.x - 2.0:
			_rotor_canvas.draw_line(Vector2(fx, hr.position.y + 2.0), Vector2(fx, hr.end.y - 2.0), Color(0.03, 0.04, 0.05, 0.90), 1.5, false)
			_rotor_canvas.draw_line(Vector2(fx + 1.0, hr.position.y + 2.0), Vector2(fx + 1.0, hr.end.y - 2.0), Color(0.24, 0.28, 0.34, 0.85), 1.0, false)
			fx += fin_spacing
		_rotor_canvas.draw_rect(hr, Color(0.20, 0.25, 0.30, 0.90), false, 1.5)

	# 4. Industrial Cable Ladder Trays (parallel steel rails with cross rungs)
	for tray in CABLE_LADDER_TRAYS:
		var p0: Vector2 = tray["from"]
		var p1: Vector2 = tray["to"]
		var width: float = float(tray["width"])
		var spacing: float = float(tray["spacing"])
		var dir: Vector2 = (p1 - p0).normalized()
		var norm: Vector2 = Vector2(-dir.y, dir.x)
		var len_total: float = p0.distance_to(p1)

		# Side rails
		var r0_start: Vector2 = p0 - norm * (width * 0.5)
		var r0_end: Vector2 = p1 - norm * (width * 0.5)
		var r1_start: Vector2 = p0 + norm * (width * 0.5)
		var r1_end: Vector2 = p1 + norm * (width * 0.5)

		_rotor_canvas.draw_line(r0_start, r0_end, Color(0.04, 0.05, 0.06, 0.95), 4.0, false)
		_rotor_canvas.draw_line(r1_start, r1_end, Color(0.04, 0.05, 0.06, 0.95), 4.0, false)
		_rotor_canvas.draw_line(r0_start, r0_end, Color(0.18, 0.22, 0.26, 0.95), 2.0, false)
		_rotor_canvas.draw_line(r1_start, r1_end, Color(0.18, 0.22, 0.26, 0.95), 2.0, false)

		# Ladder rungs & bundled cables
		var d: float = spacing * 0.5
		while d < len_total:
			var center_pt: Vector2 = p0 + dir * d
			var rung0: Vector2 = center_pt - norm * (width * 0.5)
			var rung1: Vector2 = center_pt + norm * (width * 0.5)
			_rotor_canvas.draw_line(rung0, rung1, Color(0.14, 0.17, 0.20, 0.95), 2.0, false)
			d += spacing

		# Heavy dark cables strapped along the tray
		_rotor_canvas.draw_line(p0 - norm * 2.0, p1 - norm * 2.0, Color(0.08, 0.09, 0.11, 0.95), 3.5, false)
		_rotor_canvas.draw_line(p0 + norm * 2.0, p1 + norm * 2.0, Color(0.12, 0.14, 0.16, 0.95), 2.5, false)

	# 5. Heavy Industrial Pipe Networks (casing, bolted flanges, and flowing fluid pulses)
	for pnet in _pipe_networks:
		var pts: PackedVector2Array = pnet["pts"]
		var pw: float = float(pnet["width"])
		var core_col: Color = pnet["core_col"]
		var pulse_col: Color = pnet["pulse_col"]
		var spd: float = float(pnet["speed"])
		var fstep: float = float(pnet["flange_step"])

		# Drop shadow under the pipe
		_rotor_canvas.draw_polyline(pts, Color(0.02, 0.025, 0.035, 0.92), pw + 5.0, false)
		# Outer metallic pipe casing
		_rotor_canvas.draw_polyline(pts, Color(0.10, 0.12, 0.15, 0.98), pw + 1.0, false)
		_rotor_canvas.draw_polyline(pts, Color(0.18, 0.22, 0.26, 0.96), pw - 2.0, false)
		# Inner fluid core
		_rotor_canvas.draw_polyline(pts, core_col, pw * 0.40, false)
		# Specular top highlight line
		_rotor_canvas.draw_polyline(pts, Color(0.35, 0.42, 0.48, 0.85), 1.5, false)

		# Animated fluid pulses flowing through the line
		var flow_offset: float = fposmod(_time * spd, 40.0)
		for seg in range(pts.size() - 1):
			var a: Vector2 = pts[seg]
			var b: Vector2 = pts[seg + 1]
			var seg_len: float = a.distance_to(b)
			if seg_len <= 1.0:
				continue
			var sdir: Vector2 = (b - a) / seg_len
			var snorm: Vector2 = Vector2(-sdir.y, sdir.x)

			# Moving glowing dash pulses
			var cur_d: float = flow_offset
			while cur_d < seg_len:
				var p_start: Vector2 = a + sdir * cur_d
				var p_end: Vector2 = a + sdir * mini(cur_d + 12.0, seg_len)
				_rotor_canvas.draw_line(p_start, p_end, pulse_col, pw * 0.45, false)
				cur_d += 40.0

			# Bolted flange collars at regular intervals along segment
			var fd: float = fstep * 0.5
			while fd < seg_len:
				var f_pt: Vector2 = a + sdir * fd
				var fl0: Vector2 = f_pt - snorm * (pw * 0.70)
				var fl1: Vector2 = f_pt + snorm * (pw * 0.70)
				_rotor_canvas.draw_line(fl0, fl1, Color(0.04, 0.05, 0.06, 0.95), 4.0, false)
				_rotor_canvas.draw_line(fl0, fl1, Color(0.28, 0.34, 0.40, 0.95), 2.5, false)
				# Flange bolt heads
				_rotor_canvas.draw_circle(f_pt - snorm * (pw * 0.50), 1.2, Color(0.42, 0.48, 0.54, 0.95))
				_rotor_canvas.draw_circle(f_pt + snorm * (pw * 0.50), 1.2, Color(0.42, 0.48, 0.54, 0.95))
				fd += fstep

	# 6. Catenary Sagging Wires and Hanging Cable Bundles
	for wire in SAGGING_WIRE_HARNESSES:
		var p0: Vector2 = wire["p0"]
		var p1: Vector2 = wire["p1"]
		var sag: float = float(wire["sag"])
		var strand_count: int = int(wire["strands"])
		var steps: int = 16

		var strand_colors: Array = [
			Color(0.08, 0.09, 0.11, 0.95), # Heavy black rubber sleeve
			Color(0.85, 0.48, 0.18, 0.92), # Amber power wire
			Color(0.20, 0.70, 0.82, 0.90), # Cyan sensor wire
			Color(0.22, 0.25, 0.28, 0.95), # Braided steel ground
		]

		for s in range(strand_count):
			var scol: Color = strand_colors[s % strand_colors.size()]
			var y_shift: float = float(s) * 2.2 - float(strand_count) * 1.1
			var curve_pts: PackedVector2Array = PackedVector2Array()

			for st in range(steps + 1):
				var t: float = float(st) / float(steps)
				# Parabolic / catenary sag: 4 * sag * t * (1 - t)
				var sag_y: float = 4.0 * (sag + float(s) * 1.5) * t * (1.0 - t)
				var pt: Vector2 = p0.lerp(p1, t) + Vector2(0.0, sag_y + y_shift)
				curve_pts.append(pt)

			# Drop shadow under wire
			var shadow_pts: PackedVector2Array = PackedVector2Array()
			for cp in curve_pts:
				shadow_pts.append(cp + Vector2(0.0, 2.0))
			_rotor_canvas.draw_polyline(shadow_pts, Color(0.02, 0.03, 0.04, 0.70), 2.2, false)

			# Wire strand
			_rotor_canvas.draw_polyline(curve_pts, scol, 2.0 if s == 0 else 1.4, false)

		# Cable zip-ties / binding collars along the bundle
		for tie_frac in [0.25, 0.50, 0.75]:
			var mid_t: float = tie_frac
			var mid_sag: float = 4.0 * sag * mid_t * (1.0 - mid_t)
			var tie_pt: Vector2 = p0.lerp(p1, mid_t) + Vector2(0.0, mid_sag)
			_rotor_canvas.draw_line(tie_pt - Vector2(0.0, 5.0), tie_pt + Vector2(0.0, 5.0), Color(0.03, 0.04, 0.05, 0.95), 3.0, false)
			_rotor_canvas.draw_line(tie_pt - Vector2(0.0, 4.0), tie_pt + Vector2(0.0, 4.0), Color(0.35, 0.40, 0.45, 0.95), 1.5, false)

	# 7. Wall-Mounted Junction Boxes with Blinking Telemetry LEDs
	for jb in JUNCTION_BOXES:
		var jpos: Vector2 = jb["pos"]
		var jsize: Vector2 = jb["size"]
		var lcol: Color = jb["led_col"]
		var bspd: float = float(jb["blink_speed"])
		var box_rect: Rect2 = Rect2(jpos - jsize * 0.5, jsize)

		# Drop shadow and box body
		_rotor_canvas.draw_rect(box_rect.grow(2.0), Color(0.03, 0.04, 0.05, 0.90), true)
		_rotor_canvas.draw_rect(box_rect, Color(0.14, 0.17, 0.20, 0.98), true)
		_rotor_canvas.draw_rect(box_rect, Color(0.25, 0.30, 0.35, 0.90), false, 1.5)

		# Inner door panel groove
		_rotor_canvas.draw_rect(box_rect.grow(-3.0), Color(0.10, 0.12, 0.15, 0.95), true)

		# Status LED (pulsing / blinking)
		var led_pulse: float = 0.5 + 0.5 * sin(_time * bspd * TAU)
		var active_led_col: Color = lcol
		active_led_col.a = 0.30 + 0.70 * (1.0 if led_pulse > 0.4 else 0.1)

		var led_pt: Vector2 = jpos + Vector2(-jsize.x * 0.25, -jsize.y * 0.25)
		_rotor_canvas.draw_circle(led_pt, 3.5, Color(active_led_col.r, active_led_col.g, active_led_col.b, active_led_col.a * 0.35))
		_rotor_canvas.draw_circle(led_pt, 1.8, active_led_col)
		_rotor_canvas.draw_circle(led_pt, 0.8, Color(1.0, 1.0, 1.0, active_led_col.a * 0.9))

	# 8. Recessed Sub-Hull Ventilation Fans & Turbine Heat-Exchangers
	for f in SUBHULL_FANS:
		var fpos: Vector2 = f["pos"]
		var rad: float = float(f["radius"])
		var spd: float = float(f["speed"])
		var blade_count: int = int(f.get("blades", 6))
		var glow_col: Color = f.get("glow", Color(0.55, 0.28, 0.12, 0.25))
		var ang: float = _time * spd

		# Outer steel housing & drop shadow
		_rotor_canvas.draw_circle(fpos, rad + 5.0, Color(0.02, 0.025, 0.035, 0.96))
		_rotor_canvas.draw_circle(fpos, rad + 2.5, Color(0.20, 0.24, 0.28, 0.98))
		_rotor_canvas.draw_circle(fpos, rad - 1.0, Color(0.03, 0.04, 0.05, 0.98))

		# Housing mounting studs (4 corner bolts)
		for stud_ang in [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]:
			var stud_pt: Vector2 = fpos + Vector2(cos(stud_ang), sin(stud_ang)) * (rad + 3.0)
			_rotor_canvas.draw_circle(stud_pt, 1.3, Color(0.35, 0.40, 0.46, 0.95))

		# Deep interior thermal glow with subtle breathing pulsation
		var glow_pulse: float = 0.85 + 0.15 * sin(_time * 2.5 + fpos.x * 0.01)
		var cur_glow: Color = glow_col
		cur_glow.a *= glow_pulse
		_rotor_canvas.draw_circle(fpos, rad * 0.65, cur_glow)

		# Rotating angled fan blades
		var blade_width_ang: float = TAU / float(blade_count) * 0.42
		for b in range(blade_count):
			var a0: float = ang + float(b) * TAU / float(blade_count)
			var a1: float = a0 + blade_width_ang
			var p0: Vector2 = fpos + Vector2(cos(a0), sin(a0)) * (rad * 0.20)
			var p1: Vector2 = fpos + Vector2(cos(a0), sin(a0)) * (rad - 3.5)
			var p2: Vector2 = fpos + Vector2(cos(a1), sin(a1)) * (rad - 3.5)
			var p3: Vector2 = fpos + Vector2(cos(a1), sin(a1)) * (rad * 0.20)

			# Blade polygon with specular lead edge
			_rotor_canvas.draw_colored_polygon(
				PackedVector2Array([p0, p1, p2, p3]),
				Color(0.18, 0.22, 0.26, 0.95)
			)
			_rotor_canvas.draw_line(p0, p1, Color(0.30, 0.36, 0.42, 0.95), 1.2, false)

		# Protective heavy grille crossbars & center hub
		_rotor_canvas.draw_line(fpos - Vector2(rad, 0.0), fpos + Vector2(rad, 0.0), Color(0.12, 0.15, 0.18, 0.95), 2.5, false)
		_rotor_canvas.draw_line(fpos - Vector2(0.0, rad), fpos + Vector2(0.0, rad), Color(0.12, 0.15, 0.18, 0.95), 2.5, false)
		_rotor_canvas.draw_line(fpos - Vector2(rad, 0.0), fpos + Vector2(rad, 0.0), Color(0.24, 0.28, 0.33, 0.90), 1.0, false)
		_rotor_canvas.draw_line(fpos - Vector2(0.0, rad), fpos + Vector2(0.0, rad), Color(0.24, 0.28, 0.33, 0.90), 1.0, false)

		# Center bearing hub cap
		_rotor_canvas.draw_circle(fpos, rad * 0.25, Color(0.04, 0.05, 0.06, 0.98))
		_rotor_canvas.draw_circle(fpos, rad * 0.20, Color(0.26, 0.30, 0.35, 0.98))
		_rotor_canvas.draw_circle(fpos, rad * 0.08, Color(0.10, 0.12, 0.15, 1.0))
