extends SceneTree
## Focused collision check for the Hydroponics wall bands and open service aisle.

const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)


func _blocked_at(space: PhysicsDirectSpaceState2D, player: CharacterBody2D, point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 1
	return not space.intersect_shape(query).is_empty()


func _run() -> void:
	var level := LEVEL.instantiate() as Node2D
	root.add_child(level)
	await physics_frame
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var walls := level.get_node("HydroponicsRoomProps/WallCollision") as StaticBody2D
	var space := root.world_2d.direct_space_state
	for wall in walls.get_children():
		var shape := wall as CollisionShape2D
		_check(_blocked_at(space, player, shape.global_position), "Hydroponics wall is not solid: " + shape.name)
	var aisle := level.to_global(Vector2(320, 770))
	_check(not _blocked_at(space, player, aisle), "Hydroponics central aisle is blocked")
	for prop_name in [&"ControlConsole", &"NutrientPump"]:
		var prop := level.get_node("HydroponicsRoomProps/" + str(prop_name)) as AnimatedSprite2D
		_check(player.call("_is_body_over_floor", prop.global_position), "Equipment is not fully over the interior floor: " + str(prop_name))
		var prop_body := prop.get_node("PropCollision") as StaticBody2D
		var prop_shape := prop_body.get_node("VisibleFootprint") as CollisionShape2D
		var prop_query := PhysicsShapeQueryParameters2D.new()
		prop_query.shape = prop_shape.shape
		prop_query.transform = prop_shape.global_transform
		prop_query.collision_mask = 1
		prop_query.exclude = [prop_body.get_rid()]
		var overlaps := space.intersect_shape(prop_query)
		if not overlaps.is_empty():
			var collider_paths: Array[String] = []
			for hit in overlaps:
				collider_paths.append(str(hit.collider.get_path()))
			print("Equipment overlap %s: %s" % [prop_name, collider_paths])
		_check(overlaps.is_empty(), "Equipment overlaps a wall or solid prop: " + str(prop_name))
	player.global_position = level.to_global(Vector2(500, 800))
	await physics_frame
	var hit := player.move_and_collide(Vector2.UP * 200.0)
	_check(hit != null and hit.get_collider() == walls, "Player can cross the Hydroponics top wall")
	player.global_position = level.to_global(Vector2(320, 780))
	await physics_frame
	var bottom_hit := player.move_and_collide(Vector2.DOWN * 60.0)
	_check(bottom_hit != null and bottom_hit.get_collider() == walls, "Player can walk onto the Hydroponics bottom wall")
	player.global_position = level.to_global(Vector2(333, 670))
	await physics_frame
	var top_door_hit := player.move_and_collide(Vector2.UP * 50.0)
	_check(top_door_hit == null, "Hydroponics top door (LowerDeckWestEntry2) is blocked by wall collision")
	for service_point in [Vector2(246, 760), Vector2(212, 780), Vector2(156, 734)]:
		var world_point := level.to_global(service_point)
		_check(not _blocked_at(space, player, world_point), "Hydroponics left-corner equipment access is blocked at " + str(service_point))
	print("HYDROPONICS WALL COLLISION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	level.queue_free()
	await process_frame
	quit(0 if _failures == 0 else 1)
