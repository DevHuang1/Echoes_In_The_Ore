@tool
extends Node2D

const LOWER_PANEL_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png"
const CARGO_GRATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_cargo_grate.png"
const LOWER_PLATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png"
const SMALL_GRATE_PATH: String = "res://art/overview/floor_modules/tiles/floor_tile_small_grate.png"
const POWER_CONVERTER_TEX: Texture2D = preload("res://art/concepts/ship_room_props/power_converter.png")

const TURBINE_MODULE_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/turbine_module.tscn")
const COOLANT_PUMP_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/coolant_circulation_pump.tscn")
const FUEL_MANIFOLD_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/fuel_valve_manifold.tscn")
const CYLINDER_RACK_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/secured_cylinder_rack.tscn")
const TIED_BOX_BUNDLE_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/tied_box_bundle.tscn")
const CARGO_LOCKER_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/cargo_locker.tscn")

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
	# Aft machinery bulkhead bay behind S03 and S06 (where external plumes used to be)
	Rect2(1715.0, 120.0, 195.0, 680.0),
	# Lower hull structural bays along south perimeter
	Rect2(215.0, 828.0, 520.0, 120.0),
	Rect2(760.0, 838.0, 610.0, 115.0),
	Rect2(1395.0, 812.0, 330.0, 135.0),
]

# Heavy structural sub-hull conduit runs connecting the recessed machinery bays
var _subhull_conduit_runs: Array = [
	PackedVector2Array([Vector2(-80.0, 472.0), Vector2(680.0, 472.0), Vector2(755.0, 472.0), Vector2(755.0, 630.0)]),
	PackedVector2Array([Vector2(755.0, 125.0), Vector2(1020.0, 125.0), Vector2(1020.0, 495.0), Vector2(1680.0, 495.0)]),
	PackedVector2Array([Vector2(1045.0, 350.0), Vector2(1045.0, 625.0), Vector2(1480.0, 625.0)]),
	PackedVector2Array([Vector2(120.0, 488.0), Vector2(120.0, 885.0), Vector2(1650.0, 885.0), Vector2(1795.0, 885.0)]),
	PackedVector2Array([Vector2(1795.0, 60.0), Vector2(1795.0, 885.0)]),
]

# Recessed sub-hull ventilation fans & heat-exchanger rotors spinning slowly in the machinery wells
const SUBHULL_FANS: Array = [
	{"pos": Vector2(220.0, 472.0), "radius": 24.0, "speed": 1.1},
	{"pos": Vector2(510.0, 472.0), "radius": 24.0, "speed": -0.95},
	{"pos": Vector2(758.0, 125.0), "radius": 32.0, "speed": 0.85},
	{"pos": Vector2(935.0, 125.0), "radius": 32.0, "speed": -0.85},
	{"pos": Vector2(758.0, 395.0), "radius": 34.0, "speed": 0.75},
	{"pos": Vector2(758.0, 535.0), "radius": 34.0, "speed": -0.75},
	{"pos": Vector2(1048.0, 435.0), "radius": 36.0, "speed": 0.90},
	{"pos": Vector2(1048.0, 555.0), "radius": 36.0, "speed": -0.90},
	{"pos": Vector2(1335.0, 545.0), "radius": 34.0, "speed": 1.05},
	{"pos": Vector2(1620.0, 505.0), "radius": 30.0, "speed": -1.15},
	{"pos": Vector2(1805.0, 265.0), "radius": 38.0, "speed": 0.80},
	{"pos": Vector2(1805.0, 680.0), "radius": 38.0, "speed": -0.80},
]

# Recessed pixel-art machinery & reserve storage props inside the sub-hull cavities (collision disabled)
const SUBHULL_PROP_PLACEMENTS: Array = [
	# North central auxiliary bay (above upper corridor)
	{"kind": &"turbine_module", "pos": Vector2(845.0, 122.0), "dir": 2},
	{"kind": &"coolant_pump", "pos": Vector2(715.0, 126.0), "dir": 1},
	{"kind": &"fuel_manifold", "pos": Vector2(980.0, 124.0), "dir": 1},
	# West lift shaft machinery well
	{"kind": &"cylinder_rack", "pos": Vector2(755.0, 335.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(755.0, 465.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(755.0, 595.0)},
	# East lift shaft machinery well
	{"kind": &"turbine_module", "pos": Vector2(1048.0, 375.0), "dir": 2},
	{"kind": &"fuel_manifold", "pos": Vector2(1125.0, 485.0), "dir": 1},
	{"kind": &"cylinder_rack", "pos": Vector2(1125.0, 585.0), "dir": 1},
	# West mid-deck trench (between S02 and S04)
	{"kind": &"coolant_pump", "pos": Vector2(150.0, 472.0), "dir": 1},
	{"kind": &"fuel_manifold", "pos": Vector2(295.0, 472.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(430.0, 472.0)},
	{"kind": &"coolant_pump", "pos": Vector2(585.0, 472.0), "dir": 1},
	# Southwest reserve bay (left of S04)
	{"kind": &"cylinder_rack", "pos": Vector2(118.0, 585.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(118.0, 675.0)},
	{"kind": &"cargo_locker", "pos": Vector2(118.0, 760.0), "dir": 2, "appearance": 1},
	# East mid-deck trench (between S03 and S06)
	{"kind": &"turbine_module", "pos": Vector2(1245.0, 545.0), "dir": 2},
	{"kind": &"coolant_pump", "pos": Vector2(1425.0, 545.0), "dir": 1},
	{"kind": &"fuel_manifold", "pos": Vector2(1555.0, 505.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(1685.0, 505.0)},
	# Aft machinery bulkhead bay (replacing external engine flames)
	{"kind": &"turbine_module", "pos": Vector2(1805.0, 185.0), "dir": 2},
	{"kind": &"fuel_manifold", "pos": Vector2(1805.0, 355.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(1805.0, 475.0), "dir": 1},
	{"kind": &"turbine_module", "pos": Vector2(1805.0, 595.0), "dir": 2},
	{"kind": &"box_bundle", "pos": Vector2(1805.0, 755.0)},
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

	# 2. Structural girders, recessed bay curbing, conduits & rotating sub-hull fans
	_rotor_canvas = Node2D.new()
	_rotor_canvas.name = "SubhullStructureCanvas"
	_rotor_canvas.draw.connect(_on_structure_canvas_draw)
	add_child(_rotor_canvas)

	# 3. Recessed pixel-art machinery & storage props in the sub-hull bays
	var props_root: Node2D = Node2D.new()
	props_root.name = "RecessedSubhullProps"
	props_root.modulate = Color(0.34, 0.38, 0.44, 1.0)
	add_child(props_root)

	for p_item in SUBHULL_PROP_PLACEMENTS:
		var kind: StringName = p_item["kind"]
		var p_pos: Vector2 = p_item["pos"]
		var scene: PackedScene = null
		match kind:
			&"turbine_module":
				scene = TURBINE_MODULE_SCENE
			&"coolant_pump":
				scene = COOLANT_PUMP_SCENE
			&"fuel_manifold":
				scene = FUEL_MANIFOLD_SCENE
			&"cylinder_rack":
				scene = CYLINDER_RACK_SCENE
			&"box_bundle":
				scene = TIED_BOX_BUNDLE_SCENE
			&"cargo_locker":
				scene = CARGO_LOCKER_SCENE
		if scene == null:
			continue
		var inst: Node2D = scene.instantiate() as Node2D
		inst.position = p_pos
		inst.set("collision_enabled", false)
		inst.set("hide_markers_enabled", false)
		if p_item.has("dir"):
			inst.set("direction", int(p_item["dir"]))
		if p_item.has("appearance"):
			inst.set("appearance", int(p_item["appearance"]))
		props_root.add_child(inst)

	# Auxiliary power converters in the recessed sub-hull bays
	var converter_positions: Array = [
		Vector2(698.0, 82.0),
		Vector2(995.0, 410.0),
		Vector2(1485.0, 505.0),
		Vector2(1755.0, 415.0),
	]
	for cpos in converter_positions:
		var sp: Sprite2D = Sprite2D.new()
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.texture = POWER_CONVERTER_TEX
		sp.scale = Vector2(0.026, 0.026)
		sp.position = cpos
		props_root.add_child(sp)


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

	# 3. Sub-hull armored conduit trunks
	for run in _subhull_conduit_runs:
		var pts: PackedVector2Array = run
		_rotor_canvas.draw_polyline(pts, Color(0.02, 0.03, 0.04, 0.92), 11.0, false)
		_rotor_canvas.draw_polyline(pts, Color(0.15, 0.18, 0.21, 0.96), 7.0, false)
		_rotor_canvas.draw_polyline(pts, Color(0.28, 0.33, 0.38, 0.90), 2.5, false)

	# 4. Recessed sub-hull ventilation fans & turbine heat-exchangers
	for f in SUBHULL_FANS:
		var fpos: Vector2 = f["pos"]
		var rad: float = float(f["radius"])
		var spd: float = float(f["speed"])
		var ang: float = _time * spd

		# Outer housing & dark pit
		_rotor_canvas.draw_circle(fpos, rad + 4.0, Color(0.02, 0.03, 0.04, 0.95))
		_rotor_canvas.draw_circle(fpos, rad + 1.5, Color(0.18, 0.22, 0.26, 0.95))
		_rotor_canvas.draw_circle(fpos, rad - 1.5, Color(0.04, 0.05, 0.07, 0.96))

		# Subtle warm turbine glow deep inside the housing
		_rotor_canvas.draw_circle(fpos, rad * 0.55, Color(0.55, 0.28, 0.12, 0.18))

		# Rotating fan blades
		var blade_count: int = 6
		for b in range(blade_count):
			var a0: float = ang + float(b) * TAU / float(blade_count)
			var a1: float = a0 + 0.34
			var p0: Vector2 = fpos + Vector2(cos(a0), sin(a0)) * (rad * 0.22)
			var p1: Vector2 = fpos + Vector2(cos(a0), sin(a0)) * (rad - 3.0)
			var p2: Vector2 = fpos + Vector2(cos(a1), sin(a1)) * (rad - 3.0)
			var p3: Vector2 = fpos + Vector2(cos(a1), sin(a1)) * (rad * 0.22)
			_rotor_canvas.draw_colored_polygon(
				PackedVector2Array([p0, p1, p2, p3]),
				Color(0.20, 0.24, 0.28, 0.92)
			)

		# Protective grille bars & center hub
		_rotor_canvas.draw_line(fpos - Vector2(rad, 0.0), fpos + Vector2(rad, 0.0), Color(0.14, 0.17, 0.20, 0.90), 2.0, false)
		_rotor_canvas.draw_line(fpos - Vector2(0.0, rad), fpos + Vector2(0.0, rad), Color(0.14, 0.17, 0.20, 0.90), 2.0, false)
		_rotor_canvas.draw_circle(fpos, rad * 0.24, Color(0.24, 0.28, 0.32, 0.98))
		_rotor_canvas.draw_circle(fpos, rad * 0.10, Color(0.10, 0.12, 0.15, 1.0))
