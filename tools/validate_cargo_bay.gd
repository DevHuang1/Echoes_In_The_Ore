extends Node
## MCP-compatible rendered walkthrough validation; no scene/game state is saved.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const PLAYER := preload("res://scenes/player/player.tscn")
const SKIN := preload("res://themes/ship_pixel_theme.tres")
var checks := 0
var failures := 0
var level: Node2D
var player: ShipPlayer
var floor_sprite: Sprite2D
var collection: Node2D
var query := PhysicsShapeQueryParameters2D.new()
var capture_view: SubViewport
var preview_root: Node2D
var preview_player: ShipPlayer
var caption: Label
var report := {}

func _ready() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _frames(count := 3) -> void:
	for i in range(count):
		await get_tree().process_frame

func _hits(point: Vector2) -> Array[Dictionary]:
	query.transform = Transform2D(0, floor_sprite.to_global(point))
	return get_viewport().world_2d.direct_space_state.intersect_shape(query, 64)

func _walkable(point: Vector2) -> bool:
	return player._is_body_over_floor(floor_sprite.to_global(point)) and _hits(point).is_empty()

func _check_routes() -> void:
	# Include the north doors, western dogleg and south entrance in one grid.
	var origin := Vector2(660,400)
	var width := 143
	var height := 74
	var valid := PackedByteArray()
	valid.resize(width * height)
	for y in range(height):
		for x in range(width):
			if _walkable(origin + Vector2(x,y) * 4):
				valid[y * width + x] = 1
	var start := Vector2i(60,35)
	var queue: Array[Vector2i] = [start]
	var seen := {start: start}
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + delta
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height or seen.has(neighbor):
				continue
			if valid[neighbor.y * width + neighbor.x] == 1:
				seen[neighbor] = cell
				queue.append(neighbor)
	var targets := {
		"Northwest door": Vector2(868,444),
		"Northeast door": Vector2(1120,444),
		"West dogleg": Vector2(752,516),
		"South entrance": Vector2(868,648),
		"Locker access": floor_sprite.to_local(collection.get_node("CargoLocker/AccessPoint").global_position),
		"Bundle access": floor_sprite.to_local(collection.get_node("TiedBoxBundle/AccessPoint").global_position),
		"Bundle hide space": floor_sprite.to_local(collection.get_node("TiedBoxBundle/HidePoint").global_position),
	}
	report.routes = {}
	for target in targets:
		var reachable := false
		var destination := start
		for cell in seen:
			if (origin + Vector2(cell) * 4).distance_to(targets[target]) <= 7:
				reachable = true
				destination = cell
				break
		_check(reachable, "No continuous player route to " + target)
		report.routes[target] = reachable
		if reachable:
			var path: Array[Vector2i] = [destination]
			while path[-1] != start:
				path.append(seen[path[-1]])
			path.reverse()
			player.global_position = floor_sprite.to_global(origin + Vector2(start) * 4)
			for cell in path:
				var desired := floor_sprite.to_global(origin + Vector2(cell) * 4)
				player._move_on_walkable_floor(desired - player.global_position)
			var goal := floor_sprite.to_global(origin + Vector2(destination) * 4)
			_check(player.global_position.distance_to(goal) < 0.5, "Player failed to walk route to " + target)
	print("Cargo clearance: ", JSON.stringify(report.routes))
	# Prop footprints stay outside the existing activation rectangles.
	for prop in collection.get_children():
		for body_shape in prop.get_node("StaticBody2D").get_children():
			if not body_shape is CollisionShape2D or body_shape.disabled:
				continue
			var extents: Rect2 = body_shape.shape.get_rect()
			for door in get_tree().get_nodes_in_group("ship_door"):
				var trigger := Rect2(-Vector2(door.opening_width,door.wall_depth)*0.5, Vector2(door.opening_width,door.wall_depth)).grow(door.activation_distance)
				var overlaps := false
				for corner in [extents.position, Vector2(extents.end.x,extents.position.y), extents.end, Vector2(extents.position.x,extents.end.y)]:
					if trigger.has_point(door.to_local(body_shape.to_global(corner))):
						overlaps = true
				_check(not overlaps, "Prop overlaps door trigger: " + str(prop.name))

func _preview_setup() -> void:
	capture_view = SubViewport.new()
	capture_view.size = Vector2i(320,440)
	capture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	capture_view.world_2d = World2D.new()
	add_child(capture_view)
	preview_root = Node2D.new()
	preview_root.y_sort_enabled = true
	capture_view.add_child(preview_root)
	var camera := Camera2D.new()
	camera.position = Vector2(0,-15)
	camera.zoom = Vector2(3,3)
	preview_root.add_child(camera)
	camera.make_current()
	preview_player = PLAYER.instantiate()
	preview_player.get_node("Camera2D").enabled = false
	preview_root.add_child(preview_player)
	preview_player.set_physics_process(false)
	preview_player.sprite.stop()
	preview_player.sprite.frame = 0
	preview_player.hide()
	var canvas := CanvasLayer.new()
	capture_view.add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(8,390)
	caption.theme = SKIN
	caption.add_theme_font_size_override("font_size",12)
	canvas.add_child(caption)

func _preview_image() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	return capture_view.get_texture().get_image()

func _validate_views(prop: Node2D) -> void:
	var preview := load(prop.scene_file_path).instantiate() as Node2D
	preview_root.add_child(preview)
	preview.position = Vector2.ZERO
	var gallery := Image.create(1280, 440 * maxi(preview.appearance_names.size(),1), false, Image.FORMAT_RGBA8)
	gallery.fill(Color(0.027,0.047,0.067))
	var variants := maxi(preview.appearance_names.size(),1)
	for variant in range(variants):
		preview.appearance = variant
		for direction in range(preview.view_names.size()):
			preview.direction = direction
			await _frames(2)
			var index: int = preview.get_view_index()
			var sprite := preview.get_node("Sprite2D") as Sprite2D
			var atlas := sprite.texture as AtlasTexture
			_check(atlas.region == preview.atlas_regions[index], "Wrong directional crop")
			_check(Rect2(Vector2.ZERO, preview.artwork.get_size()).encloses(atlas.region), "Crop outside sheet")
			_check(sprite.to_global(preview.floor_anchors[index]).is_equal_approx(preview.global_position), "Unstable floor anchor")
			_check(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and sprite.rotation == 0 and not sprite.flip_h and not sprite.flip_v, "Artwork rotated/flipped/filtered incorrectly")
			_check(preview.rotation == 0 and preview.scale == Vector2.ONE, "Prop root transformed")
			_check(preview.get_script().is_tool(), "Editor preview missing")
			var info := preview.get_property_list().filter(func(p: Dictionary): return p.name == "direction")
			if preview.view_names.size() > 1:
				_check(info[0].hint == PROPERTY_HINT_ENUM and info[0].hint_string == ",".join(preview.view_names), "Inspector direction labels missing")
			var variant_name: String = preview.appearance_names[variant] if variants > 1 else "Intact"
			caption.text = str(prop.name) + "\n" + preview.view_names[direction] + " / " + variant_name
			var picture := await _preview_image()
			gallery.blit_rect(picture, Rect2i(0,0,320,440), Vector2i(direction * 320,variant * 440))
			picture.save_png("res://.godot/cargo_validation/%s_%d_%d.png" % [prop.name,variant,direction])
	gallery.save_png("res://.godot/cargo_validation/%s_views.png" % prop.name)
	preview.direction = prop.direction
	preview.appearance = prop.appearance
	var main := preview.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
	var old_points := (main.shape as ConvexPolygonShape2D).points
	var old_scale: float = preview.artwork_scale
	preview.artwork_scale = old_scale * 1.1
	_check((main.shape as ConvexPolygonShape2D).points == old_points, "Artwork Scale changed collision geometry")
	preview.artwork_scale = old_scale
	# Pixel comparison verifies the real player renders completely over the
	# furniture when in front, but is occluded by it when behind.
	caption.hide()
	capture_view.transparent_bg = true
	var differences := []
	for in_front in [false,true]:
		preview.show()
		preview_player.show()
		var depth: float = preview.get_current_footprint_size().y
		preview_player.position = Vector2(0, depth * 0.5 + 9 if in_front else -depth * 0.5 - 9)
		var both := await _preview_image()
		preview.hide()
		var only_player := await _preview_image()
		preview_player.hide()
		var hidden_pixels := 0
		for y in range(440):
			for x in range(320):
				var actor_color := only_player.get_pixel(x,y)
				if actor_color.a < 0.98:
					continue
				var composite_color := both.get_pixel(x,y)
				var delta := Vector3(composite_color.r - actor_color.r, composite_color.g - actor_color.g, composite_color.b - actor_color.b)
				if delta.length() > 0.035:
					hidden_pixels += 1
		differences.append(hidden_pixels)
		both.save_png("res://.godot/cargo_validation/%s_%s.png" % [prop.name,"front" if in_front else "behind"])
	_check(differences[1] == 0, "Player not fully in front: " + str(prop.name))
	_check(differences[0] > 0, "Player not occluded behind: " + str(prop.name))
	report.sorting[prop.name] = differences
	caption.show()
	capture_view.transparent_bg = false
	preview.queue_free()
	await _frames(2)

func _capture_room(capture_name: String, zoom: float, show_hud: bool) -> void:
	var hud: WalkHud = level.get("_walk_hud")
	hud.visible = show_hud
	player.global_position = floor_sprite.to_global(Vector2(980,540))
	player.camera.zoom = Vector2(zoom,zoom)
	player.call("_update_camera_limits")
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	await _frames(6)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/cargo_validation/" + capture_name + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/cargo_validation")
	level = LEVEL.instantiate()
	add_child(level)
	player = level.get_node("Player")
	floor_sprite = level.get_node("FloorLayer")
	collection = level.get_node("CargoBayProps")
	await _frames(8)
	level.call("_on_arrival_briefing_dismissed")
	for child in level.get_children():
		if child is CanvasLayer and child != level.get("_walk_hud"):
			child.hide()
			child.set_process_input(false)
			child.set_process_unhandled_key_input(false)
	player.set_physics_process(false)
	for door in get_tree().get_nodes_in_group("ship_door"):
		door.set_physics_process(false)
		door.set("_is_open",true)
	query.shape = player.get_node("CollisionShape2D").shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	_check(collection.get_child_count() == 6, "Cargo props duplicated/missing")
	_check(collection.y_sort_enabled and level.y_sort_enabled and player.z_index == 3, "Shared sorting not configured")
	_check(level.is_editable_instance(collection), "Cargo children not editable in walkthrough")
	report.sorting = {}
	report.props = {}
	for prop in collection.get_children():
		_check(prop.z_index == player.z_index and prop.scale == Vector2.ONE and prop.rotation == 0, "Prop root/sorting convention changed")
		_check(prop.collision_enabled, "Initial prop collision disabled")
		var body := prop.get_node("StaticBody2D") as StaticBody2D
		_check(body.collision_layer == 1 and body.collision_mask == 0, "Collision layer convention changed")
		for collision in body.get_children():
			if not collision is CollisionShape2D or collision.disabled:
				continue
			var points: PackedVector2Array = collision.shape.points if collision.shape is ConvexPolygonShape2D else PackedVector2Array([Vector2.ZERO])
			var center := Vector2.ZERO
			for point in points:
				center += point
				var pixel := Vector2i(floor_sprite.to_local(collision.to_global(point)).floor())
				_check(player.get("_walkable_floor_mask").get_pixelv(pixel).a >= 0.15, "Footprint outside floor: " + str(prop.name))
			center /= points.size()
			var point := floor_sprite.to_local(collision.to_global(center))
			_check(_hits(point).any(func(hit: Dictionary): return hit.collider == body), "Solid footprint not detected")
		prop.collision_enabled = false
		await get_tree().physics_frame
		await _frames(2)
		_check(body.get_children().all(func(c: Node): return c.disabled), "Collision Enabled did not disable all footprint parts")
		prop.collision_enabled = true
		await get_tree().physics_frame
		await _frames(2)
		report.props[prop.name] = {"floor_position": str(floor_sprite.to_local(prop.global_position)), "direction": prop.view_names[prop.direction], "scale": prop.artwork_scale}
	_check_routes()
	await _capture_room("cargo_bay_gameplay",1.75,true)
	await _capture_room("cargo_bay_close",2.7,false)
	_preview_setup()
	for prop in collection.get_children():
		await _validate_views(prop)
	capture_view.queue_free()
	await _frames(3)
	report.checks = checks
	report.failures = failures
	var out := FileAccess.open("res://.godot/cargo_validation/report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"\t"))
	out.close()
	print("CARGO BAY VALIDATION: %s (%d checks, %d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
