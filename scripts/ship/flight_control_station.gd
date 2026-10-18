@tool
extends Node2D
## Decorative solid furniture. Root position marks the center of the floor base.

enum Direction { NORTH, SOUTH, EAST, WEST }
enum StationState { OPERATIONAL, MALFUNCTIONING }

const SHEET: Texture2D = preload("res://art/concepts/bridge_room_props/Pixel-Art Flight Control Station Sprite Sheet.png")
# Individually measured alpha >= 8/255 bounds with two pixels of padding.
# Sheet columns are rear/North, front/South, right/East, left/West.
const REGIONS: Array[Rect2] = [
	Rect2(28, 94, 440, 315), Rect2(500, 84, 603, 340),
	Rect2(1131, 82, 289, 324), Rect2(1456, 82, 289, 324),
	Rect2(28, 503, 440, 319), Rect2(500, 497, 603, 340),
	Rect2(1129, 493, 291, 326), Rect2(1458, 493, 287, 326),
]
const FLOOR_ANCHORS: Array[Vector2] = [
	Vector2(218, 235), Vector2(300, 260), Vector2(143, 244), Vector2(144, 244),
	Vector2(218, 239), Vector2(300, 260), Vector2(145, 246), Vector2(142, 246),
]

@export var direction: Direction = Direction.SOUTH:
	set(value):
		direction = value
		_refresh_preview()
@export var state: StationState = StationState.OPERATIONAL:
	set(value):
		state = value
		_refresh_preview()
@export_range(0.01, 0.5, 0.005) var artwork_scale: float = 0.12:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_north_south_size: Vector2 = Vector2(52, 18):
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
