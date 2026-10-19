@tool
extends Node2D

const SHIP_SCENE_PATH := "res://scenes/ship/bare_ship_walkthrough.tscn"
const PLANET_TEXTURE_PATH := "res://art/planet/mock_planet_surface.png"
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")

const ORE_SITES := [
	{
		"id": &"west_cyan_ore",
		"title": "Sample west cyan crystal vein",
		"marker_label": "CYAN ORE",
		"position": Vector2(420.0, 420.0),
		"prompt": "CRYSTALLINE CYAN ORE VEIN   /   [E] EXTRACT SAMPLE",
		"completion": "Cyan crystal core logged. High resonance readings detected.",
	},
	{
		"id": &"north_viridian_ore",
		"title": "Scan north crater resonance core",
		"marker_label": "CORE VEIN",
		"position": Vector2(800.0, 320.0),
		"prompt": "VIRIDIAN RESONANCE VEIN   /   [E] SCAN ECHO",
		"completion": "Subsurface harmonic echo recorded from the northern crater.",
	},
	{
		"id": &"east_amber_ore",
		"title": "Collect east amber silicate sample",
		"marker_label": "AMBER ORE",
		"position": Vector2(1180.0, 440.0),
		"prompt": "AMBER SILICATE OUTCROP   /   [E] COLLECT SAMPLE",
		"completion": "Heavy amber ore sample stored in suit containment.",
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
var _feedback_text := "EXITED ASTERIA-1  //  VESPERA-IV SURFACE LANDING ZONE"
var _feedback_timer := 4.0
var _transitioning := false


func _ready() -> void:
	var planet_img := Image.load_from_file(ProjectSettings.globalize_path(PLANET_TEXTURE_PATH))
	if planet_img != null and not planet_img.is_empty():
		surface_layer.texture = ImageTexture.create_from_image(planet_img)
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
		if absf(player.global_position.x - AIRLOCK_ENTRY_POS.x) <= 46.0 and player.global_position.y >= 736.0 and Input.is_action_pressed(&"move_down"):
			_board_ship()
			return

	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _hud_modal_open or not event.is_action_pressed(&"interact"):
		return
	if _near_ship_airlock:
		get_viewport().set_input_as_handled()
		_board_ship()
	elif _active_ore_id != &"":
		get_viewport().set_input_as_handled()
		_sample_ore(_active_ore_id)


func _refresh_prompt() -> void:
	_near_ship_airlock = false
	_active_ore_id = &""
	if _hud_modal_open:
		_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(AIRLOCK_ENTRY_POS) <= AIRLOCK_INTERACT_RADIUS:
		_near_ship_airlock = true
		_walk_hud.set_interaction_prompt("ASTERIA-1 EXTERIOR AIRLOCK   /   [E] ENTER SHIP", true)
		return

	for site in ORE_SITES:
		var site_id: StringName = site["id"]
		if _sampled_sites.has(site_id):
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
	if _sampled_sites.has(site_id):
		return
	var completion := "Ore sample logged."
	for site in ORE_SITES:
		if site["id"] == site_id:
			completion = site["completion"]
			break
	_sampled_sites[site_id] = true
	_walk_hud.set_task_completed(site_id)
	_feedback_text = "%s\nSURFACE SAMPLES  %d / %d COMPLETE" % [completion, _sampled_sites.size(), ORE_SITES.size()]
	_feedback_timer = 4.0


func _board_ship() -> void:
	if _transitioning:
		return
	_transitioning = true
	Engine.set_meta(&"returning_from_planet", true)
	get_tree().change_scene_to_file(SHIP_SCENE_PATH)


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	player.set_physics_process(not _hud_modal_open)
