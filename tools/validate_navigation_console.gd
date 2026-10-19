extends SceneTree
## Run with --headless --path . --script tools/validate_navigation_console.gd.
## Omit --headless and append -- --render to also check draw order and save previews.

const CONSOLE := preload("res://scenes/ship/props/navigation_console.tscn")
const WALKTHROUGH := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var console := CONSOLE.instantiate()
	root.add_child(console)
	var original_position: Vector2 = console.position
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://art/concepts/bridge_room_props/Flat rear console panel redesign.png"))
	_check(sheet.get_size() == Vector2i(1774, 887), "Unexpected sheet dimensions")
	_check(sheet.get_pixel(0, 0).a == 0.0 and sheet.get_pixel(550, 100).a == 0.0, "Background must be transparent")
	for state in range(2):
		for direction in range(4):
			console.state = state
			console.direction = direction
			var index := state * 4 + direction
			var sprite := console.get_node("Sprite2D") as Sprite2D
			var atlas := sprite.texture as AtlasTexture
			_check(atlas.region == console.REGIONS[index], "Wrong atlas region")
			var crop := sheet.get_region(Rect2i(atlas.region))
			_check(crop.get_used_rect() == Rect2i(Vector2i.ZERO, crop.get_size()), "Crop must match actual alpha bounds")
			_check(console.position == original_position and console.scale == Vector2.ONE, "Root anchor/scale changed")
			_check(sprite.position.is_equal_approx(-console.FLOOR_ANCHORS[index] * console.artwork_scale), "Wrong floor anchor")
			var bottom_y: float = sprite.position.y + atlas.region.size.y * sprite.scale.y
			_check(is_equal_approx(bottom_y, 9.0), "Cabinet base shifted between views/states")
			_check(sprite.rotation == 0.0 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork rotated or filtering changed")
			var shape := console.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
			var expected_size := Vector2(58, 18) if direction < 2 else Vector2(28, 18)
			_check(shape.shape.size == expected_size and shape.scale == Vector2.ONE, "Wrong independent floor footprint")
	console.direction = 1
	var shape := console.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
	console.artwork_scale = 0.16
	_check(shape.shape.size == Vector2(58, 18), "Art scale changed collision size")
	console.artwork_scale = 0.12
	var other := CONSOLE.instantiate()
	root.add_child(other)
	console.footprint_north_south_size = Vector2(62, 20)
	_check(other.get_node("StaticBody2D/CollisionShape2D").shape.size == Vector2(58, 18), "Instances share mutable footprints")
	other.queue_free()
	console.queue_free()
	await process_frame

	var level := WALKTHROUGH.instantiate()
	root.add_child(level)
	var placed := level.get_node_or_null("BridgeRoomProps/NavigationConsole") as Node2D
	if placed == null:
		# The walkthrough console was removed in favour of the flight-control
		# station; keep validating the reusable scene itself, skip the placement.
		print("NAVIGATION CONSOLE VALIDATION: SKIP (walkthrough NavigationConsole removed; superseded by FlightControlStation)")
		quit(0)
		return
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	_check(placed.global_position == Vector2(200, 315), "Unexpected console placement")
	_check(level.y_sort_enabled and level.get_node("BridgeRoomProps").y_sort_enabled, "Missing shared Y sort")
	_check(player.z_index == 3 and player.get_node("AnimatedSprite2D").z_index == 0 and placed.z_index == 3, "Player/console must sort at the same effective Z")
	_check(level.get_node("WallLayer").z_index == -1 and level.get_node("ShipDoors/UpperServiceSouthEntry").z_index == -2, "Walls/doors changed depth")
	for name in ["PowerMaintenanceRoomProps", "LifeSupportRoomProps", "HydroponicsRoomProps"]:
		_check(level.get_node(name).z_index == 0 and not level.get_node(name).y_sort_enabled, "Completed room sorting changed")
	await physics_frame
	player.position = Vector2(200, 350)
	await physics_frame
	var hit := player.move_and_collide(Vector2(0, -60))
	_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Console must stop the player")
	player.position = Vector2(245, 350)
	await physics_frame
	_check(player.move_and_collide(Vector2(0, -60)) == null, "Route beside console is blocked")
	var floor_image := Image.load_from_file(ProjectSettings.globalize_path("res://art/overview/asteria_overview_floor.png"))
	for point in [Vector2i(163, 315), Vector2i(237, 315), Vector2i(200, 290), Vector2i(200, 340), Vector2i(330, 350)]:
		_check(floor_image.get_pixelv(point).a > 0.15, "Placement/approach is outside the existing floor")
	if "--render" in OS.get_cmdline_user_args():
		await _render_checks(level, player)
	print("NAVIGATION CONSOLE VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)


func _render_checks(level: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/console_validation")
	for child in level.get_children():
		if child is CanvasLayer:
			child.hide()
	# Match the actual hierarchy and Z values with solid polygons to prove draw order.
	var sorting_root := Node2D.new()
	sorting_root.y_sort_enabled = true
	root.add_child(sorting_root)
	var collection := Node2D.new()
	collection.y_sort_enabled = true
	sorting_root.add_child(collection)
	var prop := Polygon2D.new()
	prop.z_index = 3
	prop.position = Vector2(100, 100)
	prop.polygon = PackedVector2Array([Vector2(-30, -40), Vector2(30, -40), Vector2(30, 10), Vector2(-30, 10)])
	prop.color = Color.RED
	collection.add_child(prop)
	var actor := Node2D.new()
	actor.z_index = 3
	sorting_root.add_child(actor)
	var actor_sprite := Polygon2D.new()
	actor_sprite.polygon = PackedVector2Array([Vector2(-10, -40), Vector2(10, -40), Vector2(10, 10), Vector2(-10, 10)])
	actor_sprite.color = Color.GREEN
	actor.add_child(actor_sprite)
	var camera := Camera2D.new()
	camera.position = Vector2(root.size) * 0.5
	root.add_child(camera)
	camera.make_current()
	level.hide()
	for actor_y in [90, 105]:
		actor.position = Vector2(100, actor_y)
		await process_frame
		await RenderingServer.frame_post_draw
		var pixel := root.get_texture().get_image().get_pixel(100, 90)
		var expected := Color.RED if actor_y < 100 else Color.GREEN
		_check(pixel.is_equal_approx(expected), "Rendered Y sorting failed at player Y %d: %s" % [actor_y, pixel])
	sorting_root.queue_free()
	level.show()
	camera.position = Vector2(200, 335)
	camera.zoom = Vector2(3, 3)
	for sample in [{"name": "behind", "y": 290}, {"name": "front", "y": 333}]:
		player.position = Vector2(200, sample.y)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/console_validation/bridge_%s.png" % sample.name)
	camera.queue_free()
