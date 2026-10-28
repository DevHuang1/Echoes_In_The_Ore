class_name ShipPlayer
extends CharacterBody2D

signal equipment_changed(equipped_item_id: StringName, flashlight_active: bool)
signal equipment_used(item_id: StringName)
signal equipment_amount_changed(item_id: StringName, remaining_amount: int)
signal equipment_depleted(item_id: StringName)

const THURA_ATLAS: Texture2D = preload("res://art/characters/runtime/thura_walk_4dir.png")
const THURA_SIT_DOWN: Texture2D = preload("res://art/characters/runtime/thura_sit_down.png")
const WARM_LIGHT_SCENE: PackedScene = preload("res://scenes/ship/props/warm_ship_light.tscn")
const CELL_SIZE: Vector2 = Vector2(313.5, 313.5)
const SITTING_FRAME_REGION := Rect2i(375, 456, 504, 513)
const ANIMATION_ROWS: Dictionary = {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

# Optional 24-frame (6x4) or 16-frame (4x4) custom walk-cycle sheets if placed in art/characters/runtime/ or art/characters/
const CUSTOM_WALK_SHEET_CANDIDATES: Dictionary = {
	&"engineering_multitool": [
		"res://art/characters/runtime/Thura's 24-Frame Multitool Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_engineering_multitool.png",
		"res://art/characters/Thura's 24-Frame Multitool Walk Cycle.png",
	],
	&"electrical_discharge_tool": [
		"res://art/characters/runtime/Thura walking with two-pronged tool.png",
		"res://art/characters/runtime/thura_walk_electrical_discharge_tool.png",
		"res://art/characters/Thura walking with two-pronged tool.png",
	],
	&"captains_revolver": [
		"res://art/characters/runtime/Thura’s Revolver Walk Cycle.png",
		"res://art/characters/runtime/Thura's Revolver Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_captains_revolver.png",
		"res://art/characters/Thura’s Revolver Walk Cycle.png",
	],
	&"mineral_survey_scanner": [
		"res://art/characters/runtime/Thura's 24-frame scanner walk sheet.png",
		"res://art/characters/runtime/thura_walk_mineral_survey_scanner.png",
		"res://art/characters/Thura's 24-frame scanner walk sheet.png",
	],
	&"suit_flashlight": [
		"res://art/characters/runtime/Walking sprites with restored shoulder flashlights.png",
		"res://art/characters/runtime/thura_walk_suit_flashlight.png",
		"res://art/characters/Walking sprites with restored shoulder flashlights.png",
	],
	&"industrial_plasma_cutter": [
		"res://art/characters/runtime/Thura’s 24-Frame Plasma Cutter Walk Cycle.png",
		"res://art/characters/runtime/Thura's 24-Frame Plasma Cutter Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_industrial_plasma_cutter.png",
		"res://art/characters/Thura’s 24-Frame Plasma Cutter Walk Cycle.png",
	],
	&"survey_beacon": [
		"res://art/characters/runtime/Thura’s Survey Beacon Walk Cycle.png",
		"res://art/characters/runtime/Thura's Survey Beacon Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_survey_beacon.png",
		"res://art/characters/Thura’s Survey Beacon Walk Cycle.png",
	],
	&"medical_injector": [
		"res://art/characters/runtime/Thura’s Medical Injector Walk Cycle.png",
		"res://art/characters/runtime/Thura's Medical Injector Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_medical_injector.png",
		"res://art/characters/Thura’s Medical Injector Walk Cycle.png",
	],
	&"pressure_sealant": [
		"res://art/characters/runtime/Thura’s Pixel-Art Torch Walk Cycle.png",
		"res://art/characters/runtime/Thura's Pixel-Art Torch Walk Cycle.png",
		"res://art/characters/runtime/thura_walk_pressure_sealant.png",
		"res://art/characters/Thura’s Pixel-Art Torch Walk Cycle.png",
	],
	&"emergency_flare": [
		"res://art/characters/runtime/Thura Walking With an Unlit Flare.png",
		"res://art/characters/runtime/thura_walk_emergency_flare.png",
		"res://art/characters/Thura Walking With an Unlit Flare.png",
	],
}

# Built-in directional held-equipment visual definitions
const HELD_EQUIPMENT_VISUALS: Dictionary = {
	&"captains_revolver": {
		"texture": preload("res://art/tools/captains_revolver.png"),
		"region": Rect2i(35, 292, 960, 880),
		"scale": Vector2(0.16, 0.16),
		"glow_color": Color(1.0, 0.72, 0.34, 0.85),
		"light_energy": 0.18,
		"light_scale": 0.42,
	},
	&"industrial_plasma_cutter": {
		"texture": preload("res://art/tools/industrial_plasma_cutter.png"),
		"region": Rect2i(89, 340, 840, 650),
		"scale": Vector2(0.19, 0.19),
		"glow_color": Color(0.38, 0.94, 1.0, 0.94),
		"light_energy": 0.32,
		"light_scale": 0.56,
	},
	&"engineering_multitool": {
		"texture": preload("res://art/tools/engineering_multitool.png"),
		"region": Rect2i(45, 335, 930, 790),
		"scale": Vector2(0.17, 0.17),
		"glow_color": Color(0.38, 0.88, 1.0, 0.88),
		"light_energy": 0.24,
		"light_scale": 0.46,
	},
	&"mineral_survey_scanner": {
		"texture": preload("res://art/tools/mineral_survey_scanner.png"),
		"region": Rect2i(90, 232, 850, 940),
		"scale": Vector2(0.16, 0.16),
		"glow_color": Color(0.32, 0.94, 1.0, 0.92),
		"light_energy": 0.28,
		"light_scale": 0.52,
	},
	&"electrical_discharge_tool": {
		"texture": preload("res://art/tools/electrical_discharge_tool.png"),
		"region": Rect2i(100, 410, 860, 710),
		"scale": Vector2(0.18, 0.18),
		"glow_color": Color(0.45, 0.90, 1.0, 0.95),
		"light_energy": 0.34,
		"light_scale": 0.56,
	},
	&"survey_beacon": {
		"texture": preload("res://art/tools/survey_beacon.png"),
		"region": Rect2i(100, 350, 830, 780),
		"scale": Vector2(0.16, 0.16),
		"glow_color": Color(1.0, 0.78, 0.28, 0.92),
		"light_energy": 0.36,
		"light_scale": 0.62,
	},
	&"pressure_sealant": {
		"texture": preload("res://art/tools/pressure_sealant.png"),
		"region": Rect2i(150, 390, 740, 780),
		"scale": Vector2(0.17, 0.17),
		"glow_color": Color(0.38, 0.88, 1.0, 0.85),
		"light_energy": 0.22,
		"light_scale": 0.46,
	},
	&"medical_injector": {
		"texture": preload("res://art/tools/medical_injector.png"),
		"region": Rect2i(180, 250, 760, 925),
		"scale": Vector2(0.15, 0.15),
		"glow_color": Color(0.34, 0.96, 0.68, 0.88),
		"light_energy": 0.20,
		"light_scale": 0.42,
	},
	&"emergency_flare": {
		"texture": preload("res://art/tools/emergency_flare.png"),
		"region": Rect2i(220, 225, 740, 940),
		"scale": Vector2(0.15, 0.15),
		"glow_color": Color(1.0, 0.46, 0.20, 0.96),
		"light_energy": 0.52,
		"light_scale": 0.78,
	},
	&"suit_flashlight": {
		"texture": preload("res://art/tools/suit_flashlight.png"),
		"region": Rect2i(65, 360, 900, 620),
		"scale": Vector2(0.15, 0.15),
		"glow_color": Color(1.0, 0.95, 0.82, 0.95),
		"light_energy": 0.48,
		"light_scale": 0.74,
	},
}

const CONTINUOUS_TOOLS: Array[StringName] = [
	&"industrial_plasma_cutter",
	&"engineering_multitool",
	&"electrical_discharge_tool",
	&"pressure_sealant",
]

const LIMITED_EQUIPMENT: Dictionary = {
	&"emergency_flare": {
		"default": 5,
		"max": 10,
	},
	&"captains_revolver": {
		"default": 6,
		"max": 18,
	},
	&"survey_beacon": {
		"default": 3,
		"max": 6,
	},
	&"medical_injector": {
		"default": 3,
		"max": 5,
	},
	&"pressure_sealant": {
		"default": 50,
		"max": 100,
	},
}

@export var move_speed: float = 150.0
@export var sprite_scale: Vector2 = Vector2(0.12, 0.12)

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing_animation: StringName = &"walk_down"
var _camera_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1774.0, 887.0))
var _walkable_floor_mask: Image = null
var _walkable_floor_origin: Vector2 = Vector2.ZERO
var _walkable_body_margin: float = 8.0

var _default_frames: SpriteFrames = null
var _custom_frames_cache: Dictionary = {}
var _held_tool_tex_cache: Dictionary = {}
var _using_custom_walk_sheet: bool = false

var _equipped_item_id: StringName = &""
var _suit_flashlight_unlocked: bool = false
var _suit_flashlight_enabled: bool = false
var _held_item_sprite: Sprite2D = null
var _fx_overlay: Node2D = null
var _world_fx_canvas: Node2D = null
var _equipment_light: PointLight2D = null
var _action_impact_light: PointLight2D = null
var _flashlight_light: PointLight2D = null
var _equip_anim_timer: float = 0.0
var _pulse_time: float = 0.0

# Shooting, laser beam, flare projectile, and working animation state for all 10 equipments
var _is_using_tool: bool = false
var _touch_shoot_held: bool = false
var _use_aim_mouse: bool = false
var _aim_dir: Vector2 = Vector2.DOWN
var _action_cooldown: float = 0.0
var _action_anim_timer: float = 0.0
var _action_anim_duration: float = 0.45
var _recoil_amount: float = 0.0
var _flashlight_overcharge_timer: float = 0.0
var _laser_beam_length: float = 160.0
var _spray_emit_accum: float = 0.0

# World-space projectiles, ejected brass casings, burning floor flares, deployed survey beacons, and sealant foam
var _bullet_tracers: Array[Dictionary] = []
var _shell_casings: Array[Dictionary] = []
var _flying_flares: Array[Dictionary] = []
var _burning_flares: Array[Dictionary] = []
var _deployed_beacons: Array[Dictionary] = []
var _sealant_patches: Array[Dictionary] = []
var _scanner_waves: Array[Dictionary] = []
var _med_particles: Array[Dictionary] = []
var _standing_sprite_scale: Vector2 = Vector2.ONE
var _standing_sprite_position: Vector2 = Vector2.ZERO
var _sitting_pose_active: bool = false
var _walkable_blocker_polygons: Array[PackedVector2Array] = []
var _equipment_amounts: Dictionary = {}


func is_item_limited(item_id: StringName) -> bool:
	return LIMITED_EQUIPMENT.has(item_id)


func get_equipment_amount(item_id: StringName) -> int:
	if not LIMITED_EQUIPMENT.has(item_id):
		return -1
	if not _equipment_amounts.has(item_id):
		_equipment_amounts[item_id] = LIMITED_EQUIPMENT[item_id]["default"]
	return int(_equipment_amounts[item_id])


func get_equipment_max_amount(item_id: StringName) -> int:
	if not LIMITED_EQUIPMENT.has(item_id):
		return -1
	return int(LIMITED_EQUIPMENT[item_id]["max"])


func set_equipment_amount(item_id: StringName, amount: int) -> void:
	if not LIMITED_EQUIPMENT.has(item_id):
		return
	var max_amt: int = int(LIMITED_EQUIPMENT[item_id]["max"])
	_equipment_amounts[item_id] = clampi(amount, 0, max_amt)
	equipment_amount_changed.emit(item_id, _equipment_amounts[item_id])
	_update_equipment_transform()


func has_ammo_for_item(item_id: StringName) -> bool:
	if not LIMITED_EQUIPMENT.has(item_id):
		return true
	return get_equipment_amount(item_id) > 0


func consume_item_amount(item_id: StringName, count: int = 1) -> bool:
	if not LIMITED_EQUIPMENT.has(item_id):
		return true
	var cur: int = get_equipment_amount(item_id)
	if cur < count:
		equipment_depleted.emit(item_id)
		return false
	_equipment_amounts[item_id] = cur - count
	equipment_amount_changed.emit(item_id, _equipment_amounts[item_id])
	if _equipment_amounts[item_id] <= 0:
		equipment_depleted.emit(item_id)
	_update_equipment_transform()
	return true


func sync_equipment_amounts(amounts: Dictionary) -> void:
	for k in amounts:
		_equipment_amounts[k] = int(amounts[k])
	_update_equipment_transform()


func _ready() -> void:
	add_to_group("ship_player")
	_configure_sprite_animations()
	_setup_equipment_visual_nodes()
	_apply_equipped_visuals()
	sprite.scale = sprite_scale
	_standing_sprite_scale = sprite.scale
	_standing_sprite_position = sprite.position
	sprite.play(_facing_animation)
	sprite.stop()
	if is_instance_valid(camera):
		camera.enabled = true
		camera.make_current()
	get_viewport().size_changed.connect(_update_camera_limits)
	_update_camera_limits()


func _setup_equipment_visual_nodes() -> void:
	_held_item_sprite = Sprite2D.new()
	_held_item_sprite.name = "HeldEquipmentSprite"
	_held_item_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_held_item_sprite.visible = false
	add_child(_held_item_sprite)

	_fx_overlay = Node2D.new()
	_fx_overlay.name = "EquipmentFxOverlay"
	_fx_overlay.z_index = 2
	_fx_overlay.draw.connect(_on_fx_overlay_draw)
	add_child(_fx_overlay)

	_world_fx_canvas = Node2D.new()
	_world_fx_canvas.name = "EquipmentWorldFxCanvas"
	_world_fx_canvas.top_level = true
	_world_fx_canvas.z_as_relative = false
	_world_fx_canvas.z_index = 2
	_world_fx_canvas.draw.connect(_on_world_fx_draw)
	add_child(_world_fx_canvas)

	_equipment_light = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	_equipment_light.name = "EquippedToolLight"
	_equipment_light.enabled = false
	_equipment_light.energy = 0.0
	add_child(_equipment_light)

	_action_impact_light = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	_action_impact_light.name = "ActionImpactLight"
	_action_impact_light.top_level = true
	_action_impact_light.enabled = false
	_action_impact_light.energy = 0.0
	add_child(_action_impact_light)

	_flashlight_light = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	_flashlight_light.name = "SuitFlashlightPoint"
	_flashlight_light.color = Color(0.96, 0.94, 0.84, 1.0)
	_flashlight_light.energy = 0.34
	_flashlight_light.texture_scale = 0.68
	_flashlight_light.enabled = _suit_flashlight_enabled
	add_child(_flashlight_light)

	_update_equipment_transform()


func _physics_process(delta: float) -> void:
	_pulse_time = fposmod(_pulse_time + delta * 4.5, 1000.0)
	if _equip_anim_timer > 0.0:
		_equip_anim_timer = maxf(_equip_anim_timer - delta * 4.2, 0.0)
	if _action_cooldown > 0.0:
		_action_cooldown = maxf(_action_cooldown - delta, 0.0)
	if _action_anim_timer > 0.0:
		_action_anim_timer = maxf(_action_anim_timer - delta, 0.0)
	if _recoil_amount > 0.0:
		_recoil_amount = maxf(_recoil_amount - delta * 5.2, 0.0)
	if _flashlight_overcharge_timer > 0.0:
		_flashlight_overcharge_timer = maxf(_flashlight_overcharge_timer - delta, 0.0)

	var direction: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var joy_vec: Vector2 = Engine.get_meta(&"echoes_mobile_joystick_vec", Vector2.ZERO) if Engine.has_meta(&"echoes_mobile_joystick_vec") else Vector2.ZERO
	if joy_vec.length_squared() > direction.length_squared():
		direction = joy_vec
	var movement: Vector2 = direction * move_speed * delta
	if _has_walkable_floor_mask():
		_move_on_walkable_floor(movement)
	elif not movement.is_zero_approx():
		move_and_collide(movement)
	if direction.length_squared() > 0.0:
		if not _is_using_tool or not _use_aim_mouse:
			_update_facing(direction)
		if not sprite.is_playing():
			sprite.play(_facing_animation)
	elif sprite.is_playing():
		sprite.stop()
		sprite.frame = 0

	_update_continuous_tool_action(delta)
	_update_world_projectiles_and_deployables(delta)
	_update_equipment_transform()
	if is_instance_valid(_fx_overlay):
		_fx_overlay.queue_redraw()
	if is_instance_valid(_world_fx_canvas):
		_world_fx_canvas.queue_redraw()


func set_touch_shoot_held(held: bool) -> void:
	_touch_shoot_held = held
	if held:
		start_using_equipment(false)
	else:
		stop_using_equipment()


func start_using_equipment(aim_at_mouse: bool = true) -> void:
	_use_aim_mouse = aim_at_mouse
	if _use_aim_mouse:
		var to_mouse: Vector2 = get_global_mouse_position() - global_position
		if to_mouse.length_squared() > 4.0:
			_aim_dir = to_mouse.normalized()
			_update_facing(_aim_dir)
	else:
		var joy_vec: Vector2 = Engine.get_meta(&"echoes_mobile_joystick_vec", Vector2.ZERO) if Engine.has_meta(&"echoes_mobile_joystick_vec") else Vector2.ZERO
		if joy_vec.length_squared() > 0.04:
			_aim_dir = joy_vec.normalized()
			_update_facing(_aim_dir)
		else:
			_aim_dir = _get_facing_vector()

	var active_tool: StringName = _equipped_item_id
	if active_tool == &"":
		if _suit_flashlight_unlocked:
			if not _suit_flashlight_enabled:
				set_suit_flashlight_enabled(true)
			_flashlight_overcharge_timer = 1.8
			_action_anim_duration = 1.8
			_action_anim_timer = 1.8
			equipment_used.emit(&"suit_flashlight")
		return

	_is_using_tool = true
	if CONTINUOUS_TOOLS.has(active_tool):
		if active_tool == &"pressure_sealant" and not has_ammo_for_item(&"pressure_sealant"):
			_is_using_tool = false
			_action_cooldown = 0.35
			equipment_depleted.emit(&"pressure_sealant")
			return
		_action_anim_duration = 0.35
		_action_anim_timer = 0.35
		equipment_used.emit(active_tool)
		return

	if _action_cooldown > 0.0:
		return

	match active_tool:
		&"captains_revolver":
			if not has_ammo_for_item(&"captains_revolver"):
				_action_cooldown = 0.35
				equipment_depleted.emit(&"captains_revolver")
				return
			_fire_captains_revolver()
			consume_item_amount(&"captains_revolver", 1)
		&"emergency_flare":
			if not has_ammo_for_item(&"emergency_flare"):
				_action_cooldown = 0.35
				equipment_depleted.emit(&"emergency_flare")
				return
			_shoot_emergency_flare()
			consume_item_amount(&"emergency_flare", 1)
		&"mineral_survey_scanner":
			_trigger_mineral_scanner()
		&"survey_beacon":
			if not has_ammo_for_item(&"survey_beacon"):
				_action_cooldown = 0.35
				equipment_depleted.emit(&"survey_beacon")
				return
			_deploy_survey_beacon()
			consume_item_amount(&"survey_beacon", 1)
		&"medical_injector":
			if not has_ammo_for_item(&"medical_injector"):
				_action_cooldown = 0.35
				equipment_depleted.emit(&"medical_injector")
				return
			_trigger_medical_injector()
			consume_item_amount(&"medical_injector", 1)
		&"suit_flashlight":
			if not _suit_flashlight_enabled:
				set_suit_flashlight_enabled(true)
			_flashlight_overcharge_timer = 2.0
			_action_anim_duration = 2.0
			_action_anim_timer = 2.0
			_action_cooldown = 0.45
	equipment_used.emit(active_tool)


func stop_using_equipment() -> void:
	_is_using_tool = false
	_touch_shoot_held = false


func is_using_equipment() -> bool:
	return _is_using_tool or _action_anim_timer > 0.01


func get_active_illumination_points() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	# 1. Flying flare projectiles light up rooms they pass through
	for ff in _flying_flares:
		var fpos: Vector2 = ff["pos"]
		pts.append(fpos)
	# 2. Burning floor flares light up the room where they land!
	for bf in _burning_flares:
		var bpos: Vector2 = bf["pos"]
		pts.append(bpos)
	# 3. Deployed survey beacons light up the room where they are placed
	for db in _deployed_beacons:
		var dpos: Vector2 = db["pos"]
		pts.append(dpos)
	# 4. Active weapon muzzle flash, plasma laser beam endpoint, electrical arc, or overcharged flashlight beam
	if is_instance_valid(_action_impact_light) and _action_impact_light.enabled:
		pts.append(_action_impact_light.global_position)
	if _flashlight_overcharge_timer > 0.01 and _suit_flashlight_enabled:
		pts.append(global_position + _get_facing_vector() * 72.0)
	if _equipped_item_id == &"emergency_flare" and get_equipment_amount(&"emergency_flare") > 0:
		pts.append(global_position)
	return pts


func _raycast_floor_distance(start_world: Vector2, dir: Vector2, max_dist: float) -> float:
	if not _has_walkable_floor_mask():
		return max_dist
	var step: float = 6.0
	var d: float = 12.0
	while d <= max_dist:
		var test_pt: Vector2 = start_world + dir * d
		if not _is_point_clear_for_beam(test_pt):
			return maxf(d - step, 10.0)
		d += step
	return max_dist


func _is_point_clear_for_beam(world_pt: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", world_pt, 2.0)):
			return false
	if not _has_walkable_floor_mask():
		return true
	var sample: Vector2 = world_pt - _walkable_floor_origin
	var px: int = floori(sample.x)
	var py: int = floori(sample.y)
	if px < 0 or py < 0 or px >= _walkable_floor_mask.get_width() or py >= _walkable_floor_mask.get_height():
		return false
	return _walkable_floor_mask.get_pixel(px, py).a >= 0.15


func _get_muzzle_world_pos() -> Vector2:
	if is_instance_valid(_held_item_sprite) and _held_item_sprite.visible:
		return _held_item_sprite.global_position + _aim_dir * 9.0
	return global_position + _aim_dir * 12.0 + Vector2(0.0, -2.0)


func _fire_captains_revolver() -> void:
	_action_cooldown = 0.28
	_action_anim_duration = 0.26
	_action_anim_timer = 0.26
	_recoil_amount = 1.0

	var muzzle_pos: Vector2 = _get_muzzle_world_pos()
	var hit_dist: float = _raycast_floor_distance(muzzle_pos, _aim_dir, 285.0)
	var hit_pos: Vector2 = muzzle_pos + _aim_dir * hit_dist

	_bullet_tracers.append({
		"start": muzzle_pos,
		"end": hit_pos,
		"timer": 0.22,
		"max_timer": 0.22,
		"dir": _aim_dir,
	})

	var perp: Vector2 = Vector2(-_aim_dir.y, _aim_dir.x)
	var eject_vel: Vector2 = (-_aim_dir * 26.0 + perp * 42.0) + Vector2(0.0, -34.0)
	_shell_casings.append({
		"pos": muzzle_pos - _aim_dir * 4.0,
		"vel": eject_vel,
		"rot": 0.0,
		"timer": 1.6,
	})


func _shoot_emergency_flare() -> void:
	_action_cooldown = 0.48
	_action_anim_duration = 0.38
	_action_anim_timer = 0.38
	_recoil_amount = 0.65

	var start_pos: Vector2 = _get_muzzle_world_pos()
	var max_throw: float = 175.0
	if _use_aim_mouse:
		var mouse_dist: float = start_pos.distance_to(get_global_mouse_position())
		max_throw = clampf(mouse_dist, 48.0, 210.0)
	var travel_dist: float = _raycast_floor_distance(start_pos, _aim_dir, max_throw)
	var target_pos: Vector2 = start_pos + _aim_dir * maxf(travel_dist - 8.0, 16.0)

	var flare_light: PointLight2D = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	flare_light.top_level = true
	flare_light.global_position = start_pos
	flare_light.color = Color(1.0, 0.46, 0.18, 1.0)
	flare_light.energy = 0.92
	flare_light.texture_scale = 1.38
	flare_light.enabled = true
	add_child(flare_light)

	_flying_flares.append({
		"start": start_pos,
		"target": target_pos,
		"pos": start_pos,
		"progress": 0.0,
		"duration": clampf(travel_dist / 290.0, 0.22, 0.58),
		"light": flare_light,
	})


func _trigger_mineral_scanner() -> void:
	_action_cooldown = 0.55
	_action_anim_duration = 0.95
	_action_anim_timer = 0.95

	var origin_pos: Vector2 = _get_muzzle_world_pos()
	var pings: Array[Vector2] = []
	var parent_node: Node = get_parent()
	if parent_node != null:
		_collect_scan_targets_recursive(parent_node, origin_pos, pings)

	_scanner_waves.append({
		"origin": origin_pos,
		"dir": _aim_dir,
		"timer": 1.15,
		"max_timer": 1.15,
		"pings": pings,
	})


func _collect_scan_targets_recursive(node: Node, origin_pos: Vector2, out_pings: Array[Vector2]) -> void:
	if out_pings.size() >= 10:
		return
	for child in node.get_children():
		if child == self:
			continue
		var n2d: Node2D = child as Node2D
		if n2d != null:
			var cname: String = child.name
			if cname.begins_with("Vent_") or cname.find("Door") != -1 or cname.find("Locker") != -1 or cname.find("Rack") != -1 or cname.find("Manifold") != -1 or cname.find("Turbine") != -1 or cname.find("Bundle") != -1:
				var d: float = n2d.global_position.distance_to(origin_pos)
				if d > 16.0 and d <= 185.0:
					var to_target: Vector2 = (n2d.global_position - origin_pos).normalized()
					if to_target.dot(_aim_dir) >= 0.35:
						out_pings.append(n2d.global_position)
		_collect_scan_targets_recursive(child, origin_pos, out_pings)


func _deploy_survey_beacon() -> void:
	_action_cooldown = 0.65
	_action_anim_duration = 0.55
	_action_anim_timer = 0.55

	var deploy_dist: float = _raycast_floor_distance(global_position, _aim_dir, 28.0)
	var deploy_pos: Vector2 = global_position + _aim_dir * maxf(deploy_dist * 0.75, 14.0)

	# Keep at most 3 deployed beacons active at once
	if _deployed_beacons.size() >= 3:
		var oldest: Dictionary = _deployed_beacons.pop_front()
		var old_light: PointLight2D = oldest["light"] as PointLight2D
		if is_instance_valid(old_light):
			old_light.queue_free()

	var b_light: PointLight2D = WARM_LIGHT_SCENE.instantiate() as PointLight2D
	b_light.top_level = true
	b_light.global_position = deploy_pos
	b_light.color = Color(1.0, 0.78, 0.28, 1.0)
	b_light.energy = 0.72
	b_light.texture_scale = 1.18
	b_light.enabled = true
	add_child(b_light)

	_deployed_beacons.append({
		"pos": deploy_pos,
		"timer": 22.0,
		"max_timer": 22.0,
		"light": b_light,
	})


func _trigger_medical_injector() -> void:
	_action_cooldown = 0.70
	_action_anim_duration = 0.85
	_action_anim_timer = 0.85
	for i in range(8):
		var ang: float = float(i) * (TAU / 8.0)
		_med_particles.append({
			"pos": global_position + Vector2(cos(ang) * 10.0, sin(ang) * 6.0 - 4.0),
			"vel": Vector2(cos(ang) * 8.0, -22.0 - float(i % 3) * 6.0),
			"timer": 0.95,
			"max_timer": 0.95,
		})


func _update_continuous_tool_action(delta: float) -> void:
	var mouse_held: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var space_held: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed(&"shoot")
	if _is_using_tool and not mouse_held and not space_held and not _touch_shoot_held:
		_is_using_tool = false

	if _is_using_tool:
		var joy_vec: Vector2 = Engine.get_meta(&"echoes_mobile_joystick_vec", Vector2.ZERO) if Engine.has_meta(&"echoes_mobile_joystick_vec") else Vector2.ZERO
		if _use_aim_mouse and mouse_held and not _touch_shoot_held:
			var to_mouse: Vector2 = get_global_mouse_position() - global_position
			if to_mouse.length_squared() > 4.0:
				_aim_dir = to_mouse.normalized()
				_update_facing(_aim_dir)
		elif joy_vec.length_squared() > 0.04:
			_aim_dir = joy_vec.normalized()
			_update_facing(_aim_dir)
		else:
			_aim_dir = _get_facing_vector()

		if _touch_shoot_held and not CONTINUOUS_TOOLS.has(_equipped_item_id) and _action_cooldown <= 0.0:
			start_using_equipment(false)

		if CONTINUOUS_TOOLS.has(_equipped_item_id):
			_action_anim_duration = 0.25
			_action_anim_timer = 0.25

			if _equipped_item_id == &"industrial_plasma_cutter":
				var muzzle: Vector2 = _get_muzzle_world_pos()
				_laser_beam_length = _raycast_floor_distance(muzzle, _aim_dir, 235.0)
			elif _equipped_item_id == &"pressure_sealant":
				if not has_ammo_for_item(&"pressure_sealant"):
					_is_using_tool = false
					_action_anim_timer = 0.0
					equipment_depleted.emit(&"pressure_sealant")
					return
				_spray_emit_accum += delta
				if _spray_emit_accum >= 0.08:
					_spray_emit_accum = 0.0
					consume_item_amount(&"pressure_sealant", 1)
					var muzzle_s: Vector2 = _get_muzzle_world_pos()
					var max_d: float = _raycast_floor_distance(muzzle_s, _aim_dir, 72.0)
					var d_rand: float = clampf(22.0 + fposmod(_pulse_time * 37.0, maxf(max_d - 18.0, 12.0)), 14.0, max_d)
					var spread_ang: float = (fposmod(sin(_pulse_time * 43.0) * 97.3, 1.0) - 0.5) * 0.45
					var s_dir: Vector2 = _aim_dir.rotated(spread_ang)
					_sealant_patches.append({
						"pos": muzzle_s + s_dir * d_rand,
						"radius": 4.2 + fposmod(_pulse_time * 13.0, 3.8),
						"timer": 5.5,
						"max_timer": 5.5,
					})
					if _sealant_patches.size() > 28:
						_sealant_patches.pop_front()


func _update_world_projectiles_and_deployables(delta: float) -> void:
	# 1. Bullet tracers
	var i: int = _bullet_tracers.size() - 1
	while i >= 0:
		var bt: Dictionary = _bullet_tracers[i]
		var t: float = float(bt["timer"]) - delta
		if t <= 0.0:
			_bullet_tracers.remove_at(i)
		else:
			bt["timer"] = t
		i -= 1

	# 2. Ejected brass shell casings
	i = _shell_casings.size() - 1
	while i >= 0:
		var sc: Dictionary = _shell_casings[i]
		var t: float = float(sc["timer"]) - delta
		if t <= 0.0:
			_shell_casings.remove_at(i)
		else:
			sc["timer"] = t
			if t > 1.15:
				var vel: Vector2 = sc["vel"]
				vel.y += 140.0 * delta
				var sc_pos: Vector2 = sc["pos"]
				sc["pos"] = sc_pos + vel * delta
				sc["vel"] = vel
				sc["rot"] = float(sc["rot"]) + delta * 18.0
		i -= 1

	# 3. Flying flare projectiles -> transition to burning floor flares on impact!
	i = _flying_flares.size() - 1
	while i >= 0:
		var ff: Dictionary = _flying_flares[i]
		var dur: float = maxf(float(ff["duration"]), 0.1)
		var prog: float = float(ff["progress"]) + delta / dur
		var start_p: Vector2 = ff["start"]
		var target_p: Vector2 = ff["target"]
		var f_light: PointLight2D = ff["light"] as PointLight2D
		if prog >= 1.0:
			if is_instance_valid(f_light):
				f_light.global_position = target_p
				f_light.energy = 0.95
				f_light.texture_scale = 1.48
			_burning_flares.append({
				"pos": target_p,
				"timer": 20.0,
				"max_timer": 20.0,
				"light": f_light,
				"seed": float(_burning_flares.size()) * 1.7 + _pulse_time,
			})
			if _burning_flares.size() > 5:
				var oldest_f: Dictionary = _burning_flares.pop_front()
				var old_l: PointLight2D = oldest_f["light"] as PointLight2D
				if is_instance_valid(old_l):
					old_l.queue_free()
			_flying_flares.remove_at(i)
		else:
			ff["progress"] = prog
			var arc_h: float = sin(prog * PI) * 18.0
			var cur_pos: Vector2 = start_p.lerp(target_p, prog) + Vector2(0.0, -arc_h)
			ff["pos"] = cur_pos
			if is_instance_valid(f_light):
				f_light.global_position = cur_pos
		i -= 1

	# 4. Burning floor flares (sputter & light up the room for 20s)
	i = _burning_flares.size() - 1
	while i >= 0:
		var bf: Dictionary = _burning_flares[i]
		var t: float = float(bf["timer"]) - delta
		var f_light: PointLight2D = bf["light"] as PointLight2D
		if t <= 0.0:
			if is_instance_valid(f_light):
				f_light.queue_free()
			_burning_flares.remove_at(i)
		else:
			bf["timer"] = t
			if is_instance_valid(f_light):
				var fade_out: float = clampf(t / 2.5, 0.0, 1.0)
				var flicker: float = 0.88 + 0.18 * sin(_pulse_time * 4.5 + float(bf["seed"]))
				f_light.energy = 0.95 * fade_out * flicker
		i -= 1

	# 5. Deployed survey beacons
	i = _deployed_beacons.size() - 1
	while i >= 0:
		var db: Dictionary = _deployed_beacons[i]
		var t: float = float(db["timer"]) - delta
		var b_light: PointLight2D = db["light"] as PointLight2D
		if t <= 0.0:
			if is_instance_valid(b_light):
				b_light.queue_free()
			_deployed_beacons.remove_at(i)
		else:
			db["timer"] = t
			if is_instance_valid(b_light):
				var fade_out: float = clampf(t / 2.0, 0.0, 1.0)
				var pulse: float = 0.78 + 0.26 * (0.5 + 0.5 * sin(_pulse_time * 2.2))
				b_light.energy = 0.72 * fade_out * pulse
		i -= 1

	# 6. Sealant foam patches
	i = _sealant_patches.size() - 1
	while i >= 0:
		var sp: Dictionary = _sealant_patches[i]
		var t: float = float(sp["timer"]) - delta
		if t <= 0.0:
			_sealant_patches.remove_at(i)
		else:
			sp["timer"] = t
		i -= 1

	# 7. Scanner waves
	i = _scanner_waves.size() - 1
	while i >= 0:
		var sw: Dictionary = _scanner_waves[i]
		var t: float = float(sw["timer"]) - delta
		if t <= 0.0:
			_scanner_waves.remove_at(i)
		else:
			sw["timer"] = t
		i -= 1

	# 8. Medical bio-stim particles
	i = _med_particles.size() - 1
	while i >= 0:
		var mp: Dictionary = _med_particles[i]
		var t: float = float(mp["timer"]) - delta
		if t <= 0.0:
			_med_particles.remove_at(i)
		else:
			mp["timer"] = t
			var mp_pos: Vector2 = mp["pos"]
			var mp_vel: Vector2 = mp["vel"]
			mp["pos"] = mp_pos + mp_vel * delta
		i -= 1

	# 9. Update dynamic action impact PointLight2D (muzzle flash, laser endpoint, arc flash)
	if is_instance_valid(_action_impact_light):
		if _action_anim_timer > 0.01 and _equipped_item_id == &"industrial_plasma_cutter":
			var muzzle: Vector2 = _get_muzzle_world_pos()
			_action_impact_light.global_position = muzzle + _aim_dir * _laser_beam_length
			_action_impact_light.color = Color(0.38, 0.94, 1.0, 1.0)
			_action_impact_light.energy = 0.82 * (0.85 + 0.20 * sin(_pulse_time * 9.0))
			_action_impact_light.texture_scale = 0.95
			_action_impact_light.enabled = true
		elif _action_anim_timer > 0.01 and _equipped_item_id == &"captains_revolver":
			var muzzle: Vector2 = _get_muzzle_world_pos()
			_action_impact_light.global_position = muzzle + _aim_dir * 20.0
			_action_impact_light.color = Color(1.0, 0.78, 0.36, 1.0)
			_action_impact_light.energy = 0.95 * (_action_anim_timer / maxf(_action_anim_duration, 0.01))
			_action_impact_light.texture_scale = 1.15
			_action_impact_light.enabled = true
		elif _action_anim_timer > 0.01 and _equipped_item_id == &"electrical_discharge_tool":
			var muzzle: Vector2 = _get_muzzle_world_pos()
			_action_impact_light.global_position = muzzle + _aim_dir * 52.0
			_action_impact_light.color = Color(0.48, 0.88, 1.0, 1.0)
			_action_impact_light.energy = 0.78 * (0.65 + 0.35 * sin(_pulse_time * 16.0))
			_action_impact_light.texture_scale = 0.92
			_action_impact_light.enabled = true
		elif _action_anim_timer > 0.01 and _equipped_item_id == &"engineering_multitool":
			var muzzle: Vector2 = _get_muzzle_world_pos()
			_action_impact_light.global_position = muzzle + _aim_dir * 22.0
			_action_impact_light.color = Color(1.0, 0.82, 0.42, 1.0)
			_action_impact_light.energy = 0.56
			_action_impact_light.texture_scale = 0.68
			_action_impact_light.enabled = true
		else:
			_action_impact_light.enabled = false


func equip_item(item_id: StringName) -> void:
	if _equipped_item_id == item_id:
		return
	_is_using_tool = false
	_action_anim_timer = 0.0
	_equipped_item_id = item_id
	_equip_anim_timer = 1.0
	_apply_equipped_visuals()
	equipment_changed.emit(_equipped_item_id, _suit_flashlight_enabled)


func unequip_item() -> void:
	if _equipped_item_id == &"":
		return
	_is_using_tool = false
	_action_anim_timer = 0.0
	_equipped_item_id = &""
	_equip_anim_timer = 1.0
	_apply_equipped_visuals()
	equipment_changed.emit(_equipped_item_id, _suit_flashlight_enabled)


func toggle_equip_item(item_id: StringName) -> StringName:
	if item_id == &"" or _equipped_item_id == item_id:
		unequip_item()
	else:
		equip_item(item_id)
	return _equipped_item_id


func get_equipped_item() -> StringName:
	return _equipped_item_id


func set_suit_flashlight_unlocked(unlocked: bool) -> void:
	_suit_flashlight_unlocked = unlocked
	if not _suit_flashlight_unlocked and _suit_flashlight_enabled:
		set_suit_flashlight_enabled(false)


func is_suit_flashlight_unlocked() -> bool:
	return _suit_flashlight_unlocked


func set_suit_flashlight_enabled(enabled: bool) -> void:
	if enabled and not _suit_flashlight_unlocked:
		return
	_suit_flashlight_enabled = enabled
	if is_instance_valid(_flashlight_light):
		_flashlight_light.enabled = _suit_flashlight_enabled
	_apply_equipped_visuals()
	if is_instance_valid(_fx_overlay):
		_fx_overlay.queue_redraw()
	equipment_changed.emit(_equipped_item_id, _suit_flashlight_enabled)


func toggle_suit_flashlight() -> bool:
	if not _suit_flashlight_unlocked:
		return false
	set_suit_flashlight_enabled(not _suit_flashlight_enabled)
	return _suit_flashlight_enabled


func is_suit_flashlight_enabled() -> bool:
	return _suit_flashlight_enabled


func _apply_equipped_visuals() -> void:
	var was_playing: bool = sprite.is_playing() if is_instance_valid(sprite) else false
	var custom_frames: SpriteFrames = _get_custom_walk_frames(_equipped_item_id)
	if custom_frames != null:
		_using_custom_walk_sheet = true
		if is_instance_valid(sprite):
			sprite.sprite_frames = custom_frames
			sprite.animation = _facing_animation
			if was_playing:
				sprite.play(_facing_animation)
		if is_instance_valid(_held_item_sprite):
			_held_item_sprite.visible = false
	else:
		_using_custom_walk_sheet = false
		if is_instance_valid(sprite):
			if _default_frames != null and sprite.sprite_frames != _default_frames:
				sprite.sprite_frames = _default_frames
				sprite.animation = _facing_animation
				if was_playing:
					sprite.play(_facing_animation)
		if is_instance_valid(_held_item_sprite):
			if _equipped_item_id != &"" and HELD_EQUIPMENT_VISUALS.has(_equipped_item_id):
				var vdef: Dictionary = HELD_EQUIPMENT_VISUALS[_equipped_item_id]
				_held_item_sprite.texture = _get_clean_held_tool_texture(_equipped_item_id, vdef["texture"], vdef["region"])
				_held_item_sprite.scale = vdef["scale"]
				_held_item_sprite.visible = true
			else:
				_held_item_sprite.visible = false

	if is_instance_valid(_equipment_light):
		if _equipped_item_id != &"" and HELD_EQUIPMENT_VISUALS.has(_equipped_item_id):
			var vdef: Dictionary = HELD_EQUIPMENT_VISUALS[_equipped_item_id]
			var gcol: Color = vdef["glow_color"]
			_equipment_light.color = Color(gcol.r, gcol.g, gcol.b, 1.0)
			_equipment_light.energy = float(vdef["light_energy"])
			_equipment_light.texture_scale = float(vdef["light_scale"])
			_equipment_light.enabled = true
		else:
			_equipment_light.enabled = false

	_update_equipment_transform()
	if is_instance_valid(_fx_overlay):
		_fx_overlay.queue_redraw()


func _get_custom_walk_frames(item_id: StringName) -> SpriteFrames:
	var lookup_key: StringName = item_id if item_id != &"" else (&"suit_flashlight" if _suit_flashlight_enabled else &"")
	if lookup_key == &"" or not CUSTOM_WALK_SHEET_CANDIDATES.has(lookup_key):
		return null
	if _custom_frames_cache.has(lookup_key):
		return _custom_frames_cache[lookup_key] as SpriteFrames

	var paths: Array = CUSTOM_WALK_SHEET_CANDIDATES[lookup_key]
	for p in paths:
		var path_str: String = String(p)
		var abs_path: String = ProjectSettings.globalize_path(path_str)
		if not FileAccess.file_exists(abs_path) and not ResourceLoader.exists(path_str):
			continue
		var img: Image = Image.load_from_file(abs_path)
		if (img == null or img.is_empty()) and ResourceLoader.exists(path_str):
			var rtex: Texture2D = load(path_str) as Texture2D
			if rtex != null:
				img = rtex.get_image()
		if img == null or img.is_empty():
			continue

		img.convert(Image.FORMAT_RGBA8)
		var corner_c: Color = img.get_pixel(0, 0)
		if corner_c.a > 0.85 and corner_c.r > 0.90 and corner_c.g > 0.90 and corner_c.b > 0.90:
			var w: int = img.get_width()
			var h: int = img.get_height()
			for y in range(h):
				for x in range(w):
					var px: Color = img.get_pixel(x, y)
					if px.r > 0.93 and px.g > 0.93 and px.b > 0.93:
						img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))

		var sheet_tex: ImageTexture = ImageTexture.create_from_image(img)
		var cols: int = 6 if float(img.get_width()) / float(maxi(img.get_height(), 1)) > 1.25 else 4
		var cell_w: float = float(img.get_width()) / float(cols)
		var cell_h: float = float(img.get_height()) / 4.0

		var frames: SpriteFrames = SpriteFrames.new()
		frames.remove_animation(&"default")
		for animation_name in ANIMATION_ROWS:
			frames.add_animation(animation_name)
			frames.set_animation_speed(animation_name, 10.0 if cols == 6 else 8.0)
			frames.set_animation_loop(animation_name, true)
			var row: int = int(ANIMATION_ROWS[animation_name])
			for col_idx in range(cols):
				var atlas_frame: AtlasTexture = AtlasTexture.new()
				atlas_frame.atlas = sheet_tex
				atlas_frame.region = Rect2(Vector2(float(col_idx) * cell_w, float(row) * cell_h), Vector2(cell_w, cell_h))
				frames.add_frame(animation_name, atlas_frame)
		_custom_frames_cache[lookup_key] = frames
		return frames
	return null


func _get_clean_held_tool_texture(item_id: StringName, src_tex: Texture2D, region: Rect2i) -> Texture2D:
	if _held_tool_tex_cache.has(item_id):
		return _held_tool_tex_cache[item_id] as Texture2D

	var clean_icon_path: String = "res://art/tools/icons/%s.png" % String(item_id)
	var clean_abs_path: String = ProjectSettings.globalize_path(clean_icon_path)
	if FileAccess.file_exists(clean_abs_path):
		var clean_img: Image = Image.load_from_file(clean_abs_path)
		if clean_img != null and not clean_img.is_empty():
			var c_ratio: float = 64.0 / maxf(float(clean_img.get_width()), float(clean_img.get_height()))
			clean_img.resize(
				maxi(1, roundi(float(clean_img.get_width()) * c_ratio)),
				maxi(1, roundi(float(clean_img.get_height()) * c_ratio)),
				Image.INTERPOLATE_LANCZOS
			)
			var clean_tex: ImageTexture = ImageTexture.create_from_image(clean_img)
			_held_tool_tex_cache[item_id] = clean_tex
			return clean_tex

	if src_tex == null:
		return null
	var img: Image = src_tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var crop: Image = img.get_region(region)
	var ratio: float = 64.0 / maxf(float(crop.get_width()), float(crop.get_height()))
	var nw: int = maxi(1, roundi(float(crop.get_width()) * ratio))
	var nh: int = maxi(1, roundi(float(crop.get_height()) * ratio))
	crop.resize(nw, nh, Image.INTERPOLATE_LANCZOS)

	var out_tex: ImageTexture = ImageTexture.create_from_image(crop)
	_held_tool_tex_cache[item_id] = out_tex
	return out_tex


func _get_facing_vector() -> Vector2:
	match _facing_animation:
		&"walk_left":
			return Vector2.LEFT
		&"walk_right":
			return Vector2.RIGHT
		&"walk_up":
			return Vector2.UP
		_:
			return Vector2.DOWN


func _update_equipment_transform() -> void:
	var walk_bob: float = 0.0
	if is_instance_valid(sprite) and sprite.is_playing():
		walk_bob = -1.2 if (sprite.frame % 2 == 1) else 0.8
	var equip_pop: float = sin(_equip_anim_timer * PI) * 0.25

	var hand_offset: Vector2 = Vector2(5.0, 2.0)
	var flip_h_val: bool = false
	var rot_val: float = 0.0
	var z_val: int = 1

	match _facing_animation:
		&"walk_down":
			hand_offset = Vector2(5.5, 3.5 + walk_bob)
			flip_h_val = false
			rot_val = 0.10
			z_val = 1
		&"walk_left":
			hand_offset = Vector2(-8.5, 1.5 + walk_bob)
			flip_h_val = true
			rot_val = -0.06
			z_val = 1
		&"walk_right":
			hand_offset = Vector2(8.5, 1.5 + walk_bob)
			flip_h_val = false
			rot_val = 0.06
			z_val = 1
		&"walk_up":
			hand_offset = Vector2(6.5, -1.5 + walk_bob)
			flip_h_val = false
			rot_val = -0.15
			z_val = -1

	var f_dir: Vector2 = _aim_dir if (_action_anim_timer > 0.01 or _is_using_tool) else _get_facing_vector()

	# Apply weapon recoil kickback or tool working motion to the held item sprite
	var action_offset: Vector2 = Vector2.ZERO
	var action_rot: float = 0.0
	if _recoil_amount > 0.01:
		action_offset = -f_dir * (_recoil_amount * 5.2) + Vector2(0.0, -_recoil_amount * 1.8)
		action_rot = (-0.42 if not flip_h_val else 0.42) * _recoil_amount
	elif _action_anim_timer > 0.01 or _is_using_tool:
		match _equipped_item_id:
			&"industrial_plasma_cutter":
				var aim_angle: float = _aim_dir.angle()
				if flip_h_val:
					action_rot = clampf(wrapf(aim_angle - PI, -PI, PI), -0.85, 0.85)
				else:
					action_rot = clampf(wrapf(aim_angle, -PI, PI), -0.85, 0.85)
				if _is_using_tool:
					action_offset = f_dir * (1.2 + sin(_pulse_time * 26.0) * 0.7)
			&"captains_revolver":
				var aim_angle: float = _aim_dir.angle()
				if flip_h_val:
					action_rot = clampf(wrapf(aim_angle - PI, -PI, PI), -0.75, 0.75)
				else:
					action_rot = clampf(wrapf(aim_angle, -PI, PI), -0.75, 0.75)
			&"engineering_multitool":
				action_offset = f_dir * (2.2 + sin(_pulse_time * 14.0) * 1.2)
				action_rot = sin(_pulse_time * 18.0) * 0.14
			&"electrical_discharge_tool":
				action_offset = f_dir * 3.0
				action_rot = sin(_pulse_time * 22.0) * 0.10
			&"medical_injector":
				var inj_p: float = sin((_action_anim_timer / maxf(_action_anim_duration, 0.01)) * PI)
				action_offset = -hand_offset * (0.45 * inj_p)
				action_rot = 0.35 * inj_p
			&"mineral_survey_scanner":
				var sweep_ang: float = sin(_pulse_time * 3.2) * 0.25
				action_offset = f_dir * 2.5
				action_rot = sweep_ang

	if is_instance_valid(_held_item_sprite):
		_held_item_sprite.position = hand_offset + action_offset
		_held_item_sprite.flip_h = flip_h_val
		_held_item_sprite.rotation = rot_val - equip_pop * 0.45 + action_rot
		_held_item_sprite.z_index = z_val
		if HELD_EQUIPMENT_VISUALS.has(_equipped_item_id):
			var base_sc: Vector2 = HELD_EQUIPMENT_VISUALS[_equipped_item_id]["scale"]
			_held_item_sprite.scale = base_sc * (1.0 + equip_pop)
		if _equipped_item_id == &"emergency_flare":
			_held_item_sprite.visible = (get_equipment_amount(&"emergency_flare") > 0)

	if is_instance_valid(_equipment_light):
		if _equipped_item_id == &"emergency_flare":
			var has_flares: bool = get_equipment_amount(&"emergency_flare") > 0
			_equipment_light.enabled = has_flares
			if has_flares:
				_equipment_light.position = hand_offset + f_dir * 12.0
				var base_e: float = float(HELD_EQUIPMENT_VISUALS[&"emergency_flare"]["light_energy"])
				_equipment_light.energy = base_e * (0.88 + 0.18 * sin(_pulse_time * 3.2))
		elif _equipment_light.enabled:
			_equipment_light.position = hand_offset + f_dir * 12.0

	if is_instance_valid(_flashlight_light):
		_flashlight_light.enabled = _suit_flashlight_enabled
		var boost: float = 1.0 + 1.25 * clampf(_flashlight_overcharge_timer, 0.0, 1.0)
		_flashlight_light.energy = 0.34 * boost
		_flashlight_light.texture_scale = 0.68 * (1.0 + 0.45 * clampf(_flashlight_overcharge_timer, 0.0, 1.0))
		_flashlight_light.position = _get_facing_vector() * (26.0 * boost) + Vector2(0.0, -2.0)


func _on_fx_overlay_draw() -> void:
	if not is_instance_valid(_fx_overlay):
		return
	var f_dir: Vector2 = _aim_dir if (_action_anim_timer > 0.01 or _is_using_tool) else _get_facing_vector()
	var perp: Vector2 = Vector2(-f_dir.y, f_dir.x)

	# 1. Shoulder/Suit Flashlight directional cone when enabled ([F] or overcharged with Left Click / Space)
	if _suit_flashlight_enabled:
		var fl_dir: Vector2 = _get_facing_vector()
		var fl_perp: Vector2 = Vector2(-fl_dir.y, fl_dir.x)
		var origin: Vector2 = fl_dir * 6.0 + Vector2(0.0, -3.0)
		var overcharge: float = clampf(_flashlight_overcharge_timer, 0.0, 1.0)
		var reach: float = 54.0 + 56.0 * overcharge
		var half_spread: float = 20.0 + 14.0 * overcharge
		var p0: Vector2 = origin - fl_perp * 2.5
		var p1: Vector2 = origin + fl_perp * 2.5
		var p2: Vector2 = origin + fl_dir * reach + fl_perp * half_spread
		var p3: Vector2 = origin + fl_dir * reach - fl_perp * half_spread
		_fx_overlay.draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), Color(1.0, 0.96, 0.82, 0.075 + 0.08 * overcharge))
		var mid_p2: Vector2 = origin + fl_dir * (reach * 0.62) + fl_perp * (half_spread * 0.55)
		var mid_p3: Vector2 = origin + fl_dir * (reach * 0.62) - fl_perp * (half_spread * 0.55)
		_fx_overlay.draw_colored_polygon(PackedVector2Array([p0, p1, mid_p2, mid_p3]), Color(1.0, 0.98, 0.88, 0.11 + 0.10 * overcharge))
		_fx_overlay.draw_circle(origin, 1.8 + 1.0 * overcharge, Color(1.0, 0.96, 0.78, 0.85))

	# 2. Passive tool tip glow + Active shooting/working animations for all 10 equipments
	if _equipped_item_id != &"" and HELD_EQUIPMENT_VISUALS.has(_equipped_item_id):
		var vdef: Dictionary = HELD_EQUIPMENT_VISUALS[_equipped_item_id]
		var gcol: Color = vdef["glow_color"]
		var tip_pos: Vector2 = to_local(_get_muzzle_world_pos())
		var pulse: float = 0.75 + 0.25 * sin(_pulse_time * 2.0)
		var flare_depleted: bool = (_equipped_item_id == &"emergency_flare" and get_equipment_amount(&"emergency_flare") <= 0)
		if not flare_depleted:
			_fx_overlay.draw_circle(tip_pos, 3.4 * pulse, Color(gcol.r, gcol.g, gcol.b, 0.22 * pulse))
			_fx_overlay.draw_circle(tip_pos, 1.3, Color(1.0, 0.98, 0.92, 0.75 * pulse))

		if _equipped_item_id == &"emergency_flare" and not flare_depleted:
			# Handheld flare burning flame & sparks
			var fl_flicker: float = 0.80 + 0.30 * sin(_pulse_time * 7.5)
			_fx_overlay.draw_circle(tip_pos, 6.5 * fl_flicker, Color(1.0, 0.35, 0.12, 0.28))
			_fx_overlay.draw_circle(tip_pos, 3.2 * fl_flicker, Color(1.0, 0.72, 0.28, 0.85))
			for s in range(3):
				var sa: float = _pulse_time * 5.0 + float(s) * 2.1
				var sp: Vector2 = tip_pos + Vector2(cos(sa), sin(sa)) * (4.0 + 2.5 * sin(_pulse_time * 9.0 + float(s)))
				_fx_overlay.draw_circle(sp, 0.9, Color(1.0, 0.92, 0.65, 0.85))

		if _action_anim_timer > 0.01:
			var norm_a: float = clampf(_action_anim_timer / maxf(_action_anim_duration, 0.01), 0.0, 1.0)
			match _equipped_item_id:
				&"captains_revolver":
					# Starburst muzzle flash & blast ring at the revolver barrel
					var flash_r: float = 12.0 * norm_a
					_fx_overlay.draw_circle(tip_pos, flash_r * 0.85, Color(1.0, 0.68, 0.22, 0.55 * norm_a))
					_fx_overlay.draw_line(tip_pos, tip_pos + f_dir * (flash_r * 1.7), Color(1.0, 0.95, 0.75, 0.95 * norm_a), 2.8, true)
					_fx_overlay.draw_line(tip_pos - perp * (flash_r * 0.8), tip_pos + perp * (flash_r * 0.8), Color(1.0, 0.84, 0.38, 0.90 * norm_a), 2.2, true)
					_fx_overlay.draw_circle(tip_pos, 3.5 * norm_a, Color(1.0, 0.98, 0.92, norm_a))
					_fx_overlay.draw_arc(tip_pos, (1.0 - norm_a) * 18.0 + 4.0, 0.0, TAU, 16, Color(1.0, 0.76, 0.34, 0.55 * norm_a), 1.4, true)

				&"industrial_plasma_cutter":
					# High-energy continuous laser beam + helical rings + molten impact sparks
					var beam_end: Vector2 = tip_pos + f_dir * _laser_beam_length
					var beam_jit: float = 0.88 + 0.16 * sin(_pulse_time * 18.0)
					_fx_overlay.draw_line(tip_pos, beam_end, Color(0.18, 0.78, 1.0, 0.28 * beam_jit), 8.5, true)
					_fx_overlay.draw_line(tip_pos, beam_end, Color(0.38, 0.94, 1.0, 0.68 * beam_jit), 4.2, true)
					_fx_overlay.draw_line(tip_pos, beam_end, Color(0.96, 1.0, 1.0, 0.96), 1.8, true)

					# Traveling plasma energy nodes along the laser beam
					var d_node: float = fposmod(_pulse_time * 95.0, 26.0)
					while d_node < _laser_beam_length - 6.0:
						var n_pt: Vector2 = tip_pos + f_dir * d_node
						_fx_overlay.draw_circle(n_pt, 2.8, Color(1.0, 0.84, 0.36, 0.72))
						d_node += 26.0

					# Molten cutting impact flare & sparks at laser endpoint
					_fx_overlay.draw_circle(beam_end, 7.5 * beam_jit, Color(1.0, 0.62, 0.22, 0.48))
					_fx_overlay.draw_circle(beam_end, 3.6, Color(1.0, 0.98, 0.90, 0.96))
					for sp_i in range(6):
						var s_ang: float = (-f_dir).angle() + (float(sp_i) - 2.5) * 0.42 + sin(_pulse_time * 15.0 + float(sp_i)) * 0.22
						var s_len: float = 6.0 + 10.0 * fposmod(_pulse_time * 4.5 + float(sp_i) * 0.23, 1.0)
						var sp_end: Vector2 = beam_end + Vector2(cos(s_ang), sin(s_ang)) * s_len
						_fx_overlay.draw_line(beam_end, sp_end, Color(1.0, 0.78, 0.32, 0.88), 1.4, true)
						_fx_overlay.draw_circle(sp_end, 1.1, Color(0.55, 0.96, 1.0, 0.92))

				&"engineering_multitool":
					# Rotary calibration reticle + welding arc + hot sparks
					var work_pt: Vector2 = tip_pos + f_dir * 18.0
					_fx_overlay.draw_line(tip_pos, work_pt, Color(0.42, 0.92, 1.0, 0.85), 2.2, true)
					var rot_a: float = _pulse_time * 4.5
					_fx_overlay.draw_arc(work_pt, 8.5, rot_a, rot_a + 1.8, 10, Color(0.38, 0.92, 1.0, 0.82), 1.5, true)
					_fx_overlay.draw_arc(work_pt, 8.5, rot_a + PI, rot_a + PI + 1.8, 10, Color(1.0, 0.76, 0.28, 0.82), 1.5, true)
					_fx_overlay.draw_circle(work_pt, 2.6, Color(1.0, 0.96, 0.84, 0.95))
					for w_i in range(5):
						var w_ang: float = rot_a * 1.7 + float(w_i) * 1.25
						var w_dist: float = 4.0 + 8.0 * fposmod(_pulse_time * 5.0 + float(w_i) * 0.31, 1.0)
						var w_pt: Vector2 = work_pt + Vector2(cos(w_ang), sin(w_ang)) * w_dist
						_fx_overlay.draw_line(work_pt, w_pt, Color(1.0, 0.82, 0.36, 0.85), 1.2, true)

				&"electrical_discharge_tool":
					# Twin-prong branching high-voltage lightning arcs + EMP ring
					var reach_e: float = 88.0
					for branch in range(3):
						var prev_p: Vector2 = tip_pos + perp * (float(branch - 1) * 3.0)
						for seg in range(1, 7):
							var t_seg: float = float(seg) / 6.0
							var jitter_lat: float = sin(_pulse_time * 24.0 + float(seg) * 2.7 + float(branch) * 1.9) * (9.5 * sin(t_seg * PI))
							var next_p: Vector2 = tip_pos + f_dir * (reach_e * t_seg) + perp * jitter_lat
							_fx_overlay.draw_line(prev_p, next_p, Color(0.35, 0.82, 1.0, 0.45), 3.6, true)
							_fx_overlay.draw_line(prev_p, next_p, Color(0.88, 0.96, 1.0, 0.95), 1.5, true)
							prev_p = next_p
					var emp_r: float = 10.0 + fposmod(_pulse_time * 52.0, 28.0)
					_fx_overlay.draw_arc(tip_pos + f_dir * 36.0, emp_r, 0.0, TAU, 18, Color(0.45, 0.90, 1.0, 0.45), 1.3, true)

				&"pressure_sealant":
					# Pressurized cryo-sealant / torch spray cone
					for jet_i in range(9):
						var j_prog: float = fposmod(_pulse_time * 2.6 + float(jet_i) * 0.11, 1.0)
						var j_spread: float = (float(jet_i % 5) - 2.0) * 0.14
						var j_dir: Vector2 = f_dir.rotated(j_spread)
						var j_pos: Vector2 = tip_pos + j_dir * (j_prog * 64.0)
						var j_rad: float = 1.8 + j_prog * 5.2
						var j_col: Color = Color(0.52, 0.94, 1.0, (1.0 - j_prog) * 0.62)
						_fx_overlay.draw_circle(j_pos, j_rad, j_col)

				&"medical_injector":
					# Bio-stim emerald healing aura & shield ring around Thura
					var heal_prog: float = 1.0 - norm_a
					var ring_rad: float = 10.0 + heal_prog * 22.0
					_fx_overlay.draw_arc(Vector2(0.0, -2.0), ring_rad, 0.0, TAU, 24, Color(0.28, 0.96, 0.64, 0.72 * norm_a), 2.0, true)
					_fx_overlay.draw_circle(Vector2(0.0, -2.0), ring_rad * 0.75, Color(0.24, 0.92, 0.58, 0.16 * norm_a))

	# 3. Quick equip/unequip ring pulse
	if _equip_anim_timer > 0.01:
		var ring_r: float = 8.0 + (1.0 - _equip_anim_timer) * 14.0
		var ring_col: Color = Color(0.38, 0.90, 1.0, _equip_anim_timer * 0.45)
		if _equipped_item_id != &"" and HELD_EQUIPMENT_VISUALS.has(_equipped_item_id):
			var c: Color = HELD_EQUIPMENT_VISUALS[_equipped_item_id]["glow_color"]
			ring_col = Color(c.r, c.g, c.b, _equip_anim_timer * 0.55)
		_fx_overlay.draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 20, ring_col, 1.3, false)


func _on_world_fx_draw() -> void:
	if not is_instance_valid(_world_fx_canvas):
		return

	# 1. Curing pressure sealant foam patches on the floor
	for sp in _sealant_patches:
		var spos: Vector2 = sp["pos"]
		var srad: float = float(sp["radius"])
		var st: float = float(sp["timer"])
		var smax: float = float(sp["max_timer"])
		var alpha: float = clampf(st / smax, 0.0, 1.0)
		_world_fx_canvas.draw_circle(spos, srad, Color(0.36, 0.88, 0.96, 0.38 * alpha))
		_world_fx_canvas.draw_circle(spos + Vector2(-1.2, -1.0), srad * 0.62, Color(0.84, 0.98, 1.0, 0.52 * alpha))

	# 2. Ejected brass revolver shell casings
	for sc in _shell_casings:
		var cpos: Vector2 = sc["pos"]
		var crot: float = float(sc["rot"])
		var ct: float = clampf(float(sc["timer"]), 0.0, 1.0)
		var cdir: Vector2 = Vector2(cos(crot), sin(crot)) * 1.8
		_world_fx_canvas.draw_line(cpos - cdir, cpos + cdir, Color(0.96, 0.78, 0.32, 0.92 * ct), 1.6, true)

	# 3. Revolver bullet tracers & impact spark bursts
	for bt in _bullet_tracers:
		var b_start: Vector2 = bt["start"]
		var b_end: Vector2 = bt["end"]
		var bt_norm: float = clampf(float(bt["timer"]) / float(bt["max_timer"]), 0.0, 1.0)
		var b_dir: Vector2 = bt["dir"]
		var head_t: float = clampf((1.0 - bt_norm) * 3.2, 0.25, 1.0)
		var tail_t: float = clampf(head_t - 0.55, 0.0, 1.0)
		var p_tail: Vector2 = b_start.lerp(b_end, tail_t)
		var p_head: Vector2 = b_start.lerp(b_end, head_t)
		_world_fx_canvas.draw_line(p_tail, p_head, Color(1.0, 0.78, 0.32, 0.65 * bt_norm), 3.2, true)
		_world_fx_canvas.draw_line(p_tail, p_head, Color(1.0, 0.98, 0.88, 0.96 * bt_norm), 1.4, true)

		# Impact spark burst at bullet destination
		_world_fx_canvas.draw_circle(b_end, 6.5 * bt_norm, Color(1.0, 0.68, 0.24, 0.45 * bt_norm))
		for k in range(5):
			var i_ang: float = (-b_dir).angle() + (float(k) - 2.0) * 0.48
			var i_len: float = (1.0 - bt_norm) * 14.0 + 3.0
			_world_fx_canvas.draw_line(b_end, b_end + Vector2(cos(i_ang), sin(i_ang)) * i_len, Color(1.0, 0.86, 0.42, 0.90 * bt_norm), 1.3, true)

	# 4. Flying flare projectiles in mid-air
	for ff in _flying_flares:
		var fpos: Vector2 = ff["pos"]
		var fstart: Vector2 = ff["start"]
		_world_fx_canvas.draw_line(fstart.lerp(fpos, 0.55), fpos, Color(1.0, 0.48, 0.18, 0.45), 3.0, true)
		_world_fx_canvas.draw_circle(fpos, 6.0, Color(1.0, 0.36, 0.14, 0.42))
		_world_fx_canvas.draw_circle(fpos, 2.8, Color(1.0, 0.92, 0.72, 0.98))

	# 5. Burning floor flares (intense room-lighting glow halo, magnesium sparks & rising smoke)
	for bf in _burning_flares:
		var bpos: Vector2 = bf["pos"]
		var bt: float = float(bf["timer"])
		var bseed: float = float(bf["seed"])
		var fade: float = clampf(bt / 2.5, 0.0, 1.0)
		var flicker: float = 0.84 + 0.22 * sin(_pulse_time * 6.5 + bseed)

		# Large warm room-illumination floor halo
		_world_fx_canvas.draw_circle(bpos, 68.0 * flicker, Color(1.0, 0.38, 0.14, 0.08 * fade))
		_world_fx_canvas.draw_circle(bpos, 34.0 * flicker, Color(1.0, 0.48, 0.18, 0.16 * fade))
		_world_fx_canvas.draw_circle(bpos, 12.0 * flicker, Color(1.0, 0.64, 0.26, 0.36 * fade))

		# Flare canister body on floor + white-hot burning tip
		_world_fx_canvas.draw_line(bpos - Vector2(3.5, 1.0), bpos + Vector2(3.5, 1.0), Color(0.82, 0.22, 0.14, 0.95 * fade), 2.8, true)
		_world_fx_canvas.draw_circle(bpos + Vector2(3.2, 0.6), 3.2 * flicker, Color(1.0, 0.96, 0.84, 0.98 * fade))

		# Sputtering magnesium sparks
		for s_i in range(5):
			var sp_phase: float = fposmod(_pulse_time * 1.8 + float(s_i) * 0.21 + bseed, 1.0)
			var sp_ang: float = float(s_i) * 1.25 + bseed + sin(_pulse_time * 3.0 + float(s_i)) * 0.4
			var sp_pt: Vector2 = bpos + Vector2(3.2, 0.6) + Vector2(cos(sp_ang), sin(sp_ang)) * (sp_phase * 16.0) + Vector2(0.0, -sp_phase * 8.0)
			_world_fx_canvas.draw_circle(sp_pt, 1.2 * (1.0 - sp_phase), Color(1.0, 0.84, 0.42, (1.0 - sp_phase) * 0.92 * fade))

	# 6. Deployed Survey Beacons on floor (rotating radar sweep & sonar rings)
	for db in _deployed_beacons:
		var dpos: Vector2 = db["pos"]
		var dt: float = float(db["timer"])
		var fade_b: float = clampf(dt / 2.0, 0.0, 1.0)
		var ring_p: float = fposmod(_pulse_time * 0.55, 1.0)
		var ring_r: float = 10.0 + ring_p * 64.0
		_world_fx_canvas.draw_arc(dpos, ring_r, 0.0, TAU, 28, Color(1.0, 0.78, 0.28, (1.0 - ring_p) * 0.48 * fade_b), 1.4, true)
		var sweep_a: float = fposmod(_pulse_time * 1.8, TAU)
		_world_fx_canvas.draw_line(dpos, dpos + Vector2(cos(sweep_a), sin(sweep_a)) * 34.0, Color(1.0, 0.84, 0.36, 0.62 * fade_b), 1.4, true)
		# Beacon tripod & blinking dome
		_world_fx_canvas.draw_circle(dpos, 5.2, Color(0.14, 0.18, 0.22, 0.95 * fade_b))
		_world_fx_canvas.draw_circle(dpos, 3.4, Color(1.0, 0.78, 0.28, 0.92 * fade_b))
		_world_fx_canvas.draw_circle(dpos, 1.6, Color(1.0, 0.98, 0.88, fade_b))

	# 7. Mineral Survey Scanner expanding sonar fan waves & target ping locks
	for sw in _scanner_waves:
		var s_orig: Vector2 = sw["origin"]
		var s_dir: Vector2 = sw["dir"]
		var s_norm: float = 1.0 - clampf(float(sw["timer"]) / float(sw["max_timer"]), 0.0, 1.0)
		var s_fade: float = sin(s_norm * PI)
		var base_a: float = s_dir.angle()
		for w_idx in range(3):
			var w_prog: float = clampf(s_norm * 1.25 - float(w_idx) * 0.16, 0.0, 1.0)
			if w_prog > 0.0:
				var w_rad: float = 16.0 + w_prog * 155.0
				_world_fx_canvas.draw_arc(s_orig, w_rad, base_a - 0.68, base_a + 0.68, 22, Color(0.32, 0.94, 1.0, (1.0 - w_prog) * 0.68), 1.8, true)

		var pings: Array = sw["pings"]
		for p_pt in pings:
			var t_pos: Vector2 = p_pt
			var d_sz: float = 6.5 + 2.0 * sin(_pulse_time * 6.0)
			var d_pts: PackedVector2Array = PackedVector2Array([
				t_pos + Vector2(0.0, -d_sz),
				t_pos + Vector2(d_sz, 0.0),
				t_pos + Vector2(0.0, d_sz),
				t_pos + Vector2(-d_sz, 0.0),
				t_pos + Vector2(0.0, -d_sz),
			])
			_world_fx_canvas.draw_polyline(d_pts, Color(0.34, 0.98, 0.78, 0.92 * s_fade), 1.6, true)
			_world_fx_canvas.draw_circle(t_pos, 2.0, Color(0.92, 1.0, 0.96, 0.95 * s_fade))

	# 8. Medical Injector rising green '+' bio-stim crosses
	for mp in _med_particles:
		var mpos: Vector2 = mp["pos"]
		var mnorm: float = clampf(float(mp["timer"]) / float(mp["max_timer"]), 0.0, 1.0)
		var mcol: Color = Color(0.32, 0.98, 0.66, 0.92 * mnorm)
		_world_fx_canvas.draw_line(mpos - Vector2(3.0, 0.0), mpos + Vector2(3.0, 0.0), mcol, 1.6, false)
		_world_fx_canvas.draw_line(mpos - Vector2(0.0, 3.0), mpos + Vector2(0.0, 3.0), mcol, 1.6, false)


func set_camera_bounds(bounds: Rect2) -> void:
	_camera_bounds = bounds
	_update_camera_limits()
	if is_instance_valid(camera):
		camera.enabled = true
		camera.make_current()
		camera.reset_smoothing()


func set_walkable_floor_mask(floor_texture: Texture2D, floor_origin: Vector2 = Vector2.ZERO, body_margin: float = 8.0) -> void:
	_walkable_floor_mask = floor_texture.get_image()
	if _walkable_floor_mask.is_compressed():
		var error: int = _walkable_floor_mask.decompress()
		if error != OK:
			push_error("Could not decompress the walkable floor mask.")
			_walkable_floor_mask = null
			return
	_walkable_floor_origin = floor_origin
	_walkable_body_margin = maxf(body_margin, 0.0)


func set_walkable_blocker_polygons(polygons: Array[PackedVector2Array]) -> void:
	_walkable_blocker_polygons = polygons.duplicate()


func _has_walkable_floor_mask() -> bool:
	return _walkable_floor_mask != null and not _walkable_floor_mask.is_empty()


func _move_on_walkable_floor(movement: Vector2) -> void:
	if not is_zero_approx(movement.x):
		var step_x: Vector2 = Vector2(movement.x, 0.0)
		if _is_body_over_floor(global_position + step_x):
			move_and_collide(step_x)
		elif _is_body_over_floor(global_position + step_x * 0.5):
			move_and_collide(step_x * 0.5)
	if not is_zero_approx(movement.y):
		var step_y: Vector2 = Vector2(0.0, movement.y)
		if _is_body_over_floor(global_position + step_y):
			move_and_collide(step_y)
		elif _is_body_over_floor(global_position + step_y * 0.5):
			move_and_collide(step_y * 0.5)


func _is_body_over_floor(center: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", center, _walkable_body_margin)):
			return false
	var diagonal: float = _walkable_body_margin * 0.70710678
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(_walkable_body_margin, 0.0),
		Vector2(-_walkable_body_margin, 0.0),
		Vector2(0.0, _walkable_body_margin),
		Vector2(0.0, -_walkable_body_margin),
		Vector2(diagonal, diagonal),
		Vector2(diagonal, -diagonal),
		Vector2(-diagonal, diagonal),
		Vector2(-diagonal, -diagonal),
	]
	for offset in offsets:
		var sample: Vector2 = center + offset - _walkable_floor_origin
		var pixel_x: int = floori(sample.x)
		var pixel_y: int = floori(sample.y)
		if pixel_x < 0 or pixel_y < 0 or pixel_x >= _walkable_floor_mask.get_width() or pixel_y >= _walkable_floor_mask.get_height():
			return false
		if _walkable_floor_mask.get_pixel(pixel_x, pixel_y).a < 0.15:
			return false
		for blocker in _walkable_blocker_polygons:
			if Geometry2D.is_point_in_polygon(sample, blocker):
				return false
	return true


func _configure_sprite_animations() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 8.0)
		frames.set_animation_loop(animation_name, true)
		var row: int = int(ANIMATION_ROWS[animation_name])
		for column in range(4):
			var atlas_frame: AtlasTexture = AtlasTexture.new()
			atlas_frame.atlas = THURA_ATLAS
			atlas_frame.region = Rect2(Vector2(float(column) * CELL_SIZE.x, float(row) * CELL_SIZE.y), CELL_SIZE)
			frames.add_frame(animation_name, atlas_frame)
	frames.add_animation(&"sit_down")
	frames.set_animation_speed(&"sit_down", 1.0)
	frames.set_animation_loop(&"sit_down", true)
	var sitting_image := THURA_SIT_DOWN.get_image()
	var sitting_frame: Texture2D = THURA_SIT_DOWN
	if sitting_image != null and sitting_image.get_size().x >= SITTING_FRAME_REGION.end.x and sitting_image.get_size().y >= SITTING_FRAME_REGION.end.y:
		sitting_frame = ImageTexture.create_from_image(sitting_image.get_region(SITTING_FRAME_REGION))
	frames.add_frame(&"sit_down", sitting_frame)
	_default_frames = frames
	sprite.sprite_frames = frames
	sprite.animation = _facing_animation


func face_toward(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	if not _sitting_pose_active and is_instance_valid(sprite):
		sprite.animation = _facing_animation
		sprite.stop()
		sprite.frame = 0


func sit_down() -> void:
	_sitting_pose_active = true
	sprite.stop()
	sprite.animation = &"sit_down"
	sprite.frame = 0
	sprite.scale = _standing_sprite_scale * 0.52
	sprite.position = _standing_sprite_position


func stand_up() -> void:
	_sitting_pose_active = false
	sprite.stop()
	sprite.animation = _facing_animation
	sprite.frame = 0
	sprite.scale = _standing_sprite_scale
	sprite.position = _standing_sprite_position


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	if not _sitting_pose_active and sprite.animation != _facing_animation:
		sprite.play(_facing_animation)


func _update_camera_limits() -> void:
	if not is_instance_valid(camera):
		return
	var pad: Vector2 = Vector2(360.0, 240.0)
	camera.limit_left = floori(_camera_bounds.position.x - pad.x)
	camera.limit_top = floori(_camera_bounds.position.y - pad.y)
	camera.limit_right = ceili(_camera_bounds.end.x + pad.x)
	camera.limit_bottom = ceili(_camera_bounds.end.y + pad.y)
