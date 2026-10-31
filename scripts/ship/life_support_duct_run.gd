@tool
extends Node2D

var DUCT_PATH := PackedVector2Array([
	Vector2(-20, 75),
	Vector2(0, 75),
	Vector2(16, 59),
	Vector2(126, 59),
	Vector2(144, 77),
	Vector2(144, 103),
])

const DUCT_SHADOW := Color(0.025, 0.035, 0.045, 0.98)
const DUCT_EDGE := Color(0.11, 0.18, 0.22, 1.0)
const DUCT_CASING := Color(0.04, 0.48, 0.59, 1.0)
const DUCT_GLOW := Color(0.13, 0.82, 0.94, 1.0)
const DUCT_GLINT := Color(0.62, 0.96, 1.0, 0.9)


func _draw() -> void:
	draw_polyline(DUCT_PATH, DUCT_SHADOW, 22.0, true)
	draw_polyline(DUCT_PATH, DUCT_EDGE, 18.0, true)
	draw_polyline(DUCT_PATH, DUCT_CASING, 14.0, true)
	draw_polyline(DUCT_PATH, DUCT_GLOW, 8.0, true)
	draw_polyline(_offset_points(DUCT_PATH, Vector2(0, -2.0)), DUCT_GLINT, 1.6, true)
	for point in [Vector2(16, 59), Vector2(72, 59), Vector2(126, 59), Vector2(144, 77)]:
		_draw_clamp(point)


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted


func _draw_clamp(point: Vector2) -> void:
	draw_circle(point, 9.0, DUCT_SHADOW)
	draw_circle(point, 6.5, DUCT_EDGE)
	draw_circle(point, 3.7, DUCT_CASING)
	draw_circle(point, 1.5, DUCT_GLINT)
