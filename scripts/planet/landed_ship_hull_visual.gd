@tool
extends Node2D


func _draw() -> void:
	# Draw the landed Asteria-1 Valkyrie white exterior hull & boarding ramp around the huge airlock door
	var hull_rect := Rect2(-280.0, 22.0, 560.0, 170.0)
	# Outer dark hull shadow & bevel
	draw_rect(Rect2(-292.0, 14.0, 584.0, 184.0), Color(0.11, 0.12, 0.14, 0.98), true)
	# Main Valkyrie warm-white hull plating
	draw_rect(hull_rect, Color(0.86, 0.85, 0.82, 1.0), true)
	draw_rect(Rect2(-264.0, 34.0, 528.0, 140.0), Color(0.91, 0.90, 0.88, 1.0), true)
	# Hull panel seams & red Valkyrie stripe accents
	draw_rect(hull_rect, Color(0.20, 0.20, 0.22, 1.0), false, 3.0)
	draw_rect(Rect2(-250.0, 48.0, 140.0, 6.0), Color(0.84, 0.26, 0.23, 0.95), true)
	draw_rect(Rect2(110.0, 48.0, 140.0, 6.0), Color(0.84, 0.26, 0.23, 0.95), true)

	# Heavy boarding ramp extending north from the huge airlock door (y = -48..22)
	var ramp_pts := PackedVector2Array([
		Vector2(-68.0, 22.0),
		Vector2(68.0, 22.0),
		Vector2(54.0, -48.0),
		Vector2(-54.0, -48.0),
	])
	draw_colored_polygon(ramp_pts, Color(0.76, 0.75, 0.73, 0.98))
	draw_polyline(
		PackedVector2Array([Vector2(-68.0, 22.0), Vector2(-54.0, -48.0), Vector2(54.0, -48.0), Vector2(68.0, 22.0)]),
		Color(0.18, 0.19, 0.22, 1.0),
		2.5
	)
	for step_y in [-34.0, -20.0, -6.0, 8.0]:
		draw_line(Vector2(-50.0, step_y), Vector2(50.0, step_y), Color(0.45, 0.45, 0.47, 0.9), 2.0)
