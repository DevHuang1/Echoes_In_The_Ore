@tool
extends Node2D
## Floor markings and surface conduits remain beneath props and characters.

func _draw() -> void:
	var amber := Color(0.74, 0.51, 0.20, 0.7)
	var steel := Color(0.12, 0.16, 0.18, 0.85)
	var cyan := Color(0.24, 0.69, 0.72, 0.65)
	draw_rect(Rect2(198, 55, 68, 49), steel)
	draw_rect(Rect2(198, 55, 68, 49), amber, false, 1.0)
	for x in range(200, 265, 8):
		draw_line(Vector2(x, 102), Vector2(x + 4, 97), amber, 2.0)
	# Power conduit hugs the north edge, away from the entrance and walking aisle.
	var cable := PackedVector2Array([Vector2(85, 20), Vector2(85, 10), Vector2(355, 10), Vector2(355, 72)])
	draw_polyline(cable, steel, 4.0)
	draw_polyline(cable, amber, 1.0)
	var feed := PackedVector2Array([Vector2(35, 123), Vector2(20, 123), Vector2(20, 153), Vector2(165, 153)])
	draw_polyline(feed, steel, 4.0)
	draw_polyline(feed, cyan, 1.0)
