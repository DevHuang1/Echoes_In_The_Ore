extends SceneTree
## -- --audit-only records the current discrepancy without changing the scene.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const MANIFEST := "res://art/overview/floor_modules/floor_modules_manifest.json"
var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _body_on_image(image: Image, point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(8,0), Vector2(-8,0), Vector2(0,8), Vector2(0,-8), Vector2(8,8) * 0.70710678, Vector2(8,-8) * 0.70710678, Vector2(-8,8) * 0.70710678, Vector2(-8,-8) * 0.70710678]:
		var sample := Vector2i((point + offset).floor())
		if sample.x < 0 or sample.y < 0 or sample.x >= image.get_width() or sample.y >= image.get_height() or image.get_pixelv(sample).a < 0.15:
			return false
	return true

func _run() -> void:
	var audit_only := "--audit-only" in OS.get_cmdline_user_args()
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var level := LEVEL.instantiate() as Node2D
	root.add_child(level)
	var player := level.get_node("Player") as CharacterBody2D
	player.set_physics_process(false)
	# Doors are opened only in memory to isolate floor-mask alignment from gates.
	for door in get_nodes_in_group("ship_door"):
		door.set_process(false)
		door.set("_is_open", true)
	await physics_frame
	var floor_sprite := level.get_node("FloorLayer") as Sprite2D
	var floor_image := floor_sprite.texture.get_image()
	if floor_image.is_compressed():
		floor_image.decompress()
	var origin: Vector2 = player.get("_walkable_floor_origin")
	print("Visible floor origin %s; movement-mask origin %s; displacement %s" % [floor_sprite.global_position, origin, origin - floor_sprite.global_position])
	var report := {"visible_origin": [floor_sprite.global_position.x, floor_sprite.global_position.y], "movement_origin": [origin.x, origin.y], "rooms": [], "false_block_examples": []}
	var total_wrong := 0
	var sample_count := 0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = player.get_node("CollisionShape2D").shape
	query.collision_mask = 1
	for room in manifest.modules:
		if room.kind != "room_floor":
			continue
		var blocked := 0
		var allowed := 0
		var example_count := 0
		var room_origin := Vector2(room.origin[0], room.origin[1])
		var room_size := Vector2(room.size[0], room.size[1])
		for y in range(int(room_origin.y), int(room_origin.y + room_size.y), 8):
			for x in range(int(room_origin.x), int(room_origin.x + room_size.x), 8):
				var point := Vector2(x, y)
				var world := floor_sprite.to_global(point)
				var expected := _body_on_image(floor_image, point)
				var actual: bool = player.call("_is_body_over_floor", world)
				sample_count += 1
				if expected and not actual:
					blocked += 1
					query.transform = Transform2D(0, world + Vector2.RIGHT)
					if example_count < 2 and _body_on_image(floor_image, point + Vector2.RIGHT) and root.world_2d.direct_space_state.intersect_shape(query).is_empty():
						report.false_block_examples.append({"room": room.id, "world": [world.x, world.y]})
						example_count += 1
				elif actual and not expected:
					allowed += 1
		var row := {"room": room.id, "label": room.label, "false_blocks": blocked, "false_allows": allowed}
		report.rooms.append(row)
		total_wrong += blocked + allowed
		print("%s %s: %d false blocks; %d false allows" % [room.id, room.label, blocked, allowed])
	report["samples"] = sample_count
	report["mismatches"] = total_wrong
	if not audit_only:
		_check_prop_anchors(level)
	var output_path := "res://.godot/floor_alignment_before.json" if audit_only else "res://.godot/floor_alignment_after.json"
	var output := FileAccess.open(output_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	if not audit_only:
		if total_wrong != 0 or not origin.is_equal_approx(floor_sprite.global_position):
			_failures += 1
			push_error("Player floor boundary does not match the rendered floor")
		if FileAccess.file_exists("res://.godot/floor_alignment_before.json"):
			var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/floor_alignment_before.json"))
			var moved := 0
			for example in before.false_block_examples:
				var point := Vector2(example.world[0], example.world[1])
				player.global_position = point
				player.call("_move_on_walkable_floor", Vector2.RIGHT)
				if player.global_position.is_equal_approx(point + Vector2.RIGHT):
					moved += 1
				else:
					_failures += 1
					push_error("Previously blocked clear-floor probe still fails: " + str(example))
			print("Movement succeeds at %d previously blocked, furniture-free probes." % moved)
	print("FLOOR ALIGNMENT %s: %d samples, %d mismatches" % ["AUDIT" if audit_only else "PASS" if _failures == 0 else "FAIL", sample_count, total_wrong])
	quit(0 if _failures == 0 else 1)

func _check_prop_anchors(level: Node2D) -> void:
	var count := 0
	for collection_name in ["BridgeRoomProps", "CrewLivingQuarterProps"]:
		for prop in level.get_node(collection_name).get_children():
			var sprite := prop.get_node("Sprite2D") as Sprite2D
			var collision := prop.get_node("StaticBody2D/CollisionShape2D") as CollisionShape2D
			var offset: Vector2 = prop.get("footprint_offset")
			var constants: Dictionary = prop.get_script().get_script_constant_map()
			var anchor: Vector2
			if constants.has("FLOOR_ANCHOR"):
				anchor = constants["FLOOR_ANCHOR"]
			elif constants.has("FLOOR_ANCHORS"):
				var index: int = prop.get("direction")
				if constants["FLOOR_ANCHORS"].size() > 4:
					index += int(prop.get("state")) * 4
				anchor = constants["FLOOR_ANCHORS"][index]
			else:
				anchor = prop.get("floor_anchors")[prop.get_view_index()]
			if not sprite.to_global(anchor).is_equal_approx(prop.global_position) or not collision.global_position.is_equal_approx(prop.to_global(offset)):
				_failures += 1
				push_error("Prop sprite/collider anchor mismatch: " + str(prop.get_path()))
			count += 1
	print("Checked sprite/collider floor-anchor alignment on %d saved bridge/quarters props." % count)
