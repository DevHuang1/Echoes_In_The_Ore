@tool
extends Node2D
## Decorative navigation console. The root marks the center of its floor footprint.
## Artwork and collision are sized independently; leave the root scale at (1, 1).

enum Direction { NORTH, SOUTH, EAST, WEST }
enum ConsoleState { OPERATIONAL, MALFUNCTIONING }

const SHEET: Texture2D = preload("res://art/concepts/bridge_room_props/Flat rear console panel redesign.png")
# Measured nontransparent bounds, in North/South/East/West order for each state.
# These are explicit crops, not an evenly divided grid.
const REGIONS: Array[Rect2] = [
	Rect2(46, 31, 488, 404), Rect2(557, 31, 540, 405),
	Rect2(1110, 27, 303, 410), Rect2(1451, 25, 289, 413),
	Rect2(46, 449, 487, 414), Rect2(555, 449, 540, 404),
	Rect2(1110, 450, 297, 393), Rect2(1449, 451, 293, 394),
]
# Each crop has its own base-center anchor. The bottom of the cabinet is 75 source
# pixels below the floor center, including the visible front of the footprint.
const FLOOR_ANCHORS: Array[Vector2] = [
	Vector2(244, 329), Vector2(272, 330), Vector2(145, 335), Vector2(142, 338),
	Vector2(244, 339), Vector2(274, 329), Vector2(145, 318), Vector2(144, 319),
]

@export var direction: Direction = Direction.SOUTH:
	set(value):
		direction = value
		_refresh_preview()
@export var state: ConsoleState = ConsoleState.OPERATIONAL:
	set(value):
		state = value
		_refresh_preview()
@export_range(0.01, 0.5, 0.005) var artwork_scale: float = 0.12:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_north_south_size: Vector2 = Vector2(58, 18):
	set(value):
		footprint_north_south_size = value
		_refresh_preview()
@export var footprint_east_west_size: Vector2 = Vector2(28, 18):
	set(value):
		footprint_east_west_size = value
		_refresh_preview()
@export var footprint_offset: Vector2 = Vector2.ZERO:
	set(value):
		footprint_offset = value
		_refresh_preview()


func _ready() -> void:
	_refresh_preview()


func _refresh_preview() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	var collision := get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D
	if sprite == null or collision == null:
		return
	var index := int(state) * 4 + int(direction)
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = REGIONS[index]
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.centered = false
	sprite.scale = Vector2.ONE * artwork_scale
	sprite.position = -FLOOR_ANCHORS[index] * artwork_scale
	var footprint := RectangleShape2D.new()
	var size := footprint_north_south_size if direction < Direction.EAST else footprint_east_west_size
	footprint.size = Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	collision.shape = footprint
	collision.position = footprint_offset
