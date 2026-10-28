class_name ResonanceOreVillain
extends CharacterBody2D

signal rampage_station_hit(station_index: int)
signal rampage_finished
signal villain_repelled(tool_id: StringName)
signal transformed_stage2
signal transformed_final_form

enum FormStage { LIQUID, STAGE1_INFECTED, STAGE2_MUTATED, STAGE3_FINAL_FORM }

const LIQUID_ATLAS_PATH := "res://art/characters/runtime/echo_liquid_walk_4dir.png"
const FUSED_ATLAS_PATH := "res://art/characters/runtime/echo_amara_fused_walk_4dir.png"
const MUTATED_ATLAS_PATH := "res://art/characters/runtime/echo_amara_mutated_walk_4dir.png"
const FINAL_FORM_ATLAS_PATH := "res://art/characters/runtime/echo_amara_final_form_walk_4dir.png"
const WARM_LIGHT_SCENE := preload("res://scenes/ship/props/warm_ship_light.tscn")
const FLOOR_ALPHA_THRESHOLD := 0.15
const NAV_CELL_SIZE := 24.0
const BODY_RADIUS := 7.0
const DISPLAY_SCALE := 0.125
const LIQUID_DISPLAY_SCALE := 0.115

const DISTORTED_WHISPERS: Array[String] = [
	"\"Thura... I can hear the hydroponics humming... but my fingers won't move...\"",
	"\"The ore... it has such a clear resonance... don't fight it...\"",
	"\"Where did the crew go, Thura? I have something to show them...\"",
	"\"It's so cold inside the ducts... Thura, please open the hatch...\"",
	"\"Ward was looking for me in Med Bay... why was he running...?\"",
	"\"Biological containment... compromised... run, Thura... RUN—\""
]

const LAB_AREA := Rect2(Vector2(760.0, 465.0), Vector2(390.0, 155.0))
const SHIP_ROAM_AREAS := [
	Rect2(Vector2(760.0, 465.0), Vector2(390.0, 155.0)),
	Rect2(Vector2(585.0, 35.0), Vector2(545.0, 255.0)),
	Rect2(Vector2(575.0, 420.0), Vector2(610.0, 235.0)),
	Rect2(Vector2(1170.0, 185.0), Vector2(560.0, 520.0)),
]
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_right": 1,
	&"walk_left": 2,
	&"walk_up": 3,
}

@export_range(30.0, 240.0, 1.0) var move_speed: float = 76.0
@export_range(40.0, 260.0, 1.0) var stalk_player_distance: float = 185.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var form_stage: FormStage = FormStage.LIQUID
var _random := RandomNumberGenerator.new()
var _floor_mask: Image
var _floor_origin := Vector2.ZERO
var _grid := AStarGrid2D.new()
var _grid_region := Rect2i()
var _navigation_ready := false
var _roam_cells: Array[Vector2i] = []
var _path: Array[Vector2] = []
var _path_index := 0
var _destination := Vector2.ZERO
var _has_destination := false
var _idle_remaining := 0.4
var _facing_animation: StringName = &"walk_down"
var _repath_timer := 0.0
var _pulse_time := 0.0
var _aura_light: PointLight2D
var _is_fused_form := false
var _is_repelled := false
var _repel_cooldown := 0.0
var _whisper_timer := 10.0
var _flicker_check_timer := 0.5

var _rampage_targets: Array[Vector2] = []
var _rampage_index := 0
var _in_rampage := false

func _ready() -> void:
	_random.randomize()
	if Engine.has_meta(&"resonance_ore_final_form") and bool(Engine.get_meta(&"resonance_ore_final_form")):
		form_stage = FormStage.STAGE3_FINAL_FORM
		_is_fused_form = true
	elif Engine.has_meta(&"resonance_ore_mutated_stage2") and bool(Engine.get_meta(&"resonance_ore_mutated_stage2")):
		form_stage = FormStage.STAGE2_MUTATED
		_is_fused_form = true
	elif Engine.has_meta(&"resonance_ore_fused_with_amara") and bool(Engine.get_meta(&"resonance_ore_fused_with_amara")):
		form_stage = FormStage.STAGE1_INFECTED
		_is_fused_form = true
	else:
		form_stage = FormStage.LIQUID
		_is_fused_form = false

	add_to_group("ship_crew")
	add_to_group("ship_villain")

	var atlas_to_use := LIQUID_ATLAS_PATH
	if form_stage == FormStage.STAGE3_FINAL_FORM:
		atlas_to_use = FINAL_FORM_ATLAS_PATH
		move_speed = 105.0
	elif form_stage == FormStage.STAGE2_MUTATED:
		atlas_to_use = MUTATED_ATLAS_PATH
		move_speed = 96.0
	elif form_stage == FormStage.STAGE1_INFECTED:
		atlas_to_use = FUSED_ATLAS_PATH
		move_speed = 88.0
	else:
		move_speed = 48.0

	_configure_sprite_animations(atlas_to_use)
	if not _is_fused_form:
		var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape != null and collision_shape.shape is CircleShape2D:
			collision_shape.shape = collision_shape.shape.duplicate()
			var liquid_shape := collision_shape.shape as CircleShape2D
			liquid_shape.radius = 4.0

	_build_aura_light()
	await get_tree().physics_frame
	_build_navigation()
	if not _navigation_ready and not _in_rampage:
		set_physics_process(false)
		return
	if not _in_rampage:
		var spawn_cell := _world_to_cell(global_position)
		if _grid_region.has_point(spawn_cell) and _grid.is_point_solid(spawn_cell):
			spawn_cell = _find_nearest_clear_cell(spawn_cell)
			if _grid_region.has_point(spawn_cell) and not _grid.is_point_solid(spawn_cell):
				global_position = _cell_to_world(spawn_cell)
		_choose_next_destination()


func start_lab_rampage(targets: Array[Vector2]) -> void:
	_rampage_targets = targets.duplicate()
	_rampage_index = 0
	_in_rampage = not _rampage_targets.is_empty()
	set_physics_process(true)


func fuse_with_amara() -> void:
	if _is_fused_form:
		return
	await get_tree().create_timer(2.8).timeout
	if not is_inside_tree():
		return
	_is_fused_form = true
	form_stage = FormStage.STAGE1_INFECTED
	Engine.set_meta(&"resonance_ore_fused_with_amara", true)
	Engine.set_meta(&"resonance_ore_sample_evolved", true)
	move_speed = 88.0
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var fused_shape := collision_shape.shape as CircleShape2D
		fused_shape.radius = BODY_RADIUS
	_configure_sprite_animations(FUSED_ATLAS_PATH)
	if is_instance_valid(_aura_light):
		_aura_light.color = Color(0.96, 0.34, 0.16, 1.0)


func mutate_to_stage2() -> void:
	form_stage = FormStage.STAGE2_MUTATED
	_is_fused_form = true
	Engine.set_meta(&"resonance_ore_mutated_stage2", true)
	move_speed = 96.0
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var mutated_shape := collision_shape.shape as CircleShape2D
		mutated_shape.radius = BODY_RADIUS + 1.5
	_configure_sprite_animations(MUTATED_ATLAS_PATH)
	if is_instance_valid(_aura_light):
		_aura_light.color = Color(0.72, 0.15, 0.98, 1.0)
		_aura_light.energy = 0.58
		_aura_light.texture_scale = 0.36
	transformed_stage2.emit()


func mutate_to_final_form() -> void:
	form_stage = FormStage.STAGE3_FINAL_FORM
	_is_fused_form = true
	Engine.set_meta(&"resonance_ore_final_form", true)
	move_speed = 105.0
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var final_shape := collision_shape.shape as CircleShape2D
		final_shape.radius = BODY_RADIUS + 3.0
	_configure_sprite_animations(FINAL_FORM_ATLAS_PATH)
	if is_instance_valid(sprite):
		sprite.scale = Vector2.ONE * (DISPLAY_SCALE * 1.18)
	if is_instance_valid(_aura_light):
		_aura_light.color = Color(0.85, 0.22, 1.0, 1.0)
		_aura_light.energy = 0.82
		_aura_light.texture_scale = 0.48
	transformed_final_form.emit()


func disappear_into_ducts() -> void:
	_in_rampage = false
	_has_destination = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	var fade := create_tween().set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.tween_property(self, "scale", Vector2.ONE * 0.18, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_aura_light):
		fade.tween_property(_aura_light, "energy", 0.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished
	if is_inside_tree():
		visible = false
		Engine.set_meta(&"echo_disappeared_into_ducts", true)


func emerge_from_ducts(at_position: Vector2) -> void:
	global_position = at_position
	visible = true
	modulate = Color.WHITE
	modulate.a = 0.0
	scale = Vector2.ONE * 0.22
	set_physics_process(true)
	_is_repelled = false
	_in_rampage = false
	_has_destination = false
	Engine.set_meta(&"echo_disappeared_into_ducts", false)
	var surge := create_tween().set_parallel(true)
	surge.tween_property(self, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE)
	surge.tween_property(self, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(_aura_light):
		var target_energy := 0.45 if form_stage == FormStage.STAGE2_MUTATED else 0.35
		surge.tween_property(_aura_light, "energy", target_energy, 0.65)
	await surge.finished
	_choose_next_destination()


func repel_with_tool(tool_id: StringName, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if _is_repelled or not visible:
		return
	_is_repelled = true
	_repel_cooldown = 26.0
	villain_repelled.emit(tool_id)

	# Violet screech reaction and particle burst
	if is_instance_valid(sprite):
		var flash := create_tween()
		flash.tween_property(sprite, "modulate", Color(2.8, 0.4, 3.2, 1.0), 0.14)
		flash.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	if is_instance_valid(_aura_light):
		_aura_light.energy = 1.6
		_aura_light.color = Color(0.9, 0.3, 1.0, 1.0)

	await get_tree().create_timer(0.38).timeout
	await disappear_into_ducts()


func _physics_process(delta: float) -> void:
	_pulse_time += delta
	if is_instance_valid(_aura_light):
		var base_e := 0.42 if _in_rampage else (0.35 if form_stage == FormStage.STAGE2_MUTATED else 0.28)
		_aura_light.energy = base_e + 0.12 * sin(_pulse_time * (8.5 if _in_rampage else 4.2))

	if _is_repelled:
		_repel_cooldown = maxf(_repel_cooldown - delta, 0.0)
		if _repel_cooldown <= 0.0:
			_is_repelled = false

	if _in_rampage:
		_process_rampage(delta)
		return

	if not _navigation_ready or not visible:
		return

	if _repath_timer > 0.0:
		_repath_timer = maxf(_repath_timer - delta, 0.0)

	_check_player_stalking()
	_update_proximity_clues(delta)

	if _idle_remaining > 0.0:
		_idle_remaining = maxf(_idle_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		if not sprite.is_playing():
			sprite.play(_facing_animation)
		return

	if not _has_destination:
		_choose_next_destination()
		return

	if _path_index >= _path.size():
		_arrive_at_destination()
		return

	var waypoint := _path[_path_index]
	var to_waypoint := waypoint - global_position
	var distance := to_waypoint.length()
	if distance <= 2.5:
		_path_index += 1
		if _path_index >= _path.size():
			_arrive_at_destination()
		return

	var direction := to_waypoint / distance
	_update_facing(direction)
	var step_distance := minf(move_speed * delta, distance)
	var motion := direction * step_distance

	if _is_blocked_by_closed_door(global_position + motion):
		velocity = Vector2.ZERO
		_idle_remaining = 0.3
		return

	velocity = direction * move_speed
	var collision := move_and_collide(motion)
	if collision != null:
		_has_destination = false
		_idle_remaining = 0.35
	elif not sprite.is_playing():
		sprite.play(_facing_animation)


func _process_rampage(delta: float) -> void:
	if _rampage_index >= _rampage_targets.size():
		_in_rampage = false
		rampage_finished.emit()
		if _navigation_ready:
			_choose_next_destination()
		return

	var target := _rampage_targets[_rampage_index]
	var to_target := target - global_position
	var dist := to_target.length()
	var rampage_speed := 155.0
	if dist <= 6.0:
		global_position = target
		var strike_idx := _rampage_index
		_rampage_index += 1
		# Violent lunge and slash animation on impact.
		if is_instance_valid(sprite):
			sprite.scale = Vector2.ONE * (DISPLAY_SCALE * 1.24)
			var slash_tween := create_tween()
			slash_tween.tween_property(sprite, "scale", Vector2.ONE * DISPLAY_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rampage_station_hit.emit(strike_idx)
		return

	var dir := to_target / dist
	_update_facing(dir)
	global_position += dir * minf(rampage_speed * delta, dist)
	if not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_aura_light() -> void:
	_aura_light = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	_aura_light.color = Color(1.0, 0.38, 0.18, 1.0)
	_aura_light.energy = 0.32
	_aura_light.texture_scale = 0.28
	add_child(_aura_light)


func _check_player_stalking() -> void:
	if _in_rampage or _is_repelled or not visible:
		return
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	if not is_instance_valid(player):
		return

	# If player is concealed inside a locker or hiding spot, lose sight!
	if player.get("is_concealed") == true or player.is_in_group("concealed_players"):
		return

	var dist := global_position.distance_to(player.global_position)
	if dist <= stalk_player_distance:
		var dir := player.global_position - global_position
		if not dir.is_zero_approx():
			_update_facing(dir)
		if dist > 38.0 and _repath_timer <= 0.0:
			_repath_timer = 1.0
			var target_cell := _world_to_cell(player.global_position)
			if _grid_region.has_point(target_cell):
				if _grid.is_point_solid(target_cell):
					target_cell = _find_nearest_clear_cell(target_cell)
				_set_destination(target_cell)


func _update_proximity_clues(delta: float) -> void:
	if not visible or _is_repelled:
		return

	_flicker_check_timer -= delta
	if _flicker_check_timer <= 0.0:
		_flicker_check_timer = 0.6
		var room_lighting := get_tree().get_first_node_in_group("ship_room_lighting")
		if room_lighting == null and get_parent() != null:
			room_lighting = get_parent().get_node_or_null("ShipRoomLighting")
		if room_lighting != null and room_lighting.has_method("set_room_flicker"):
			# Determine nearby rooms based on position
			for room_id in [&"r07_mid_left", &"r08_central_bay", &"r09_shuttle_bay", &"r06_starboard_aft"]:
				if global_position.x < 650.0 and room_id == &"r07_mid_left":
					room_lighting.call("set_room_flicker", room_id, true)
				elif global_position.x >= 650.0 and global_position.x <= 1150.0 and room_id == &"r08_central_bay":
					room_lighting.call("set_room_flicker", room_id, true)
				elif global_position.x > 1150.0 and room_id == &"r09_shuttle_bay":
					room_lighting.call("set_room_flicker", room_id, true)

	if _is_fused_form:
		_whisper_timer -= delta
		if _whisper_timer <= 0.0:
			_whisper_timer = _random.randf_range(16.0, 28.0)
			var whisper: String = DISTORTED_WHISPERS[_random.randi_range(0, DISTORTED_WHISPERS.size() - 1)]
			var walk_hud := get_tree().get_first_node_in_group("walk_hud")
			if walk_hud == null and get_parent() != null:
				walk_hud = get_parent().get_node_or_null("WalkHud")
			if walk_hud != null and walk_hud.has_method("show_room_feedback"):
				walk_hud.call("show_room_feedback", "INTERCOM STATIC // DR. OKOYE:\n" + whisper, 5.0)


func _choose_next_destination() -> void:
	if _roam_cells.is_empty():
		_idle_remaining = 0.5
		return
	for _attempt in range(30):
		var target_cell: Vector2i = _roam_cells[_random.randi_range(0, _roam_cells.size() - 1)]
		if _grid.is_point_solid(target_cell):
			continue
		var target_pos := _cell_to_world(target_cell)
		if global_position.distance_to(target_pos) < 56.0:
			continue
		if _set_destination(target_cell):
			return
	_idle_remaining = 0.5


func _set_destination(target_cell: Vector2i) -> bool:
	if not _grid_region.has_point(target_cell) or _grid.is_point_solid(target_cell):
		return false
	var start_cell := _world_to_cell(global_position)
	if not _grid_region.has_point(start_cell):
		return false
	if _grid.is_point_solid(start_cell):
		start_cell = _find_nearest_clear_cell(start_cell)
		if not _grid_region.has_point(start_cell) or _grid.is_point_solid(start_cell):
			return false
	var id_path := _grid.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		return false
	_path.clear()
	for cell in id_path:
		if cell != start_cell:
			_path.append(_cell_to_world(cell))
	if _path.is_empty():
		return false
	_path_index = 0
	_destination = _cell_to_world(target_cell)
	_has_destination = true
	return true


func _find_nearest_clear_cell(origin: Vector2i) -> Vector2i:
	for radius in range(1, 6):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if absi(x) + absi(y) != radius:
					continue
				var candidate := origin + Vector2i(x, y)
				if _grid_region.has_point(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)


func _arrive_at_destination() -> void:
	_has_destination = false
	_path.clear()
	_path_index = 0
	velocity = Vector2.ZERO
	_idle_remaining = _random.randf_range(1.6, 3.2)


func _is_blocked_by_closed_door(position_to_check: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", position_to_check, BODY_RADIUS)):
			return true
	return false


func _position_is_walkable(world_position: Vector2) -> bool:
	var local_position := world_position - _floor_origin
	var pixel_x := floori(local_position.x)
	var pixel_y := floori(local_position.y)
	if pixel_x < 0 or pixel_y < 0 or pixel_x >= _floor_mask.get_width() or pixel_y >= _floor_mask.get_height():
		return false
	return _floor_mask.get_pixel(pixel_x, pixel_y).a >= FLOOR_ALPHA_THRESHOLD


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := world_position - _floor_origin
	return Vector2i(floori(local_position.x / NAV_CELL_SIZE), floori(local_position.y / NAV_CELL_SIZE))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return _floor_origin + Vector2((float(cell.x) + 0.5) * NAV_CELL_SIZE, (float(cell.y) + 0.5) * NAV_CELL_SIZE)


func _configure_sprite_animations(atlas_path: String) -> void:
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	var raw_img := Image.load_from_file(ProjectSettings.globalize_path(atlas_path))
	if raw_img == null or raw_img.is_empty():
		return
	var atlas_tex: Texture2D = ImageTexture.create_from_image(raw_img)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var cell_size := Vector2(float(atlas_tex.get_width()) / 4.0, float(atlas_tex.get_height()) / 4.0)
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 5.5)
		frames.set_animation_loop(animation_name, true)
		var row: int = ANIMATION_ROWS[animation_name]
		for column in range(4):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = atlas_tex
			atlas_frame.region = Rect2(Vector2(column * cell_size.x, row * cell_size.y), cell_size)
			frames.add_frame(animation_name, atlas_frame)
	sprite.sprite_frames = frames
	var target_scale := LIQUID_DISPLAY_SCALE
	if form_stage == FormStage.STAGE3_FINAL_FORM:
		target_scale = DISPLAY_SCALE * 1.18
	elif _is_fused_form:
		target_scale = DISPLAY_SCALE
	sprite.scale = Vector2.ONE * target_scale
	sprite.position = Vector2(0.0, -6.0 if _is_fused_form else -1.0)
	sprite.flip_h = false
	sprite.animation = _facing_animation
	sprite.play(_facing_animation)


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	sprite.flip_h = false
	if sprite.animation != _facing_animation or not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_navigation() -> void:
	var floor_layer := get_parent().get_node_or_null("FloorLayer") as Sprite2D
	if floor_layer == null or floor_layer.texture == null:
		return

	_floor_mask = floor_layer.texture.get_image()
	if _floor_mask.is_compressed() and _floor_mask.decompress() != OK:
		_floor_mask = null
		return
	_floor_origin = floor_layer.global_position

	var columns := ceili(float(_floor_mask.get_width()) / NAV_CELL_SIZE)
	var rows := ceili(float(_floor_mask.get_height()) / NAV_CELL_SIZE)
	_grid_region = Rect2i(Vector2i.ZERO, Vector2i(columns, rows))
	_grid.region = _grid_region
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.update()

	var clearance_samples: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(BODY_RADIUS, 0.0),
		Vector2(-BODY_RADIUS, 0.0),
		Vector2(0.0, BODY_RADIUS),
		Vector2(0.0, -BODY_RADIUS),
	]
	_roam_cells.clear()
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var clear := true
			for sample_offset in clearance_samples:
				if not _position_is_walkable(center + sample_offset):
					clear = false
					break
			if not clear:
				_grid.set_point_solid(cell, true)
				continue
			for area in SHIP_ROAM_AREAS:
				if (area as Rect2).has_point(center):
					_roam_cells.append(cell)
					break

	_navigation_ready = not _roam_cells.is_empty()
