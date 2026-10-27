@tool
extends Node2D

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const RESONANCE_ORE_TANK_STORED_TEXTURE := preload("res://art/planet/modern_ore_containment_stored.png")
const RESONANCE_ORE_TANK_CRACKING_TEXTURE := preload("res://art/planet/modern_ore_containment_cracking.png")
const RESONANCE_ORE_TANK_ARM_BREAKOUT_TEXTURE := preload("res://art/planet/modern_ore_containment_arm_breakout.png")
const RESONANCE_ORE_TANK_HATCHED_TEXTURE := preload("res://art/planet/modern_ore_containment_hatched.png")
const RESONANCE_ORE_VILLAIN_SCENE := preload("res://scenes/ship/crew/resonance_ore_villain.tscn")
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


class LabWreckageLayer extends Node2D:
	var destroyed_stages: int = 0
	var spark_time: float = 0.0

	func set_destroyed_stages(stages: int) -> void:
		if destroyed_stages == stages:
			return
		destroyed_stages = stages
		queue_redraw()

	func _process(delta: float) -> void:
		if destroyed_stages <= 0:
			return
		spark_time = fposmod(spark_time + delta, 100.0)
		queue_redraw()

	func _draw() -> void:
		if destroyed_stages <= 0:
			return
		# Stage 1+: Irregular pixel-art bio-fluid spill & scorched debris below OreContainment (236, 74..104)
		var spill_outer := PackedVector2Array([
			Vector2(198, 92), Vector2(214, 88), Vector2(236, 90), Vector2(262, 89),
			Vector2(272, 96), Vector2(258, 106), Vector2(234, 110), Vector2(210, 105)
		])
		draw_colored_polygon(spill_outer, Color(0.05, 0.24, 0.28, 0.46))
		var spill_core := PackedVector2Array([
			Vector2(212, 94), Vector2(238, 92), Vector2(254, 96),
			Vector2(246, 104), Vector2(226, 105), Vector2(214, 100)
		])
		draw_colored_polygon(spill_core, Color(0.14, 0.58, 0.64, 0.42))
		for shard in [Vector2(204, 96), Vector2(222, 108), Vector2(238, 104), Vector2(252, 95), Vector2(268, 104), Vector2(194, 88)]:
			var pts := PackedVector2Array([
				shard + Vector2(-4.0, -2.0),
				shard + Vector2(5.0, -1.0),
				shard + Vector2(1.0, 4.0),
			])
			draw_colored_polygon(pts, Color(0.45, 0.92, 1.0, 0.82))
		_draw_claw_slashes(Vector2(236.0, 74.0), 18.0)

		if destroyed_stages >= 2:
			# Stage 2+: Archive racks (313, 76), (350, 76), (387, 76) scorched & slashed
			for ax in [313.0, 350.0, 387.0]:
				draw_circle(Vector2(ax, 84.0), 15.0, Color(0.03, 0.03, 0.04, 0.52))
				_draw_claw_slashes(Vector2(ax, 76.0), 13.0)
				_draw_spark(Vector2(ax + 4.0, 68.0), ax * 0.13)

		if destroyed_stages >= 3:
			# Stage 3+: Specimen Analysis Table (290, 158) & Robotic Arm (312, 146) smashed
			draw_circle(Vector2(290.0, 158.0), 28.0, Color(0.03, 0.04, 0.05, 0.56))
			draw_circle(Vector2(276.0, 162.0), 16.0, Color(0.10, 0.48, 0.56, 0.45))
			_draw_claw_slashes(Vector2(290.0, 156.0), 22.0)
			_draw_spark(Vector2(282.0, 148.0), 1.7)
			_draw_spark(Vector2(312.0, 144.0), 3.1)

		if destroyed_stages >= 4:
			# Stage 4+: Research Console (355, 158) & Right Storage Cabinet smashed
			draw_circle(Vector2(355.0, 160.0), 20.0, Color(0.03, 0.03, 0.04, 0.54))
			_draw_claw_slashes(Vector2(355.0, 156.0), 16.0)
			_draw_spark(Vector2(356.0, 152.0), 4.4)

		if destroyed_stages >= 5:
			# Stage 5+: Instrument Trolley (290, 205) knocked over & reagents spilled
			draw_circle(Vector2(280.0, 210.0), 18.0, Color(0.86, 0.52, 0.16, 0.42))
			draw_circle(Vector2(296.0, 214.0), 14.0, Color(0.16, 0.68, 0.54, 0.44))
			_draw_claw_slashes(Vector2(286.0, 206.0), 15.0)

		if destroyed_stages >= 6:
			# Stage 6+: Left Storage Cabinets (134, 72), Waste Bins (467, 82), Wash Sink (468, 155) wrecked
			draw_circle(Vector2(126.0, 82.0), 18.0, Color(0.03, 0.04, 0.05, 0.50))
			_draw_claw_slashes(Vector2(126.0, 74.0), 16.0)
			draw_circle(Vector2(458.0, 92.0), 14.0, Color(0.22, 0.32, 0.16, 0.46))
			draw_circle(Vector2(456.0, 162.0), 18.0, Color(0.18, 0.56, 0.72, 0.46))
			_draw_claw_slashes(Vector2(464.0, 154.0), 14.0)
			_draw_spark(Vector2(130.0, 72.0), 5.8)

	func _draw_claw_slashes(center: Vector2, span: float) -> void:
		for idx in range(5):
			var ang := float(idx) * 1.25 + 0.3
			var shard_pos := center + Vector2(cos(ang), sin(ang)) * (span * 0.55)
			var pts := PackedVector2Array([
				shard_pos + Vector2(-2.5, -1.5),
				shard_pos + Vector2(3.0, -0.5),
				shard_pos + Vector2(0.5, 2.5),
			])
			draw_colored_polygon(pts, Color(0.38, 0.86, 0.96, 0.72) if idx % 2 == 0 else Color(0.92, 0.58, 0.22, 0.72))

	func _draw_spark(pos: Vector2, phase: float) -> void:
		# Animated bubbling green bio-fluid droplets near the breached tank
		for b_idx in range(4):
			var b_phase := fposmod(spark_time * 0.9 + float(b_idx) * 0.25 + phase * 0.1, 1.0)
			var b_pos := Vector2(222.0 + float(b_idx) * 11.0, 98.0 - b_phase * 8.0)
			draw_circle(b_pos, 1.4 + sin(b_phase * PI) * 1.4, Color(0.42, 0.98, 0.72, 0.55 * (1.0 - b_phase)))
		var pulse := sin(spark_time * 24.0 + phase * 5.0)
		if pulse < 0.15:
			return
		var col := Color(1.0, 0.88, 0.32, 0.95) if pulse > 0.55 else Color(0.38, 0.92, 1.0, 0.88)
		for idx in range(5):
			var angle := phase + spark_time * 15.0 + float(idx) * 1.25
			var mid := pos + Vector2(cos(angle + 0.28), sin(angle + 0.28)) * (3.5 + 2.5 * pulse)
			var tip := pos + Vector2(cos(angle), sin(angle)) * (7.0 + 5.5 * pulse)
			draw_line(pos, mid, col, 1.6, false)
			draw_line(mid, tip, col, 1.2, false)
		draw_circle(pos, 2.4, Color(1.0, 0.98, 0.9, 0.95))


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
var _active_crew_task_id: StringName = &""
var _active_airlock_exit := false
var _transitioning_to_planet := false
var _xenomorph_timer_active := false
var _xenomorph_countdown := XENOMORPH_INCUBATION_SECONDS
var _xenomorph_visual_stage := -1
var _tank_countdown_label: Label
var _lab_wreckage_layer: LabWreckageLayer


func _load_sprite_png(sprite: Sprite2D, res_path: String) -> void:
	if not is_instance_valid(sprite):
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null and not img.is_empty():
		sprite.texture = ImageTexture.create_from_image(img)


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
	_tank_countdown_label.name = "XenomorphCountdownLabel"
	_tank_countdown_label.position = Vector2(174.0, 42.0)
	_tank_countdown_label.z_index = 6
	_tank_countdown_label.add_theme_font_size_override("font_size", 9)
	_tank_countdown_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.36))
	_tank_countdown_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.95))
	_tank_countdown_label.add_theme_constant_override("outline_size", 3)
	_tank_countdown_label.visible = false
	lab_room.add_child(_tank_countdown_label)
	return _tank_countdown_label


func _ensure_lab_wreckage_layer() -> LabWreckageLayer:
	if is_instance_valid(_lab_wreckage_layer):
		return _lab_wreckage_layer
	var lab_room := get_node_or_null("LabRoom") as Node2D
	if lab_room == null:
		return null
	_lab_wreckage_layer = LabWreckageLayer.new()
	_lab_wreckage_layer.name = "LabWreckageLayer"
	_lab_wreckage_layer.z_index = 2
	lab_room.add_child(_lab_wreckage_layer)
	return _lab_wreckage_layer


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
		lbl.text = "BIO-BREACH  %02d:%02d" % [mins, secs]
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
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_stored.png")
				tank_sprite.modulate = Color.WHITE
			1:
				tank_sprite.texture = RESONANCE_ORE_TANK_CRACKING_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_cracking.png")
				tank_sprite.modulate = Color(1.12, 0.96, 0.78)
				_room_task_feedback = "CONTAINMENT ALERT: SILICATE SHELL FRACTURING — CLAW EMERGING!"
				_room_task_feedback_timer = 4.5
			2:
				tank_sprite.texture = RESONANCE_ORE_TANK_ARM_BREAKOUT_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_arm_breakout.png")
				tank_sprite.modulate = Color(1.18, 0.9, 0.72)
				_room_task_feedback = "CONTAINMENT CRITICAL: ARMORED LIMB & TENDRILS BREACHING SHELL!"
				_room_task_feedback_timer = 4.5
			3:
				Engine.set_meta(&"resonance_ore_sample_evolved", true)
				tank_sprite.texture = RESONANCE_ORE_TANK_HATCHED_TEXTURE
				_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_hatched.png")
				tank_sprite.scale = Vector2(0.92, 0.92)
				var hatch := create_tween().set_parallel(true)
				hatch.tween_property(tank_sprite, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				hatch.tween_property(tank_sprite, "modulate", Color(1.2, 0.75, 0.68), 0.3)
				hatch.tween_property(tank_sprite, "modulate", Color.WHITE, 0.3).set_delay(0.3)
				_room_task_feedback = "WARNING: XENOMORPH HATCHED IN TANK — CONTAINMENT FAILING!"
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
	var wreckage := _ensure_lab_wreckage_layer()
	if is_instance_valid(wreckage):
		wreckage.set_destroyed_stages(max(wreckage.destroyed_stages, stage))
	var scorch_tint := Color(0.74, 0.68, 0.66, 1.0)
	match stage:
		1:
			# Stage 1: OreContainment shattered & cable severed
			_load_sprite_png(get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D, "res://art/planet/modern_ore_containment_destroyed.png")
			_wreck_lab_prop(NodePath("LabRoom/OreContainment"), -0.05, Vector2(0.0, 3.0), Color.WHITE, animate)
			var sleeve := get_node_or_null("LabRoom/CableRuns/ContainmentToAnalysisSleeve") as Line2D
			var sig := get_node_or_null("LabRoom/CableRuns/ContainmentToAnalysisSignal") as Line2D
			if sleeve != null:
				sleeve.points = PackedVector2Array([Vector2(248, 92), Vector2(256, 102)])
			if sig != null:
				sig.default_color = Color(1.0, 0.42, 0.18, 0.95)
				sig.points = PackedVector2Array([Vector2(248, 92), Vector2(256, 102)])
		2:
			# Stage 2: Data Archive Racks slashed & tilted with destroyed textures
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationLeft/DataArchive") as Sprite2D, "res://art/concepts/lab_props/data_archive_destroyed.png")
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationCenter/DataArchive") as Sprite2D, "res://art/concepts/lab_props/data_archive_destroyed.png")
			_load_sprite_png(get_node_or_null("LabRoom/ArchiveStationRight/DataArchive") as Sprite2D, "res://art/concepts/lab_props/data_archive_destroyed.png")
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationLeft"), -0.14, Vector2(-3.0, 2.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationCenter"), 0.10, Vector2(2.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/ArchiveStationRight"), -0.15, Vector2(3.0, 2.0), Color.WHITE, animate)
			for gl_name in ["ArchiveGlowLeft", "ArchiveGlowCenter", "ArchiveGlowRight"]:
				var gl := get_node_or_null("LabRoom/StationLighting/" + gl_name) as PointLight2D
				if gl != null:
					gl.color = Color(1.0, 0.32, 0.18, 1.0)
		3:
			# Stage 3: Specimen Analysis Table & Robotic Arm smashed with destroyed textures
			_load_sprite_png(get_node_or_null("LabRoom/NorthWorkstation/SpecimenAnalysisTable") as Sprite2D, "res://art/concepts/lab_props/specimen_analysis_table_destroyed.png")
			_load_sprite_png(get_node_or_null("LabRoom/SampleManipulator/RoboticSampleArm") as Sprite2D, "res://art/concepts/lab_props/sample_robot_arm_destroyed.png")
			_wreck_lab_prop(NodePath("LabRoom/NorthWorkstation"), -0.07, Vector2(-4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/SampleManipulator"), 0.58, Vector2(6.0, -4.0), Color.WHITE, animate)
			var ag := get_node_or_null("LabRoom/StationLighting/AnalysisGlow") as PointLight2D
			if ag != null:
				ag.color = Color(1.0, 0.28, 0.16, 1.0)
		4:
			# Stage 4: Research Console & Right Storage Cabinet smashed with destroyed textures
			_load_sprite_png(get_node_or_null("LabRoom/ConsoleStation/ResearchConsole") as Sprite2D, "res://art/concepts/lab_props/research_console_destroyed.png")
			_wreck_lab_prop(NodePath("LabRoom/ConsoleStation"), 0.15, Vector2(4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/StorageCabinetRightView"), -0.08, Vector2(-2.0, 2.0), scorch_tint, animate)
			var cg := get_node_or_null("LabRoom/StationLighting/ConsoleGlow") as PointLight2D
			if cg != null:
				cg.color = Color(1.0, 0.34, 0.16, 1.0)
		5:
			# Stage 5: Instrument Trolley knocked over onto its side with destroyed texture
			_load_sprite_png(get_node_or_null("LabRoom/MicroscopeCart/InstrumentTrolley") as Sprite2D, "res://art/concepts/lab_props/instrument_trolley_destroyed.png")
			_wreck_lab_prop(NodePath("LabRoom/MicroscopeCart"), -0.68, Vector2(-10.0, 6.0), Color.WHITE, animate)
			var wg := get_node_or_null("LabRoom/StationLighting/CartWorklight") as PointLight2D
			if wg != null:
				wg.color = Color(1.0, 0.25, 0.14, 1.0)
		6:
			# Stage 6: Left Storage Cabinet, Waste Bins & Wash Sink destroyed
			_wreck_lab_prop(NodePath("LabRoom/LeftStorageCabinet"), 0.12, Vector2(-3.0, 3.0), scorch_tint, animate)
			_wreck_lab_prop(NodePath("LabRoom/LabWasteBins"), 0.54, Vector2(-6.0, 5.0), scorch_tint, animate)
			_wreck_lab_prop(NodePath("LabRoom/WashSink"), -0.20, Vector2(-3.0, 2.0), scorch_tint, animate)
			Engine.set_meta(&"lab_destroyed_by_xenomorph", true)
			var lbl := _ensure_tank_countdown_label()
			if is_instance_valid(lbl):
				lbl.visible = true
				lbl.text = "LAB DESTROYED // XENOMORPH LOOSE"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22))
			if animate:
				_room_task_feedback = "CRITICAL ALERT: THE XENOMORPH HAS DESTROYED THE ENTIRE LAB!"
				_room_task_feedback_timer = 6.5


func _destroy_all_lab_immediately() -> void:
	for st in range(1, 7):
		_apply_lab_destruction_stage(st, false)


func _on_villain_rampage_station_hit(station_idx: int) -> void:
	# station_idx 0..4 correspond to stages 2..6 (stage 1 was OreContainment on breakout)
	var stage := clampi(station_idx + 2, 2, 6)
	_apply_lab_destruction_stage(stage, true)


func _spawn_resonance_ore_villain(play_breakout_fx: bool) -> void:
	Engine.set_meta(&"resonance_ore_sample_evolved", true)
	Engine.set_meta(&"resonance_ore_villain_spawned", true)
	var lab_room := get_node_or_null("LabRoom") as Node2D
	var containment := get_node_or_null("LabRoom/OreContainment") as Node2D
	if containment == null or lab_room == null:
		return
	var tank_sprite := containment.get_node_or_null("SampleContainment") as Sprite2D
	if tank_sprite != null:
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_destroyed.png")
	var containment_glow := get_node_or_null("LabRoom/StationLighting/ContainmentGlow") as PointLight2D
	if containment_glow != null:
		containment_glow.visible = true
		containment_glow.color = Color(1.0, 0.28, 0.16, 1.0)
		containment_glow.energy = 0.68
	var room_lighting := get_node_or_null("ShipRoomLighting")
	if room_lighting != null and room_lighting.has_method("set_room_flicker"):
		room_lighting.call("set_room_flicker", &"r08_central_bay", true)

	_apply_lab_destruction_stage(1, play_breakout_fx)

	var villain := get_node_or_null("ResonanceOreVillain") as ResonanceOreVillain
	if villain == null:
		villain = RESONANCE_ORE_VILLAIN_SCENE.instantiate() as ResonanceOreVillain
		villain.name = "ResonanceOreVillain"
		add_child(villain)

	var landing_pos := lab_room.to_global(Vector2(236.0, 114.0))
	if play_breakout_fx and not _is_lab_destroyed():
		villain.global_position = containment.global_position + Vector2(0.0, 6.0)
		villain.scale = Vector2(0.55, 0.55)
		var rampage_points: Array[Vector2] = [
			lab_room.to_global(Vector2(350.0, 106.0)), # Archive racks
			lab_room.to_global(Vector2(290.0, 134.0)), # Specimen Analysis Table & Robot Arm
			lab_room.to_global(Vector2(355.0, 134.0)), # Research Console
			lab_room.to_global(Vector2(290.0, 196.0)), # Instrument Trolley
			lab_room.to_global(Vector2(158.0, 106.0)), # Left Storage Cabinets & final Lab sweep
		]
		if not villain.rampage_station_hit.is_connected(_on_villain_rampage_station_hit):
			villain.rampage_station_hit.connect(_on_villain_rampage_station_hit)
		var leap := create_tween().set_parallel(true)
		leap.tween_property(villain, "global_position", landing_pos, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		leap.tween_property(villain, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		leap.chain().tween_callback(func() -> void:
			if is_instance_valid(villain):
				villain.start_lab_rampage(rampage_points)
		)
		_room_task_feedback = "ALERT: XENOMORPH BROKE CONTAINMENT — DESTROYING ALL LAB STATIONS!"
		_room_task_feedback_timer = 6.5
	else:
		villain.global_position = landing_pos
		_destroy_all_lab_immediately()


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
		tank_sprite.texture = RESONANCE_ORE_TANK_HATCHED_TEXTURE
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_hatched.png")
	else:
		tank_sprite.texture = RESONANCE_ORE_TANK_STORED_TEXTURE
		_load_sprite_png(tank_sprite, "res://art/planet/modern_ore_containment_stored.png")
	tank_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tank_sprite.set_meta(&"hatched", is_evolved)
	_start_xenomorph_incubation_timer()


func _deposit_ore_into_containment() -> void:
	Engine.set_meta(&"resonance_ore_sample_stored", true)
	Engine.set_meta(&"resonance_ore_incubation_remaining", XENOMORPH_INCUBATION_SECONDS)
	if is_instance_valid(_walk_hud) and _walk_hud.has_method("consume_item"):
		_walk_hud.consume_item(&"resonance_ore_sample")
	_display_contained_ore_sample()
	var tank_sprite := get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D
	if tank_sprite != null:
		tank_sprite.scale = Vector2(0.94, 0.94)
		var place_tween := create_tween().set_parallel(true)
		place_tween.tween_property(tank_sprite, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		place_tween.tween_property(tank_sprite, "modulate", Color(0.82, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		place_tween.tween_property(tank_sprite, "modulate", Color.WHITE, 0.25).set_delay(0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_start_xenomorph_incubation_timer()
	_room_task_feedback = "RESONANCE ORE PLACED IN CONTAINMENT  //  1:00 BIO-INCUBATION STARTED"
	_room_task_feedback_timer = 4.5


func _update_contained_ore_sample() -> void:
	if _is_ore_sample_stored() and is_instance_valid(_walk_hud) and _walk_hud.has_method("consume_item"):
		_walk_hud.consume_item(&"resonance_ore_sample")
	_display_contained_ore_sample()
	if _is_ore_sample_stored() and not _is_ore_villain_spawned():
		_start_xenomorph_incubation_timer()


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
	_display_contained_ore_sample()

	# Movement samples global positions; include any saved ship-root translation.
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.global_position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)

	var returning_from_planet := Engine.has_meta(&"returning_from_planet") and bool(Engine.get_meta(&"returning_from_planet"))
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
	if _transitioning_to_planet or _arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open or not event.is_action_pressed(&"interact"):
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
		_room_task_feedback = "LAB STATION OFFLINE  //  DESTROYED BY XENOMORPH BREACH"
		_room_task_feedback_timer = 3.5
		return
	if device_id == &"lab_containment" and _is_ore_sample_collected() and not _is_ore_sample_stored():
		_deposit_ore_into_containment()
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(device_id, 0, 1)
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
	if _crew_dialogue_open or not _arrival_briefing_open and (_hud_modal_open or _task_console_open):
		_walk_hud.set_interaction_prompt("", false)
		return
	if is_instance_valid(exterior_airlock):
		var airlock_access_pos := exterior_airlock.global_position + Vector2(0.0, 28.0)
		if player.global_position.distance_to(airlock_access_pos) <= AIRLOCK_INTERACTION_RADIUS:
			_active_airlock_exit = true
			_walk_hud.set_interaction_prompt("EXTERIOR AIRLOCK   /   [E] EXIT TO PLANET SURFACE", true)
			return
	if is_instance_valid(amara) and player.global_position.distance_to(amara.global_position) <= AMARA_INTERACTION_RADIUS:
		_active_amara_interaction = true
		_walk_hud.set_interaction_prompt("AMARA OKOYE   /   [E] TALK", true)
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
			prompt_text = "%s   /   DESTROYED BY XENOMORPH" % station_title
		elif _active_lab_device_id == &"lab_containment" and _is_ore_sample_collected() and not _is_ore_sample_stored():
			prompt_text = "SAMPLE CONTAINMENT   /   [E] PLACE RESONANCE ORE IN TANK"
		elif _active_lab_device_id == &"lab_containment" and _xenomorph_timer_active:
			var secs_left := ceili(_xenomorph_countdown)
			prompt_text = "SAMPLE CONTAINMENT (BREACH IN %02d:%02d)   /   [E] OPEN CONTROLS" % [secs_left / 60, secs_left % 60]
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
	if _crew_dialogue_open:
		return
	var first_meeting := not _amara_intro_seen
	_crew_dialogue_open = true
	_amara_intro_seen = true
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(true)
	_update_player_walk_state()
	_walk_hud.set_interaction_prompt("", false)
	var lines: Array[String] = []
	var offer_tasks := not _crew_tasks_unlocked
	if offer_tasks:
		if first_meeting:
			lines.append("I'm Amara Okoye. I keep the grow beds alive, and I know this section of the ship inside out.")
			lines.append("The nutrient pump needs an inspection, and the seedling rack's humidity sensor needs recalibrating.")
		else:
			lines.append("I've got two hydroponics jobs that could use another set of hands: the nutrient pump and the seedling rack sensor.")
		lines.append("Want to take them? I'll mark a reachable service point beside each station on your ship map.")
	else:
		var completed_count := _completed_crew_tasks.size()
		if completed_count >= AMARA_CREW_TASKS.size():
			lines.append("The pump is flowing and the seedling sensor is steady. The beds should be in good shape now. Thank you.")
		elif completed_count == 1:
			for task in AMARA_CREW_TASKS:
				if not _completed_crew_tasks.has(task["id"]):
					lines.append("Good work on the first job. %s still needs attention when you have a moment." % str(task["title"]).replace("Amara: ", ""))
					break
		else:
			lines.append("The nutrient pump and seedling sensor are both marked on your ship map. Check in with me if anything looks off.")
	_crew_dialogue.start_dialogue(lines, offer_tasks)


func _on_amara_dialogue_finished(accepted_tasks: bool) -> void:
	_crew_dialogue_open = false
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


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open))
