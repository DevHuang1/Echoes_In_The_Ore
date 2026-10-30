class_name ResonanceOreVillain
extends CharacterBody2D

signal rampage_station_hit(station_index: int)
signal rampage_finished
signal villain_repelled(tool_id: StringName)
signal transformed_stage2
signal transformed_final_form

enum FormStage { LIQUID = 0, STAGE1_INFECTED = 1, STAGE2_MUTATED = 2, STAGE3_FINAL_FORM = 3 }

const LIQUID_ATLAS_PATH := "res://art/characters/runtime/echo_liquid_walk_4dir.png"
const FUSED_ATLAS_PATH := "res://art/characters/runtime/echo_amara_fused_walk_4dir.png"
const MUTATED_ATLAS_PATH := "res://art/characters/runtime/echo_amara_mutated_walk_4dir.png"
const FINAL_FORM_ATLAS_PATH := "res://art/characters/runtime/echo_amara_final_form_walk_4dir.png"
const WARM_LIGHT_SCENE := preload("res://scenes/ship/props/warm_ship_light.tscn")
const FLOOR_ALPHA_THRESHOLD := 0.15
const NAV_CELL_SIZE := 20.0
const BODY_RADIUS := 7.0
const NAV_CLEARANCE_RADIUS := BODY_RADIUS + 3.0
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
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

@export_range(30.0, 240.0, 1.0) var move_speed: float = 76.0
@export_range(40.0, 9999.0, 1.0) var stalk_player_distance: float = 185.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var form_stage: FormStage = FormStage.LIQUID

# Compatibility property aliases for external callers / dev panels
var current_stage: int:
	get:
		return int(form_stage)
	set(value):
		set_form_stage(value, true)

var stalk_speed: float:
	get:
		return move_speed
	set(value):
		move_speed = value

var in_ducts: bool:
	get:
		return _in_ducts
	set(value):
		if value and not _in_ducts:
			disappear_into_ducts()
		elif not value and _in_ducts:
			emerge_from_ducts(global_position)

var is_active: bool:
	get:
		return visible and not _in_ducts
	set(value):
		if value:
			wake_up()
		else:
			disappear_into_ducts()

var is_fused_with_amara: bool:
	get:
		return _is_fused_form
	set(value):
		_is_fused_form = value

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
var _attack_cooldown := 0.0
var _is_chasing := false
var _in_ducts := false
var _duct_stalk_timer := 0.0

var _rampage_targets: Array[Vector2] = []
var _rampage_index := 0
var _rampage_path_target_index := -1
var _in_rampage := false
var _acid_drips: Array[Dictionary] = []
var _repel_burst_timer := 0.0

var _walk_blend: float = 0.0
var _walk_stride_phase: float = 0.0
var _door_wait_retries: int = 0

var _tentacle_attack_timer: float = 0.0
var _tentacle_attack_duration: float = 0.55
var _tentacle_target_pos: Vector2 = Vector2.ZERO
var _tentacle_target_world_pos: Vector2 = Vector2.ZERO
var _tentacle_target_dir: Vector2 = Vector2.DOWN
var _tentacle_strikes: Array[Dictionary] = []
var _tentacle_impact_particles: Array[Dictionary] = []
var _tentacle_impact_spawned: bool = false
var _foreground_overlay: Node2D = null


func _ready() -> void:
	_random.randomize()
	add_to_group("resonance_ore_villain")
	add_to_group("ship_villain")
	add_to_group("ship_crew")

	var initial_stage: FormStage = FormStage.LIQUID
	if Engine.has_meta(&"resonance_ore_final_form") and bool(Engine.get_meta(&"resonance_ore_final_form")):
		initial_stage = FormStage.STAGE3_FINAL_FORM
	elif Engine.has_meta(&"resonance_ore_mutated_stage2") and bool(Engine.get_meta(&"resonance_ore_mutated_stage2")):
		initial_stage = FormStage.STAGE2_MUTATED
	elif Engine.has_meta(&"resonance_ore_fused_with_amara") and bool(Engine.get_meta(&"resonance_ore_fused_with_amara")):
		initial_stage = FormStage.STAGE1_INFECTED

	_build_aura_light()
	_build_foreground_overlay()
	set_form_stage(initial_stage, true)

	_init_floor_layer_and_mask()
	_build_navigation()

	# If spawned inside a solid cell, shift to nearest clear cell
	var spawn_cell := _world_to_cell(global_position)
	if _grid_region.has_point(spawn_cell) and _grid.is_point_solid(spawn_cell):
		var clear_cell := _find_nearest_clear_cell(spawn_cell)
		if _grid_region.has_point(clear_cell) and not _grid.is_point_solid(clear_cell):
			global_position = _cell_to_world(clear_cell)

	if not _in_rampage and not _in_ducts and visible:
		_choose_next_destination()


func set_form_stage(stage_val: int, instant: bool = false) -> void:
	form_stage = clampi(stage_val, 0, 3) as FormStage
	var atlas_to_use := LIQUID_ATLAS_PATH
	var light_col := Color(1.0, 0.38, 0.18, 1.0)
	var light_energy := 0.32
	var light_scale := 0.28
	var shape_radius := 4.0

	match form_stage:
		FormStage.STAGE3_FINAL_FORM:
			_is_fused_form = true
			atlas_to_use = FINAL_FORM_ATLAS_PATH
			move_speed = 105.0
			shape_radius = BODY_RADIUS + 3.0
			light_col = Color(0.85, 0.22, 1.0, 1.0)
			light_energy = 0.82
			light_scale = 0.48
			Engine.set_meta(&"resonance_ore_final_form", true)
			Engine.set_meta(&"resonance_ore_mutated_stage2", true)
			Engine.set_meta(&"resonance_ore_fused_with_amara", true)
			if not instant:
				DialogueAudioSynth.play_sfx_2d("villain_attack", global_position, self, -1.0)
			transformed_final_form.emit()
		FormStage.STAGE2_MUTATED:
			_is_fused_form = true
			atlas_to_use = MUTATED_ATLAS_PATH
			move_speed = 96.0
			shape_radius = BODY_RADIUS + 1.5
			light_col = Color(0.72, 0.15, 0.98, 1.0)
			light_energy = 0.58
			light_scale = 0.38
			Engine.set_meta(&"resonance_ore_mutated_stage2", true)
			Engine.set_meta(&"resonance_ore_fused_with_amara", true)
			if not instant:
				DialogueAudioSynth.play_sfx_2d("villain_attack", global_position, self, -1.0)
			transformed_stage2.emit()
		FormStage.STAGE1_INFECTED:
			_is_fused_form = true
			atlas_to_use = FUSED_ATLAS_PATH
			move_speed = 88.0
			shape_radius = BODY_RADIUS
			light_col = Color(0.96, 0.34, 0.16, 1.0)
			light_energy = 0.42
			light_scale = 0.32
			Engine.set_meta(&"resonance_ore_fused_with_amara", true)
			Engine.set_meta(&"resonance_ore_sample_evolved", true)
		FormStage.LIQUID, _:
			_is_fused_form = false
			atlas_to_use = LIQUID_ATLAS_PATH
			move_speed = 52.0
			shape_radius = 4.0
			light_col = Color(1.0, 0.38, 0.18, 1.0)
			light_energy = 0.32
			light_scale = 0.28
			Engine.remove_meta(&"resonance_ore_final_form")
			Engine.remove_meta(&"resonance_ore_mutated_stage2")
			Engine.remove_meta(&"resonance_ore_fused_with_amara")

	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		var circ := CircleShape2D.new()
		circ.radius = shape_radius
		collision_shape.shape = circ

	_configure_sprite_animations(atlas_to_use)
	if is_instance_valid(_aura_light):
		_aura_light.color = light_col
		_aura_light.energy = light_energy
		_aura_light.texture_scale = light_scale


func fuse_with_amara() -> void:
	set_form_stage(FormStage.STAGE1_INFECTED, false)


func mutate_to_stage2() -> void:
	set_form_stage(FormStage.STAGE2_MUTATED, false)


func mutate_to_final_form() -> void:
	set_form_stage(FormStage.STAGE3_FINAL_FORM, false)


func wake_up(at_position: Vector2 = Vector2.INF) -> void:
	if at_position != Vector2.INF:
		global_position = at_position
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	set_physics_process(true)
	_in_ducts = false
	_is_repelled = false
	_idle_remaining = 0.0
	_rampage_path_target_index = -1
	_has_destination = false
	if is_instance_valid(_aura_light):
		var target_energy := 0.65 if form_stage == FormStage.STAGE3_FINAL_FORM else (0.50 if form_stage == FormStage.STAGE2_MUTATED else 0.35)
		_aura_light.energy = target_energy
	Engine.set_meta(&"echo_disappeared_into_ducts", false)
	_choose_next_destination()


func start_lab_rampage(targets: Array[Vector2]) -> void:
	_rampage_targets = targets.duplicate()
	_rampage_index = 0
	_rampage_path_target_index = -1
	_has_destination = false
	_path.clear()
	_in_rampage = not _rampage_targets.is_empty()
	set_physics_process(true)


func disappear_into_ducts(start_stalking: bool = true) -> void:
	_in_ducts = true
	_in_rampage = false
	_rampage_path_target_index = -1
	_has_destination = false
	velocity = Vector2.ZERO
	set_physics_process(start_stalking)
	DialogueAudioSynth.play_sfx_2d("villain_duct", global_position, self, -2.0)
	var fade := create_tween().set_parallel(true)
	fade.tween_property(self, "modulate:a", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade.tween_property(self, "scale", Vector2.ONE * 0.18, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if is_instance_valid(_aura_light):
		fade.tween_property(_aura_light, "energy", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished
	if is_inside_tree():
		visible = false
		Engine.set_meta(&"echo_disappeared_into_ducts", true)
		_duct_stalk_timer = _random.randf_range(16.0, 28.0)
		if start_stalking:
			set_physics_process(true)


func emerge_from_ducts(at_position: Vector2) -> void:
	var spawn_cell := _world_to_cell(at_position)
	if _navigation_ready and (not _grid_region.has_point(spawn_cell) or _grid.is_point_solid(spawn_cell) or not _position_is_walkable(at_position)):
		spawn_cell = _find_nearest_clear_cell(spawn_cell)
		if not _grid_region.has_point(spawn_cell) or _grid.is_point_solid(spawn_cell):
			_duct_stalk_timer = 6.0
			return
		at_position = _cell_to_world(spawn_cell)
	global_position = at_position
	visible = true
	modulate = Color.WHITE
	modulate.a = 0.0
	scale = Vector2.ONE * 0.22
	set_physics_process(true)
	_is_repelled = false
	_in_rampage = false
	_in_ducts = false
	_rampage_path_target_index = -1
	_has_destination = false
	_idle_remaining = 0.0
	Engine.set_meta(&"echo_disappeared_into_ducts", false)
	DialogueAudioSynth.play_sfx_2d("villain_emerge", at_position, self, -1.0)
	var surge := create_tween().set_parallel(true)
	surge.tween_property(self, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	surge.tween_property(self, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(_aura_light):
		var target_energy := 0.65 if form_stage == FormStage.STAGE3_FINAL_FORM else (0.48 if form_stage == FormStage.STAGE2_MUTATED else 0.35)
		surge.tween_property(_aura_light, "energy", target_energy, 0.55)
	await surge.finished
	if is_inside_tree():
		_choose_next_destination()


func repel_with_tool(tool_id: StringName, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if _is_repelled or not visible or _in_ducts:
		return
	_is_repelled = true
	_repel_burst_timer = 0.45
	_repel_cooldown = 20.0
	villain_repelled.emit(tool_id)
	DialogueAudioSynth.play_sfx_2d("villain_hurt", global_position, self, -1.0)

	# Violet screech reaction and particle/flash burst
	if is_instance_valid(sprite):
		var flash := create_tween()
		flash.tween_property(sprite, "modulate", Color(2.8, 0.4, 3.2, 1.0), 0.12)
		flash.tween_property(sprite, "modulate", Color.WHITE, 0.18)
	if is_instance_valid(_aura_light):
		_aura_light.energy = 1.6
		_aura_light.color = Color(0.9, 0.3, 1.0, 1.0)

	await get_tree().create_timer(0.35).timeout
	if is_inside_tree():
		await disappear_into_ducts()


func _physics_process(delta: float) -> void:
	_pulse_time += delta
	if _repel_burst_timer > 0.0:
		_repel_burst_timer = maxf(_repel_burst_timer - delta, 0.0)

	var is_moving := velocity.length_squared() > 10.0 and visible and not _in_ducts
	_walk_blend = move_toward(_walk_blend, 1.0 if is_moving else 0.0, delta * 8.0)
	if is_moving:
		_walk_stride_phase += delta * (move_speed / 6.5)
	else:
		_walk_stride_phase = fposmod(_walk_stride_phase, TAU)

	if _tentacle_attack_timer > 0.0:
		_tentacle_attack_timer = maxf(_tentacle_attack_timer - delta, 0.0)
		if _tentacle_target_world_pos != Vector2.ZERO:
			_tentacle_target_pos = to_local(_tentacle_target_world_pos)
		var t_prog: float = 1.0 - (_tentacle_attack_timer / _tentacle_attack_duration)
		if t_prog >= 0.28 and not _tentacle_impact_spawned:
			_tentacle_impact_spawned = true
			_spawn_tentacle_impact_fx(_tentacle_target_pos)

	var tp_idx := _tentacle_impact_particles.size() - 1
	while tp_idx >= 0:
		var tp: Dictionary = _tentacle_impact_particles[tp_idx]
		var tpt: float = float(tp["timer"]) - delta
		if tpt <= 0.0:
			_tentacle_impact_particles.remove_at(tp_idx)
		else:
			tp["timer"] = tpt
			var tp_pos: Vector2 = tp["pos"]
			var tp_vel: Vector2 = tp["vel"]
			tp["pos"] = tp_pos + tp_vel * delta
			tp["vel"] = tp_vel * pow(0.3, delta)
			_tentacle_impact_particles[tp_idx] = tp
		tp_idx -= 1

	if is_instance_valid(_aura_light):
		var base_e := 0.42 if _in_rampage else (0.35 if form_stage >= FormStage.STAGE2_MUTATED else 0.28)
		_aura_light.energy = base_e + 0.12 * sin(_pulse_time * (8.5 if _in_rampage else 4.2))

	# Dripping corrosive acid ichor puddles when moving
	if is_moving:
		if _random.randf() < delta * 3.8:
			_acid_drips.append({
				"pos": Vector2(_random.randf_range(-4.5, 4.5), _random.randf_range(-1.5, 3.0)),
				"timer": 0.85,
				"max_timer": 0.85,
				"color": Color(0.35, 0.95, 0.45, 0.85) if form_stage == FormStage.LIQUID else Color(0.82, 0.25, 0.95, 0.85)
			})
			if _acid_drips.size() > 16:
				_acid_drips.pop_front()

	var d_idx := _acid_drips.size() - 1
	while d_idx >= 0:
		var ad: Dictionary = _acid_drips[d_idx]
		ad["timer"] = float(ad["timer"]) - delta
		if float(ad["timer"]) <= 0.0:
			_acid_drips.remove_at(d_idx)
		else:
			_acid_drips[d_idx] = ad
		d_idx -= 1

	queue_redraw()
	if is_instance_valid(_foreground_overlay):
		_foreground_overlay.queue_redraw()

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if _is_repelled:
		_repel_cooldown = maxf(_repel_cooldown - delta, 0.0)
		if _repel_cooldown <= 0.0:
			_is_repelled = false

	# When lurking in ducts, advance timer to emerge near player
	if _in_ducts:
		if _duct_stalk_timer > 0.0:
			_duct_stalk_timer = maxf(_duct_stalk_timer - delta, 0.0)
			if _duct_stalk_timer <= 0.0 and not _is_repelled:
				_try_emerge_near_player()
		return

	if _in_rampage:
		_process_rampage(delta)
		return

	if not visible:
		return

	if _repath_timer > 0.0:
		_repath_timer = maxf(_repath_timer - delta, 0.0)

	_check_player_stalking()
	_update_proximity_clues(delta)

	if not _is_chasing and _idle_remaining > 0.0:
		_idle_remaining = maxf(_idle_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		if not sprite.is_playing():
			sprite.play(_facing_animation)
		return

	if not _has_destination:
		if not _is_chasing:
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

	# Trigger doors ahead to slide open
	_handle_doors_near(global_position + direction * 28.0)

	var motion := direction * minf(move_speed * delta, distance)
	var blocked_door := _get_blocking_door(global_position + motion)
	if blocked_door != null:
		if blocked_door.get("locked"):
			var blocked_cell := _world_to_cell(global_position + motion)
			if _grid_region.has_point(blocked_cell):
				_grid.set_point_solid(blocked_cell, true)
			velocity = Vector2.ZERO
			_has_destination = false
			_path.clear()
			_path_index = 0
			_repath_timer = 0.0
			_door_wait_retries = 0
			return

		# Unlocked door is sliding open; pause briefly so it can open instead of aborting the path
		velocity = Vector2.ZERO
		_door_wait_retries += 1
		if _door_wait_retries < 8:
			_idle_remaining = 0.25
			return
		_door_wait_retries = 0
		_path.clear()
		_path_index = 0
		_has_destination = false
		_idle_remaining = 0.2
		return
	else:
		_door_wait_retries = 0

	if not _can_move_on_walkable_floor(motion):
		var blocked_cell := _world_to_cell(global_position + motion)
		if _grid_region.has_point(blocked_cell):
			_grid.set_point_solid(blocked_cell, true)
		velocity = Vector2.ZERO
		_has_destination = false
		_path.clear()
		_path_index = 0
		_repath_timer = 0.0
		return

	velocity = direction * move_speed
	var previous_position := global_position
	var collision := move_and_collide(motion)
	if collision != null or not _position_is_walkable(global_position, true):
		var blocked_cell := _world_to_cell(global_position if collision == null else (global_position + motion))
		if _grid_region.has_point(blocked_cell):
			_grid.set_point_solid(blocked_cell, true)
		if not _position_is_walkable(global_position, true):
			global_position = previous_position
		velocity = Vector2.ZERO
		_has_destination = false
		_path.clear()
		_path_index = 0
		_repath_timer = 0.0

	if not sprite.is_playing():
		sprite.play(_facing_animation)


func _check_player_stalking() -> void:
	if _in_rampage or _is_repelled or not visible or _in_ducts:
		_is_chasing = false
		return
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		_is_chasing = false
		return
	var player: Node2D = null
	for p in players:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			player = p as Node2D
			break
	if player == null:
		_is_chasing = false
		return

	# If player is concealed inside a locker or hiding spot, lose sight!
	if player.get("is_concealed") == true or player.is_in_group("concealed_players"):
		_is_chasing = false
		_has_destination = false
		_path.clear()
		velocity = Vector2.ZERO
		return

	# If monster itself is touching an active floor flare boundary, stagger back and retreat
	if player.has_method("is_position_in_flare_safe_zone") and bool(player.call("is_position_in_flare_safe_zone", global_position, 12.0)):
		repel_with_tool(&"emergency_flare", global_position)
		return

	# High-Intensity Flare Safe Zone: Monster cannot enter or chase inside burning flares!
	if player.has_method("is_position_in_flare_safe_zone") and bool(player.call("is_position_in_flare_safe_zone", player.global_position)):
		_is_chasing = false
		_has_destination = false
		_path.clear()
		velocity = Vector2.ZERO
		return

	# Dynamic Multi-Sensory & Lighting Perception
	var effective_stalk_dist := stalk_player_distance
	var player_sprinting := false
	if player.has_method("is_sprinting") and bool(player.call("is_sprinting")):
		player_sprinting = true

	var player_flashlight := false
	if player.has_method("is_suit_flashlight_enabled") and bool(player.call("is_suit_flashlight_enabled")):
		player_flashlight = true

	if player_sprinting:
		# Acoustic detection: loud sprint footsteps travel across rooms and ducts
		effective_stalk_dist = maxf(effective_stalk_dist, 320.0)
	elif player_flashlight:
		# Direct flashlight cone illuminates the player, increasing visual detection range
		effective_stalk_dist = maxf(effective_stalk_dist, 260.0)
	else:
		# Darkness stealth: unpowered dark rooms reduce detection range
		var lighting_nodes := get_tree().get_nodes_in_group("ship_room_lighting")
		if not lighting_nodes.is_empty():
			var lighting = lighting_nodes[0]
			if lighting.has_method("is_emergency_breaker_mode") and bool(lighting.call("is_emergency_breaker_mode")):
				var cur_room: StringName = StringName(lighting.call("get_current_player_room_id"))
				if not bool(lighting.call("is_breaker_powered", cur_room)):
					effective_stalk_dist = 90.0

	var dist := global_position.distance_to(player.global_position)
	if dist <= effective_stalk_dist:
		_is_chasing = true
		_idle_remaining = 0.0
		var dir := player.global_position - global_position
		if not dir.is_zero_approx():
			_update_facing(dir)

		# Attack trigger at close range
		if dist <= 28.0 and _attack_cooldown <= 0.0:
			_attack_player(player)
			return

		if _repath_timer <= 0.0 or not _has_destination:
			_repath_timer = 0.4
			var start_cell := _world_to_cell(global_position)
			if not _grid_region.has_point(start_cell) or _grid.is_point_solid(start_cell):
				start_cell = _find_nearest_clear_cell(start_cell)
			var target_cell := _find_nearest_reachable_cell(_world_to_cell(player.global_position), start_cell)
			if _grid_region.has_point(target_cell) and _set_destination(target_cell):
				return
			_has_destination = false
			_path.clear()
			_path_index = 0
			velocity = Vector2.ZERO
	else:
		_is_chasing = false


func execute_tentacle_attack(target_world_pos: Vector2) -> void:
	_tentacle_attack_timer = _tentacle_attack_duration
	_tentacle_target_pos = to_local(target_world_pos)
	var diff := target_world_pos - global_position
	_tentacle_target_dir = diff.normalized() if not diff.is_zero_approx() else Vector2.DOWN
	_tentacle_strikes.clear()

	var is_final := (form_stage >= FormStage.STAGE2_MUTATED)
	var tendril_count := 6 if is_final else 4
	var target_dist := clampf(diff.length(), 16.0, 72.0)

	for i in range(tendril_count):
		var angle_spread := _random.randf_range(-0.45, 0.45)
		var length_jitter := _random.randf_range(-6.0, 12.0)
		_tentacle_strikes.append({
			"angle": angle_spread,
			"dist": target_dist + length_jitter,
			"curl_freq": _random.randf_range(1.5, 3.2),
			"curl_amp": _random.randf_range(6.0, 14.0) * (1.0 if i % 2 == 0 else -1.0),
			"phase": _random.randf_range(0.0, TAU),
			"width": _random.randf_range(2.6, 4.2) if is_final else _random.randf_range(2.0, 3.2),
		})

	_spawn_tentacle_impact_fx(_tentacle_target_pos)


func _spawn_tentacle_impact_fx(local_pos: Vector2) -> void:
	var is_final := (form_stage >= FormStage.STAGE2_MUTATED)
	var particle_count := 14 if is_final else 8
	var base_col := Color(0.85, 0.22, 1.0, 0.95) if is_final else Color(0.95, 0.35, 0.15, 0.95)
	for i in range(particle_count):
		var ang := _random.randf_range(0.0, TAU)
		var spd := _random.randf_range(28.0, 85.0)
		_tentacle_impact_particles.append({
			"pos": local_pos,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"timer": _random.randf_range(0.25, 0.48),
			"max_timer": 0.48,
			"size": _random.randf_range(1.4, 3.2),
			"color": base_col if i % 2 == 0 else Color(1.0, 1.0, 1.0, 0.9),
		})


func _attack_player(player: Node2D) -> void:
	_attack_cooldown = 1.8
	DialogueAudioSynth.play_sfx_2d("villain_attack", global_position, self, 0.0)

	# Execute visible tentacle lash / whip attack
	execute_tentacle_attack(player.global_position)

	# Trigger initial screen shake on player
	if player.has_method("trigger_screen_shake"):
		player.call("trigger_screen_shake", 0.70 if form_stage >= FormStage.STAGE2_MUTATED else 0.50)

	# Visual chromatic flash on player sprite
	var p_sprite := player.get_node_or_null("AnimatedSprite2D") as CanvasItem
	if p_sprite != null:
		var hit_tween := create_tween()
		hit_tween.tween_property(p_sprite, "modulate", Color(2.8, 0.35, 0.45, 1.0), 0.08)
		hit_tween.tween_property(p_sprite, "modulate", Color.WHITE, 0.22)

	# Close any open service console on contact
	for console in get_tree().get_nodes_in_group("service_task_console"):
		if is_instance_valid(console) and console.has_method("_close_console"):
			console.call("_close_console")

	var equipped: StringName = player.get_equipped_item_id() if player.has_method("get_equipped_item_id") else &""
	if equipped in [&"emergency_flare", &"electrical_discharge_tool"]:
		var charge_count := 1
		if player.has_method("get_equipment_amount"):
			charge_count = int(player.call("get_equipment_amount", equipped))
		if charge_count > 0:
			if player.has_method("consume_item_amount"):
				player.call("consume_item_amount", equipped, 1)
			repel_with_tool(equipped, player.global_position)
			var hud := get_tree().get_first_node_in_group("walk_hud")
			if hud != null and hud.has_method("show_room_feedback"):
				hud.call("show_room_feedback", "CLOSE-RANGE DEFENSE TRIGGERED! %s REPELLED THE ECHO HOST!" % String(equipped).replace("_", " ").to_upper(), 4.0)
			return

	# Struggle escape with consumable survival items
	var struggle_items: Array[StringName] = [&"emergency_flare", &"electrical_discharge_tool", &"survey_beacon", &"medical_injector"]
	for item_id in struggle_items:
		if player.has_method("get_equipment_amount") and int(player.call("get_equipment_amount", item_id)) > 0:
			if player.has_method("consume_item_amount"):
				player.call("consume_item_amount", item_id, 1)
			repel_with_tool(item_id, player.global_position)
			var hud := get_tree().get_first_node_in_group("walk_hud")
			if hud != null and hud.has_method("show_room_feedback"):
				hud.call("show_room_feedback", "STRUGGLE ESCAPE! Used %s to break free from the Echo!" % String(item_id).replace("_", " ").to_upper(), 4.0)
			return

	if is_instance_valid(sprite):
		var target_scale := (DISPLAY_SCALE * 1.35) if form_stage >= FormStage.STAGE2_MUTATED else (DISPLAY_SCALE * 1.2)
		var lunge := create_tween()
		lunge.tween_property(sprite, "scale", Vector2.ONE * target_scale, 0.12).set_trans(Tween.TRANS_QUAD)
		lunge.tween_property(sprite, "scale", Vector2.ONE * DISPLAY_SCALE, 0.22).set_trans(Tween.TRANS_BACK)

	var knock_dir := (player.global_position - global_position).normalized()
	if knock_dir.is_zero_approx():
		knock_dir = Vector2.UP
	player.global_position += knock_dir * (28.0 if form_stage >= FormStage.STAGE2_MUTATED else 22.0)

	# Heavy trauma screen shake on unmitigated direct tentacle hit
	if player.has_method("trigger_screen_shake"):
		player.call("trigger_screen_shake", 0.85)

	if player.has_method("take_damage"):
		player.call("take_damage", 25.0)

	var walk_hud := get_tree().get_first_node_in_group("walk_hud")
	if walk_hud != null and walk_hud.has_method("show_room_feedback"):
		var entity_name := "APEX ECHO HOST" if form_stage >= FormStage.STAGE2_MUTATED else "ECHO INFECTED DR. OKOYE"
		walk_hud.call("show_room_feedback", "⚠️ CRITICAL TENTACLE ATTACK: %s STRUCK!\nSUIT INTEGRITY DAMAGED! EQUIP FLARE / ARC TOOL OR RETREAT TO A SECURED LOCKER!" % entity_name, 4.0)


func repel_with_light(intensity: float = 1.0, source_pos: Vector2 = Vector2.ZERO) -> void:
	repel_with_tool(&"high_intensity_light", source_pos if source_pos != Vector2.ZERO else global_position)


func on_system_milestone_completed(milestone_id: StringName) -> void:
	match milestone_id:
		&"power_auxiliary", &"power_grid_restored", &"reactor_stabilized":
			if form_stage < FormStage.STAGE2_MUTATED:
				mutate_to_stage2()
		&"life_support", &"airflow_restored", &"atmosphere_purged":
			if form_stage < FormStage.STAGE3_FINAL_FORM:
				mutate_to_final_form()


func _try_emerge_near_player() -> void:
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		return
	var player := players[0] as Node2D
	if not is_instance_valid(player):
		return

	var cur_scene := get_tree().current_scene
	if cur_scene != null and cur_scene.has_method("ship_control_locked") and bool(cur_scene.call("ship_control_locked")):
		_duct_stalk_timer = 6.0
		return

	var emerge_pos := Vector2.ZERO
	var player_cell := _world_to_cell(player.global_position)
	for attempt in range(25):
		var offset_cell := player_cell + Vector2i(_random.randi_range(-7, 7), _random.randi_range(-7, 7))
		if _grid_region.has_point(offset_cell) and not _grid.is_point_solid(offset_cell):
			var cand_pos := _cell_to_world(offset_cell)
			if cand_pos.distance_to(player.global_position) >= 80.0 and _position_is_walkable(cand_pos):
				emerge_pos = cand_pos
				break

	if emerge_pos == Vector2.ZERO:
		_duct_stalk_timer = 6.0
		return

	emerge_from_ducts(emerge_pos)


func _handle_doors_near(position_to_check: Vector2) -> void:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", position_to_check, 18.0)):
			if not door.get("locked"):
				if door.has_method("_set_open_target"):
					door.call("_set_open_target", true)
				elif door.has_method("set_open"):
					door.call("set_open", true)


func _process_rampage(delta: float) -> void:
	if _rampage_index >= _rampage_targets.size():
		_in_rampage = false
		_rampage_path_target_index = -1
		rampage_finished.emit()
		if _navigation_ready:
			_choose_next_destination()
		return

	var target := _rampage_targets[_rampage_index]
	var rampage_speed := 155.0
	if _rampage_path_target_index != _rampage_index:
		var start_cell := _world_to_cell(global_position)
		if not _grid_region.has_point(start_cell) or _grid.is_point_solid(start_cell):
			start_cell = _find_nearest_clear_cell(start_cell)
		var target_cell := _find_nearest_reachable_cell(_world_to_cell(target), start_cell)
		if not _grid_region.has_point(target_cell) or not _set_destination(target_cell):
			_rampage_index += 1
			return
		_rampage_path_target_index = _rampage_index

	if _path_index >= _path.size():
		var strike_idx := _rampage_index
		_rampage_index += 1
		_rampage_path_target_index = -1
		_has_destination = false
		if is_instance_valid(sprite):
			sprite.scale = Vector2.ONE * (DISPLAY_SCALE * 1.24)
			var slash_tween := create_tween()
			slash_tween.tween_property(sprite, "scale", Vector2.ONE * DISPLAY_SCALE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rampage_station_hit.emit(strike_idx)
		return

	var waypoint := _path[_path_index]
	var to_waypoint := waypoint - global_position
	var dist := to_waypoint.length()
	if dist <= 2.5:
		_path_index += 1
		return
	var dir := to_waypoint / dist
	_update_facing(dir)
	_handle_doors_near(global_position + dir * 28.0)
	var motion := dir * minf(rampage_speed * delta, dist)
	if not _can_move_on_walkable_floor(motion):
		_has_destination = false
		_path.clear()
		_path_index = 0
		_rampage_path_target_index = -1
		return
	velocity = dir * rampage_speed
	var prev_pos := global_position
	var col := move_and_collide(motion)
	if col != null or not _position_is_walkable(global_position, true):
		if not _position_is_walkable(global_position, true):
			global_position = prev_pos
		_has_destination = false
		_path.clear()
		_path_index = 0
		_rampage_path_target_index = -1
		return
	if not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_foreground_overlay() -> void:
	if is_instance_valid(_foreground_overlay):
		return
	_foreground_overlay = Node2D.new()
	_foreground_overlay.name = "ForegroundOverlay"
	_foreground_overlay.z_index = 4
	_foreground_overlay.draw.connect(_draw_foreground)
	add_child(_foreground_overlay)


func _draw_foreground() -> void:
	if not visible or _in_ducts or not is_instance_valid(_foreground_overlay):
		return

	# 1. Menacing predatory eye flares (drawn over the head of the sprite)
	var eye_blink := 0.75 + 0.25 * sin(_pulse_time * 8.0)
	var is_final := (form_stage >= FormStage.STAGE2_MUTATED)
	var eye_col := Color(1.0, 0.18, 0.12, 0.95 * eye_blink) if is_final else Color(1.0, 0.45, 0.15, 0.90 * eye_blink)
	var head_center := Vector2(0.0, -10.0 if _is_fused_form else -3.0)
	_foreground_overlay.draw_circle(head_center + Vector2(-2.2, 0.0), 1.8, Color(eye_col.r, eye_col.g, eye_col.b, 0.45))
	_foreground_overlay.draw_circle(head_center + Vector2(2.2, 0.0), 1.8, Color(eye_col.r, eye_col.g, eye_col.b, 0.45))
	_foreground_overlay.draw_circle(head_center + Vector2(-2.2, 0.0), 0.9, eye_col)
	_foreground_overlay.draw_circle(head_center + Vector2(2.2, 0.0), 0.9, eye_col)

	# 2. Violent repulsion energy shockwave when struck
	if _repel_burst_timer > 0.0:
		var r_norm := 1.0 - (_repel_burst_timer / 0.45)
		var ring_r := 6.0 + r_norm * 36.0
		var repel_col := Color(0.85, 0.25, 1.0, (1.0 - r_norm) * 0.90)
		_foreground_overlay.draw_arc(Vector2(0.0, -6.0), ring_r, 0.0, TAU, 22, repel_col, 2.0, true)
		for sp_k in range(8):
			var sp_a := float(sp_k) * (TAU / 8.0) + sin(float(sp_k) * 3.2) * 0.3
			var sp_dist := ring_r * 0.92
			_foreground_overlay.draw_circle(Vector2(0.0, -6.0) + Vector2(cos(sp_a), sin(sp_a)) * sp_dist, 1.4 * (1.0 - r_norm), Color(1.0, 1.0, 1.0, (1.0 - r_norm)))

	# 3. High-velocity tentacle lash attack & impact shockwaves (drawn over player & monster)
	_draw_tentacle_attack(_foreground_overlay)


func _draw() -> void:
	if not visible or _in_ducts:
		return

	# 0. Grounded, dynamic multi-ellipse shadow beneath monster's feet/contact point
	_draw_shadow()

	# 1. Eldritch void distortion aura
	var aura_pulse: float = 0.78 + 0.22 * sin(_pulse_time * 6.5)
	var is_final: bool = (form_stage >= FormStage.STAGE2_MUTATED)
	var void_col := Color(0.68, 0.12, 0.95, 0.28 * aura_pulse) if is_final else Color(0.95, 0.25, 0.12, 0.22 * aura_pulse)
	draw_circle(Vector2(0.0, -6.0), (14.0 if is_final else 9.5) * aura_pulse, void_col)
	draw_circle(Vector2(0.0, -6.0), (7.0 if is_final else 5.0) * aura_pulse, Color(0.05, 0.01, 0.08, 0.55))

	# 2. Writhing shadow tendrils reaching out behind body
	var tendril_count := 6 if is_final else 4
	for t_i in range(tendril_count):
		var t_angle := float(t_i) * (TAU / float(tendril_count)) + sin(_pulse_time * 3.5 + float(t_i)) * 0.45
		var t_len := (12.0 if is_final else 7.5) + sin(_pulse_time * 5.0 + float(t_i) * 1.8) * 4.0
		var t_tip := Vector2(0.0, -6.0) + Vector2(cos(t_angle), sin(t_angle)) * t_len
		draw_line(Vector2(0.0, -6.0), t_tip, Color(void_col.r, void_col.g, void_col.b, 0.65), 1.6, false)
		draw_circle(t_tip, 1.1, Color(1.0, 0.85, 0.95, 0.85))

	# 3. Corrosive acid drip puddles on the deck
	for ad in _acid_drips:
		var a_t: float = clampf(float(ad["timer"]) / float(ad["max_timer"]), 0.0, 1.0)
		var a_pos: Vector2 = ad["pos"]
		var a_col: Color = ad["color"]
		a_col.a *= pow(a_t, 1.2)
		draw_circle(a_pos, 2.2 * a_t, a_col)
		draw_circle(a_pos + Vector2(0.0, -1.0 * (1.0 - a_t) * 4.0), 0.9 * a_t, Color(1.0, 1.0, 1.0, a_col.a * 0.75))

	# Fallback if foreground overlay is not active
	if not is_instance_valid(_foreground_overlay):
		_draw_tentacle_attack(self)


func _draw_shadow() -> void:
	var shadow_offset_y := 7.0 if _is_fused_form else 1.5
	var move_dir := velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.DOWN
	var shift := -move_dir * (1.2 * _walk_blend)
	var center := Vector2(0.0, shadow_offset_y) + Vector2(shift.x, shift.y * 0.45)

	var is_final := (form_stage >= FormStage.STAGE2_MUTATED)
	var walk_pulse := sin(_walk_stride_phase * 2.0) * _walk_blend
	var idle_pulse := sin(_pulse_time * 2.5) * 0.4 * (1.0 - _walk_blend)

	var base_rx: float
	var base_ry: float
	match form_stage:
		FormStage.STAGE3_FINAL_FORM:
			base_rx = 14.5
			base_ry = 6.5
		FormStage.STAGE2_MUTATED:
			base_rx = 12.0
			base_ry = 5.5
		FormStage.STAGE1_INFECTED:
			base_rx = 9.5
			base_ry = 4.2
		FormStage.LIQUID, _:
			base_rx = 11.0
			base_ry = 3.2

	var rx := base_rx + walk_pulse * 0.9 + idle_pulse
	var ry := base_ry - absf(walk_pulse) * 0.35 + idle_pulse * 0.5

	# 1. Subtle resonance chromatic deck reflection
	var rim_color := Color(0.72, 0.18, 0.98, 0.14) if is_final else (Color(0.96, 0.35, 0.15, 0.12) if _is_fused_form else Color(0.35, 0.95, 0.45, 0.12))
	_draw_ellipse(center, rx + 2.5, ry + 1.2, rim_color)

	# 2. Soft outer penumbra shadow
	_draw_ellipse(center, rx + 1.0, ry + 0.5, Color(0.01, 0.015, 0.03, 0.26))

	# 3. Mid contact shadow
	_draw_ellipse(center, rx * 0.78, ry * 0.78, Color(0.01, 0.01, 0.02, 0.42))

	# 4. Deep core shadow directly under body
	_draw_ellipse(center + Vector2(0.0, 0.3), rx * 0.52, ry * 0.52, Color(0.005, 0.005, 0.015, 0.60))

	# Alternating footstep contact shadow blobs for humanoid walk cycle
	if _is_fused_form and _walk_blend > 0.05:
		var left_lift := maxf(0.0, sin(_walk_stride_phase)) * _walk_blend
		var right_lift := maxf(0.0, -sin(_walk_stride_phase)) * _walk_blend
		var left_pos := center + Vector2(-3.0, -0.3 - left_lift * 1.3)
		var right_pos := center + Vector2(3.0, -0.3 - right_lift * 1.3)
		_draw_ellipse(left_pos, 2.6 - left_lift * 0.5, 1.4 - left_lift * 0.25, Color(0.005, 0.008, 0.018, 0.38 * (1.0 - left_lift * 0.45)))
		_draw_ellipse(right_pos, 2.6 - right_lift * 0.5, 1.4 - right_lift * 0.25, Color(0.005, 0.008, 0.018, 0.38 * (1.0 - right_lift * 0.45)))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx <= 0.05 or ry <= 0.05 or color.a <= 0.005:
		return
	var pts := PackedVector2Array()
	const STEPS := 16
	for i in range(STEPS):
		var angle := TAU * float(i) / float(STEPS)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)


func _draw_tentacle_attack(target_canvas: CanvasItem = null) -> void:
	var canvas: CanvasItem = target_canvas if target_canvas != null else self
	if _tentacle_attack_timer <= 0.0 and _tentacle_impact_particles.is_empty():
		return

	var is_final := (form_stage >= FormStage.STAGE2_MUTATED)
	var void_aura_col := Color(0.85, 0.22, 1.0, 0.65) if is_final else Color(0.98, 0.38, 0.18, 0.65)
	var void_core_col := Color(0.06, 0.01, 0.09, 0.95)

	if _tentacle_attack_timer > 0.0:
		var t_prog: float = 1.0 - (_tentacle_attack_timer / _tentacle_attack_duration)
		# Extension curve: rapid whip forward (0.0 to 0.35), strike/thrash (0.35 to 0.65), retract (0.65 to 1.0)
		var whip_reach: float
		if t_prog < 0.35:
			whip_reach = sin((t_prog / 0.35) * PI * 0.5)
		elif t_prog < 0.65:
			whip_reach = 1.0 + sin((t_prog - 0.35) * 20.0) * 0.08
		else:
			var ret := (t_prog - 0.65) / 0.35
			whip_reach = 1.0 - ret * ret

		var root_pos := Vector2(0.0, -6.0 if _is_fused_form else -1.0)

		for strike in _tentacle_strikes:
			var s_ang: float = float(strike["angle"])
			var s_dist: float = float(strike["dist"]) * whip_reach
			var s_freq: float = float(strike["curl_freq"])
			var s_amp: float = float(strike["curl_amp"])
			var s_phase: float = float(strike["phase"])
			var s_w: float = float(strike["width"])

			var tendril_dir := _tentacle_target_dir.rotated(s_ang)
			var normal := Vector2(-tendril_dir.y, tendril_dir.x)

			var pts := PackedVector2Array()
			const SEGMENTS := 12
			for seg in range(SEGMENTS + 1):
				var seg_f := float(seg) / float(SEGMENTS)
				var seg_pt := root_pos + tendril_dir * (s_dist * seg_f)
				var lateral := sin(seg_f * PI * s_freq + s_phase + _pulse_time * 10.0) * s_amp * sin(seg_f * PI) * whip_reach
				seg_pt += normal * lateral
				pts.append(seg_pt)

			if pts.size() >= 2:
				# Outer void aura
				canvas.draw_polyline(pts, void_aura_col, s_w * 1.6, false)
				# Inner dark tentacle core
				canvas.draw_polyline(pts, void_core_col, s_w, false)
				# Barbed tip
				var tip: Vector2 = pts[pts.size() - 1]
				canvas.draw_circle(tip, s_w * 0.8, Color(1.0, 0.9, 1.0, 0.95))

		# Impact shockwave ring at target during strike phase
		if t_prog >= 0.25 and t_prog <= 0.70:
			var ring_norm := (t_prog - 0.25) / 0.45
			var ring_r := 4.0 + ring_norm * 28.0
			var ring_alpha := (1.0 - ring_norm) * 0.85
			var ring_col := Color(void_aura_col.r, void_aura_col.g, void_aura_col.b, ring_alpha)
			canvas.draw_arc(_tentacle_target_pos, ring_r, 0.0, TAU, 18, ring_col, 2.0, true)
			# Central impact flare
			canvas.draw_circle(_tentacle_target_pos, 3.5 * (1.0 - ring_norm), Color(1.0, 1.0, 1.0, ring_alpha))

	# Draw impact particles
	for p in _tentacle_impact_particles:
		var p_t: float = clampf(float(p["timer"]) / float(p["max_timer"]), 0.0, 1.0)
		var p_pos: Vector2 = p["pos"]
		var p_col: Color = p["color"]
		p_col.a *= pow(p_t, 1.1)
		var p_sz: float = float(p["size"]) * p_t
		canvas.draw_circle(p_pos, p_sz, p_col)


func _build_aura_light() -> void:
	if is_instance_valid(_aura_light):
		return
	_aura_light = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	_aura_light.color = Color(1.0, 0.38, 0.18, 1.0)
	_aura_light.energy = 0.32
	_aura_light.texture_scale = 0.28
	add_child(_aura_light)


func _update_proximity_clues(delta: float) -> void:
	if not visible or _is_repelled or _in_ducts:
		return

	_flicker_check_timer -= delta
	if _flicker_check_timer <= 0.0:
		_flicker_check_timer = 0.6
		var room_lighting := get_tree().get_first_node_in_group("ship_room_lighting")
		if room_lighting == null and get_parent() != null:
			room_lighting = get_parent().get_node_or_null("ShipRoomLighting")
		if room_lighting != null and room_lighting.has_method("set_room_flicker"):
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
	if not _grid_region.has_point(target_cell):
		return false
	if _grid.is_point_solid(target_cell):
		target_cell = _find_nearest_clear_cell(target_cell)
		if not _grid_region.has_point(target_cell) or _grid.is_point_solid(target_cell):
			return false

	var start_cell := _world_to_cell(global_position)
	if not _grid_region.has_point(start_cell) or _grid.is_point_solid(start_cell):
		start_cell = _find_nearest_clear_cell(start_cell)
		if not _grid_region.has_point(start_cell) or _grid.is_point_solid(start_cell):
			return false

	if start_cell == target_cell:
		_path = [_cell_to_world(target_cell)]
		_path_index = 0
		_destination = _cell_to_world(target_cell)
		_has_destination = true
		return true

	var id_path := _grid.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		return false
	_path.clear()
	for cell in id_path:
		if cell != start_cell:
			_path.append(_cell_to_world(cell))
	if _path.is_empty():
		_path.append(_cell_to_world(target_cell))
	_path_index = 0
	_destination = _cell_to_world(target_cell)
	_has_destination = true
	return true


func _find_nearest_clear_cell(origin: Vector2i) -> Vector2i:
	if _grid_region.has_point(origin) and not _grid.is_point_solid(origin):
		return origin
	for radius in range(1, 10):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var candidate := origin + Vector2i(dx, dy)
				if _grid_region.has_point(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return origin


func _find_nearest_reachable_cell(origin: Vector2i, start_cell: Vector2i) -> Vector2i:
	if not _grid_region.has_point(start_cell):
		return Vector2i(-1, -1)
	for radius in range(0, 13):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var candidate := origin + Vector2i(dx, dy)
				if not _grid_region.has_point(candidate) or _grid.is_point_solid(candidate):
					continue
				if candidate == start_cell or not _grid.get_id_path(start_cell, candidate).is_empty():
					return candidate
	return Vector2i(-1, -1)


func _arrive_at_destination() -> void:
	_has_destination = false
	_path.clear()
	_path_index = 0
	velocity = Vector2.ZERO
	_idle_remaining = _random.randf_range(1.4, 2.8) if not _is_chasing else 0.0


func _get_effective_radius() -> float:
	match form_stage:
		FormStage.STAGE3_FINAL_FORM:
			return BODY_RADIUS + 3.0
		FormStage.STAGE2_MUTATED:
			return BODY_RADIUS + 1.5
		FormStage.STAGE1_INFECTED:
			return BODY_RADIUS
		FormStage.LIQUID, _:
			return 4.0


func _get_attack_range() -> float:
	match form_stage:
		FormStage.STAGE3_FINAL_FORM:
			return 48.0
		FormStage.STAGE2_MUTATED:
			return 40.0
		FormStage.STAGE1_INFECTED:
			return 34.0
		FormStage.LIQUID, _:
			return 28.0


func _get_blocking_door(position_to_check: Vector2) -> Node2D:
	if not is_inside_tree():
		return null
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", position_to_check, _get_effective_radius())):
			return door as Node2D
	return null


func _init_floor_layer_and_mask() -> void:
	if _floor_mask != null:
		return
	var floor_layer: Sprite2D = null
	if get_parent() != null:
		floor_layer = get_parent().get_node_or_null("FloorLayer") as Sprite2D
	if floor_layer == null and get_tree() != null and get_tree().current_scene != null:
		floor_layer = get_tree().current_scene.get_node_or_null("FloorLayer") as Sprite2D
	if floor_layer == null and get_tree() != null and get_tree().current_scene != null:
		floor_layer = get_tree().current_scene.find_child("FloorLayer", true, false) as Sprite2D

	if floor_layer != null and floor_layer.texture != null:
		var raw_img := floor_layer.texture.get_image()
		if raw_img != null:
			if raw_img.is_compressed():
				raw_img.decompress()
			_floor_mask = raw_img
			var origin := floor_layer.global_position
			if floor_layer.centered:
				origin -= floor_layer.texture.get_size() * 0.5
			_floor_origin = origin + floor_layer.offset


func _position_is_walkable(world_position: Vector2, check_doors: bool = true) -> bool:
	_init_floor_layer_and_mask()

	# Check closed pressure doors
	if check_doors and is_inside_tree():
		for door in get_tree().get_nodes_in_group("ship_door"):
			if door.has_method("blocks_position") and bool(door.call("blocks_position", world_position, _get_effective_radius())):
				return false

	if _floor_mask == null:
		return true

	var radius := _get_effective_radius()
	var diagonal := radius * 0.70710678
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(radius, 0.0),
		Vector2(-radius, 0.0),
		Vector2(0.0, radius),
		Vector2(0.0, -radius),
		Vector2(diagonal, diagonal),
		Vector2(diagonal, -diagonal),
		Vector2(-diagonal, diagonal),
		Vector2(-diagonal, -diagonal),
	]
	for offset in offsets:
		var local_position := world_position + offset - _floor_origin
		var pixel_x := floori(local_position.x)
		var pixel_y := floori(local_position.y)
		if pixel_x < 0 or pixel_y < 0 or pixel_x >= _floor_mask.get_width() or pixel_y >= _floor_mask.get_height():
			return false
		if _floor_mask.get_pixel(pixel_x, pixel_y).a < FLOOR_ALPHA_THRESHOLD:
			return false
	return true


func _can_move_on_walkable_floor(motion: Vector2) -> bool:
	_init_floor_layer_and_mask()
	var sample_count := maxi(1, ceili(motion.length() / 4.0))
	for sample_index in range(1, sample_count + 1):
		var sample_position := global_position + motion * (float(sample_index) / float(sample_count))
		if not _position_is_walkable(sample_position, true):
			return false
	return true


func _world_to_cell(world_position: Vector2) -> Vector2i:
	_init_floor_layer_and_mask()
	var local_position := world_position - _floor_origin
	return Vector2i(floori(local_position.x / NAV_CELL_SIZE), floori(local_position.y / NAV_CELL_SIZE))


func _cell_to_world(cell: Vector2i) -> Vector2:
	_init_floor_layer_and_mask()
	return _floor_origin + Vector2((float(cell.x) + 0.5) * NAV_CELL_SIZE, (float(cell.y) + 0.5) * NAV_CELL_SIZE)


func _configure_sprite_animations(atlas_path: String) -> void:
	if sprite == null:
		sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return

	var atlas_tex: Texture2D = null
	if ResourceLoader.exists(atlas_path):
		atlas_tex = load(atlas_path) as Texture2D
	if atlas_tex == null:
		var global_p := ProjectSettings.globalize_path(atlas_path)
		if FileAccess.file_exists(global_p):
			var raw_img := Image.load_from_file(global_p)
			if raw_img != null and not raw_img.is_empty():
				atlas_tex = ImageTexture.create_from_image(raw_img)

	if atlas_tex == null:
		return

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var cell_size := Vector2(float(atlas_tex.get_width()) / 4.0, float(atlas_tex.get_height()) / 4.0)
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 5.5)
		frames.set_animation_loop(animation_name, true)
		var row: int = int(ANIMATION_ROWS[animation_name])
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
	sprite.modulate = Color.WHITE
	sprite.flip_h = false
	sprite.animation = _facing_animation
	sprite.play(_facing_animation)


func _update_facing(direction: Vector2) -> void:
	if not is_instance_valid(sprite) or direction.is_zero_approx():
		return
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	sprite.flip_h = false
	if sprite.animation != _facing_animation or not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_navigation() -> void:
	_init_floor_layer_and_mask()

	var map_width := 1800.0
	var map_height := 900.0

	if _floor_mask != null:
		map_width = float(_floor_mask.get_width())
		map_height = float(_floor_mask.get_height())

	var columns := ceili(map_width / NAV_CELL_SIZE)
	var rows := ceili(map_height / NAV_CELL_SIZE)
	_grid_region = Rect2i(Vector2i.ZERO, Vector2i(columns, rows))
	_grid.region = _grid_region
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.update()

	var space_state := get_world_2d().direct_space_state if is_inside_tree() else null
	var probe_query: PhysicsShapeQueryParameters2D = null
	if space_state != null:
		probe_query = PhysicsShapeQueryParameters2D.new()
		var probe_shape := CircleShape2D.new()
		probe_shape.radius = NAV_CLEARANCE_RADIUS
		probe_query.shape = probe_shape
		probe_query.collision_mask = 1
		probe_query.exclude = [get_rid()]

	_roam_cells.clear()
	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)

			if _floor_mask != null and not _position_is_walkable(center, false):
				_grid.set_point_solid(cell, true)
				continue

			if is_inside_tree():
				var door_blocked := false
				for door in get_tree().get_nodes_in_group("ship_door"):
					if door.get("locked") and door.has_method("blocks_position") and bool(door.call("blocks_position", center, BODY_RADIUS)):
						door_blocked = true
						break
				if door_blocked:
					_grid.set_point_solid(cell, true)
					continue

			if space_state != null and probe_query != null:
				probe_query.transform = Transform2D(0.0, center)
				if not space_state.intersect_shape(probe_query, 1).is_empty():
					_grid.set_point_solid(cell, true)
					continue

			_roam_cells.append(cell)

	_navigation_ready = not _roam_cells.is_empty()
