@tool
extends Node2D

const SHIP_SCENE_PATH := "res://scenes/ship/bare_ship_walkthrough.tscn"
const EREBOS_SURFACE := preload("res://art/planet/erebos_extraction_surface_v2.png")
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")
const THADINGYUT_MEMORY_SCENE := preload("res://scenes/ui/thadingyut_memory_cutscene.tscn")
const ORE_ECHO_SAMPLE_RATE := 22050.0
const ORE_ECHO_DURATION := 3.2
const ORE_EXTRACTION_CONSOLE := preload("res://scripts/ui/ore_extraction_console.gd")
const EXTRACTION_RIG_TASK_ID := &"erebos_rig_test"
const RIG_REPORT_TASK_ID := &"report_failed_rig"
const ORE_RETURN_TASK_ID := &"return_ore_to_amara"
const RIDGE_REST_TASK_ID := &"remember_at_ridge_stone"
const ORE_ECHO_TASK_ID := &"trace_ore_echo"
const ECHO_RETURN_TASK_ID := &"return_after_ore_echo"
const EXTRACTION_RIG_POSITION := Vector2(1060.0, 520.0)
const EXTRACTION_RIG := {
	"id": &"erebos_extraction_rig",
	"marker_label": "EREBOS RIG",
	"machine": "CENTRAL RESONANCE CORE DRILL",
	"depth_m": 58,
	"pressure_mpa": "2.1",
	"test_only": true,
}
const ORE_SITES := [
	{
		"id": &"west_ore_cut",
		"title": "Collect a sample from the western ore seam",
		"marker_label": "ORE SEAM",
		"position": Vector2(310.0, 435.0),
		"marker_position": Vector2(220.0, 336.0),
		"completion": "Thura gathers a sample from the exposed resonance seam.",
	},
]

const AIRLOCK_ENTRY_POS := Vector2(800.0, 748.0)
const AIRLOCK_INTERACT_RADIUS := 88.0
const ORE_INTERACT_RADIUS := 140.0
const REST_POINT := Vector2(1060.0, 610.0)
const REST_INTERACT_RADIUS := 78.0

@onready var surface_layer: Sprite2D = $PlanetSurface
@onready var airlock_gate: Node2D = $LandedShipHull/ExteriorAirlockGate
@onready var player: ShipPlayer = $Player

var _walk_hud: WalkHud
var _extraction_console: OreExtractionConsole
var _hud_modal_open := false
var _explored_sites: Dictionary = {}
var _active_ore_id: StringName = &""
var _near_rest_point := false
var _near_echo_site := false
var _near_extraction_rig := false
var _resting := false
var _reflection_text := ""
var _near_ship_airlock := false
var _feedback_text := "EXITED ASTERIA-1  //  EREBOS EXPLORATION ZONE"
var _feedback_timer := 4.0
var _transitioning := false


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
		"position": EXTRACTION_RIG_POSITION,
		"marker_position": EXTRACTION_RIG_POSITION + Vector2(0.0, -36.0),
	}


func _ore_discovery_task_entry() -> Dictionary:
	var site: Dictionary = ORE_SITES[0]
	return {
		"id": site["id"],
		"title": site["title"],
		"marker_label": site["marker_label"],
		"position": site["position"],
		"marker_position": site["marker_position"],
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
		"title": "Sit by the extraction rig and wait for instructions",
		"marker_label": "EXTRACTION RIG",
		"position": REST_POINT,
		"marker_position": REST_POINT + Vector2(0.0, -42.0),
	}


func _rig_report_task_entry() -> Dictionary:
	return {
		"id": RIG_REPORT_TASK_ID,
		"title": "Return to Asteria-1 and report the rig failure",
		"marker_label": "REPORT TO AMARA",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ore_return_task_entry() -> Dictionary:
	return {
		"id": ORE_RETURN_TASK_ID,
		"title": "Return the ore sample to Dr. Okoye",
		"marker_label": "RETURN WITH ORE",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ore_echo_task_entry() -> Dictionary:
	var site: Dictionary = ORE_SITES[0]
	return {
		"id": ORE_ECHO_TASK_ID,
		"title": "Follow the echo to the ore seam",
		"marker_label": "ECHO SOURCE",
		"position": site["position"],
		"marker_position": site["marker_position"],
	}


func _echo_return_task_entry() -> Dictionary:
	return {
		"id": ECHO_RETURN_TASK_ID,
		"title": "Follow the echo back to Asteria-1",
		"marker_label": "RETURN TO SHIP",
		"position": AIRLOCK_ENTRY_POS,
		"marker_position": AIRLOCK_ENTRY_POS + Vector2(0.0, -46.0),
	}


func _ready() -> void:
	surface_layer.texture = EREBOS_SURFACE
	surface_layer.scale = Vector2(1600.0 / float(EREBOS_SURFACE.get_width()), 1000.0 / float(EREBOS_SURFACE.get_height()))
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	_add_black_space_backdrop()

	# Build walkable mask for the planet surface (y >= 205 is walkable terrain)
	var mask_img := Image.create(1600, 1000, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 0))
	mask_img.fill_rect(Rect2i(64, 205, 1472, 725), Color(1, 1, 1, 1))
	# Block the solid hull body behind the airlock threshold (y > 768 around x=520..1080)
	mask_img.fill_rect(Rect2i(520, 768, 560, 220), Color(0, 0, 0, 0))
	var mask_tex := ImageTexture.create_from_image(mask_img)
	player.set_walkable_floor_mask(mask_tex, Vector2.ZERO, 8.0)
	player.set_walkable_blocker_polygons(_make_terrain_blockers())
	player.camera.zoom = Vector2(0.72, 0.72)
	player.set_camera_bounds(Rect2(Vector2.ZERO, Vector2(1600.0, 1000.0)))
	player.global_position = Vector2(800.0, 684.0)
	player.camera.make_current()
	player.camera.reset_smoothing()
	if _ore_sample_collected():
		for site in ORE_SITES:
			_explored_sites[site["id"]] = true

	var hud_tasks: Array[Dictionary] = []
	hud_tasks.append(_rig_test_task_entry())
	if _rig_test_failed() and not _rig_failure_reported():
		hud_tasks.append(_rig_report_task_entry())
	elif _rig_test_failed() and not _ore_sample_collected():
		hud_tasks.append(_ore_discovery_task_entry())
	if _ore_sample_collected() and not _ore_sample_stored():
		hud_tasks.append(_ore_return_task_entry())
	if _ore_sample_stored() and not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
		hud_tasks.append(_ridge_rest_task_entry())
	if Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete")) and not _echo_heard():
		hud_tasks.append(_ore_echo_task_entry())
	if _echo_heard():
		hud_tasks.append(_echo_return_task_entry())
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
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_walk_hud.set_walking_visible(true)


func _process(delta: float) -> void:
	if _transitioning:
		return
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(_feedback_timer - delta, 0.0)
		if is_zero_approx(_feedback_timer):
			_feedback_text = ""

	# Check walk-in re-entry through the huge open ship airlock door
	if is_instance_valid(airlock_gate) and airlock_gate.has_method("is_open") and bool(airlock_gate.call("is_open")):
		if absf(player.global_position.x - AIRLOCK_ENTRY_POS.x) <= 46.0 and player.global_position.y >= 736.0 and Input.is_action_just_pressed(&"move_down"):
			_board_ship()
			return

	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _resting or _hud_modal_open or not event.is_action_pressed(&"interact"):
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
	if _hud_modal_open:
		_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(AIRLOCK_ENTRY_POS) <= AIRLOCK_INTERACT_RADIUS:
		_near_ship_airlock = true
		var return_prompt := "TEST THE EXTRACTION RIG BEFORE LEAVING"
		if _rig_test_failed() and not _rig_failure_reported():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] REPORT THE FAILED RIG"
		elif _rig_test_failed() and not _ore_sample_collected():
			return_prompt = "COLLECT AN ORE SAMPLE BEFORE RETURNING"
		elif _ore_sample_collected() and not _ore_sample_stored():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] RETURN WITH ORE SAMPLE"
		elif _ore_sample_stored() and not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
			return_prompt = "SIT BY THE EXTRACTION RIG AND WAIT FOR AMARA'S INSTRUCTIONS"
		elif Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete")) and not _echo_heard():
			return_prompt = "FOLLOW THE ECHO TO THE ORE SEAM"
		elif _echo_heard():
			return_prompt = "ASTERIA-1 AIRLOCK   /   [E] FOLLOW THE ECHO BACK TO THE LAB"
		_walk_hud.set_interaction_prompt(return_prompt, true)
		return
	var reflection_complete := Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))
	if _ore_sample_stored() and not reflection_complete and player.global_position.distance_to(REST_POINT) <= REST_INTERACT_RADIUS:
		_near_rest_point = true
		_walk_hud.set_interaction_prompt("EXTRACTION RIG   /   [E] SIT AND WAIT FOR AMARA", true)
		return
	if reflection_complete and not _echo_heard() and player.global_position.distance_to(ORE_SITES[0]["position"]) <= ORE_INTERACT_RADIUS:
		_near_echo_site = true
		_walk_hud.set_interaction_prompt("ORE SEAM   /   [E] LISTEN TO THE ECHO", true)
		return
	if not _rig_test_failed() and player.global_position.distance_to(EXTRACTION_RIG_POSITION) <= 86.0:
		_near_extraction_rig = true
		_walk_hud.set_interaction_prompt("ORE EXTRACTION RIG   /   [E] RUN MACHINE TEST", true)
		return

	if _rig_test_failed() and _rig_failure_reported() and not _ore_sample_collected():
		for site in ORE_SITES:
			var site_id: StringName = site["id"]
			if _explored_sites.has(site_id):
				continue
			var pos: Vector2 = site["position"]
			if player.global_position.distance_to(pos) <= ORE_INTERACT_RADIUS:
				_active_ore_id = site_id
				_walk_hud.set_interaction_prompt("BLUE ORE SEAM   /   [E] COLLECT SAMPLE", true)
				return

	if _feedback_timer > 0.0 and not _feedback_text.is_empty():
		_walk_hud.set_interaction_prompt(_feedback_text, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _collect_ore_sample(site_id: StringName) -> void:
	if _explored_sites.has(site_id) or not _rig_test_failed() or not _rig_failure_reported():
		return
	var completion := "Thura gathers a resonance ore sample from the exposed seam."
	for site in ORE_SITES:
		if site["id"] == site_id:
			completion = site["completion"]
			break
	_explored_sites[site_id] = true
	Engine.set_meta(&"resonance_ore_seam_discovered", true)
	Engine.set_meta(&"resonance_ore_sample_collected", true)
	_walk_hud.set_task_completed(site_id)
	_walk_hud.add_task_entry(_ore_return_task_entry())
	_walk_hud.grant_hotbar_item(&"resonance_ore_sample")
	_feedback_text = "%s\nSAMPLE SECURED  //  RETURN TO DR. OKOYE" % completion
	_feedback_timer = 5.0


func _listen_for_ore_echo() -> void:
	if _echo_heard() or not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
		return
	Engine.set_meta(&"resonance_echo_heard", true)
	_emit_ore_echo_visual()
	_walk_hud.set_task_completed(ORE_ECHO_TASK_ID)
	_walk_hud.add_task_entry(_echo_return_task_entry())
	_feedback_text = "THE ORE SEAM ANSWERS  //  SOMETHING IS WRONG ON ASTERIA-1"
	_feedback_timer = 6.0


func _open_extraction_console() -> void:
	if _rig_test_failed():
		return
	_extraction_console = ORE_EXTRACTION_CONSOLE.new() as OreExtractionConsole
	add_child(_extraction_console)
	_extraction_console.machine_test_failed.connect(_on_machine_test_failed)
	_extraction_console.modal_state_changed.connect(_on_extraction_console_modal_state_changed)
	_extraction_console.open(EXTRACTION_RIG)


func _on_machine_test_failed(_site_id: StringName) -> void:
	Engine.set_meta(&"erebos_rig_test_failed", true)
	if is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(EXTRACTION_RIG_TASK_ID)
		_walk_hud.add_task_entry(_rig_report_task_entry())
	_feedback_text = "DRILL TEST FAILED  //  REPORT TO DR. OKOYE ABOARD ASTERIA-1"
	_feedback_timer = 6.0


func _on_extraction_console_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	player.set_physics_process(not is_open)
	if not is_open:
		_extraction_console = null
		_refresh_prompt()


func _board_ship() -> void:
	if _transitioning:
		return
	if not _rig_test_failed():
		_feedback_text = "TEST THE EXTRACTION RIG BEFORE LEAVING"
		_feedback_timer = 4.0
		return
	if not _rig_failure_reported():
		if is_instance_valid(_walk_hud):
			_walk_hud.set_task_completed(RIG_REPORT_TASK_ID)
	elif not _ore_sample_collected():
		_feedback_text = "COLLECT THE RESONANCE ORE SAMPLE FOR DR. OKOYE"
		_feedback_timer = 4.0
		return
	if _ore_sample_collected() and not _ore_sample_stored() and is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(ORE_RETURN_TASK_ID)
	if _ore_sample_stored() and not (Engine.has_meta(&"resonance_ore_rest_complete") and bool(Engine.get_meta(&"resonance_ore_rest_complete"))):
		_feedback_text = "SIT BY THE EXTRACTION RIG AND WAIT FOR AMARA'S INSTRUCTIONS"
		_feedback_timer = 4.0
		return
	if _ore_sample_stored() and not _echo_heard():
		_feedback_text = "FOLLOW THE ECHO TO THE ORE SEAM BEFORE RETURNING"
		_feedback_timer = 4.0
		return
	if _echo_heard() and is_instance_valid(_walk_hud):
		_walk_hud.set_task_completed(ECHO_RETURN_TASK_ID)
	_transitioning = true
	Engine.set_meta(&"returning_from_planet", true)
	get_tree().change_scene_to_file(SHIP_SCENE_PATH)


func _start_reflection() -> void:
	if _resting:
		return
	_resting = true
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
	player.face_toward(Vector2(310.0, 435.0))
	Engine.set_meta(&"resonance_ore_rest_complete", true)
	_walk_hud.set_task_completed(RIDGE_REST_TASK_ID)
	_walk_hud.add_task_entry(_ore_echo_task_entry())
	_reflection_text = "No instruction comes from Amara. A faint echo answers from the ore seam where you found the sample."
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
	var frame_count := int(ORE_ECHO_SAMPLE_RATE * ORE_ECHO_DURATION)
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	var taps := [Vector2(0.0, 1.0), Vector2(0.48, 0.48), Vector2(1.03, 0.24), Vector2(1.66, 0.12)]
	for frame_index in range(frame_count):
		var time := float(frame_index) / ORE_ECHO_SAMPLE_RATE
		var signal_value := 0.0
		for tap in taps:
			var local_time: float = time - tap.x
			if local_time < 0.0:
				continue
			var envelope := exp(-2.55 * local_time) * minf(local_time / 0.035, 1.0)
			var frequency := 78.0 + 7.0 * sin(local_time * 2.1)
			var metallic := sin(TAU * frequency * local_time)
			metallic += 0.38 * sin(TAU * frequency * 2.41 * local_time + 0.6)
			metallic += 0.16 * sin(TAU * frequency * 3.08 * local_time + 1.1)
			signal_value += tap.y * envelope * metallic
		var sample := clampf(signal_value * 0.22, -1.0, 1.0)
		frames[frame_index] = Vector2(sample, sample)
	playback.push_buffer(frames)


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	player.set_physics_process(not _hud_modal_open)


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
