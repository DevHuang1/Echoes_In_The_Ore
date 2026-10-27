@tool
extends Node2D

const LONG_VENT: Texture2D = preload("res://art/props/floor_decals/floor_vent_long_refined.png")
const JUNCTION_VENT: Texture2D = preload("res://art/props/floor_decals/floor_vent_square_refined.png")

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
	# R11 Lower Deck East
	{"id": &"r11_lower_deck_east_west", "pos": Vector2(665.0, 712.0), "kind": &"square", "scale": Vector2(0.034, 0.034), "rot": 0.0},
	{"id": &"r11_lower_deck_east", "pos": Vector2(885.0, 748.0), "kind": &"long", "scale": Vector2(0.036, 0.036), "rot": 0.0},
]

var _long_vent_tex: Texture2D = LONG_VENT
var _junction_vent_tex: Texture2D = JUNCTION_VENT


func _ready() -> void:
	var long_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://art/props/floor_decals/floor_vent_long_refined.png"))
	if long_img != null and not long_img.is_empty():
		_long_vent_tex = ImageTexture.create_from_image(long_img)
	var junc_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://art/props/floor_decals/floor_vent_square_refined.png"))
	if junc_img != null and not junc_img.is_empty():
		_junction_vent_tex = ImageTexture.create_from_image(junc_img)

	for child in get_children():
		child.queue_free()
	for vent in ROOM_AND_HALLWAY_VENTS:
		var pos: Vector2 = vent["pos"]
		var rot: float = float(vent.get("rot", 0.0))
		var sc: Vector2 = vent.get("scale", Vector2(0.035, 0.035))
		var kind: StringName = vent.get("kind", &"square")
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "Vent_%s" % String(vent.get("id", &"vent"))
		sprite.z_as_relative = false
		sprite.z_index = -1
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = _long_vent_tex if kind == &"long" else _junction_vent_tex
		sprite.position = pos
		sprite.rotation = rot
		sprite.scale = sc
		add_child(sprite)

	set_process(false)
	queue_redraw()
