@tool
extends Node2D
## Intact four-direction chair. Root marks the center of the pedestal footprint.

enum Direction { NORTH, SOUTH, EAST, WEST }

const SHEET: Texture2D = preload("res://art/concepts/bridge_room_props/Four-way captain's chair sprite sheet.png")
# Visually verified directions: rear, front, facing right, facing left.
# Measured opaque body bounds plus two pixels; only the intact top row is used.
const REGIONS: Array[Rect2] = [
	Rect2(19, 52, 385, 419), Rect2(406, 52, 357, 419),
	Rect2(815, 52, 303, 419), Rect2(1181, 52, 303, 419),
]
# Pedestal ground-plane centers relative to the individually measured crops.
const FLOOR_ANCHORS: Array[Vector2] = [
	Vector2(193, 371), Vector2(178, 371), Vector2(152, 371), Vector2(154, 371),
]

@export var direction: Direction = Direction.NORTH:
	set(value):
		direction = value
		_refresh_preview()
@export_range(0.01, 0.3, 0.001) var artwork_scale: float = 0.065:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_size: Vector2 = Vector2(16, 6):
	set(value):
		footprint_size = value
		_refresh_preview()
@export var footprint_offset: Vector2 = Vector2.ZERO:
	set(value):
		footprint_offset = value
		_refresh_preview()


func _ready() -> void:
	_refresh_preview()


func get_footprint_points() -> PackedVector2Array:
	# A low oval follows the pedestal/feet, rather than blocking the tall backrest.
	var half := Vector2(maxf(footprint_size.x, 1.0), maxf(footprint_size.y, 1.0)) * 0.5
	var points := PackedVector2Array()
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * half)
	return points


func _refresh_preview() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	var collision := get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D
	if sprite == null or collision == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = REGIONS[int(direction)]
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.centered = false
	sprite.scale = Vector2.ONE * artwork_scale
	sprite.position = -FLOOR_ANCHORS[int(direction)] * artwork_scale
	var footprint := ConvexPolygonShape2D.new()
	footprint.points = get_footprint_points()
	collision.shape = footprint
	collision.position = footprint_offset
