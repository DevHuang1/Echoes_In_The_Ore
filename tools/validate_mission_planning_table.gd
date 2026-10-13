extends SceneTree
## Use --headless for geometry; append -- --render for sorting and screenshots.
const TABLE := preload("res://scenes/ship/props/mission_planning_table.tscn")
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var table := TABLE.instantiate()
	root.add_child(table)
	var image := Image.load_from_file(ProjectSettings.globalize_path(table.SHEET.resource_path))
	_check(image.get_size() == Vector2i(1774, 887) and image.get_pixel(0, 0).a == 0, "Unexpected table sheet/transparency")
	var coverage := Image.create(1774, 887, false, Image.FORMAT_L8)
	for i in range(8):
		coverage.fill_rect(Rect2i(table.REGIONS[i]), Color.WHITE)
		for j in range(i + 1, 8):
			_check(not table.REGIONS[i].intersects(table.REGIONS[j]), "Atlas crops overlap")
	var missing := 0
	for y in range(887):
		for x in range(1774):
			if image.get_pixel(x, y).a >= 8.0 / 255.0 and coverage.get_pixel(x, y).r == 0:
				missing += 1
	_check(missing == 0, "Visible pixels outside measured crops: %d" % missing)
	for state in range(2):
		for direction in range(4):
			table.state = state
			table.direction = direction
			var art := table.get_node("Sprite2D") as Sprite2D
			_check(art.texture.region == table.REGIONS[state * 4 + direction], "Wrong direction/state mapping")
			_check(art.rotation == 0 and not art.flip_h and not art.flip_v and art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork orientation/filter changed")
			_check(is_equal_approx(art.position.y + art.texture.region.size.y * art.scale.y, 9.1), "Base tip moved between states/views")
			var points: PackedVector2Array = table.get_footprint_points()
			for size in [0.1, 0.13, 0.16]:
				table.artwork_scale = size
				_check(art.to_global(table.FLOOR_ANCHORS[state * 4 + direction]).is_equal_approx(table.global_position), "Floor anchor moved when sized")
				_check(table.get_node("StaticBody2D/CollisionShape2D").shape.points == points, "Artwork scale changed collision")
			table.artwork_scale = 0.13
			_check(table.scale == Vector2.ONE and table.rotation == 0, "Root scaled/rotated")
	var other := TABLE.instantiate()
	root.add_child(other)
	table.direction = 0
	table.footprint_north_south_size = Vector2(60, 18)
	table.footprint_offset = Vector2(2, 1)
	_check(table.get_node("StaticBody2D/CollisionShape2D").position == Vector2(2, 1), "Footprint offset ignored")
	_check(other.footprint_north_south_size == Vector2(58, 16) and other.get_node("StaticBody2D/CollisionShape2D").shape != table.get_node("StaticBody2D/CollisionShape2D").shape, "Collision resources shared")
	table.queue_free()
	other.queue_free()
	await process_frame
	var level := LEVEL.instantiate()
	root.add_child(level)
	var props := level.get_node("BridgeRoomProps") as Node2D
	var placed := props.get_node("MissionPlanningTable") as Node2D
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var tables := 0
	var chairs := 0
	for child in props.get_children():
		if child.scene_file_path == TABLE.resource_path:
			tables += 1
		if child.scene_file_path == "res://scenes/ship/props/captain_chair.tscn":
			chairs += 1
	_check(tables == 1 and chairs == 3, "Table/chair instance counts changed")
	_check(placed.direction == 0 and placed.state == 0, "Wrong operational horizontal view")
	var art := placed.get_node("Sprite2D") as Sprite2D
	var visual_center := art.to_global(art.texture.region.size * 0.5)
	_check(visual_center.is_equal_approx(Vector2(221, 353)), "Visible center misses screenshot circle")
	_check(level.y_sort_enabled and props.y_sort_enabled and placed.z_index == player.z_index, "Sorting mismatch")
	await physics_frame
	var query := PhysicsShapeQueryParameters2D.new()
	var collision := placed.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = 1
	query.exclude = [placed.get_node("StaticBody2D").get_rid()]
	_check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Table overlaps existing furniture")
	for side in [-1, 1]:
		player.position = placed.global_position + Vector2(0, side * 35)
		await physics_frame
		var hit := player.move_and_collide(Vector2(0, -side * 45))
		_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Table not solid from both sides")
	# Full player clearance around all four edges, including nearby chairs.
	var offsets: Array[Vector2] = [Vector2(-39, -18), Vector2(39, -18), Vector2(39, 18), Vector2(-39, 18), Vector2(-39, -18)]
	player.position = placed.global_position + offsets[0]
	await physics_frame
	for i in range(1, offsets.size()):
		var target := placed.global_position + offsets[i]
		_check(player.call("_is_body_over_floor", target), "Walking route leaves deck")
		_check(player.move_and_collide(target - player.position) == null, "Walking route around table blocked")
		await physics_frame
	player.position = Vector2(270, 350)
	await physics_frame
	_check(player.move_and_collide(Vector2(60, 0)) == null, "Bridge entrance route blocked")
	if "--render" in OS.get_cmdline_user_args():
		await _render(level, placed, player)
	print("MISSION PLANNING TABLE VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)

func _render(level: Node2D, table: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/mission_table_validation")
	for child in level.get_children():
		if child is CanvasLayer:
			child.hide()
	var camera := Camera2D.new()
	camera.position = Vector2(200, 345)
	camera.zoom = Vector2(3, 3)
	root.add_child(camera)
	camera.make_current()
	var art := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	art.hide()
	var probe := Polygon2D.new()
	probe.color = Color.GREEN
	probe.polygon = PackedVector2Array([Vector2(-5, -40), Vector2(5, -40), Vector2(5, 20), Vector2(-5, 20)])
	player.add_child(probe)
	probe.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var sample := Vector2i(root.get_canvas_transform() * (table.global_position + Vector2(0, -5)))
	var baseline := root.get_texture().get_image().get_pixelv(sample)
	for side in [-1, 1]:
		player.position = table.global_position + Vector2(0, side * 10)
		probe.show()
		await process_frame
		await RenderingServer.frame_post_draw
		var pixel := root.get_texture().get_image().get_pixelv(sample)
		var expected := baseline if side < 0 else Color.GREEN
		var error := maxf(absf(pixel.r - expected.r), maxf(absf(pixel.g - expected.g), absf(pixel.b - expected.b)))
		_check(error <= 3.0 / 255.0, "Rendered player/table sorting failed")
	probe.queue_free()
	art.show()
	player.position = Vector2(280, 350)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/mission_table_validation/bridge_placement.png")
	table.state = 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/mission_table_validation/bridge_damaged.png")
	table.state = 0
	for side in [-1, 1]:
		player.position = table.global_position + Vector2(0, side * 17)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/mission_table_validation/player_%s.png" % ("behind" if side < 0 else "front"))
	camera.queue_free()
