extends Node2D

const FOG_ANCHORS := [
	Vector3(95.0, 165.0, 0.9), Vector3(198.0, 132.0, 0.9), Vector3(297.0, 105.0, 0.82),
	Vector3(390.0, 72.0, 0.82), Vector3(468.0, 112.0, 0.9), Vector3(555.0, 33.0, 0.86),
	Vector3(665.0, -3.0, 0.9), Vector3(785.0, -10.0, 1.0), Vector3(902.0, -12.0, 1.0),
	Vector3(1015.0, -8.0, 1.0), Vector3(1124.0, -1.0, 0.94), Vector3(1225.0, 10.0, 0.9),
	Vector3(1325.0, 34.0, 0.88), Vector3(1436.0, 65.0, 0.9), Vector3(1542.0, 88.0, 0.92),
	Vector3(1650.0, 104.0, 0.98), Vector3(1768.0, 166.0, 0.88), Vector3(1780.0, 280.0, 0.9),
	Vector3(1782.0, 390.0, 0.92), Vector3(1780.0, 512.0, 0.9), Vector3(1776.0, 624.0, 0.86),
	Vector3(1718.0, 720.0, 0.92), Vector3(1620.0, 798.0, 1.0), Vector3(1515.0, 850.0, 0.96),
	Vector3(1405.0, 881.0, 0.96), Vector3(1288.0, 891.0, 1.0), Vector3(1167.0, 894.0, 1.0),
	Vector3(1045.0, 894.0, 1.0), Vector3(922.0, 895.0, 1.0), Vector3(798.0, 894.0, 1.0),
	Vector3(674.0, 892.0, 1.0), Vector3(552.0, 889.0, 1.0), Vector3(430.0, 884.0, 0.98),
	Vector3(306.0, 878.0, 0.98), Vector3(192.0, 863.0, 0.92), Vector3(92.0, 824.0, 0.9),
	Vector3(7.0, 756.0, 0.9), Vector3(-8.0, 646.0, 0.88), Vector3(-14.0, 530.0, 0.92),
	Vector3(-15.0, 418.0, 0.92), Vector3(-12.0, 313.0, 0.9), Vector3(25.0, 235.0, 0.86),
]

const PALETTE := [
	Color(0.28, 0.66, 0.92, 1.0),
	Color(0.36, 0.48, 0.88, 1.0),
	Color(0.56, 0.42, 0.86, 1.0),
]

@export var cloud_texture: Texture2D
@export_range(0.0, 1.0) var opacity := 0.62
@export var cloud_size := Vector2(210.0, 148.0)

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if cloud_texture == null:
		return

	for index in range(FOG_ANCHORS.size()):
		var anchor: Vector3 = FOG_ANCHORS[index]
		var index_f := float(index)
		var sway := Vector2(sin(_elapsed * 0.12 + index_f * 1.7) * 8.0, cos(_elapsed * 0.1 + index_f * 1.3) * 6.0)
		var center := Vector2(anchor.x, anchor.y) + sway
		var scale_factor := anchor.z * (0.92 + 0.08 * sin(_elapsed * 0.17 + index_f))
		var size := cloud_size * scale_factor
		var palette_color: Color = PALETTE[index % PALETTE.size()]
		var alpha := opacity * (0.42 + 0.12 * sin(index_f * 2.1))
		var color := Color(palette_color.r, palette_color.g, palette_color.b, alpha)
		draw_texture_rect(cloud_texture, Rect2(center - size * 0.5, size), false, color)
