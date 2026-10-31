@tool
extends Node2D

const SHIP_SCENE_PATH: String = "res://scenes/ship/bare_ship_walkthrough.tscn"
const PLANET_TEXTURE_PATH: String = "res://art/planet/erebos_extraction_surface_pixel.png"
const EREBOS_SURFACE := preload("res://art/planet/erebos_extraction_surface_pixel.png")
const WALK_HUD_SCENE: PackedScene = preload("res://scenes/ui/walk_hud.tscn")
const STORY_CUTSCENE_SCRIPT: Script = preload("res://scripts/ui/story_cutscene_overlay.gd")
const THADINGYUT_MEMORY_SCENE := preload("res://scenes/ui/thadingyut_memory_cutscene.tscn")
const ORE_EXTRACTION_CONSOLE := preload("res://scripts/ui/ore_extraction_console.gd")
const STORY_STATE_META_KEY: StringName = &"echoes_story_progression_state"
const SUIT_O2_DAMAGE_META_KEY: StringName = &"erebos_suit_o2_damaged"

const ORE_ECHO_SAMPLE_RATE: float = 22050.0
const ORE_ECHO_DURATION: float = 3.2

const EXTRACTION_RIG_TASK_ID := &"erebos_rig_test"
const RIG_REPORT_TASK_ID := &"report_failed_rig"
const ORE_RETURN_TASK_ID := &"return_ore_to_amara"
const RIDGE_REST_TASK_ID := &"remember_at_ridge_stone"
const ORE_ECHO_TASK_ID := &"trace_ore_echo"
const ECHO_RETURN_TASK_ID := &"return_after_ore_echo"
const EXTRACTION_RIG_POSITION := Vector2(1060.0, 520.0)
const REST_POINT := Vector2(1060.0, 610.0)
const REST_INTERACT_RADIUS: float = 78.0

const EXTRACTION_RIG := {
	"id": &"erebos_extraction_rig",
	"marker_label": "EREBOS RIG",
	"machine": "CENTRAL RESONANCE CORE DRILL",
	"depth_m": 58,
	"pressure_mpa": "2.1",
	"test_only": true,
}

# Equipment on Erebos requires multi-site progression rather than instant 1st-node handouts
const ORE_SITES: Array[Dictionary] = [
	{
		"id": &"west_cyan_ore",
		"title": "Collect a sealed sample from the exposed ore",
		"marker_label": "SITE K-12 W",
		"room_name": "Erebos Surface (West)",
		"action_hint": "Approach the exposed seam and take one sealed sample to the landing airlock.",
		"purpose": "Amara needs a clean sample to compare against the failed rig's four-pulse reading.",
		"position": Vector2(310.0, 435.0),
		"marker_position": Vector2(220.0, 336.0),
		"prompt": "EXPOSED RESONANCE ORE   /   [E] COLLECT SEALED SAMPLE",
		"completion": "Resonance ore sample secured. Return to Asteria-1 and deliver it to Dr. Okoye.",
		"reward_item": &"",
		"milestone_reward": &"",
		"log_id": &"log_okoye_crystals",
	},
	{
		"id": &"north_viridian_ore",
		"title": "Inspect the drill breach and its black mineral ribs",
		"marker_label": "THE BREACH",
		"room_name": "Main Drill Breach",
		"action_hint": "Scan the cavity and log the four-pulse pattern.",
		"purpose": "Check whether the hollow mineral ribs explain the signal heard from orbit.",
		"position": Vector2(800.0, 320.0),
		"marker_position": Vector2(800.0, 280.0),
		"prompt": "SUBSURFACE DRILL CAVITY   /   [E] INSPECT BREACH & DRILL RIG",
		"completion": "Drill breach logged. The mineral ribs match the four-pulse signal from orbit.",
		"reward_item": &"",
		"milestone_reward": &"",
		"log_id": &"log_ruiz_breach",
	},
	{
		"id": &"east_amber_ore",
		"title": "Search the eastern trench for Ruiz's signal",
		"marker_label": "RUIZ'S SIGNAL",
		"room_name": "Collapsed Trench",
		"action_hint": "Follow the signal to Ruiz's helmet and recover its last transmission.",
		"purpose": "Find out what happened to Ruiz before the tremors make the trench unsafe.",
		"position": Vector2(1180.0, 440.0),
		"marker_position": Vector2(1180.0, 400.0),
		"prompt": "RUIZ'S DAMAGED HELMET   /   [E] TRACE LAST RADIO SIGNAL",
		"completion": "Ruiz's signal fragment recovered. Return to Asteria-1 before the suit seal fails.",
		"reward_item": &"",
		"milestone_reward": &"",
		"log_id": &"log_suit_fragment",
	},
]

const AIRLOCK_ENTRY_POS: Vector2 = Vector2(800.0, 748.0)
const AIRLOCK_INTERACT_RADIUS: float = 88.0
const ORE_INTERACT_RADIUS: float = 140.0

@onready var surface_layer: Sprite2D = $PlanetSurface
@onready var airlock_gate: Node2D = $LandedShipHull/ExteriorAirlockGate
@onready var player: ShipPlayer = $Player

var _walk_hud: WalkHud = null
var _story_cutscene: CanvasLayer = null
var _extraction_console: OreExtractionConsole = null
var _hud_modal_open: bool = false
var _cutscene_open: bool = false
var _sampled_sites: Dictionary = {}
var _explored_sites: Dictionary = {}
var _active_ore_id: StringName = &""
var _near_ship_airlock: bool = false
var _near_rest_point: bool = false
var _near_echo_site: bool = false
var _near_extraction_rig: bool = false
var _resting: bool = false
var _reflection_text: String = ""
var _feedback_text: String = "ACT II: EREBOS (SITE K-12)  //  INVESTIGATE FORMATIONS & DRILL SITE"
var _feedback_timer: float = 4.5
var _transitioning: bool = false
var _interactive_highlights_canvas: Node2D = null
var _highlight_pulse_time: float = 0.0


func _make_terrain_blockers() -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	# Trace the irregular edge of each large cliff and mesa, leaving the surrounding paths open.
	polygons.append(PackedVector2Array([
		Vector2(0, 264), Vector2(38, 258), Vector2(72, 269), Vector2(101, 283), Vector2(126, 296),
		Vector2(146, 322), Vector2(162, 348), Vector2(194, 345), Vector2(223, 352), Vector2(250, 364),
		Vector2(278, 381), Vector2(292, 405), Vector2(271, 423), Vector2(245, 437), Vector2(214, 431),
		Vector2(185, 440), Vector2(151, 456), Vector2(116, 458), Vector2(84, 447), Vector2(54, 433),
		Vector2(28, 430), Vector2(0, 438),
	]))
	polygons.append(PackedVector2Array([
		Vector2(600, 226), Vector2(618, 210), Vector2(644, 205), Vector2(663, 214), Vector2(680, 199),
		Vector2(708, 206), Vector2(731, 220), Vector2(752, 212), Vector2(780, 218), Vector2(803, 206),
		Vector2(830, 216), Vector2(850, 226), Vector2(875, 214), Vector2(902, 220), Vector2(927, 212),
		Vector2(950, 223), Vector2(977, 237), Vector2(997, 258), Vector2(985, 279), Vector2(966, 290),
		Vector2(951, 310), Vector2(929, 320), Vector2(904, 317), Vector2(880, 332), Vector2(851, 340),
		Vector2(824, 335), Vector2(800, 321), Vector2(778, 308), Vector2(753, 303), Vector2(730, 312),
		Vector2(708, 300), Vector2(686, 304), Vector2(664, 286), Vector2(643, 275), Vector2(624, 257),
	]))
	polygons.append(PackedVector2Array([
		Vector2(1208, 335), Vector2(1224, 315), Vector2(1248, 307), Vector2(1270, 315), Vector2(1292, 300),
		Vector2(1318, 305), Vector2(1342, 317), Vector2(1365, 306), Vector2(1390, 316), Vector2(1410, 310),
		Vector2(1435, 323), Vector2(1460, 318), Vector2(1488, 331), Vector2(1510, 351), Vector2(1524, 374),
		Vector2(1509, 392), Vector2(1484, 401), Vector2(1465, 424), Vector2(1438, 438), Vector2(1410, 449),
		Vector2(1382, 442), Vector2(1360, 453), Vector2(1335, 445), Vector2(1314, 432), Vector2(1290, 429),
		Vector2(1268, 414), Vector2(1246, 410), Vector2(1227, 391), Vector2(1216, 368),
	]))
	polygons.append(PackedVector2Array([
		Vector2(0, 608), Vector2(36, 596), Vector2(77, 606), Vector2(111, 622), Vector2(145, 619),
		Vector2(177, 634), Vector2(207, 626), Vector2(238, 640), Vector2(271, 649), Vector2(303, 667),
		Vector2(335, 680), Vector2(366, 703), Vector2(391, 735), Vector2(418, 762), Vector2(442, 792),
		Vector2(450, 829), Vector2(438, 862), Vector2(423, 895), Vector2(391, 914), Vector2(358, 930),
		Vector2(0, 930),
	]))
	polygons.append(PackedVector2Array([
		Vector2(1372, 575), Vector2(1405, 558), Vector2(1440, 556), Vector2(1470, 565), Vector2(1500, 552),
		Vector2(1530, 560), Vector2(1563, 552), Vector2(1600, 560), Vector2(1600, 930), Vector2(1564, 928),
		Vector2(1534, 917), Vector2(1506, 930), Vector2(1474, 919), Vector2(1448, 902), Vector2(1425, 883),
		Vector2(1403, 858), Vector2(1382, 830), Vector2(1368, 797), Vector2(1350, 766), Vector2(1348, 730),
		Vector2(1360, 699), Vector2(1354, 665), Vector2(1363, 628),
	]))
	polygons.append(PackedVector2Array([
		Vector2(348, 410), Vector2(364, 390), Vector2(384, 380), Vector2(405, 385), Vector2(425, 371),
		Vector2(448, 378), Vector2(468, 390), Vector2(489, 394), Vector2(507, 411), Vector2(522, 433),
		Vector2(518, 455), Vector2(499, 472), Vector2(475, 488), Vector2(450, 493), Vector2(426, 481),
		Vector2(402, 484), Vector2(382, 471), Vector2(365, 456), Vector2(350, 438),
	]))
	# Match the visible drill, conveyor, generator, and ore tanks with separate tight hit shapes.
	polygons.append(PackedVector2Array([Vector2(803, 426), Vector2(845, 419), Vector2(900, 426), Vector2(950, 428), Vector2(985, 415), Vector2(991, 435), Vector2(958, 448), Vector2(908, 446), Vector2(856, 442), Vector2(812, 442)]))
	polygons.append(PackedVector2Array([Vector2(973, 333), Vector2(982, 317), Vector2(1003, 308), Vector2(1023, 316), Vector2(1032, 338), Vector2(1029, 365), Vector2(1047, 380), Vector2(1052, 410), Vector2(1041, 432), Vector2(1027, 443), Vector2(988, 442), Vector2(973, 426), Vector2(970, 398), Vector2(976, 373), Vector2(969, 351)]))
	polygons.append(PackedVector2Array([Vector2(1027, 409), Vector2(1051, 397), Vector2(1082, 395), Vector2(1110, 408), Vector2(1124, 426), Vector2(1117, 447), Vector2(1091, 461), Vector2(1058, 459), Vector2(1036, 450), Vector2(1019, 435)]))
	polygons.append(PackedVector2Array([Vector2(1134, 413), Vector2(1159, 408), Vector2(1184, 416), Vector2(1208, 418), Vector2(1224, 433), Vector2(1218, 454), Vector2(1197, 466), Vector2(1169, 469), Vector2(1141, 457), Vector2(1129, 438)]))
	return polygons


func _rig_test_task_entry() -> Dictionary:
	return {
		"id": EXTRACTION_RIG_TASK_ID,
		"title": "Test the extraction rig",
		"marker_label": "TEST RIG",
		"room_name": "Erebos Deep Rig",
		"action_hint": "At the marked rig, start the test cycle and read the result.",
		"purpose": "Verify the machine can run safely before Thura returns to Amara with a status report.",
		"milestone_reward": &"",
		"position": EXTRACTION_RIG_POSITION,
		"marker_position": EXTRACTION_RIG_POSITION + Vector2(0.0, -36.0),
	}


func _rig_test_failed() -> bool:
	return Engine.has_meta(&"erebos_rig_test_failed") and bool(Engine.get_meta(&"erebos_rig_test_failed"))


func _ore_seam_discovered() -> bool:
	return Engine.has_meta(&"resonance_ore_seam_discovered") and bool(Engine.get_meta(&"resonance_ore_seam_discovered"))


func _ore_sample_collected() -> bool:
	return Engine.has_meta(&"resonance_ore_sample_collected") and bool(Engine.get_meta(&"resonance_ore_sample_collected"))


func _ore_sample_stored() -> bool:
	return Engine.has_meta(&"resonance_ore_sample_stored") and bool(Engine.get_meta(&"resonance_ore_sample_stored"))


func _rig_failure_reported() -> bool:
	return Engine.has_meta(&"erebos_rig_failure_reported") and bool(Engine.get_meta(&"erebos_rig_failure_reported"))


func _echo_heard() -> bool:
	return Engine.has_meta(&"resonance_echo_heard") and bool(Engine.get_meta(&"resonance_echo_heard"))


func _ridge_rest_task_entry() -> Dictionary:
	return {
		"id": RIDGE_REST_TASK_ID,
		"title": "Sit by the failed rig and remember the past",
		"marker_label": "EXTRACTION RIG",
		"room_name": "Erebos Surface Ridge",
		"action_hint": "Sit in front of the silent rig and let the memory play.",
		"purpose": "Thura has no repair order from Amara yet. The quiet brings back the memory of asking his mother about the stars.",
		"milestone_reward": &"",
		"position": REST_POINT,
		"marker_position": REST_POINT + Vector2(0.0, -42.0),
	}


func _rig_report_task_entry() -> Dictionary:
	return {
		"id": RIG_REPORT_TASK_ID,
		"title": "Report the failed rig to Amara",
		"marker_label": "REPORT TO AMARA",
		"room_name": "Asteria-1 Airlock",
		"action_hint": "Board Asteria-1, find Dr. Okoye, and report what the test showed.",
		"purpose": "Amara must know the rig is unsafe before Thura investigates the ore seam.",
		"milestone_reward": &"",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ore_return_task_entry() -> Dictionary:
	return {
		"id": ORE_RETURN_TASK_ID,
		"title": "Return the ore sample to Dr. Okoye",
		"marker_label": "RETURN WITH ORE",
		"room_name": "Asteria-1 Airlock",
		"action_hint": "Board Asteria-1 and hand the sealed ore sample to Dr. Okoye in the lab.",
		"purpose": "Amara will compare the sample's resonance with the failed rig telemetry.",
		"milestone_reward": &"",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ore_echo_task_entry() -> Dictionary:
	var site: Dictionary = ORE_SITES[0]
	return {
		"id": ORE_ECHO_TASK_ID,
		"title": "Follow the echo to the ore seam",
		"marker_label": "ECHO SOURCE",
		"room_name": "Resonance Seam",
		"action_hint": "Return to the ore seam and follow the repeating pulses to their source.",
		"purpose": "The echo began where Thura found the sample. Find out whether the source has changed.",
		"milestone_reward": &"",
		"position": site["position"],
		"marker_position": site.get("marker_position", site["position"] + Vector2(0.0, -36.0)),
	}


func _echo_return_task_entry() -> Dictionary:
	return {
		"id": ECHO_RETURN_TASK_ID,
		"title": "Follow the echo back to Asteria-1",
		"marker_label": "RETURN TO SHIP",
		"room_name": "Asteria-1 Airlock",
		"action_hint": "Return to the airlock and warn the crew about the echo.",
		"purpose": "Something is wrong at the ore seam. Get back to the ship and check the lab and crew.",
		"milestone_reward": &"",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _rig_mining_task_entry() -> Dictionary:
	return {
		"id": &"erebos_deep_mining",
		"title": "Drill resonance core with bypass coupler",
		"marker_label": "DRILL RIG",
		"room_name": "Erebos Extraction Rig",
		"action_hint": "Operate the console, achieve 432 Hz harmonic lock, and vent coolant to extract the core intact.",
		"purpose": "The oversized resonance crystal needs a powered hauler and the lab's sealed containment tank.",
		"milestone_reward": &"resonance_ore_core",
		"position": EXTRACTION_RIG_POSITION,
		"marker_position": EXTRACTION_RIG_POSITION + Vector2(0.0, -36.0),
	}


func _core_return_task_entry() -> Dictionary:
	return {
		"id": &"cargo_core_containment",
		"title": "Ask Amara for heavy-core recovery",
		"marker_label": "RETURN TO SHIP",
		"room_name": "Asteria-1 Airlock",
		"action_hint": "The core is too large to carry. Board Asteria-1 and ask Dr. Okoye to send a powered hauler.",
		"purpose": "A recovery vehicle is needed to transport the oversized resonance core safely to the lab.",
		"milestone_reward": &"",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ready() -> void:
	if EREBOS_SURFACE != null:
		surface_layer.texture = EREBOS_SURFACE
		surface_layer.scale = Vector2(1600.0 / float(EREBOS_SURFACE.get_width()), 1000.0 / float(EREBOS_SURFACE.get_height()))
	elif not PLANET_TEXTURE_PATH.is_empty():
		var planet_img: Image = Image.load_from_file(ProjectSettings.globalize_path(PLANET_TEXTURE_PATH))
		if planet_img != null and not planet_img.is_empty():
			surface_layer.texture = ImageTexture.create_from_image(planet_img)

	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	_add_black_space_backdrop()
	var dev_mining_start: bool = Engine.has_meta(&"dev_start_mining_task")
	if dev_mining_start:
		Engine.remove_meta(&"dev_start_mining_task")

	if Engine.has_meta(STORY_STATE_META_KEY):
		var raw_st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		_sampled_sites = raw_st.get("sampled_planet_sites", {}).duplicate()
		_explored_sites = _sampled_sites.duplicate()

	var mask_img: Image = Image.create(1600, 1000, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 0))
	mask_img.fill_rect(Rect2i(64, 205, 1472, 725), Color(1, 1, 1, 1))
	# Block the solid hull body behind the airlock threshold (y > 768 around x=520..1080)
	mask_img.fill_rect(Rect2i(520, 768, 560, 220), Color(0, 0, 0, 0))
	var mask_tex := ImageTexture.create_from_image(mask_img)
	player.set_walkable_floor_mask(mask_tex, Vector2.ZERO, 8.0)
	player.set_walkable_blocker_polygons(_make_terrain_blockers())
	# Match the close gameplay framing used inside the ship.
	player.camera.zoom = Vector2(1.75, 1.75)
	player.set_camera_bounds(Rect2(Vector2.ZERO, Vector2(1600.0, 1000.0)))
	if dev_mining_start and Engine.has_meta(&"dev_warp_target"):
		var mining_target: Vector2 = Engine.get_meta(&"dev_warp_target")
		Engine.remove_meta(&"dev_warp_target")
		player.global_position = mining_target
	elif Engine.has_meta(&"dev_warp_target"):
		var dev_target: Vector2 = Engine.get_meta(&"dev_warp_target")
		Engine.remove_meta(&"dev_warp_target")
		player.global_position = dev_target
	else:
		player.global_position = Vector2(800.0, 684.0)
	if Engine.has_meta(SUIT_O2_DAMAGE_META_KEY) and bool(Engine.get_meta(SUIT_O2_DAMAGE_META_KEY)):
		player.move_speed *= 0.78
	player.camera.make_current()
	player.camera.reset_smoothing()

	var hud_tasks: Array[Dictionary] = []
	if dev_mining_start:
		hud_tasks.append(_rig_mining_task_entry())
	else:
		hud_tasks.append(_rig_test_task_entry())
	if not dev_mining_start and _rig_test_failed() and not _rig_failure_reported():
		hud_tasks.append(_rig_report_task_entry())
	var has_coupler: bool = Engine.has_meta(&"harmonic_bypass_coupler_unlocked")
	var core_extracted: bool = Engine.has_meta(&"resonance_ore_core_extracted") and bool(Engine.get_meta(&"resonance_ore_core_extracted"))
	if not dev_mining_start and has_coupler and not core_extracted:
		hud_tasks.append(_rig_mining_task_entry())
	elif not dev_mining_start and core_extracted and not Engine.has_meta(&"resonance_ore_core_stored"):
		hud_tasks.append(_core_return_task_entry())
	if not dev_mining_start and _ore_sample_collected() and not _ore_sample_stored():
		hud_tasks.append(_ore_return_task_entry())
	if not dev_mining_start and _ore_sample_stored() and not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
		hud_tasks.append(_ridge_rest_task_entry())
	if not dev_mining_start and Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete")) and not _echo_heard():
		hud_tasks.append(_ore_echo_task_entry())
	if not dev_mining_start and _echo_heard():
		hud_tasks.append(_echo_return_task_entry())

	for site in ORE_SITES:
		if dev_mining_start or not _rig_failure_reported():
			continue
		hud_tasks.append({
			"id": site["id"],
			"title": site["title"],
			"marker_label": site["marker_label"],
			"room_name": site.get("room_name", "Erebos Surface"),
			"action_hint": site.get("action_hint", ""),
			"purpose": site.get("purpose", ""),
			"reward_item": site.get("reward_item", &""),
			"milestone_reward": site.get("milestone_reward", site.get("reward_item", &"")),
			"is_equipment_task": StringName(site.get("reward_item", &"")) != &"" or StringName(site.get("milestone_reward", &"")) != &"",
			"position": site["position"],
			"marker_position": site.get("marker_position", site["position"] + Vector2(0.0, -28.0)),
		})

	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_tasks, Vector2.ZERO, Vector2(1600.0, 1000.0))
	if _rig_test_failed():
		_walk_hud.set_task_completed(EXTRACTION_RIG_TASK_ID)
	if _ore_sample_collected():
		_walk_hud.set_task_completed(StringName(ORE_SITES[0]["id"]))
	if Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete")):
		_walk_hud.set_task_completed(RIDGE_REST_TASK_ID)
	if _echo_heard():
		_walk_hud.set_task_completed(ORE_ECHO_TASK_ID)
	for done_site in _sampled_sites:
		_walk_hud.set_task_completed(StringName(done_site), true)

	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_walk_hud.set_story_act_label("ACT II — EREBOS (SITE K-12)")
	_walk_hud.set_show_all_active_tasks(false)
	_walk_hud.set_walking_visible(true)

	if not is_instance_valid(_interactive_highlights_canvas):
		_interactive_highlights_canvas = Node2D.new()
		_interactive_highlights_canvas.name = "InteractiveHighlightsCanvas"
		_interactive_highlights_canvas.z_as_relative = false
		_interactive_highlights_canvas.z_index = 1
		_interactive_highlights_canvas.draw.connect(_on_interactive_highlights_draw.bind(_interactive_highlights_canvas))
		add_child(_interactive_highlights_canvas)

	_story_cutscene = STORY_CUTSCENE_SCRIPT.new() as CanvasLayer
	_story_cutscene.connect(&"cutscene_finished", _on_cutscene_finished)
	add_child(_story_cutscene)


func _save_planet_state() -> void:
	var st: Dictionary = {}
	if Engine.has_meta(STORY_STATE_META_KEY):
		var raw_st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		st = raw_st.duplicate(true)
	st["sampled_planet_sites"] = _sampled_sites.duplicate()
	Engine.set_meta(STORY_STATE_META_KEY, st)


func _process(delta: float) -> void:
	if _transitioning:
		return
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(_feedback_timer - delta, 0.0)
		if is_zero_approx(_feedback_timer):
			_feedback_text = ""

	if not _hud_modal_open and not _cutscene_open and is_instance_valid(airlock_gate) and airlock_gate.has_method("is_open") and bool(airlock_gate.call("is_open")):
		if absf(player.global_position.x - AIRLOCK_ENTRY_POS.x) <= 46.0 and player.global_position.y >= 736.0 and Input.is_action_pressed(&"move_down"):
			_board_ship()
			return

	_highlight_pulse_time = fposmod(_highlight_pulse_time + delta * 3.2, TAU)
	if is_instance_valid(_interactive_highlights_canvas):
		_interactive_highlights_canvas.queue_redraw()

	_refresh_prompt()


func _on_interactive_highlights_draw(canvas: Node2D = null) -> void:
	if canvas == null:
		canvas = _interactive_highlights_canvas
	if not is_instance_valid(player) or not is_instance_valid(canvas) or not canvas.is_inside_tree():
		return
	# Overhead task markers already indicate each objective on top;
	# unnecessary floor highlight boxes/brackets have been removed.


func _draw_small_station_highlight(_canvas: Node2D, _center: Vector2, _half_extents: Vector2, _base_col: Color, _is_near: bool, _pulse: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _resting or _hud_modal_open or _cutscene_open or not event.is_action_pressed(&"interact"):
		return
	if _near_ship_airlock:
		get_viewport().set_input_as_handled()
		_board_ship()
	elif _active_ore_id != &"":
		get_viewport().set_input_as_handled()
		_collect_ore_sample(_active_ore_id)
	elif _near_rest_point:
		get_viewport().set_input_as_handled()
		_start_reflection()
	elif _near_echo_site:
		get_viewport().set_input_as_handled()
		_listen_for_ore_echo()
	elif _near_extraction_rig:
		get_viewport().set_input_as_handled()
		_open_extraction_console()


func _refresh_prompt() -> void:
	_near_ship_airlock = false
	_active_ore_id = &""
	_near_rest_point = false
	_near_echo_site = false
	_near_extraction_rig = false
	if _resting:
		_walk_hud.set_interaction_prompt(_reflection_text, true)
		return
	if _hud_modal_open or _cutscene_open:
		_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(AIRLOCK_ENTRY_POS) <= AIRLOCK_INTERACT_RADIUS:
		_near_ship_airlock = true
		var return_prompt := "ASTERIA-1 EXTERIOR AIRLOCK   /   [E] BOARD SHIP"
		var core_extracted_airlock: bool = Engine.has_meta(&"resonance_ore_core_extracted") and bool(Engine.get_meta(&"resonance_ore_core_extracted"))
		if core_extracted_airlock and not Engine.has_meta(&"resonance_ore_core_stored"):
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] BOARD SHIP — CORE REQUIRES HAULER"
		elif not _rig_test_failed() and _sampled_sites.is_empty():
			return_prompt = "RIG TEST STILL AVAILABLE   /   [E] BOARD ASTERIA-1"
		elif _rig_test_failed() and not _rig_failure_reported():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] BOARD SHIP & REPORT FAILED RIG"
		elif _rig_test_failed() and not _ore_sample_collected():
			return_prompt = "ORE SEAM STILL AVAILABLE   /   [E] BOARD ASTERIA-1"
		elif _ore_sample_collected() and not _ore_sample_stored():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] RETURN WITH ORE SAMPLE"
		elif _ore_sample_stored() and not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
			return_prompt = "REST TASK STILL OPEN   /   [E] RETURN TO ASTERIA-1"
		elif Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete")) and not _echo_heard():
			return_prompt = "ORE ECHO STILL ACTIVE   /   [E] RETURN TO ASTERIA-1"
		elif _echo_heard():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] FOLLOW THE ECHO BACK TO THE LAB"
		_walk_hud.set_interaction_prompt(return_prompt, true)
		return

	var reflection_complete := Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))
	if _ore_sample_stored() and not reflection_complete and player.global_position.distance_to(REST_POINT) <= REST_INTERACT_RADIUS:
		_near_rest_point = true
		_walk_hud.set_interaction_prompt("FAILED EXTRACTION RIG   /   [E] SIT AND REMEMBER", true)
		return
	if reflection_complete and not _echo_heard() and player.global_position.distance_to(ORE_SITES[0]["position"]) <= ORE_INTERACT_RADIUS:
		_near_echo_site = true
		_walk_hud.set_interaction_prompt("ORE SEAM   /   [E] LISTEN TO THE ECHO", true)
		return

	var has_bypass: bool = Engine.has_meta(&"harmonic_bypass_coupler_unlocked") or (_walk_hud != null and _walk_hud.inventory_count(&"harmonic_bypass_coupler") > 0)
	var core_extracted: bool = Engine.has_meta(&"resonance_ore_core_extracted") and bool(Engine.get_meta(&"resonance_ore_core_extracted"))

	if player.global_position.distance_to(EXTRACTION_RIG_POSITION) <= 90.0:
		_near_extraction_rig = true
		if not _rig_test_failed():
			_walk_hud.set_interaction_prompt("ORE EXTRACTION RIG   /   [E] RUN MACHINE TEST", true)
		elif has_bypass and not core_extracted:
			_walk_hud.set_interaction_prompt("EXTRACTION RIG   /   [E] INSTALL BYPASS & DRILL CORE", true)
		elif core_extracted:
			_walk_hud.set_interaction_prompt("EXTRACTION RIG   /   [E] INSPECT BOREHOLE (CORE SECURED)", true)
		else:
			_walk_hud.set_interaction_prompt("FAILED EXTRACTION RIG   /   [E] BORE MOTOR LOCKED", true)
		return

	for site in ORE_SITES:
		var site_id: StringName = site["id"]
		if _sampled_sites.has(site_id):
			continue
		if not _rig_test_failed() or not _rig_failure_reported():
			continue
		var pos: Vector2 = site["position"]
		if player.global_position.distance_to(pos) <= ORE_INTERACT_RADIUS:
			_active_ore_id = site_id
			_walk_hud.set_interaction_prompt(site["prompt"], true)
			return

	if _feedback_timer > 0.0 and not _feedback_text.is_empty():
		_walk_hud.set_interaction_prompt(_feedback_text, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _sample_ore(site_id: StringName) -> void:
	_collect_ore_sample(site_id)


func _collect_ore_sample(site_id: StringName) -> void:
	if _sampled_sites.has(site_id) or not _rig_test_failed() or not _rig_failure_reported():
		return
	var is_ore_seam := site_id == &"west_cyan_ore"
	if is_ore_seam and is_instance_valid(_walk_hud):
		_walk_hud.grant_hotbar_item(&"resonance_ore_sample")
	var completion: String = "Ore sample logged."
	var log_id: StringName = &""
	for site in ORE_SITES:
		if site["id"] == site_id:
			completion = site["completion"]
			log_id = site.get("log_id", &"")
			break
	_sampled_sites[site_id] = true
	_explored_sites[site_id] = true
	if is_ore_seam:
		Engine.set_meta(&"resonance_ore_seam_discovered", true)
		Engine.set_meta(&"resonance_ore_sample_collected", true)
	_walk_hud.set_task_completed(site_id)
	if is_ore_seam and not _ore_sample_stored() and is_instance_valid(_walk_hud):
		_walk_hud.add_task_entry(_ore_return_task_entry())
	if log_id != &"":
		_walk_hud.record_audio_log(log_id)

	_save_planet_state()
	_feedback_text = "%s\nEREBOS SITE K-12  %d / %d COMPLETE" % [completion, _sampled_sites.size(), ORE_SITES.size()]
	_feedback_timer = 4.5

	var cutscene_data: Dictionary = _build_planet_cutscene(site_id)
	if not cutscene_data.is_empty() and is_instance_valid(_story_cutscene):
		_cutscene_open = true
		_walk_hud.set_walking_visible(false)
		_update_player_walk_state()
		_story_cutscene.call(&"play_cutscene", site_id, cutscene_data)


func _open_extraction_console() -> void:
	var has_bypass: bool = Engine.has_meta(&"harmonic_bypass_coupler_unlocked") or (_walk_hud != null and _walk_hud.inventory_count(&"harmonic_bypass_coupler") > 0)
	var core_extracted: bool = Engine.has_meta(&"resonance_ore_core_extracted") and bool(Engine.get_meta(&"resonance_ore_core_extracted"))

	if _rig_test_failed() and not has_bypass and not core_extracted:
		_feedback_text = "BORE MOTOR LOCKED  //  REPORT TO DR. OKOYE ON ASTERIA-1 FOR A HARMONIC BYPASS"
		_feedback_timer = 5.0
		return

	_extraction_console = ORE_EXTRACTION_CONSOLE.new() as OreExtractionConsole
	add_child(_extraction_console)
	_extraction_console.machine_test_failed.connect(_on_machine_test_failed)
	_extraction_console.extraction_completed.connect(_on_core_extraction_completed)
	_extraction_console.modal_state_changed.connect(_on_extraction_console_modal_state_changed)

	var rig_config: Dictionary = EXTRACTION_RIG.duplicate(true)
	rig_config["bypass_active"] = has_bypass
	rig_config["test_only"] = not has_bypass and not _rig_test_failed()
	_extraction_console.open(rig_config)


func _on_core_extraction_completed(_site_id: StringName, is_pristine: bool = true) -> void:
	Engine.set_meta(&"resonance_ore_core_extracted", true)
	Engine.set_meta(&"resonance_ore_core_pristine", is_pristine)
	if is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(&"erebos_deep_mining", true)
		_walk_hud.set_task_completed(EXTRACTION_RIG_TASK_ID, true)
		_walk_hud.add_task_entry(_core_return_task_entry())
		var grade_str: String = "Pristine" if is_pristine else "Fractured"
		_walk_hud.show_objective_toast("EXTRACTION SUCCESSFUL", "%s core recovered. It is too large to carry—call Amara for a hauler." % grade_str, true)
	_feedback_text = "CORE EXTRACTED  //  TOO LARGE TO CARRY  //  ASK AMARA FOR A POWERED HAULER"
	_feedback_timer = 6.0
	call_deferred(&"_play_resonance_core_recovery_cutscene", is_pristine)


func _play_resonance_core_recovery_cutscene(is_pristine: bool) -> void:
	if not is_instance_valid(_story_cutscene) or not is_instance_valid(_walk_hud):
		return
	_cutscene_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var core_grade := "PRISTINE" if is_pristine else "FRACTURED"
	_story_cutscene.call(&"play_cutscene", &"resonance_core_recovery", {
		"act": "ACT II — EREBOS // CORE RECOVERY",
		"clock": "SITE K-12 // RECOVERED DRILL FEED",
		"title": "SOMETHING ANSWERS FROM BELOW",
		"large_artwork": true,
		"slides": [
			{
				"speaker": "DRILL CAMERA // TARGET CONTACT",
				"image": "res://art/storyboards/resonance_core_recovery/scene_04_reveal.png",
				"fade_in_seconds": 2.0,
				"typing_speed": 24.0,
				"auto_advance_seconds": 1.8,
				"text": "At target depth, the drill uncovers a pale core. Its veins repeat with impossible precision."
			},
			{
				"speaker": "EREBOS SURFACE // RIG POWER-UP",
				"image": "res://art/storyboards/resonance_core_recovery/scene_01_rig_awakens.png",
				"fade_in_seconds": 1.5,
				"typing_speed": 27.0,
				"auto_advance_seconds": 1.2,
				"text": "The rig comes alive beneath Erebos's darkening sky. Thura begins the final bore toward the four-pulse signal."
			},
			{
				"speaker": "DRILL CAMERA // DESCENT",
				"image": "res://art/storyboards/resonance_core_recovery/scene_02_descent.png",
				"fade_in_seconds": 1.5,
				"typing_speed": 27.0,
				"auto_advance_seconds": 1.2,
				"text": "The pipe sinks through layer after layer of solid basalt. The signal grows louder as the drill descends into the dark."
			},
			{
				"speaker": "RECOVERY WINCH // SAMPLE SECURED",
				"image": "res://art/storyboards/resonance_core_recovery/scene_05_extraction.png",
				"fade_in_seconds": 1.8,
				"typing_speed": 24.0,
				"auto_advance_seconds": 1.8,
				"text": "A corrupted frame jumps ahead: the sleeve has already closed around the %s Core. The signal continues inside the sealed sample." % core_grade
			},
			{
				"speaker": "DRILL CAMERA // FIRST CONTACT",
				"image": "res://art/storyboards/resonance_core_recovery/scene_03_first_contact.png",
				"fade_in_seconds": 1.8,
				"typing_speed": 25.0,
				"auto_advance_seconds": 1.5,
				"text": "The feed snaps back. At target depth, the cutter touches something pale beneath the rock. The four-pulse signal stops."
			},
			{
				"blackout": true,
				"hold_seconds": 3.4
			},
			{
				"speaker": "RECOVERED FEED // FINAL FRAME",
				"image": "res://art/storyboards/resonance_core_recovery/scene_06_horror_reveal.png",
				"fade_in_seconds": 3.6,
				"typing_speed": 18.0,
				"text": "The final frame shows Thura reflected inside the Core. He turns toward the camera. No one is behind him. The four-pulse signal returns."
			},
		]
	})


func _on_machine_test_failed(_site_id: StringName) -> void:
	Engine.set_meta(&"erebos_rig_test_failed", true)
	if is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(EXTRACTION_RIG_TASK_ID)
		_walk_hud.add_task_entry(_rig_report_task_entry())
	_feedback_text = "DRILL TEST FAILED  //  REPORT TO DR. OKOYE ABOARD ASTERIA-1"
	_feedback_timer = 6.0


func _on_extraction_console_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()
	if not is_open:
		_extraction_console = null
		_refresh_prompt()


func _listen_for_ore_echo() -> void:
	if _echo_heard() or not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
		return
	Engine.set_meta(&"resonance_echo_heard", true)
	_emit_ore_echo_visual()
	_walk_hud.set_task_completed(ORE_ECHO_TASK_ID)
	_walk_hud.add_task_entry(_echo_return_task_entry())
	_feedback_text = "THE ORE SEAM ANSWERS  //  SOMETHING IS WRONG ON ASTERIA-1"
	_feedback_timer = 6.0


func _build_planet_cutscene(site_id: StringName) -> Dictionary:
	match site_id:
		&"west_cyan_ore":
			return {
				"act": "ACT II — EREBOS // SITE K-12",
				"clock": "EREBOS SURFACE // DEPOSIT SITE K-12",
				"title": "CRYSTALS DO NOT REARRANGE THEMSELVES (SITE 1/2)",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DR. THURA MIN // SITE K-12 WEST RIDGE",
						"text": "Erebos is silent except for radio chatter and vibrations travelling through the low-gravity regolith. Near the failed rig, Thura spots an exposed seam of glass-like cyan ore. Its surface rings with the exact four-pulse pattern detected from orbit. He seals one sample for Dr. Okoye.",
					},
					{
						"speaker": "DR. AMARA OKOYE & MATEO RUIZ // SURFACE RADIO",
						"text": "OKOYE: \"Commander, these structures are too regular. Requesting we halt drilling until we study them.\"\n\nRUIZ: \"They are crystals, Amara.\"\n\nOKOYE: \"Crystals do not rearrange themselves when you shine light on them.\"\n\n[Proceed to the Main Drill Cavity north of the lander to check on Mateo Ruiz's drilling rig.]",
					},
				],
			}
		&"north_viridian_ore":
			return {
				"act": "ACT II — EREBOS // THE BREACH",
				"clock": "EREBOS SURFACE // MAIN DRILL CAVITY",
				"title": "THE BREACH BENEATH SITE K-12",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DRILL CAMERA FEED // SUBSURFACE CAVITY",
						"text": "The autonomous drill breaks through into a massive hollow chamber beneath Erebos. Instead of solid metal, the camera reveals black, reflective structures resembling mineral ribs surrounding a central mass.\n\nThe four-pulse signal stops. For several seconds, there is complete silence. Then the drilling rig loses all power.",
					},
					{
						"speaker": "MATEO RUIZ // SUIT TELEMETRY",
						"text": "Ruiz goes out manually to restart the drill. His suit camera catches a thin black substance moving against the direction of gravity.\n\nHis radio cuts out. Over the channel, the crew hears Ruiz breathing heavily, followed by a sharp metallic impact. His tracking signal begins moving underground at impossible speed. Commander Chen orders Thura to search the eastern trench while the team still has a signal.",
					},
				],
			}
		&"east_amber_ore":
			return {
				"act": "ACT II — EREBOS // EMERGENCY EVACUATION",
				"clock": "EREBOS SURFACE // COLLAPSED EXCAVATION TRENCH",
				"title": "SOMETHING IS USING HIS SUIT",
				"echo_pulse": true,
				"slides": [
					{
						"speaker": "DR. THURA MIN // EASTERN EXCAVATION TRENCH",
						"text": "Alone, Thura finds Ruiz's damaged helmet at the trench edge. The reinforced visor is shattered outward, as if something escaped from inside. Beneath the dust, Ruiz's suit radio clicks once, then falls silent.",
					},
					{
						"speaker": "MATEO RUIZ // RECOVERED SUIT RADIO FRAGMENT",
						"text": "The helmet speaker gives a few clicks and a burst of static. A voice almost forms, then vanishes beneath the tremor. Thura cannot make out the words.",
					},
					{
						"speaker": "COMMANDER MAYA CHEN // EVACUATION ORDER",
						"text": "A tremor starts rolling through the trench. Chen orders Thura back to the lander. The damaged suit can hold pressure for a little longer, but every minute outside risks a full seal failure.",
						"choices": [
							{"id": &"search_longer", "label": "Search Ruiz's last signal (risk suit oxygen and move slower)"},
							{"id": &"evacuate_now", "label": "Evacuate now (keep oxygen, leave the signal unrecovered)"},
						],
					},
				],
			}
	return {}


func _on_cutscene_finished(cutscene_id: StringName, choice_id: StringName) -> void:
	_cutscene_open = false
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()
	if cutscene_id == &"resonance_core_recovery":
		_feedback_text = "CORE STILL AT THE RIG  //  CLOSE THE CONSOLE AND ASK AMARA FOR A HEAVY HAULER"
		_feedback_timer = 6.0
	elif choice_id == &"search_longer":
		Engine.set_meta(SUIT_O2_DAMAGE_META_KEY, true)
		Engine.set_meta(&"ruiz_last_signal_recovered", true)
		player.move_speed *= 0.78
		_walk_hud.play_radio_transmission("MATEO RUIZ // RECOVERED FRAGMENT", "Thura, don't follow the lights. It's copying the beacon. I can hear it using— [SIGNAL LOST]")
		_feedback_text = "RUIZ'S LAST SIGNAL RECOVERED  //  SUIT O2 LEAKING; MOVEMENT SLOWED  //  BOARD SHIP"
		_feedback_timer = 5.5
	elif choice_id == &"evacuate_now":
		Engine.set_meta(&"ruiz_last_signal_recovered", false)
		_feedback_text = "OXYGEN SEAL HOLDS  //  RUIZ'S LAST SIGNAL LOST  //  BOARD ASTERIA-1"
		_feedback_timer = 5.5


func _board_ship() -> void:
	if _transitioning:
		return
	# Always allow a return to the ship. Story objectives remain pending when the
	# player leaves early, so they can resume the surface sequence on the next EVA.
	if _ore_sample_collected() and not _ore_sample_stored() and is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(ORE_RETURN_TASK_ID)
	if _echo_heard() and is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(ECHO_RETURN_TASK_ID)
	_save_planet_state()
	Engine.remove_meta(SUIT_O2_DAMAGE_META_KEY)
	_transitioning = true
	Engine.set_meta(&"returning_from_planet", true)
	get_tree().change_scene_to_file(SHIP_SCENE_PATH)


func _start_reflection() -> void:
	if _resting or _cutscene_open:
		return
	_resting = true
	_cutscene_open = true
	if is_instance_valid(_walk_hud):
		_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	player.set_physics_process(false)
	player.global_position = REST_POINT + Vector2(0.0, 14.0)
	player.face_toward(EXTRACTION_RIG_POSITION)
	player.sit_down()
	_reflection_text = "The quiet brings an old memory back..."
	_walk_hud.set_interaction_prompt(_reflection_text, true)
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	_walk_hud.set_interaction_prompt("", false)
	player.face_toward(REST_POINT + Vector2(-100.0, -30.0))
	var memory_cutscene := THADINGYUT_MEMORY_SCENE.instantiate() as ThadingyutMemoryCutscene
	add_child(memory_cutscene)
	await memory_cutscene.finished
	if not is_inside_tree():
		return
	_cutscene_open = false
	if is_instance_valid(_walk_hud):
		_walk_hud.set_walking_visible(true)
	_update_player_walk_state()
	player.face_toward(Vector2(310.0, 435.0))
	Engine.set_meta(&"resonance_ore_rest_complete", true)
	_walk_hud.set_task_completed(RIDGE_REST_TASK_ID)
	_walk_hud.add_task_entry(_ore_echo_task_entry())
	_reflection_text = "Amara gives no answer. Four slow pulses rise from the ore seam—the rhythm draws Thura back to the star he asked his mother about."
	_walk_hud.set_interaction_prompt(_reflection_text, true)
	await get_tree().create_timer(3.8).timeout
	if not is_inside_tree():
		return
	_resting = false
	_reflection_text = ""
	player.stand_up()
	player.set_physics_process(true)
	_feedback_text = "NO REPAIR ORDER FROM AMARA  //  ECHO COMING FROM THE ORE SEAM"
	_feedback_timer = 6.0
	_walk_hud.set_interaction_prompt("FOLLOW THE ECHO TO THE ORE SEAM", true)


func _emit_ore_echo_visual() -> void:
	var source: Vector2 = ORE_SITES[0]["position"]
	var echo_source := Node2D.new()
	echo_source.name = "ResonanceEchoPulse"
	echo_source.position = source
	echo_source.z_index = 6
	add_child(echo_source)
	_play_ore_echo_sound(echo_source)
	for wave_index in range(3):
		var ring := Line2D.new()
		ring.width = 2.0
		ring.default_color = Color(0.44, 0.91, 1.0, 0.76)
		ring.closed = true
		var points := PackedVector2Array()
		for point_index in range(33):
			var angle := TAU * float(point_index) / 32.0
			points.append(Vector2(cos(angle), sin(angle)) * 7.0)
		ring.points = points
		ring.scale = Vector2(0.2, 0.2)
		echo_source.add_child(ring)
		var pulse := create_tween().set_parallel(true)
		pulse.tween_property(ring, "scale", Vector2(7.0, 7.0), 1.55).set_delay(float(wave_index) * 0.42).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(ring, "modulate:a", 0.0, 1.45).set_delay(float(wave_index) * 0.42).set_trans(Tween.TRANS_SINE)
	var cleanup := create_tween()
	cleanup.tween_interval(ORE_ECHO_DURATION + 0.2)
	cleanup.tween_callback(echo_source.queue_free)


func _play_ore_echo_sound(parent: Node2D) -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = ORE_ECHO_SAMPLE_RATE
	generator.buffer_length = ORE_ECHO_DURATION + 0.25
	var echo_sound := AudioStreamPlayer2D.new()
	echo_sound.name = "DistantOreEcho"
	echo_sound.stream = generator
	echo_sound.volume_db = -3.0
	echo_sound.max_distance = 1400.0
	parent.add_child(echo_sound)
	echo_sound.play()
	var playback := echo_sound.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frame_count: int = int(ORE_ECHO_SAMPLE_RATE * ORE_ECHO_DURATION)
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	var taps := [Vector2(0.0, 1.0), Vector2(0.48, 0.48), Vector2(1.03, 0.24), Vector2(1.66, 0.12)]
	for frame_index in range(frame_count):
		var time: float = float(frame_index) / ORE_ECHO_SAMPLE_RATE
		var signal_value: float = 0.0
		for tap in taps:
			var local_time: float = time - tap.x
			if local_time < 0.0:
				continue
			var envelope: float = exp(-2.55 * local_time) * minf(local_time / 0.035, 1.0)
			var frequency: float = 78.0 + 7.0 * sin(local_time * 2.1)
			var metallic: float = sin(TAU * frequency * local_time)
			metallic += 0.38 * sin(TAU * frequency * 2.41 * local_time + 0.6)
			metallic += 0.16 * sin(TAU * frequency * 3.08 * local_time + 1.1)
			signal_value += tap.y * envelope * metallic
		var sample: float = clampf(signal_value * 0.22, -1.0, 1.0)
		frames[frame_index] = Vector2(sample, sample)
	playback.push_buffer(frames)


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_hud_modal_open or _cutscene_open or _resting))


func _add_black_space_backdrop() -> void:
	var background_layer := CanvasLayer.new()
	background_layer.name = "BlackSpaceBackdrop"
	background_layer.layer = -10
	var black_space := ColorRect.new()
	black_space.name = "Space"
	black_space.color = Color.BLACK
	black_space.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(black_space)
	add_child(background_layer)
