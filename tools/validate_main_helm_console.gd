extends SceneTree
## Append -- --render (without --headless) for rendered sorting and screenshots.
const HELM := preload("res://scenes/ship/props/main_helm_console.tscn")
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var helm := HELM.instantiate()
	root.add_child(helm)
	var art := helm.get_node("Sprite2D") as Sprite2D
	var collision := helm.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(helm.ARTWORK.resource_path))
	_check(image.get_size() == Vector2i(1024, 1536), "Unexpected helm artwork")
	_check(art.rotation == 0 and not art.flip_h and not art.flip_v and art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork orientation/filter changed")
	var points: PackedVector2Array = helm.get_footprint_points()
	_check(collision.shape is ConvexPolygonShape2D and collision.shape.points == points, "Wrong chamfered footprint")
	# Every default footprint edge lies in solid cabinet pixels, never its halo.
	var soft_edge_samples := 0
	for i in range(points.size()):
		for step in range(21):
			var point := points[i].lerp(points[(i + 1) % points.size()], float(step) / 20.0)
			var texel := Vector2i(helm.FLOOR_ANCHOR + point / helm.artwork_scale)
			if image.get_pixelv(texel).a < 224.0 / 255.0:
				soft_edge_samples += 1
	_check(soft_edge_samples == 0, "Collision extends into halo/empty space")
	for size in [0.04, 0.058, 0.08]:
		helm.artwork_scale = size
		_check(art.to_global(helm.FLOOR_ANCHOR).is_equal_approx(helm.global_position), "Floor anchor moved with art scaling")
		_check(collision.shape.points == points and helm.scale == Vector2.ONE and helm.rotation == 0, "Art scaling changed floor geometry")
	var other := HELM.instantiate()
	root.add_child(other)
	helm.footprint_size = Vector2(30, 64)
	helm.footprint_offset = Vector2(2, 3)
	_check(collision.position == Vector2(2, 3), "Footprint offset ignored")
	_check(other.footprint_size == Vector2(28, 66) and other.get_node("StaticBody2D/CollisionShape2D").shape != collision.shape, "Instances share mutable collision")
	helm.footprint_corner_cut = 0
	_check(helm.get_footprint_points().size() == 4, "Zero bevel creates invalid polygon")
	helm.queue_free()
	other.queue_free()
	await process_frame
	var level := LEVEL.instantiate()
	root.add_child(level)
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var props := level.get_node("BridgeRoomProps") as Node2D
	var placed := props.get_node("MainHelmConsole") as Node2D
	var count := 0
	for child in props.get_children():
		if child.scene_file_path == HELM.resource_path:
			count += 1
	_check(count == 1, "Expected exactly one helm instance")
	_check(placed.global_position == Vector2(108, 347), "Incorrect placement including bridge offset")
	_check(props.position == Vector2(7, 12), "Bridge offset changed")
	var saved := {"UpperFlightControlStation": Vector2(220, 258), "UpperBowFlightConsole": Vector2(140, 274), "LowerBowFlightConsole": Vector2(136, 417), "LowerFlightControlStation": Vector2(218, 429)}
	for node_name in saved:
		_check(props.get_node(node_name).position == saved[node_name], "Saved prop placement lost: " + node_name)
	_check(level.y_sort_enabled and props.y_sort_enabled and placed.z_index == player.z_index, "Shared sorting mismatch")
	var floor_image := Image.load_from_file(ProjectSettings.globalize_path("res://art/overview/asteria_overview_floor.png"))
	for point in placed.get_footprint_points():
		_check(floor_image.get_pixelv(Vector2i(placed.global_position + point)).a > 0.15, "Footprint outside deck")
	await physics_frame
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = placed.get_node("StaticBody2D/CollisionShape2D").shape
	query.transform = placed.get_node("StaticBody2D/CollisionShape2D").global_transform
	query.collision_mask = 1
	query.exclude = [placed.get_node("StaticBody2D").get_rid()]
	_check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Helm overlaps another solid prop")
	player.position = placed.global_position + Vector2(55, 0)
	await physics_frame
	var hit := player.move_and_collide(Vector2(-70, 0))
	_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Helm is not solid")
	player.position = placed.global_position + Vector2(36, -20)
	await physics_frame
	_check(player.move_and_collide(Vector2(0, 40)) == null, "Right-side operator access is blocked")
	for offset in [Vector2(36, -20), Vector2(36, 0), Vector2(36, 20)]:
		_check(player.call("_is_body_over_floor", placed.global_position + offset), "Operator access lacks walkable deck clearance")
	player.position = Vector2(150, 347)
	await physics_frame
	_check(player.move_and_collide(Vector2(170, 0)) == null, "Central route blocked")
	if "--render" in OS.get_cmdline_user_args():
		await _render(level, placed, player)
	print("MAIN HELM VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)

func _render(level: Node2D, helm: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/main_helm_validation")
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
	var sample := Vector2i(root.get_canvas_transform() * (helm.global_position + Vector2(0, -5)))
	var baseline := root.get_texture().get_image().get_pixelv(sample)
	for side in [-1, 1]:
		player.position = helm.global_position + Vector2(0, side * 10)
		probe.show()
		await process_frame
		await RenderingServer.frame_post_draw
		var pixel := root.get_texture().get_image().get_pixelv(sample)
		var expected := baseline if side < 0 else Color.GREEN
		var error := maxf(absf(pixel.r - expected.r), maxf(absf(pixel.g - expected.g), absf(pixel.b - expected.b)))
		_check(error <= 3.0 / 255.0, "Rendered player/helm sorting failed")
	probe.queue_free()
	art.show()
	player.position = helm.global_position + Vector2(36, 0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/main_helm_validation/bridge_placement.png")
	var outline := Line2D.new()
	outline.points = helm.get_footprint_points()
	outline.closed = true
	outline.width = 0.5
	outline.default_color = Color(0.2, 1, 0.4)
	helm.add_child(outline)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/main_helm_validation/bridge_footprint.png")
	outline.queue_free()
	camera.queue_free()
