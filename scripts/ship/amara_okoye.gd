class_name AmaraOkoye
extends CharacterBody2D

const WALK_ATLAS := preload("res://art/characters/runtime/amara_walk_4dir.png")
const FLOOR_ALPHA_THRESHOLD := 0.15
const NAV_CELL_SIZE := 24.0
const BODY_RADIUS := 7.0
const DISPLAY_SCALE := 0.12
# Keep local patrols inside Hydroponics and out of the east access corridor.
const HYDROPONICS_AREA := Rect2(Vector2(60.0, 650.0), Vector2(420.0, 190.0))
const SHIP_ROAM_AREAS := [
	Rect2(Vector2(45.0, 205.0), Vector2(570.0, 270.0)),
	Rect2(Vector2(585.0, 35.0), Vector2(545.0, 255.0)),
	Rect2(Vector2(575.0, 420.0), Vector2(610.0, 235.0)),
	Rect2(Vector2(1170.0, 185.0), Vector2(560.0, 520.0)),
]
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

enum RoamPhase { HYDROPONICS, SHIP_EXCURSION, RETURNING }

@export_range(20.0, 240.0, 1.0) var move_speed: float = 170.0
@export var movement_burst_range := Vector2(0.84, 1.38)
@export var local_idle_seconds := Vector2(0.02, 0.08)
@export var ship_idle_seconds := Vector2(0.02, 0.08)
@export var room_roam_seconds := Vector2(20.0, 28.0)
@export var room_roam_stops := Vector2i(8, 12)
@export var excursion_stops := Vector2i(12, 20)
@export_range(30.0, 180.0, 1.0) var ship_excursion_max_seconds := 105.0
@export_range(40.0, 240.0, 1.0) var notice_player_distance: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _random := RandomNumberGenerator.new()
var _floor_mask: Image
var _floor_origin := Vector2.ZERO
var _grid := AStarGrid2D.new()
var _hydroponics_grid := AStarGrid2D.new()
var _grid_region := Rect2i()
var _navigation_ready := false
var _hydroponics_cells: Array[Vector2i] = []
var _ship_zone_cells: Array = []
var _path: Array[Vector2] = []
var _path_index := 0
var _destination := Vector2.ZERO
var _current_speed := 170.0
var _has_destination := false
var _idle_remaining := 0.0
var _phase := RoamPhase.HYDROPONICS
var _seconds_until_excursion := 0.0
var _excursion_seconds := 0.0
var _excursion_stops_remaining := 0
var _room_stops_remaining := 0
var _facing_animation: StringName = &"walk_down"


func _ready() -> void:
	_random.randomize()
	add_to_group("ship_crew")
	_configure_sprite_animations()
	await get_tree().physics_frame
	_build_navigation()
	if not _navigation_ready:
		set_physics_process(false)
		return
	var spawn_cell := _world_to_cell(global_position)
	if _grid_region.has_point(spawn_cell) and _hydroponics_grid.is_point_solid(spawn_cell):
		spawn_cell = _find_nearest_clear_cell(spawn_cell, true)
		if _grid_region.has_point(spawn_cell) and not _hydroponics_grid.is_point_solid(spawn_cell):
			global_position = _cell_to_world(spawn_cell)
	# Start with a lively hydroponics round before her longer ship excursion.
	_room_stops_remaining = _random.randi_range(room_roam_stops.x, room_roam_stops.y)
	_seconds_until_excursion = _random.randf_range(room_roam_seconds.x, room_roam_seconds.y)
	_choose_next_destination()


func _physics_process(delta: float) -> void:
	if not _navigation_ready:
		return
	if _phase == RoamPhase.HYDROPONICS:
		_seconds_until_excursion = maxf(_seconds_until_excursion - delta, 0.0)
	elif _phase == RoamPhase.SHIP_EXCURSION:
		_excursion_seconds += delta

	if _idle_remaining > 0.0:
		_idle_remaining = maxf(_idle_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		_stop_walking()
		_face_player_if_nearby()
		return

	if not _has_destination:
		_choose_next_destination()
		return
	if _path_index >= _path.size():
		_arrive_at_destination()
		return

	var waypoint := _path[_path_index]
	var to_waypoint := waypoint - global_position
	var distance := to_waypoint.length()
	if distance <= 1.5:
		_path_index += 1
		if _path_index >= _path.size():
			_arrive_at_destination()
		return

	var direction := to_waypoint / distance
	_update_facing(direction)
	var step_distance := minf(_current_speed * delta, distance)
	var motion := direction * step_distance
	if _is_blocked_by_closed_door(global_position + motion):
		velocity = Vector2.ZERO
		_stop_walking()
		_path.clear()
		_path_index = 0
		_has_destination = false
		_idle_remaining = 0.04
		return

	velocity = direction * _current_speed
	var collision := move_and_collide(motion)
	if collision != null:
		_handle_unmapped_obstacle()
	elif not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_navigation() -> void:
	var floor_layer := get_parent().get_node_or_null("FloorLayer") as Sprite2D
	if floor_layer == null or floor_layer.texture == null:
		push_warning("Amara could not find the ship floor for navigation.")
		return

	_floor_mask = floor_layer.texture.get_image()
	if _floor_mask.is_compressed() and _floor_mask.decompress() != OK:
		push_warning("Amara could not read the ship floor mask.")
		_floor_mask = null
		return
	_floor_origin = floor_layer.global_position

	var columns := ceili(float(_floor_mask.get_width()) / NAV_CELL_SIZE)
	var rows := ceili(float(_floor_mask.get_height()) / NAV_CELL_SIZE)
	_grid_region = Rect2i(Vector2i.ZERO, Vector2i(columns, rows))
	_grid.region = _grid_region
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.update()
	_hydroponics_grid.region = _grid_region
	_hydroponics_grid.cell_size = Vector2.ONE
	_hydroponics_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_hydroponics_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_hydroponics_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_hydroponics_grid.update()

	var clearance_samples: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(BODY_RADIUS, 0.0),
		Vector2(-BODY_RADIUS, 0.0),
		Vector2(0.0, BODY_RADIUS),
		Vector2(0.0, -BODY_RADIUS),
	]
	_ship_zone_cells.clear()
	for _zone in SHIP_ROAM_AREAS:
		_ship_zone_cells.append([])

	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var clear := true
			for sample_offset in clearance_samples:
				if not _position_is_walkable(center + sample_offset):
					clear = false
					break
			if not clear:
				_grid.set_point_solid(cell, true)
				_hydroponics_grid.set_point_solid(cell, true)
				continue
			if HYDROPONICS_AREA.has_point(center):
				_hydroponics_cells.append(cell)
			else:
				_hydroponics_grid.set_point_solid(cell, true)
			for zone_index in range(SHIP_ROAM_AREAS.size()):
				if SHIP_ROAM_AREAS[zone_index].has_point(center):
					var zone_cells: Array = _ship_zone_cells[zone_index]
					zone_cells.append(cell)

	_navigation_ready = not _hydroponics_cells.is_empty()
	if not _navigation_ready:
		push_warning("Amara could not find a clear hydroponics patrol route.")


func _choose_next_destination() -> void:
	var found_destination := false
	match _phase:
		RoamPhase.HYDROPONICS:
			if _seconds_until_excursion <= 0.0 or _room_stops_remaining <= 0:
				_phase = RoamPhase.SHIP_EXCURSION
				_excursion_seconds = 0.0
				_excursion_stops_remaining = _random.randi_range(excursion_stops.x, excursion_stops.y)
				found_destination = _choose_ship_destination()
				if not found_destination:
					_phase = RoamPhase.RETURNING
					found_destination = _choose_local_destination()
			else:
				found_destination = _choose_local_destination()
		RoamPhase.SHIP_EXCURSION:
			if _excursion_stops_remaining <= 0 or _excursion_seconds >= ship_excursion_max_seconds:
				_phase = RoamPhase.RETURNING
				found_destination = _choose_local_destination()
			else:
				found_destination = _choose_ship_destination()
		RoamPhase.RETURNING:
			found_destination = _choose_local_destination()

	if not found_destination:
		_idle_remaining = 0.08


func _choose_local_destination() -> bool:
	# Use the room-only path grid once she is home. A return trip still uses
	# the ship grid so she can travel back from an excursion.
	var local_only := _should_use_hydroponics_grid()
	return _choose_destination_from(_hydroponics_cells, 76.0, local_only)


func _choose_ship_destination() -> bool:
	for _attempt in range(10):
		var zone_index := _random.randi_range(0, _ship_zone_cells.size() - 1)
		var candidates: Array = _ship_zone_cells[zone_index]
		if _choose_destination_from(candidates, 120.0):
			return true
	return false


func _choose_destination_from(candidates: Array, minimum_distance: float, local_only: bool = false) -> bool:
	if candidates.is_empty():
		return false
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	var attempts := mini(40, candidates.size())
	for _attempt in range(attempts):
		var target_cell: Vector2i = candidates[_random.randi_range(0, candidates.size() - 1)]
		if navigation_grid.is_point_solid(target_cell):
			continue
		var target_position := _cell_to_world(target_cell)
		if global_position.distance_to(target_position) < minimum_distance:
			continue
		if _set_destination(target_cell, local_only):
			return true
	return false


func _set_destination(target_cell: Vector2i, local_only: bool = false) -> bool:
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	if not _grid_region.has_point(target_cell) or navigation_grid.is_point_solid(target_cell):
		return false
	var start_cell := _world_to_cell(global_position)
	if not _grid_region.has_point(start_cell):
		return false
	if navigation_grid.is_point_solid(start_cell):
		start_cell = _find_nearest_clear_cell(start_cell, local_only)
		if not _grid_region.has_point(start_cell) or navigation_grid.is_point_solid(start_cell):
			return false
	var id_path := navigation_grid.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		return false

	_path.clear()
	for cell in id_path:
		if cell != start_cell:
			_path.append(_cell_to_world(cell))
	if _path.is_empty():
		return false
	_path_index = 0
	_destination = _cell_to_world(target_cell)
	_current_speed = move_speed * _random.randf_range(movement_burst_range.x, movement_burst_range.y)
	_has_destination = true
	return true


func _find_nearest_clear_cell(origin: Vector2i, local_only: bool = false) -> Vector2i:
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	for radius in range(1, 5):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if absi(x) + absi(y) != radius:
					continue
				var candidate := origin + Vector2i(x, y)
				if _grid_region.has_point(candidate) and not navigation_grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)


func _should_use_hydroponics_grid() -> bool:
	return (
		_phase == RoamPhase.HYDROPONICS
		or (_phase == RoamPhase.RETURNING and HYDROPONICS_AREA.has_point(global_position))
	)


func _arrive_at_destination() -> void:
	_has_destination = false
	_path.clear()
	_path_index = 0
	velocity = Vector2.ZERO
	_stop_walking()
	if _phase == RoamPhase.HYDROPONICS:
		_room_stops_remaining -= 1
	elif _phase == RoamPhase.SHIP_EXCURSION:
		_excursion_stops_remaining -= 1
	elif _phase == RoamPhase.RETURNING:
		_phase = RoamPhase.HYDROPONICS
		_room_stops_remaining = _random.randi_range(room_roam_stops.x, room_roam_stops.y)
		_seconds_until_excursion = _random.randf_range(room_roam_seconds.x, room_roam_seconds.y)
	var idle_range := ship_idle_seconds if _phase == RoamPhase.SHIP_EXCURSION else local_idle_seconds
	_idle_remaining = _random.randf_range(idle_range.x, idle_range.y)


func _handle_unmapped_obstacle() -> void:
	velocity = Vector2.ZERO
	_stop_walking()
	if _path_index < _path.size():
		var blocked_cell := _world_to_cell(_path[_path_index])
		if _grid_region.has_point(blocked_cell):
			_grid.set_point_solid(blocked_cell, true)
			_hydroponics_grid.set_point_solid(blocked_cell, true)
	var target_cell := _world_to_cell(_destination)
	var local_only := _should_use_hydroponics_grid()
	if not _set_destination(target_cell, local_only):
		_has_destination = false
		_idle_remaining = 0.08


func _is_blocked_by_closed_door(position_to_check: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", position_to_check, BODY_RADIUS)):
			return true
	return false


func _position_is_walkable(world_position: Vector2) -> bool:
	var local_position := world_position - _floor_origin
	var pixel_x := floori(local_position.x)
	var pixel_y := floori(local_position.y)
	if pixel_x < 0 or pixel_y < 0 or pixel_x >= _floor_mask.get_width() or pixel_y >= _floor_mask.get_height():
		return false
	return _floor_mask.get_pixel(pixel_x, pixel_y).a >= FLOOR_ALPHA_THRESHOLD


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := world_position - _floor_origin
	return Vector2i(floori(local_position.x / NAV_CELL_SIZE), floori(local_position.y / NAV_CELL_SIZE))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return _floor_origin + Vector2((float(cell.x) + 0.5) * NAV_CELL_SIZE, (float(cell.y) + 0.5) * NAV_CELL_SIZE)


func _configure_sprite_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var cell_size := Vector2(float(WALK_ATLAS.get_width()) / 4.0, float(WALK_ATLAS.get_height()) / 4.0)
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 8.0)
		frames.set_animation_loop(animation_name, true)
		var row: int = ANIMATION_ROWS[animation_name]
		for column in range(4):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = WALK_ATLAS
			atlas_frame.region = Rect2(Vector2(column * cell_size.x, row * cell_size.y), cell_size)
			frames.add_frame(animation_name, atlas_frame)
	sprite.sprite_frames = frames
	# Match Thura's runtime sprite scale so both crew members read at the same size.
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.animation = _facing_animation
	sprite.stop()


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	if sprite.animation != _facing_animation:
		sprite.play(_facing_animation)


func _stop_walking() -> void:
	if sprite.is_playing():
		sprite.stop()
		sprite.frame = 0


func _face_player_if_nearby() -> void:
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	if not is_instance_valid(player) or global_position.distance_to(player.global_position) > notice_player_distance:
		return
	var direction := player.global_position - global_position
	if not direction.is_zero_approx():
		_update_facing(direction)
		_stop_walking()
