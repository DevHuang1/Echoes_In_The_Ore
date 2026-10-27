@tool
extends Node2D

const SHIP_SCENE_PATH := "res://scenes/ship/bare_ship_walkthrough.tscn"
const EREBOS_SURFACE := preload("res://art/planet/erebos_extraction_surface.png")
const ORE_EXTRACTION_CONSOLE := preload("res://scripts/ui/ore_extraction_console.gd")
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")

const ORE_SITES := [
	{
		"id": &"west_ore_cut",
		"title": "Extract ore from the western cut",
		"marker_label": "WEST CUT",
		"position": Vector2(420.0, 420.0),
		"machine": "WESTERN CORE DRILL",
		"depth_m": 42,
		"pressure_mpa": "1.8",
		"prompt": "WESTERN DRILL FACE   /   [E] EXTRACT CORE SAMPLE",
		"completion": "Western cut sampled. Mineral seam continues below the surface.",
	},
	{
		"id": &"north_ore_ridge",
		"title": "Drill the northern ridge seam",
		"marker_label": "NORTH RIDGE",
		"position": Vector2(800.0, 320.0),
		"machine": "NORTH RIDGE BORER",
		"depth_m": 67,
		"pressure_mpa": "2.3",
		"prompt": "NORTHERN BORING STATION   /   [E] EXTRACT CORE SAMPLE",
		"completion": "North ridge sample secured. Resonance remains stable.",
	},
	{
		"id": &"east_ore_face",
		"title": "Sample the eastern drill face",
		"marker_label": "EASTERN FACE",
		"position": Vector2(1180.0, 440.0),
		"machine": "EASTERN CUTTER RIG",
		"depth_m": 51,
		"pressure_mpa": "1.9",
		"prompt": "EASTERN EXCAVATION   /   [E] EXTRACT CORE SAMPLE",
		"completion": "Eastern drill sample stored in suit containment.",
	},
]

const AIRLOCK_ENTRY_POS := Vector2(800.0, 748.0)
const AIRLOCK_INTERACT_RADIUS := 88.0
const ORE_INTERACT_RADIUS := 74.0

@onready var surface_layer: Sprite2D = $PlanetSurface
@onready var airlock_gate: Node2D = $LandedShipHull/ExteriorAirlockGate
@onready var player: ShipPlayer = $Player

var _walk_hud: WalkHud
var _hud_modal_open := false
var _sampled_sites: Dictionary = {}
var _active_ore_id: StringName = &""
var _near_ship_airlock := false
var _feedback_text := "EXITED ASTERIA-1  //  EREBOS MINING ZONE"
var _feedback_timer := 4.0
var _transitioning := false


func _ready() -> void:
	surface_layer.texture = EREBOS_SURFACE
	surface_layer.scale = Vector2(1600.0 / float(EREBOS_SURFACE.get_width()), 1000.0 / float(EREBOS_SURFACE.get_height()))
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	# Build walkable mask for the planet surface (y >= 205 is walkable terrain)
	var mask_img := Image.create(1600, 1000, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 0))
	mask_img.fill_rect(Rect2i(64, 205, 1472, 725), Color(1, 1, 1, 1))
	# Block the solid hull body behind the airlock threshold (y > 768 around x=520..1080)
	mask_img.fill_rect(Rect2i(520, 768, 560, 220), Color(0, 0, 0, 0))
	var mask_tex := ImageTexture.create_from_image(mask_img)
	player.set_walkable_floor_mask(mask_tex, Vector2.ZERO, 8.0)
	player.set_camera_bounds(Rect2(Vector2.ZERO, Vector2(1600.0, 1000.0)))
	player.global_position = Vector2(800.0, 684.0)
	player.camera.make_current()
	player.camera.reset_smoothing()

	var hud_tasks: Array[Dictionary] = []
	for site in ORE_SITES:
		hud_tasks.append({
			"id": site["id"],
			"title": site["title"],
			"marker_label": site["marker_label"],
			"position": site["position"],
			"marker_position": site["position"] + Vector2(0.0, -34.0),
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_tasks, Vector2.ZERO, Vector2(1600.0, 1000.0))
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
	if _transitioning or _hud_modal_open or not event.is_action_pressed(&"interact"):
		return
	if _near_ship_airlock:
		get_viewport().set_input_as_handled()
		if _sampled_sites.size() >= ORE_SITES.size():
			_board_ship()
		else:
			_feedback_text = "EXTRACTION INCOMPLETE  //  VISIT EACH MINING RIG"
			_feedback_timer = 3.5
	elif _active_ore_id != &"":
		get_viewport().set_input_as_handled()
		_open_extraction_console(_active_ore_id)


func _refresh_prompt() -> void:
	_near_ship_airlock = false
	_active_ore_id = &""
	if _hud_modal_open:
		_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(AIRLOCK_ENTRY_POS) <= AIRLOCK_INTERACT_RADIUS:
		_near_ship_airlock = true
		var return_prompt := "ASTERIA-1 AIRLOCK   /   [E] RETURN WITH CORE SAMPLES" if _sampled_sites.size() >= ORE_SITES.size() else "ASTERIA-1 AIRLOCK   /   EXTRACT ALL CORE SAMPLES FIRST"
		_walk_hud.set_interaction_prompt(return_prompt, true)
		return

	for site in ORE_SITES:
		var site_id: StringName = site["id"]
		if _sampled_sites.has(site_id):
			continue
		var pos: Vector2 = site["position"]
		if player.global_position.distance_to(pos) <= ORE_INTERACT_RADIUS:
			_active_ore_id = site_id
			_walk_hud.set_interaction_prompt("%s   /   [E] OPEN MACHINE CONSOLE" % str(site.get("machine", "MINING RIG")), true)
			return

	if _feedback_timer > 0.0 and not _feedback_text.is_empty():
		_walk_hud.set_interaction_prompt(_feedback_text, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _sample_ore(site_id: StringName) -> void:
	if _sampled_sites.has(site_id):
		return
	var completion := "Ore sample logged."
	for site in ORE_SITES:
		if site["id"] == site_id:
			completion = site["completion"]
			break
	_sampled_sites[site_id] = true
	_walk_hud.set_task_completed(site_id)
	if _sampled_sites.size() >= ORE_SITES.size():
		Engine.set_meta(&"resonance_ore_sample_collected", true)
		if is_instance_valid(_walk_hud) and _walk_hud.has_method("grant_hotbar_item"):
			_walk_hud.grant_hotbar_item(&"resonance_ore_sample")
		_feedback_text = "ORE EXTRACTION COMPLETE // CORE SAMPLE ADDED TO SUIT CONTAINMENT"
	else:
		_feedback_text = "%s\nSURFACE SAMPLES  %d / %d COMPLETE" % [completion, _sampled_sites.size(), ORE_SITES.size()]
	_feedback_timer = 4.0


func _open_extraction_console(site_id: StringName) -> void:
	for site in ORE_SITES:
		if site["id"] != site_id:
			continue
		var console := ORE_EXTRACTION_CONSOLE.new() as OreExtractionConsole
		console.extraction_completed.connect(_on_ore_extraction_completed)
		console.modal_state_changed.connect(_on_extraction_console_modal_changed)
		add_child(console)
		console.open(site)
		_walk_hud.set_walking_visible(false)
		return


func _on_ore_extraction_completed(site_id: StringName) -> void:
	_sample_ore(site_id)


func _on_extraction_console_modal_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	player.set_physics_process(not is_open)
	if not is_open and is_instance_valid(_walk_hud):
		_walk_hud.set_walking_visible(true)


func _board_ship() -> void:
	if _transitioning:
		return
	if _sampled_sites.size() < ORE_SITES.size():
		_feedback_text = "EXTRACTION INCOMPLETE  //  VISIT EACH MINING RIG"
		_feedback_timer = 3.5
		return
	_transitioning = true
	Engine.set_meta(&"returning_from_planet", true)
	get_tree().change_scene_to_file(SHIP_SCENE_PATH)


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	player.set_physics_process(not _hud_modal_open)
