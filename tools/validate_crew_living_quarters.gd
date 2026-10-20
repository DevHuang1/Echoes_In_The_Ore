extends SceneTree
## Use --headless for geometry, or append -- --render for sorting/screenshots.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const PROP_PATHS := ["stacked_capsule_bed", "personal_computer_desk", "blue_crew_chair", "communal_table_with_plant", "storage_cabinet", "three_drawer_chest"]
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var view_count := 0
	for prop_id in PROP_PATHS:
		var packed := load("res://scenes/ship/props/crew_quarters/%s.tscn" % prop_id) as PackedScene
		var prop := packed.instantiate()
		root.add_child(prop)
		_check(prop.get_script().is_tool(), "Missing editor preview: " + prop_id)
		_check(prop.view_names.size() == prop.atlas_regions.size() and prop.floor_anchors.size() == prop.atlas_regions.size(), "Inconsistent view definitions")
		var source := Image.load_from_file(ProjectSettings.globalize_path(prop.artwork.resource_path))
		_check(source.get_pixel(0, 0).a == 0, "Background is not transparent: " + prop_id)
		var coverage := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_L8)
		for i in range(prop.atlas_regions.size()):
			coverage.fill_rect(Rect2i(prop.atlas_regions[i]), Color.WHITE)
			for j in range(i + 1, prop.atlas_regions.size()):
				_check(not prop.atlas_regions[i].intersects(prop.atlas_regions[j]), "Atlas views overlap")
		var missing := 0
		for y in range(source.get_height()):
			for x in range(source.get_width()):
				if source.get_pixel(x, y).a >= 128.0 / 255.0 and coverage.get_pixel(x, y).r == 0:
					missing += 1
		_check(missing == 0, "Opaque pixels outside crops: %s (%d)" % [prop_id, missing])
		for entry in prop.get_property_list():
			if entry.name == "direction":
				_check(bool(entry.usage & PROPERTY_USAGE_EDITOR) == (prop.view_names.size() > 1), "Direction Inspector visibility incorrect")
				if prop.view_names.size() > 1:
					_check(entry.hint_string == ",".join(prop.view_names), "Wrong per-sheet direction labels")
		for i in range(prop.atlas_regions.size()):
			view_count += 1
			prop.direction = i
			var art := prop.get_node("Sprite2D") as Sprite2D
			_check(art.texture.region == prop.atlas_regions[i] and art.texture.filter_clip, "Wrong crop: " + prop_id)
			_check(art.rotation == 0 and not art.flip_h and not art.flip_v and art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork orientation/filter changed")
			var points: PackedVector2Array = prop.get_footprint_points()
			var default_scale: float = prop.artwork_scale
			for factor in [0.8, 1.2]:
				prop.artwork_scale = default_scale * factor
				_check(art.to_global(prop.floor_anchors[i]).is_equal_approx(prop.global_position), "Floor anchor moved")
				_check(prop.get_node("StaticBody2D/CollisionShape2D").shape.points == points, "Artwork scale changed collision")
			prop.artwork_scale = default_scale
			_check(prop.scale == Vector2.ONE and prop.rotation == 0, "Root transform changed")
		var other := packed.instantiate()
		root.add_child(other)
		prop.footprint_offset = Vector2(2, 1)
		_check(prop.get_node("StaticBody2D/CollisionShape2D").position == Vector2(2, 1), "Footprint offset ignored")
		_check(prop.get_node("StaticBody2D/CollisionShape2D").shape != other.get_node("StaticBody2D/CollisionShape2D").shape, "Mutable collision shared between instances")
		prop.queue_free()
		other.queue_free()
		await process_frame
	print("Checked %d artwork views across six props." % view_count)
	var level := LEVEL.instantiate()
	root.add_child(level)
	var props := level.get_node("CrewLivingQuarterProps") as Node2D
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	_check(props.get_child_count() == 17, "Incorrect furniture count")
	_check(level.is_editable_instance(props), "Room collection children are not editable in walkthrough")
	_check(level.y_sort_enabled and props.y_sort_enabled, "Missing shared Y-sorting")
	var bed := props.get_node("StackedCapsuleUnit") as Node2D
	_check(bed.view_names.size() == 1 and bed.find_children("*", "StaticBody2D", true, false).size() == 1 and bed.find_children("*", "CollisionShape2D", true, false).size() == 1, "Bed must remain one fixed-view prop with one shared footprint")
	await physics_frame
	for prop in props.get_children():
		_check(prop.z_index == player.z_index and prop.scale == Vector2.ONE and prop.rotation == 0, "Sorting/root transform mismatch")
		var collision := prop.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = collision.shape
		query.transform = collision.global_transform
		query.collision_mask = 1
		query.exclude = [prop.get_node("StaticBody2D").get_rid()]
		_check(root.world_2d.direct_space_state.intersect_shape(query).is_empty(), "Overlapping furniture: " + prop.name)
		# Approach an exposed edge; another chair may occupy a desk/table's front.
		var blocked_by_prop := false
		var player_query := PhysicsShapeQueryParameters2D.new()
		player_query.shape = player.get_node("CollisionShape2D").shape
		player_query.collision_mask = 1
		for approach in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()]:
			var half_size: Vector2 = prop.get_current_footprint_size() * 0.5
			var distance: float = absf(approach.x) * half_size.x + absf(approach.y) * half_size.y + 20
			var start: Vector2 = collision.global_position + approach * distance
			player_query.transform = Transform2D(0, start)
			if not player.call("_is_body_over_floor", start) or not root.world_2d.direct_space_state.intersect_shape(player_query).is_empty():
				continue
			player.position = start
			await physics_frame
			var hit := player.move_and_collide(-approach * 30)
			if hit != null and hit.get_collider() == prop.get_node("StaticBody2D"):
				blocked_by_prop = true
				break
		_check(blocked_by_prop, "Furniture is not solid from an exposed edge: " + prop.name)
	await _check_routes(player)
	if "--render" in OS.get_cmdline_user_args():
		await _render(level, props, player)
	print("CREW QUARTERS VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)

func _check_routes(player: CharacterBody2D) -> void:
	# Flood-fill using the actual player circle and alpha-mask movement rule.
	# Door staging points are inside the room, beyond the closed-door volumes.
	var origin := Vector2(300, 450)
	var extent := Vector2i(97, 52)
	var valid: Dictionary = {}
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.get_node("CollisionShape2D").shape
	query.collision_mask = 1
	await physics_frame
	for y in range(extent.y):
		for x in range(extent.x):
			var cell := Vector2i(x, y)
			var point := origin + Vector2(cell) * 4.0
			if not player.call("_is_body_over_floor", point):
				continue
			query.transform = Transform2D(0, point)
			if root.world_2d.direct_space_state.intersect_shape(query).is_empty():
				valid[cell] = true
	var start := Vector2i(57, 1) # (528,454), inside the north entry.
	_check(valid.has(start), "North entrance staging point is blocked")
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + delta
			if valid.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	var targets := {"Bed south access": Vector2(344,590), "Desk operator": Vector2(458,498), "Desk chair side": Vector2(482,513), "Table north": Vector2(485,550), "Table south": Vector2(485,596), "Table west": Vector2(446,578), "Table east": Vector2(524,578), "Cabinet doors": Vector2(568,515), "Drawer front": Vector2(398,504), "South exit staging": Vector2(335,620)}
	targets.merge({"Bed 02 south access": Vector2(391,630), "Bed 03 south access": Vector2(582,630), "Bed 04 south access": Vector2(630,630), "Cabinet 02 doors": Vector2(608,515), "Cabinet 03 doors": Vector2(348,489), "Cabinet 04 doors": Vector2(508,504), "Drawer 02 front": Vector2(427,535)})
	for label in targets:
		var delta: Vector2 = (targets[label] - origin) / 4.0
		var cell := Vector2i(roundi(delta.x), roundi(delta.y))
		if not reached.has(cell):
			query.transform = Transform2D(0, targets[label])
			var colliders: Array[String] = []
			for hit in root.world_2d.direct_space_state.intersect_shape(query):
				colliders.append(str(hit.collider.get_path()))
			print("Blocked access %s at %s: floor=%s colliders=%s" % [label, targets[label], player.call("_is_body_over_floor", targets[label]), colliders])
		_check(reached.has(cell), "No player-sized route to " + label)
	print("Player-circle flood fill reached %d floor cells and checked %d access points." % [reached.size(), targets.size()])

func _render(level: Node2D, props: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/crew_quarters_validation")
	for child in level.get_children():
		if child is CanvasLayer:
			child.hide()
	var camera := Camera2D.new()
	camera.position = Vector2(480, 530)
	camera.zoom = Vector2(2.45, 2.45)
	root.add_child(camera)
	camera.make_current()
	var player_art := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	player_art.hide()
	var probe := Polygon2D.new()
	probe.color = Color.GREEN
	probe.polygon = PackedVector2Array([Vector2(-5,-40), Vector2(5,-40), Vector2(5,20), Vector2(-5,20)])
	player.add_child(probe)
	probe.hide()
	for node_name in ["StackedCapsuleUnit", "PersonalComputerDesk", "DeskChair", "CommunalTable", "StorageCabinet", "ThreeDrawerChest"]:
		var prop := props.get_node(node_name) as Node2D
		var offset := Vector2(18,-5) if node_name == "PersonalComputerDesk" else Vector2(0,-5)
		var point := prop.global_position + offset
		await process_frame
		await RenderingServer.frame_post_draw
		var sample := Vector2i(root.get_canvas_transform() * point)
		var baseline := root.get_texture().get_image().get_pixelv(sample)
		var art := prop.get_node("Sprite2D") as Sprite2D
		var texel := Vector2i(art.to_local(point) + art.texture.region.position)
		_check(prop.artwork.get_image().get_pixelv(texel).a > 0.98, "Sorting sample is not opaque: " + node_name)
		for side in [-1,1]:
			player.position = prop.global_position + Vector2(offset.x, side * 10)
			probe.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixel := root.get_texture().get_image().get_pixelv(sample)
			var expected := baseline if side < 0 else Color.GREEN
			var error := maxf(absf(pixel.r-expected.r), maxf(absf(pixel.g-expected.g), absf(pixel.b-expected.b)))
			_check(error <= 3.0/255.0, "Rendered sorting failed: " + node_name)
		probe.hide()
	probe.queue_free()
	player_art.show()
	player.position = Vector2(530,538)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/crew_quarters_validation/furnished_quarters.png")
	for prop in props.get_children():
		var outline := Line2D.new()
		outline.points = prop.get_footprint_points()
		outline.position = prop.footprint_offset
		outline.closed = true
		outline.width = 0.5
		outline.default_color = Color(0.2,1,0.4)
		prop.add_child(outline)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/crew_quarters_validation/footprints.png")
	camera.queue_free()
