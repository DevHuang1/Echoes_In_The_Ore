extends Node2D

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const ARRIVAL_BRIEFING_SCENE := preload("res://scenes/ui/arrival_briefing.tscn")

@export var player_spawn: Vector2 = Vector2(900.0, 500.0)

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var player: ShipPlayer = $Player


func _ready() -> void:
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)
	player.global_position = player_spawn
	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
	var arrival_briefing := ARRIVAL_BRIEFING_SCENE.instantiate()
	arrival_briefing.connect(&"dismissed", _on_arrival_briefing_dismissed)
	add_child(arrival_briefing)


func _on_arrival_briefing_dismissed() -> void:
	player.set_physics_process(true)
