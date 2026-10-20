extends SceneTree
## Use --headless for geometry checks; omit it and append -- --render for previews.

const CONSOLE := preload("res://scenes/ship/props/diagonal_flight_console.tscn")
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
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(console.SHEET.resource_path))
	_check(sheet.get_size() == Vector2i(1774, 887) and sheet.get_pixel(0, 0).a == 0, "Unexpected sheet size/transparency")
	# Low-alpha background specks exist. Every pixel at alpha >= 8 must belong
	# to exactly one measured crop; no visible sprite or neighboring view is cut.
	var covered := Image.create(1774, 887, false, Image.FORMAT_L8)
	for region in console.REGIONS:
		covered.fill_rect(Rect2i(region), Color.WHITE)
	for i in range(8):
		for j in range(i + 1, 8):
			_check(not console.REGIONS[i].intersects(console.REGIONS[j]), "Atlas views overlap")
	var missing_pixels := 0
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			if sheet.get_pixel(x, y).a >= 8.0 / 255.0 and covered.get_pixel(x, y).r == 0:
				missing_pixels += 1
	_check(missing_pixels == 0, "Visible pixels missing from atlas regions: %d" % missing_pixels)
	for state in range(2):
		for direction in range(4):
			console.state = state
			console.direction = direction
			var index := state * 4 + direction
			var sprite := console.get_node("Sprite2D") as Sprite2D
			_check(sprite.texture.region == console.REGIONS[index], "Wrong atlas crop")
			_check(sprite.texture.atlas == console.SHEET and sprite.texture.filter_clip, "Wrong sheet or atlas clipping")
			_check(is_equal_approx(sprite.texture.region.size.x * sprite.scale.x, console.REFERENCE_WIDTHS[direction] * console.artwork_scale), "Apparent width changed from the previous version")
			_check(sprite.position.is_equal_approx(-console.FLOOR_ANCHORS[index] * console.get_source_scale()), "Incorrect v2 floor anchor")
			_check(console.position == Vector2.ZERO and console.scale == Vector2.ONE and console.rotation == 0, "Root anchor/transform changed")
			_check(sprite.rotation == 0 and sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Rotated artwork or wrong filtering")
			_check(is_equal_approx(sprite.position.y + sprite.texture.region.size.y * sprite.scale.y, 18.7), "Base shifts between views/states")
			var collision := console.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
			_check(collision.shape is ConvexPolygonShape2D and collision.shape.points == console.get_footprint_points(), "Wrong diagonal footprint")
			await physics_frame
			var query := PhysicsPointQueryParameters2D.new()
			query.collision_mask = 1
			query.position = Vector2.ZERO
			_check(not root.world_2d.direct_space_state.intersect_point(query).is_empty(), "Cabinet center is not solid")
			var slope := 1.0 if direction in [0, 3] else -1.0
			query.position = Vector2(28, -16 * slope)
			_check(root.world_2d.direct_space_state.intersect_point(query).is_empty(), "Empty diagonal bounding-box corner is blocked")
	var original_points: PackedVector2Array = console.get_node("StaticBody2D/CollisionShape2D").shape.points
	console.artwork_scale = 0.2
	_check(console.get_node("StaticBody2D/CollisionShape2D").shape.points == original_points, "Art scaling changed collision")
	var other := CONSOLE.instantiate()
	root.add_child(other)
	console.footprint_length = 80
	console.footprint_offset = Vector2(4, 2)
	_check(console.get_node("StaticBody2D/CollisionShape2D").position == Vector2(4, 2), "Footprint offset ignored")
	_check(other.footprint_length == 60 and other.get_node("StaticBody2D/CollisionShape2D").shape != console.get_node("StaticBody2D/CollisionShape2D").shape, "Footprints are shared")
	console.queue_free()
	other.queue_free()
	await process_frame
	var level := WALKTHROUGH.instantiate()
	root.add_child(level)
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var floor_image := Image.load_from_file(ProjectSettings.globalize_path("res://art/overview/asteria_overview_floor.png"))
	for name in ["UpperBowFlightConsole", "LowerBowFlightConsole"]:
		var placed := level.get_node("BridgeRoomProps/" + name) as Node2D
		_check(placed.state == 0 and placed.direction == (2 if name.begins_with("Upper") else 0), "Wrong placed direction/state")
		_check(placed.z_index == player.z_index and level.y_sort_enabled and placed.get_parent().y_sort_enabled, "Shared sorting mismatch")
		for point in placed.get_footprint_points():
			_check(floor_image.get_pixelv(Vector2i(placed.global_position + point)).a > 0.15, "Footprint outside deck: " + name)
		player.position = placed.global_position + Vector2(0, 45)
		await physics_frame
		var hit := player.move_and_collide(Vector2(0, -60))
		_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Player not blocked by " + name)
	# The route through the bridge center and east opening remains clear.
	player.position = Vector2(270, 350)
	await physics_frame
	_check(player.move_and_collide(Vector2(-95, 0)) == null, "Central bridge route blocked")
	for point in [Vector2i(175, 350), Vector2i(270, 350), Vector2i(330, 350)]:
		_check(floor_image.get_pixelv(point).a > 0.15, "Central route outside floor")
	if "--render" in OS.get_cmdline_user_args():
		await _render_checks(level, player)
	print("DIAGONAL FLIGHT CONSOLE VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)


func _render_checks(level: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/diagonal_console_validation")
	for child in level.get_children():
		if child is CanvasLayer:
			child.hide()
	var camera := Camera2D.new()
	camera.position = Vector2(200, 335)
	camera.zoom = Vector2(3, 3)
	root.add_child(camera)
	camera.make_current()
	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	sprite.hide()
	var probe := Polygon2D.new()
	probe.color = Color.GREEN
	probe.polygon = PackedVector2Array([Vector2(-5, -40), Vector2(5, -40), Vector2(5, 20), Vector2(-5, 20)])
	player.add_child(probe)
	probe.hide()
	for name in ["UpperBowFlightConsole", "LowerBowFlightConsole"]:
		var placed := level.get_node("BridgeRoomProps/" + name) as Node2D
		var point := placed.global_position + Vector2(0, -5)
		var screen_point := Vector2i(root.get_canvas_transform() * point)
		await process_frame
		await RenderingServer.frame_post_draw
		screen_point = Vector2i(root.get_canvas_transform() * point)
		var baseline := root.get_texture().get_image().get_pixelv(screen_point)
		var art := placed.get_node("Sprite2D") as Sprite2D
		var texel := Vector2i(art.to_local(point) + art.texture.region.position)
		_check(placed.SHEET.get_image().get_pixelv(texel).a > 0.98, "Sorting sample misses opaque cabinet")
		for side in [-1, 1]:
			player.position = placed.global_position + Vector2(0, side * 10)
			probe.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixel := root.get_texture().get_image().get_pixelv(screen_point)
			# Most solid pixels have alpha 254. A hidden green probe can contribute
			# one or two 8-bit levels through them, unlike an incorrectly drawn actor.
			var expected := baseline if side < 0 else Color.GREEN
			var error := maxf(absf(pixel.r - expected.r), maxf(absf(pixel.g - expected.g), absf(pixel.b - expected.b)))
			_check(error <= 3.0 / 255.0, "Rendered player overlap failed for %s side %d: %s vs %s" % [name, side, pixel, expected])
		probe.hide()
	probe.queue_free()
	sprite.show()
	player.position = Vector2(240, 350)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/diagonal_console_validation/bridge_v2_operational.png")
	for name in ["UpperBowFlightConsole", "LowerBowFlightConsole"]:
		level.get_node("BridgeRoomProps/" + name).state = 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/diagonal_console_validation/bridge_v2_malfunctioning.png")
	for name in ["UpperBowFlightConsole", "LowerBowFlightConsole"]:
		level.get_node("BridgeRoomProps/" + name).state = 0
	for sample in [{"name": "upper_behind", "position": Vector2(132, 253)}, {"name": "upper_front", "position": Vector2(132, 298)}, {"name": "lower_behind", "position": Vector2(132, 380)}, {"name": "lower_front", "position": Vector2(132, 425)}]:
		player.position = sample.position
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/diagonal_console_validation/%s.png" % sample.name)
	camera.queue_free()
