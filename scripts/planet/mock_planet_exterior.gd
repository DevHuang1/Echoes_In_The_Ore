@tool
extends Node2D

const SHIP_SCENE_PATH: String = "res://scenes/ship/bare_ship_walkthrough.tscn"
const PLANET_TEXTURE_PATH: String = "res://art/planet/mock_planet_surface.png"
const WALK_HUD_SCENE: PackedScene = preload("res://scenes/ui/walk_hud.tscn")
const STORY_CUTSCENE_SCRIPT: Script = preload("res://scripts/ui/story_cutscene_overlay.gd")
const STORY_STATE_META_KEY: StringName = &"echoes_story_progression_state"

# Equipment on Erebos requires multi-site progression rather than instant 1st-node handouts
const ORE_SITES: Array[Dictionary] = [
	{
		"id": &"west_cyan_ore",
		"title": "Strike hollow crystals (Site 1/2 -> Flare & Cutter)",
		"marker_label": "SITE K-12 W",
		"position": Vector2(420.0, 420.0),
		"prompt": "HOLLOW MINERAL FORMATION   /   [E] STRIKE & TEST RESONANCE",
		"completion": "4-pulse crystal resonance logged (1/2 surface checks complete — inspect the Main Drill Breach next).",
		"reward_item": &"",
		"log_id": &"log_okoye_crystals",
	},
	{
		"id": &"north_viridian_ore",
		"title": "Inspect drill breach (Unlocks Flare & Plasma Cutter)",
		"marker_label": "THE BREACH",
		"position": Vector2(800.0, 320.0),
		"prompt": "SUBSURFACE DRILL CAVITY   /   [E] INSPECT BREACH & DRILL RIG",
		"completion": "Drill breach logged (2/2 surface checks): Recovered Emergency Flare & Industrial Plasma Cutter!",
		"reward_item": &"industrial_plasma_cutter",
		"log_id": &"log_ruiz_breach",
	},
	{
		"id": &"east_amber_ore",
		"title": "Search collapsed trench for Ruiz & Okoye",
		"marker_label": "RUIZ / OKOYE",
		"position": Vector2(1180.0, 440.0),
		"prompt": "SHATTERED HELMET & COLLAPSED TRENCH   /   [E] SEARCH FOR CREW",
		"completion": "Ruiz and Okoye lost in excavation collapse. Evacuate to Asteria-1 airlock!",
		"reward_item": &"",
		"log_id": &"log_suit_fragment",
	},
]

const AIRLOCK_ENTRY_POS: Vector2 = Vector2(800.0, 748.0)
const AIRLOCK_INTERACT_RADIUS: float = 88.0
const ORE_INTERACT_RADIUS: float = 74.0

@onready var surface_layer: Sprite2D = $PlanetSurface
@onready var airlock_gate: Node2D = $LandedShipHull/ExteriorAirlockGate
@onready var player: ShipPlayer = $Player

var _walk_hud: WalkHud = null
var _story_cutscene: CanvasLayer = null
var _hud_modal_open: bool = false
var _cutscene_open: bool = false
var _sampled_sites: Dictionary = {}
var _active_ore_id: StringName = &""
var _near_ship_airlock: bool = false
var _feedback_text: String = "ACT II: EREBOS (SITE K-12)  //  INVESTIGATE FORMATIONS & DRILL SITE"
var _feedback_timer: float = 4.5
var _transitioning: bool = false


func _ready() -> void:
	var planet_img: Image = Image.load_from_file(ProjectSettings.globalize_path(PLANET_TEXTURE_PATH))
	if planet_img != null and not planet_img.is_empty():
		surface_layer.texture = ImageTexture.create_from_image(planet_img)
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	if Engine.has_meta(STORY_STATE_META_KEY):
		var st: Dictionary = Engine.get_meta(STORY_STATE_META_KEY)
		_sampled_sites = st.get("sampled_planet_sites", {}).duplicate()

	var mask_img: Image = Image.create(1600, 1000, false, Image.FORMAT_RGBA8)
	mask_img.fill(Color(0, 0, 0, 0))
	mask_img.fill_rect(Rect2i(64, 205, 1472, 725), Color(1, 1, 1, 1))
	mask_img.fill_rect(Rect2i(520, 768, 560, 220), Color(0, 0, 0, 0))
	var mask_tex: ImageTexture = ImageTexture.create_from_image(mask_img)
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
			"reward_item": site.get("reward_item", &""),
			"is_equipment_task": StringName(site.get("reward_item", &"")) != &"",
			"position": site["position"],
			"marker_position": site["position"] + Vector2(0.0, -28.0),
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_tasks, Vector2.ZERO, Vector2(1600.0, 1000.0))
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_walk_hud.set_story_act_label("ACT II — EREBOS (SITE K-12)")
	for done_site in _sampled_sites:
		_walk_hud.set_task_completed(StringName(done_site), true)
	_walk_hud.set_walking_visible(true)

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

	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _hud_modal_open or _cutscene_open or not event.is_action_pressed(&"interact"):
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
	if _hud_modal_open or _cutscene_open:
		_walk_hud.set_interaction_prompt("", false)
		return

	if player.global_position.distance_to(AIRLOCK_ENTRY_POS) <= AIRLOCK_INTERACT_RADIUS:
		_near_ship_airlock = true
		_walk_hud.set_interaction_prompt("ASTERIA-1 EXTERIOR AIRLOCK   /   [E] EVACUATE TO SHIP", true)
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
	var completion: String = "Ore sample logged."
	var log_id: StringName = &""
	for site in ORE_SITES:
		if site["id"] == site_id:
			completion = str(site["completion"])
			log_id = site.get("log_id", &"")
			break
	_sampled_sites[site_id] = true
	_walk_hud.set_task_completed(site_id)
	if log_id != &"":
		_walk_hud.record_audio_log(log_id)

	# Unlock Emergency Flare & Industrial Plasma Cutter only after at least 2 surface sites are investigated!
	if _sampled_sites.size() >= 2:
		if not _walk_hud.has_equipment_item(&"emergency_flare"):
			_walk_hud.unlock_equipment_item(&"emergency_flare", false, "Erebos Surface Milestone (2 Sites): Emergency Flare unlocked!")
		if _sampled_sites.has(&"north_viridian_ore") and not _walk_hud.has_equipment_item(&"industrial_plasma_cutter"):
			_walk_hud.unlock_equipment_item(&"industrial_plasma_cutter", true, "Erebos Drill Breach Milestone: Recovered Ruiz's Industrial Plasma Cutter!")

	_save_planet_state()
	_feedback_text = "%s\nEREBOS SITE K-12  %d / %d COMPLETE" % [completion, _sampled_sites.size(), ORE_SITES.size()]
	_feedback_timer = 4.5

	var cutscene_data: Dictionary = _build_planet_cutscene(site_id)
	if not cutscene_data.is_empty() and is_instance_valid(_story_cutscene):
		_cutscene_open = true
		_walk_hud.set_walking_visible(false)
		_update_player_walk_state()
		_story_cutscene.call(&"play_cutscene", site_id, cutscene_data)


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
						"text": "Erebos is silent except for radio chatter and vibrations travelling through the low-gravity regolith. When Thura strikes the glass-like mineral formation, it rings hollow — producing the exact four-pulse, seven-second pause pattern detected from orbit.",
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
				"reward": {
					"name": "Industrial Plasma Cutter & Emergency Flare",
					"desc": "Surface Milestone Complete: Recovered Ruiz's Industrial Plasma Cutter & Emergency Flares!",
					"texture": load("res://art/tools/icons/industrial_plasma_cutter.png"),
				},
				"slides": [
					{
						"speaker": "DRILL CAMERA FEED // SUBSURFACE CAVITY",
						"text": "The autonomous drill breaks through into a massive hollow chamber beneath Erebos. Instead of solid metal, the camera reveals black, reflective structures resembling mineral ribs surrounding a central mass.\n\nThe four-pulse signal stops. For several seconds, there is complete silence. Then the drilling rig loses all power.",
					},
					{
						"speaker": "MATEO RUIZ // SUIT TELEMETRY",
						"text": "Ruiz goes out manually to restart the drill. His suit camera catches a thin black substance moving against the direction of gravity.\n\nHis radio cuts out. Over the channel, the crew hears Ruiz breathing heavily, followed by a sharp metallic impact. His tracking signal begins moving underground at impossible speed!\n\n[Thura recovers the heavy Industrial Plasma Cutter and Emergency Flare kit beside the stalled rig as Commander Chen orders an immediate search at the eastern trench.]",
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
						"speaker": "DR. THURA MIN & DR. AMARA OKOYE // EXCAVATION SITE",
						"text": "Near the eastern crater trench, Thura and Okoye find Ruiz's damaged helmet — but no body. The reinforced visor is shattered outward, as though something escaped from inside it.\n\nA violent tremor collapses the ridge, separating Okoye from Thura!",
					},
					{
						"speaker": "DR. AMARA OKOYE // LAST RADIO TRANSMISSION (LOG 7/8)",
						"text": "Through the static, Thura hears Okoye calling for help:\n\nOKOYE: \"Thura, I found him.\"\nTHURA: \"Is Ruiz alive?\"\n\nThere is a long pause.\n\nOKOYE: \"Something is using his suit.\"\n[Her transmission ends.]",
					},
					{
						"speaker": "COMMANDER MAYA CHEN // EVACUATION ORDER",
						"text": "Another tremor destabilizes Site K-12. Commander Chen orders Thura back to the lander immediately. Before liftoff, the mining rig automatically seals its final black drill core inside a reinforced sample container...",
						"choices": [
							{"id": &"search_longer", "label": "Resist order & search the collapsed trench longer for Okoye (damages O2)"},
							{"id": &"evacuate_now", "label": "Obey Commander Chen & retreat to the Asteria-1 airlock immediately"},
						],
					},
				],
			}
	return {}


func _on_cutscene_finished(_cutscene_id: StringName, choice_id: StringName) -> void:
	_cutscene_open = false
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()
	if choice_id == &"search_longer":
		_feedback_text = "SUIT O2 DAMAGED IN TREMOR  //  OKOYE NOT FOUND  //  BOARD ASTERIA-1 AIRLOCK"
		_feedback_timer = 5.5
	elif choice_id == &"evacuate_now":
		_feedback_text = "DRILL CORE SEALED IN CONTAINER  //  RETURN TO ASTERIA-1 AIRLOCK"
		_feedback_timer = 5.5


func _board_ship() -> void:
	if _transitioning:
		return
	_save_planet_state()
	_transitioning = true
	Engine.set_meta(&"returning_from_planet", true)
	var result := get_tree().change_scene_to_file(SHIP_SCENE_PATH)
	if result != OK:
		_transitioning = false
		Engine.remove_meta(&"returning_from_planet")
		_feedback_text = "Ship scene unavailable. You remain on the development surface; retry the airlock."
		_feedback_timer = 8.0


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_hud_modal_open or _cutscene_open))
