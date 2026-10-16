extends SceneTree
## Run with a rendered window to audit the visual swap without saving game state.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const OLD_WALL := preload("res://art/overview/asteria_overview_walls_2x.png")
const NEW_WALL := preload("res://art/concepts/ship_walls_valkyrie.png")
const MANIFEST := "res://art/overview/floor_modules/floor_modules_manifest.json"
var _failures := 0
var _checks := 0
var _level: Node2D
var _player: ShipPlayer
var _floor: Sprite2D
var _wall: Sprite2D
var _old_image: Image
var _new_image: Image
var _doors: Array[Node] = []
var _report := {}

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error(message)

func _frames(count := 3) -> void:
	for i in range(count):
		await process_frame

func _old_visual() -> void:
	_wall.texture = OLD_WALL
	_wall.scale = Vector2(0.5, 0.5)
	_wall.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _new_visual() -> void:
	_wall.texture = NEW_WALL
	_wall.scale = Vector2.ONE
	_wall.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _structure() -> Array:
	var records := []
	for node in _level.find_children("*", "", true, false):
		if node is CollisionShape2D:
			records.append([str(_level.get_path_to(node)), str(node.global_transform), str(node.shape), node.disabled])
		elif node is CollisionPolygon2D:
			records.append([str(_level.get_path_to(node)), str(node.global_transform), str(node.polygon), node.disabled])
		elif node is Light2D:
			records.append([str(_level.get_path_to(node)), str(node.global_transform), str(node.color), node.energy, node.range_z_min, node.range_z_max, node.shadow_enabled])
		elif node is NavigationRegion2D:
			records.append([str(_level.get_path_to(node)), str(node.global_transform), node.enabled, node.navigation_layers])
		elif node is StaticBody2D:
			records.append([str(_level.get_path_to(node)), str(node.global_transform), node.collision_layer, node.collision_mask])
	for collection in ["BridgeRoomProps", "CrewLivingQuarterProps", "HydroponicsRoomProps", "PowerMaintenanceRoomProps", "LifeSupportRoomProps"]:
		for prop in _level.get_node(collection).get_children():
			if prop is Node2D:
				records.append([collection + "/" + str(prop.name), str(prop.transform)])
	return records

func _alpha(image: Image, point: Vector2) -> float:
	var pixel := Vector2i(point.floor())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= image.get_width() or pixel.y >= image.get_height():
		return 0.0
	return image.get_pixelv(pixel).a

func _door_gap(image: Image, point: Vector2) -> Array:
	var clear: Array = []
	var run_start := -1
	for x in range(floori(point.x) - 36, ceili(point.x) + 37):
		var open := _alpha(image, Vector2(x, point.y)) < 0.15
		if open and run_start < 0:
			run_start = x
		if run_start >= 0 and (not open or x == ceili(point.x) + 36):
			var end := x if open else x - 1
			clear.append([run_start, end, end - run_start + 1])
			run_start = -1
	return clear

func _probe_movement() -> Array:
	var results := []
	_player.set_physics_process(false)
	for door in _doors:
		door.set_physics_process(false)
		door.set("_is_open", true)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _player.get_node("CollisionShape2D").shape
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	for door in _doors:
		var center := _floor.to_local(door.global_position)
		var path_x := INF
		var y0 := floori(center.y) - 28
		var y1 := ceili(center.y) + 28
		for x in range(floori(center.x) - 22, ceili(center.x) + 23):
			var clear := true
			for y in range(y0, y1 + 1):
				var world := _floor.to_global(Vector2(x, y))
				query.transform = Transform2D(0, world)
				if not _player._is_body_over_floor(world) or not root.world_2d.direct_space_state.intersect_shape(query).is_empty():
					clear = false
					break
			if clear:
				path_x = x
				break
		var traversed := false
		if is_finite(path_x):
			_player.global_position = _floor.to_global(Vector2(path_x, y0))
			for y in range(y0, y1):
				_player._move_on_walkable_floor(Vector2.DOWN)
			var target := _floor.to_global(Vector2(path_x, y1))
			traversed = _player.global_position.distance_to(target) < 0.1
		results.append({"name": str(door.name), "has_straight_floor_path": is_finite(path_x), "traversed": traversed})
	return results

func _shot(name: String, point: Vector2, zoom: float) -> void:
	_player.set_physics_process(false)
	_player.global_position = _floor.to_global(point)
	_player.camera.zoom = Vector2(zoom, zoom)
	_player.call("_update_camera_limits")
	_player.camera.reset_smoothing()
	_player.camera.force_update_scroll()
	await _frames(6)
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://.godot/wall_validation/%s.png" % name)
	_check(result == OK, "Screenshot save failed")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/wall_validation")
	_level = LEVEL.instantiate()
	root.add_child(_level)
	_player = _level.get_node("Player")
	_floor = _level.get_node("FloorLayer")
	_wall = _level.get_node("WallLayer")
	_doors = get_nodes_in_group("ship_door")
	await _frames(8)
	_level.call("_on_arrival_briefing_dismissed")
	for child in _level.get_children():
		if child is CanvasLayer and child != _level.get("_walk_hud"):
			child.hide()
			child.set_process_input(false)
			child.set_process_unhandled_input(false)
			child.set_process_unhandled_key_input(false)
	_player.set_physics_process(false)
	_check(_wall.texture == NEW_WALL, "Wrong wall texture")
	_check(NEW_WALL.get_size() == Vector2(1774, 887), "Wall import reduced source resolution")
	_check(_wall.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Wall filtering must be nearest")
	_check(_wall.position == _floor.position and _wall.scale == Vector2.ONE and not _wall.centered, "Wall/floor origin or scale changed")
	_check(_wall.z_index == -1 and _floor.z_index == -2, "Wall/floor rendering order changed")
	_check(_player.get("_walkable_floor_origin") == _floor.global_position, "Movement mask origin changed")
	var import_settings := ConfigFile.new()
	_check(import_settings.load("res://art/concepts/ship_walls_valkyrie.png.import") == OK, "Wall import file missing")
	_check(import_settings.get_value("params", "compress/mode") == 0 and import_settings.get_value("params", "process/size_limit") == 0, "Wall import must be lossless and unlimited")
	_old_image = OLD_WALL.get_image()
	if _old_image.is_compressed():
		_old_image.decompress()
	_old_image.resize(1774, 887, Image.INTERPOLATE_NEAREST)
	_new_image = NEW_WALL.get_image()
	if _new_image.is_compressed():
		_new_image.decompress()
	_report["wall_origin"] = str(_wall.global_position)
	_report["doors"] = []
	for door in _doors:
		var point := _floor.to_local(door.global_position)
		var old_gap := _door_gap(_old_image, point)
		var new_gap := _door_gap(_new_image, point)
		_report.doors.append({"name": str(door.name), "floor_position": [point.x, point.y], "saved_opening_width": door.opening_width, "old_clear_runs": old_gap, "new_clear_runs": new_gap})
		_check(not new_gap.is_empty(), "New art fully covers door opening: " + str(door.name))
		# Check the actual automatic trigger and both blocking states.
		door.set_physics_process(false)
		_player.global_position = door.to_global(Vector2(0, -door.wall_depth * 0.5 - 12))
		door.set("_is_open", false)
		_check(door.blocks_position(door.global_position, 8), "Closed door no longer blocks")
		door.set_physics_process(true)
		await create_timer(0.35).timeout
		_check(door.get("_is_open") and not door.blocks_position(door.global_position, 8), "Door automatic opening failed")
		door.set_physics_process(false)
		door.set("_is_open", true)
	var original_player_position := _player.global_position
	var structure := _structure()
	_old_visual()
	_check(_structure() == structure, "Visual swap altered collision, navigation, light or prop data")
	var old_movement := _probe_movement()
	_player.global_position = original_player_position
	_new_visual()
	_check(_structure() == structure, "Restoring wall visual altered gameplay data")
	var new_movement := _probe_movement()
	_check(old_movement == new_movement, "Wall replacement changed doorway movement")
	_report["movement"] = new_movement
	print("Doorway movement comparison: ", JSON.stringify(new_movement))

	# Recess entrance is not a pressure door; validate its saved collider gap.
	_player.global_position = _floor.to_global(Vector2(862, 342))
	for step in range(56):
		_player._move_on_walkable_floor(Vector2.DOWN)
	_report["recess_south_traversed"] = _player.global_position.distance_to(_floor.to_global(Vector2(862,398))) < 0.1
	_check(_report.recess_south_traversed, "Recess south entrance no longer traversable")

	# Actual movement input in three areas at the normal gameplay zoom.
	_report["walking"] = []
	for point in [Vector2(285,355), Vector2(950,540), Vector2(1500,400)]:
		_player.global_position = _floor.to_global(point)
		_player.set_physics_process(true)
		var start := _player.global_position
		Input.action_press(&"move_right")
		await create_timer(0.16).timeout
		Input.action_release(&"move_right")
		_player.set_physics_process(false)
		var distance := _player.global_position.x - start.x
		_check(distance > 8.0, "Walking input blocked in room: " + str(point))
		_report.walking.append({"point": str(point), "distance": distance})

	var hud: WalkHud = _level.get("_walk_hud")
	for item in [["bridge", Vector2(230,350)], ["central_corridors", Vector2(1000,400)], ["engine_area", Vector2(1530,390)]]:
		hud.show()
		await _shot(item[0] + "_normal", item[1], 1.75)
		hud.hide()
		await _shot(item[0] + "_close", item[1], 3.0)
		_old_visual()
		await _shot(item[0] + "_old_close", item[1], 3.0)
		_new_visual()
	# These camera targets are outside the walkable deck; hide the test actor
	# rather than showing a diagnostic teleport onto the engine casing.
	_player.hide()
	for item in [["upper_engine", Vector2(1650,168)], ["lower_engine", Vector2(1655,576)]]:
		await _shot(item[0] + "_normal", item[1], 1.75)
		await _shot(item[0] + "_close", item[1], 3.0)
	_player.show()
	# Record every room boundary at a useful inspection zoom.
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for room in manifest.modules:
		if room.kind != "room_floor":
			continue
		var center := Vector2(room.origin[0], room.origin[1]) + Vector2(room.size[0], room.size[1]) * 0.5
		await _shot("room_" + str(room.id), center, 2.0)
	# Whole-deck overview with floor and existing furnishings untouched.
	await _shot("whole_ship", Vector2(887,443.5), 0.7)
	var out := FileAccess.open("res://.godot/wall_validation/report.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(_report, "\t"))
	out.close()
	_level.queue_free()
	await _frames(4)
	print("WALL VISUAL VALIDATION: %s (%d checks, %d failures; %d saved doors)" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures, _doors.size()])
	quit(0 if _failures == 0 else 1)

