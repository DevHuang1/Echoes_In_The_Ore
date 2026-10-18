@tool
extends Node2D
## Shared editor/runtime behavior for the six approved quarters furniture scenes.
## Artwork is independently sized. The unscaled root marks the floor anchor.

@export_storage var artwork: Texture2D
@export_storage var atlas_regions: Array[Rect2] = []
@export_storage var floor_anchors: PackedVector2Array = PackedVector2Array()
@export_storage var view_names: PackedStringArray = PackedStringArray():
	set(value):
		view_names = value
		notify_property_list_changed()
@export_storage var oval_footprint: bool = false
@export_storage var direction: int = 0:
	set(value):
		direction = value
		_refresh_preview()

@export_range(0.01, 0.3, 0.001) var artwork_scale: float = 0.1:
	set(value):
		artwork_scale = value
		_refresh_preview()

@export_group("Floor Footprint", "footprint_")
@export var footprint_size: Vector2 = Vector2(40, 16):
	set(value):
		footprint_size = value
		_refresh_preview()
@export var footprint_side_size: Vector2 = Vector2(18, 16):
	set(value):
		footprint_side_size = value
		_refresh_preview()
@export_range(0.0, 20.0, 0.5) var footprint_corner_cut: float = 3.0:
	set(value):
		footprint_corner_cut = value
		_refresh_preview()
@export var footprint_offset: Vector2 = Vector2.ZERO:
	set(value):
		footprint_offset = value
		_refresh_preview()


func _validate_property(property: Dictionary) -> void:
	if property.name == "direction" and view_names.size() > 1:
		property.usage = PROPERTY_USAGE_DEFAULT
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(view_names)
	if property.name == "footprint_side_size" and view_names.size() < 4:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "footprint_corner_cut" and oval_footprint:
		property.usage = PROPERTY_USAGE_STORAGE


func _ready() -> void:
	_refresh_preview()


func get_view_index() -> int:
	return clampi(direction, 0, maxi(atlas_regions.size() - 1, 0))


func get_current_footprint_size() -> Vector2:
	return footprint_side_size if get_view_index() >= 2 else footprint_size


func get_footprint_points() -> PackedVector2Array:
	var size := get_current_footprint_size()
	var half := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0)) * 0.5
	if oval_footprint:
		var points := PackedVector2Array()
		for i in range(12):
			var angle := TAU * float(i) / 12.0
			points.append(Vector2(cos(angle), sin(angle)) * half)
		return points
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
	if sprite == null or collision == null or artwork == null or atlas_regions.is_empty() or floor_anchors.size() != atlas_regions.size():
		return
	var index := get_view_index()
	var atlas := AtlasTexture.new()
	atlas.atlas = artwork
	atlas.region = atlas_regions[index]
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.centered = false
	sprite.scale = Vector2.ONE * artwork_scale
	sprite.position = -floor_anchors[index] * artwork_scale
	var shape := ConvexPolygonShape2D.new()
	shape.points = get_footprint_points()
	collision.shape = shape
	collision.position = footprint_offset
