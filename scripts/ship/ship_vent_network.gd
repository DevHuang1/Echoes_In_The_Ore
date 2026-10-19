@tool
extends Node2D

const LONG_VENT := preload("res://art/props/floor_decals/floor_vent_long_refined.png")
const JUNCTION_VENT := preload("res://art/props/floor_decals/floor_vent_square_refined.png")

const ROOM_AND_HALLWAY_VENTS: Array[Dictionary] = [
	# Main Hallways & Vestibules
	{"id": &"hallway_west_foyer", "pos": Vector2(356.0, 346.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	{"id": &"hallway_airlock", "pos": Vector2(478.5, 332.0), "kind": &"square", "scale": Vector2(0.030, 0.030), "rot": 0.0},
	{"id": &"hallway_main_west", "pos": Vector2(612.0, 390.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	{"id": &"hallway_main_east", "pos": Vector2(960.0, 390.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	# R01 Bridge (inside the bridge room floor)
	{"id": &"r01_bridge", "pos": Vector2(198.0, 346.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R02 Upper Main Room (west, center, and east bays)
	{"id": &"r02_upper_main_west", "pos": Vector2(715.0, 185.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r02_upper_main", "pos": Vector2(860.0, 155.0), "kind": &"long", "scale": Vector2(0.036, 0.036), "rot": 0.0},
	{"id": &"r02_upper_main_east", "pos": Vector2(995.0, 185.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R03 Center Recess
	{"id": &"r03_center_recess_west", "pos": Vector2(805.0, 328.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	{"id": &"r03_center_recess_east", "pos": Vector2(918.0, 328.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	# R04 Power Maintenance
	{"id": &"r04_power_maint", "pos": Vector2(1118.0, 340.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	# R05 Life Support
	{"id": &"r05_life_support", "pos": Vector2(1275.0, 336.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	# R06 Engine Room (upper, center, and lower decks)
	{"id": &"r06_engine_room_upper", "pos": Vector2(1472.0, 300.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r06_engine_room", "pos": Vector2(1485.0, 390.0), "kind": &"long", "scale": Vector2(0.036, 0.036), "rot": PI * 0.5},
	{"id": &"r06_engine_room_lower", "pos": Vector2(1472.0, 480.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R07 Crew Living Quarters (west bunks & central living area)
	{"id": &"r07_crew_quarters_west", "pos": Vector2(370.0, 585.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r07_crew_quarters", "pos": Vector2(485.0, 565.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R08 Central Lower Bay
	{"id": &"r08_central_bay_west", "pos": Vector2(805.0, 565.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r08_central_bay", "pos": Vector2(985.0, 565.0), "kind": &"long", "scale": Vector2(0.036, 0.036), "rot": 0.0},
	# R09 Shuttle Bay (clear floor west of cargo bundle)
	{"id": &"r09_shuttle_bay", "pos": Vector2(1248.0, 628.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R10 Hydroponics Bay (West Lower Deck)
	{"id": &"r10_hydroponics_west", "pos": Vector2(165.0, 748.0), "kind": &"square", "scale": Vector2(0.032, 0.032), "rot": 0.0},
	{"id": &"r10_hydroponics_lower", "pos": Vector2(335.0, 712.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	# R11 Lower Deck East (previously missing vents)
	{"id": &"r11_lower_deck_east_west", "pos": Vector2(665.0, 712.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r11_lower_deck_east", "pos": Vector2(885.0, 748.0), "kind": &"long", "scale": Vector2(0.036, 0.036), "rot": 0.0},
]

# Airplane cabin-style twin parallel floor emergency escape lighting strips across the ship
const CABIN_LIGHT_STRIP_ROUTES: Array[Dictionary] = [
	# Main corridor spine (Bridge to Engine Room)
	{
		"points": [Vector2(300.0, 390.0), Vector2(1465.0, 390.0)],
		"aisle_half_width": 11.5,
	},
	# Emergency exit corridor leading north to the Exterior Airlock Gate
	{
		"points": [Vector2(478.5, 390.0), Vector2(478.5, 266.0)],
		"aisle_half_width": 12.5,
	},
	# R01 Bridge branch
	{
		"points": [Vector2(300.0, 390.0), Vector2(300.0, 346.0), Vector2(215.0, 346.0)],
		"aisle_half_width": 9.0,
	},
	# R02 Upper Main Room loop
	{
		"points": [Vector2(650.0, 390.0), Vector2(650.0, 155.0), Vector2(1046.5, 155.0), Vector2(1046.5, 390.0)],
		"aisle_half_width": 9.5,
	},
	# R03 Center Recess branch
	{
		"points": [Vector2(862.0, 390.0), Vector2(862.0, 316.0)],
		"aisle_half_width": 8.5,
	},
	# R05 Life Support & R06 Engine Room upper branch
	{
		"points": [Vector2(1197.5, 390.0), Vector2(1197.5, 280.0), Vector2(1296.0, 280.0)],
		"aisle_half_width": 8.5,
	},
	# R07 Crew Quarters & R10 Lower Deck / Hydroponics west spine
	{
		"points": [Vector2(521.5, 390.0), Vector2(521.5, 748.0), Vector2(335.0, 748.0)],
		"aisle_half_width": 9.5,
	},
	# R08 Central Lower Bay & R10 Lower Deck east loop
	{
		"points": [Vector2(865.0, 390.0), Vector2(865.0, 748.0), Vector2(521.5, 748.0)],
		"aisle_half_width": 9.5,
	},
	{
		"points": [Vector2(865.0, 535.0), Vector2(1111.5, 535.0), Vector2(1111.5, 390.0)],
		"aisle_half_width": 9.5,
	},
	# R09 Shuttle Bay branch
	{
		"points": [Vector2(1252.5, 390.0), Vector2(1252.5, 590.0), Vector2(1295.0, 590.0)],
		"aisle_half_width": 9.0,
	},
]

# Vibrant blue airplane emergency escape floor lighting palette (matching reference image style in blue)
const BLOOM_OUTER_BLUE := Color(0.03, 0.36, 1.0, 0.12)
const BLOOM_MID_BLUE := Color(0.06, 0.50, 1.0, 0.24)
const BLOOM_INNER_BLUE := Color(0.14, 0.66, 1.0, 0.44)
const TRACK_HOUSING_COLOR := Color(0.04, 0.13, 0.28, 0.88)
const STRIP_BASE_BLUE := Color(0.14, 0.56, 1.0, 0.86)
const BAR_GLOW_BLUE := Color(0.20, 0.72, 1.0, 0.40)
const BAR_BODY_BLUE := Color(0.38, 0.84, 1.0, 0.96)
const BAR_CORE_WHITE_BLUE := Color(0.88, 0.98, 1.0, 1.0)

var _long_vent_tex: Texture2D = LONG_VENT
var _junction_vent_tex: Texture2D = JUNCTION_VENT
var _pulse_time := 0.0


func _ready() -> void:
	var long_img := Image.load_from_file(ProjectSettings.globalize_path("res://art/props/floor_decals/floor_vent_long_refined.png"))
	if long_img != null and not long_img.is_empty():
		_long_vent_tex = ImageTexture.create_from_image(long_img)
	var junc_img := Image.load_from_file(ProjectSettings.globalize_path("res://art/props/floor_decals/floor_vent_square_refined.png"))
	if junc_img != null and not junc_img.is_empty():
		_junction_vent_tex = ImageTexture.create_from_image(junc_img)

	for child in get_children():
		child.queue_free()
	for vent in ROOM_AND_HALLWAY_VENTS:
		var pos: Vector2 = vent["pos"]
		var rot: float = float(vent.get("rot", 0.0))
		var sc: Vector2 = vent.get("scale", Vector2(0.035, 0.035))
		var kind: StringName = vent.get("kind", &"square")
		var sprite := Sprite2D.new()
		sprite.name = "Vent_%s" % String(vent.get("id", &"vent"))
		sprite.z_as_relative = false
		sprite.z_index = -1
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = _long_vent_tex if kind == &"long" else _junction_vent_tex
		sprite.position = pos
		sprite.rotation = rot
		sprite.scale = sc
		add_child(sprite)

	set_process(not Engine.is_editor_hint())
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time = fposmod(_pulse_time + delta * 2.2, TAU)
	queue_redraw()


func _draw() -> void:
	# Draw airplane cabin-style twin blue emergency escape floor light strips across the ship
	for route_data in CABIN_LIGHT_STRIP_ROUTES:
		var pts: Array = route_data["points"]
		var half_w: float = float(route_data.get("aisle_half_width", 9.5))
		_draw_cabin_light_route(pts, half_w)


func _draw_cabin_light_route(pts: Array, aisle_half_width: float) -> void:
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var delta := b - a
		var seg_len := delta.length()
		if seg_len < 1.0:
			continue
		var dir := delta / seg_len
		var normal := Vector2(-dir.y, dir.x)

		for side: float in [-1.0, 1.0]:
			var offset := normal * (aisle_half_width * side)
			var p0 := a + offset
			var p1 := b + offset

			# Multi-layered soft blue neon floor bloom around the track
			draw_line(p0, p1, BLOOM_OUTER_BLUE, 12.0, false)
			draw_line(p0, p1, BLOOM_MID_BLUE, 7.5, false)
			draw_line(p0, p1, BLOOM_INNER_BLUE, 4.6, false)

			# Recessed floor channel housing + continuous blue illuminated strip base
			draw_line(p0, p1, TRACK_HOUSING_COLOR, 3.4, false)
			draw_line(p0, p1, STRIP_BASE_BLUE, 2.2, false)

			# Corner end-caps so right-angle turns join seamlessly
			draw_circle(p0, 3.6, BLOOM_MID_BLUE)
			draw_circle(p0, 1.7, TRACK_HOUSING_COLOR)
			draw_circle(p0, 1.1, STRIP_BASE_BLUE)
			draw_circle(p1, 3.6, BLOOM_MID_BLUE)
			draw_circle(p1, 1.7, TRACK_HOUSING_COLOR)
			draw_circle(p1, 1.1, STRIP_BASE_BLUE)

			# Segmented glowing rectangular light bars inside the strip (matching the reference photo)
			var bar_len := 10.0
			var gap_len := 5.5
			var step := bar_len + gap_len
			var d := 3.0
			var idx := 0
			while d + bar_len <= seg_len - 2.0:
				var bar_start := p0 + dir * d
				var bar_end := p0 + dir * (d + bar_len)
				var core_start := p0 + dir * (d + 1.1)
				var core_end := p0 + dir * (d + bar_len - 1.1)

				var shimmer := 0.90 + 0.10 * sin(_pulse_time - float(idx) * 0.45)
				var glow_c := Color(BAR_GLOW_BLUE.r, BAR_GLOW_BLUE.g, BAR_GLOW_BLUE.b, BAR_GLOW_BLUE.a * shimmer)
				var body_c := Color(BAR_BODY_BLUE.r, BAR_BODY_BLUE.g, BAR_BODY_BLUE.b, BAR_BODY_BLUE.a * shimmer)
				var core_c := Color(BAR_CORE_WHITE_BLUE.r, BAR_CORE_WHITE_BLUE.b, BAR_CORE_WHITE_BLUE.b, BAR_CORE_WHITE_BLUE.a * shimmer)

				draw_line(bar_start, bar_end, glow_c, 6.0, false)
				draw_line(bar_start, bar_end, body_c, 2.6, false)
				draw_line(core_start, core_end, core_c, 1.4, false)

				d += step
				idx += 1
