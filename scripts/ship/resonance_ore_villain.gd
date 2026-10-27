class_name ResonanceOreVillain
extends CharacterBody2D

signal rampage_station_hit(station_index: int)
signal rampage_finished

const WALK_ATLAS_PATH := "res://art/characters/runtime/ore_monster_walk_4dir.png"
const WALK_ATLAS := preload("res://art/characters/runtime/ore_monster_walk_4dir.png")
const WARM_LIGHT_SCENE := preload("res://scenes/ship/props/warm_ship_light.tscn")
const FLOOR_ALPHA_THRESHOLD := 0.15
const NAV_CELL_SIZE := 24.0
const BODY_RADIUS := 7.0
const DISPLAY_SCALE := 0.165

const LAB_AREA := Rect2(Vector2(760.0, 465.0), Vector2(390.0, 155.0))
const SHIP_ROAM_AREAS := [
	Rect2(Vector2(760.0, 465.0), Vector2(390.0, 155.0)),
	Rect2(Vector2(585.0, 35.0), Vector2(545.0, 255.0)),
	Rect2(Vector2(575.0, 420.0), Vector2(610.0, 235.0)),
	Rect2(Vector2(1170.0, 185.0), Vector2(560.0, 520.0)),
]
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

const THREAT_BARKS: Array[Dictionary] = [
	{
		"tag": "CONTAINMENT BREACH",
		"barks": [
			"Chitinous silicate plates resonate with a low sub-harmonic hum...",
			"Golden bio-luminescent tendrils lash across the wrecked Lab deck.",
			"The xenomorph's obsidian visor locks onto nearby thermal signatures.",
		]
	},
	{
		"tag": "LAB DESTROYED",
		"barks": [
			"High-frequency acoustic spikes echo through the shattered lab consoles.",
			"Claws scrape against the hull plating, drawing ambient power from severed cables.",
			"Crystalline spores drift from the fractured ore shell.",
		]
	},
]

@export_range(30.0, 240.0, 1.0) var move_speed: float = 76.0
@export_range(40.0, 260.0, 1.0) var stalk_player_distance: float = 185.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

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
var _bark_cooldown := 4.0
var _repath_timer := 0.0
var _pulse_time := 0.0
var _aura_light: PointLight2D

var _rampage_targets: Array[Vector2] = []
var _rampage_index := 0
var _in_rampage := false

var _bubble_root: Node2D
var _bubble_panel: PanelContainer
var _bubble_tag_label: Label
var _bubble_text_label: Label
var _bubble_tween: Tween


func _ready() -> void:
	_random.randomize()
	add_to_group("ship_crew")
	add_to_group("ship_villain")
	_configure_sprite_animations()
	_build_aura_light()
	_build_overhead_bubble()
	_show_overhead_bark("XENOMORPH BREACH", "The Xenomorph shatters the bio-tank and rampages through the Lab!", 4.2)
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


func _physics_process(delta: float) -> void:
	_pulse_time += delta
	if is_instance_valid(_aura_light):
		var base_e := 0.42 if _in_rampage else 0.28
		_aura_light.energy = base_e + 0.12 * sin(_pulse_time * (8.5 if _in_rampage else 4.2))

	if _in_rampage:
		_process_rampage(delta)
		return

	if not _navigation_ready:
		return

	if _bark_cooldown > 0.0:
		_bark_cooldown = maxf(_bark_cooldown - delta, 0.0)
	if _repath_timer > 0.0:
		_repath_timer = maxf(_repath_timer - delta, 0.0)

	_check_player_stalking()

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
		_show_overhead_bark("LAB DESTROYED", "Every console and containment rack in the Lab lies in ruins!", 3.8)
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
		# Violent lunge & slash animation on impact
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


func _build_overhead_bubble() -> void:
	_bubble_root = Node2D.new()
	_bubble_root.name = "OverheadBubble"
	_bubble_root.position = Vector2(0.0, -42.0)
	_bubble_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_bubble_root.z_index = 10
	add_child(_bubble_root)

	_bubble_panel = PanelContainer.new()
	_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_panel.custom_minimum_size = Vector2(170.0, 0.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.015, 0.02, 0.92)
	style.border_color = Color(1.0, 0.42, 0.20, 0.92)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	_bubble_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_bubble_panel.add_child(vbox)

	_bubble_tag_label = Label.new()
	_bubble_tag_label.add_theme_font_size_override("font_size", 9)
	_bubble_tag_label.add_theme_color_override("font_color", Color(1.0, 0.56, 0.24))
	vbox.add_child(_bubble_tag_label)

	_bubble_text_label = Label.new()
	_bubble_text_label.add_theme_font_size_override("font_size", 11)
	_bubble_text_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.88))
	_bubble_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text_label.custom_minimum_size = Vector2(170.0, 0.0)
	vbox.add_child(_bubble_text_label)

	_bubble_root.add_child(_bubble_panel)
	_bubble_panel.position = Vector2(-95.0, -44.0)


func _show_overhead_bark(tag: String, text: String, duration: float = 2.8) -> void:
	if not is_instance_valid(_bubble_root):
		return
	_bubble_tag_label.text = "XENOMORPH  •  " + tag.to_upper()
	_bubble_text_label.text = text

	if is_instance_valid(_bubble_tween) and _bubble_tween.is_running():
		_bubble_tween.kill()

	_bubble_tween = create_tween()
	_bubble_tween.tween_property(_bubble_root, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bubble_tween.tween_interval(maxf(duration - 0.5, 1.2))
	_bubble_tween.tween_property(_bubble_root, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _check_player_stalking() -> void:
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	if not is_instance_valid(player):
		return

	var dist := global_position.distance_to(player.global_position)
	if dist <= stalk_player_distance:
		var dir := player.global_position - global_position
		if not dir.is_zero_approx():
			_update_facing(dir)
		if dist > 42.0 and _repath_timer <= 0.0:
			_repath_timer = 1.2
			var target_cell := _world_to_cell(player.global_position)
			if _grid_region.has_point(target_cell):
				if _grid.is_point_solid(target_cell):
					target_cell = _find_nearest_clear_cell(target_cell)
				_set_destination(target_cell)
		if _bark_cooldown <= 0.0:
			_bark_cooldown = 14.0
			var info: Dictionary = THREAT_BARKS[_random.randi_range(0, THREAT_BARKS.size() - 1)]
			var barks: Array = info["barks"]
			_show_overhead_bark(info["tag"], barks[_random.randi_range(0, barks.size() - 1)], 2.8)


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


func _configure_sprite_animations() -> void:
	var atlas_tex: Texture2D = WALK_ATLAS
	var raw_img := Image.load_from_file(ProjectSettings.globalize_path(WALK_ATLAS_PATH))
	if raw_img != null and not raw_img.is_empty():
		atlas_tex = ImageTexture.create_from_image(raw_img)
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
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.animation = _facing_animation
	sprite.play(_facing_animation)


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
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
