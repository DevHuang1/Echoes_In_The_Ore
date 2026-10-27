@tool
extends "res://scripts/ship/crew_quarters_prop.gd"
## Extends the working quarters preview/anchor/footprint workflow without
## changing existing furniture. All dimensions below are unscaled world units.
const CROP_SHADER := preload("res://shaders/cargo_atlas_clip.gdshader")

@export_storage var appearance_names := PackedStringArray()
@export_storage var crop_outlines: Array[PackedVector2Array] = []
@export_storage var facing_vectors := PackedVector2Array()
@export_storage var footprint_kind: int = 0 # 0: cabinet, 1: pallet, 2: three crates
@export_storage var hide_markers_enabled := false
@export_storage var appearance: int = 0:
	set(value):
		appearance = value
		_refresh_preview()

@export var collision_enabled := true:
	set(value):
		collision_enabled = value
		_refresh_preview()

@export_group("Pallet Forks", "fork_")
@export var fork_north_length := 40.0:
	set(value):
		fork_north_length = value
		_refresh_preview()
@export var fork_south_length := 31.0:
	set(value):
		fork_south_length = value
		_refresh_preview()
@export var fork_side_length := 38.0:
	set(value):
		fork_side_length = value
		_refresh_preview()
@export var fork_width := 6.0:
	set(value):
		fork_width = value
		_refresh_preview()
@export var fork_spacing := 14.0:
	set(value):
		fork_spacing = value
		_refresh_preview()
@export var fork_side_width := 3.0:
	set(value):
		fork_side_width = value
		_refresh_preview()
@export var fork_north_offset := 37.0:
	set(value):
		fork_north_offset = value
		_refresh_preview()
@export var fork_south_offset := 18.0:
	set(value):
		fork_south_offset = value
		_refresh_preview()
@export var fork_side_offset := Vector2(27,32):
	set(value):
		fork_side_offset = value
		_refresh_preview()

@export_group("Hiding Access")
@export_range(30.0, 150.0, 5.0) var hide_transition_speed := 95.0
@export_range(4.0, 14.0, 1.0) var hide_door_tolerance := 10.0
@export var access_distance := 30.0:
	set(value):
		access_distance = value
		_refresh_preview()
@export var access_offset := Vector2.ZERO:
	set(value):
		access_offset = value
		_refresh_preview()
@export var hide_offset := Vector2.ZERO:
	set(value):
		hide_offset = value
		_refresh_preview()

var _crop_material: ShaderMaterial

func _validate_property(property: Dictionary) -> void:
	super._validate_property(property)
	if property.name == "appearance" and appearance_names.size() > 1:
		property.usage = PROPERTY_USAGE_DEFAULT
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(appearance_names)
	if str(property.name).begins_with("fork_") and footprint_kind != 1:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "footprint_corner_cut" and footprint_kind == 2:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name in ["access_distance", "access_offset", "hide_offset"] and not hide_markers_enabled:
		property.usage = PROPERTY_USAGE_STORAGE

func get_view_index() -> int:
	var views := maxi(view_names.size(), 1)
	return clampi(appearance * views + clampi(direction, 0, views - 1), 0, maxi(atlas_regions.size() - 1, 0))

func get_current_footprint_size() -> Vector2:
	return footprint_side_size if direction >= 2 and view_names.size() >= 4 else footprint_size

func _crate_polygons() -> Array[PackedVector2Array]:
	var size := Vector2(maxf(footprint_size.x, 1.0), maxf(footprint_size.y, 1.0))
	var result: Array[PackedVector2Array] = []
	# Three projected cabinet bases, preserving the V-shaped space between the
	# front crates instead of filling the whole visible sprite with one box.
	for normalized in [
		[Vector2(-0.5,-0.05), Vector2(-0.25,-0.30), Vector2(-0.06,-0.05), Vector2(-0.25,0.35)],
		[Vector2(0.06,0), Vector2(0.25,-0.25), Vector2(0.5,0), Vector2(0.25,0.5)],
		[Vector2(-0.22,-0.30), Vector2(0,-0.5), Vector2(0.22,-0.30), Vector2(0,-0.12)],
	]:
		var points := PackedVector2Array()
		for point in normalized:
			points.append(point * size)
		result.append(points)
	return result

func get_footprint_points() -> PackedVector2Array:
	if footprint_kind == 2:
		return _crate_polygons()[0]
	return super.get_footprint_points()

func _refresh_preview() -> void:
	super._refresh_preview()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	var main := get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D
	if sprite == null or main == null or artwork == null or atlas_regions.is_empty():
		return
	var index := get_view_index()
	if index < crop_outlines.size() and not crop_outlines[index].is_empty():
		if _crop_material == null:
			_crop_material = ShaderMaterial.new()
			_crop_material.shader = CROP_SHADER
		var points := crop_outlines[index].duplicate()
		var count := mini(points.size(), 128)
		points.resize(128)
		_crop_material.set_shader_parameter("clip_points", points)
		_crop_material.set_shader_parameter("clip_count", count)
		sprite.material = _crop_material
	else:
		sprite.material = null
	main.set_deferred("disabled", not collision_enabled)
	var extra_a := get_node_or_null("StaticBody2D/ExtraFootprintA") as CollisionShape2D
	var extra_b := get_node_or_null("StaticBody2D/ExtraFootprintB") as CollisionShape2D
	if extra_a == null or extra_b == null:
		return
	for extra in [extra_a, extra_b]:
		extra.set_deferred("disabled", not collision_enabled or footprint_kind == 0)
	if footprint_kind == 1:
		var facing := facing_vectors[clampi(direction, 0, facing_vectors.size() - 1)]
		var length := fork_side_length if direction >= 2 else fork_north_length if facing.y < 0 else fork_south_length
		var along := fork_north_offset if facing.y < 0 else fork_south_offset if facing.y > 0 else fork_side_offset.x if facing.x > 0 else fork_side_offset.y
		var spacing := fork_spacing if direction < 2 else 4.0
		var across := Vector2.RIGHT if direction < 2 else Vector2.DOWN
		var center := facing * along + (Vector2(0,-3) if direction >= 2 else Vector2.ZERO)
		for item in [[extra_a, -1.0], [extra_b, 1.0]]:
			var shape := RectangleShape2D.new()
			shape.size = Vector2(maxf(fork_width, 1), maxf(length, 1)) if direction < 2 else Vector2(maxf(length, 1), maxf(fork_side_width, 1))
			item[0].shape = shape
			item[0].position = footprint_offset + center + across * spacing * 0.5 * item[1]
	elif footprint_kind == 2:
		var polygons := _crate_polygons()
		for item in [[extra_a, 1], [extra_b, 2]]:
			var shape := ConvexPolygonShape2D.new()
			shape.points = polygons[item[1]]
			item[0].shape = shape
			item[0].position = footprint_offset
	for marker_name in ["AccessPoint", "HidePoint"]:
		var marker := get_node_or_null(marker_name) as Marker2D
		if marker != null:
			marker.visible = hide_markers_enabled
	var access := get_node_or_null("AccessPoint") as Marker2D
	var hide_marker := get_node_or_null("HidePoint") as Marker2D
	if access != null and hide_marker != null:
		var facing := facing_vectors[clampi(direction, 0, facing_vectors.size() - 1)] if not facing_vectors.is_empty() else Vector2.DOWN
		access.position = footprint_offset + facing * access_distance + access_offset
		hide_marker.position = footprint_offset + hide_offset
