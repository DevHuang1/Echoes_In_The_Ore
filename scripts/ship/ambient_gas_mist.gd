extends Node2D

@export var cloud_texture: Texture2D
@export var gas_color := Color(0.35, 0.88, 1.0, 1.0)
@export_range(1, 48, 1) var blob_count := 16
@export var spread := Vector2(34.0, 18.0)
@export var drift_direction := Vector2(0.12, -1.0)
@export var drift_speed := 6.0
@export var lifetime := 7.0
@export var blob_size := Vector2(38.0, 28.0)
@export_range(0.0, 1.0) var opacity := 0.72

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	if cloud_texture == null or blob_count <= 0 or lifetime <= 0.0:
		return

	var direction := drift_direction.normalized()
	for index in range(blob_count):
		var index_f := float(index)
		var phase := fposmod(_elapsed / lifetime + index_f / float(blob_count), 1.0)
		var fade_in := smoothstep(0.0, 0.22, phase)
		var fade_out := 1.0 - smoothstep(0.68, 1.0, phase)
		var fade := fade_in * fade_out
		var seed_x := _stable_unit(index, 1.0) - 0.5
		var seed_y := _stable_unit(index, 2.0) - 0.5
		var center := Vector2(seed_x * spread.x, seed_y * spread.y)
		center += direction * ((phase - 0.18) * drift_speed * lifetime)
		center += Vector2(sin(_elapsed * 0.68 + index_f * 1.9) * 3.8, cos(_elapsed * 0.52 + index_f * 1.3) * 2.4)

		var size_scale := lerpf(0.58, 1.42, phase) * lerpf(0.76, 1.24, _stable_unit(index, 3.0))
		var size := blob_size * size_scale
		var color := Color(gas_color.r, gas_color.g, gas_color.b, gas_color.a * opacity * fade)
		draw_texture_rect(cloud_texture, Rect2(center - size * 0.5, size), false, color)


func _stable_unit(index: int, salt: float) -> float:
	var value := sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return value - floor(value)
