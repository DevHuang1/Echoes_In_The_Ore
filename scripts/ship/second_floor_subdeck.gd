@tool
extends Node2D

const SHIP_MAIN_DECK_SCENE_PATH: String = "res://scenes/ship/bare_ship_walkthrough.tscn"
const WALK_HUD_SCENE: PackedScene = preload("res://scenes/ui/walk_hud.tscn")
const SERVICE_TASK_CONSOLE_SCENE: PackedScene = preload("res://scenes/ui/service_task_console.tscn")
const STORY_CUTSCENE_SCRIPT: Script = preload("res://scripts/ui/story_cutscene_overlay.gd")
const WARM_LIGHT_SCENE: PackedScene = preload("res://scenes/ship/props/warm_ship_light.tscn")
const GAS_MIST_SCENE: PackedScene = preload("res://scenes/ship/props/ambient_gas_mist.tscn")
const PRESSURE_DOOR_SCENE: PackedScene = preload("res://scenes/ship/doors/pressure_door.tscn")
const LIFT_SCRIPT: Script = preload("res://scripts/ship/subdeck_access_lift.gd")
const STORY_STATE_META_KEY: StringName = &"echoes_story_progression_state"

const LONG_VENT_TEX: Texture2D = preload("res://art/props/floor_decals/floor_vent_long_refined.png")
const SQUARE_VENT_TEX: Texture2D = preload("res://art/props/floor_decals/floor_vent_square_refined.png")
const POWER_CONVERTER_TEX: Texture2D = preload("res://art/concepts/ship_room_props/power_converter.png")

# Reusable pixel-art storage, stored product, equipment, and monster-hiding prop scenes
const CYLINDER_RACK_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/secured_cylinder_rack.tscn")
const CARGO_LOCKER_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/cargo_locker.tscn")
const TIED_BOX_BUNDLE_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/tied_box_bundle.tscn")
const PALLET_MOVER_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/electric_pallet_mover.tscn")
const MAINT_TROLLEY_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/maintenance_trolley.tscn")
const INSPECTION_SCALE_SCENE: PackedScene = preload("res://scenes/ship/props/cargo_bay/cargo_inspection_scale.tscn")
const TURBINE_MODULE_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/turbine_module.tscn")
const COOLANT_PUMP_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/coolant_circulation_pump.tscn")
const FUEL_MANIFOLD_SCENE: PackedScene = preload("res://scenes/ship/props/engine_room/fuel_valve_manifold.tscn")

const MAP_SIZE: Vector2i = Vector2i(1774, 887)
const LIFT_RETURN_POS: Vector2 = Vector2(490.0, 172.0)
const PLAYER_SPAWN_POS: Vector2 = Vector2(490.0, 224.0)
const LIFT_INTERACT_RADIUS: float = 62.0
const SUBDECK_TASK_RADIUS: float = 64.0

const UNLIT_ROOM_TINT: Color = Color(0.015, 0.022, 0.035, 0.72)
const LIT_ROOM_SHADE_TINT: Color = Color(0.04, 0.06, 0.09, 0.18)
const FADE_SPEED: float = 5.5

# Brand-new Second Floor (Sub-Deck 02) room layout — completely distinct from the Top Floor
const ROOM_DEFINITIONS: Array = [
	{
		"id": &"s00_corridor_spine",
		"label": "S00 Upper Service Spine",
		"origin": Vector2(676.0, 195.0),
		"size": Vector2(338.0, 139.0),
		"teleport_pos": Vector2(882.0, 256.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_corridor_horizontal.png",
		"entry_rects": [
			Rect2(660.0, 225.0, 34.0, 62.0),
			Rect2(996.0, 225.0, 34.0, 62.0),
			Rect2(855.0, 316.0, 56.0, 34.0),
		],
		"wall_lights": [
			{"pos": Vector2(755.0, 233.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.40, "color": Color(1.0, 0.60, 0.28, 1.0)},
			{"pos": Vector2(945.0, 226.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.40, "color": Color(0.38, 0.78, 0.88, 1.0)},
		],
	},
	{
		"id": &"s01_lift_vestibule",
		"label": "S01 Lift Junction",
		"origin": Vector2(820.0, 334.0),
		"size": Vector2(194.0, 169.0),
		"teleport_pos": Vector2(882.0, 385.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_upper_plate.png",
		"entry_rects": [
			Rect2(855.0, 316.0, 56.0, 34.0),
			Rect2(855.0, 486.0, 56.0, 34.0),
		],
		"wall_lights": [
			{"pos": Vector2(859.0, 375.0), "side": &"left", "length": 22.0, "energy": 0.22, "scale": 0.38, "color": Color(0.38, 0.78, 0.88, 1.0)},
			{"pos": Vector2(906.0, 465.0), "side": &"right", "length": 22.0, "energy": 0.22, "scale": 0.38, "color": Color(1.0, 0.58, 0.24, 1.0)},
		],
	},
	{
		"id": &"s02_bulk_storage",
		"label": "S02 Bulk Storage Vault",
		"origin": Vector2(70.0, 40.0),
		"size": Vector2(606.0, 455.0),
		"teleport_pos": Vector2(300.0, 250.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png",
		"entry_rects": [Rect2(660.0, 225.0, 34.0, 62.0)],
		"wall_lights": [
			{"pos": Vector2(260.0, 102.0), "side": &"top", "length": 24.0, "energy": 0.24, "scale": 0.40, "color": Color(1.0, 0.62, 0.30, 1.0)},
			{"pos": Vector2(495.0, 102.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.38, "color": Color(0.42, 0.78, 0.88, 1.0)},
			{"pos": Vector2(118.0, 250.0), "side": &"left", "length": 22.0, "energy": 0.22, "scale": 0.38, "color": Color(1.0, 0.62, 0.30, 1.0)},
		],
	},
	{
		"id": &"s03_pipe_labyrinth",
		"label": "S03 Turbine & Engine Hall",
		"origin": Vector2(1014.0, 20.0),
		"size": Vector2(755.0, 480.0),
		"teleport_pos": Vector2(1355.0, 255.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png",
		"entry_rects": [Rect2(996.0, 225.0, 34.0, 62.0)],
		"wall_lights": [
			{"pos": Vector2(1355.0, 120.0), "side": &"top", "length": 24.0, "energy": 0.24, "scale": 0.42, "color": Color(0.38, 0.78, 0.88, 1.0)},
			{"pos": Vector2(1500.0, 230.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.40, "color": Color(1.0, 0.60, 0.26, 1.0)},
		],
	},
	{
		"id": &"s04_equipment_bay",
		"label": "S04 Tool & Parts Workshop",
		"origin": Vector2(190.0, 503.0),
		"size": Vector2(591.0, 375.0),
		"teleport_pos": Vector2(535.0, 675.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png",
		"entry_rects": [Rect2(764.0, 650.0, 34.0, 66.0)],
		"wall_lights": [
			{"pos": Vector2(355.0, 605.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.38, "color": Color(1.0, 0.60, 0.26, 1.0)},
			{"pos": Vector2(540.0, 605.0), "side": &"top", "length": 24.0, "energy": 0.22, "scale": 0.38, "color": Color(0.42, 0.78, 0.88, 1.0)},
		],
	},
	{
		"id": &"s05_product_depot",
		"label": "S05 Coolant Pump Bay",
		"origin": Vector2(781.0, 503.0),
		"size": Vector2(422.0, 375.0),
		"teleport_pos": Vector2(925.0, 680.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png",
		"entry_rects": [
			Rect2(855.0, 486.0, 56.0, 34.0),
			Rect2(764.0, 650.0, 34.0, 66.0),
			Rect2(1186.0, 652.0, 34.0, 60.0),
		],
		"wall_lights": [
			{"pos": Vector2(925.0, 575.0), "side": &"top", "length": 22.0, "energy": 0.22, "scale": 0.38, "color": Color(0.38, 0.78, 0.88, 1.0)},
			{"pos": Vector2(925.0, 745.0), "side": &"bottom", "length": 22.0, "energy": 0.22, "scale": 0.36, "color": Color(1.0, 0.60, 0.26, 1.0)},
		],
	},
	{
		"id": &"s06_shadow_vault",
		"label": "S06 Echo Shadow Nest",
		"origin": Vector2(1203.0, 503.0),
		"size": Vector2(565.0, 375.0),
		"teleport_pos": Vector2(1600.0, 680.0),
		"floor_tile": "res://art/overview/floor_modules/tiles/floor_tile_upper_plate.png",
		"entry_rects": [
			Rect2(1186.0, 652.0, 34.0, 60.0),
			Rect2(1368.0, 652.0, 34.0, 60.0),
		],
		"wall_lights": [
			{"pos": Vector2(1595.0, 615.0), "side": &"top", "length": 22.0, "energy": 0.18, "scale": 0.34, "color": Color(1.0, 0.38, 0.18, 1.0)},
		],
	},
]

# A crooked service route ties the storage and engine wings to the lower workshop and hidden nest.
const CORRIDOR_RECTS: Array = [
	Rect2i(650, 225, 465, 65),
	Rect2i(855, 250, 55, 305),
	Rect2i(640, 655, 165, 58),
	Rect2i(1065, 658, 390, 48),
]

# The generated floor layer already contains its grates, hazard markings, and service recesses.
const FLOOR_DECAL_COMPONENTS: Array = []
# Walkability is derived from the aligned floor/wall masks; no extra collision posts are needed.
const INTERNAL_WALL_PARTITIONS: Array = []

# Storage, engine-service, workshop, coolant, and nest props placed on verified walkable floor lanes.
const SUBDECK_PROP_PLACEMENTS: Array = [
	# S02 Bulk Storage Vault (verified interior floor x=130..610, y=125..365; upper-right bay cleared for MainDeckReturnLift)
	{"kind": &"cylinder_rack", "pos": Vector2(245.0, 138.0), "dir": 1},
	{"kind": &"cylinder_rack", "pos": Vector2(565.0, 138.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(235.0, 345.0)},
	{"kind": &"box_bundle", "pos": Vector2(435.0, 345.0)},
	{"kind": &"box_bundle", "pos": Vector2(560.0, 345.0)},
	{"kind": &"cargo_locker", "pos": Vector2(145.0, 215.0), "dir": 2, "appearance": 0},
	{"kind": &"cargo_locker", "pos": Vector2(148.0, 305.0), "dir": 2, "appearance": 1},
	{"kind": &"cargo_locker", "pos": Vector2(592.0, 195.0), "dir": 3, "appearance": 2},
	{"kind": &"pallet_mover", "pos": Vector2(315.0, 315.0), "dir": 2},
	{"kind": &"inspection_scale", "pos": Vector2(530.0, 300.0), "dir": 1},

	# S03 Turbine & Engine Hall (verified interior floor around turbine ring & east bay)
	{"kind": &"fuel_manifold", "pos": Vector2(1285.0, 115.0), "dir": 1},
	{"kind": &"turbine_module", "pos": Vector2(1355.0, 235.0), "dir": 2},
	{"kind": &"coolant_pump", "pos": Vector2(1290.0, 355.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(1450.0, 340.0), "dir": 1},
	{"kind": &"fuel_manifold", "pos": Vector2(1615.0, 245.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(1635.0, 295.0)},
	{"kind": &"cargo_locker", "pos": Vector2(1140.0, 225.0), "dir": 2, "appearance": 2},
	{"kind": &"cargo_locker", "pos": Vector2(1675.0, 265.0), "dir": 3, "appearance": 1},

	# S04 Tool & Parts Workshop (verified left bay x=285..435, right bay x=490..605, y=605..755)
	{"kind": &"turbine_module", "pos": Vector2(355.0, 635.0), "dir": 2},
	{"kind": &"cylinder_rack", "pos": Vector2(540.0, 615.0), "dir": 1},
	{"kind": &"maint_trolley", "pos": Vector2(515.0, 745.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(310.0, 745.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(405.0, 745.0)},
	{"kind": &"cargo_locker", "pos": Vector2(295.0, 680.0), "dir": 2, "appearance": 1},
	{"kind": &"cargo_locker", "pos": Vector2(592.0, 740.0), "dir": 3, "appearance": 0},

	# S05 Coolant Pump Bay (verified interior floor x=800..1055, y=565..780)
	{"kind": &"fuel_manifold", "pos": Vector2(915.0, 585.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(812.0, 635.0), "dir": 1},
	{"kind": &"coolant_pump", "pos": Vector2(1042.0, 645.0), "dir": 1},
	{"kind": &"box_bundle", "pos": Vector2(965.0, 765.0)},
	{"kind": &"cargo_locker", "pos": Vector2(890.0, 765.0), "dir": 2, "appearance": 2},

	# S06 Echo Shadow Nest (verified interior floor x=1450..1660, y=620..760)
	{"kind": &"cargo_locker", "pos": Vector2(1575.0, 622.0), "dir": 2, "appearance": 2},
	{"kind": &"cargo_locker", "pos": Vector2(1652.0, 648.0), "dir": 3, "appearance": 1},
	{"kind": &"cargo_locker", "pos": Vector2(1590.0, 748.0), "dir": 2, "appearance": 0},
	{"kind": &"box_bundle", "pos": Vector2(1642.0, 742.0)},
	{"kind": &"box_bundle", "pos": Vector2(1652.0, 700.0)},
]

# The new floor texture contains its vents and grates, so avoid overlaying old-deck decals.
const SUBDECK_VENTS: Array = []

# Multi-layered pixel-art pipe runs (matching scripts/ship/hydroponics_pipes.gd)
const PIPE_SHADOW: Color = Color(0.025, 0.031, 0.034, 0.88)
const PIPE_CASING: Color = Color(0.19, 0.23, 0.23, 1.0)
const PIPE_RIM: Color = Color(0.48, 0.51, 0.48, 1.0)
const WARM_FLUID: Color = Color(0.79, 0.34, 0.11, 1.0)
const COOL_FLUID: Color = Color(0.12, 0.66, 0.68, 1.0)
const WARM_GLINT: Color = Color(1.0, 0.73, 0.39, 0.85)
const COOL_GLINT: Color = Color(0.55, 0.93, 0.90, 0.82)
const FLOW_DASH_SPACING: float = 22.0
const FLOW_DASH_LENGTH: float = 6.0
const FLOW_SPEED: float = 42.0

# Flowing floor pipe lines disabled on Sub-Deck 02 to match its clean industrial aesthetic
var _subdeck_warm_pipe_runs: Array = []
var _subdeck_cool_pipe_runs: Array = []

const SUBDECK_TASKS: Array = [
	{
		"id": &"subdeck_inventory_manifest",
		"title": "Trace Ward's signal in the cargo vault (Flare)",
		"marker_label": "STORAGE",
		"room_name": "S02 Bulk Storage Vault",
		"action_hint": "Trace Ward's radio lure inside the bulk storage vault",
		"milestone_reward": &"emergency_flare",
		"position": Vector2(300.0, 250.0),
		"prompt": "BULK STORAGE VAULT   /   [E] TRACE WARD'S VOICE",
		"completion": "False radio lure confirmed. Unlocked: Emergency Flare.",
		"reward_item": &"emergency_flare",
		"console_task_id": &"",
	},
	{
		"id": &"subdeck_workshop_power",
		"title": "Calibrate S04 Workshop aux power (Multitool)",
		"marker_label": "WORKSHOP",
		"room_name": "S04 Engineering Workshop",
		"action_hint": "Calibrate auxiliary power converter at capacitor banks",
		"milestone_reward": &"engineering_multitool",
		"position": Vector2(535.0, 675.0),
		"prompt": "WORKSHOP POWER CONVERTER   /   [E] CALIBRATE AUX POWER BUS",
		"completion": "Workshop capacitor banks synchronized! Unlocked: Engineering Multitool.",
		"reward_item": &"engineering_multitool",
		"console_task_id": &"auxiliary_power",
	},
	{
		"id": &"subdeck_coolant_manifold",
		"title": "Align S05 Coolant Bay valves (Sealant)",
		"marker_label": "COOLANT BAY",
		"room_name": "S05 Coolant Bay",
		"action_hint": "Align circulation manifold valves to equalize pressure",
		"milestone_reward": &"pressure_sealant",
		"position": Vector2(925.0, 680.0),
		"prompt": "COOLANT CIRCULATION MANIFOLD   /   [E] ALIGN COOLANT VALVES",
		"completion": "Sub-deck coolant manifold aligned! Unlocked: Pressure Sealant.",
		"reward_item": &"pressure_sealant",
		"console_task_id": &"nutrient_flow",
	},
	{
		"id": &"subdeck_pipe_pressure",
		"title": "Rescue Leila Haddad in the engine hall (Arc Tool)",
		"marker_label": "ENGINE HALL",
		"room_name": "Turbine Engine Hall",
		"action_hint": "Free Leila Haddad and construct high-voltage arc capacitor",
		"milestone_reward": &"electrical_discharge_tool",
		"position": Vector2(1500.0, 265.0),
		"prompt": "TURBINE SERVICE CONSOLE   /   [E] RESCUE LEILA & BUILD ARC TOOL",
		"completion": "Cooling valves equalized! Constructed: Electrical Discharge Tool.",
		"reward_item": &"electrical_discharge_tool",
		"console_task_id": &"air_filter",
	},
	{
		"id": &"subdeck_shadow_nest_check",
		"title": "Inspect the hidden Echo nest (Plasma Cutter)",
		"marker_label": "DARK NEST",
		"room_name": "Breached Alcove S06",
		"action_hint": "Inspect the mineral rib nest in the breached alcove",
		"milestone_reward": &"industrial_plasma_cutter",
		"position": Vector2(1600.0, 680.0),
		"prompt": "BREACHED CONTAINMENT ALCOVE   /   [E] INSPECT ECHO NEST",
		"completion": "Mineral rib nest logged. Recovered: Industrial Plasma Cutter.",
		"reward_item": &"industrial_plasma_cutter",
		"console_task_id": &"",
	},
]

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var subdeck_floor_components: Node2D = $SubdeckFloorComponents
@onready var subdeck_pipe_network: Node2D = $SubdeckPipeNetwork
@onready var wall_layer: Node2D = $WallLayer
@onready var subdeck_props: Node2D = $SubdeckProps
@onready var subdeck_doors: Node2D = $SubdeckDoors
@onready var subdeck_lighting: Node2D = $SubdeckLighting
@onready var player: ShipPlayer = $Player

var _lights_canvas: Node2D = null
var _walk_hud: WalkHud = null
var _story_cutscene: CanvasLayer = null
var _hud_modal_open: bool = false
var _task_console_open: bool = false
var _cutscene_open: bool = false
var _pending_cutscene_task_id: StringName = &""
var _transitioning: bool = false
var _near_lift: bool = false
var _active_task_id: StringName = &""
var _completed_tasks: Dictionary = {}
var _feedback_text: String = "ACT IV: SILENT RUNNING  //  SUB-DECK 02 STORAGE, PIPES & ECHO NEST"
var _feedback_timer: float = 4.5
var _entry_grace_timer: float = 0.55
var _flow_distance: float = 0.0
var _tex_cache: Dictionary = {}

# Room lighting & Dev Menu state (matches ShipRoomLighting interface)
var _room_states: Array = []
var flicker_current_room: bool = false
var flicker_all_rooms: bool = false
var force_all_lights_on: bool = false
var flicker_rooms: Dictionary = {}
var flicker_style: StringName = &"erratic"
var flicker_speed: float = 1.0
var _flicker_time: float = 0.0
var _current_player_room_id: StringName = &""


func _load_png_image(res_path: String) -> Image:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null and not img.is_empty():
		return img
	if ResourceLoader.exists(res_path):
		var tex: Texture2D = load(res_path) as Texture2D
		if tex != null:
			return tex.get_image()
	return null


func _load_png_texture(res_path: String) -> Texture2D:
	if _tex_cache.has(res_path):
		return _tex_cache[res_path] as Texture2D
	var img: Image = _load_png_image(res_path)
	if img != null and not img.is_empty():
		var itex: ImageTexture = ImageTexture.create_from_image(img)
		_tex_cache[res_path] = itex
		return itex
	if ResourceLoader.exists(res_path):
		var rtex: Texture2D = load(res_path) as Texture2D
		_tex_cache[res_path] = rtex
		return rtex
	return null


func _ready() -> void:
	add_to_group("ship_room_lighting")
	_build_subdeck_environment()
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	if Engine.has_meta(STORY_STATE_META_KEY):
		var st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		_completed_tasks = st.get("completed_subdeck_tasks", {}).duplicate()

	var mask_tex: Texture2D = _build_walkable_mask_texture()
	player.set_walkable_floor_mask(mask_tex, Vector2.ZERO, 8.0)
	player.set_camera_bounds(Rect2(Vector2.ZERO, Vector2(MAP_SIZE)))
	if Engine.has_meta(&"dev_warp_target"):
		var dev_target: Vector2 = Engine.get_meta(&"dev_warp_target")
		Engine.remove_meta(&"dev_warp_target")
		player.global_position = dev_target
	else:
		player.global_position = PLAYER_SPAWN_POS
	if is_instance_valid(player.camera):
		player.camera.make_current()
		player.camera.reset_smoothing()

	var hud_tasks: Array[Dictionary] = []
	for task in SUBDECK_TASKS:
		var tpos: Vector2 = task["position"]
		hud_tasks.append({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"room_name": task.get("room_name", task["marker_label"]),
			"action_hint": task.get("action_hint", task["prompt"]),
			"reward_item": task.get("reward_item", &""),
			"milestone_reward": task.get("milestone_reward", task.get("reward_item", &"")),
			"is_equipment_task": StringName(task.get("reward_item", &"")) != &"",
			"position": tpos,
			"marker_position": tpos + Vector2(0.0, -28.0),
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_tasks, Vector2.ZERO, Vector2(MAP_SIZE))
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	var subdeck_floor_tex: Texture2D = _load_png_texture("res://art/overview/subdeck_02_floor_pre_arrival.png")
	var subdeck_wall_tex: Texture2D = _load_png_texture("res://art/overview/subdeck_02_walls_pre_arrival.png")
	_walk_hud.set_map_textures(subdeck_floor_tex, subdeck_wall_tex)
	_walk_hud.set_show_all_active_tasks(true)
	_walk_hud.set_story_act_label("ACT IV — THE HUNT (SUB-DECK 02)")
	for done_id in _completed_tasks:
		_walk_hud.set_task_completed(StringName(done_id), true)
	_walk_hud.set_walking_visible(true)
	_story_cutscene = STORY_CUTSCENE_SCRIPT.new() as CanvasLayer
	_story_cutscene.connect(&"cutscene_finished", _on_subdeck_cutscene_finished)
	add_child(_story_cutscene)
	_update_all_rooms(1.0, true)
	if is_instance_valid(player) and not player.equipment_used.is_connected(_on_player_equipment_used):
		player.equipment_used.connect(_on_player_equipment_used)


func _build_subdeck_environment() -> void:
	_room_states.clear()

	# 1. Load pre-baked Second Floor texture onto FloorLayer (z_index = -2)
	if is_instance_valid(floor_layer):
		floor_layer.z_as_relative = false
		floor_layer.z_index = -2
		floor_layer.centered = false
		floor_layer.position = Vector2.ZERO
		var prebaked_floor: Texture2D = _load_png_texture("res://art/overview/subdeck_02_floor_pre_arrival.png")
		floor_layer.texture = prebaked_floor if prebaked_floor != null else _build_tiled_floor_layer_texture()

	# 2. Place modular floor decal components (grates, hazard zones, hangar markings, vents) at z_index = -2 / -1
	if is_instance_valid(subdeck_floor_components):
		for child in subdeck_floor_components.get_children():
			child.queue_free()
		for decal in FLOOR_DECAL_COMPONENTS:
			var d_path: String = decal["path"]
			var d_pos: Vector2 = decal["pos"]
			var d_scale: Vector2 = decal["scale"]
			var d_sprite: Sprite2D = Sprite2D.new()
			d_sprite.centered = false
			d_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			d_sprite.texture = _load_png_texture(d_path)
			d_sprite.position = d_pos
			d_sprite.scale = d_scale
			d_sprite.modulate = Color(0.84, 0.88, 0.92, 1.0)
			subdeck_floor_components.add_child(d_sprite)

		for v in SUBDECK_VENTS:
			var vsprite: Sprite2D = Sprite2D.new()
			vsprite.z_as_relative = false
			vsprite.z_index = -1
			vsprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var kind: StringName = v["kind"]
			vsprite.texture = LONG_VENT_TEX if kind == &"long" else SQUARE_VENT_TEX
			vsprite.position = v["pos"]
			vsprite.rotation = float(v["rot"])
			vsprite.scale = v["scale"]
			subdeck_floor_components.add_child(vsprite)

		var lift_node: Node2D = Node2D.new()
		lift_node.name = "MainDeckReturnLift"
		lift_node.position = LIFT_RETURN_POS
		lift_node.set_script(LIFT_SCRIPT)
		lift_node.set("is_up_lift", true)
		subdeck_floor_components.add_child(lift_node)

	# 3. Connect pixel-art pipe network layer (z_index = -1)
	if is_instance_valid(subdeck_pipe_network):
		if not subdeck_pipe_network.draw.is_connected(_on_subdeck_pipes_draw):
			subdeck_pipe_network.draw.connect(_on_subdeck_pipes_draw)
		subdeck_pipe_network.queue_redraw()

	# 4. Build WallLayer (z_index = -1) ON TOP OF FloorLayer using real pixel-art wall_components sprites
	_build_modular_wall_components_layer()

	# 5. Populate pixel-art storage, stored products, equipment, and hiding props
	_build_subdeck_props()

	# 6. Spawn pressure doors at all 6 room entrances
	_build_subdeck_doors()

	# 7. Build per-room lighting & wall-mounted flickering light fixtures
	_build_room_lighting_nodes()


func _tile_image_into_rect(dest: Image, tile_img: Image, target_rect: Rect2i) -> void:
	if tile_img == null or tile_img.is_empty():
		dest.fill_rect(target_rect, Color(0.22, 0.25, 0.29, 1.0))
		return
	var tw: int = tile_img.get_width()
	var th: int = tile_img.get_height()
	if tw <= 0 or th <= 0:
		return
	var y: int = target_rect.position.y
	while y < target_rect.end.y:
		var h: int = mini(th, target_rect.end.y - y)
		var x: int = target_rect.position.x
		while x < target_rect.end.x:
			var w: int = mini(tw, target_rect.end.x - x)
			dest.blit_rect(tile_img, Rect2i(0, 0, w, h), Vector2i(x, y))
			x += w
		y += h


func _build_tiled_floor_layer_texture() -> Texture2D:
	var canvas: Image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.0, 0.0, 0.0, 0.0))

	var corr_h_img: Image = _load_png_image("res://art/overview/floor_modules/tiles/floor_tile_corridor_horizontal.png")
	var corr_v_img: Image = _load_png_image("res://art/overview/floor_modules/tiles/floor_tile_corridor_vertical.png")
	var default_plate_img: Image = _load_png_image("res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png")
	if default_plate_img != null:
		default_plate_img.convert(Image.FORMAT_RGBA8)
	if corr_h_img != null:
		corr_h_img.convert(Image.FORMAT_RGBA8)
	if corr_v_img != null:
		corr_v_img.convert(Image.FORMAT_RGBA8)

	# Outer dark hull foundation border under wall components so wall edges sit over solid hull framing
	var all_floor_rects: Array = []
	for rdef in ROOM_DEFINITIONS:
		var o: Vector2 = rdef["origin"]
		var s: Vector2 = rdef["size"]
		all_floor_rects.append(Rect2i(int(o.x), int(o.y), int(s.x), int(s.y)))
	for crect in CORRIDOR_RECTS:
		all_floor_rects.append(crect)

	for r in all_floor_rects:
		canvas.fill_rect(r.grow(18), Color(0.08, 0.10, 0.13, 1.0))
		canvas.fill_rect(r.grow(10), Color(0.16, 0.19, 0.23, 1.0))

	# Tile each room with its designated pixel-art floor module tile
	for rdef in ROOM_DEFINITIONS:
		var o: Vector2 = rdef["origin"]
		var s: Vector2 = rdef["size"]
		var r_rect: Rect2i = Rect2i(int(o.x), int(o.y), int(s.x), int(s.y))
		var tile_path: String = String(rdef.get("floor_tile", "res://art/overview/floor_modules/tiles/floor_tile_lower_plate.png"))
		var t_img: Image = _load_png_image(tile_path)
		if t_img != null:
			t_img.convert(Image.FORMAT_RGBA8)
		else:
			t_img = default_plate_img
		_tile_image_into_rect(canvas, t_img, r_rect)

	# Tile corridor spine, hiding alcoves, and doorway thresholds with corridor floor components
	for i in range(CORRIDOR_RECTS.size()):
		var crect: Rect2i = CORRIDOR_RECTS[i]
		var c_img: Image = corr_h_img if crect.size.x >= crect.size.y else corr_v_img
		if c_img == null:
			c_img = default_plate_img
		_tile_image_into_rect(canvas, c_img, crect)

	return ImageTexture.create_from_image(canvas)


func _add_wall_component_sprite(tex_path: String, pos: Vector2, rot: float = 0.0, sc: Vector2 = Vector2(0.5, 0.5)) -> void:
	if not is_instance_valid(wall_layer):
		return
	var sp: Sprite2D = Sprite2D.new()
	sp.centered = true
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.texture = _load_png_texture(tex_path)
	sp.position = pos
	sp.rotation = rot
	sp.scale = sc
	wall_layer.add_child(sp)


func _add_horizontal_wall_run(y: float, x_start: float, x_end: float, door_gaps: Array) -> void:
	var seg_step: float = 110.0
	var x: float = x_start
	while x < x_end - 8.0:
		var next_x: float = minf(x + seg_step, x_end)
		var mid_x: float = (x + next_x) * 0.5
		var in_gap: bool = false
		for gap in door_gaps:
			if mid_x >= gap.x - 18.0 and mid_x <= gap.y + 18.0:
				in_gap = true
				break
		if not in_gap:
			var span: float = next_x - x
			var scale_x: float = clampf(span / 180.0, 0.22, 0.56) * 0.5
			_add_wall_component_sprite(
				"res://art/overview/wall_components/wall_straight_h_long.png",
				Vector2(mid_x, y),
				0.0,
				Vector2(scale_x * 2.0, 0.46)
			)
		x += seg_step


func _add_vertical_wall_run(x: float, y_start: float, y_end: float, door_gaps: Array) -> void:
	var seg_step: float = 76.0
	var y: float = y_start
	while y < y_end - 8.0:
		var next_y: float = minf(y + seg_step, y_end)
		var mid_y: float = (y + next_y) * 0.5
		var in_gap: bool = false
		for gap in door_gaps:
			if mid_y >= gap.x - 16.0 and mid_y <= gap.y + 16.0:
				in_gap = true
				break
		if not in_gap:
			var span: float = next_y - y
			var scale_y: float = clampf(span / 86.0, 0.28, 0.56) * 0.5
			_add_wall_component_sprite(
				"res://art/overview/wall_components/wall_straight_v.png",
				Vector2(x, mid_y),
				0.0,
				Vector2(0.46, scale_y * 2.0)
			)
		y += seg_step


func _build_modular_wall_components_layer() -> void:
	if not is_instance_valid(wall_layer):
		return
	for child in wall_layer.get_children():
		if child.name != "WallsSprite":
			child.queue_free()

	var walls_sprite: Sprite2D = wall_layer.get_node_or_null("WallsSprite") as Sprite2D
	if walls_sprite == null:
		walls_sprite = Sprite2D.new()
		walls_sprite.name = "WallsSprite"
		walls_sprite.centered = false
		walls_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wall_layer.add_child(walls_sprite)
	var prebaked_walls: Texture2D = _load_png_texture("res://art/overview/subdeck_02_walls_pre_arrival.png")
	if prebaked_walls != null:
		walls_sprite.texture = prebaked_walls

	# Internal partition wall collision shapes for hiding alcoves
	var wall_body: StaticBody2D = StaticBody2D.new()
	wall_body.name = "SubdeckInternalWallCollisions"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	wall_layer.add_child(wall_body)

	for part in INTERNAL_WALL_PARTITIONS:
		var p_pos: Vector2 = part["pos"]
		var p_rot: float = float(part["rot"])
		var p_col: Vector2 = part["col"]

		var c_node: CollisionShape2D = CollisionShape2D.new()
		var r_shape: RectangleShape2D = RectangleShape2D.new()
		r_shape.size = p_col
		c_node.shape = r_shape
		c_node.position = p_pos
		c_node.rotation = p_rot
		wall_body.add_child(c_node)


func _build_subdeck_props() -> void:
	if not is_instance_valid(subdeck_props):
		return
	for child in subdeck_props.get_children():
		child.queue_free()

	for p_item in SUBDECK_PROP_PLACEMENTS:
		var kind: StringName = p_item["kind"]
		var p_pos: Vector2 = p_item["pos"]
		var scene: PackedScene = null
		match kind:
			&"cylinder_rack":
				scene = CYLINDER_RACK_SCENE
			&"cargo_locker":
				scene = CARGO_LOCKER_SCENE
			&"box_bundle":
				scene = TIED_BOX_BUNDLE_SCENE
			&"pallet_mover":
				scene = PALLET_MOVER_SCENE
			&"maint_trolley":
				scene = MAINT_TROLLEY_SCENE
			&"inspection_scale":
				scene = INSPECTION_SCALE_SCENE
			&"turbine_module":
				scene = TURBINE_MODULE_SCENE
			&"coolant_pump":
				scene = COOLANT_PUMP_SCENE
			&"fuel_manifold":
				scene = FUEL_MANIFOLD_SCENE
		if scene == null:
			continue
		var inst: Node2D = scene.instantiate() as Node2D
		inst.position = p_pos
		if p_item.has("dir"):
			var dir_val: int = int(p_item["dir"])
			inst.set("direction", dir_val)
		if p_item.has("appearance"):
			var app_val: int = int(p_item["appearance"])
			inst.set("appearance", app_val)
		subdeck_props.add_child(inst)

	# Auxiliary power converters mounted in S03 and S04
	var converter_positions: Array = [
		Vector2(1145.0, 285.0),
		Vector2(540.0, 745.0),
	]
	for cpos in converter_positions:
		var psprite: Sprite2D = Sprite2D.new()
		psprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		psprite.texture = POWER_CONVERTER_TEX
		psprite.scale = Vector2(0.028, 0.028)
		psprite.position = cpos
		psprite.modulate = Color(0.86, 0.88, 0.92, 1.0)
		subdeck_props.add_child(psprite)

	# Sub-deck steam & containment vapor pockets
	var mist_configs: Array = [
		{"pos": Vector2(1450.0, 255.0), "color": Color(0.52, 0.75, 0.86, 1.0), "opacity": 0.34},
		{"pos": Vector2(882.0, 420.0), "color": Color(0.88, 0.52, 0.24, 1.0), "opacity": 0.32},
		{"pos": Vector2(1600.0, 680.0), "color": Color(0.52, 0.82, 0.40, 1.0), "opacity": 0.46},
		{"pos": Vector2(535.0, 680.0), "color": Color(0.68, 0.76, 0.82, 1.0), "opacity": 0.30},
	]
	for mcfg in mist_configs:
		var mist: Node2D = GAS_MIST_SCENE.instantiate() as Node2D
		mist.position = mcfg["pos"]
		mist.set("gas_color", mcfg["color"])
		mist.set("opacity", float(mcfg["opacity"]))
		subdeck_props.add_child(mist)


func _build_subdeck_doors() -> void:
	if not is_instance_valid(subdeck_doors):
		return
	for child in subdeck_doors.get_children():
		child.queue_free()

	var door_positions: Array = [
		{"id": &"s02_storage_door", "pos": Vector2(676.0, 255.5), "width": 46.0, "orientation": 1},
		{"id": &"s03_engine_door", "pos": Vector2(1013.5, 255.5), "width": 46.0, "orientation": 1},
		{"id": &"s04_workshop_door", "pos": Vector2(780.5, 683.0), "width": 58.0, "orientation": 1},
		{"id": &"s05_coolant_door", "pos": Vector2(882.5, 502.5), "width": 48.0, "orientation": 0},
		{"id": &"s05_nest_corridor_door", "pos": Vector2(1203.0, 680.5), "width": 48.0, "orientation": 1},
		{"id": &"s06_nest_door", "pos": Vector2(1385.0, 680.5), "width": 48.0, "orientation": 1},
	]
	for dcfg in door_positions:
		var door: Node2D = PRESSURE_DOOR_SCENE.instantiate() as Node2D
		door.position = dcfg["pos"]
		door.set("door_id", dcfg["id"])
		door.set("opening_width", float(dcfg["width"]))
		door.set("orientation", int(dcfg.get("orientation", 0)))
		door.set("wall_depth", 24.0)
		subdeck_doors.add_child(door)


func _wall_inward_normal(wall_side: StringName) -> Vector2:
	match wall_side:
		&"bottom":
			return Vector2.UP
		&"left":
			return Vector2.RIGHT
		&"right":
			return Vector2.LEFT
		_:
			return Vector2.DOWN


func _wall_tangent(wall_side: StringName) -> Vector2:
	match wall_side:
		&"left", &"right":
			return Vector2.DOWN
		_:
			return Vector2.RIGHT


func _build_room_lighting_nodes() -> void:
	if not is_instance_valid(subdeck_lighting):
		return
	for child in subdeck_lighting.get_children():
		child.queue_free()

	var editor_lit: float = 1.0 if Engine.is_editor_hint() else 0.0
	var floor_img: Image = _load_png_image("res://art/overview/subdeck_02_floor_pre_arrival.png")
	if floor_img != null and not floor_img.is_empty():
		floor_img.convert(Image.FORMAT_RGBA8)

	for def in ROOM_DEFINITIONS:
		var origin: Vector2 = def["origin"]
		var size: Vector2 = def["size"]
		var rw: int = int(size.x)
		var rh: int = int(size.y)
		var r_img: Image = Image.create(rw, rh, false, Image.FORMAT_RGBA8)
		if floor_img != null and not floor_img.is_empty():
			var ox: int = int(origin.x)
			var oy: int = int(origin.y)
			var fw: int = floor_img.get_width()
			var fh: int = floor_img.get_height()
			for ly in range(rh):
				var gy: int = oy + ly
				if gy < 0 or gy >= fh:
					continue
				for lx in range(rw):
					var gx: int = ox + lx
					if gx < 0 or gx >= fw:
						continue
					var fa: float = floor_img.get_pixel(gx, gy).a
					if fa > 0.02:
						r_img.set_pixel(lx, ly, Color(1.0, 1.0, 1.0, fa))
		else:
			r_img.fill(Color(1.0, 1.0, 1.0, 1.0))
		var r_tex: ImageTexture = ImageTexture.create_from_image(r_img)

		var dim_sprite: Sprite2D = Sprite2D.new()
		dim_sprite.name = "%s_DimOverlay" % String(def["id"])
		dim_sprite.centered = false
		dim_sprite.position = origin
		dim_sprite.z_index = 1
		dim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dim_sprite.texture = r_tex
		dim_sprite.modulate = UNLIT_ROOM_TINT
		subdeck_lighting.add_child(dim_sprite)

		var light_entries: Array = []
		var wall_fixtures: Array = []
		var wall_defs: Array = def.get("wall_lights", [])
		for wdef in wall_defs:
			var wpos: Vector2 = wdef["pos"]
			var wside: StringName = wdef.get("side", &"top")
			var wlen: float = float(wdef.get("length", 24.0))
			var wcol: Color = wdef.get("color", Color(1.0, 0.74, 0.38, 1.0))
			wall_fixtures.append({
				"pos": wpos,
				"side": wside,
				"length": wlen,
				"color": wcol,
				"lit_amount": editor_lit,
				"is_flickering": false,
			})

			var wlight: PointLight2D = WARM_LIGHT_SCENE.instantiate() as PointLight2D
			wlight.position = wpos + _wall_inward_normal(wside) * 18.0
			wlight.energy = float(wdef.get("energy", 0.46))
			wlight.texture_scale = float(wdef.get("scale", 0.50))
			wlight.color = wcol
			subdeck_lighting.add_child(wlight)
			light_entries.append({
				"node": wlight,
				"base_energy": wlight.energy,
			})

		_room_states.append({
			"id": def["id"],
			"label": def.get("label", String(def["id"])),
			"teleport_pos": def.get("teleport_pos", origin + size * 0.5),
			"bbox": Rect2(origin, size),
			"origin": origin,
			"image": r_img,
			"entry_rects": def.get("entry_rects", []),
			"dim_sprite": dim_sprite,
			"lights": light_entries,
			"wall_fixtures": wall_fixtures,
			"lit_factor": 0.0,
		})

	if not is_instance_valid(_lights_canvas):
		_lights_canvas = Node2D.new()
		_lights_canvas.name = "MountedLightsCanvas"
		_lights_canvas.z_as_relative = false
		_lights_canvas.z_index = 2
		_lights_canvas.draw.connect(_on_lights_canvas_draw.bind(_lights_canvas))
		subdeck_lighting.add_child(_lights_canvas)


func _on_lights_canvas_draw(canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = _lights_canvas
	if not is_instance_valid(player) or not is_instance_valid(canvas) or not canvas.is_inside_tree():
		return
	# Overhead task markers already indicate each objective on top;
	# unnecessary floor highlight boxes/brackets have been removed.


func _draw_small_station_highlight(_canvas: Node2D, _center: Vector2, _half_extents: Vector2, _base_col: Color, _is_near: bool, _pulse: float) -> void:
	pass


func _on_subdeck_pipes_draw() -> void:
	# Flowing water/coolant pipe overlay disabled per aesthetic preference.
	pass


func _draw_pipe_on_layer(canvas: Node2D, points: PackedVector2Array, fluid: Color, glint: Color, flow_phase: float, reverse_flow: bool) -> void:
	if points.size() < 2:
		return
	canvas.draw_polyline(points, PIPE_SHADOW, 7.4, true)
	canvas.draw_polyline(points, PIPE_CASING, 5.8, true)
	canvas.draw_polyline(points, PIPE_RIM, 3.7, true)
	canvas.draw_polyline(points, fluid, 1.9, true)
	canvas.draw_polyline(_offset_points(points, Vector2(0.0, -0.8)), glint, 0.7, true)
	_draw_pipe_flow(canvas, points, glint, flow_phase, reverse_flow)

	for i in range(points.size()):
		var pt: Vector2 = points[i]
		canvas.draw_circle(pt, 3.8, PIPE_SHADOW)
		canvas.draw_circle(pt, 2.9, PIPE_RIM)
		canvas.draw_circle(pt, 1.75, PIPE_CASING)
		canvas.draw_circle(pt, 0.9, fluid)
		if i < points.size() - 1:
			var next_pt: Vector2 = points[i + 1]
			var seg_len: float = pt.distance_to(next_pt)
			if seg_len >= 120.0:
				var mid: Vector2 = pt.lerp(next_pt, 0.5)
				var dir: Vector2 = (next_pt - pt) / seg_len
				var across: Vector2 = Vector2(-dir.y, dir.x)
				canvas.draw_line(mid - across * 4.5, mid + across * 4.5, PIPE_SHADOW, 5.2, true)
				canvas.draw_line(mid - across * 3.2, mid + across * 3.2, PIPE_RIM, 2.5, true)
				canvas.draw_circle(mid, 0.8, WARM_GLINT)


func _draw_pipe_flow(canvas: Node2D, points: PackedVector2Array, color: Color, flow_phase: float, reverse_flow: bool) -> void:
	var total_length: float = _path_length(points)
	if total_length <= 0.0:
		return
	var dash_spacing: float = minf(FLOW_DASH_SPACING, total_length * 0.5)
	var dash_length: float = minf(FLOW_DASH_LENGTH, dash_spacing * 0.8)
	var dash_start: float = fposmod(flow_phase, dash_spacing) - dash_length
	while dash_start < total_length:
		var visible_start: float = maxf(dash_start, 0.0)
		var visible_end: float = minf(dash_start + dash_length, total_length)
		if visible_end > visible_start:
			var start_distance: float = total_length - visible_end if reverse_flow else visible_start
			var end_distance: float = total_length - visible_start if reverse_flow else visible_end
			canvas.draw_line(
				_point_at_distance(points, start_distance),
				_point_at_distance(points, end_distance),
				color,
				1.25,
				true
			)
		dash_start += dash_spacing


func _path_length(points: PackedVector2Array) -> float:
	var length: float = 0.0
	for index in range(points.size() - 1):
		length += points[index].distance_to(points[index + 1])
	return length


func _point_at_distance(points: PackedVector2Array, distance: float) -> Vector2:
	var remaining: float = distance
	for index in range(points.size() - 1):
		var start: Vector2 = points[index]
		var finish: Vector2 = points[index + 1]
		var segment_length: float = start.distance_to(finish)
		if remaining <= segment_length and segment_length > 0.001:
			return start.lerp(finish, remaining / segment_length)
		remaining -= segment_length
	return points[points.size() - 1]


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted: PackedVector2Array = PackedVector2Array()
	for point in points:
		shifted.append(point + offset)
	return shifted


func _build_walkable_mask_texture() -> Texture2D:
	var mask_img: Image = _load_png_image("res://art/overview/subdeck_02_walkable_mask_pre_arrival.png")
	if mask_img != null and not mask_img.is_empty():
		mask_img.convert(Image.FORMAT_RGBA8)
		var bridge_rects: Array[Rect2i] = [
			Rect2i(175, 160, 43, 46),
			Rect2i(175, 234, 43, 44),
			Rect2i(358, 160, 42, 46),
			Rect2i(358, 234, 42, 44),
			Rect2i(645, 234, 215, 44),
			Rect2i(985, 234, 135, 44),
			Rect2i(860, 236, 45, 322),
			Rect2i(1180, 234, 505, 64),
			Rect2i(1265, 138, 130, 157),
			Rect2i(1180, 275, 305, 113),
			Rect2i(442, 644, 42, 62),
			Rect2i(640, 655, 435, 57),
			Rect2i(1065, 658, 390, 46),
			Rect2i(1550, 635, 110, 110),
		]
		for br in bridge_rects:
			mask_img.fill_rect(br, Color(1.0, 1.0, 1.0, 1.0))
		return ImageTexture.create_from_image(mask_img)

	var img: Image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for def in ROOM_DEFINITIONS:
		var o: Vector2 = def["origin"]
		var s: Vector2 = def["size"]
		img.fill_rect(Rect2i(int(o.x), int(o.y), int(s.x), int(s.y)), Color(1.0, 1.0, 1.0, 1.0))
	for crect in CORRIDOR_RECTS:
		img.fill_rect(crect, Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if _transitioning:
		return
	if _entry_grace_timer > 0.0:
		_entry_grace_timer = maxf(_entry_grace_timer - delta, 0.0)
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(_feedback_timer - delta, 0.0)
		if is_zero_approx(_feedback_timer):
			_feedback_text = ""

	_flow_distance = fposmod(_flow_distance + delta * FLOW_SPEED, 10000.0)
	_flicker_time = fposmod(_flicker_time + delta * maxf(flicker_speed, 0.1), 1000.0)
	if is_instance_valid(subdeck_pipe_network):
		subdeck_pipe_network.queue_redraw()
	_update_all_rooms(delta, false)
	_update_stalker_player_collision(delta)
	if is_instance_valid(_lights_canvas):
		_lights_canvas.queue_redraw()

	if _entry_grace_timer <= 0.0 and not _hud_modal_open and not _task_console_open and not _cutscene_open:
		if absf(player.global_position.x - LIFT_RETURN_POS.x) <= 34.0 and absf(player.global_position.y - LIFT_RETURN_POS.y) <= 22.0 and Input.is_action_pressed(&"move_up"):
			_return_to_main_deck()
			return

	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _hud_modal_open or _task_console_open or _cutscene_open or not event.is_action_pressed(&"interact"):
		return
	if _near_lift:
		get_viewport().set_input_as_handled()
		_return_to_main_deck()
	elif _active_task_id != &"":
		get_viewport().set_input_as_handled()
		_trigger_subdeck_task(_active_task_id)


func _refresh_prompt() -> void:
	_near_lift = false
	_active_task_id = &""
	if _hud_modal_open or _task_console_open or _cutscene_open or not is_instance_valid(_walk_hud):
		if is_instance_valid(_walk_hud):
			_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(LIFT_RETURN_POS) <= LIFT_INTERACT_RADIUS:
		_near_lift = true
		_walk_hud.set_interaction_prompt("MAIN DECK CARGO LIFT   /   [E] ASCEND TO FIRST FLOOR", true)
		return

	var closest_task: Dictionary = {}
	var closest_dist: float = SUBDECK_TASK_RADIUS
	for task in SUBDECK_TASKS:
		var tid: StringName = task["id"]
		if _completed_tasks.has(tid):
			continue
		var tpos: Vector2 = task["position"]
		var dist: float = player.global_position.distance_to(tpos)
		if dist <= closest_dist:
			closest_dist = dist
			closest_task = task
	if not closest_task.is_empty():
		_active_task_id = closest_task["id"]
		var prompt_str: String = closest_task["prompt"]
		_walk_hud.set_interaction_prompt(prompt_str, true)
		return

	if _feedback_timer > 0.0 and not _feedback_text.is_empty():
		_walk_hud.set_interaction_prompt(_feedback_text, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _trigger_subdeck_task(task_id: StringName) -> void:
	if _completed_tasks.has(task_id) or _task_console_open or _cutscene_open:
		return
	var console_id: StringName = &""
	for task in SUBDECK_TASKS:
		if task["id"] == task_id:
			console_id = StringName(task.get("console_task_id", &""))
			break
	if console_id != &"":
		_open_subdeck_task_console(task_id, console_id)
	else:
		_complete_subdeck_task(task_id, true)


func _open_subdeck_task_console(subdeck_task_id: StringName, console_task_id: StringName) -> void:
	if _task_console_open:
		return
	DialogueAudioSynth.play_sfx("terminal_open", self, -3.0)
	_task_console_open = true
	_pending_cutscene_task_id = &""
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console: ServiceTaskConsole = SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(console_task_id, _completed_tasks.size(), SUBDECK_TASKS.size())
	console.task_completed.connect(func(_cid: StringName): _on_subdeck_console_completed(subdeck_task_id))
	console.console_closed.connect(_on_subdeck_console_closed)
	add_child(console)


func _on_subdeck_console_completed(subdeck_task_id: StringName) -> void:
	_complete_subdeck_task(subdeck_task_id, false)
	_pending_cutscene_task_id = subdeck_task_id


func _on_subdeck_console_closed() -> void:
	_task_console_open = false
	if _pending_cutscene_task_id != &"":
		var next_cutscene_id: StringName = _pending_cutscene_task_id
		_pending_cutscene_task_id = &""
		var cdata: Dictionary = _build_subdeck_cutscene(next_cutscene_id)
		if not cdata.is_empty() and is_instance_valid(_story_cutscene):
			_cutscene_open = true
			_walk_hud.set_walking_visible(false)
			_update_player_walk_state()
			_story_cutscene.call(&"play_cutscene", next_cutscene_id, cdata)
			return
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()


func _complete_subdeck_task(task_id: StringName, play_cutscene_now: bool = true) -> void:
	if _completed_tasks.has(task_id):
		return
	DialogueAudioSynth.play_sfx("task_complete", self, -2.0)
	var completion: String = "Sub-deck check complete."
	var reward_item: StringName = &""
	for task in SUBDECK_TASKS:
		var tid: StringName = task["id"]
		if tid == task_id:
			completion = String(task["completion"])
			reward_item = StringName(task.get("reward_item", &""))
			break
	_completed_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)

	if reward_item != &"" and not _walk_hud.has_equipment_item(reward_item):
		var auto_equip: bool = reward_item != &"emergency_flare" and reward_item != &"pressure_sealant"
		_walk_hud.unlock_equipment_item(reward_item, auto_equip, completion)

	_save_subdeck_state()
	_feedback_text = "%s\nSUB-DECK CHECKS  %d / %d COMPLETE" % [completion, _completed_tasks.size(), SUBDECK_TASKS.size()]
	_feedback_timer = 4.5

	if play_cutscene_now:
		var cdata: Dictionary = _build_subdeck_cutscene(task_id)
		if not cdata.is_empty() and is_instance_valid(_story_cutscene):
			_cutscene_open = true
			_walk_hud.set_walking_visible(false)
			_update_player_walk_state()
			_story_cutscene.call(&"play_cutscene", task_id, cdata)


func _build_subdeck_cutscene(task_id: StringName) -> Dictionary:
	match task_id:
		&"subdeck_inventory_manifest":
			return {
				"act": "ACT IV — CHAPTER 2: SILENT RUNNING",
				"clock": "ASTERIA-1 // SUB-DECK 02 // STORED PRODUCTS DEPOT",
				"title": "IMITATIONS IN THE DARK (SUB-DECK STORAGE)",
				"echo_pulse": true,
				"reward": {
					"name": "Emergency Flare",
					"desc": "Sub-Deck Storage Vault: High-intensity thermal flare kit unlocked!",
					"texture": load("res://art/tools/icons/emergency_flare.png"),
				},
				"slides": [
					{
						"speaker": "THE ECHO (ELIAS WARD'S VOICE) // SUB-DECK INTERCOM",
						"text": "Through the dark maintenance spine, Elias Ward's voice echoes from two different vents at once, repeating his earlier joke with unnatural cadence. Some calls over the ship radio are genuine; others are imitations — and the Echo is learning to speak more convincingly.\n\n[Complete the remaining Sub-Deck 02 checks to help Leila Haddad assemble the Electrical Discharge Tool.]",
					},
				],
			}
		&"subdeck_workshop_power":
			return {
				"act": "ACT IV — SUB-DECK 02 // S04 TOOL & PARTS WORKSHOP",
				"clock": "ASTERIA-1 // SUB-DECK 02 // AUXILIARY CONVERTER BAY",
				"title": "WORKSHOP CAPACITOR BANKS SYNCHRONIZED",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "LEILA HADDAD (INTERCOM) // SUB-DECK ENGINEERING",
						"text": "LEILA HADDAD: 'Nice work on the S04 Workshop converter, Thura! The lower deck bus is holding steady now, and we've got enough capacitor charge to energize the high-voltage arc coils once the coolant manifold and turbine lines are stabilized.'",
					},
				],
			}
		&"subdeck_coolant_manifold":
			return {
				"act": "ACT IV — SUB-DECK 02 // S05 COOLANT PUMP BAY",
				"clock": "ASTERIA-1 // SUB-DECK 02 // COOLANT CIRCULATION DEPOT",
				"title": "SUB-HULL COOLANT MANIFOLD ALIGNED",
				"echo_pulse": false,
				"slides": [
					{
						"speaker": "DR. THURA MIN // S05 COOLANT BAY TELEMETRY",
						"text": "With all three circulation valves aligned in S05, chilled coolant floods back into the starboard turbine loop, purging the superheated steam pockets that the Echo was using for cover.",
					},
				],
			}
		&"subdeck_pipe_pressure":
			var c_dict: Dictionary = {
				"act": "ACT IV — CHAPTER 3: THE ENGINEER",
				"clock": "ASTERIA-1 // SUB-DECK 02 // TURBINE ENGINE HALL",
				"title": "LEILA HADDAD & THE ELECTRICAL ARC WEAPON",
				"echo_pulse": true,
				"reward": {
					"name": "Electrical Discharge Tool",
					"desc": "Sub-Deck Engine Hall Complete: High-voltage arc weapon unlocked!",
					"texture": load("res://art/tools/icons/electrical_discharge_tool.png"),
				},
				"slides": [
					{
						"speaker": "LEILA HADDAD // CHIEF ENGINEER",
						"text": "Leila Haddad is trapped behind the reactor-control partition while the Echo stalks the warm, powered steam conduits.\n\nLEILA: 'Thura! The organism grows by consuming electrical energy and heat, but high-voltage arc discharges force it to recoil! Reactivate the cooling valves and we can wire an Electrical Discharge Tool!'",
					},
					{
						"speaker": "CRITICAL DECISION // REACTOR COOLING MANIFOLD",
						"text": "The Echo's four-pulse vibration shakes the catwalk outside Leila's bulkhead. Do you risk the warm conduit corridor to pull Leila out, or prioritize remote engine restoration?",
						"choices": [
							{"id": &"rescue_leila", "label": "Flush coolant lines, repel the Echo & rescue Chief Engineer Leila Haddad"},
							{"id": &"prioritize_engine", "label": "Lock the reactor partition & prioritize remote engine restoration"},
						],
					},
				],
			}
			return c_dict
		&"subdeck_shadow_nest_check":
			return {
				"act": "ACT IV — THE ECHO'S TRAITS",
				"clock": "ASTERIA-1 // SUB-DECK 02 // SHADOW CONTAINMENT NEST",
				"title": "DORMANT FOR THOUSANDS OF YEARS",
				"echo_pulse": true,
				"reward": {
					"name": "Industrial Plasma Cutter",
					"desc": "Sub-Deck Shadow Nest: Heavy plasma cutter recovered!",
					"texture": load("res://art/tools/icons/industrial_plasma_cutter.png"),
				},
				"slides": [
					{
						"speaker": "DR. THURA MIN // CONTAINMENT ANALYSIS",
						"text": "Inside the breached shadow vault, black mineral ribs have fused into the bulkhead. Thura's analysis is complete: the Echo cannot survive prolonged atmospheric re-entry temperatures. If lured into the mining module and detached at a steep entry angle, the heat of Earth's atmosphere will destroy it completely.",
					},
				],
			}
	return {}


func _on_subdeck_cutscene_finished(cutscene_id: StringName, choice_id: StringName) -> void:
	_cutscene_open = false
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()
	if cutscene_id == &"subdeck_pipe_pressure":
		var st: Dictionary = {}
		if Engine.has_meta(STORY_STATE_META_KEY):
			var raw_st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
			st = raw_st.duplicate(true)
		st["leila_rescued"] = (choice_id != &"prioritize_engine")
		Engine.set_meta(STORY_STATE_META_KEY, st)
		if choice_id == &"rescue_leila":
			_feedback_text = "LEILA HADDAD RESCUED  //  ELECTRICAL DISCHARGE TOOL UNLOCKED"
		else:
			_feedback_text = "ENGINE RESTORED REMOTELY  //  LEILA TAKEN BY THE ECHO  //  DISCHARGE TOOL RECOVERED"
		_feedback_timer = 5.5


func _save_subdeck_state() -> void:
	var st: Dictionary = {}
	if Engine.has_meta(STORY_STATE_META_KEY):
		var raw_st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		st = raw_st.duplicate(true)
	st["completed_subdeck_tasks"] = _completed_tasks.duplicate()
	Engine.set_meta(STORY_STATE_META_KEY, st)


func _return_to_main_deck() -> void:
	if _transitioning:
		return
	DialogueAudioSynth.play_sfx("lift_move", self, -2.0)
	_save_subdeck_state()
	_transitioning = true
	Engine.set_meta(&"returning_from_second_floor", true)
	get_tree().change_scene_to_file(SHIP_MAIN_DECK_SCENE_PATH)


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_hud_modal_open or _task_console_open or _cutscene_open))


func _update_all_rooms(delta: float, snap_immediately: bool) -> void:
	if not is_instance_valid(player):
		return
	var pt: Vector2 = player.global_position
	var extra_illum_pts: Array[Vector2] = []
	if player.has_method("get_active_illumination_points"):
		var raw_pts: Array = player.call("get_active_illumination_points")
		for rp in raw_pts:
			var rvec: Vector2 = rp
			extra_illum_pts.append(rvec)

	var detected_room: StringName = &""
	for idx in range(_room_states.size()):
		var room: Dictionary = _room_states[idx]
		var room_id: StringName = room["id"]
		var bbox: Rect2 = room["bbox"]
		var entries: Array = room["entry_rects"]
		var occupied: bool = bbox.has_point(pt)
		if not occupied:
			for er in entries:
				var er_rect: Rect2 = er
				if er_rect.has_point(pt):
					occupied = true
					break
		if occupied:
			if detected_room == &"" or detected_room == &"s00_corridor_spine":
				detected_room = room_id

		var flare_lit: bool = false
		for ept in extra_illum_pts:
			if bbox.has_point(ept):
				flare_lit = true
				break
			for er in entries:
				var er_rect2: Rect2 = er
				if er_rect2.has_point(ept):
					flare_lit = true
					break
			if flare_lit:
				break

		var room_flicker_forced: bool = flicker_all_rooms or bool(flicker_rooms.get(room_id, false))
		var is_flickering: bool = room_flicker_forced or (flicker_current_room and occupied)
		var should_be_lit: bool = occupied or flare_lit or force_all_lights_on or room_flicker_forced

		var target: float = 1.0 if should_be_lit else 0.0
		var current: float = float(room["lit_factor"])
		if snap_immediately:
			current = target
		else:
			current = move_toward(current, target, delta * FADE_SPEED)
		room["lit_factor"] = current

		var effective_lit: float = current
		if is_flickering and current > 0.01:
			effective_lit = current * _compute_flicker_multiplier(_flicker_time, float(idx) * 2.17)
		_apply_room_lighting(room, effective_lit, is_flickering, idx)

	_current_player_room_id = detected_room


func _compute_flicker_multiplier(t: float, phase: float) -> float:
	var p: float = t + phase
	match flicker_style:
		&"strobe":
			var pulse: float = sin(p * 26.0) + 0.45 * sin(p * 41.0)
			return 1.28 if pulse > 0.0 else 0.02
		&"brownout":
			var wave: float = 0.5 + 0.5 * sin(p * 3.8 + sin(p * 1.7))
			var sputter: float = 0.5 + 0.5 * sin(p * 31.0)
			if wave < 0.35:
				return 0.03 + 0.12 * sputter
			elif wave < 0.55:
				return 0.20 + 0.55 * sputter
			return 0.88 + 0.20 * sin(p * 9.0)
		&"pulse":
			return 0.08 + 1.02 * (0.5 + 0.5 * sin(p * 6.5))
		_:
			var cell: float = floorf(p * 13.5)
			var noise: float = fposmod(sin(cell * 127.1 + phase * 311.7) * 43758.5453, 1.0)
			var sub_noise: float = fposmod(sin(floorf(p * 29.0) * 269.5 + phase * 183.3) * 19453.21, 1.0)
			if noise < 0.28:
				return 0.02 if sub_noise < 0.68 else 0.15
			elif noise < 0.52:
				return 0.18 + 0.58 * sub_noise
			elif noise > 0.84:
				return 1.25
			return 0.85 + 0.15 * sin(p * 19.0)


func _apply_room_lighting(room: Dictionary, lit_factor: float, is_flickering: bool, room_idx: int) -> void:
	var clamped_lit: float = clampf(lit_factor, 0.0, 1.0)
	var dim_sprite: Sprite2D = room["dim_sprite"] as Sprite2D
	if is_instance_valid(dim_sprite):
		var shade_col: Color = UNLIT_ROOM_TINT.lerp(LIT_ROOM_SHADE_TINT, clamped_lit)
		if is_flickering and clamped_lit < 0.42:
			shade_col.a = lerpf(0.85, UNLIT_ROOM_TINT.a, clamped_lit / 0.42)
		dim_sprite.modulate = shade_col

	var lights: Array = room["lights"]
	for i in range(lights.size()):
		var entry: Dictionary = lights[i]
		var light_node: PointLight2D = entry["node"] as PointLight2D
		if is_instance_valid(light_node):
			var base_e: float = float(entry["base_energy"])
			var local_lit: float = lit_factor
			if is_flickering:
				var jitter: float = 0.80 + 0.36 * sin(_flicker_time * 36.0 + float(i) * 1.9 + float(room_idx))
				local_lit *= jitter
			light_node.energy = base_e * maxf(local_lit, 0.0)
			light_node.enabled = local_lit > 0.01

	var wall_fixtures: Array = room["wall_fixtures"]
	for i in range(wall_fixtures.size()):
		var fdata: Dictionary = wall_fixtures[i]
		var fixture_lit: float = lit_factor
		if is_flickering and lit_factor > 0.01:
			var fjitter: float = 0.78 + 0.40 * sin(_flicker_time * 40.0 + float(i) * 2.3 + float(room_idx))
			fixture_lit = maxf(lit_factor * fjitter, 0.0)
		fdata["lit_amount"] = fixture_lit
		fdata["is_flickering"] = is_flickering


# --- Dev Menu / Testing API ---

func get_room_definitions() -> Array:
	return ROOM_DEFINITIONS


func get_current_player_room_id() -> StringName:
	return _current_player_room_id


func set_flicker_current_room(enabled: bool) -> void:
	flicker_current_room = enabled


func is_flicker_current_room() -> bool:
	return flicker_current_room


func set_flicker_all_rooms(enabled: bool) -> void:
	flicker_all_rooms = enabled


func is_flicker_all_rooms() -> bool:
	return flicker_all_rooms


func set_room_flicker(room_id: StringName, enabled: bool) -> void:
	if enabled:
		flicker_rooms[room_id] = true
	else:
		flicker_rooms.erase(room_id)


func toggle_room_flicker(room_id: StringName) -> bool:
	var next_state: bool = not is_room_flickering(room_id)
	set_room_flicker(room_id, next_state)
	return next_state


func is_room_flickering(room_id: StringName) -> bool:
	return bool(flicker_rooms.get(room_id, false))


func set_flicker_style(style: StringName) -> void:
	flicker_style = style


func get_flicker_style() -> StringName:
	return flicker_style


func set_flicker_speed(speed: float) -> void:
	flicker_speed = clampf(speed, 0.25, 3.0)


func get_flicker_speed() -> float:
	return flicker_speed


func set_force_all_lights_on(enabled: bool) -> void:
	force_all_lights_on = enabled


func is_force_all_lights_on() -> bool:
	return force_all_lights_on


func clear_all_flicker() -> void:
	flicker_current_room = false
	flicker_all_rooms = false
	flicker_rooms.clear()


func _on_player_equipment_used(item_id: StringName) -> void:
	var villain := get_tree().get_first_node_in_group("resonance_ore_villain") as ResonanceOreVillain
	if villain == null:
		villain = get_tree().get_first_node_in_group("ship_villain") as ResonanceOreVillain
	if villain == null:
		villain = get_node_or_null("ResonanceOreVillain") as ResonanceOreVillain
	if not is_instance_valid(villain) or not villain.visible:
		return
	if item_id in [&"emergency_flare", &"industrial_plasma_cutter", &"electrical_discharge_tool", &"captains_revolver"]:
		var dist: float = player.global_position.distance_to(villain.global_position)
		if dist <= 240.0:
			villain.repel_with_tool(item_id, player.global_position)
			if is_instance_valid(_walk_hud):
				_walk_hud.show_room_feedback("ECHO HOST DETERRED BY %s! RETREATING INTO SERVICE DUCTS!" % String(item_id).replace("_", " ").to_upper(), 4.5)


func _update_stalker_player_collision(_delta: float) -> void:
	var villain := get_tree().get_first_node_in_group("resonance_ore_villain") as ResonanceOreVillain
	if villain == null:
		villain = get_tree().get_first_node_in_group("ship_villain") as ResonanceOreVillain
	if villain == null:
		villain = get_node_or_null("ResonanceOreVillain") as ResonanceOreVillain
	if not is_instance_valid(villain) or not villain.visible:
		return
	if player.get("is_concealed") == true or player.is_in_group("concealed_players"):
		return
	var dist: float = player.global_position.distance_to(villain.global_position)
	if dist <= 28.0:
		var equipped: StringName = player.get_equipped_item_id() if player.has_method("get_equipped_item_id") else &""
		if equipped in [&"emergency_flare", &"electrical_discharge_tool"]:
			villain.repel_with_tool(equipped, player.global_position)
			if is_instance_valid(_walk_hud):
				_walk_hud.show_room_feedback("CLOSE-RANGE DEFENSE TRIGGERED! %s REPELLED THE ECHO HOST!" % String(equipped).replace("_", " ").to_upper(), 4.5)
		elif villain.has_method("_attack_player"):
			villain.call("_attack_player", player)
		else:
			var knockback_dir: Vector2 = (player.global_position - villain.global_position).normalized()
			if knockback_dir.is_zero_approx():
				knockback_dir = Vector2.UP
			player.global_position += knockback_dir * 20.0
			if is_instance_valid(_walk_hud):
				_walk_hud.show_room_feedback("WARNING: AMARA ATTACKED! HIDE IN A LOCKER OR USE WEAPONS TO REPEL HER!", 4.0)
