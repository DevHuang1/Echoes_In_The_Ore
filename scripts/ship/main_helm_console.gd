@tool
extends Node2D
## Single operational overhead view. Root marks the cabinet's floor center.

const ARTWORK: Texture2D = preload("res://art/concepts/bridge_room_props/Rotated twin-screen operational helm console.png")
# Center of the solid cabinet bounds (alpha >= 8/255), excluding the faint halo.
const FLOOR_ANCHOR := Vector2(533, 776)

@export_range(0.01, 0.2, 0.001) var artwork_scale: float = 0.058:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_size: Vector2 = Vector2(28, 66):
	set(value):
		footprint_size = value
		_refresh_preview()
@export_range(0.0, 30.0, 0.5) var footprint_corner_cut: float = 8.0:
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
	var half := Vector2(maxf(footprint_size.x, 1.0), maxf(footprint_size.y, 1.0)) * 0.5
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
	sprite.texture = ARTWORK
	sprite.centered = false
	sprite.scale = Vector2.ONE * artwork_scale
	sprite.position = -FLOOR_ANCHOR * artwork_scale
	var footprint := ConvexPolygonShape2D.new()
	footprint.points = get_footprint_points()
	collision.shape = footprint
	collision.position = footprint_offset
