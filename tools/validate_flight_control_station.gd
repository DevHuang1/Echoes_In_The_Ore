extends SceneTree
## Run with --headless for geometry; append -- --render for overlap and screenshots.
const STATION := preload("res://scenes/ship/props/flight_control_station.tscn")
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error(message)

func _run() -> void:
	var station := STATION.instantiate()
	root.add_child(station)
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(station.SHEET.resource_path))
	_check(sheet.get_size() == Vector2i(1774, 887), "Unexpected sheet size")
	var coverage := Image.create(1774, 887, false, Image.FORMAT_L8)
	for region in station.REGIONS:
		coverage.fill_rect(Rect2i(region), Color.WHITE)
	for i in range(8):
		for j in range(i + 1, 8):
			_check(not station.REGIONS[i].intersects(station.REGIONS[j]), "Atlas crops overlap")
	var missing := 0
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			if sheet.get_pixel(x, y).a >= 8.0 / 255.0 and coverage.get_pixel(x, y).r == 0:
				missing += 1
	_check(missing == 0, "Atlas omitted visible pixels: %d" % missing)
	for state in range(2):
		for direction in range(4):
			station.state = state
			station.direction = direction
			var art := station.get_node("Sprite2D") as Sprite2D
			_check(art.texture.region == station.REGIONS[state * 4 + direction], "Wrong direction/state crop")
			_check(station.scale == Vector2.ONE and station.rotation == 0 and station.position == Vector2.ZERO, "Floor root changed")
			_check(art.rotation == 0 and art.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Artwork rotation/filter changed")
			_check(is_equal_approx(art.position.y + art.texture.region.size.y * art.scale.y, 9.6), "State floor anchor shifted")
			var expected := Vector2(52, 18) if direction < 2 else Vector2(28, 18)
			_check(station.get_node("StaticBody2D/CollisionShape2D").shape.size == expected, "Wrong floor footprint")
	station.direction = 1
	station.artwork_scale = 0.2
	_check(station.get_node("StaticBody2D/CollisionShape2D").shape.size == Vector2(52, 18), "Art scale affected collision")
	var other := STATION.instantiate()
	root.add_child(other)
	station.footprint_north_south_size = Vector2(60, 20)
	_check(other.get_node("StaticBody2D/CollisionShape2D").shape.size == Vector2(52, 18), "Instances share footprints")
	station.queue_free()
	other.queue_free()
	await process_frame
	var level := LEVEL.instantiate()
	root.add_child(level)
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	var props := level.get_node("BridgeRoomProps") as Node2D
	_check(props.position == Vector2(7, 12), "Bridge offset was lost")
	_check(props.get_node("UpperBowFlightConsole").position == Vector2(138, 282) and props.get_node("LowerBowFlightConsole").position == Vector2(134, 416), "Manual diagonal placement was lost")
	_check(props.get_node_or_null("NavigationConsole") == null, "Navigation console was not replaced")
	var floor_image := Image.load_from_file(ProjectSettings.globalize_path("res://art/overview/asteria_overview_floor.png"))
	for name in ["UpperFlightControlStation", "LowerFlightControlStation"]:
		var placed := props.get_node(name) as Node2D
		_check(placed.direction == (1 if name.begins_with("Upper") else 0) and placed.state == 0, "Wrong placed orientation/state")
		_check(placed.global_position == (Vector2(228, 277) if name.begins_with("Upper") else Vector2(228, 447)), "Wrong station position")
		_check(level.y_sort_enabled and props.y_sort_enabled and placed.z_index == player.z_index, "Shared sorting changed")
		for offset in [Vector2(-26, -9), Vector2(26, -9), Vector2(-26, 9), Vector2(26, 9)]:
			_check(floor_image.get_pixelv(Vector2i(placed.global_position + offset)).a > 0.15, "Station footprint is outside deck")
		player.position = placed.global_position - Vector2(0, 40)
		await physics_frame
		var hit := player.move_and_collide(Vector2(0, 60))
		_check(hit != null and hit.get_collider() == placed.get_node("StaticBody2D"), "Station does not block player")
	player.position = Vector2(180, 350)
	await physics_frame
	_check(player.move_and_collide(Vector2(150, 0)) == null, "Central route is blocked")
	if "--render" in OS.get_cmdline_user_args():
		await _render(level, player)
	print("FLIGHT CONTROL STATION VALIDATION: %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	for audio in root.find_children("*", "AudioStreamPlayer", true, false) + root.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.stream = null
	await create_timer(0.15).timeout
	level.queue_free()
	await process_frame
	await process_frame
	quit(0 if _failures == 0 else 1)

func _render(level: Node2D, player: CharacterBody2D) -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/flight_station_validation")
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
	for name in ["UpperFlightControlStation", "LowerFlightControlStation"]:
		var placed := level.get_node("BridgeRoomProps/" + name) as Node2D
		var point := placed.global_position + Vector2(0, -5)
		await process_frame
		await RenderingServer.frame_post_draw
		var sample := Vector2i(root.get_canvas_transform() * point)
		var baseline := root.get_texture().get_image().get_pixelv(sample)
		for side in [-1, 1]:
			player.position = placed.global_position + Vector2(0, side * 10)
			probe.show()
			await process_frame
			await RenderingServer.frame_post_draw
			var pixel := root.get_texture().get_image().get_pixelv(sample)
			var expected := baseline if side < 0 else Color.GREEN
			var error := maxf(absf(pixel.r - expected.r), maxf(absf(pixel.g - expected.g), absf(pixel.b - expected.b)))
			_check(error <= 3.0 / 255.0, "Rendered overlap failed for " + name)
		probe.hide()
	probe.queue_free()
	art.show()
	player.position = Vector2(250, 350)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/flight_station_validation/bridge_operational.png")
	for name in ["UpperFlightControlStation", "LowerFlightControlStation"]:
		level.get_node("BridgeRoomProps/" + name).state = 1
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/flight_station_validation/bridge_malfunctioning.png")
	camera.queue_free()
