@tool
extends Node2D

const FLOOR_TEXTURE: Texture2D = preload("res://art/overview/asteria_overview_floor.png")
const RESONANCE_ORE_TANK_STORED_TEXTURE := preload("res://art/concepts/lab_props/ore_containment_stored_refined.png")
const RESONANCE_ORE_TANK_CRACKING_TEXTURE := preload("res://art/planet/modern_ore_containment_cracking.png")
const RESONANCE_ORE_TANK_DESTROYED_TEXTURE := preload("res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png")
const RESONANCE_ORE_LEAK_TEXTURE := preload("res://art/concepts/lab_props/destroyed/ore_leak_tank_to_floor.png")
const RESONANCE_ORE_VILLAIN_SCENE := preload("res://scenes/ship/crew/resonance_ore_villain.tscn")
const ECHO_LIQUID_ATLAS := preload("res://art/characters/runtime/echo_liquid_walk_4dir.png")
const XENOMORPH_INCUBATION_SECONDS := 60.0
const ARRIVAL_BRIEFING_SCENE: PackedScene = preload("res://scenes/ui/arrival_briefing.tscn")
const SERVICE_TASK_CONSOLE_SCENE: PackedScene = preload("res://scenes/ui/service_task_console.tscn")
const WALK_HUD_SCENE: PackedScene = preload("res://scenes/ui/walk_hud.tscn")
const CREW_DIALOGUE_SCENE: PackedScene = preload("res://scenes/ui/crew_dialogue.tscn")
const STORY_CUTSCENE_SCRIPT: Script = preload("res://scripts/ui/story_cutscene_overlay.gd")
const SHIP_PILOTING_SCRIPT: Script = preload("res://scripts/ui/ship_piloting_console.gd")
const MOCK_PLANET_SCENE_PATH: String = "res://scenes/planet/mock_planet_exterior.tscn"
const SECOND_FLOOR_SCENE_PATH: String = "res://scenes/ship/second_floor_subdeck.tscn"
const AIRLOCK_INTERACTION_RADIUS: float = 92.0
const AIRLOCK_RETURN_FLOOR_POS: Vector2 = Vector2(478.5, 294.0)
const SUBDECK_LIFT_FLOOR_POS: Vector2 = Vector2(862.0, 321.0)
const SUBDECK_RETURN_FLOOR_POS: Vector2 = Vector2(862.0, 350.0)
const SUBDECK_LIFT_INTERACTION_RADIUS: float = 58.0
const STORY_STATE_META_KEY: StringName = &"echoes_story_progression_state"
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

const LAB_DOOR_REPAIR_TASK_ID := &"repair_lab_pressure_door"
const LAB_ENTRY_TASK_ID := &"investigate_echo_lab"
const RIG_REPORT_TASK_ID := &"report_failed_rig"

# Strengthened multi-task storyline: individual tasks advance the story & ship systems,
# and equipment is earned only after completing multi-task storyline milestones!
const ROOM_TASKS: Array[Dictionary] = [
	{
		"id": &"auxiliary_power",
		"title": "Reconnect aux power bus (Task 3/4 -> Multitool)",
		"marker_label": "AUX POWER",
		"station_path": NodePath("PowerMaintenanceRoomProps/PowerCellModule"),
		"marker_offset": Vector2(0.0, -24.0),
		"prompt": "AUXILIARY POWER CELL   /   [E] RECONNECT POWER BUS",
		"completion": "Auxiliary power bus synced (1/2 Engineering checks complete — finish Life Support to unlock Engineering Multitool).",
		"reward_item": &"",
		"log_id": &"log_leila_power",
	},
	{
		"id": &"air_filter",
		"title": "Replace air scrubber (Unlocks Multitool)",
		"marker_label": "LIFE SUPPORT",
		"station_path": NodePath("LifeSupportRoomProps/FilterCartridge"),
		"marker_offset": Vector2(0.0, -26.0),
		"prompt": "LIFE-SUPPORT FILTER   /   [E] REPLACE SCRUBBER CARTRIDGE",
		"completion": "Life-support scrubbers online! Milestone reached (4 Tasks): Engineering Multitool unlocked!",
		"reward_item": &"engineering_multitool",
		"log_id": &"",
	},
	{
		"id": &"nutrient_flow",
		"title": "Route nutrient flow (Task 5/6 -> Scanner & Sealant)",
		"marker_label": "HYDROPONICS",
		"station_path": NodePath("HydroponicsRoomProps/ControlConsole"),
		"interaction_offset": Vector2(32.0, 0.0),
		"marker_offset": Vector2(0.0, -22.0),
		"interaction_radius": 65.0,
		"prompt": "HYDROPONICS CONSOLE   /   [E] ROUTE NUTRIENTS",
		"completion": "Nutrient manifold aligned (1/2 Science checks complete — calibrate Drone Array next to unlock Scanner & Sealant).",
		"reward_item": &"",
		"log_id": &"log_okoye_fields",
	},
]
const ROOM_TASK_INTERACTION_RADIUS: float = 44.0
const AMARA_INTERACTION_RADIUS: float = 66.0
const CREW_TASK_INTERACTION_RADIUS: float = 64.0
const STORY_STATION_INTERACTION_RADIUS: float = 68.0

# Both of Amara's Hydroponics crew jobs must be completed to earn the Medical Injector
const AMARA_CREW_TASKS: Array[Dictionary] = [
	{
		"id": &"amara_nutrient_pump",
		"title": "Amara (1/2): Inspect nutrient pump",
		"marker_label": "AMARA / PUMP",
		"station_path": NodePath("HydroponicsRoomProps/NutrientPump"),
		"interaction_offset": Vector2(36.0, 0.0),
		"marker_offset": Vector2(0.0, -22.0),
		"prompt": "NUTRIENT PUMP   /   [E] INSPECT",
		"completion": "The nutrient pump is clear and flowing again (1/2 Amara checks complete).",
		"reward_item": &"",
	},
	{
		"id": &"amara_seedling_sensor",
		"title": "Amara (2/2): Calibrate seedling sensor (Med Injector)",
		"marker_label": "SEEDLINGS",
		"station_path": NodePath("HydroponicsRoomProps/SeedlingRack"),
		"interaction_offset": Vector2(44.0, 0.0),
		"marker_offset": Vector2(0.0, -28.0),
		"prompt": "SEEDLING RACK   /   [E] CALIBRATE SENSOR",
		"completion": "Seedling humidity sensor calibrated.",
		"reward_item": &"",
	},
]

# Storyline, Ship Driving & Cutscene stations across the Main Deck for Acts I, III, IV, and V
const STORY_STATIONS: Array[Dictionary] = [
	{
		"id": &"cabin_may_recording",
		"title": "Play May's Yangon message (Task 1/2 -> Suit Light)",
		"marker_label": "CREW BUNK",
		"station_path": NodePath("CrewLivingQuarterProps/PersonalComputerDesk"),
		"interaction_offset": Vector2(0.0, 44.0),
		"marker_offset": Vector2(0.0, -24.0),
		"prompt": "THURA'S BUNK & TERMINAL   /   [E] PLAY MAY'S RECORDING",
		"reward_item": &"",
		"log_id": &"log_may_message",
	},
	{
		"id": &"bridge_flight_piloting",
		"title": "Pilot ship & evade asteroids (Unlocks Suit Light [F])",
		"marker_label": "PILOT HELM",
		"station_path": NodePath("BridgeRoomProps/UpperBowFlightConsole"),
		"interaction_offset": Vector2(28.0, 14.0),
		"marker_offset": Vector2(0.0, -26.0),
		"prompt": "BRIDGE FLIGHT HELM   /   [E] MONITOR AUTOPILOT & PILOT SHIP",
		"reward_item": &"suit_flashlight",
		"log_id": &"",
	},
	{
		"id": &"drone_vibration_scan",
		"title": "Scan Erebos drone feed (Unlocks Scanner & Sealant)",
		"marker_label": "DRONE BAY",
		"station_path": NodePath("CargoBayProps/MaintenanceTrolley"),
		"interaction_offset": Vector2(-34.0, 0.0),
		"marker_offset": Vector2(0.0, -34.0),
		"prompt": "MINING DRONE RIG   /   [E] REPAIR DRONE & SCAN EREBOS",
		"reward_item": &"mineral_survey_scanner",
		"log_id": &"log_ruiz_sponsors",
	},
	{
		"id": &"landing_prep_beacons",
		"title": "Prep Site K-12 gear (Unlocks Survey Beacon)",
		"marker_label": "SHUTTLE BAY",
		"station_path": NodePath("ShuttleBayCargo"),
		"interaction_offset": Vector2(-42.0, -18.0),
		"marker_offset": Vector2(-16.0, -38.0),
		"prompt": "SHUTTLE LANDING CRATES   /   [E] PREP SITE K-12 BEACONS",
		"reward_item": &"survey_beacon",
		"log_id": &"log_ward_daughter",
	},
	{
		"id": &"cargo_breach_inspection",
		"title": "Inspect breached drill core (Act IV Hunt)",
		"marker_label": "SAMPLE CORE",
		"station_path": NodePath("CargoBayProps/CargoInspectionScale"),
		"interaction_offset": Vector2(-38.0, 12.0),
		"marker_offset": Vector2(0.0, -34.0),
		"prompt": "DRILL CORE CONTAINMENT   /   [E] INSPECT MASS ANOMALY",
		"reward_item": &"",
		"log_id": &"log_core_telemetry",
	},
	{
		"id": &"subdeck_lift_descent",
		"title": "Descend to Second Floor (Sub-Deck 02 Tasks)",
		"marker_label": "SUB-DECK 02",
		"station_path": NodePath("CenterRecessRoom/SubDeckAccessLift"),
		"interaction_offset": Vector2(0.0, 0.0),
		"marker_offset": Vector2(0.0, -26.0),
		"prompt": "SUB-DECK CARGO LIFT   /   [E] DESCEND TO SECOND FLOOR",
		"reward_item": &"electrical_discharge_tool",
		"log_id": &"",
	},
	{
		"id": &"commanders_secret_bridge",
		"title": "Confront Chen on Bridge (Unlocks Revolver)",
		"marker_label": "BRIDGE TABLE",
		"station_path": NodePath("BridgeRoomProps/MissionPlanningTable"),
		"interaction_offset": Vector2(28.0, 0.0),
		"marker_offset": Vector2(0.0, -24.0),
		"prompt": "MISSION PLANNING TABLE   /   [E] CONFRONT COMMANDER CHEN",
		"reward_item": &"captains_revolver",
		"log_id": &"log_chen_debate",
	},
	{
		"id": &"act_v_finale_home",
		"title": "Execute Final Containment Plan",
		"marker_label": "FINALE / HELM",
		"station_path": NodePath("BridgeRoomProps/MainHelmConsole"),
		"interaction_offset": Vector2(36.0, 0.0),
		"marker_offset": Vector2(-6.0, -28.0),
		"prompt": "NAVIGATION CORE & AIRLOCK   /   [E] EXECUTE FINAL PLAN",
		"reward_item": &"",
		"log_id": &"",
	},
]

# Step-by-step sequential order so tasks appear one after another instead of overloading the player
const SEQUENTIAL_MAIN_DECK_ORDER: Array[StringName] = [
	&"cabin_may_recording",
	&"bridge_flight_piloting",
	&"auxiliary_power",
	&"air_filter",
	&"nutrient_flow",
	&"drone_vibration_scan",
	&"landing_prep_beacons",
	&"cargo_breach_inspection",
	&"subdeck_lift_descent",
	&"commanders_secret_bridge",
	&"act_v_finale_home",
]

@export var player_spawn: Vector2 = Vector2(900.0, 500.0)

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var wall_layer: Sprite2D = $WallLayer
@onready var exterior_airlock: Node2D = $ExteriorAirlockGate
@onready var player: ShipPlayer = $Player
@onready var amara: AmaraOkoye = $AmaraOkoye

var _completed_room_tasks: Dictionary = {}
var _completed_story_stations: Dictionary = {}
var _active_room_task_id: StringName = &""
var _active_story_station_id: StringName = &""
var _task_console_open: bool = false
var _piloting_console_open: bool = false
var _arrival_briefing_open: bool = true
var _hud_modal_open: bool = false
var _cutscene_open: bool = false
var _room_task_feedback: String = ""
var _pending_room_task_feedback: String = ""
var _room_task_feedback_timer: float = 0.0
var _walk_hud: WalkHud = null
var _crew_dialogue: CrewDialogue = null
var _story_cutscene: CanvasLayer = null
var _crew_dialogue_open: bool = false
var _amara_intro_seen: bool = false
var _crew_tasks_unlocked: bool = false
var _completed_crew_tasks: Dictionary = {}
var _active_amara_interaction: bool = false
var _active_crew_task_id: StringName = &""
var _active_airlock_exit: bool = false
var _active_subdeck_descent: bool = false
var _transitioning_to_planet: bool = false
var _subdeck_return_grace_timer: float = 0.0
var _echo_lab_return_active: bool = false
var _lab_door_repair_required: bool = false
var _active_lab_door_repair: bool = false
var _active_locked_lab_door: bool = false
var _lab_door_repairing: bool = false
var _lab_entry_reveal_started: bool = false
var _amara_ore_handoff_active: bool = false
var _active_lab_device_id: StringName = &""
var _tank_countdown_label: Label = null
var _tank_liquid_sprite: AnimatedSprite2D = null
var _ore_leak_sprite: Sprite2D = null
var _ore_leak_phase: float = 0.0
var _villain_instance: Node2D = null
var _xenomorph_timer_active: bool = false
var _xenomorph_countdown: float = XENOMORPH_INCUBATION_SECONDS
var _xenomorph_visual_stage: int = -1
var _chen_rescued: bool = false
var _leila_rescued: bool = false
var _tutorial_step: int = 1
var _autopilot_asteroid_timer: float = 82.0
var _interactive_highlights_canvas: Node2D = null
var _highlight_pulse_time: float = 0.0


func _load_sprite_png(sprite: Sprite2D, res_path: String) -> void:
	if not is_instance_valid(sprite):
		return
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(res_path))
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
		# The narrow stream starts beneath the tank; the wider pool spreads into the open floor.
		_ore_leak_sprite.position = Vector2(276.0, 122.0)
		_ore_leak_sprite.scale = Vector2(0.052, 0.052)
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


func _has_heard_ore_echo() -> bool:
	return Engine.has_meta(&"resonance_echo_heard") and bool(Engine.get_meta(&"resonance_echo_heard"))


func _is_rig_test_failed() -> bool:
	return Engine.has_meta(&"erebos_rig_test_failed") and bool(Engine.get_meta(&"erebos_rig_test_failed"))


func _is_rig_failure_reported() -> bool:
	return Engine.has_meta(&"erebos_rig_failure_reported") and bool(Engine.get_meta(&"erebos_rig_failure_reported"))


func _has_repaired_lab_door() -> bool:
	return Engine.has_meta(&"resonance_lab_door_repaired") and bool(Engine.get_meta(&"resonance_lab_door_repaired"))


func _lab_pressure_door() -> ShipPressureDoor:
	return get_node_or_null("ShipDoors/CentralBayNorthEntry") as ShipPressureDoor


func _lab_pressure_doors() -> Array[ShipPressureDoor]:
	var doors: Array[ShipPressureDoor] = []
	for door_path in [
		"ShipDoors/CentralBayNorthEntry",
		"ShipDoors/LowerDeckCenterEntry",
		"ShipDoors/LowerDeckCenterEntry2",
		"ShipDoors/LowerDeckCenterEntry3",
	]:
		var door := get_node_or_null(door_path) as ShipPressureDoor
		if door != null:
			doors.append(door)
	return doors


func _set_lab_doors_locked(locked: bool) -> void:
	for door in _lab_pressure_doors():
		door.set_locked(locked)


func _lab_door_repair_task_entry() -> Dictionary:
	var workbench := get_node_or_null("MaintenanceWorkshop/RepairWorkbench") as Node2D
	var marker_position := Vector2(732.0, 606.0)
	var interaction_position := Vector2(732.0, 651.0)
	if workbench != null:
		interaction_position = workbench.global_position + Vector2(0.0, 40.0)
		marker_position = workbench.global_position + Vector2(0.0, -42.0)
	return {
		"id": LAB_DOOR_REPAIR_TASK_ID,
		"title": "Restore all sealed laboratory doors",
		"marker_label": "LAB ACCESS REPAIR",
		"position": interaction_position,
		"marker_position": marker_position,
	}


func _lab_entry_task_entry() -> Dictionary:
	var door := _lab_pressure_door()
	var door_position := door.global_position if door != null else Vector2(686.0, 435.0)
	return {
		"id": LAB_ENTRY_TASK_ID,
		"title": "Enter the lab and investigate the echo",
		"marker_label": "LAB ACCESS",
		"position": door_position + Vector2(0.0, 48.0),
		"marker_position": door_position + Vector2(0.0, -34.0),
	}


func _rig_report_task_entry() -> Dictionary:
	var marker_position := amara.global_position + Vector2(0.0, -48.0)
	var interaction_position := amara.global_position + Vector2(0.0, 38.0)
	return {
		"id": RIG_REPORT_TASK_ID,
		"title": "Report the failed extraction rig to Dr. Okoye",
		"marker_label": "REPORT TO AMARA",
		"position": interaction_position,
		"marker_position": marker_position,
	}


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
	if _is_ore_villain_spawned() or _xenomorph_timer_active or not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
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
				_load_sprite_png(tank_sprite, "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png")
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


func _add_dirty_lab_floor() -> void:
	var lab_room := get_node_or_null("LabRoom") as Node2D
	if lab_room == null or lab_room.has_node("DirtyFloor"):
		return
	var stains := Node2D.new()
	stains.name = "DirtyFloor"
	stains.z_index = -1
	lab_room.add_child(stains)
	var patches := [
		{"position": Vector2(174.0, 196.0), "size": Vector2(35.0, 8.0), "color": Color(0.045, 0.055, 0.052, 0.72)},
		{"position": Vector2(244.0, 211.0), "size": Vector2(48.0, 11.0), "color": Color(0.09, 0.052, 0.035, 0.74)},
		{"position": Vector2(318.0, 190.0), "size": Vector2(38.0, 9.0), "color": Color(0.035, 0.06, 0.055, 0.78)},
		{"position": Vector2(388.0, 211.0), "size": Vector2(31.0, 8.0), "color": Color(0.11, 0.055, 0.036, 0.7)},
		{"position": Vector2(444.0, 181.0), "size": Vector2(26.0, 7.0), "color": Color(0.04, 0.05, 0.047, 0.68)},
	]
	for index in range(patches.size()):
		var patch: Dictionary = patches[index]
		var stain := Polygon2D.new()
		stain.name = "GrimePatch%d" % index
		stain.position = patch["position"]
		stain.color = patch["color"]
		var size: Vector2 = patch["size"]
		var points := PackedVector2Array()
		for point_index in range(14):
			var angle := TAU * float(point_index) / 14.0
			var unevenness := 0.78 + 0.22 * sin(float(point_index) * 2.7 + float(index))
			points.append(Vector2(cos(angle) * size.x, sin(angle) * size.y) * unevenness)
		stain.polygon = points
		stains.add_child(stain)


func _apply_lab_destruction_stage(stage: int, animate: bool) -> void:
	match stage:
		1:
			# Stage 1: OreContainment shattered.
			_load_sprite_png(get_node_or_null("LabRoom/OreContainment/SampleContainment") as Sprite2D, "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png")
			_set_ore_leak_visible(true)
			_wreck_lab_prop(NodePath("LabRoom/OreContainment"), -0.05, Vector2(0.0, 3.0), Color.WHITE, animate)
			var analysis_sleeve := get_node_or_null("LabRoom/CableRuns/AnalysisToConsoleSleeve") as Line2D
			var analysis_power := get_node_or_null("LabRoom/CableRuns/AnalysisToConsolePower") as Line2D
			if analysis_sleeve != null:
				analysis_sleeve.visible = false
			if analysis_power != null:
				analysis_power.visible = false
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
			_add_dirty_lab_floor()
			_load_single_sprite_png(get_node_or_null("LabRoom/LeftStorageCabinet/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/sample_cabinet.png")
			_load_single_sprite_png(get_node_or_null("LabRoom/LabWasteBins/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/lab_waste_bins.png", Vector2(0.4, 0.4))
			_load_single_sprite_png(get_node_or_null("LabRoom/WashSink/Sprite") as Sprite2D, "res://art/concepts/lab_props/destroyed/wash_sink.png", Vector2(0.5, 0.5))
			_wreck_lab_prop(NodePath("LabRoom/LeftStorageCabinet"), 0.08, Vector2(-3.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/LabWasteBins"), 0.12, Vector2(-4.0, 3.0), Color.WHITE, animate)
			_wreck_lab_prop(NodePath("LabRoom/WashSink"), -0.08, Vector2(-2.0, 2.0), Color.WHITE, animate)
			Engine.set_meta(&"lab_destroyed_by_xenomorph", true)
			if is_instance_valid(_tank_countdown_label):
				_tank_countdown_label.visible = false
				_tank_countdown_label.text = ""
			_room_task_feedback = ""
			_room_task_feedback_timer = 0.0


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
		tank_sprite.texture = RESONANCE_ORE_TANK_DESTROYED_TEXTURE
		_load_sprite_png(tank_sprite, "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png")
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
		_load_sprite_png(tank_sprite, "res://art/concepts/lab_props/destroyed/ore_containment_redesigned.png")
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
	Engine.set_meta(&"resonance_ore_maintained", true)
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

	_load_persistent_story_state()

	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.global_position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds: Rect2 = Rect2(floor_layer.global_position, map_size)
	player.set_camera_bounds(camera_bounds)

	var returning_from_planet: bool = Engine.has_meta(&"returning_from_planet") and bool(Engine.get_meta(&"returning_from_planet"))
	var returning_from_second_floor: bool = Engine.has_meta(&"returning_from_second_floor") and bool(Engine.get_meta(&"returning_from_second_floor"))
	if returning_from_planet:
		Engine.remove_meta(&"returning_from_planet")
		player.global_position = floor_layer.to_global(AIRLOCK_RETURN_FLOOR_POS)
	elif returning_from_second_floor:
		Engine.remove_meta(&"returning_from_second_floor")
		player.global_position = floor_layer.to_global(SUBDECK_RETURN_FLOOR_POS)
		_subdeck_return_grace_timer = 0.65
	else:
		player.global_position = player_spawn

	player.camera.enabled = true
	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
	var all_defs_by_id: Dictionary = {}
	for task in ROOM_TASKS:
		all_defs_by_id[task["id"]] = task
	for st in STORY_STATIONS:
		all_defs_by_id[st["id"]] = st
	var hud_task_entries: Array[Dictionary] = []
	for ordered_id in SEQUENTIAL_MAIN_DECK_ORDER:
		if not all_defs_by_id.has(ordered_id):
			continue
		var entry_def: Dictionary = all_defs_by_id[ordered_id]
		var station_node: Node2D = get_node_or_null(entry_def["station_path"]) as Node2D
		if station_node == null:
			continue
		var interaction_pos: Vector2 = _room_task_interaction_position(entry_def, station_node)
		var m_off: Vector2 = entry_def.get("marker_offset", Vector2(0.0, -26.0))
		hud_task_entries.append({
			"id": entry_def["id"],
			"title": entry_def["title"],
			"marker_label": entry_def["marker_label"],
			"reward_item": entry_def.get("reward_item", &""),
			"is_equipment_task": StringName(entry_def.get("reward_item", &"")) != &"",
			"position": interaction_pos,
			"marker_position": _task_marker_position(station_node, m_off),
		})
	if _lab_door_repair_required:
		hud_task_entries.append(_lab_door_repair_task_entry())
	elif _echo_lab_return_active:
		hud_task_entries.append(_lab_entry_task_entry())
	if returning_from_planet and _is_rig_test_failed() and not _is_rig_failure_reported():
		hud_task_entries.append(_rig_report_task_entry())
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_task_entries, floor_layer.global_position, FLOOR_TEXTURE.get_size())
	if _echo_lab_return_active and not _lab_door_repair_required:
		_walk_hud.set_task_completed(LAB_DOOR_REPAIR_TASK_ID)
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)

	for done_id in _completed_room_tasks:
		_walk_hud.set_task_completed(StringName(done_id), true)
	for done_st in _completed_story_stations:
		_walk_hud.set_task_completed(StringName(done_st), true)
	if _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud(true)
		for done_crew in _completed_crew_tasks:
			_walk_hud.set_task_completed(StringName(done_crew), true)

	_interactive_highlights_canvas = Node2D.new()
	_interactive_highlights_canvas.name = "InteractiveHighlightsCanvas"
	_interactive_highlights_canvas.z_as_relative = false
	_interactive_highlights_canvas.z_index = 1
	_interactive_highlights_canvas.draw.connect(_on_interactive_highlights_draw)
	add_child(_interactive_highlights_canvas)

	_crew_dialogue = CREW_DIALOGUE_SCENE.instantiate() as CrewDialogue
	_crew_dialogue.dialogue_finished.connect(_on_amara_dialogue_finished)
	add_child(_crew_dialogue)

	_story_cutscene = STORY_CUTSCENE_SCRIPT.new() as CanvasLayer
	_story_cutscene.connect(&"cutscene_finished", _on_story_cutscene_finished)
	add_child(_story_cutscene)

	var briefing_already_shown: bool = Engine.has_meta(&"echoes_arrival_briefing_shown") and bool(Engine.get_meta(&"echoes_arrival_briefing_shown"))
	if returning_from_planet:
		_arrival_briefing_open = false
		_walk_hud.set_walking_visible(true)
		_walk_hud.set_story_act_label("ACT III — THE RETURN")
		_room_task_feedback = "ACT III: THE RETURN  //  INSPECT DRILL CORE IN CARGO BAY"
		_room_task_feedback_timer = 5.0
		_update_player_walk_state()
	elif returning_from_second_floor:
		_arrival_briefing_open = false
		_walk_hud.set_walking_visible(true)
		_room_task_feedback = "CARGO LIFT CYCLE COMPLETE  //  MAIN DECK (LEVEL 01)"
		_room_task_feedback_timer = 3.5
		if _echo_lab_return_active:
			_room_task_feedback = ""
			_room_task_feedback_timer = 0.0
		elif _is_rig_test_failed() and not _is_rig_failure_reported():
			_room_task_feedback = "RIG TEST FAILED  //  REPORT TO DR. OKOYE"
			_room_task_feedback_timer = 6.0
		_update_player_walk_state()
	elif briefing_already_shown:
		_arrival_briefing_open = false
		_walk_hud.set_walking_visible(true)
		_update_player_walk_state()
	else:
		Engine.set_meta(&"echoes_arrival_briefing_shown", true)
		_walk_hud.set_walking_visible(false)
		var arrival_briefing: Node = ARRIVAL_BRIEFING_SCENE.instantiate()
		arrival_briefing.connect(&"dismissed", _on_arrival_briefing_dismissed)
		add_child(arrival_briefing)


func _load_persistent_story_state() -> void:
	if not Engine.has_meta(STORY_STATE_META_KEY):
		return
	var st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
	_completed_room_tasks = st.get("completed_room_tasks", {}).duplicate()
	_completed_story_stations = st.get("completed_story_stations", {}).duplicate()
	_completed_crew_tasks = st.get("completed_crew_tasks", {}).duplicate()
	_crew_tasks_unlocked = bool(st.get("crew_tasks_unlocked", false))
	_amara_intro_seen = bool(st.get("amara_intro_seen", false))
	_chen_rescued = bool(st.get("chen_rescued", false))
	_leila_rescued = bool(st.get("leila_rescued", false))


func _save_persistent_story_state() -> void:
	var st: Dictionary = {}
	if Engine.has_meta(STORY_STATE_META_KEY):
		var raw_st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		st = raw_st.duplicate(true)
	st["completed_room_tasks"] = _completed_room_tasks.duplicate()
	st["completed_story_stations"] = _completed_story_stations.duplicate()
	st["completed_crew_tasks"] = _completed_crew_tasks.duplicate()
	st["crew_tasks_unlocked"] = _crew_tasks_unlocked
	st["amara_intro_seen"] = _amara_intro_seen
	st["chen_rescued"] = _chen_rescued
	st["leila_rescued"] = _leila_rescued
	Engine.set_meta(STORY_STATE_META_KEY, st)


func _get_total_completed_main_tasks() -> int:
	return _completed_room_tasks.size() + _completed_story_stations.size()


func _evaluate_equipment_story_milestones() -> String:
	var unlocked_notes: Array[String] = []
	var total_main: int = _get_total_completed_main_tasks()

	# Milestone 1 (2 Main Tasks: May's Recording + Bridge Ship Piloting): Suit Flashlight [F]
	if total_main >= 2 and _completed_story_stations.has(&"bridge_flight_piloting") and not _walk_hud.has_equipment_item(&"suit_flashlight"):
		_walk_hud.unlock_equipment_item(&"suit_flashlight", true, "Milestone 1 (2 Tasks Complete): Bridge & Habitation checks cleared — Suit Flashlight [F] issued!")
		unlocked_notes.append("MILESTONE UNLOCKED: SUIT FLASHLIGHT [F]")

	# Milestone 2 (4 Main Tasks including Aux Power + Air Filter): Engineering Multitool
	if total_main >= 4 and _completed_room_tasks.has(&"auxiliary_power") and _completed_room_tasks.has(&"air_filter") and not _walk_hud.has_equipment_item(&"engineering_multitool"):
		_walk_hud.unlock_equipment_item(&"engineering_multitool", true, "Milestone 2 (4 Tasks Complete): Power & Life Support restored — Engineering Multitool issued!")
		unlocked_notes.append("MILESTONE UNLOCKED: ENGINEERING MULTITOOL")

	# Milestone 3 (6 Main Tasks including Nutrient Flow + Drone Scan): Pressure Sealant & Mineral Survey Scanner
	if total_main >= 6 and _completed_room_tasks.has(&"nutrient_flow") and _completed_story_stations.has(&"drone_vibration_scan"):
		if not _walk_hud.has_equipment_item(&"pressure_sealant"):
			_walk_hud.unlock_equipment_item(&"pressure_sealant", false, "Milestone 3 (6 Tasks Complete): Hydroponics & Drone Bay calibrated — Pressure Sealant issued!")
		if not _walk_hud.has_equipment_item(&"mineral_survey_scanner"):
			_walk_hud.unlock_equipment_item(&"mineral_survey_scanner", true, "Milestone 3 (6 Tasks Complete): 4-Pulse Erebos telemetry isolated — Mineral Survey Scanner issued!")
			unlocked_notes.append("MILESTONE UNLOCKED: SURVEY SCANNER & PRESSURE SEALANT")

	# Milestone 4 (7+ Main Tasks including Shuttle Bay Prep): Survey Beacon
	if total_main >= 7 and _completed_story_stations.has(&"landing_prep_beacons") and not _walk_hud.has_equipment_item(&"survey_beacon"):
		_walk_hud.unlock_equipment_item(&"survey_beacon", true, "Milestone 4 (7 Tasks Complete): Pre-descent checklist complete — Survey Beacon issued!")
		unlocked_notes.append("MILESTONE UNLOCKED: SURVEY BEACON")

	# Milestone 5 (Confront Commander Chen on Bridge after 8+ tasks): Captain's Revolver
	if _completed_story_stations.has(&"commanders_secret_bridge") and not _walk_hud.has_equipment_item(&"captains_revolver"):
		_walk_hud.unlock_equipment_item(&"captains_revolver", true, "Act IV Bridge Confrontation: Commander Chen's Revolver unlocked!")
		unlocked_notes.append("MILESTONE UNLOCKED: CAPTAIN'S REVOLVER")

	return "\n".join(unlocked_notes)


func _process(delta: float) -> void:
	if _transitioning_to_planet:
		return
	_update_xenomorph_incubation(delta)
	_update_echo_lab_entry()
	_highlight_pulse_time = fposmod(_highlight_pulse_time + delta * 3.2, TAU)
	if is_instance_valid(_interactive_highlights_canvas):
		_interactive_highlights_canvas.queue_redraw()
	if _subdeck_return_grace_timer > 0.0:
		_subdeck_return_grace_timer = maxf(_subdeck_return_grace_timer - delta, 0.0)
	if _room_task_feedback_timer > 0.0:
		_room_task_feedback_timer = maxf(_room_task_feedback_timer - delta, 0.0)
		if is_zero_approx(_room_task_feedback_timer):
			_room_task_feedback = ""

	# Occasional Autopilot Asteroid Swarm Cutscene Interception while cruising in space!
	if not _arrival_briefing_open and not _hud_modal_open and not _task_console_open and not _piloting_console_open and not _crew_dialogue_open and not _cutscene_open:
		if _completed_story_stations.has(&"bridge_flight_piloting"):
			_autopilot_asteroid_timer -= delta
			if _autopilot_asteroid_timer <= 0.0:
				_autopilot_asteroid_timer = 95.0
				trigger_emergency_asteroid_cutscene()
				return

	if _tutorial_step == 1 and not _arrival_briefing_open and player.global_position.distance_to(player_spawn) > 36.0:
		_tutorial_step = 2
		_room_task_feedback = "TUTORIAL 2/3: COMPLETE MULTI-TASK STORY MILESTONES AT [!] MARKERS TO EARN EQUIPMENT"
		_room_task_feedback_timer = 7.0
	elif _tutorial_step == 2 and (_completed_room_tasks.size() > 0 or _completed_story_stations.size() > 0):
		_tutorial_step = 3
		_room_task_feedback = "TUTORIAL 3/3: REPORT TO THE BRIDGE HELM TO MONITOR AUTOPILOT & UNLOCK YOUR FIRST GEAR"
		_room_task_feedback_timer = 7.0

	if not _arrival_briefing_open and not _hud_modal_open and not _task_console_open and not _piloting_console_open and not _crew_dialogue_open and not _cutscene_open:
		var local_floor_pos: Vector2 = floor_layer.to_local(player.global_position)
		if is_instance_valid(exterior_airlock) and exterior_airlock.has_method("is_open") and bool(exterior_airlock.call("is_open")):
			if local_floor_pos.x >= 434.0 and local_floor_pos.x <= 523.0 and local_floor_pos.y <= 278.0 and Input.is_action_pressed(&"move_up"):
				_exit_ship_to_planet()
				return
		if _subdeck_return_grace_timer <= 0.0:
			if local_floor_pos.x >= 826.0 and local_floor_pos.x <= 898.0 and local_floor_pos.y >= 296.0 and local_floor_pos.y <= 326.0 and Input.is_action_pressed(&"move_up"):
				_descend_to_second_floor()
				return

	_refresh_room_task_prompt()


func _update_echo_lab_entry() -> void:
	if not _echo_lab_return_active or _lab_door_repair_required or _lab_entry_reveal_started or _lab_door_repairing:
		return
	for door in _lab_pressure_doors():
		var player_in_door_space := door.to_local(player.global_position)
		var lab_room := get_node_or_null("LabRoom") as Node2D
		if lab_room == null:
			return
		var threshold := door.wall_depth * 0.5 + 24.0
		var is_bottom_entry := door.global_position.y > lab_room.to_global(Vector2(0.0, 150.0)).y
		var crossed_into_lab := player_in_door_space.y > threshold
		if is_bottom_entry:
			crossed_into_lab = player_in_door_space.y < -threshold
		if not crossed_into_lab or absf(player_in_door_space.x) > door.opening_width * 0.5 + 22.0:
			continue
		_lab_entry_reveal_started = true
		Engine.set_meta(&"resonance_lab_entered_after_echo", true)
		_walk_hud.set_task_completed(LAB_ENTRY_TASK_ID)
		_echo_lab_return_active = false
		return


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning_to_planet or _arrival_briefing_open or _hud_modal_open or _task_console_open or _piloting_console_open or _crew_dialogue_open or _cutscene_open or not event.is_action_pressed(&"interact"):
		return
	if _active_airlock_exit:
		get_viewport().set_input_as_handled()
		_exit_ship_to_planet()
		return
	if _active_subdeck_descent:
		get_viewport().set_input_as_handled()
		_descend_to_second_floor()
		return
	if _active_lab_door_repair:
		get_viewport().set_input_as_handled()
		_repair_lab_pressure_door()
		return
	if _active_locked_lab_door:
		get_viewport().set_input_as_handled()
		_room_task_feedback = "LABORATORY ACCESS SEALED  //  RESTORE ACCESS AT REPAIR WORKBENCH"
		_room_task_feedback_timer = 4.0
		return
	if _active_amara_interaction:
		_begin_amara_dialogue()
	elif _active_crew_task_id != &"":
		_complete_crew_task(_active_crew_task_id)
	elif _active_lab_device_id != &"":
		_open_lab_device_console(_active_lab_device_id)
	elif _active_room_task_id != &"":
		_open_room_task_console(_active_room_task_id)
	elif _active_story_station_id != &"":
		_trigger_story_station(_active_story_station_id)
	else:
		return
	get_viewport().set_input_as_handled()


func _exit_ship_to_planet() -> void:
	if _transitioning_to_planet:
		return
	_save_persistent_story_state()
	_transitioning_to_planet = true
	get_tree().change_scene_to_file(MOCK_PLANET_SCENE_PATH)


func _descend_to_second_floor() -> void:
	if _transitioning_to_planet:
		return
	_completed_story_stations[&"subdeck_lift_descent"] = true
	if is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(&"subdeck_lift_descent", true)
	_save_persistent_story_state()
	_transitioning_to_planet = true
	get_tree().change_scene_to_file(SECOND_FLOOR_SCENE_PATH)


func trigger_emergency_asteroid_cutscene() -> void:
	if _piloting_console_open or _task_console_open or _cutscene_open:
		return
	_open_ship_piloting_console(&"asteroid_emergency_override", true)


func _open_ship_piloting_console(encounter_id: StringName, is_emergency: bool) -> void:
	if _piloting_console_open:
		return
	var pilot_console: CanvasLayer = SHIP_PILOTING_SCRIPT.new() as CanvasLayer
	if pilot_console == null:
		return
	_piloting_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	pilot_console.call(&"setup", encounter_id, is_emergency)
	pilot_console.connect(&"piloting_completed", _on_ship_piloting_completed)
	pilot_console.connect(&"piloting_closed", _on_ship_piloting_closed)
	add_child(pilot_console)


func _on_ship_piloting_completed(encounter_id: StringName, hull_remaining: float) -> void:
	_piloting_console_open = false
	_autopilot_asteroid_timer = 95.0
	if encounter_id == &"bridge_flight_piloting" and not _completed_story_stations.has(&"bridge_flight_piloting"):
		_completed_story_stations[&"bridge_flight_piloting"] = true
		_walk_hud.set_task_completed(&"bridge_flight_piloting")
		var milestone_msg: String = _evaluate_equipment_story_milestones()
		_save_persistent_story_state()

		# Play post-evasion narrative cutscene with Pilot Elias Ward
		var cutscene_data: Dictionary = _build_cutscene_data(&"bridge_flight_piloting")
		if not cutscene_data.is_empty() and is_instance_valid(_story_cutscene):
			_cutscene_open = true
			_walk_hud.set_walking_visible(false)
			_update_player_walk_state()
			_story_cutscene.call(&"play_cutscene", &"bridge_flight_piloting", cutscene_data)
			return
		_room_task_feedback = "ASTEROID BELT CLEARED (HULL %d%%) — AUTOPILOT RESTORED\n%s" % [roundi(hull_remaining), milestone_msg]
		_room_task_feedback_timer = 5.0
	else:
		_room_task_feedback = "EMERGENCY ASTEROID SWARM EVADED (HULL %d%%)  //  AUTOPILOT RESUMED" % roundi(hull_remaining)
		_room_task_feedback_timer = 4.5

	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()


func _on_ship_piloting_closed() -> void:
	_piloting_console_open = false
	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()


func _open_room_task_console(task_id: StringName) -> void:
	if _task_console_open:
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console: ServiceTaskConsole = SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(task_id, _completed_room_tasks.size(), ROOM_TASKS.size())
	console.task_completed.connect(_on_room_task_completed)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _on_room_task_completed(task_id: StringName) -> void:
	if _completed_room_tasks.has(task_id):
		return
	var completion: String = "Service task complete."
	var log_id: StringName = &""
	for task in ROOM_TASKS:
		if task["id"] == task_id:
			completion = str(task["completion"])
			log_id = task.get("log_id", &"")
			break
	_completed_room_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	if log_id != &"":
		_walk_hud.record_audio_log(log_id)
	var milestone_note: String = _evaluate_equipment_story_milestones()
	_save_persistent_story_state()
	_room_task_feedback = "%s\nSERVICE TASKS  %d / %d COMPLETE" % [
		completion,
		_completed_room_tasks.size(),
		ROOM_TASKS.size(),
	]
	if not milestone_note.is_empty():
		_room_task_feedback += "\n" + milestone_note
	_pending_room_task_feedback = _room_task_feedback


func _repair_lab_pressure_door() -> void:
	if not _lab_door_repair_required or _lab_door_repairing:
		return
	var door := _lab_pressure_door()
	if door == null:
		_room_task_feedback = "LAB DOOR CONTROLLER NOT FOUND  //  CHECK THE SHIP MAP"
		_room_task_feedback_timer = 4.0
		return
	_lab_door_repairing = true
	player.set_physics_process(false)
	player.face_toward(door.global_position)
	var workbench := get_node_or_null("MaintenanceWorkshop/RepairWorkbench") as CanvasItem
	if workbench != null:
		var sparks := create_tween()
		sparks.set_loops(4)
		sparks.tween_property(workbench, "modulate", Color(1.0, 0.69, 0.32), 0.18)
		sparks.tween_property(workbench, "modulate", Color.WHITE, 0.18)
	for phase in ["ISOLATING THE DAMAGED LAB INTERLOCK...", "BYPASSING THE JAMMED PRESSURE SEAL...", "RESTORING THE DOOR ACTUATOR..."]:
		_walk_hud.set_interaction_prompt(str(phase), true)
		await get_tree().create_timer(0.72).timeout
		if not is_inside_tree():
			return
	if workbench != null:
		workbench.modulate = Color.WHITE
	_set_lab_doors_locked(false)
	Engine.set_meta(&"resonance_lab_door_repaired", true)
	_lab_door_repair_required = false
	_lab_door_repairing = false
	_walk_hud.set_task_completed(LAB_DOOR_REPAIR_TASK_ID)
	_walk_hud.add_task_entry(_lab_entry_task_entry())
	_room_task_feedback = "LAB ACCESS RESTORED  //  FOLLOW THE ORE ECHO INSIDE"
	_room_task_feedback_timer = 5.0
	_update_player_walk_state()
	_walk_hud.set_interaction_prompt("LAB ACCESS RESTORED   /   RETURN INSIDE AND FOLLOW THE ECHO", true)


func _on_room_task_console_closed() -> void:
	_task_console_open = false
	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()
	if not _pending_room_task_feedback.is_empty():
		_room_task_feedback = _pending_room_task_feedback
		_room_task_feedback_timer = 4.5
		_pending_room_task_feedback = ""


func _refresh_room_task_prompt() -> void:
	_active_room_task_id = &""
	_active_crew_task_id = &""
	_active_story_station_id = &""
	_active_amara_interaction = false
	_active_airlock_exit = false
	_active_subdeck_descent = false
	if _crew_dialogue_open or _cutscene_open or _piloting_console_open or not _arrival_briefing_open and (_hud_modal_open or _task_console_open):
		_walk_hud.set_interaction_prompt("", false)
		return
	if is_instance_valid(exterior_airlock):
		var airlock_access_pos: Vector2 = exterior_airlock.global_position + Vector2(0.0, 28.0)
		if player.global_position.distance_to(airlock_access_pos) <= AIRLOCK_INTERACTION_RADIUS:
			_active_airlock_exit = true
			_walk_hud.set_interaction_prompt("EXTERIOR AIRLOCK   /   [E] EXIT TO EREBOS (SITE K-12)", true)
			return
	var subdeck_lift_world_pos: Vector2 = floor_layer.to_global(SUBDECK_LIFT_FLOOR_POS)
	if player.global_position.distance_to(subdeck_lift_world_pos) <= SUBDECK_LIFT_INTERACTION_RADIUS:
		_active_subdeck_descent = true
		_walk_hud.set_interaction_prompt("SUB-DECK CARGO LIFT   /   [E] DESCEND TO SECOND FLOOR", true)
		return
	if is_instance_valid(amara) and player.global_position.distance_to(amara.global_position) <= AMARA_INTERACTION_RADIUS:
		_active_amara_interaction = true
		_walk_hud.set_interaction_prompt("DR. AMARA OKOYE   /   [E] TALK", true)
		return
	var closest_crew_task: Dictionary = {}
	var closest_crew_distance: float = CREW_TASK_INTERACTION_RADIUS
	for task in AMARA_CREW_TASKS:
		var task_id: StringName = task["id"]
		if _completed_crew_tasks.has(task_id):
			continue
		var station: Node2D = get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_position: Vector2 = _crew_task_interaction_position(task, station)
		var distance: float = minf(
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
	var closest_task: Dictionary = {}
	var closest_distance: float = 999999.0
	for task in ROOM_TASKS:
		var task_id: StringName = task["id"]
		if _completed_room_tasks.has(task_id):
			continue
		var station_path: NodePath = task["station_path"]
		var station: Node2D = get_node_or_null(station_path) as Node2D
		if station == null:
			continue
		var interaction_pos: Vector2 = _room_task_interaction_position(task, station)
		var max_dist: float = float(task.get("interaction_radius", ROOM_TASK_INTERACTION_RADIUS))
		var distance: float = minf(
			player.global_position.distance_to(interaction_pos),
			player.global_position.distance_to(station.global_position)
		)
		if distance <= max_dist and distance <= closest_distance:
			closest_distance = distance
			closest_task = task

	if not closest_task.is_empty():
		_active_room_task_id = closest_task["id"]
		_walk_hud.set_interaction_prompt(closest_task["prompt"], true)
		return

	var closest_story: Dictionary = {}
	var closest_story_dist: float = STORY_STATION_INTERACTION_RADIUS
	var helm_chair_node: Node2D = get_node_or_null("BridgeRoomProps/MainHelmChair") as Node2D
	var upper_chair_node: Node2D = get_node_or_null("BridgeRoomProps/UpperStationChair") as Node2D
	for st in STORY_STATIONS:
		var st_id: StringName = st["id"]
		# Allow re-triggering the Bridge Flight Piloting helm & the Act V finale anytime!
		if _completed_story_stations.has(st_id) and st_id != &"act_v_finale_home" and st_id != &"bridge_flight_piloting":
			continue
		var st_node: Node2D = get_node_or_null(st["station_path"]) as Node2D
		if st_node == null:
			continue
		var st_pos: Vector2 = _room_task_interaction_position(st, st_node)
		var d: float = minf(
			player.global_position.distance_to(st_pos),
			player.global_position.distance_to(st_node.global_position)
		)
		# Also let the player drive the ship right from the Bridge helm/station chairs at the ship head!
		if st_id == &"bridge_flight_piloting":
			if is_instance_valid(helm_chair_node):
				d = minf(d, player.global_position.distance_to(helm_chair_node.global_position))
			if is_instance_valid(upper_chair_node):
				d = minf(d, player.global_position.distance_to(upper_chair_node.global_position))
		if d <= closest_story_dist:
			closest_story_dist = d
			closest_story = st
	if not closest_story.is_empty():
		_active_story_station_id = closest_story["id"]
		_walk_hud.set_interaction_prompt(closest_story["prompt"], true)
		return

	if _room_task_feedback_timer > 0.0:
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
		_room_task_feedback = "ORE STORED BY DR. OKOYE  /  RETURN TO THE EXTRACTION RIG AND WAIT FOR INSTRUCTIONS"
		_room_task_feedback_timer = 5.0
		_update_player_walk_state()
		return
	var first_meeting := not (Engine.has_meta(&"amara_mission_briefed") and bool(Engine.get_meta(&"amara_mission_briefed")))
	var reporting_rig_failure := _is_rig_test_failed() and not _is_rig_failure_reported()
	_crew_dialogue_open = true
	_amara_intro_seen = true
	if first_meeting:
		Engine.set_meta(&"amara_mission_briefed", true)
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
	elif reporting_rig_failure:
		Engine.set_meta(&"erebos_rig_failure_reported", true)
		_walk_hud.set_task_completed(RIG_REPORT_TASK_ID)
		lines.append("You were right to come back. The rig's drive is damaged; don't try to force it again. I can see a resonance seam in the western crater. Bring me a small sample so I can study what the failed drill disturbed.")
	elif first_meeting:
		lines.append("I'm Dr. Amara Okoye, astrobiologist. Test the resonance rig on Erebos. If it fails, come back and report to me before you continue.")
	else:
		lines.append("I'm analyzing the rig failure from here. Bring me a sample from the exposed seam when you return.")
	_crew_dialogue.start_dialogue(lines, offer_tasks)


func _on_amara_dialogue_finished(accepted_tasks: bool) -> void:
	_crew_dialogue_open = false
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(false)
	if accepted_tasks and not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud(false)
		_room_task_feedback = "COMPLETE BOTH OF AMARA'S HYDROPONICS JOBS (0/2) TO UNLOCK THE MEDICAL INJECTOR."
		_room_task_feedback_timer = 4.5
	_save_persistent_story_state()
	_update_player_walk_state()


func _unlock_crew_tasks_on_hud(force: bool = false) -> void:
	if _crew_tasks_unlocked and not force:
		return
	_crew_tasks_unlocked = true
	for task in AMARA_CREW_TASKS:
		var station: Node2D = get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var m_off: Vector2 = task.get("marker_offset", Vector2(0.0, -24.0))
		_walk_hud.add_task_entry({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"reward_item": &"medical_injector" if task["id"] == &"amara_seedling_sensor" else &"",
			"is_equipment_task": task["id"] == &"amara_seedling_sensor",
			"position": _crew_task_interaction_position(task, station),
			"marker_position": _task_marker_position(station, m_off),
		})


func _room_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent: Node2D = station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _crew_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent: Node2D = station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _task_marker_position(station: Node2D, marker_offset: Vector2 = Vector2(0.0, -26.0)) -> Vector2:
	return station.global_position + marker_offset


func _complete_crew_task(task_id: StringName) -> void:
	if _completed_crew_tasks.has(task_id):
		return
	if not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud(false)
	var completion: String = "Hydroponics check complete."
	for task in AMARA_CREW_TASKS:
		if task["id"] == task_id:
			completion = str(task["completion"])
			break
	_completed_crew_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	# Only unlock the Medical Injector after BOTH of Amara's hydroponics tasks are complete!
	if _completed_crew_tasks.size() >= AMARA_CREW_TASKS.size() and not _walk_hud.has_equipment_item(&"medical_injector"):
		_walk_hud.unlock_equipment_item(&"medical_injector", true, "Both Hydroponics checks completed — Dr. Okoye issued Medical Injector!")
		completion = "Both Hydroponics checks complete! Dr. Okoye issued: Medical Injector."
	_walk_hud.record_audio_log(&"log_okoye_fields")
	_save_persistent_story_state()
	_room_task_feedback = "%s\nAMARA'S JOBS  %d / %d COMPLETE" % [completion, _completed_crew_tasks.size(), AMARA_CREW_TASKS.size()]
	_room_task_feedback_timer = 4.5


func _trigger_story_station(station_id: StringName) -> void:
	if _cutscene_open or _piloting_console_open or not is_instance_valid(_story_cutscene):
		return

	# New Main Task: Ship Driving & Asteroid Evasion at the Bridge Flight Helm!
	if station_id == &"bridge_flight_piloting":
		_open_ship_piloting_console(&"bridge_flight_piloting", false)
		return

	var st_def: Dictionary = {}
	for st in STORY_STATIONS:
		if st["id"] == station_id:
			st_def = st
			break
	if st_def.is_empty():
		return

	_completed_story_stations[station_id] = true
	_walk_hud.set_task_completed(station_id)
	var log_id: StringName = st_def.get("log_id", &"")
	if log_id != &"":
		_walk_hud.record_audio_log(log_id)
	_evaluate_equipment_story_milestones()
	_save_persistent_story_state()

	var cutscene_data: Dictionary = _build_cutscene_data(station_id)
	if cutscene_data.is_empty():
		return
	_cutscene_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	_story_cutscene.call(&"play_cutscene", station_id, cutscene_data)


func _build_cutscene_data(station_id: StringName) -> Dictionary:
	match station_id:
		&"cabin_may_recording":
			return {
				"act": "PROLOGUE & ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // HABITATION RING",
				"title": "THE PAPER STAR & MAY'S TRANSMISSION (TASK 1/2)",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "MEMORY // THE SKY ABOVE YANGON",
						"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
						"text": "Rain falls against a window in Yangon. The electricity has gone out. Young Thura climbs onto the roof with his mother, a physics teacher.\n\nYOUNG THURA: \"Do astronauts ever get afraid?\"\nMOTHER: \"Of course.\"\nYOUNG THURA: \"Then how do they go?\"\nMOTHER: \"They learn what their fear is trying to tell them.\"",
					},
					{
						"speaker": "MAY MIN // DELAYED EARTH RECORDING (LOG 1/8)",
						"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
						"text": "Attached to Thura's sleeping compartment is the paper star May folded from one of their mother's old lesson books.\n\nMAY'S RECORDING: \"Ko Thura, everyone here keeps asking when you will bring back an alien. Please bring a friendly one. Also, Ma would say you look too thin.\"",
					},
					{
						"speaker": "BRIDGE INTERCOM // PILOT ELIAS WARD",
						"text": "ELIAS WARD (INTERCOM): \"Thura, glad you're up! Report to the Bridge Flight Helm in R01 — Autopilot is guiding us into the Erebos debris belt and Commander Chen wants you on the auxiliary flight controls before we issue your EVA Suit Flashlight.\"",
					},
				],
			}
		&"bridge_flight_piloting":
			return {
				"act": "ACT I — THE LONG APPROACH // HELM CLEARANCE",
				"clock": "ASTERIA-1 // DAY 184 // BRIDGE FLIGHT DECK",
				"title": "THROUGH THE SHEARWATER DEBRIS BELT",
				"echo_pulse": false,
				"reward": {
					"name": "Suit Flashlight [F]",
					"desc": "Milestone 1 Complete (2 Tasks): Shoulder-mounted tactical beam unlocked! Press [F] to toggle or [LMB/Space] to overcharge.",
					"texture": load("res://art/tools/icons/suit_flashlight.png"),
				},
				"slides": [
					{
						"speaker": "ELIAS WARD // PILOT & NAVIGATION OFFICER",
						"text": "ELIAS WARD: \"Nice hands on the thrusters, Thura! Those Erebos shearwater fragments came in hot, and the autopilot's optical sensors didn't even flag them until we were right on top of the swarm.\"\n\nCOMMANDER MAYA CHEN: \"Stay alert. Autopilot will hold our orbital approach, but if another debris wave crosses our vector, we'll need manual evasion again. Thura, your Suit Flashlight is now authorized — report to Leila in Power Maintenance and Life Support next.\"",
					},
				],
			}
		&"drone_vibration_scan":
			return {
				"act": "ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // DRONE MAINTENANCE BAY",
				"title": "FOUR PULSES, SEVEN SECONDS",
				"echo_pulse": true,
				"reward": {
					"name": "Mineral Survey Scanner & Pressure Sealant",
					"desc": "Milestone 3 Complete (6 Tasks): Survey Scanner & Pressure Sealant unlocked in your Quick Bar!",
					"texture": load("res://art/tools/icons/mineral_survey_scanner.png"),
				},
				"slides": [
					{
						"speaker": "NARRATION // DRONE TELEMETRY BENCH",
						"image": "res://art/storyboards/thura_earth/02_radio_with_father.png",
						"text": "In Yangon, Thura's father repaired generators and radios, teaching him to diagnose machines by listening to their sounds. As Thura calibrates the autonomous mining drone's acoustic array, a repeating vibration echoes up from Erebos below.",
					},
					{
						"speaker": "ACOUSTIC TELEMETRY // EREBOS ORBITAL FEED",
						"text": "4 PULSES  ...  7-SECOND PAUSE  ...  4 PULSES  ...  7-SECOND PAUSE.\n\nMATEO RUIZ (MINING SPECIALIST): \"It is a rock, Thura. Rocks make noise. The commercial sponsors didn't fund Asteria-1 so we could panic over echoes.\"\n\nDR. THURA MIN: \"Not usually with timing.\"",
					},
				],
			}
		&"landing_prep_beacons":
			return {
				"act": "ACT I — THE LONG APPROACH",
				"clock": "ASTERIA-1 // DAY 184 // SHUTTLE BAY",
				"title": "PREPARING FOR SITE K-12",
				"echo_pulse": false,
				"reward": {
					"name": "Survey Beacon",
					"desc": "Milestone 4 Complete (7 Tasks): High-output surface transponder unlocked for Site K-12.",
					"texture": load("res://art/tools/icons/survey_beacon.png"),
				},
				"slides": [
					{
						"speaker": "ELIAS WARD // PILOT & NAVIGATION OFFICER (LOG 5/8)",
						"text": "ELIAS WARD: \"All pre-descent engineering and science tasks are green. Here's your Survey Beacon kit, Thura. I just recorded three terrible knock-knock jokes for my daughter back in Houston, so make sure we come back from this rock.\"\n\nCOMMANDER MAYA CHEN (INTERCOM): \"Orbital lock over Site K-12 is green. Thura, take the Exterior Airlock to descend to Erebos.\"",
					},
				],
			}
		&"cargo_breach_inspection":
			_walk_hud.set_story_act_label("ACT IV — THE HUNT")
			var lighting: Node = get_node_or_null("ShipRoomLighting")
			if lighting != null and lighting.has_method("set_flicker_all_rooms"):
				lighting.call("set_flicker_all_rooms", true)
			return {
				"act": "ACT III & IV — THE RETURN & FIRST BLOOD",
				"clock": "ASTERIA-1 // RETURN TRAJECTORY // CARGO HOLD",
				"title": "THE SAMPLE CONTAINER IS EMPTY",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "ACT III // THE RETURN FROM EREBOS",
						"text": "Ruiz and Dr. Okoye are officially recorded as missing. Before the emergency evacuation from Site K-12, the automated rig sealed its final black drill core inside a reinforced sample container. It did not accidentally enter the container — it allowed itself to be collected.",
					},
					{
						"speaker": "LEILA HADDAD & DR. THURA MIN // CARGO BAY",
						"text": "The sample container had been gaining mass. Now, inside the cargo bay, the reinforced container sits completely empty. There is no broken lock and no forced entry — only a narrow opening melted into the ship's cable ducts.\n\nSuddenly, the deck lights fail. Across multiple speakers simultaneously, Dr. Okoye's voice whispers:\nOKOYE'S VOICE: \"Thura, I found him.\"",
					},
					{
						"speaker": "ACT IV — CHAPTER 1: FIRST BLOOD",
						"text": "The colony of mineral organisms has absorbed recorded sounds and electrical patterns from the crew's equipment. The crew names it THE ECHO.\n\nMinutes later, Elias Ward investigates a false distress call in the medical bay using Okoye's voice. Thura watches the security feed freeze for exactly seven seconds. When the video returns, Ward is gone — and his voice begins calling from Sub-Deck 02. Descend to Sub-Deck 02 or confront Commander Chen on the Bridge!",
					},
				],
			}
		&"commanders_secret_bridge":
			_walk_hud.set_story_act_label("ACT V — HOME")
			return {
				"act": "ACT IV — CHAPTER 4: THE COMMANDER'S SECRET",
				"clock": "ASTERIA-1 // BRIDGE COMMAND DECK",
				"title": "YOU GAVE IT TRANSPORTATION",
				"echo_pulse": true,
				"reward": {
					"name": "Captain's Revolver",
					"desc": "Milestone 5 Complete: Commander Chen's emergency sidearm unlocked in Quick Bar!",
					"texture": load("res://art/tools/icons/captains_revolver.png"),
				},
				"slides": [
					{
						"speaker": "DR. THURA MIN & COMMANDER MAYA CHEN // BRIDGE",
						"text": "Thura uncovers the encrypted pre-departure telemetry on the Bridge planning table: Commander Chen knew the sample container was gaining mass before leaving Erebos.\n\nTHURA: \"You knew something was inside it.\"\nCHEN: \"I knew the reading was wrong.\"\nTHURA: \"You knew enough.\"",
					},
					{
						"speaker": "COMMANDER MAYA CHEN // BRIDGE",
						"text": "CHEN: \"Two people were already gone. I thought bringing back the sample might tell us why.\"\n\nTHURA: \"You did not bring back an explanation. You gave it transportation.\"",
					},
					{
						"speaker": "EMERGENCY CONTAINMENT BREACH // CHOICE",
						"text": "Chen rushes to separate the contaminated cargo module manually. Over the intercom, the Echo imitates Elias Ward's voice pleading for the hatch to stay open. Chen hesitates as a black reflective silhouette lunges from the overhead conduit!",
						"choices": [
							{"id": &"save_chen", "label": "Restore emergency locks immediately & pull Commander Chen clear"},
							{"id": &"seal_bridge", "label": "Seal the inner bridge bulkhead before the Echo breaches helm"},
						],
					},
				],
			}
		&"act_v_finale_home":
			var logs_count: int = _walk_hud.get_unlocked_equipment_count() + _walk_hud.get_collected_logs_count()
			var crew_saved_note: String = "Crew survived with you: %s" % (
				"Commander Chen & Leila Haddad" if (_chen_rescued and _leila_rescued)
				else "Commander Maya Chen" if _chen_rescued
				else "Chief Engineer Leila Haddad" if _leila_rescued
				else "None (Thura alone)"
			)
			return {
				"act": "ACT V — HOME // FINAL DECISION",
				"clock": "ASTERIA-1 // EARTH APPROACH VECTOR",
				"title": "SOME DISCOVERIES ARE WORTH LEAVING BEHIND",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "MISSION CONTROL // EARTH QUARANTINE DIRECTIVE",
						"text": "DO NOT BEGIN EARTH-ENTRY PROCEDURE.\nCONFIRM BIOLOGICAL CONTAINMENT.\nAWAIT REMOTE QUARANTINE INSTRUCTIONS.\n\n[The Echo has damaged the communication array. Thura can receive messages, but cannot reply — and automatic Earth-entry has already begun. %s]" % crew_saved_note,
					},
					{
						"speaker": "THE ECHO (MOTHER'S VOICE) // FINAL AIRLOCK",
						"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
						"text": "As Thura reaches the airlock to lure the Echo into the mining module for uncontrolled atmospheric burn-up, the speaker crackles with the voice of his mother from Yangon:\n\nMOTHER'S VOICE: \"Do astronauts ever get afraid?\"\nThura stops. The creature continues:\nMOTHER'S VOICE: \"Then how do they go?\"",
					},
					{
						"speaker": "DR. THURA MIN // THE PAPER STAR",
						"image": "res://art/storyboards/thura_earth/08_may_gives_paper_star.png",
						"text": "Thura removes the folded paper star from his suit and looks at it.\n\nTHURA: \"You heard the words.\"\nHe reaches for the master airlock and navigation core controls.\nTHURA: \"But you never understood them.\"\n\n[CHOOSE YOUR FINAL TRAJECTORY — TELEMETRY SCORE: %d]" % logs_count,
						"choices": [
							{"id": &"ending_dawn", "label": "ENDING 1 — DAWN: Trap the Echo, burn the mining module & return home"},
							{"id": &"ending_trajectory", "label": "ENDING 2 — THE LAST TRAJECTORY: Redirect Asteria-1 into deep space"},
							{"id": &"ending_homecoming", "label": "ENDING 3 — HOMECOMING: Enter return capsule without confirming containment"},
							{"id": &"ending_voices", "label": "ENDING 4 — VOICES: Transmit all research data & eject into space"},
						],
					},
				],
			}
	return {}


func _on_story_cutscene_finished(cutscene_id: StringName, choice_id: StringName) -> void:
	_cutscene_open = false
	if cutscene_id == &"cabin_may_recording":
		_room_task_feedback = "TASK 1/2 COMPLETE  //  HEAD TO BRIDGE FLIGHT HELM (R01) TO PILOT ASTERIA-1 & UNLOCK SUIT LIGHT"
		_room_task_feedback_timer = 5.5
	elif cutscene_id == &"commanders_secret_bridge":
		if choice_id == &"save_chen":
			_chen_rescued = true
			_room_task_feedback = "COMMANDER CHEN RESCUED  //  CAPTAIN'S REVOLVER UNLOCKED  //  PROCEED TO HELM FOR ACT V"
		else:
			_chen_rescued = false
			_room_task_feedback = "BRIDGE SEALED  //  CAPTAIN'S REVOLVER UNLOCKED  //  PROCEED TO HELM FOR ACT V"
		_room_task_feedback_timer = 5.0
		_save_persistent_story_state()
	elif cutscene_id == &"act_v_finale_home" and choice_id != &"":
		_play_ending_epilogue(choice_id)
		return

	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()


func _play_ending_epilogue(ending_id: StringName) -> void:
	var epilogue_data: Dictionary = {}
	match ending_id:
		&"ending_dawn":
			epilogue_data = {
				"act": "ENDING 1 — DAWN",
				"clock": "YANGON, MYANMAR // MONTHS LATER",
				"title": "SOMETHING WE WERE NOT READY TO BRING HOME",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "ATMOSPHERIC ENTRY // EARTH ORBIT",
						"image": "res://art/storyboards/thura_earth/sequences/may_farewell/03_after_handoff.png",
						"text": "Thura seals the Echo inside the mining module, detaches the clamps, and sends the contaminated section into Earth's atmosphere at a steep, destructive angle. The colony organism burns away in the plasma of re-entry while the return capsule splashes down safely in the ocean.",
					},
					{
						"speaker": "THURA & MAY // ROOFTOP IN YANGON",
						"image": "res://art/storyboards/thura_earth/01_yangon_rooftop.png",
						"text": "Months later, Thura returns to Yangon. He stands on the same apartment rooftop from the prologue with his younger sister, May.\n\nMAY: \"Did you find anything out there?\"\nThura looks toward the stars.\nTHURA: \"Yes.\"\nMAY: \"What was it?\"\nTHURA: \"Something we were not ready to bring home.\"",
					},
				],
			}
		&"ending_trajectory":
			epilogue_data = {
				"act": "ENDING 2 — THE LAST TRAJECTORY",
				"clock": "ASTERIA-1 // DEEP SPACE TRAJECTORY",
				"title": "TELL MY FAMILY I SAW THE SKY THEY SHOWED ME",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DR. THURA MIN // FINAL TRANSMISSION",
						"image": "res://art/storyboards/thura_earth/07_astronaut_selected.png",
						"text": "Refusing to risk Earth, Thura manually redirects the entire spacecraft away from home into deep space.\n\nTHURA: \"My name is Dr. Thura Min, mission specialist of Asteria-1. This vessel must not be recovered. Do not follow our trajectory. Tell my family I saw the sky they showed me.\"\n\nYears later, a deep-space listening station receives four pulses, followed by a seven-second pause.",
					},
				],
			}
		&"ending_homecoming":
			epilogue_data = {
				"act": "ENDING 3 — HOMECOMING",
				"clock": "EARTH RECOVERY ZONE // LANDING SITE",
				"title": "FOUR PULSES. SEVEN SECONDS OF SILENCE.",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "EARTH RECOVERY TEAM // CAPSULE HATCH",
						"text": "The return capsule lands safely on Earth without full containment confirmation. Recovery teams approach the scorched hull; Thura appears to be the only survivor.\n\nAs the hatch opens, beneath the spacecraft, a black reflective substance slowly slips into a coastal drainage channel.\n\nFour pulses. Seven seconds of silence. Four pulses.",
					},
				],
			}
		&"ending_voices":
			epilogue_data = {
				"act": "ENDING 4 — VOICES",
				"clock": "HIGH EARTH ORBIT // MISSION CONTROL LINK",
				"title": "ASTERIA-1 REQUESTING PERMISSION TO LAND",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "THE ECHO (THURA'S VOICE) // ORBITAL APPROACH",
						"text": "Having transmitted the complete electromagnetic and acoustic dossier on the Echo to Earth, Thura ejects himself into space before the ship reaches orbital insertion.\n\nMinutes later, the empty spacecraft changes direction without receiving a command. Over the radio, Mission Control hears Thura's exact voice:\n\nTHURA'S VOICE: \"Asteria-1 requesting permission to land.\"",
					},
				],
			}
	if epilogue_data.is_empty():
		_walk_hud.set_walking_visible(not _arrival_briefing_open)
		_update_player_walk_state()
		return
	_cutscene_open = true
	_story_cutscene.call(&"play_cutscene", &"epilogue_complete", epilogue_data)


func _on_arrival_briefing_dismissed() -> void:
	_arrival_briefing_open = false
	_walk_hud.set_walking_visible(true)
	_room_task_feedback = "TUTORIAL 1/3: USE [WASD / ARROWS] TO WALK  ·  COMPLETE MULTI-TASK MILESTONES TO UNLOCK GEAR"
	_room_task_feedback_timer = 7.0
	_update_player_walk_state()


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_arrival_briefing_open or _hud_modal_open or _task_console_open or _piloting_console_open or _crew_dialogue_open or _cutscene_open))
	if not player.is_physics_processing() and is_instance_valid(player.sprite):
		player.sprite.stop()
		player.sprite.frame = 0


func _on_interactive_highlights_draw() -> void:
	# Floor lighting strips and station highlight overlays removed per user request.
	pass


func _draw_small_station_highlight(_canvas: Node2D, _center: Vector2, _half_extents: Vector2, _base_col: Color, _is_near: bool, _pulse: float) -> void:
	pass


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



func _is_lab_device_interactable(device_id: StringName) -> bool:
	if _echo_lab_return_active and not _lab_entry_reveal_started:
		return false
	if device_id == &"lab_earth_comms":
		return true
	if device_id == &"lab_containment":
		return _is_ore_sample_stored() or (_is_ore_sample_collected() and not _is_ore_sample_stored())
	return false


