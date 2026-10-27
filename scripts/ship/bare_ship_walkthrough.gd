@tool
extends Node2D

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const RESONANCE_ORE_TANK_STORED_TEXTURE := preload("res://art/concepts/lab_props/ore_containment_stored_refined.png")
const RESONANCE_ORE_TANK_CRACKING_TEXTURE := preload("res://art/planet/modern_ore_containment_cracking.png")
const RESONANCE_ORE_TANK_DESTROYED_TEXTURE := preload("res://art/planet/modern_ore_containment_destroyed.png")
const RESONANCE_ORE_LEAK_TEXTURE := preload("res://art/concepts/lab_props/destroyed/ore_leak_tank_to_floor.png")
const RESONANCE_ORE_VILLAIN_SCENE := preload("res://scenes/ship/crew/resonance_ore_villain.tscn")
const ECHO_LIQUID_ATLAS := preload("res://art/characters/runtime/echo_liquid_walk_4dir.png")
const ARRIVAL_BRIEFING_SCENE := preload("res://scenes/ui/arrival_briefing.tscn")
const SERVICE_TASK_CONSOLE_SCENE := preload("res://scenes/ui/service_task_console.tscn")
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")
const CREW_DIALOGUE_SCENE := preload("res://scenes/ui/crew_dialogue.tscn")
const MOCK_PLANET_SCENE_PATH := "res://scenes/planet/mock_planet_exterior.tscn"
const AIRLOCK_INTERACTION_RADIUS := 74.0
const AIRLOCK_RETURN_FLOOR_POS := Vector2(478.5, 294.0)
const XENOMORPH_INCUBATION_SECONDS := 60.0

const ROOM_TASKS := [
	{
		"id": &"auxiliary_power",
		"title": "Reconnect auxiliary power",
		"marker_label": "AUX POWER",
		"station_path": NodePath("PowerMaintenanceRoomProps/PowerCellModule"),
		"prompt": "AUXILIARY POWER CELL   /   [E] RECONNECT",
		"completion": "Power cell reconnected. Auxiliary power is restored.",
	},
	{
		"id": &"air_filter",
		"title": "Replace life-support filter",
		"marker_label": "LIFE SUPPORT",
		"station_path": NodePath("LifeSupportRoomProps/FilterCartridge"),
		"prompt": "LIFE-SUPPORT FILTER   /   [E] REPLACE",
		"completion": "Filter replaced. Life-support airflow is clear.",
	},
	{
		"id": &"nutrient_flow",
		"title": "Restore hydroponic nutrient flow",
		"marker_label": "HYDROPONICS",
		"station_path": NodePath("HydroponicsRoomProps/ControlConsole"),
		"interaction_offset": Vector2(32.0, 0.0),
		"interaction_radius": 65.0,
		"prompt": "HYDROPONICS CONSOLE   /   [E] ROUTE NUTRIENTS",
		"completion": "Nutrient manifold aligned. The grow beds are irrigating.",
	},
]
const LAB_DEVICES := [
	{
		"id": &"lab_specimen",
		"station_path": NodePath("LabRoom/NorthWorkstation"),
		"interaction_offset": Vector2(-34.0, 27.0),
		"prompt": "SPECIMEN ANALYSIS TABLE   /   [E] OPEN ANALYZER",
	},
	{
		"id": &"lab_earth_comms",
		"station_path": NodePath("LabRoom/ConsoleStation"),
		"interaction_offset": Vector2(39.0, 18.0),
		"prompt": "RESEARCH CONSOLE   /   [E] OPEN TERMINAL",
	},
	{
		"id": &"lab_containment",
		"station_path": NodePath("LabRoom/OreContainment"),
		"interaction_offset": Vector2(0.0, 38.0),
		"prompt": "SAMPLE CONTAINMENT   /   [E] OPEN CONTROLS",
	},
	{
		"id": &"lab_trolley",
		"station_path": NodePath("LabRoom/MicroscopeCart"),
		"interaction_offset": Vector2(0.0, 38.0),
		"prompt": "INSTRUMENT TROLLEY   /   [E] OPEN INSTRUMENTS",
	},
	{
		"id": &"lab_archive_01",
		"station_path": NodePath("LabRoom/ArchiveStationLeft"),
		"interaction_offset": Vector2(-18.0, 34.0),
		"prompt": "PERSONNEL ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_archive_02",
		"station_path": NodePath("LabRoom/ArchiveStationCenter"),
		"interaction_offset": Vector2(0.0, 34.0),
		"prompt": "SPECIMEN ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_archive_03",
		"station_path": NodePath("LabRoom/ArchiveStationRight"),
		"interaction_offset": Vector2(18.0, 34.0),
		"prompt": "CONTAINMENT ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_robot_arm",
		"station_path": NodePath("LabRoom/SampleManipulator"),
		"interaction_offset": Vector2(0.0, 36.0),
		"prompt": "SAMPLE MANIPULATOR   /   [E] OPEN CONTROLS",
	},
]
const ROOM_TASK_INTERACTION_RADIUS := 44.0
const AMARA_INTERACTION_RADIUS := 66.0
const CREW_TASK_INTERACTION_RADIUS := 64.0
# Keep these task points in the clear aisle beside each collidable prop.
const AMARA_CREW_TASKS := [
	{
		"id": &"amara_nutrient_pump",
		"title": "Amara: inspect the nutrient pump",
		"marker_label": "AMARA / PUMP",
		"station_path": NodePath("HydroponicsRoomProps/NutrientPump"),
		"interaction_offset": Vector2(36.0, 0.0),
		"prompt": "NUTRIENT PUMP   /   [E] INSPECT",
		"completion": "The nutrient pump is clear and flowing again.",
	},
	{
		"id": &"amara_seedling_sensor",
		"title": "Amara: recalibrate the seedling sensor",
		"marker_label": "AMARA / SEEDLINGS",
		"station_path": NodePath("HydroponicsRoomProps/SeedlingRack"),
		"interaction_offset": Vector2(44.0, 0.0),
		"prompt": "SEEDLING RACK   /   [E] CALIBRATE SENSOR",
		"completion": "The seedling rack humidity sensor is calibrated.",
	},
]


@export var player_spawn: Vector2 = Vector2(900.0, 500.0)

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var wall_layer: Sprite2D = $WallLayer
@onready var exterior_airlock: Node2D = $ExteriorAirlockGate
@onready var player: ShipPlayer = $Player
@onready var amara: AmaraOkoye = $AmaraOkoye

var _completed_room_tasks: Dictionary = {}
var _active_room_task_id: StringName = &""
var _active_lab_device_id: StringName = &""
var _task_console_open := false
var _arrival_briefing_open := true
var _hud_modal_open := false
var _room_task_feedback := ""
var _pending_room_task_feedback := ""
var _room_task_feedback_timer := 0.0
var _walk_hud: WalkHud
var _crew_dialogue: CrewDialogue
var _crew_dialogue_open := false
var _amara_intro_seen := false
var _crew_tasks_unlocked := false
var _completed_crew_tasks: Dictionary = {}
var _active_amara_interaction := false
var _amara_ore_handoff_active := false
var _active_crew_task_id: StringName = &""
var _active_airlock_exit := false
var _transitioning_to_planet := false
var _xenomorph_timer_active := false
var _xenomorph_countdown := XENOMORPH_INCUBATION_SECONDS
var _xenomorph_visual_stage := -1
var _tank_countdown_label: Label
var _tank_liquid_sprite: AnimatedSprite2D
var _ore_leak_sprite: Sprite2D
var _ore_leak_phase := 0.0


func _load_sprite_png(sprite: Sprite2D, res_path: String) -> void:
	if not is_instance_valid(sprite):
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null and not img.is_empty():
		sprite.texture = ImageTexture.create_from_image(img)


func _load_single_sprite_png(sprite: Sprite2D, res_path: String, sprite_scale: Vector2 = Vector2.ONE) -> void:
	if not is_instance_valid(sprite):
		return
	_load_sprite_png(sprite, res_path)
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.scale = sprite_scale


func _set_ore_leak_visible(is_visible: bool) -> void:
	if not is_instance_valid(_ore_leak_sprite):
		var lab_room := get_node_or_null("LabRoom") as Node2D
		if lab_room == null:
			return
		_ore_leak_sprite = Sprite2D.new()
		_ore_leak_sprite.name = "ResonanceOreLeak"
		_ore_leak_sprite.texture = RESONANCE_ORE_LEAK_TEXTURE
		_ore_leak_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# The narrow stream starts beneath the tank; the wider pool runs across the deck.
		_ore_leak_sprite.position = Vector2(255.0, 105.0)
		_ore_leak_sprite.scale = Vector2(0.041, 0.041)
		_ore_leak_sprite.z_index = 0
		_ore_leak_sprite.visible = false
		lab_room.add_child(_ore_leak_sprite)
	_ore_leak_sprite.visible = is_visible


func _is_ore_sample_collected() -> bool:
	return Engine.has_meta(&"resonance_ore_sample_collected") and bool(Engine.get_meta(&"resonance_ore_sample_collected"))


func _is_ore_sample_stored() -> bool:
	return Engine.has_meta(&"resonance_ore_sample_stored") and bool(Engine.get_meta(&"resonance_ore_sample_stored"))


func _is_ore_sample_evolved() -> bool:
	return Engine.has_meta(&"resonance_ore_sample_evolved") and bool(Engine.get_meta(&"resonance_ore_sample_evolved"))


func _is_ore_villain_spawned() -> bool:
	return Engine.has_meta(&"resonance_ore_villain_spawned") and bool(Engine.get_meta(&"resonance_ore_villain_spawned"))


func _is_lab_destroyed() -> bool:
	return Engine.has_meta(&"lab_destroyed_by_xenomorph") and bool(Engine.get_meta(&"lab_destroyed_by_xenomorph"))


func _ensure_tank_countdown_label() -> Label:
	if is_instance_valid(_tank_countdown_label):
		return _tank_countdown_label
	var lab_room := get_node_or_null("LabRoom") as Node2D
	if lab_room == null:
		return null
	_tank_countdown_label = Label.new()
	_tank_countdown_label.name = "EchoIncubationCountdownLabel"
	_tank_countdown_label.position = Vector2(174.0, 42.0)
	_tank_countdown_label.z_index = 6
	_tank_countdown_label.add_theme_font_size_override("font_size", 9)
	_tank_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	_tank_countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	_tank_countdown_label.add_theme_constant_override("outline_size", 3)
	_tank_countdown_label.visible = false
	lab_room.add_child(_tank_countdown_label)
	return _tank_countdown_label


func _set_tank_liquid_visible(visible: bool) -> void:
	if not is_instance_valid(_tank_liquid_sprite):
		var containment := get_node_or_null("LabRoom/OreContainment") as Node2D
		if containment == null:
			return
		_tank_liquid_sprite = AnimatedSprite2D.new()
		_tank_liquid_sprite.name = "LiquidOreInsideTank"
		_tank_liquid_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var tank_sprite := containment.get_node_or_null("SampleContainment") as Sprite2D
		_tank_liquid_sprite.position = tank_sprite.position if tank_sprite != null else Vector2.ZERO
		_tank_liquid_sprite.scale = Vector2(2.0, 0.65)
		_tank_liquid_sprite.z_index = -1
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		frames.add_animation(&"flow")
		frames.set_animation_speed(&"flow", 4.0)
		frames.set_animation_loop(&"flow", true)
		var frame_size := Vector2(float(ECHO_LIQUID_ATLAS.get_width()) / 4.0, float(ECHO_LIQUID_ATLAS.get_height()) / 4.0)
		for column in range(4):
			var frame := AtlasTexture.new()
			frame.atlas = ECHO_LIQUID_ATLAS
			frame.region = Rect2(Vector2(float(column) * frame_size.x, 0.0), frame_size)
			frames.add_frame(&"flow", frame)
		_tank_liquid_sprite.sprite_frames = frames
		_tank_liquid_sprite.animation = &"flow"
		containment.add_child(_tank_liquid_sprite)
	if visible:
		_tank_liquid_sprite.visible = true
		_tank_liquid_sprite.play(&"flow")
	else:
		_tank_liquid_sprite.visible = false


func _start_xenomorph_incubation_timer() -> void:
	if _is_ore_villain_spawned() or _xenomorph_timer_active:
		return
	_xenomorph_timer_active = true
	if Engine.has_meta(&"resonance_ore_incubation_remaining"):
		_xenomorph_countdown = float(Engine.get_meta(&"resonance_ore_incubation_remaining"))
	else:
		_xenomorph_countdown = XENOMORPH_INCUBATION_SECONDS
		Engine.set_meta(&"resonance_ore_incubation_remaining", _xenomorph_countdown)
	_xenomorph_visual_stage = -1
	_update_xenomorph_incubation(0.0)


func _update_xenomorph_incubation(delta: float) -> void:
	if not _xenomorph_timer_active or _is_ore_villain_spawned():
		return
	_xenomorph_countdown = maxf(_xenomorph_countdown - delta, 0.0)
	Engine.set_meta(&"resonance_ore_incubation_remaining", _xenomorph_countdown)

	var elapsed := XENOMORPH_INCUBATION_SECONDS - _xenomorph_countdown
	var tank_sprite := get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D
	var lbl := _ensure_tank_countdown_label()
	if is_instance_valid(lbl):
		lbl.visible = true
		var secs_left := ceili(_xenomorph_countdown)
		var mins := secs_left / 60
		var secs := secs_left % 60
		lbl.text = "ECHO FORMATION  %02d:%02d" % [mins, secs]
		if _xenomorph_countdown <= 15.0:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.34, 0.24))
		elif _xenomorph_countdown <= 35.0:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.64, 0.28))

	var stage := 0
	if elapsed >= 50.0:
		stage = 3
	elif elapsed >= 35.0:
		stage = 2
	elif elapsed >= 18.0:
		stage = 1

	if stage != _xenomorph_visual_stage and is_instance_valid(tank_sprite):
		_xenomorph_visual_stage = stage
		match stage:
			0:
				tank_sprite.texture = RESONANCE_ORE_TANK_STORED_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/concepts/lab_props/ore_containment_stored_refined.png")
				tank_sprite.modulate = Color.WHITE
				_set_tank_liquid_visible(false)
			1:
				tank_sprite.texture = RESONANCE_ORE_TANK_STORED_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_empty.png")
				tank_sprite.modulate = Color.WHITE
				_set_tank_liquid_visible(true)
				_room_task_feedback = "SAMPLE ALERT: THE SOLID ORE HAS BECOME BLACK LIQUID."
				_room_task_feedback_timer = 4.5
			2:
				tank_sprite.texture = RESONANCE_ORE_TANK_CRACKING_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_cracking.png")
				tank_sprite.modulate = Color(1.0, 0.94, 0.86)
				_set_tank_liquid_visible(true)
				_room_task_feedback = "PRESSURE WARNING: LIQUID ORE IS PUSHING THROUGH THE TANK SEALS."
				_room_task_feedback_timer = 4.5
			3:
				tank_sprite.texture = RESONANCE_ORE_TANK_DESTROYED_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_destroyed.png")
				_set_tank_liquid_visible(false)
				_room_task_feedback = "CONTAINMENT BREACH: BLACK LIQUID HAS ENTERED THE SERVICE DUCTS."
				_room_task_feedback_timer = 5.0

	if _xenomorph_countdown <= 0.0:
		_xenomorph_timer_active = false
		if is_instance_valid(lbl):
			lbl.text = "CONTAINMENT BREACHED"
			lbl.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22))
		_spawn_resonance_ore_villain(true)


func _wreck_lab_prop(node_path: NodePath, rot: float, offset: Vector2, tint: Color, animate: bool) -> void:
	var node := get_node_or_null(node_path) as Node2D
	if node == null:
		return
	if not node.has_meta(&"orig_pos"):
		node.set_meta(&"orig_pos", node.position)
	var base_pos: Vector2 = node.get_meta(&"orig_pos")
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(node, "position", base_pos + offset, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "rotation", rot, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(node, "modulate", Color(1.35, 0.45, 0.28), 0.08)
		tw.tween_property(node, "modulate", tint, 0.18).set_delay(0.08)
	else:
		node.position = base_pos + offset
		node.rotation = rot
		node.modulate = tint


func _apply_lab_destruction_stage(stage: int, animate: bool) -> void:
	match stage:
		1:
			# Stage 1: OreContainment shattered & cable severed
			_load_sprite_png(get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D, "res://art/concepts/lab_props/destroyed/ore_containment.png")
			_set_ore_leak_visible(true)
			_wreck_lab_prop(NodePath("LabRoom/OreContainment"), -0.05, Vector2(0.0, 3.0), Color.WHITE, animate)
			var sleeve := get_node_or_null("LabRoom/CableRuns/ContainmentToAnalysisSleeve") as Line2D
			var sig := get_node_or_null("LabRoom/CableRuns/ContainmentToAnalysisSignal") as Line2D
			if sleeve != null:
				sleeve.visible = false
			if sig != null:
				sig.visible = false
		2:
			# Stage 2: Archive screens break and two drawers are torn open.
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationLeft/DataArchive") as Sprite2D, "res://art/concepts/lab_props/destroyed/data_archive.png")
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationCenter/DataArchive") as Sprite2D, "res://art/concepts/lab_props/destroyed/data_archive.png")
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationRight/DataArchive") as Sprite2D, "res://art/concepts/lab_props/destroyed/data_archive.png")
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationLeft"), -0.14, Vector2(-3.0, 2.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationCenter"), 0.10, Vector2(2.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationRight"), -0.15, Vector2(3.0, 2.0), Color.WHITE, animate)
			for gl_name in ["ArchiveGlowLeft", "ArchiveGlowCenter", "ArchiveGlowRight"]:
				var gl := get_node_or_null("LabRoom/StationLighting/" + gl_name) as PointLight2D
				if gl != null:
					gl.color = Color(1.0, 0.32, 0.18, 1.0)
		3:
			# Stage 3: Specimen Analysis Table & Robotic Arm smashed with destroyed textures
			_load_sprite_png(get_node_or_null("LabRoom/NorthWorkstation/SpecimenAnalysisTable") as Sprite2D, "res://art/concepts/lab_props/destroyed/specimen_analysis_table.png")
			_load_sprite_png(get_node_or_null("LabRoom/SampleManipulator/RoboticSampleArm") as Sprite2D, "res://art/concepts/lab_props/destroyed/sample_robot_arm.png")
			_wreck_lab_prop(NodePath("LabRoom/NorthWorkstation"), -0.07, Vector2(-4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/SampleManipulator"), 0.12, Vector2(4.0, -2.0), Color.WHITE, animate)
			var ag := get_node_or_null("LabRoom/StationLighting/AnalysisGlow") as PointLight2D
			if ag != null:
				ag.color = Color(1.0, 0.28, 0.16, 1.0)
		4:
			# Stage 4: Research console screens crack and the side storage cabinet breaks open.
			_load_sprite_png(get_node_or_null("LabRoom/ConsoleStation/ResearchConsole") as Sprite2D, "res://art/concepts/lab_props/destroyed/research_console.png")
			_load_sprite_png(get_node_or_null("LabRoom/StorageCabinetRightView/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/right_storage_cabinet.png")
			_wreck_lab_prop(NodePath("LabRoom/ConsoleStation"), 0.15, Vector2(4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/StorageCabinetRightView"), -0.08, Vector2(-2.0, 2.0), Color.WHITE, animate)
			var cg := get_node_or_null("LabRoom/StationLighting/ConsoleGlow") as PointLight2D
			if cg != null:
				cg.color = Color(1.0, 0.34, 0.16, 1.0)
		5:
			# Stage 5: Instrument trolley is overturned with broken glass and a collapsed arm.
			_load_sprite_png(get_node_or_null("LabRoom/MicroscopeCart/InstrumentTrolley") as Sprite2D, "res://art/concepts/lab_props/destroyed/instrument_trolley.png")
			_wreck_lab_prop(NodePath("LabRoom/MicroscopeCart"), 0.04, Vector2(-4.0, 3.0), Color.WHITE, animate)
			var wg := get_node_or_null("LabRoom/StationLighting/CartWorklight") as PointLight2D
			if wg != null:
				wg.color = Color(1.0, 0.25, 0.14, 1.0)
		6:
			# Stage 6: Left Storage Cabinet, Waste Bins & Wash Sink destroyed
			_load_single_sprite_png(get_node_or_null("LabRoom/LeftStorageCabinet/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/sample_cabinet.png")
			_load_single_sprite_png(get_node_or_null("LabRoom/LabWasteBins/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/lab_waste_bins.png", Vector2(0.4, 0.4))
			_load_single_sprite_png(get_node_or_null("LabRoom/WashSink/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/wash_sink.png", Vector2(0.5, 0.5))
			_wreck_lab_prop(NodePath("LabRoom/LeftStorageCabinet"), 0.08, Vector2(-3.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/LabWasteBins"), 0.12, Vector2(-4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/WashSink"), -0.08, Vector2(-2.0, 2.0), Color.WHITE, animate)
			Engine.set_meta(&"lab_destroyed_by_xenomorph", true)
			var lbl := _ensure_tank_countdown_label()
			if is_instance_valid(lbl):
				lbl.visible = true
				lbl.text = "LAB DESTROYED // ECHO LOOSE"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22))
			if animate:
				_room_task_feedback = "CRITICAL ALERT: THE ECHO HAS DESTROYED THE ENTIRE LAB!"
				_room_task_feedback_timer = 6.5


func _destroy_all_lab_immediately() -> void:
	for st in range(1, 7):
		_apply_lab_destruction_stage(st, false)
	_set_lab_station_lights_visible(false)


func _set_lab_station_lights_visible(is_visible: bool) -> void:
	var lighting := get_node_or_null("LabRoom/StationLighting") as Node2D
	if lighting == null:
		return
	for child in lighting.get_children():
		if child is PointLight2D:
			(child as PointLight2D).visible = is_visible


func _play_lab_breach_wave() -> void:
	var lab_room := get_node_or_null("LabRoom") as Node2D
	if lab_room == null:
		return
	var wave := Polygon2D.new()
	wave.name = "ResonanceBreachWave"
	wave.color = Color(0.05, 0.78, 0.72, 0.36)
	wave.position = Vector2(286.0, 132.0)
	wave.scale = Vector2(0.01, 0.01)
	wave.z_index = 5
	var circle := PackedVector2Array()
	for index in range(48):
		var angle := TAU * float(index) / 48.0
		circle.append(Vector2(cos(angle), sin(angle)))
	wave.polygon = circle
	lab_room.add_child(wave)

	var lights := get_node_or_null("LabRoom/StationLighting") as Node2D
	if lights != null:
		for child in lights.get_children():
			if child is PointLight2D:
				var light := child as PointLight2D
				light.visible = true
				light.color = Color(0.24, 1.0, 0.86, 1.0)
				var flicker := create_tween()
				flicker.tween_property(light, "energy", 1.1, 0.12)
				flicker.tween_property(light, "energy", 0.06, 0.18)
				flicker.tween_property(light, "energy", 0.85, 0.08)
				flicker.tween_property(light, "energy", 0.0, 0.24)

	var surge := create_tween()
	surge.tween_property(wave, "scale", Vector2(255.0, 138.0), 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await surge.finished
	wave.queue_free()
	_set_lab_station_lights_visible(false)


func _spawn_resonance_ore_villain(play_breakout_fx: bool) -> void:
	Engine.set_meta(&"resonance_ore_villain_spawned", true)
	var lab_room := get_node_or_null("LabRoom") as Node2D
	var containment := get_node_or_null("LabRoom/OreContainment") as Node2D
	if containment == null or lab_room == null:
		return
	var tank_sprite := containment.get_node_or_null("SampleContainment") as Sprite2D
	if tank_sprite != null:
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_destroyed.png")
	_set_tank_liquid_visible(false)
	var containment_glow := get_node_or_null("LabRoom/StationLighting/ContainmentGlow") as PointLight2D
	if containment_glow != null:
		containment_glow.visible = true
		containment_glow.color = Color(1.0, 0.28, 0.16, 1.0)
		containment_glow.energy = 0.68
	var room_lighting := get_node_or_null("ShipRoomLighting")
	if room_lighting != null and room_lighting.has_method("set_room_flicker"):
		room_lighting.call("set_room_flicker", &"r08_central_bay", true)

	var villain := get_node_or_null("ResonanceOreVillain") as ResonanceOreVillain
	if villain == null:
		villain = RESONANCE_ORE_VILLAIN_SCENE.instantiate() as ResonanceOreVillain
		villain.name = "ResonanceOreVillain"
		add_child(villain)

	var landing_pos := lab_room.to_global(Vector2(236.0, 114.0))
	if play_breakout_fx and not _is_lab_destroyed():
		villain.global_position = containment.global_position + Vector2(0.0, 6.0)
		villain.scale = Vector2(0.55, 0.55)
		var leap := create_tween().set_parallel(true)
		leap.tween_property(villain, "global_position", landing_pos, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		leap.tween_property(villain, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await leap.finished
		if not is_instance_valid(villain):
			return
		_room_task_feedback = "ALERT: BLACK LIQUID LIFEFORM DETECTED IN THE SERVICE DUCTS."
		_room_task_feedback_timer = 6.5
		await get_tree().create_timer(6.5).timeout
		if not is_instance_valid(villain):
			return
		_room_task_feedback = "DR. OKOYE: SUIT FAILURE  /  VITALS DROPPING"
		_room_task_feedback_timer = 5.0
		if is_instance_valid(amara) and amara.visible:
			villain.set_physics_process(false)
			var attack := create_tween()
			attack.tween_property(villain, "global_position", amara.global_position, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await attack.finished
			if not is_instance_valid(villain):
				return
			await amara.become_missing()
		else:
			Engine.set_meta(&"lab_doctor_missing", true)
		if not is_instance_valid(villain):
			return
		_room_task_feedback = "DR. OKOYE: SIGNAL LOST  /  LOCATION UNKNOWN"
		_room_task_feedback_timer = 5.0
		await villain.fuse_with_amara()
		if not is_instance_valid(villain):
			return
		_room_task_feedback = "DR. OKOYE IS MISSING  /  ECHO HOST FORM ACTIVE"
		_room_task_feedback_timer = 6.5
		await get_tree().create_timer(2.4).timeout
		if not is_instance_valid(villain):
			return
		_room_task_feedback = "THE ECHO HAS ENTERED THE SERVICE DUCTS  /  LAB SYSTEMS FAILING"
		_room_task_feedback_timer = 6.5
		await villain.disappear_into_ducts()
		if not is_instance_valid(villain):
			return
		_apply_lab_destruction_stage(1, true)
		await get_tree().create_timer(0.22).timeout
		await _play_lab_breach_wave()
		for stage in range(2, 7):
			_apply_lab_destruction_stage(stage, false)
		_room_task_feedback = "RESONANCE SURGE  /  LAB SYSTEMS CRITICAL"
		_room_task_feedback_timer = 6.5
	else:
		villain.global_position = landing_pos
		if Engine.has_meta(&"echo_disappeared_into_ducts") and bool(Engine.get_meta(&"echo_disappeared_into_ducts")):
			villain.visible = false
			villain.set_physics_process(false)
			_destroy_all_lab_immediately()
			return
		if is_instance_valid(amara) and amara.visible:
			await amara.become_missing()
		else:
			Engine.set_meta(&"lab_doctor_missing", true)
		if not (Engine.has_meta(&"resonance_ore_fused_with_amara") and bool(Engine.get_meta(&"resonance_ore_fused_with_amara"))):
			await villain.fuse_with_amara()
		_destroy_all_lab_immediately()
		await villain.disappear_into_ducts()


func _display_contained_ore_sample() -> void:
	var containment := get_node_or_null("LabRoom/OreContainment") as Node2D
	if containment == null:
		return
	containment.scale = Vector2(0.056, 0.056)
	var containment_glow := get_node_or_null("LabRoom/StationLighting/ContainmentGlow") as CanvasItem
	var tank_sprite := containment.get_node_or_null("SampleContainment") as Sprite2D
	if tank_sprite == null:
		return
	var is_stored := _is_ore_sample_stored()
	if is_instance_valid(containment_glow):
		containment_glow.visible = is_stored
	if not is_stored:
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_empty.png")
		tank_sprite.set_meta(&"hatched", false)
		return
	if _is_ore_villain_spawned():
		tank_sprite.set_meta(&"hatched", true)
		_spawn_resonance_ore_villain(false)
		return
	var is_evolved := _is_ore_sample_evolved()
	if is_evolved:
		tank_sprite.texture = RESONANCE_ORE_TANK_DESTROYED_TEXTURE
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_destroyed.png")
	else:
		tank_sprite.texture = RESONANCE_ORE_TANK_STORED_TEXTURE
		_load_sprite_png(tank_sprite, "res://art/concepts/lab_props/ore_containment_stored_refined.png")
	tank_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tank_sprite.set_meta(&"hatched", is_evolved)
	var stimulated := Engine.has_meta(&"resonance_ore_stimulated") and bool(Engine.get_meta(&"resonance_ore_stimulated"))
	if stimulated:
		_start_xenomorph_incubation_timer()


func _deposit_ore_into_containment() -> void:
	Engine.set_meta(&"resonance_ore_sample_stored", true)
	Engine.set_meta(&"resonance_ore_incubation_remaining", XENOMORPH_INCUBATION_SECONDS)
	Engine.set_meta(&"resonance_ore_chamber_pressure", 0.82)
	Engine.set_meta(&"resonance_ore_atmosphere_test_passed", false)
	Engine.set_meta(&"resonance_ore_stimulated", false)
	if is_instance_valid(_walk_hud) and _walk_hud.has_method("consume_item"):
		_walk_hud.consume_item(&"resonance_ore_sample")
	_display_contained_ore_sample()
	if is_instance_valid(amara):
		amara.begin_sample_watch()
	var tank_sprite := get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D
	if tank_sprite != null:
		tank_sprite.scale = Vector2(0.94, 0.94)
		var place_tween := create_tween().set_parallel(true)
		place_tween.tween_property(tank_sprite, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		place_tween.tween_property(tank_sprite, "modulate", Color(0.82, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		place_tween.tween_property(tank_sprite, "modulate", Color.WHITE, 0.25).set_delay(0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_room_task_feedback = "RESONANCE ORE PLACED IN CONTAINMENT  //  ATMOSPHERE STUDY READY"
	_room_task_feedback_timer = 4.5


func _update_contained_ore_sample() -> void:
	if _is_ore_sample_stored() and is_instance_valid(_walk_hud) and _walk_hud.has_method("consume_item"):
		_walk_hud.consume_item(&"resonance_ore_sample")
	_display_contained_ore_sample()
	var stimulated := Engine.has_meta(&"resonance_ore_stimulated") and bool(Engine.get_meta(&"resonance_ore_stimulated"))
	if _is_ore_sample_stored() and stimulated and not _is_ore_villain_spawned():
		_start_xenomorph_incubation_timer()


func _on_containment_stimulated() -> void:
	if not _is_ore_sample_stored():
		return
	Engine.set_meta(&"resonance_ore_incubation_remaining", XENOMORPH_INCUBATION_SECONDS)
	_xenomorph_countdown = XENOMORPH_INCUBATION_SECONDS
	_start_xenomorph_incubation_timer()
	_room_task_feedback = "ELECTRICAL STIMULUS APPLIED  //  1:00 BIO-INCUBATION STARTED"
	_room_task_feedback_timer = 4.5


func _ready() -> void:
	_load_sprite_png(floor_layer, "res://art/concepts/Refined pixel-art spacecraft floor.png")
	_load_sprite_png(wall_layer, "res://art/concepts/ship_walls_valkyrie.png")
	_load_sprite_png(get_node_or_null("CenterRecessRoom/FloorVisual") as Sprite2D, "res://art/overview/floor_modules/rooms/r03_center_recess_floor.png")
	_load_sprite_png(get_node_or_null("PowerMaintenanceRoomProps/FloorDetail/UpperDeckPanel") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_upper_plate.png")
	_load_sprite_png(get_node_or_null("PowerMaintenanceRoomProps/FloorDetail/PowerCellCautionInset") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_hazard_zone.png")
	_load_sprite_png(get_node_or_null("LifeSupportRoomProps/FloorDetail/LifeSupportDeckPanel") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png")
	_load_sprite_png(get_node_or_null("LifeSupportRoomProps/FloorDetail/AirflowServiceGrate") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_small_grate.png")
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	var returning_from_planet := Engine.has_meta(&"returning_from_planet") and bool(Engine.get_meta(&"returning_from_planet"))
	if not returning_from_planet:
		for meta_key in [
			&"resonance_ore_sample_collected",
			&"resonance_ore_sample_stored",
			&"resonance_ore_sample_evolved",
			&"resonance_ore_villain_spawned",
			&"resonance_ore_fused_with_amara",
			&"lab_doctor_missing",
			&"echo_disappeared_into_ducts",
			&"lab_destroyed_by_xenomorph",
			&"resonance_ore_stimulated",
			&"resonance_ore_atmosphere_test_passed",
			&"resonance_ore_chamber_pressure",
			&"resonance_ore_incubation_remaining",
		]:
			if Engine.has_meta(meta_key):
				Engine.remove_meta(meta_key)
	if not amara.sample_study_started.is_connected(_on_containment_stimulated):
		amara.sample_study_started.connect(_on_containment_stimulated)
	_display_contained_ore_sample()

	# Movement samples global positions; include any saved ship-root translation.
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.global_position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)

	if returning_from_planet:
		Engine.remove_meta(&"returning_from_planet")
		player.global_position = floor_layer.to_global(AIRLOCK_RETURN_FLOOR_POS)
	else:
		player.global_position = player_spawn

	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
	var hud_task_entries: Array[Dictionary] = []
	for task in ROOM_TASKS:
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_pos := _room_task_interaction_position(task, station)
		hud_task_entries.append({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"position": interaction_pos,
			"marker_position": _task_marker_position(station, task.get("interaction_offset", Vector2.ZERO)),
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_task_entries, floor_layer.global_position, FLOOR_TEXTURE.get_size())
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_crew_dialogue = CREW_DIALOGUE_SCENE.instantiate() as CrewDialogue
	_crew_dialogue.dialogue_finished.connect(_on_amara_dialogue_finished)
	add_child(_crew_dialogue)

	if returning_from_planet:
		_arrival_briefing_open = false
		_walk_hud.set_walking_visible(true)
		_room_task_feedback = "AIRLOCK CYCLE COMPLETE  //  ABOARD ASTERIA-1"
		_room_task_feedback_timer = 3.5
		_update_player_walk_state()
	else:
		_walk_hud.set_walking_visible(false)
		var arrival_briefing := ARRIVAL_BRIEFING_SCENE.instantiate()
		arrival_briefing.connect(&"dismissed", _on_arrival_briefing_dismissed)
		add_child(arrival_briefing)


func _process(delta: float) -> void:
	if _transitioning_to_planet:
		return
	if is_instance_valid(_ore_leak_sprite) and _ore_leak_sprite.visible:
		_ore_leak_phase = fposmod(_ore_leak_phase + delta * 0.8, TAU)
		var glow := 0.93 + (sin(_ore_leak_phase) + 1.0) * 0.045
		_ore_leak_sprite.modulate = Color(glow, glow * 0.98, glow * 0.92, 1.0)
		_ore_leak_sprite.scale.y = 0.041 + sin(_ore_leak_phase * 0.5) * 0.0005
	if _room_task_feedback_timer > 0.0:
		_room_task_feedback_timer = maxf(_room_task_feedback_timer - delta, 0.0)
		if is_zero_approx(_room_task_feedback_timer):
			_room_task_feedback = ""

	_update_xenomorph_incubation(delta)

	# Allow walking straight through the huge open airlock door to exit to the planet
	if not _arrival_briefing_open and not _hud_modal_open and not _task_console_open and not _crew_dialogue_open:
		if is_instance_valid(exterior_airlock) and exterior_airlock.has_method("is_open") and bool(exterior_airlock.call("is_open")):
			var local_floor_pos := floor_layer.to_local(player.global_position)
			if local_floor_pos.x >= 434.0 and local_floor_pos.x <= 523.0 and local_floor_pos.y <= 278.0 and Input.is_action_pressed(&"move_up"):
				_exit_ship_to_planet()
				return

	_refresh_room_task_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning_to_planet or _arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open or _amara_ore_handoff_active or not event.is_action_pressed(&"interact"):
		return
	if _active_airlock_exit:
		get_viewport().set_input_as_handled()
		_exit_ship_to_planet()
		return
	if _active_amara_interaction:
		_begin_amara_dialogue()
	elif _active_crew_task_id != &"":
		_complete_crew_task(_active_crew_task_id)
	elif _active_lab_device_id != &"":
		_open_lab_device_console(_active_lab_device_id)
	elif _active_room_task_id != &"":
		_open_room_task_console(_active_room_task_id)
	else:
		return
	get_viewport().set_input_as_handled()


func _exit_ship_to_planet() -> void:
	if _transitioning_to_planet:
		return
	_transitioning_to_planet = true
	get_tree().change_scene_to_file(MOCK_PLANET_SCENE_PATH)


func _open_lab_device_console(device_id: StringName) -> void:
	if _task_console_open:
		return
	for device in LAB_DEVICES:
		if device["id"] != device_id:
			continue
		var station := get_node_or_null(device["station_path"]) as Node2D
		if station != null:
			player.face_toward(station.global_position)
		break
	if _is_lab_destroyed() or (_is_ore_villain_spawned() and device_id == &"lab_containment"):
		_room_task_feedback = "LAB STATION OFFLINE  //  DESTROYED BY THE ECHO"
		_room_task_feedback_timer = 3.5
		return
	if device_id == &"lab_containment" and _is_ore_sample_collected() and not _is_ore_sample_stored():
		_room_task_feedback = "HAND THE ORE SAMPLE TO DR. OKOYE AT HER WORKSTATION"
		_room_task_feedback_timer = 4.0
		return
	if device_id == &"lab_containment" and _is_ore_sample_stored():
		_room_task_feedback = "DR. OKOYE IS RUNNING THE CONTAINMENT CHECKS AT THE RESEARCH COMPUTER"
		_room_task_feedback_timer = 4.0
		return
	if device_id == &"lab_earth_comms" and _is_ore_sample_collected() and not _is_ore_sample_stored():
		_room_task_feedback = "HAND THE ORE SAMPLE TO DR. OKOYE  /  SHE WILL RUN THE STUDY"
		_room_task_feedback_timer = 4.0
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	var console_task_id := device_id
	if device_id == &"lab_earth_comms" and _is_ore_sample_collected():
		console_task_id = &"lab_containment"
	console.setup(console_task_id, 0, 1)
	if console_task_id == &"lab_containment":
		console.containment_stimulated.connect(_on_containment_stimulated)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _open_room_task_console(task_id: StringName) -> void:
	if _task_console_open:
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(task_id, _completed_room_tasks.size(), ROOM_TASKS.size())
	console.task_completed.connect(_on_room_task_completed)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _on_room_task_completed(task_id: StringName) -> void:
	if _completed_room_tasks.has(task_id):
		return
	var completion := "Service task complete."
	for task in ROOM_TASKS:
		if task["id"] == task_id:
			completion = task["completion"]
			break
	_completed_room_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	_room_task_feedback = "%s\nSERVICE TASKS  %d / %d COMPLETE" % [
		completion,
		_completed_room_tasks.size(),
		ROOM_TASKS.size(),
	]
	if _completed_room_tasks.size() == ROOM_TASKS.size():
		_room_task_feedback = "POWER, LIFE SUPPORT, AND HYDROPONICS ONLINE\nSHIP SERVICE TASKS COMPLETE"
	_pending_room_task_feedback = _room_task_feedback


func _on_room_task_console_closed() -> void:
	_task_console_open = false
	_update_contained_ore_sample()
	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()
	if not _pending_room_task_feedback.is_empty():
		_room_task_feedback = _pending_room_task_feedback
		_room_task_feedback_timer = 3.5
		_pending_room_task_feedback = ""


func _refresh_room_task_prompt() -> void:
	_active_room_task_id = &""
	_active_lab_device_id = &""
	_active_crew_task_id = &""
	_active_amara_interaction = false
	_active_airlock_exit = false
	if _amara_ore_handoff_active:
		_walk_hud.set_interaction_prompt("DR. OKOYE IS TAKING THE SAMPLE TO CONTAINMENT...", true)
		return
	if _crew_dialogue_open or not _arrival_briefing_open and (_hud_modal_open or _task_console_open):
		_walk_hud.set_interaction_prompt("", false)
		return
	if is_instance_valid(exterior_airlock):
		var airlock_access_pos := exterior_airlock.global_position + Vector2(0.0, 28.0)
		if player.global_position.distance_to(airlock_access_pos) <= AIRLOCK_INTERACTION_RADIUS:
			_active_airlock_exit = true
			_walk_hud.set_interaction_prompt("EXTERIOR AIRLOCK   /   [E] EXIT TO PLANET SURFACE", true)
			return
	if is_instance_valid(amara) and amara.visible and player.global_position.distance_to(amara.global_position) <= AMARA_INTERACTION_RADIUS:
		_active_amara_interaction = true
		if _is_ore_sample_collected() and not _is_ore_sample_stored():
			_walk_hud.set_interaction_prompt("DR. OKOYE   /   [E] HAND OVER EREBOS ORE", true)
		elif _is_ore_sample_stored() and not _is_ore_villain_spawned():
			_walk_hud.set_interaction_prompt("DR. OKOYE   /   [E] CHECK SAMPLE WATCH", true)
		else:
			_walk_hud.set_interaction_prompt("DR. OKOYE   /   [E] TALK", true)
		return
	var closest_crew_task: Dictionary = {}
	var closest_crew_distance := CREW_TASK_INTERACTION_RADIUS
	for task in AMARA_CREW_TASKS:
		var task_id: StringName = task["id"]
		if _completed_crew_tasks.has(task_id):
			continue
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_position := _crew_task_interaction_position(task, station)
		var distance := minf(
			player.global_position.distance_to(interaction_position),
			player.global_position.distance_to(station.global_position)
		)
		if distance <= closest_crew_distance:
			closest_crew_distance = distance
			closest_crew_task = task
	if not closest_crew_task.is_empty():
		_active_crew_task_id = closest_crew_task["id"]
		_walk_hud.set_interaction_prompt(closest_crew_task["prompt"], true)
		return
	var closest_device: Dictionary = {}
	var closest_device_distance := ROOM_TASK_INTERACTION_RADIUS
	for device in LAB_DEVICES:
		var device_id: StringName = device["id"]
		if not _is_lab_device_interactable(device_id):
			continue
		var station := get_node_or_null(device["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_position := _room_task_interaction_position(device, station)
		var distance := player.global_position.distance_to(interaction_position)
		if distance <= closest_device_distance:
			closest_device_distance = distance
			closest_device = device
	if not closest_device.is_empty():
		_active_lab_device_id = closest_device["id"]
		var prompt_text: String = closest_device["prompt"]
		if _is_lab_destroyed() or (_is_ore_villain_spawned() and _active_lab_device_id == &"lab_containment"):
			var station_title := prompt_text.split("   /   ")[0]
			prompt_text = "%s   /   DESTROYED BY THE ECHO" % station_title
		elif _active_lab_device_id == &"lab_containment" and _is_ore_sample_collected() and not _is_ore_sample_stored():
			prompt_text = "SAMPLE CONTAINMENT   /   GIVE ORE TO DR. OKOYE"
		elif _active_lab_device_id == &"lab_containment" and _xenomorph_timer_active:
			var secs_left := ceili(_xenomorph_countdown)
			prompt_text = "SAMPLE CONTAINMENT (BREACH IN %02d:%02d)   /   USE RESEARCH COMPUTER" % [secs_left / 60, secs_left % 60]
		elif _active_lab_device_id == &"lab_containment" and _is_ore_sample_stored():
			prompt_text = "SAMPLE CONTAINMENT   /   USE RESEARCH COMPUTER FOR PRESSURE CONTROLS"
		elif _active_lab_device_id == &"lab_earth_comms" and _is_ore_sample_stored():
			prompt_text = "RESEARCH COMPUTER   /   [E] OPEN ORE & ATM MONITOR"
		elif _active_lab_device_id == &"lab_earth_comms" and _is_ore_sample_collected():
			prompt_text = "RESEARCH COMPUTER   /   GIVE SAMPLE TO DR. OKOYE TO START STUDY"
		_walk_hud.set_interaction_prompt(prompt_text, true)
		return
	var closest_task: Dictionary = {}
	var closest_distance := 999999.0
	for task in ROOM_TASKS:
		var task_id: StringName = task["id"]
		if _completed_room_tasks.has(task_id):
			continue
		var station_path: NodePath = task["station_path"]
		var station := get_node_or_null(station_path) as Node2D
		if station == null:
			continue
		var interaction_pos := _room_task_interaction_position(task, station)
		var max_dist: float = task.get("interaction_radius", ROOM_TASK_INTERACTION_RADIUS)
		var distance := minf(
			player.global_position.distance_to(interaction_pos),
			player.global_position.distance_to(station.global_position)
		)
		if distance <= max_dist and distance <= closest_distance:
			closest_distance = distance
			closest_task = task

	if not closest_task.is_empty():
		_active_room_task_id = closest_task["id"]
		_walk_hud.set_interaction_prompt(closest_task["prompt"], true)
	elif _room_task_feedback_timer > 0.0:
		_walk_hud.set_interaction_prompt(_room_task_feedback, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _begin_amara_dialogue() -> void:
	if _crew_dialogue_open or _amara_ore_handoff_active:
		return
	if _is_ore_sample_collected() and not _is_ore_sample_stored():
		_amara_ore_handoff_active = true
		_walk_hud.set_walking_visible(false)
		_update_player_walk_state()
		_walk_hud.set_interaction_prompt("DR. OKOYE IS TAKING THE SAMPLE TO CONTAINMENT...", true)
		var containment := get_node_or_null("LabRoom/OreContainment") as Node2D
		var console_station := get_node_or_null("LabRoom/ConsoleStation") as Node2D
		var tank_position := _room_task_interaction_position(LAB_DEVICES[2], containment) if containment != null else Vector2(930.0, 495.0)
		var console_position := console_station.global_position + Vector2(0.0, 18.0) if console_station != null else Vector2(1049.0, 559.0)
		await amara.carry_sample_to_tank(tank_position)
		if not is_inside_tree():
			return
		_deposit_ore_into_containment()
		await amara.walk_to_research_console_and_sit(console_position)
		if not is_inside_tree():
			return
		_amara_ore_handoff_active = false
		_walk_hud.set_walking_visible(true)
		_room_task_feedback = "ORE STORED BY DR. OKOYE  /  SHE IS MONITORING FROM THE RESEARCH CONSOLE"
		_room_task_feedback_timer = 5.0
		_update_player_walk_state()
		return
	var first_meeting := not _amara_intro_seen
	_crew_dialogue_open = true
	_amara_intro_seen = true
	_walk_hud.set_walking_visible(false)
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(true)
	_update_player_walk_state()
	_walk_hud.set_interaction_prompt("", false)
	var lines: Array[String] = []
	var offer_tasks := false
	if _is_ore_sample_stored() and not _is_ore_villain_spawned():
		lines.append("The Erebos ore is secured. I'm running the chamber checks and monitoring its response from the research console.")
		if Engine.has_meta(&"resonance_ore_stimulated") and bool(Engine.get_meta(&"resonance_ore_stimulated")):
			lines.append("It is responding to the electrical pulse. Something inside the sample is moving.")
	elif first_meeting:
		lines.append("I'm Dr. Amara Okoye, astrobiologist. Please mine a resonance ore sample on Erebos and bring it back to me. I'll load the tank and monitor it from the research console.")
	else:
		lines.append("I'm staying at the research console and keeping watch over the sample readings.")
	_crew_dialogue.start_dialogue(lines, offer_tasks)


func _is_lab_device_interactable(device_id: StringName) -> bool:
	if device_id == &"lab_earth_comms":
		return true
	if device_id == &"lab_containment":
		return _is_ore_sample_stored() or (_is_ore_sample_collected() and not _is_ore_sample_stored())
	return false


func _on_amara_dialogue_finished(accepted_tasks: bool) -> void:
	_crew_dialogue_open = false
	if not _arrival_briefing_open and not _task_console_open and not _amara_ore_handoff_active:
		_walk_hud.set_walking_visible(true)
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(false)
	if accepted_tasks and not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud()
		_room_task_feedback = "Amara's jobs are marked at reachable service points on your ship map."
		_room_task_feedback_timer = 4.0
	_update_player_walk_state()


func _unlock_crew_tasks_on_hud() -> void:
	if _crew_tasks_unlocked:
		return
	_crew_tasks_unlocked = true
	for task in AMARA_CREW_TASKS:
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		_walk_hud.add_task_entry({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"position": _crew_task_interaction_position(task, station),
			"marker_position": _task_marker_position(station),
		})


func _room_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent := station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _crew_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent := station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _task_marker_position(station: Node2D, offset: Vector2 = Vector2.ZERO) -> Vector2:
	if station is AnimatedSprite2D:
		var animated_station := station as AnimatedSprite2D
		if animated_station.sprite_frames != null:
			var texture := animated_station.sprite_frames.get_frame_texture(animated_station.animation, animated_station.frame)
			if texture != null:
				var top_offset := animated_station.offset + Vector2(0.0, -texture.get_height() * 0.5 - 12.0) + offset
				return animated_station.to_global(top_offset)
	return station.global_position + Vector2(0.0, -36.0) + offset


func _complete_crew_task(task_id: StringName) -> void:
	if _completed_crew_tasks.has(task_id):
		return
	if not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud()
	var completion := "Hydroponics check complete."
	for task in AMARA_CREW_TASKS:
		if task["id"] == task_id:
			completion = task["completion"]
			break
	_completed_crew_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	_room_task_feedback = "%s\nAMARA'S JOBS  %d / %d COMPLETE" % [completion, _completed_crew_tasks.size(), AMARA_CREW_TASKS.size()]
	_room_task_feedback_timer = 4.0


func _on_arrival_briefing_dismissed() -> void:
	_arrival_briefing_open = false
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()
	call_deferred("_begin_amara_dialogue")


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open or _amara_ore_handoff_active))
