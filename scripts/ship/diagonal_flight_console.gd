@tool
extends Node2D
## The root is the floor center. Size the artwork and footprint independently.

enum Direction { NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST }
enum ConsoleState { OPERATIONAL, MALFUNCTIONING }

const SHEET: Texture2D = preload("res://art/concepts/bridge_room_props/diagonal-flight-console-v2.png")
# Individually measured visible-alpha bounds plus two pixels of padding.
# Alpha-1 background specks are excluded; this is not a uniform sheet grid.
const REGIONS: Array[Rect2] = [
	Rect2(36, 58, 395, 380), Rect2(451, 55, 392, 381),
	Rect2(875, 49, 427, 386), Rect2(1336, 49, 421, 386),
	Rect2(36, 465, 397, 384), Rect2(451, 463, 392, 386),
	Rect2(875, 456, 428, 389), Rect2(1336, 456, 422, 389),
]
# Historical width units preserve saved Artwork Scale values; these are sizes,
# not coordinates from the old sheet. V2 is uniformly sized per view/state.
const REFERENCE_WIDTHS: Array[float] = [384.0, 390.0, 432.0, 410.0]
# V2 base-center anchors measured from each padded crop. Align the lower base
# tips to the existing footprint: 18.7 world units below the root at scale 0.17.
const FLOOR_ANCHORS: Array[Vector2] = [
	Vector2(197.5, 266.848958), Vector2(196, 270.435897),
	Vector2(213.5, 277.273148), Vector2(210.5, 273.048780),
	Vector2(198.5, 270.276042), Vector2(196, 275.435897),
	Vector2(214, 280.018519), Vector2(211, 275.780488),
]

@export var direction: Direction = Direction.SOUTHEAST:
	set(value):
		direction = value
		_refresh_preview()
@export var state: ConsoleState = ConsoleState.OPERATIONAL:
	set(value):
		state = value
		_refresh_preview()
@export_range(0.01, 0.5, 0.005) var artwork_scale: float = 0.17:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export_range(1.0, 200.0, 0.5) var footprint_length: float = 60.0:
	set(value):
		footprint_length = value
		_refresh_preview()
@export_range(1.0, 100.0, 0.5) var footprint_depth: float = 12.0:
	set(value):
		footprint_depth = value
		_refresh_preview()
@export var footprint_offset: Vector2 = Vector2.ZERO:
	set(value):
		footprint_offset = value
		_refresh_preview()


func _ready() -> void:
	_refresh_preview()


func get_source_scale() -> float:
	var index := int(state) * 4 + int(direction)
	return artwork_scale * REFERENCE_WIDTHS[int(direction)] / REGIONS[index].size.x


func get_footprint_points() -> PackedVector2Array:
	# The cabinet projects along +/-30-degree axes. A parallelogram follows its
	# actual diagonal base, leaving the empty corners of its bounding box walkable.
	var slope := 1.0 if direction in [Direction.NORTHEAST, Direction.SOUTHWEST] else -1.0
	var along := Vector2(0.8660254, slope * 0.5) * maxf(footprint_length, 1.0) * 0.5
	var across := Vector2(0.8660254, -slope * 0.5) * maxf(footprint_depth, 1.0) * 0.5
	return PackedVector2Array([-along - across, along - across, along + across, -along + across])


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
	var source_scale := get_source_scale()
	sprite.scale = Vector2.ONE * source_scale
	sprite.position = -FLOOR_ANCHORS[index] * source_scale
	var footprint := ConvexPolygonShape2D.new()
	footprint.points = get_footprint_points()
	collision.shape = footprint
	collision.position = footprint_offset
