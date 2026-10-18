@tool
extends Node2D
## Low deck-plan table. Root is its floor footprint center; artwork sizes separately.

enum Direction { NORTH, SOUTH, EAST, WEST }
enum TableState { OPERATIONAL, DAMAGED }

const SHEET: Texture2D = preload("res://art/concepts/bridge_room_props/Pixel-art mission planning table sprite sheet.png")
# Visually inspected: horizontal rear (no buttons), horizontal front (buttons
# on lower edge), vertical right-edge controls, vertical left-edge controls.
# Top row is intact/operational; bottom row has cracked displays and housings.
const REGIONS: Array[Rect2] = [
	Rect2(27, 142, 500, 241), Rect2(587, 142, 510, 241),
	Rect2(1150, 81, 216, 331), Rect2(1509, 81, 214, 332),
	Rect2(27, 547, 500, 245), Rect2(583, 548, 515, 244),
	Rect2(1150, 497, 216, 329), Rect2(1508, 497, 218, 329),
]
const FLOOR_ANCHORS: Array[Vector2] = [
	Vector2(250, 171), Vector2(256, 171), Vector2(108, 261), Vector2(107, 262),
	Vector2(250, 175), Vector2(260, 174), Vector2(108, 259), Vector2(111, 259),
]

@export var direction: Direction = Direction.NORTH:
	set(value):
		direction = value
		_refresh_preview()
@export var state: TableState = TableState.OPERATIONAL:
	set(value):
		state = value
		_refresh_preview()
@export_range(0.01, 0.5, 0.005) var artwork_scale: float = 0.13:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_north_south_size: Vector2 = Vector2(58, 16):
	set(value):
		footprint_north_south_size = value
		_refresh_preview()
@export var footprint_east_west_size: Vector2 = Vector2(22, 16):
	set(value):
		footprint_east_west_size = value
		_refresh_preview()
@export_range(0.0, 30.0, 0.5) var footprint_corner_cut: float = 3.0:
	set(value):
		footprint_corner_cut = value
		_refresh_preview()
@export var footprint_offset: Vector2 = Vector2.ZERO:
	set(value):
		footprint_offset = value
		_refresh_preview()


func _ready() -> void:
	_refresh_preview()


func get_footprint_points() -> PackedVector2Array:
	var size := footprint_north_south_size if direction < Direction.EAST else footprint_east_west_size
	var half := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)) * 0.5
	var cut := clampf(footprint_corner_cut, 0.0, minf(half.x, half.y) * 0.9)
	if is_zero_approx(cut):
		return PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	return PackedVector2Array([
		Vector2(-half.x + cut, -half.y), Vector2(half.x - cut, -half.y),
		Vector2(half.x, -half.y + cut), Vector2(half.x, half.y - cut),
		Vector2(half.x - cut, half.y), Vector2(-half.x + cut, half.y),
		Vector2(-half.x, half.y - cut), Vector2(-half.x, -half.y + cut),
	])


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
	var footprint := ConvexPolygonShape2D.new()
	footprint.points = get_footprint_points()
	collision.shape = footprint
	collision.position = footprint_offset
