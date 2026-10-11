@tool
extends Node2D

const LONG_VENT := preload("res://art/props/floor_decals/floor_vent_long.png")
const JUNCTION_VENT := preload("res://art/props/floor_decals/floor_vent_square.png")

const LONG_SCALE := 0.04
const LONG_BODY_LENGTH := 1632.0
const LONG_TILE_LENGTH := LONG_BODY_LENGTH * LONG_SCALE
const JUNCTION_SCALE := 0.04

# Routes use the full overview floor's 1774x887 coordinate space.
var _routes: Array = [
	[Vector2(115, 390), Vector2(1610, 390)],
	[Vector2(240, 390), Vector2(240, 250)],
	[Vector2(650, 390), Vector2(650, 150), Vector2(1050, 150), Vector2(1050, 390)],
	[Vector2(520, 390), Vector2(520, 700), Vector2(980, 700)],
	[Vector2(520, 700), Vector2(480, 700), Vector2(480, 760)],
	[Vector2(870, 390), Vector2(870, 600), Vector2(1120, 600), Vector2(1120, 390)],
	[Vector2(1300, 390), Vector2(1300, 300), Vector2(1510, 300), Vector2(1510, 390)],
	[Vector2(1265, 390), Vector2(1265, 620), Vector2(1350, 620), Vector2(1350, 750), Vector2(1500, 750)]
]

var _junctions: Array[Vector2] = [
	Vector2(115, 390),
	Vector2(1610, 390),
	Vector2(240, 390),
	Vector2(240, 250),
	Vector2(650, 390),
	Vector2(650, 150),
	Vector2(1050, 150),
	Vector2(1050, 390),
	Vector2(520, 390),
	Vector2(520, 700),
	Vector2(980, 700),
	Vector2(480, 700),
	Vector2(480, 760),
	Vector2(870, 390),
	Vector2(870, 600),
	Vector2(1120, 600),
	Vector2(1120, 390),
	Vector2(1300, 390),
	Vector2(1300, 300),
	Vector2(1510, 300),
	Vector2(1510, 390),
	Vector2(1265, 390),
	Vector2(1265, 620),
	Vector2(1350, 620),
	Vector2(1350, 750),
	Vector2(1500, 750),
]


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var long_texture_size := Vector2(LONG_VENT.get_size())
	for route in _routes:
		for segment_index in range(route.size() - 1):
			var start: Vector2 = route[segment_index]
			var end: Vector2 = route[segment_index + 1]
			var delta := end - start
			var segment_length := delta.length()
			if is_zero_approx(segment_length):
				continue

			var tile_count := maxi(1, roundi(segment_length / LONG_TILE_LENGTH))
			var tile_length := segment_length / float(tile_count)
			var direction := delta / segment_length
			var scale_along_vent := tile_length / LONG_BODY_LENGTH
			for tile_index in range(tile_count):
				var center := start + direction * (tile_length * (tile_index + 0.5))
				draw_set_transform(center, direction.angle(), Vector2(scale_along_vent, LONG_SCALE))
				draw_texture(LONG_VENT, -long_texture_size * 0.5)

	var junction_texture_size := Vector2(JUNCTION_VENT.get_size())
	for junction in _junctions:
		draw_set_transform(junction, 0.0, Vector2(JUNCTION_SCALE, JUNCTION_SCALE))
		draw_texture(JUNCTION_VENT, -junction_texture_size * 0.5)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
