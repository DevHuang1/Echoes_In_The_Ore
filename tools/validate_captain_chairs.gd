extends SceneTree
## Append -- --render without --headless to check rendered sorting and save previews.
const CHAIR := preload("res://scenes/ship/props/captain_chair.tscn")
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var chair := CHAIR.instantiate()
	root.add_child(chair)
	var image := Image.load_from_file(ProjectSettings.globalize_path(chair.SHEET.resource_path))
	_check(image.get_size() == Vector2i(1536, 1024), "Unexpected chair sheet")
	var coverage := Image.create(1536, 510, false, Image.FORMAT_L8)
	for i in range(4):
		var region: Rect2 = chair.REGIONS[i]
		_check(region.end.y < 510, "Chair includes damaged row")
		coverage.fill_rect(Rect2i(region), Color.WHITE)
		for j in range(i + 1, 4):
			_check(not region.intersects(chair.REGIONS[j]), "Direction crops overlap")
	var missing := 0
	for y in range(510):
		for x in range(1536):
			if image.get_pixel(x, y).a >= 128.0 / 255.0 and coverage.get_pixel(x, y).r == 0:
				missing += 1
	_check(missing == 0, "Intact opaque chair pixels were clipped: %d" % missing)
	for direction in range(4):
		chair.direction = direction
		var art := chair.get_node("Sprite2D") as Sprite2D
		_check(art.texture.region == chair.REGIONS[direction] and art.texture.filter_clip, "Wrong directional atlas")
		_check(art.rotation == 0 and not art.flip_h and not art.flip_v and art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork rotated/flipped or wrong filter")
		for size in [0.05, 0.065, 0.08]:
			chair.artwork_scale = size
			_check(art.to_global(chair.FLOOR_ANCHORS[direction]).is_equal_approx(chair.global_position), "Pedestal anchor moved")
			_check(chair.scale == Vector2.ONE and chair.rotation == 0, "Root transform changed")
			_check(chair.get_node("StaticBody2D/CollisionShape2D").shape.points == chair.get_footprint_points(), "Footprint changed with artwork scale")
	var other := CHAIR.instantiate()
	root.add_child(other)
	chair.footprint_size = Vector2(18, 8)
	chair.footprint_offset = Vector2(2, 1)
	_check(chair.get_node("StaticBody2D/CollisionShape2D").position == Vector2(2, 1), "Footprint offset ignored")
	_check(other.footprint_size == Vector2(16, 6) and other.get_node("StaticBody2D/CollisionShape2D").shape != chair.get_node("StaticBody2D/CollisionShape2D").shape, "Instances share mutable footprint")
	chair.queue_free()
	other.queue_free()
	await process_frame
	var level := LEVEL.instantiate()
	root.add_child(level)
	var props := level.get_node("BridgeRoomProps") as Node2D
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var count := 0
	for child in props.get_children():
		if child.scene_file_path == CHAIR.resource_path:
			count += 1
	_check(count == 3, "Expected exactly three chairs")
	var directions := {"UpperStationChair": 0, "MainHelmChair": 3, "LowerStationChair": 1}
	await physics_frame
	for node_name in directions:
		var placed := props.get_node(node_name) as Node2D
		_check(placed.direction == directions[node_name], "Wrong chair facing: " + node_name)
		_check(placed.scale == Vector2.ONE and placed.rotation == 0, "Chair root is rotated/scaled")
		_check(placed.z_index == player.z_index and props.y_sort_enabled and level.y_sort_enabled, "Sorting mismatch")
		var collision := placed.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = collision.shape
		query.transform = collision.global_transform
		query.collision_mask = 1
		query.exclude = [placed.get_node("StaticBody2D").get_rid()]
		_check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Chair overlaps solid furniture: " + node_name)
		player.position = placed.global_position + Vector2(40, 0)
		await physics_frame
		var hit := player.move_and_collide(Vector2(-50, 0))
		_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Chair does not block player")
		# A full player-sized route around each pedestal, including console side.
		var offsets: Array[Vector2] = [Vector2(-18, -13), Vector2(18, -13), Vector2(18, 13), Vector2(-18, 13), Vector2(-18, -13)]
		player.position = placed.global_position + offsets[0]
		await physics_frame
		for i in range(1, offsets.size()):
			var target := placed.global_position + offsets[i]
			_check(player.call("_is_body_over_floor", target), "Chair approach leaves walkable deck")
			_check(player.move_and_collide(target - player.position) == null, "Walking route around chair blocked: " + node_name)
			await physics_frame
	player.position = Vector2(270, 350)
	await physics_frame
	_check(player.move_and_collide(Vector2(60, 0)) == null, "Bridge entrance route blocked")
	if "--render" in OS.get_cmdline_user_args():
		await _render(level, props, player, directions.keys())
	print("CAPTAIN CHAIRS VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)

func _render(level: Node2D, props: Node2D, player: CharacterBody2D, chair_names: Array) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/chair_validation")
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
	for node_name in chair_names:
		var placed := props.get_node(node_name) as Node2D
		await process_frame
		await RenderingServer.frame_post_draw
		var point := placed.global_position + Vector2(0, -5)
		var sample := Vector2i(root.get_canvas_transform() * point)
		var baseline := root.get_texture().get_image().get_pixelv(sample)
		var sprite := placed.get_node("Sprite2D") as Sprite2D
		var texel := Vector2i(sprite.to_local(point) + sprite.texture.region.position)
		_check(placed.SHEET.get_image().get_pixelv(texel).a > 0.98, "Sorting sample misses opaque chair")
		for side in [-1, 1]:
			player.position = placed.global_position + Vector2(0, side * 10)
			probe.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixel := root.get_texture().get_image().get_pixelv(sample)
			var expected := baseline if side < 0 else Color.GREEN
			var error := maxf(absf(pixel.r - expected.r), maxf(absf(pixel.g - expected.g), absf(pixel.b - expected.b)))
			_check(error <= 3.0 / 255.0, "Rendered sorting failed for " + node_name)
		probe.hide()
	probe.queue_free()
	art.show()
	player.position = Vector2(280, 350)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/chair_validation/bridge_chairs.png")
	camera.queue_free()
