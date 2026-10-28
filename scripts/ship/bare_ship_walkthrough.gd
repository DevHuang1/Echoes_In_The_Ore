@tool
extends Node2D

const FLOOR_TEXTURE: Texture2D = preload("res://art/overview/asteria_overview_floor.png")
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
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_task_entries, floor_layer.global_position, FLOOR_TEXTURE.get_size())
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
	if _active_amara_interaction:
		_begin_amara_dialogue()
	elif _active_crew_task_id != &"":
		_complete_crew_task(_active_crew_task_id)
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
	if _crew_dialogue_open:
		return
	var first_meeting: bool = not _amara_intro_seen
	_crew_dialogue_open = true
	_amara_intro_seen = true
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(true)
	_update_player_walk_state()
	_walk_hud.set_interaction_prompt("", false)
	var lines: Array[String] = []
	var offer_tasks: bool = not _crew_tasks_unlocked
	if offer_tasks:
		if first_meeting:
			lines.append("Thura, glad you're awake. I'm Dr. Amara Okoye — medical and astrobiology.")
			lines.append("Commander Chen is pushing hard to land at Site K-12 on Erebos, but the electromagnetic readings from that crater don't look natural to me.")
			lines.append("Before we descend, I need both the nutrient pump inspected and the seedling rack sensor calibrated. Complete both checks for me and I'll unlock your Medical Injector.")
		else:
			lines.append("Complete both hydroponics checks — the nutrient pump and the seedling rack sensor — and I'll issue your Medical Injector.")
		lines.append("Want to take them? I'll mark both stations on your ship map.")
	else:
		var completed_count: int = _completed_crew_tasks.size()
		if completed_count >= AMARA_CREW_TASKS.size():
			lines.append("Both hydroponics checks are complete and your Medical Injector is unlocked. Keep it close on Erebos, Thura.")
		elif completed_count == 1:
			for task in AMARA_CREW_TASKS:
				if not _completed_crew_tasks.has(task["id"]):
					lines.append("That's 1 of 2 hydroponics checks done. Finish %s and I'll issue your Medical Injector." % str(task["title"]))
					break
		else:
			lines.append("Complete both the nutrient pump and seedling sensor checks to unlock your Medical Injector.")
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
